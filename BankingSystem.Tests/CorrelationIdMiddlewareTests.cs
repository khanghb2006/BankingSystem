using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace BankingSystem.Tests;

/*
    Task 25 : integrationg tests for CorrelationIdMiddleware
    Call real API in memory and check only what client can see
*/
public class CorrelationIdMiddlewareTests : IClassFixture<WebApplicationFactory<Program>>
{
     // Written as a literal on purpose: it is the contract with clients,
    // so renaming the header in the middleware must make these tests fail
    private const string HeaderName = "X-Correlation-Id";

    private readonly HttpClient m_client;

    public CorrelationIdMiddlewareTests(WebApplicationFactory<Program> factory)
    {
        m_client = factory.CreateClient();
    }

    // No id from the client : the middleware must generate one
    [Fact]
    public async Task Request_WithoutHeader_GetsGeneratedGuid()
    {
        var response = await m_client.GetAsync("/api/branches");

        // Single() fails the test if the header is missing or repeated
        var correlationId = response.Headers.GetValues(HeaderName).Single();
        Assert.True(Guid.TryParse(correlationId, out _));
    }

    // A safe id from the client is reused so a frontend can follow its own request in the log
    [Fact]
    public async Task Request_WithValidHeader_GetsSameValueBack()
    {
        var response = await SendWithCorrelationIdAsync("/api/branches" , "my-trace-123");
        Assert.Equal("my-trace-123" , response.Headers.GetValues(HeaderName).Single());
    }

    // Unsafe ids must be thrown away
    [Theory]
    [InlineData("has space")]
    [InlineData("semi;colon")]
    [InlineData("back\\slash")]
    public async Task Request_WithUnsafeHeader_GetsNewGuid(string unsafeId)
    {
        var response = await SendWithCorrelationIdAsync("/api/branches" , unsafeId);

        var correlationId = response.Headers.GetValues(HeaderName).Single();
        Assert.NotEqual(unsafeId , correlationId);
        Assert.True(Guid.TryParse(correlationId, out _));
    }

    // Boundary check : the middleware accepts at most 64 characters
    [Fact]
    public async Task Request_WithTooLongHeader_GetsNewGuid()
    {
        var tooLong = new string('x' , 65);
        var response = await SendWithCorrelationIdAsync("/api/branches" , tooLong);

        var correlationId = response.Headers.GetValues(HeaderName).Single();
        Assert.NotEqual(tooLong , correlationId);
    }

    // The exception handler clears the response when an error happens
    [Fact]
    public async Task ErrorResponse_AlsoHasHeader()
    {
        // this id does not exist so the procedure throws the exception
        var response = await m_client.GetAsync("/api/branches/BR99999999");

        Assert.Equal(HttpStatusCode.NotFound , response.StatusCode);
        Assert.True(response.Headers.Contains(HeaderName));
    }

    private async Task<HttpResponseMessage> SendWithCorrelationIdAsync(string url , string correlationId)
    {
        var request = new HttpRequestMessage(HttpMethod.Get , url);
        request.Headers.TryAddWithoutValidation(HeaderName , correlationId);

        return await m_client.SendAsync(request);
    }
}