namespace BankingSystem.Api.Common;

/*
    In-memory paging: search procedures return every row, the API returns one 
        page of them and reports the total through the header
*/
public static class Pagination
{
    public const int DefaultPageSize = 20;
    public const int MaxPageSize = 100;

    public static List<T> Slice<T>(List<T> items, int page , int size)
    {
        // out-of-range input is clamped instead of rejected
        var safePage = Math.Max(page , 0);
        var safeSize = Math.Clamp(size , 1 , MaxPageSize);

        // long avoids int overflow for a huge page number
        var start = (long)safePage * safeSize;
        if (start >= items.Count) return new List<T>();

        return items.Skip((int)start).Take(safeSize).ToList();
    }
}