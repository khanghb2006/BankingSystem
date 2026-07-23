/*
=============================================
    Banking System Functions - OTP
    Author : Huynh Bao Khang
    Description : Create functions for OTP operations
==============================================
*/
use BankingSystem;
go

/* 
--------------------------------------------------------
    Function : fn_generate_otp_code
    Description : Generate a random 6-digit OTP code
--------------------------------------------------------
*/
create or alter procedure sp_generate_otp_code
    @otp_code nchar(6) output
as 
begin
    set nocount on;
    set @otp_code = right('000000' + cast(abs(checksum(newid())) % 1000000 AS nvarchar(6)), 6);
end
go

/* 
--------------------------------------------------------
    Function : fn_check_verified_otp
    Description : Check if an OTP exists for a given customer ID and purpose
--------------------------------------------------------
*/
create or alter function fn_check_verified_otp
    (@customer_id nchar(10), @purpose nvarchar(20))
returns bit
as
begin
    declare @result bit = 0;

    if exists (
        select 1
        from OTP
        where customer_id = @customer_id 
            and purpose = @purpose
            and verified = 1
            and expired_at > getdate()
    )
        set @result = 1;

    return @result;
end
go
