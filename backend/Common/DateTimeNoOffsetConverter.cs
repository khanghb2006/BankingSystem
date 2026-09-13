namespace Backend.Common;

using System.Text.Json;
using System.Text.Json.Serialization;

/*
    Serialization DateTime without any timezone offset (no "Z" or "+07:00")
    Why : the database local VietNam time in a plain DATETIME column with no timezone info
    Just pass the value through as-is, and trust both database and app agree "Asia/Ho_Chi_Minh" timezone
*/
public sealed class DateTimeNoOffsetConverter : JsonConverter<DateTime>
{
    private const string Format = "yyyy-MM-dd'T'HH:mm:ss";

    public override DateTime Read(ref Utf8JsonReader reader , Type typeToConvert , 
        JsonSerializerOptions options)
    {
        string? text = reader.GetString();
        DateTime value = DateTime.Parse(text!);
        return value;
    }

    public override void Write(Utf8JsonWriter writer, DateTime value, 
        JsonSerializerOptions options)
    {
        String formatted = value.ToString(Format);
        writer.WriteStringValue(formatted);
    }
}