namespace BankingSystem.Api.Domain;

/* 
    A bank branch as stored in the database
    Status holds the raw lookup value exactly as in api_contract (Acitve or Closed)
*/

public record Branch(
    string Id,
    string Name,
    string? Address,
    string PhoneNumber,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    string Status
);

