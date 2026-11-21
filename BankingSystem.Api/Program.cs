using BankingSystem.Api.Data;
using Microsoft.AspNetCore.Mvc;
using BankingSystem.Api.Common;
using BankingSystem.Api.Features.Auth;
using BankingSystem.Api.Features.Branches;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers()
    .AddJsonOptions(options =>
     {
         options.JsonSerializerOptions.Converters.Add(new DecimalAsStringConverter());
         options.JsonSerializerOptions.Converters.Add(new DateTimeNoOffsetConverter());
     })
    .ConfigureApiBehaviorOptions(options =>
    {
        options.InvalidModelStateResponseFactory = context =>
        {
            var invalidFields = context.ModelState
                .Where(entry => entry.Value?.Errors.Count > 0)
                .Select(entry => string.IsNullOrEmpty(entry.Key) ? "body" : entry.Key);

            var message = "Invalid input: " + string.Join(", ", invalidFields);
            var error = new ApiError(StatusCodes.Status400BadRequest, "validation");

            return new BadRequestObjectResult(ApiResponse<object>.Fail(message, error));
        };
    });

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

// Register the global handler so exceptions become the standard JSON evenlope
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddProblemDetails();
builder.Services.AddSingleton<StoredProcedureExecutor>();


// Scoped : on instance per HTTP Request
builder.Services.AddScoped<BranchRepository>();
builder.Services.AddScoped<IBranchService, BranchService>();
builder.Services.AddScoped<AuthRepository>();
builder.Services.AddScoped<IAuthService, AuthService>();

var app = builder.Build();

app.UseMiddleware<CorrelationIdMiddleware>();
app.UseExceptionHandler();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    
    // UI for testing API endpoints
    app.UseSwaggerUI(options =>
        options.SwaggerEndpoint("/openapi/v1.json", "BankingSystem API v1"));
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();


public partial class Program {}
