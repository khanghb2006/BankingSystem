using System.Data;
using BankingSystem.Api.Common;
using Microsoft.Data.SqlClient;

namespace BankingSystem.Api.Data;

/*
    The single entry point to SQL Server
        + call stored procedures by name with named
        + Parameters and returns it rows
*/
public class StoredProcedureExecutor
{
    private readonly string m_connectionString;

    public StoredProcedureExecutor(IConfiguration config)
    {
        this.m_connectionString = config.GetConnectionString("BankingSystem")   
            ?? throw new InvalidOperationException("Missing connection string 'BankingSystem'");
    }

    /*
        procedureName : e.g "dbo.sp_branch_get_info"
        parameters : keys include the '@' prefix e.g @branch_id
    */
    public async Task<List<ResultRow>> QueryAsync (
        string procedureName,
        Dictionary<string , object?>? parameters = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // The connection is opened per call and return to the pool on dispose
            await using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);

            await using var command = new SqlCommand(procedureName , connection);
            command.CommandType = CommandType.StoredProcedure;

            if (parameters is not null)
            {
                foreach (var parameter in parameters)
                {
                    // null C# must be converted to DBNull
                    command.Parameters.AddWithValue(parameter.Key , parameter.Value ?? DBNull.Value);
                }
            }

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);

            var rows = new List<ResultRow>();
            while(await reader.ReadAsync(cancellationToken))
            {
                var values = new Dictionary<string , object?>();
                
                for (var column = 0; column < reader.FieldCount; column++)
                {
                    values[reader.GetName(column)] = reader.IsDBNull(column) 
                        ? null : reader.GetValue(column);
                }
                rows.Add(new ResultRow(values));
            }
            return rows;
        }
        catch (SqlException ex)
        {
            // Wrap the SqlException in a ProcedureException so the global handler can
            // turn it into the standard JSON envelope.
            throw new ProcedureException(ex.Number , ex.Message , ex);
        }
    }
}