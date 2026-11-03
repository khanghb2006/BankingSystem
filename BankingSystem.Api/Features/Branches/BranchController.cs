using BankingSystem.Api.Common;
using BankingSystem.Api.Features.Branches.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace BankingSystem.Api.Features.Branches;

/*
    Public branch endpoints
    No logic hear just map the route and call service
*/
[ApiController]
[Route("api/branches")]
public class BranchController(IBranchService branchService)
    : ControllerBase
{
    // GET api/branches?name=...&status=...&page=...&size=...
    [HttpGet]
    public async Task<ApiResponse<List<BranchResponseDto>>> Search (
        [FromQuery] string? name,
        [FromQuery] string? status,
        [FromQuery] int page = 0,
        [FromQuery] int size = Pagination.DefaultPageSize,
        CancellationToken cancellation = default)
    {
        var branches = await branchService.SearchAsync
            (name , status, cancellation);

        // The total counts every match, not only the current page
        Response.Headers["X-Total-Count"] = branches.Count.ToString();

        var data = new List<BranchResponseDto>();
        foreach (var branch in Pagination.Slice(branches, page , size)) 
            data.Add(BranchResponseDto.From(branch));
        
        return ApiResponse<List<BranchResponseDto>>.Ok(data);
    }

    // GET api/branches/{Id}
    [HttpGet("{Id}")]
    public async Task<ApiResponse<BranchResponseDto>> GetById (
        string id,
        CancellationToken cancellation)
    {
        var branch = await branchService.GetByIdAsync(id, cancellation);
        return ApiResponse<BranchResponseDto>.Ok(BranchResponseDto.From(branch));
    }
    
}