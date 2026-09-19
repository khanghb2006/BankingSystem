namespace Backend.Auth.Dto;

/*
    Deliberately not include the OTP code itself
    The code is only send to the user never return in this API response.
*/
public record OtpResponse (
    long OtpId,
    DateTime ExpiresAt
);