namespace BankingSystem.Api.Data;

/* 
    One row of a stored procedure result set: 
        column name -> value
    It lets repositories read results without referencing any SqlClient type
*/
public class ResultRow
{
    private readonly Dictionary<string , object?> values;

    public ResultRow(Dictionary<string , object?> values)
    {
        this.values = values;
    }

    // Read a column and casts it to the expected C# type
    public T Get<T>(string columnName)
    {
        var value = values[columnName];
        return (T)value!;
    }
}