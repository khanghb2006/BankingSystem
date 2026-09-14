namespace Backend.Branch.Dto;
using System.ComponentModel.DataAnnotations;

/*
    What the client sends in the request body of POST api/branches
    The [Required] / [MaxLength] attributes run automatically brefore Create() is even
        called ASP.NET Core reject an invalid request with outr ApiResponse envelope
*/
public record CreateBranchRequest(
    [Required , MaxLength(100)] string BranchName,
    [Required , MaxLength(100)] string Address,
    [Required , MaxLength(100)] string PhoneNumber
);