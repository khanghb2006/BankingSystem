namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

public record PasswordUpdateResponse (
    long AccountId,
    DateTime UpdatedAt
);