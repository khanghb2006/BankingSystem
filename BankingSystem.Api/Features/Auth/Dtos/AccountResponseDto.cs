namespace BankingSystem.Api.Features.Auth.Dtos;

public record AccountResponseDto (
    long AccountId,
    string Username,
    string Email,
    string PhoneNumber,
    string Role,
    string Status,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);