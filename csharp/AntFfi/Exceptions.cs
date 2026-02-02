using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when an FFI call fails.
/// </summary>
public class AntFfiException : Exception
{
    /// <summary>
    /// The error code returned by the FFI call.
    /// </summary>
    public sbyte ErrorCode { get; }

    /// <summary>
    /// Creates a new AntFfiException with the specified message.
    /// </summary>
    public AntFfiException(string message) : base(message)
    {
        ErrorCode = -1;
    }

    /// <summary>
    /// Creates a new AntFfiException from a RustCallStatus.
    /// </summary>
    public AntFfiException(string message, RustCallStatus status)
        : base(FormatMessage(message, status))
    {
        ErrorCode = status.Code;

        // Free the error buffer if present
        if (!status.ErrorBuf.IsEmpty)
        {
            var freeStatus = RustCallStatus.Create();
            NativeMethods.FreeRustBuffer(status.ErrorBuf, ref freeStatus);
        }
    }

    private static string FormatMessage(string message, RustCallStatus status)
    {
        if (status.ErrorBuf.IsEmpty)
            return $"{message} (code: {status.Code})";

        try
        {
            var errorBytes = status.ErrorBuf.ToBytes();

            // UniFFI error enums are serialized as: i32 BE variant_index + field data.
            // ClientError has variants: 1=NetworkError{reason}, 2=InitializationFailed{reason}, 3=InvalidAddress{reason}
            // Each variant has a single String field (i32 BE length + UTF-8).
            if (errorBytes.Length >= 8) // 4 bytes variant + at least 4 bytes for string length
            {
                try
                {
                    var reader = new Native.UniFFIReader(errorBytes);
                    int variantIndex = reader.ReadI32();
                    string reason = reader.ReadString();

                    string variantName = variantIndex switch
                    {
                        1 => "NetworkError",
                        2 => "InitializationFailed",
                        3 => "InvalidAddress",
                        _ => $"UnknownError(variant={variantIndex})",
                    };

                    return $"{message}: [{variantName}] {reason} (code: {status.Code})";
                }
                catch
                {
                    // Fall through to other strategies
                }
            }

            // Fallback: try as UniFFI length-prefixed string
            if (errorBytes.Length >= 4)
            {
                try
                {
                    var errorMessage = UniFFIHelpers.DeserializeString(errorBytes);
                    if (!string.IsNullOrWhiteSpace(errorMessage))
                        return $"{message}: {errorMessage} (code: {status.Code})";
                }
                catch
                {
                    // Fall through
                }
            }

            // Fallback: raw UTF-8
            var rawMessage = System.Text.Encoding.UTF8.GetString(errorBytes);
            if (!string.IsNullOrWhiteSpace(rawMessage))
                return $"{message}: {rawMessage} (code: {status.Code})";

            var hex = BitConverter.ToString(errorBytes, 0, Math.Min(errorBytes.Length, 128));
            return $"{message} (code: {status.Code}, errorBuf hex[{errorBytes.Length}]: {hex})";
        }
        catch
        {
            return $"{message} (code: {status.Code}, error buffer present but unreadable)";
        }
    }
}

/// <summary>
/// Exception thrown when encryption fails.
/// </summary>
public class EncryptionException : AntFfiException
{
    public EncryptionException(string message) : base(message) { }
    public EncryptionException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Exception thrown when decryption fails.
/// </summary>
public class DecryptionException : AntFfiException
{
    public DecryptionException(string message) : base(message) { }
    public DecryptionException(string message, RustCallStatus status) : base(message, status) { }
}
