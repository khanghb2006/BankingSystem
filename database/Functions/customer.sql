/*
=============================================
    Banking System Functions - Customer
    Author : Khang Huynh Bao
    Description : Create functions for customer management
==============================================
*/

use BankingSystem;
go

/* 
--------------------------------------------------------
    Function : fn_get_customer_id_by_email
    Description : Retrieve customer details by email
--------------------------------------------------------
*/
create or alter function fn_get_customer_id_by_email (@email nvarchar(50))
returns nchar(10)
as
begin
    declare @customer_id nchar(10);

    select @customer_id = customer_id
    from Customer
    where email = @email;

    return @customer_id;
end
go

/* 
--------------------------------------------------------
    Function : fn_customer_exists
    Description : Check if a customer with the given customer ID exists
--------------------------------------------------------
*/
create or alter function fn_customer_exists (@customer_id nchar(10))
returns bit
as
begin
    declare @exists bit = 0;

    if exists (
        select 1
        from Customer
        where customer_id = @customer_id
    )
        set @exists = 1;
    
    return @exists;
end
go

/* 
--------------------------------------------------------
    Function : fn_email_exists
    Description : Check if a customer with the given email exists
--------------------------------------------------------
*/
create or alter function fn_email_exists (@email nvarchar(50))
returns bit
as
begin
    declare @exists bit = 0;

    if exists (
        select 1
        from Customer
        where email = @email
    )
        set @exists = 1;
    
    return @exists;
end
go

/* 
--------------------------------------------------------
    Function : fn_citizen_id_exists
    Description : Check if a customer with the given citizen ID exists
--------------------------------------------------------
*/

create or alter function fn_citizen_id_exists (@citizen_id nchar(12))
returns bit
as
begin
    declare @exists bit = 0;

    if exists (
        select 1
        from Customer
        where citizen_id = @citizen_id
    )
        set @exists = 1;
    
    return @exists;
end
go

/* 
--------------------------------------------------------
    Function : fn_email_active
    Description : Check if a customer with the given email is active
--------------------------------------------------------
*/
create or alter function fn_customer_is_active (@email nvarchar(50))
returns bit
as
begin
    declare @is_active bit = 0;

    if exists (
        select 1
        from Customer
        where email = @email and status = 'Active'
    )
        set @is_active = 1;
    
    return @is_active;
end
go

/* 
--------------------------------------------------------
    Function : fn_check_password
    Description : Check if the provided password hash matches the stored password hash for the given customer ID
--------------------------------------------------------
*/
create or alter function fn_check_password (@customer_id nchar(10), @password_hash varchar(255))
returns bit
as
begin
    declare @is_match bit = 0;

    if exists (
        select 1
        from Customer
        where customer_id = @customer_id and password_hash = @password_hash
    )
        set @is_match = 1;
    
    return @is_match;
end
go