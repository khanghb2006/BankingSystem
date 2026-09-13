namespace Backend.Common;

/*  Lookup table : SQL Server throws error number -> which business domain 
        -> which HTTP status returns to
    Why needed: stored procedures use throws code number but HTTP has no build-in concept
    
    So we have to decide ourselves whether that code should map to 409 Conflict
        or 404 Not Found
*/
public static class SqlErrorCatalog
{
    // Lookup result: Domain for loogin /debugging. Status is the actual HTTP status returned
    // to the clients
    public record Entry (string Domain , int Status);

    // Band of error codes
    private record Band(int Lo , int Hi , string Domain , int Status);

    // Band List
    private static readonly List<Band> Bands =
    [
        new( 51000,  56999, "branch",           StatusCodes.Status409Conflict),
        new( 61000,  64999, "card",             StatusCodes.Status409Conflict),
        new( 71000,  76999, "customer",         StatusCodes.Status409Conflict),
        new( 81000,  87999, "employee",         StatusCodes.Status409Conflict),
        new( 91000,  96999, "loan",             StatusCodes.Status409Conflict),
        new(101000, 102999, "login_history",    StatusCodes.Status400BadRequest),
        new(110000, 110999, "account",          StatusCodes.Status409Conflict),
        new(111000, 114999, "notification",     StatusCodes.Status409Conflict),
        new(120000, 120999, "account",          StatusCodes.Status409Conflict),
        new(121000, 122999, "otp",              StatusCodes.Status422UnprocessableEntity),
        new(130000, 159999, "account",          StatusCodes.Status409Conflict),
        new(160000, 179999, "admin",            StatusCodes.Status409Conflict),
        new(210000, 279999, "bank_transaction", StatusCodes.Status409Conflict),
        new(310000, 349999, "banking_account",  StatusCodes.Status409Conflict),
        new(350000, 359999, "saving_account",   StatusCodes.Status409Conflict),
        new(410000, 449999, "beneficiary",      StatusCodes.Status409Conflict),
    ];

    // Main Entry point: give it a SQL error number, get back the matching domain + HTTP status.
    public static Entry Lookup(int code)
    {
        if (code < 50000)
            return new Entry("system" , StatusCodes.Status500InternalServerError);

        // Find the band that contains the code
        foreach (var band in Bands)
        {
            bool codeIsInsideBand = (code >= band.Lo) && (code <= band.Hi);
            if (codeIsInsideBand)
                return new Entry(band.Domain, band.Status);
        }
        return new Entry("business" , StatusCodes.Status422UnprocessableEntity);
    }
}
