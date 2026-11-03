using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace BankingSystem.Api.Common;

/*
    Writes date-times as ISO-8601 without an offset)
    API nver converts time zones
*/
public class DateTimeNoOffsetConverter : JsonConverter<DateTime>
{
    private const string format = "yyyy-MM-dd'T'HH:mm:ss";

    public override DateTime Read(
            ref Utf8JsonReader reader,
            Type typeToConvert,
            JsonSerializerOptions options)
    {
        var text = reader.GetString();
        
        // parse exact the format
        return DateTime.ParseExact(text! , format , CultureInfo.InvariantCulture , DateTimeStyles.None);
    }

    public override void Write(
        Utf8JsonWriter writer,
        DateTime value,
        JsonSerializerOptions options)
    {
        var text = value.ToString(format , CultureInfo.InvariantCulture);
        writer.WriteStringValue(text);
    }
    
}