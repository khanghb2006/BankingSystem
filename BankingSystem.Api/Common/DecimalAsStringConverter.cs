using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace BankingSystem.Api.Common;

/* 
    Writes money as a Json string with exactly two decimal place
    Client must never recieve money as a Json number , because of floating point
    parsing on the client side can lose precision
*/
public class DecimalAsStringConverter : JsonConverter<decimal>
{   public override decimal Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.String)
        {
            var text = reader.GetString();
            return decimal.Parse(text! , NumberStyles.Number , CultureInfo.InvariantCulture);
        }

        return reader.GetDecimal();
    }

    public override void Write (
        Utf8JsonWriter writer,
        decimal value,
        JsonSerializerOptions options)
    {
        // Round half-up to the decimals
        var rounded = Math.Round(value , 2 , MidpointRounding.AwayFromZero);

        // Invariant Culture forces "." as the decimal separtor
        var text = rounded.ToString("F2" , CultureInfo.InvariantCulture);

        writer.WriteStringValue(text);
    }
}