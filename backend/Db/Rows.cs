namespace Backend.Db;

using Microsoft.Data.SqlClient;

/**
    Convert the rows of a SqlDataReader into a list of dictionaries (column name -> value)
        and provides type-safe accessors matching data contact
    (NCHAR columns must be trimmed, money must be rounded to 2 decimal)  
*/
public static class Rows {
    /**
        Reads all remaining rows from the reader to a list of dictionaries
        Uses OrdinalIgnoreCase for keys s so column can be looked up case-insensitively

        @param reader The SqlDataReader to read from
        @return List of rows
    */
    public static async Task<List<Dictionary<string , object?>>> ToMapsAsync(SqlDataReader reader)
    {
        var rows = new List<Dictionary<string , object?>>();

        while (await reader.ReadAsync()) {
            var row = new Dictionary<string , object?>(StringComparer.OrdinalIgnoreCase);

            for (int columnIndex = 0; columnIndex < reader.FieldCount; columnIndex++) {
                string columnName = reader.GetName(columnIndex);
                row[columnName] = reader.IsDBNull(columnIndex) ? null :
                    reader.GetValue(columnIndex);
            }

            rows.Add(row);
        }
        return rows;
    }

    /**
        Read a column as a trimmed string. Required for NCHAR columns
    */
    public static string? Str(Dictionary<string , object?> row , string columnName) 
    {
        var value = row.GetValueOrDefault(columnName);
        return value?.ToString()?.Trim();
    }

    // Read a BIGINT colummn
    public static long? Lng(Dictionary<string , object?> row , string columnName)
    {
        var value = row.GetValueOrDefault(columnName);
        return value is null ? null : Convert.ToInt64(value);
    }

    // Read a money column, rounding to 2 decimal places
    public static decimal? Money(Dictionary<string , object?> row , string columnName)
    {
        var value = row.GetValueOrDefault(columnName);
        if (value is null) return null;

        decimal amount = Convert.ToDecimal(value);
        return Math.Round(amount , 2 , MidpointRounding.AwayFromZero);
    }

    // Read DATETIME column
    public static DateTime? Dt(Dictionary<string , object?> row, string columnName)
    {
        var value = row.GetValueOrDefault(columnName);
        return value as DateTime?;
    }
}
