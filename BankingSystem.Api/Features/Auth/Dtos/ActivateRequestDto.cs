using System.ComponentModel.DataAnnotations;

namespace BankingSystem.Api.Features.Auth.Dtos;
/*
    Body of POST /api/auth/activate. Only the account id is sent: the stored procedure
        will check it inside the databse
*/
public record ActivateRequestDto (
    [Range(1 , long.MaxValue)] long AccountId
);