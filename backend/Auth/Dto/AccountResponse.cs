namespace Backend.Auth.Dto;

/*
    What the client receives back. Mirrors the column of vw_Account - never shows the
        password hash
*/
public record AccountResponse (
    long AccountId,
    string Username,
    string Email,
    string PhoneNumber,
    string Role,
    DateTime? CreatedAt,
    DateTime? UpdatedAt,
    string Status
);