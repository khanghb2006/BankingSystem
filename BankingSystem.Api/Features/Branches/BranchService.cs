using BankingSystem.Api.Domain;

namespace BankingSystem.Api.Features.Branches;

// Read-only branch uses cases for now
public class BranchService(BranchRepository repository) 
    : IBranchService
{
    public async Task<List<Branch>> SearchAsync (
        string? name,
        string? status,
        CancellationToken cancellation)
    {
        return await repository.SearchAsync(name , status, cancellation);
    }

    public async Task<Branch> GetByIdAsync(
        string branchId,
        CancellationToken cancellation)
    {
        return await repository.GetByIdAsync(branchId, cancellation);
    }
}