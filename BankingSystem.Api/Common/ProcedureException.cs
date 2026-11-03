namespace BankingSystem.Api.Common;

// Thrown by the Data layer when a stored procedure fails.
// It carries the procedure's error number so upper layers never depend on SqlClient types.
public class ProcedureException(int errorNumber, string message, Exception innerException)
    : Exception(message, innerException)
{
    public int ErrorNumber { get; } = errorNumber;
}
