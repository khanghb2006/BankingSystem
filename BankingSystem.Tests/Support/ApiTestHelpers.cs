using System.Net;
using System.Text.Json;
using System.Net.Http.Json;

namespace BankingSystem.Tests;

internal static class ApiTestHelpers
{
    // The database keeps data between runs, so every call returns value that were never used 
    public static Dictionary<string , object?> NewRegisterBody()
    {
        var unique = Guid.NewGuid().ToString("N")[..20];
        var username = "user_" + unique;

        return new Dictionary<string , object?>
        {
            ["username"] = username,
            ["email"] = username + "@example.com",
            ["phoneNumber"] = Random.Shared.NextInt64(100_000_000_000 , 1_000_000_000_000).ToString(),
            ["password"] = "Sup3rSecret!"
        };
    }

    public static async Task<JsonDocument> ReadBodyAsync(HttpResponseMessage response)
    {
        var responseText = await response.Content.ReadAsStringAsync();
        return JsonDocument.Parse(responseText);
    }

    // Precondition of the OTP and activation cases: a brand new Pending account
    public static async Task<long> RegisterAccountAsync(HttpClient client)
    {
        string register_api = "/api/auth/register";
        var response = await client.PostAsJsonAsync(register_api , NewRegisterBody());
        response.EnsureSuccessStatusCode();

        using var body = await ReadBodyAsync(response);
        return body.RootElement.GetProperty("data").GetProperty("accountId").GetInt64();
    }

    public static async Task AssertErrorAsync(HttpResponseMessage response ,
        HttpStatusCode status, int code , string domain)
    {
        Assert.Equal(status , response.StatusCode);

        using var body = await ReadBodyAsync(response);
        Assert.False(body.RootElement.GetProperty("success").GetBoolean());

        var error = body.RootElement.GetProperty("error");
        Assert.Equal(code , error.GetProperty("code").GetInt32());
        Assert.Equal(domain , error.GetProperty("domain").GetString());
    }
}