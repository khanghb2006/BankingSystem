namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

/*
    What the client sends to POST api/auth/password/change 
    AccountId is deliberately NOT part of this request body - it comes from the caller's own
        JWT (see AuthController.ChangePassword), so nobody can change someone else's password.
*/
public record ChangePasswordRequest (
    [Required] string OldPassword,
    [Required , MinLength(8) , MaxLength(255)] string NewPassword
);