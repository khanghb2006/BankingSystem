using BankingSystem.Api.Domain;

namespace BankingSystem.Api.Features.Branches.Dtos;

/*
    Shape of a branch in API responses. Property names become camelCase in JSON.
    (branchId , branchName, ...) following api_contract
*/
public record BranchResponseDto (
    string BranchId,
    string BranchName,
    string? Address,
    string PhoneNumber,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    string Status)
{
    public static BranchResponseDto From(Branch branch)
    {
        return new BranchResponseDto(
            branch.Id,
            branch.Name,
            branch.Address,
            branch.PhoneNumber,
            branch.CreatedAt,
            branch.UpdatedAt,
            branch.Status
        );
    }
}