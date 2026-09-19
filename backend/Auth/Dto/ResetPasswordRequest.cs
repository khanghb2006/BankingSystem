namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

/*
    What the client sends to POST api/auth/password/reset - used when the user is NOT logged
        in (forgot password) and wants to reset their password.
    Safety comes from sp_account_reset_password's own check that is a 'ResetPassword' OTP for
        this exact AccoundId
*/
public record ResetPasswordRequest (
    [Required] long AccountId,
    [Required , MinLength(8) , MaxLength(255)] string NewPassword
);