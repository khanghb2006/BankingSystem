namespace Backend.Auth.Dto;

using System.ComponentModel.DataAnnotations;

/*
    What the client sends to POST api/auth/activate - the account whose "Register"
    OPT has just been verified and then change the status from "Pending" to "Active"
*/
public record ActivateRequest (
    [Required] long AccountId
);