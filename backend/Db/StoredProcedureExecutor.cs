namespace Backend.Db;

using System.Data;
using Microsoft.Data.SqlClient;

/**
    The ONLY point of contact between the backend and dbo.sp_* 
    No other class is allowed to 'using Microsoft.Data.SqlClient' - every service calls
        procs through this class. 
    Each call opens and closes its own connection (no shared/pooled connection)
*/
public sealed class StoredProcedureExecutor
{
    private readonly string _connectionString;

    public StoredProcedureExecutor(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("BankingSystem");
        if (connectionString is null) 
            throw new InvalidOperationException("Connection string 'BankingSystem' not found.");
        _connectionString = connectionString;
    }

    /*
        Call dbo.<procedureName> with named parameters and return 
            the result as a list of rows (column name -> value)
        A null value is automatically converted to DBNull.

        @param procedureName without the 'dbo.' prefix ("dbo." is added automatically)

        @param parameters Dictionary of parameter name -> value

        @return Rows returned by the the stored procedure, each row in a dictionary 
            of column name to value

        @throws SqlException when the stored procedure throws a business error
    */
    public async Task<List<Dictionary<string , object?>>> CallAsync
        ( string procedureName , params(string ParameterName , object? Value)[] parameters)
    {
        await using var connection = new SqlConnection(_connectionString);
        await using var command = new SqlCommand($"dbo.{procedureName}" , connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        foreach(var (parameterName , value) in parameters)
        {
            command.Parameters.AddWithValue(parameterName , value ?? DBNull.Value);
        }

        await connection.OpenAsync();

        await using var reader = await command.ExecuteReaderAsync();
        return await Rows.ToMapsAsync(reader);
    }

    /*
        Same as CallAsync but returns only the first row - used for create/update/get 
            endpoints , where the stored procedure returns exactly one row
            plus a message column

        @throws InvalidOperationException if the stored procedure returns 0 row.
    */
    public async Task<Dictionary<string , object?>> OneAsync
        (string procedureName , params(string ParameterName , object? value) [] parameters)
    {
        var rows = await CallAsync(procedureName , parameters);
        if (rows.Count == 0) 
            throw new InvalidOperationException($"{procedureName} returned 0 rows, expected exactly 1.");
        
        return rows[0];
    }
    
    // Read the message column that every stored procedure returns on success
    public string? Message(Dictionary<string , object?> row)
    {
        if (row.TryGetValue("message" , out var message) && message is not null) 
            return message.ToString();
        
        return null;
    }
}