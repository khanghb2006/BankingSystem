using System.ComponentModel.DataAnnotations;
namespace BankingSystem.Api.Features.Auth.Dtos;

/*
    Body of POST /api/auth/register. Every field is validated at the API boundary so
        malformed or oversized requests
    There is deliberately no role or status field: a client can never choose them and the
        the stored procedure always creates a Customer in Pending status. 
*/

public record RegisterRequestDto(
    // \z (not $) because $ also matches before a trailing newline, which would let "bob\n" through
    [property: Required, RegularExpression(@"^[A-Za-z0-9_.]{3,50}\z")] string Username,
    [property: Required, EmailAddress, MaxLength(100)] string Email,
    [property: Required, RegularExpression(@"^[0-9]{9,20}\z")] string PhoneNumber,
    [property: Required, StringLength(128, MinimumLength = 8)] string Password)
{
    // The compiler-generated ToString of a record prints every member, so logging this object
    // would write the plaintext password into the log. Override it to print the username only.
    public override string ToString()
    {
        return $"RegisterRequestDto {{ Username = {Username} }}";
    }
}