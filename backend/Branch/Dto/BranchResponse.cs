namespace Backend.Branch.Dto;

/*
    What the client receives back. Mirrors the 7 columns of vw_Branch 
*/
public record BranchResponse (
    string BranchId,
    string BranchName,
    string Address,
    string PhoneNumber,
    DateTime? CreatedAt,
    DateTime? UpdatedAt,
    string status
);