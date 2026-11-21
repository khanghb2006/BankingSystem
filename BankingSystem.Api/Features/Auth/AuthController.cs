using BankingSystem.Api.Common;
using BankingSystem.Api.Features.Auth.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace BankingSystem.Api.Features.Auth;

/*
    Public registration and activate endpoints. Map the route, call the service and
        wrap the result in the standard envelope
    Every secret (password , OTP code) travels in POST body 
*/
[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService m_authService;

    public AuthController(IAuthService authService)
    {
        this.m_authService = authService;
    }

    // POST /api/auth/register
    [HttpPost("register")]
    public async Task<ApiResponse<AccountResponseDto>> Register (
        RegisterRequestDto request,
        CancellationToken cancellation
    )
    {
        var account = await m_authService.RegisterAsync(request , cancellation);
        return ApiResponse<AccountResponseDto>.Ok(
            account,
            "Registration successful. Please verify your account via OTP"
        );
    }

    // POST api/auth/otp
    [HttpPost("otp")]
    public async Task<ApiResponse<OtpResponseDto>> RequestOtp (
        RequestOtpDto request,
        CancellationToken cancellation
    )
    {
        var otp = await m_authService.RequestOtpAsync(request , cancellation);
        return ApiResponse<OtpResponseDto>.Ok(
            otp,
            "OTP code generated. Please check your email or phone"
        );
    }

    // POST api/auth/otp/verify
    [HttpPost("otp/verify")]
    public async Task<ApiResponse<AccountResponseDto>> VerifyOtp (
        VerifyOtpRequestDto request,
        CancellationToken cancellation
    )
    {
        var account = await m_authService.VerifyOtpAsync(request , cancellation);
        return ApiResponse<AccountResponseDto>.Ok(
            account,
            "OTP verified. Please activate your account"
        );
    }

    // POST api/auth/activate
    [HttpPost("activate")]
    public async Task<ApiResponse<AccountResponseDto>> Activate (
        ActivateRequestDto request,
        CancellationToken cancellation
    )
    {
        var account = await m_authService.ActivateAsync(request , cancellation);
        return ApiResponse<AccountResponseDto>.Ok(
            account,
            "Account activated. You can now log in"
        );
    }
}