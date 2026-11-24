using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BankingSystem.Tests;

// Smoke test to ensure that the application starts up correctly
public class SwaggerSmokerTests(WebApplicationFactory<Program> factory)
    : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task SwaggerUI_ReturnsOk()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/swagger/index.html");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}