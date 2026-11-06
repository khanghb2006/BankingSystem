namespace BankingSystem.Api.Common;

// Thrown by the Data layer when a stored procedure fails.
// It carries the procedure's error number so upper layers never depend on SqlClient types.
public class ProcedureException : Exception
{
   private readonly int m_errorNumber;

   public int ErrorNumber
    {
        get { return m_errorNumber; }
    }

    public ProcedureException(int errorNumber , string message , Exception innerException) 
        : base(message , innerException)
    {
        this.m_errorNumber = errorNumber;
    }


}
