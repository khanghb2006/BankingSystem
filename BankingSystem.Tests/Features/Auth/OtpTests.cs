using System.Net;
using System.Text.Json;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BankingSystem.Tests;

/*
    Integration test for POST "/api/auth/otp base on docs/test/api.md)
*/

public class OtpTests : IClassFixture<WebApplicationFactory<Program>>
{
    private const string OtpUrl = "/api/auth/otp";
    private const string Purpose = "Register";

    private readonly HttpClient m_client;
    private readonly TestDatabase m_database;

    public OtpTests(WebApplicationFactory<Program> factory)
    {
        this.m_client = factory.CreateClient();

        var connectionString = factory.Services
            .GetRequiredService<IConfiguration>()
            .GetConnectionString("BankingSystem")
            ?? throw new InvalidOperationException("Missing connection string");
    
        this.m_database = new TestDatabase(connectionString);
    }

    // OTP-01 : the response tells which OTP was issued and when it exprises nothing more
    [Fact] 
    public async Task RequestOtp_NewAccount_ReturnOnlyIdAndExpiry()
    {
        var accountId = await ApiTestHelpers.RegisterAccountAsync(m_client);

        using JsonDocument body = await RequestOtpAsync(accountId);

        Assert.True(body.RootElement.GetProperty("success").GetBoolean());

        var keys = body.RootElement.GetProperty("data")
            .EnumerateObject()
            .Select(property => property.Name)
            .Order();
        
        Assert.Equal(new[] {"expiresAt" , "otpId"} , keys);
    }

    // OTP-02 : the code is delivered out of band, so it must never travel back the response
    [Fact]
    public async Task RequestOtp_NewAccount_ResponseHidesCode()
    {
        var accountId = await ApiTestHelpers.RegisterAccountAsync(m_client);

        using var body = await RequestOtpAsync(accountId);

        var otpCode = await m_database.GetLatestUnverifiedOtpCodeAsync(accountId , Purpose);

        var responseText = body.RootElement.GetRawText();

        Assert.DoesNotContain(otpCode , responseText);
        Assert.DoesNotContain("otpCode" , responseText , StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("otp_code" , responseText , StringComparison.OrdinalIgnoreCase);
    }

    //OTP-03 : asking again issues a new OTP. The the old code stops working
    [Fact]
    public async Task RequestOtp_Twice_IssuesNewOtp()
    {
        var accountId = await ApiTestHelpers.RegisterAccountAsync(m_client);

        using var first = await RequestOtpAsync(accountId);
        using var second = await RequestOtpAsync(accountId);

        Assert.NotEqual(ReadOtpId(first) , ReadOtpId(second));
    }

    // Every case here expects the request itself to succeed
    private async Task<JsonDocument> RequestOtpAsync(long accountId)
    {
        var response = await m_client.PostAsJsonAsync(OtpUrl , new {accountId , Purpose});

        Assert.Equal(HttpStatusCode.OK , response.StatusCode);

        return await ApiTestHelpers.ReadBodyAsync(response);
    }

    private static long ReadOtpId(JsonDocument body)
    {
        return body.RootElement.GetProperty("data").GetProperty("otpId").GetInt64();
    }
}