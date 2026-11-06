using BankingSystem.Api.Domain;

namespace BankingSystem.Api.Features.Branches;

// Read-only branch uses cases for now
public class BranchService : IBranchService
{
    private readonly BranchRepository m_repository;

    public BranchService(BranchRepository repository)
    {
        this.m_repository = repository;
    }

    public async Task<List<Branch>> SearchAsync (
        string? name,
        string? status,
        CancellationToken cancellation)
    {
        return await m_repository.SearchAsync(name , status, cancellation);
    }

    public async Task<Branch> GetByIdAsync(
        string branchId,
        CancellationToken cancellation)
    {
        return await m_repository.GetByIdAsync(branchId, cancellation);
    }
}