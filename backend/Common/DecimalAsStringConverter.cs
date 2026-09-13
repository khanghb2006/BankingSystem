namespace Backend.Common;

using System.Text.Json;
using System.Text.Json.Serialization;

/*
    Converts decimal (money amount) to/from JSON strings instead of JSON numbers
    Why: JSON numbers use floating point under the hood
*/
public sealed class DecimalAsStringConverter : JsonConverter<decimal>
{
    public override decimal Read (ref Utf8JsonReader reader , Type typetoConvert, 
        JsonSerializerOptions options)
    {
        string? text = reader.GetString();
        decimal value = decimal.Parse(text!);
        return value;   
    }

    public override void Write (Utf8JsonWriter writer, decimal value, 
        JsonSerializerOptions options)
    {
        string formatted = value.ToString("F2");
        writer.WriteStringValue(formatted);
    }
}
