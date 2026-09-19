namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

/*
    What the client sends to POST api/auth/otp/verify - the 6-digit code the user just typed
        in, checked against the sp_otp_generate_otpcode create earlier for the same
        account_id + purpose.
*/
public record VerifyOtpRequest (
    [Required] long AccountId,
    [Required , StringLength(6, MinimumLength = 6)] string OtpCode,
    [Required] string Purpose
);
