using System.ComponentModel.DataAnnotations;

namespace BankingSystem.Api.Features.Auth.Dtos;

/*
    Body of POST /api/auth/otp. The endpoint is public, so only the purposes a guest may 
        legitimately request are allowed.
    Purposes as Transaction or Login belong to authenticated flow
*/
public record RequestOtpDto (
    [Range(1 , long.MaxValue)] long AccountId,
    [Required , AllowedValues("Register" , "PasswordReset")] string Purpose
);