namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

/*
    What the client sends to POST api/auth/login. No length rule on Password here
    This check an existing password
*/
public record LoginRequest (
    [Required] string Username,
    [Required] string Password
);