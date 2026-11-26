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

    public async Task<string> GetLatestUnverifiedOtpCodeAsync(long accountId , string purpose)
    {
        await using var connection = new SqlConnection(m_connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand (
            @"  SELECT TOP 1 otp_code
                FROM OTP
                WHERE account_id = @accountId 
                    AND purpose = @purpose 
                    AND verified = 0
                ORDER BY otp_id DESC",
            connection
        );
        command.Parameters.AddWithValue("@accountId" , accountId);
        command.Parameters.AddWithValue("@purpose" , purpose);

        return (string)(await command.ExecuteScalarAsync())!;
    }
    
    // Whether the newest OTP of this account has been accepted by the verify endpoint
    public async Task<bool> IsLastestVerifiedAsync(long accountId , string purpose)
    {
        await using var connection = new SqlConnection(m_connectionString);
        await connection.OpenAsync();

        await using var command = new SqlCommand(
            @"  SELECT TOP 1 verified
                FROM OTP
                WHERE account_id = @accountId
                    AND purpose = @purpose
                ORDER BY otp_id DESC",
            connection
        );
        command.Parameters.AddWithValue("@accountId" , accountId);
        command.Parameters.AddWithValue("@purpose" , purpose);

        return (bool)(await command.ExecuteScalarAsync())!;
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