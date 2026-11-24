using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BankingSystem.Tests;

/*
    Integration tests for the public branch endpoints
    They call the real API over HTTP against the seeds database, so they
        verify the whole chain : Controller -> Service -> Repository -> Database
*/
public class BranchApiTests (WebApplicationFactory<Program> factory) 
    : IClassFixture<WebApplicationFactory<Program>>
{
    /*
        The factory start the API in memory; this client sends the request to it
            without opening a real network port
    */
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task GetBranches_ReturnsTrimmedIdsAndTotalCountHeader()
    {
        var response = await _client.GetAsync("/api/branches");

        Assert.Equal(HttpStatusCode.OK , response.StatusCode);

        // Pagination contract (api_contract): the total row count is sen in a header
        Assert.True(response.Headers.Contains("X-Total-Count"));

        var responseText = await response.Content.ReadAsStringAsync();
        using var body = JsonDocument.Parse(responseText);

        // Every response must use the envelope {success , message , data , error}
        var success = body.RootElement.GetProperty("success").GetBoolean();
        Assert.True(success);

        var branches = body.RootElement.GetProperty("data");
        Assert.Equal(JsonValueKind.Array , branches.ValueKind);
        
        var foundSeededBranch = false;
        foreach (var branch in branches.EnumerateArray())
        {
            /*
                GetString() return string? (nullable); the "!" tells the compiler
                The value is not null. If it is null , the test fails here anyway
            */
            var branchId = branch.GetProperty("branchId").GetString()!;

            // The NCHAR(10) column pads ids with spaces; the API must trim them.
            Assert.Equal(branchId.Trim() , branchId);

            if (branchId == "BR00000001") 
                foundSeededBranch = true;
        }

        // Proves the list really comes from the seeded database
        Assert.True(foundSeededBranch);
    }

    [Fact]
    public async Task GetBranch_ExistingId_ReturnsObject()
    {
        var response = await _client.GetAsync("/api/branches/BR00000001");

        Assert.Equal(HttpStatusCode.OK , response.StatusCode);

        var responseText = await response.Content.ReadAsStringAsync();
        using var body = JsonDocument.Parse(responseText);

        var success = body.RootElement.GetProperty("success").GetBoolean();
        Assert.True(success);

        // A single-record endpoint returns "data" as an object, not an array
        var data = body.RootElement.GetProperty("data");
        Assert.Equal(JsonValueKind.Object , data.ValueKind);
    }

    [Fact]
    public async Task GetBranch_UnknownId_ReturnsNotFoundEnvelope()
    {
        // This id does not exist in the seed data, so the procedure will THROW
        var response = await _client.GetAsync("/api/branches/BR99999999");
        Assert.Equal(HttpStatusCode.NotFound , response.StatusCode);
    
        var responseText = await response.Content.ReadAsStringAsync();
        using var body = JsonDocument.Parse(responseText);

        var success = body.RootElement.GetProperty("success").GetBoolean();
        Assert.False(success);

        // error.code must be the exact number thrown by sp_get_branch_get_info (53000)
        var error = body.RootElement.GetProperty("error");
        Assert.Equal(53000 , error.GetProperty("code").GetInt32());
        Assert.Equal("branch" , error.GetProperty("domain").GetString());
    }
}