namespace Backend.Tests;

using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

/*
    Intergration tests cho vertical slice Branch
    Then call Post api/branches through HTTP and check response is correct with format ApiResponse
    This test is insert real data into the database so run deploy.ps1 again to reset the database
*/
public class BranchApiTests(WebApplicationFactory<Program> factory):
    IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task Create_branch_returns_envelope()
    {
        var client = factory.CreateClient();
        var request = await client.PostAsJsonAsync("api/branches", new
        {
            BranchName =  "Chi nhanh Test",
            Address =  "1 Nguyen Hue",
            PhoneNumber = "02838220099"
        });
        var body = await request.Content.ReadFromJsonAsync<JsonElement>();

        Assert.True(body.GetProperty("success").GetBoolean());
        Assert.Equal("Branch created successfully.", body.GetProperty("message").GetString());
        Assert.True(body.GetProperty("data").TryGetProperty("branchId", out _));
    }

    [Fact]
    public async Task Create_branch_with_empty_name_returns_400()
    {
        var client = factory.CreateClient();
        var request = await client.PostAsJsonAsync("api/branches", new
        {
            BranchName =  "",
            Address =  "1 Nguyen Hue",
            PhoneNumber = "02838220099"
        });

        var body = await request.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(System.Net.HttpStatusCode.BadRequest , request.StatusCode);
        Assert.False(body.GetProperty("success").GetBoolean());
        Assert.Equal(400 , body.GetProperty("error").GetProperty("code").GetInt32());
    }
}