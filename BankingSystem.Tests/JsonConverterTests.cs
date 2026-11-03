using System.Text.Json;
using BankingSystem.Api.Common;

namespace BankingSystem.Api;

/*
    unit tests for the JSON converter that enforce the data-format contract
    Pure logic : no HTTP , no database
*/

public class JsonConverterTests
{
    // Builds serializer options with only the convertes under test registers
    private static JsonSerializerOptions CreateOptions()
    {
        var options = new JsonSerializerOptions();
        options.Converters.Add(new DecimalAsStringConverter());
        options.Converters.Add(new DateTimeNoOffsetConverter());
        return options;
    }

    [Fact]
    public void Money_IsWrittenAsStringWithTwoDecimals()
    {
        var json = JsonSerializer.Serialize(1000.5m , CreateOptions());
        Assert.Equal("\"1000.50\"", json);
    }

    [Fact]
    public void Money_WholeNumber_IsPaddedToTwoDecimals()
    {
        var json = JsonSerializer.Serialize(1000m, CreateOptions());
        Assert.Equal("\"1000.00\"", json);
    }

    [Fact] 
    public void Money_IsRoundedHalfUp()
    {
        // The middle value rounds up, matching T-SQL CAST
        var json = JsonSerializer.Serialize(1000.555m, CreateOptions());
        Assert.Equal("\"1000.56\"", json);
    }

    [Fact]
    public void DateTime_IsWrittenWithoutOffset()
    {
        // The middle value rounds up, matching T-SQL CAST
        var value = new DateTime(2026, 11, 2, 14, 30, 0, DateTimeKind.Unspecified);
        var json = JsonSerializer.Serialize(value, CreateOptions());
        Assert.Equal("\"2026-11-02T14:30:00\"", json);
    }

    [Fact]
    public void DateTime_LocalKind_DoesNotGetOffsetAppended()
    {
        // The default serializer would append an offset for Kind = Local
        var value = new DateTime (2026 , 11 , 2 , 14 , 30 , 0 , DateTimeKind.Local);
        var json = JsonSerializer.Serialize(value , CreateOptions());
        Assert.Equal("\"2026-11-02T14:30:00\"", json);
    }
}