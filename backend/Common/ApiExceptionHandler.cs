namespace Backend.Common;

using Microsoft.Data.SqlClient;
using Microsoft.AspNetCore.Diagnostics;

// IExceptionHandler: built-in ASP.NET Core hook (since .NET 8) — register it once in Program.cs
// (builder.Services.AddExceptionHandler<ApiExceptionHandler>()) and no Controller/Service needs
// try/catch anymore. Just throw, this catches it and turns it into JSON.

public sealed class ApiExceptionHandler : IExceptionHandler
{
    // ASP.NET Core calls this whenever an exception escapes a request unhandled.
    // Return true  = "I handled it, don't do anything else".
    // Return false = "not my job" → falls through to ASP.NET Core's default error handling.
    
    public async ValueTask<bool> TryHandleAsync(HttpContext ctx , Exception ex , CancellationToken ct)
    {
        // Only care about errors comming from SQL Server(stored procedures throws)
        if (ex is not SqlException sql) return false;

        // Lookup the domain + HTTP status from SqlErrorCatalog
        var entry = SqlErrorCatalog.Lookup(sql.Number);
        
        // SqlException message usually has a trailing "\r\nLine42" - take only first line
        var msg = sql.Message.Split('\n')[0];

        // Override to 404 when the message itself says "does not exits"
        var status = msg.Contains("does not exists" , StringComparison.OrdinalIgnoreCase)
            || msg.Contains("Invalid" , StringComparison.OrdinalIgnoreCase)
            ? StatusCodes.Status404NotFound
            : entry.Status;

        ctx.Response.StatusCode = status;

        // Return JSON using the same ApiResponse envelope every other endpoint uses
        await ctx.Response.WriteAsJsonAsync(
            ApiResponse<object>.Fail(msg , new ApiError(sql.Number , entry.Domain)), ct
        );

        return true;
    }
}