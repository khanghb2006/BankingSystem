namespace Backend.Common;

public record ApiResponse<T>(bool Success , string? Message , T? Data , ApiError? Error) {
    public static ApiResponse<T> Ok(string? message , T? data)
    {
        return new(true , message , data , null);
    }
    public static ApiResponse<T> Fail(string message , ApiError error)
    {
        return new(false , message , default , error);
    }
}