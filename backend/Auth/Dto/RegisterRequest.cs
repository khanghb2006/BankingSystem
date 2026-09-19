namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

/* 
    What the clients sends to POST api/auth/register
    Password arrives as plain text here - AuthService hashes it before calling 
        sp_account_register, the stored procedure itself never sees a plain-text password.
*/
public record RegisterRequest(
    [Required , MaxLength(50)] string Username,
    [Required , EmailAddress , MaxLength(100)] string Email,
    [Required , Phone , MaxLength(20)] string PhoneNumber,
    [Required , MinLength(8) , MaxLength(255)] string Password
);