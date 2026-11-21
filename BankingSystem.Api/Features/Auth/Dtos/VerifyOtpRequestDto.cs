using System.ComponentModel.DataAnnotations;

namespace BankingSystem.Api.Features.Auth.Dtos;

/* 
    Body of POST /api/auth/otp/verify. The OTP code is a secret so it is validated
        strictly and never printed. The allowed purpose must stay in sync with RequestOtpDto
*/

public record VerifyOtpRequestDto (
    [property : Range(1 , long.MaxValue)] long AccountId,
    [property: Required, RegularExpression(@"^[0-9]{6}\z")] string OtpCode,
    [property : Required , AllowedValues("Register" , "PasswordReset")] string Purpose
)
{
    // Print the identifier only; the generated ToString would include OTPcode
    public override string ToString()
    {
        return $"VerifyOtpRequestDto {{AccountId = {AccountId} , Purpose = {Purpose}}}";
    }
}