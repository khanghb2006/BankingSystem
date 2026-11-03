using BankingSystem.Api.Domain;
namespace BankingSystem.Api.Features.Branches;

/*
    Contract of the Branches feature. Other features
        depend on this interface 
*/
public interface IBranchService
{
    Task<List<Branch>> SearchAsync
        (string? name , string? status, CancellationToken cancellation);

    Task<Branch> GetByIdAsync
        (string branchId, CancellationToken cancellation);
}

