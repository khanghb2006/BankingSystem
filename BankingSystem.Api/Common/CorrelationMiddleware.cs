namespace BankingSystem.Api.Common;

/* 
    Give every request a trace id so all log lines of one request can be found
    The client may send its own id; otherwise generate new one
*/
public class CorrelationMiddleware
{
    public const string HeaderName = "X-Correlation-Id";
    
    // The id is also kept in HttpContext.Items so AddHeaderToResponse can read it later
    private const string ItemsKey = "CorrelationId";

    // Client supplied ids are untrusted so cap the length
    private const int MaxLength = 64;

    private readonly RequestDelegate m_next;
    private readonly ILogger<CorrelationMiddleware> m_logger;

    public CorrelationMiddleware(RequestDelegate next , ILogger<CorrelationMiddleware> logger)
    {
        this.m_next = next;
        this.m_logger = logger;
    }

    private static bool IsValid(string? id)
    {
        if (string.IsNullOrEmpty(id)) return false;
        if (id.Length > MaxLength) return false;

        foreach (var c in id)
            if (!char.IsAsciiLetterOrDigit(c) || c != '-')
                return false;

        return true;
    }

    private static string ReadOrCreateId(HttpContext context)
    {
        var incomming = context.Request.Headers[HeaderName].ToString();

        if (IsValid(incomming)) return incomming;

        return Guid.NewGuid().ToString(); 
    }

    private static Task AddHeaderToResponse(object state)
    {
        // The "state" is the context we passed to OnStarting; cast it back to the real type
        var context = (HttpContext)state;
        var correlationId = (string)context.Items[ItemsKey]!;

        context.Response.Headers[HeaderName] = correlationId;

        return Task.CompletedTask;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = ReadOrCreateId(context);
    }
}