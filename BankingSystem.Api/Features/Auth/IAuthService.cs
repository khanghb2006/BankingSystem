using BankingSystem.Api.Features.Auth.Dtos;

namespace BankingSystem.Api.Features.Auth;

/*
    Login and password management are added here by later task
    Every member returns the response DTO so a controller cannot reach the plaintext
        OTP code through this contract
*/

public interface IAuthService
{
    Task<AccountResponseDto> RegisterAsync (
        RegisterRequestDto request,
        CancellationToken cancellationToken
    );

    Task<OtpResponseDto> RequestOtpAsync (
        RequestOtpDto request,
        CancellationToken cancellationToken
    );

    Task<AccountResponseDto> VerifyOtpAsync (
        VerifyOtpRequestDto request,
        CancellationToken cancellationToken
    );

    Task <AccountResponseDto> ActivateAsync (
        ActivateRequestDto request,
        CancellationToken cancellationToken
    );
}