using System.Net;
using System.Text.Json;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using BankingSystem.Api.Features.Auth.Dtos;

namespace BankingSystem.Tests;

/*
    Integration tests for POST /api/auth/opt/verify base on (docs/test/verify.md)
*/
public class VerifyTest : IClassFixture<WebApplicationFactory<Program>>
{
    private const string OtpUrl = "/api/auth/otp";
    private const string VerifyUrl = OtpUrl + "/verify";
    private const string Purpose = "Register";


    private readonly HttpClient m_client;
    private readonly TestDatabase m_database;

    public VerifyTest(WebApplicationFactory<Program> factory)
    {
        this.m_client = factory.CreateClient();

        var connectionString = factory.Services
            .GetRequiredService<IConfiguration>()
            .GetConnectionString("BankingSystem")
            ?? throw new InvalidOperationException("Missing connection string");

        this.m_database = new TestDatabase(connectionString);
    }

    // VER-01 : verify only accepts the code, activation stay a separate step
    [Fact]
    public async Task VerifyOtp_CorrectCode_MarksVerifiedAndStaysPending()
    {
        var (accountId , otpCode) = await RegisterWithOtpAsync();

        var response = await VerifyAsync(accountId , otpCode);

        Assert.Equal(HttpStatusCode.OK , response.StatusCode);

        using var body = await ApiTestHelpers.ReadBodyAsync(response);
        
        Assert.Equal("Pending" , body.RootElement.GetProperty("data").GetProperty("status").GetString());
        Assert.Equal("Pending" , await m_database.GetAccountStatusAsync(accountId));
        Assert.True(await m_database.IsLastestVerifiedAsync(accountId , Purpose));
    }

    // VER-02 : a wrong code is reject and change nothing
    [Fact]
    public async Task VerifyOtp_WrongCode_ReturnsUnprocessable()
    {
        var (accountId , otpcode) = await RegisterWithOtpAsync();
        var wrongCode = otpcode == "000000" ? "111111" : "000000";

        var response = await VerifyAsync(accountId , wrongCode);

        await AssertCodeRejectedAsync(response);
        Assert.Equal("Pending" , await m_database.GetAccountStatusAsync(accountId));
        Assert.False(await m_database.IsLastestVerifiedAsync(accountId , Purpose));
    }

    // VER-06 : requesting a new OTP retires the previous code
    [Fact] 
    public async Task VerifyOtp_ReplacedCode_OnlyNewCodeWorks()
    {
        var (accountId , oldCode) = await RegisterWithOtpAsync();
        var newCode = await RequestOtpCodeAsync(accountId);

        await AssertCodeRejectedAsync(await VerifyAsync(accountId , oldCode));

        var accepted = await VerifyAsync(accountId , newCode);
        Assert.Equal(HttpStatusCode.OK , accepted.StatusCode);
    }

    // Precondition of every case : a Pending account holding a fresh Register OTP
    private async Task<(long accountId , string OtpCode)> RegisterWithOtpAsync()
    {
        var accountId = await ApiTestHelpers.RegisterAccountAsync(m_client);
        return (accountId , await RequestOtpCodeAsync(accountId));
    }

    // The code is never part of the response, so it is read from the database
    private async Task<string> RequestOtpCodeAsync(long accountId)
    {
        var response = await m_client.PostAsJsonAsync(OtpUrl , new {accountId , Purpose});
        response.EnsureSuccessStatusCode();

        return await m_database.GetLatestUnverifiedOtpCodeAsync(accountId , Purpose);
    }

    private Task<HttpResponseMessage> VerifyAsync(long accountId , string otpCode)
    {
        return m_client.PostAsJsonAsync(VerifyUrl , new {accountId , otpCode , Purpose});
    }

    private static Task AssertCodeRejectedAsync(HttpResponseMessage response)
    {
        return ApiTestHelpers.AssertErrorAsync(response , HttpStatusCode.UnprocessableEntity , 122001 , "otp");
    }
};

