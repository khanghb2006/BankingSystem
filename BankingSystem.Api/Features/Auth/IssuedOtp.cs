using System.Text.Json.Serialization;

namespace BankingSystem.Api.Features.Auth.Dtos;

/*
    Result of generating an OTP code. It carries the plaintext code so the service can
        deliver it to the user
    It lives outside Dtos on purpose: nothing here may be returned to a client
*/

public record IssuedOtp(
    long OtpId,
    DateTime ExpiresAt,
    [property: JsonIgnore] string OtpCode
)
{
    public override string ToString()
    {
        return $"IssuedOtp {{ OtpId = {OtpId} , ExpiresAt = {ExpiresAt} }}";
    }
}