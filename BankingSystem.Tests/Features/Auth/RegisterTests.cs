using System.Net;
using System.Text.Json;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BankingSystem.Tests;

/*
    Integration tests for POST /api/auth/register base on (docs/test/register.md)
    Calling the real API against the seeded database
*/
public class RegisterTests : IClassFixture<WebApplicationFactory<Program>>
{
    private const string RegisterUrl = "/api/auth/register";
    private const string ValidPassword = "Sup3rSecret!";

    private readonly HttpClient m_client;
    private readonly TestDatabase m_database;

    public RegisterTests(WebApplicationFactory<Program> factory)
    {
        this.m_client = factory.CreateClient();

        // Reuse the connection string 
        var connectionString = factory.Services
            .GetRequiredService<IConfiguration>()
            .GetConnectionString("BankingSystem")
            ?? throw new InvalidOperationException("Missing connection string `BankingSystem`");

        this.m_database = new TestDatabase(connectionString);
    }

    // REG-01
    [Fact]
    public async Task Register_ValidRequest_ReturnsPendingCustomer()
    {
        var request = ApiTestHelpers.NewRegisterBody();

        var response = await m_client.PostAsJsonAsync(RegisterUrl, request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var body = await ApiTestHelpers.ReadBodyAsync(response);
        Assert.True(body.RootElement.GetProperty("success").GetBoolean());

        var data = body.RootElement.GetProperty("data");
        Assert.Equal((string)request["username"]! , data.GetProperty("username").GetString());
        Assert.Equal("Pending" , data.GetProperty("status").GetString());
        Assert.Equal("Customer" , data.GetProperty("role").GetString());
        Assert.Equal(JsonValueKind.Number , data.GetProperty("accountId").ValueKind);
    }

    // REG-02 : the stored value must be a real hash not a plaint text
    [Fact]
    public async Task Register_ValidRequest_StoresHashNotPlainPassword()
    {
        var request = ApiTestHelpers.NewRegisterBody();

        var response = await m_client.PostAsJsonAsync(RegisterUrl, request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var body = await ApiTestHelpers.ReadBodyAsync(response);
        var accountId = body.RootElement.GetProperty("data").GetProperty("accountId").GetInt64();

        var storedHash = await m_database.GetPasswordHashAsync(accountId)!;

        Assert.NotEqual(ValidPassword , storedHash);

        // The hashser recognizes its own output, which proves the stored value is a real password
        var hasher = new PasswordHasher<object>();
        var verification = hasher.VerifyHashedPassword((string)request["username"]! , storedHash , ValidPassword);

        Assert.Equal(PasswordVerificationResult.Success , verification);
    }

    //REG-03 : neither the password nor its hash may appear anywhere in the response
    [Fact]
    public async Task Register_ValidRequest_ResponseLeaksNoSecret()
    {
        var request = ApiTestHelpers.NewRegisterBody();
        var response = await m_client.PostAsJsonAsync(RegisterUrl, request);

        Assert.Equal(HttpStatusCode.OK , response.StatusCode);

        var responseText = await response.Content.ReadAsStringAsync();

        using var body = JsonDocument.Parse(responseText);
        var accountId = body.RootElement.GetProperty("data").GetProperty("accountId").GetInt64();
        var storedHash = await m_database.GetPasswordHashAsync(accountId);

        Assert.DoesNotContain(ValidPassword , responseText);
        Assert.DoesNotContain(storedHash , responseText);
        Assert.DoesNotContain("password" , responseText , StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("hash" , responseText , StringComparison.OrdinalIgnoreCase);
    }

    // REG-05 , REG-06 , REG-07 : duplicate username , email or phone number each exactly one account
    [Theory]
    [InlineData("username" , 140000)]
    [InlineData("email" , 140010)]
    [InlineData("phoneNumber" , 140020)]
    public async Task Register_DuplicateField_ReturnConflict(string field , int expectedCode)
    {
        var existing = ApiTestHelpers.NewRegisterBody();
        (await m_client.PostAsJsonAsync(RegisterUrl , existing))
            .EnsureSuccessStatusCode();

        // Only one field is reused so the conflict cannot from anything else
        var duplicate = ApiTestHelpers.NewRegisterBody();
        duplicate[field] = existing[field];

        var response = await m_client.PostAsJsonAsync(RegisterUrl , duplicate);

        Assert.Equal(HttpStatusCode.Conflict , response.StatusCode);

        using var body = await ApiTestHelpers.ReadBodyAsync(response);
        Assert.False(body.RootElement.GetProperty("success").GetBoolean());

        var error = body.RootElement.GetProperty("error");
        Assert.Equal(expectedCode , error.GetProperty("code").GetInt32());
        Assert.Equal("account" , error.GetProperty("domain").GetString());
    }
}               