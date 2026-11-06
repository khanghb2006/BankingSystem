using Microsoft.AspNetCore.Diagnostics;

namespace BankingSystem.Api.Common;

// Global exception handler (IExceptionHandler, built into ASP.NET Core since .NET 8).
// Controllers and services never need try/catch: they just throw, and this turns the
// exception into the standard error envelope.
public sealed class ApiExceptionHandler : IExceptionHandler
{
    // THROW in T-SQL only accepts numbers >= 50000, so these are the procedures' business errors.
    private const int FirstBusinessErrorNumber = 50000;

    private readonly ILogger<ApiExceptionHandler> m_logger;
    public ApiExceptionHandler(ILogger<ApiExceptionHandler> logger)
    {
        this.m_logger = logger;
    }

    // Returning true tells ASP.NET Core the exception is handled and nothing else should run.
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        int statusCode;
        string message;
        ApiError error;

        if (exception is ProcedureException procedureException
            && procedureException.ErrorNumber >= FirstBusinessErrorNumber)
        {
            // Business error raised by a procedure: the message is safe to show to the client.
            var info = SqlErrorCatalog.Lookup(procedureException.ErrorNumber);

            message = procedureException.Message;
            error = new ApiError(procedureException.ErrorNumber, info.Domain);
            statusCode = info.HttpStatus;

            // api_contract section 2: "does not exist" / "Invalid" always means 404.
            if (message.Contains("does not exist", StringComparison.OrdinalIgnoreCase)
                || message.Contains("Invalid", StringComparison.OrdinalIgnoreCase))
            {
                statusCode = StatusCodes.Status404NotFound;
            }
        }
        else
        {
            // Unexpected failure (database down, bug...). Details go to the log only;
            // the client gets a generic message so no server internals leak.
            logger.LogError(
                exception,
                "Unhandled exception for {Method} {Path}",
                httpContext.Request.Method,
                httpContext.Request.Path);

            message = "An unexpected error occurred.";
            error = new ApiError(StatusCodes.Status500InternalServerError, "system");
            statusCode = StatusCodes.Status500InternalServerError;
        }

        httpContext.Response.StatusCode = statusCode;
        await httpContext.Response.WriteAsJsonAsync(
            ApiResponse<object>.Fail(message, error),
            cancellationToken);

        return true;
    }
}
