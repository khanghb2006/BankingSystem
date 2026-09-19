namespace Backend.Auth.Dto;

/*
    What the client receives back from a successfull login: the JWT to attach as
        "Authorization : Bearer <tolen>" on future requests, plus the accound info itself
        so the frontend can show it right away without an extra /me call.
*/
public record LoginResponse(
    string Token,
    AccountResponse Account
);