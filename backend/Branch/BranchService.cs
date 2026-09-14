namespace Backend.Branch;

using Backend.Branch.Dto;
using Backend.Common;
using Backend.Db;

/*
    Take a validated request and then calls the matching stored procedure
    Must be map the raw database row into a typed response
*/
public sealed class BranchService (StoredProcedureExecutor storedProcedureExecutor)
{
    public async Task<ApiResponse<BranchResponse>> CreateAsync(CreateBranchRequest request)
    {
        // OneAsync call dbo.sp_branch_create and returns its first result row
        Dictionary<string , object?> row = await storedProcedureExecutor.OneAsync(
            "sp_branch_create",
            ("@branch_name" , request.BranchName),
            ("@address" , request.Address),
            ("@phone_number" , request.PhoneNumber)
        );

        string? message = storedProcedureExecutor.Message(row);
        
        BranchResponse branch = MapRowToResponse(row);

        return ApiResponse<BranchResponse>.Ok(message , branch);
    }

    // Convert one raw database row into a strongly typed BranchResponse 
    private static BranchResponse MapRowToResponse(Dictionary<string , object?>row)
    {
        string branchId = Rows.Str(row , "branch_id")!;
        string branchName = Rows.Str(row , "branch_name")!;
        string address = Rows.Str(row , "address")!;
        string phoneNumber = Rows.Str(row , "phone_number")!;
        DateTime? createdAt = Rows.Dt(row , "created_at");
        DateTime? updatedAt = Rows.Dt(row , "updated_at");
        string status = Rows.Str(row , "status")!;

        return new BranchResponse(branchId , branchName , address , phoneNumber , createdAt , updatedAt , status);
    }
}