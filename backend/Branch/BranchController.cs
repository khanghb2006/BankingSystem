namespace Backend.Branch;

using Microsoft.AspNetCore.Mvc;
using Backend.Branch.Dto;
using Backend.Common;

/* 
    Receives HTTP requests for api/branches and delegates straight to BranchService.
*/
[ApiController]
[Route("api/branches")]
public sealed class BranchController (BranchService branchService) : ControllerBase
{
    [HttpPost]
    public async Task<ApiResponse<BranchResponse>> Create([FromBody] CreateBranchRequest request)
    {
        ApiResponse<BranchResponse> response = await branchService.CreateAsync(request);
        return response;
    }
}