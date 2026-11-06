using BankingSystem.Api.Data;
using BankingSystem.Api.Domain;

namespace BankingSystem.Api.Features.Branches;

/*
    One method per stored procedure. It only maps rows
        to domain objects
*/
public class BranchRepository
{
    private readonly StoredProcedureExecutor m_executor;

    public BranchRepository(StoredProcedureExecutor executor)
    {
        this.m_executor = executor;
    }
    // dbo.sp_branch_search: both parameters are optional (null = no filter)
    public async Task<List<Branch>> SearchAsync(
        string? name,
        string? status,
        CancellationToken cancellationToken)
    {
        var parameters = new Dictionary<string , object?>
        {
            ["@branch_name"] = name,
            ["@status"] = status
        };

        var rows = await m_executor.QueryAsync(
            "dbo.sp_branch_search",
            parameters,
            cancellationToken);

        var branches = new List<Branch>();
        foreach (var row in rows) 
            branches.Add(ToBranch(row));

        return branches;
    }

    /* 
        dbo.sp_branch_get_info: throws 5300 when the id does not exists
        so reaching the next line means the branch was found
    */
    public async Task<Branch> GetByIdAsync(string branchId, CancellationToken cancellation)
    {
        var parameters = new Dictionary<string , object?>
        {
            ["@branch_id"] = branchId
        };

        var rows = await m_executor.QueryAsync(
            "dbo.sp_branch_get_info",
            parameters,
            cancellation);

        return ToBranch(rows[0]);
    }

    private static Branch ToBranch(ResultRow row)
    {
        return new Branch(
            Id : row.Get<string>("branch_id").Trim(),
            Name : row.Get<string>("branch_name").Trim(),
            // address is nullable in the schema, and NVARCHAR is never padded, so read it as-is
            Address : row.Get<string?>("address"),
            PhoneNumber : row.Get<string>("phone_number").Trim(),
            CreatedAt : row.Get<DateTime>("created_at"),
            UpdatedAt : row.Get<DateTime?>("updated_at"),
            Status : row.Get<string>("status").Trim()
        );
    }
    
}