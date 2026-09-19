namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

/*
    What the client sends to POST api/auth/otp - asks the backend to create and 
        "send" a one-time code for the given purpose (Register or ResetPassword).
*/
public record GenerateOtpRequest (
    [Required] long AccountId,
    [Required] string Purpose
);