namespace Backend.Auth;

using Backend.Auth.Dto;
using Backend.Common;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using System.IdentityModel.Tokens.Jwt;

/* 
    Receives HTTP requests for api/auth and delegates straight to AuthService
    Same shapes as BranchController : no logic here only HTTP concerns
        (routing , reading headers / connection info)
*/
[ApiController]
[Route("api/[controller]")]
public sealed class AuthController (AuthService authService) : ControllerBase
{
    // Column limits of LoginHistory: ip_address VARCHAR(50) , device NVARCHAR(100)
    private const int MaxIpAddressLength = 50;
    private const int MaxDeviceLength = 100;

    [HttpPost("register")]
    public async Task<ApiResponse<AccountResponse>> Register([FromBody] RegisterRequest request)
    {
        ApiResponse<AccountResponse> response = await authService.RegisterAsync(request);
        return response;
    }

    [HttpPost("otp")]
    public async Task<ApiResponse<OtpResponse>> GenerateOtp([FromBody] GenerateOtpRequest request)
    {
        ApiResponse<OtpResponse> response = await authService.GenerateOtpAsync(request);
        return response;
    }

    [HttpPost("otp/verify")]
    public async Task<ApiResponse<AccountResponse>> VerifyOtp([FromBody] VerifyOtpRequest request)
    {
        ApiResponse<AccountResponse> response = await authService.VerifyOtpAsync(request);
        return response;
    }

    [HttpPost("activate")]
    public async Task<ApiResponse<AccountResponse>> Activate([FromBody] ActivateRequest request)
    {
        ApiResponse<AccountResponse> response = await authService.ActivateAsync(request);
        return response;
    }

    [HttpPost("login")]
    public async Task<ApiResponse<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        string ipAddress = GetClientIpAddress();
        string device = GetClientDevice();

        ApiResponse<LoginResponse> response = await authService.LoginAsync(request, ipAddress, device);
        return response;
    }

    [Authorize]
    [HttpPost("password/change")]
    public async Task<ApiResponse<PasswordUpdateResponse>> ChangePassword
        ([FromBody] ChangePasswordRequest request)
    {
        long accountId = GetCurrentAccountId();
        ApiResponse<PasswordUpdateResponse> response = 
            await authService.ChangePasswordAsync(accountId , request);
        return response;
    }

    /*
        Forgot password flow : the caller cannot login so no [Authorize] here
        Proof of identity is verified "PasswordReset" OTP
    */
    [HttpPost("password/reset")]
    public async Task<ApiResponse<PasswordUpdateResponse>> ResetPassword
        ([FromBody] ResetPasswordRequest request)
    {
        ApiResponse<PasswordUpdateResponse> response = 
            await authService.ResetPasswordAsync(request);
        return response;
    }

    private string GetClientIpAddress()
    {
        string? ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        if (string.IsNullOrEmpty(ipAddress))
            return "Unknown";
        return Truncate(ipAddress , MaxIpAddressLength);
    }

    private string GetClientDevice()
    {
        string? userAgent = Request.Headers.UserAgent.ToString();

        if (string.IsNullOrEmpty(userAgent))
            return "Unknown";
        return Truncate(userAgent , MaxDeviceLength);
    }

    private static string Truncate(string value , int maxLength)
    {
        if (value.Length <= maxLength)
            return value;
        return value.Substring(0 , maxLength);
    }

    private long GetCurrentAccountId()
    {
        string? accountIdText = User.FindFirstValue(JwtRegisteredClaimNames.Sub);
        return long.Parse(accountIdText!);
    }
}
