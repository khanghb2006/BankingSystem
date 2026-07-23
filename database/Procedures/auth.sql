/*
======================================================
    Banking System Stored Procedures - Authentication
    Author : Huỳnh Bảo Khang
    Description : Authentication Procedures
======================================================
*/

use BankingSystem;
go

/* 
--------------------------------------------------------
    Procedure : sp_register
    - Description : Register a new customer
    - Note : Password must already be hashed before calling this procedure
--------------------------------------------------------
*/
create or alter procedure sp_register (
    @first_name nvarchar(50),
    @last_name nvarchar(50),
    @gender varchar(10),
    @dob date,
    @phone_number nchar(10),
    @email nvarchar(50),
    @password_hash varchar(255),
    @citizen_id nchar(12),
    @address nvarchar(100)
)
as
begin
    set nocount on;
    set xact_abort on;
    begin try
        begin transaction;

        if dbo.fn_email_exists(@email) = 1
        throw 50001, 'email already exists.', 1;

        if dbo.fn_citizen_id_exists(@citizen_id) = 1
        throw 50002, 'Citizen ID already exists.', 1;

        -- Generate new customer ID
        declare @customer_id nchar(10)
        set @customer_id = 'CIF' + 
            right('0000000' + cast(next value for seq_CustomerID as varchar(7)) , 7)
        
        insert into Customer 
            (customer_id , first_name, last_name, gender, dob, phone_number , email,
                password_hash, citizen_id, address, created_at, status)
        values 
            (@customer_id, @first_name, @last_name, @gender, @dob, @phone_number, @email,
                @password_hash, @citizen_id, @address, getdate(), 'Active')

        select 
            customer_id, 
            email, 
            status
        from Customer
        where customer_id = @customer_id

        commit transaction;
    end try
    begin catch
        if @@trancount > 0
            rollback transaction;

        throw;
    end catch
end
go

/*
--------------------------------------------------------
    Procedure : sp_login
    - Description : Login a customer by email and password hash
--------------------------------------------------------
*/
create or alter procedure sp_login
    @email nvarchar(50),
    @password_hash varchar(255)
as
begin
    set nocount on;
    set xact_abort on;

    begin try
        begin transaction;

            if dbo.fn_email_exists(@email) = 0
                throw 50003 , 'Customer not found', 1;

            if dbo.fn_customer_is_active(@email) = 0
                throw 50004 , 'Customer is inactive', 1;

            if dbo.fn_check_password(dbo.fn_get_customer_id_by_email(@email), @password_hash) = 0
                throw 50005 , 'Incorrect email or password', 1;

            select 
                customer_id,
                first_name,
                last_name,
                email,
                phone_number,
                status,
                created_at
            from Customer
            where email = @email and password_hash = @password_hash;
        
        commit transaction;
    end try
    begin catch
        if @@trancount > 0
            rollback transaction;

        throw;
    end catch
end
go

/*
--------------------------------------------------------
    Procedure : sp_change_password
    - Description : Change customer password by customer ID. 
    - Note : Password must already be hashed before calling this procedure
--------------------------------------------------------
*/
create or alter procedure sp_change_password
    @customer_id nchar(10),
    @current_password varchar(255),
    @new_password varchar(255)
as
begin
    set nocount on;
    set xact_abort on;

    begin try

        begin transaction;

        if dbo.fn_customer_exists(@customer_id) = 0
            throw 50003, 'Customer not found', 1;
        
        if dbo.fn_customer_is_active(@customer_id) = 0
            throw 50004, 'Customer is inactive', 1;
        
        if dbo.fn_check_password(@customer_id, @current_password) = 0
            throw 50005, 'Incorrect old password', 1;

        if @current_password = @new_password
            throw 50006, 'New password cannot be the same as the old password', 1;

        update Customer
        set
            password_hash = @new_password,
            updated_at = getdate()
        where customer_id = @customer_id

        select 
            customer_id, 
            email, 
            status
        from Customer
        where customer_id = @customer_id

        commit transaction;

    end try
    begin catch
        if @@trancount > 0
            rollback transaction;

        throw;
    end catch
end
go

/* 
--------------------------------------------------------
    Procedure : sp_generate_otp
    - Description : Generate OTP for password reset
--------------------------------------------------------
*/
create or alter procedure sp_generate_otp
    @email nvarchar(50)
as 
begin
    set nocount on;
    set xact_abort on;

    begin try
        begin transaction;
            
            if dbo.fn_email_exists(@email) = 0
                throw 50003, 'Customer not found', 1;
            
            if dbo.fn_customer_is_active(@email) = 0
                throw 50004, 'Customer is inactive', 1;
            
            declare @customer_id nchar(10),
                    @otp_code nchar(6),
                    @otp_id nchar(10),
                    @expired_at datetime;
                
            set @customer_id = dbo.fn_get_customer_id_by_email(@email);

            -- Remove previous OTP
            delete from OTP
            where customer_id = @customer_id 
                and purpose = 'RESET_PASSWORD'

            -- Generate OTP ID
            set @otp_id = 'OT' + 
                right('00000000' + cast(next value for seq_OTPID as varchar(8)) , 8)

            -- Generate OTP code
            exec sp_generate_otp_code @otp_code output;
            set @expired_at = dateadd(minute, 5, getdate());

            -- Insert new OTP
            insert into OTP 
                (otp_id, customer_id, otp_code, purpose, expired_at, verified, created_at)
            values 
                (@otp_id, @customer_id, @otp_code, 'RESET_PASSWORD', @expired_at, 0, getdate());
        commit transaction;

        -- Return OTP code for backend to send email
        select 
            otp_id,
            customer_id,
            otp_code,
            expired_at
        from OTP
        where otp_id = @otp_id

    end try

    begin catch

        if @@trancount > 0
            rollback transaction;

        throw;

    end catch
end
go

/* 
--------------------------------------------------------
    Procedure : sp_verify_otp
    - Description : Verify OTP for password reset
--------------------------------------------------------
*/
create or alter procedure sp_verify_otp
    @customer_id nchar(10),
    @otp_code nchar(6),
    @purpose nvarchar(20)
as
begin
    set nocount on;
    set xact_abort on;

    begin try
        begin transaction;

            -- Validate OTP
            if not exists (
                select 1
                from OTP
                where customer_id = @customer_id 
                    and otp_code = @otp_code 
                    and purpose = @purpose
                    and verified = 0
                    and expired_at > getdate()
            )
                throw 50007, 'Invalid or expired OTP code', 1;
            
            -- Mark OTP as verified
            update OTP 
            set verified = 1
            where customer_id = @customer_id 
                and otp_code = @otp_code 
                and purpose = @purpose;

        commit transaction;
    end try
    begin catch
        if @@trancount > 0
            rollback transaction;

        throw;
    end catch
end
go

/*
--------------------------------------------------------
    Procedure : sp_reset_password
    - Description : Reset password using OTP
--------------------------------------------------------
*/
create or alter procedure sp_reset_password
    @customer_id nchar(10),
    @new_password varchar(255)
as
begin
    set nocount on;
    set xact_abort on;

    begin try
        begin transaction;
            -- Validate customer
            if dbo.fn_customer_exists(@customer_id) = 0
                throw 50003, 'Customer not found', 1;
            
            -- Validate verified OTP for password reset
            if dbo.fn_check_verified_otp(@customer_id , 'RESET_PASSWORD') = 0
                throw 50007, 'No verified OTP found for password reset', 1;

            -- Update password
            update Customer
            set password_hash = @new_password,
                updated_at = getdate()
            where customer_id = @customer_id;

            -- Remove all verified reset password OTPs
            delete from OTP
            where customer_id = @customer_id 
                and purpose = 'RESET_PASSWORD'
        
        commit transaction;
    end try
    begin catch
        if @@trancount > 0
            rollback transaction;

        throw;
    end catch
end
go