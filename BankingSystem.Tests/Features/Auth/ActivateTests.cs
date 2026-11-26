using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BankingSystem.Tests;

/*
    Integration for POST /api/auth/activate based on (docs/test/activate.md)
*/
public class ActivateTests : IClassFixture<WebApplicationFactory<Program>>
{
    private const string Purpose = "Register";

    private readonly HttpClient m_client;
    private readonly TestDatabase m_database;

    public ActivateTests(WebApplicationFactory<Program> factory)
    {
        this.m_client = factory.CreateClient();

        var connectionString = factory.Services
            .GetRequiredService<IConfiguration>()
            .GetConnectionString("BankingSystem")
            ?? throw new InvalidOperationException("Missing connection string");

        this.m_database = new TestDatabase(connectionString);
    }

    // ACT-01 : an account whose Register OTP was verified becomes Active
    [Fact]
    public async Task Activate_AfterOtpVerified_ReturnsActiveAccount()
    {
        var accountId = await RegisterVerifiedAccountAsync();
        var response = await m_client.PostAsJsonAsync("/api/auth/activate" , new {accountId});

        Assert.Equal(HttpStatusCode.OK , response.StatusCode);

        using var body = await ApiTestHelpers.ReadBodyAsync(response);
        Assert.True(body.RootElement.GetProperty("success").GetBoolean());

        var data = body.RootElement.GetProperty("data");
        Assert.Equal("Active" , data.GetProperty("status").GetString());
        Assert.NotEqual(JsonValueKind.Null , data.GetProperty("updatedAt").ValueKind);
        Assert.Equal("Active" , await m_database.GetAccountStatusAsync(accountId));
    }

    // Precondition share by the Active cases : a Pending account with a verified Register OTP
    private async Task<long> RegisterVerifiedAccountAsync()
    {
        var accountId = await ApiTestHelpers.RegisterAccountAsync(m_client);

        string opt_api = "/api/auth/otp";
        (await m_client.PostAsJsonAsync(opt_api , new {accountId , Purpose}))
            .EnsureSuccessStatusCode();

        var otpCode = await m_database.GetLatestUnverifiedOtpCodeAsync(accountId , Purpose);
        
        string verify_otp_api = "/api/auth/otp/verify";
        (await m_client.PostAsJsonAsync(verify_otp_api , new {accountId , otpCode , Purpose}))
            .EnsureSuccessStatusCode();

        return accountId;
    }
}