/* 
================================================================
    Banking System Stored Procedures - Account
    Author : Huynh Bao Khang
    Description : Account Management Procedures

    Procedures:
    -----------
        1. sp_create_account
        2. sp_get_customer_accounts
        3. sp_get_account_balance
        4. sp_update_account_status
        5. sp_close_account
================================================================
*/

use BankingSystem;
go

/* 
----------------------------------------
    sp_create_account
    Description : Create a new account for a customer
----------------------------------------
*/
create or alter procedure sp_create_account
    @customer_id nchar(10),
    @branch_id nchar(10),
    @account_type nvarchar(20),
    @currency nvarchar(10),
    @initial_balance decimal(18, 2)
as
begin
    set nocount on;
    set xact_abort on;

    begin try
        begin transaction;

        /* Validate Customer */
        if not exists (
            select 1
            from Customer
            where customer_id = @customer_id
        )
        throw 50004, 'Customer does not exist.', 1;

        /* Validate Branch */
        if not exists (
            select 1
            from Branch
            where branch_id = @branch_id
        )
        throw 50005, 'Branch does not exist.', 1;

        /* Validate Account Type */
        if @account_type not in ('Savings', 'Checking')
            throw 50006, 'Invalid account type.', 1;
        
        /* Validate Currency */
        if upper(@currency) not in ('USD' , 'EUR' , 'CNY' , 'VND')
            throw 50007 , 'Unsupported currency.' , 1;
        
        /* Validate Initial Balance */
        if @initial_balance < 0
            throw 50008, 'Initial balance cannot be negative.', 1;
        
        /* Generate Account ID */
        declare @account_id nchar(10);
        declare @next_account_id int = next value for seq_AccountID;

        set @account_id = 'AC' + right('000000' + cast(@next_account_id as varchar(6)), 6);

        /* Generate Account Number */
        declare @account_number nchar(20);
        declare @next_account_number bigint = next value for seq_AccountNumber;
        set @account_number = cast(@next_account_number as nchar(20));

        /* Insert Account */
        insert into Account 
            (account_id, account_number, customer_id, branch_id, account_type, 
                currency, balance, available_balance, opened_at, closed_at, status)
        values
            (@account_id, @account_number, @customer_id, @branch_id, @account_type,
                upper(@currency), @initial_balance, @initial_balance, getdate(), null, 'Active');
        
        commit transaction;

        /* Return created account details */
        select 
            account_id, account_number, customer_id, branch_id, account_type, 
                currency, balance, available_balance, opened_at, closed_at, status
        from Account
        where account_id = @account_id;

    end try
    begin catch
        if @@trancount > 0
            rollback transaction
        throw
    end catch
end 
go

/* 
----------------------------------------
    sp_get_customer_accounts
    Description : Get all accounts of a customer
----------------------------------------
*/
create or alter procedure sp_get_customer_accounts
    @customer_id nchar(10)
as 
begin
    set nocount on;
    begin try
        /* Validate Customer */
        if not exists (
            select 1
            from Customer
            where customer_id = @customer_id
        )
        throw 50008 , 'Customer does not exist.' , 1;

        select 
            account_id, account_number, branch_id, account_type, 
                currency, balance, available_balance, opened_at, closed_at, status
        from Account
        where customer_id = @customer_id
        order by opened_at desc;

    end try
    begin catch
        throw;
    end catch
end
go

/* 
----------------------------------------
    sp_get_account_balance
    Description : Get the balance of an account
----------------------------------------
*/
create or alter procedure sp_get_account_balance
    @account_id nchar(10)
as 
begin
    set nocount on;
    begin try 
        /* Validate Account */
        if not exists (
            select 1
            from Account
            where account_id = @account_id
        )
        throw 50009 , 'Account does not exist.' , 1;

        select 
            account_id, account_number, balance, available_balance,
                currency, status
        from Account
        where account_id = @account_id;
    end try
    begin catch
        throw;
    end catch
end
go

/*
----------------------------------------
    sp_update_account_status
    Description : Update the status of an account (Active, Inactive, Closed)
----------------------------------------
*/
create or alter procedure sp_update_account_status
    @account_id nchar(10),
    @new_status nvarchar(20)
as
begin
    set nocount on;
    begin try
        begin transaction;
        /* Validate Account */
        if not exists (
            select 1
            from Account
            where account_id = @account_id
        )
        throw 50009 , 'Account does not exist.' , 1;

        /* Validate New Status */
        if @new_status not in ('Active', 'Inactive', 'Closed')
            throw 50010 , 'Invalid account status.' , 1;

        /* Update Account */
        update Account
        set 
            status = @new_status,
            closed_at = case 
                when @new_status = 'Closed' then getdate() 
                else closed_at 
            end
        where account_id = @account_id;
        
        commit transaction;
        
        select
            account_id, account_number, customer_id, branch_id, account_type, 
                currency, balance, available_balance, opened_at, closed_at, status
        from Account
        where account_id = @account_id;

    end try
    begin catch
        if @@trancount > 0
            rollback transaction
        throw;
    end catch
end
go 

/* 
----------------------------------------
    sp_close_account
    Description : Close an account (set status to Closed)
----------------------------------------
*/

create or alter procedure sp_close_account
    @account_id nchar(10)
as
begin
    set nocount on;
    begin try
        begin transaction

        /* Validate Account */
        if not exists (
            select 1
            from Account
            where account_id = @account_id
        )
        throw 50009 , 'Account does not exist.' , 1;

        /* Already Closed */
        if exists (
            select 1
            from Account
            where account_id = @account_id
                and status = 'Closed'
        )
        throw 50011 , 'Account is already closed.' , 1;

        /* Update Account Status */
        update Account
        set 
            status = 'Closed',
            closed_at = getdate()
        where account_id = @account_id;

        commit transaction;

        select
            account_id, account_number, customer_id, branch_id, account_type, 
                currency, balance, available_balance, opened_at, closed_at, status
        from Account
        where account_id = @account_id;

    end try
    begin catch
        if @@trancount > 0
            rollback transaction
        throw;
    end catch
end
go
