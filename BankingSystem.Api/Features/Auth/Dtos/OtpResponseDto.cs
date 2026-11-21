namespace BankingSystem.Api.Features.Auth.Dtos;

public record OtpResponseDto (
    long OtpId,
    DateTime ExpiresAt
);