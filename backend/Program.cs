using Backend.Db;
using Backend.Common;
using System.Text.Json;
using Backend.Branch;
using Backend.Auth;
using Backend.Security;
using Microsoft.AspNetCore.Identity;

var builder = WebApplication.CreateBuilder(args);

// Register controllers, and customize how JSON is written for every response
builder.Services.AddControllers().AddJsonOptions(options =>
{
    // C# Field are PascalCase (BranchName) so JSON convertion is camelCase(branchName)
    options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    options.JsonSerializerOptions.Converters.Add(new DecimalAsStringConverter());
    options.JsonSerializerOptions.Converters.Add(new DateTimeNoOffsetConverter());
});

/*
    When [Required] / [MaxLenght] validation on a request DTO fails, ASP.NET Core 
    automatically returns its own default error shape.
    This replaces that with our own ApiResponse envelope, so all errors are consistent.
*/
builder.Services.Configure<Microsoft.AspNetCore.Mvc.ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        // Walk every field in the ModelState dictionary and keep only the ones that failed
        // Validation (e.g [Required] on an empty branchName), building one to readable message
        var errorMessages = new List<string>();

        foreach (var entry in context.ModelState)
        {
            string fieldName = entry.Key;
            var fieldState = entry.Value;

            // That field passed validation, skip it
            if (fieldState is null || fieldState.Errors.Count == 0) continue;

            string firstErrorMessage = fieldState.Errors[0].ErrorMessage;
            errorMessages.Add($"{fieldName}: {firstErrorMessage}");
        }

        string combinedMessage = string.Join("; " , errorMessages);
        var errorBody = ApiResponse<object>.Fail(combinedMessage , 
            new ApiError(400 , "validation"));
        
        return new Microsoft.AspNetCore.Mvc.BadRequestObjectResult(errorBody);
    };
});

/*
    AddScoped : one StoredProcedureExecutor instance per HTTP request. 
    It only holds the connection string (not a real open connection), so creating one per 
        request is cheap and safe.
*/
builder.Services.AddScoped<StoredProcedureExecutor>();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddProblemDetails(); // required plumbing for AddExceptionHandler to work
builder.Services.AddScoped<BranchService>();


/* 
    Auth wiring
    JwtOptions is read once at startup from the "Jwt" section (Secret comes from 
        appsettings.Development.json , TtlMinutes from appsettings.json)
*/
JwtOptions jwtOptions = builder.Configuration
    .GetSection(JwtOptions.SectionName)
    .Get<JwtOptions>()!;

// Fail fast : a missing secret would otherwise only blow up on the first login
if (string.IsNullOrWhiteSpace(jwtOptions.Secret))
    throw new Exception("Jwt:Secret is not configured.");

builder.Services.AddSingleton(jwtOptions);
builder.Services.AddSingleton<JwtIssuer>();
builder.Services.AddSingleton<PasswordHasher<object>>();
builder.Services.AddScoped<AuthService>();


// Allow the React dev server (different port = different origin) to call this API
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy (policy =>
    {
        string allowOrigin = builder.Configuration["Cors:AllowedOrigin"]!;
        policy.WithOrigins(allowOrigin);
        policy.WithMethods("GET" , "POST" , "PUT" , "DELETE");
        policy.WithExposedHeaders("X-Total-Count");
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseExceptionHandler(applicationBuilder => { }); // Activate ApiExceptionHandler 
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();
app.MapControllers();

app.Run();

public partial class Program { } // for integration tests to access the WebApplicationFactory