using Microsoft.Data.SqlClient;

namespace BankingSystem.Tests;


/* 
    Read the real database directly only to verify what the API must never reveal
    Test code only: production code changes data through stored procedures alone
*/
public class TestDatabase
{
    private readonly string m_connectionString;

    public TestDatabase(string connectionString)
    {
        this.m_connectionString = connectionString;
    }

    // The hash stored for an account. The API never returns it
    public async Task<string> GetPasswordHashAsync(long accountId)
    {
        return await ScalarAsync<string> (
            "SELECT password_hash FROM Account WHERE account_id = @accountId",
            accountId
        );
    }

    public async Task<string> GetAccountStatusAsync(long accountId)
    {
        return await ScalarAsync<string> (
            "SELECT status FROM Account WHERE account_id = @accountId",
            accountId
        );
    }

    private async Task<T> ScalarAsync<T>(string sql , long accountId)
    {
        await using var connection = new SqlConnection(m_connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(sql , connection);
        command.Parameters.AddWithValue("@accountId" , accountId);

        var result = await command.ExecuteScalarAsync();
        return (T)result!;
    }
}