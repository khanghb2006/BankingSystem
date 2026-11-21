using BankingSystem.Api.Features.Auth.Dtos;
using Microsoft.AspNetCore.Identity;

namespace BankingSystem.Api.Features.Auth;

/* 
    Register and activation flow. This is where the plaintext is turned into a hash
        and where the plaintext OTP code is kept away from the response
*/
public class AuthService : IAuthService
{
    private readonly AuthRepository m_repository;
    private readonly IHostEnvironment m_environment;
    private readonly ILogger<AuthService> m_logger;

    private readonly PasswordHasher<string> m_passwordHasher = new PasswordHasher<string>();

    public AuthService(
        AuthRepository repository,
        IHostEnvironment environment,
        ILogger<AuthService> logger
    )
    {
        this.m_repository = repository;
        this.m_environment = environment;
        this.m_logger = logger;
    }

    public async Task<AccountResponseDto> RegisterAsync(
        RegisterRequestDto request,
        CancellationToken cancellationToken
    )
    {
        var passwordHash = m_passwordHasher.HashPassword(request.Username, request.Password);
        return await m_repository.RegisterAsync(
            request.Username,
            request.Email,
            request.PhoneNumber,
            passwordHash,
            cancellationToken
        );
    }

    public async Task<OtpResponseDto> RequestOtpAsync(
        RequestOtpDto request,
        CancellationToken cancellationToken
    )
    {
        var issuedOtp = await m_repository.GenerateOtpAsync(
            request.AccountId,
            request.Purpose,
            cancellationToken
        );

        if (m_environment.IsDevelopment())
        {
            m_logger.LogInformation(
                "Development  OTP code for account {AccountId} and purpose {Purpose} is {OtpCode}",
                request.AccountId,
                request.Purpose,
                issuedOtp.OtpCode
            );
        }

        return new OtpResponseDto(issuedOtp.OtpId, issuedOtp.ExpiresAt);
    }

    public async Task<AccountResponseDto> VerifyOtpAsync (
        VerifyOtpRequestDto request,
        CancellationToken cancellationToken
    )
    {
        return await m_repository.VerifyOtpAsync(
            request.AccountId,
            request.OtpCode,
            request.Purpose,
            cancellationToken
        );
    }
    
    public async Task<AccountResponseDto> ActivateAsync(
        ActivateRequestDto request,
        CancellationToken cancellationToken
    )
    {
        return await m_repository.ActivateAsync(
            request.AccountId,
            cancellationToken
        );
    }
}