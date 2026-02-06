using System.Runtime.InteropServices;
using System.Text;

namespace AntFfi.Native;

/// <summary>
/// Reads values from a byte array in UniFFI's big-endian binary format.
/// Used to deserialize compound types (records, enums) from RustBuffer contents.
/// </summary>
internal class UniFFIReader
{
    private readonly byte[] _data;
    private int _offset;

    public UniFFIReader(byte[] data)
    {
        _data = data;
        _offset = 0;
    }

    public int ReadI32()
    {
        int value = (_data[_offset] << 24) | (_data[_offset + 1] << 16) |
                    (_data[_offset + 2] << 8) | _data[_offset + 3];
        _offset += 4;
        return value;
    }

    public ulong ReadU64()
    {
        ulong value = ((ulong)_data[_offset] << 56) | ((ulong)_data[_offset + 1] << 48) |
                      ((ulong)_data[_offset + 2] << 40) | ((ulong)_data[_offset + 3] << 32) |
                      ((ulong)_data[_offset + 4] << 24) | ((ulong)_data[_offset + 5] << 16) |
                      ((ulong)_data[_offset + 6] << 8) | (ulong)_data[_offset + 7];
        _offset += 8;
        return value;
    }

    public IntPtr ReadPointer()
    {
        return (IntPtr)(long)ReadU64();
    }

    public string ReadString()
    {
        int len = ReadI32();
        var str = Encoding.UTF8.GetString(_data, _offset, len);
        _offset += len;
        return str;
    }

    public byte[] ReadBytes()
    {
        int len = ReadI32();
        var bytes = new byte[len];
        Array.Copy(_data, _offset, bytes, 0, len);
        _offset += len;
        return bytes;
    }

    public bool ReadBool()
    {
        return _data[_offset++] != 0;
    }
}

/// <summary>
/// Writes values to a byte array in UniFFI's big-endian binary format.
/// Used to serialize compound types (enums, records) for passing to Rust.
/// </summary>
internal class UniFFIWriter
{
    private readonly List<byte> _buf = new();

    public void WriteI32(int value)
    {
        _buf.Add((byte)(value >> 24));
        _buf.Add((byte)(value >> 16));
        _buf.Add((byte)(value >> 8));
        _buf.Add((byte)value);
    }

    public void WriteU64(ulong value)
    {
        _buf.Add((byte)(value >> 56));
        _buf.Add((byte)(value >> 48));
        _buf.Add((byte)(value >> 40));
        _buf.Add((byte)(value >> 32));
        _buf.Add((byte)(value >> 24));
        _buf.Add((byte)(value >> 16));
        _buf.Add((byte)(value >> 8));
        _buf.Add((byte)value);
    }

    public void WritePointer(IntPtr ptr)
    {
        WriteU64((ulong)(long)ptr);
    }

    public void WriteString(string value)
    {
        var bytes = Encoding.UTF8.GetBytes(value);
        WriteI32(bytes.Length);
        _buf.AddRange(bytes);
    }

    public byte[] ToArray() => _buf.ToArray();
}

/// <summary>
/// Helper methods for UniFFI serialization format.
/// </summary>
/// <remarks>
/// UniFFI uses a specific serialization format where byte arrays (Vec&lt;u8&gt;)
/// are prefixed with a 4-byte big-endian length.
/// </remarks>
public static class UniFFIHelpers
{
    /// <summary>
    /// Serializes a byte array with a 4-byte big-endian length prefix (UniFFI format).
    /// </summary>
    /// <param name="data">The data to serialize.</param>
    /// <returns>The serialized data with length prefix.</returns>
    public static byte[] SerializeBytes(byte[] data)
    {
        var result = new byte[4 + data.Length];

        // Write 4-byte big-endian length prefix
        result[0] = (byte)(data.Length >> 24);
        result[1] = (byte)(data.Length >> 16);
        result[2] = (byte)(data.Length >> 8);
        result[3] = (byte)data.Length;

        // Copy data after prefix
        Buffer.BlockCopy(data, 0, result, 4, data.Length);

        return result;
    }

    /// <summary>
    /// Deserializes a byte array by reading the 4-byte big-endian length prefix and extracting the data.
    /// </summary>
    /// <param name="serialized">The serialized data with length prefix.</param>
    /// <returns>The deserialized data without the prefix.</returns>
    /// <exception cref="ArgumentException">Thrown if the data is too short or the length is invalid.</exception>
    public static byte[] DeserializeBytes(byte[] serialized)
    {
        if (serialized.Length < 4)
            throw new ArgumentException("Serialized data too short for UniFFI format", nameof(serialized));

        // Read 4-byte big-endian length prefix
        int len = (serialized[0] << 24) | (serialized[1] << 16) | (serialized[2] << 8) | serialized[3];

        if (len < 0 || len > serialized.Length - 4)
            throw new ArgumentException($"Invalid UniFFI length prefix: {len}, available: {serialized.Length - 4}", nameof(serialized));

        var result = new byte[len];
        Buffer.BlockCopy(serialized, 4, result, 0, len);
        return result;
    }

    /// <summary>
    /// Serializes a string with UniFFI format (4-byte big-endian length prefix + UTF-8 bytes).
    /// </summary>
    /// <param name="str">The string to serialize.</param>
    /// <returns>The serialized string.</returns>
    public static byte[] SerializeString(string str)
    {
        var utf8Bytes = System.Text.Encoding.UTF8.GetBytes(str);
        return SerializeBytes(utf8Bytes);
    }

    /// <summary>
    /// Deserializes a string from UniFFI format.
    /// </summary>
    /// <param name="serialized">The serialized string.</param>
    /// <returns>The deserialized string.</returns>
    public static string DeserializeString(byte[] serialized)
    {
        var utf8Bytes = DeserializeBytes(serialized);
        return System.Text.Encoding.UTF8.GetString(utf8Bytes);
    }

    /// <summary>
    /// Creates a RustBuffer from a byte array, serializing it with UniFFI format.
    /// </summary>
    /// <param name="data">The data to convert.</param>
    /// <returns>A RustBuffer containing the serialized data.</returns>
    public static RustBuffer ToRustBuffer(byte[] data)
    {
        var serialized = SerializeBytes(data);
        var pinnedHandle = GCHandle.Alloc(serialized, GCHandleType.Pinned);

        try
        {
            var foreignBytes = new ForeignBytes
            {
                Len = serialized.Length,
                Data = pinnedHandle.AddrOfPinnedObject()
            };

            var status = RustCallStatus.Create();
            var buffer = NativeMethods.RustBufferFromBytes(foreignBytes, ref status);

            if (status.IsError)
            {
                throw new AntFfiException("Failed to create RustBuffer", status);
            }

            return buffer;
        }
        finally
        {
            pinnedHandle.Free();
        }
    }

    /// <summary>
    /// Converts a RustBuffer to a byte array, deserializing from UniFFI format.
    /// </summary>
    /// <param name="buffer">The RustBuffer to convert.</param>
    /// <param name="freeBuffer">Whether to free the buffer after conversion (default: true).</param>
    /// <returns>The deserialized byte array.</returns>
    public static byte[] FromRustBuffer(RustBuffer buffer, bool freeBuffer = true)
    {
        try
        {
            if (buffer.IsEmpty)
                return Array.Empty<byte>();

            var raw = buffer.ToBytes();
            return DeserializeBytes(raw);
        }
        finally
        {
            if (freeBuffer && !buffer.IsEmpty)
            {
                var status = RustCallStatus.Create();
                NativeMethods.FreeRustBuffer(buffer, ref status);
            }
        }
    }

    /// <summary>
    /// Converts a RustBuffer to a raw byte array without UniFFI deserialization.
    /// </summary>
    /// <param name="buffer">The RustBuffer to convert.</param>
    /// <param name="freeBuffer">Whether to free the buffer after conversion (default: true).</param>
    /// <returns>The raw byte array.</returns>
    public static byte[] FromRustBufferRaw(RustBuffer buffer, bool freeBuffer = true)
    {
        try
        {
            return buffer.ToBytes();
        }
        finally
        {
            if (freeBuffer && !buffer.IsEmpty)
            {
                var status = RustCallStatus.Create();
                NativeMethods.FreeRustBuffer(buffer, ref status);
            }
        }
    }

    /// <summary>
    /// Converts a RustBuffer containing a direct UTF-8 string (no length prefix).
    /// Used for strings returned directly from FFI functions.
    /// </summary>
    /// <param name="buffer">The RustBuffer to convert.</param>
    /// <param name="freeBuffer">Whether to free the buffer after conversion (default: true).</param>
    /// <returns>The string.</returns>
    public static string StringFromRustBuffer(RustBuffer buffer, bool freeBuffer = true)
    {
        try
        {
            if (buffer.IsEmpty)
                return string.Empty;

            var bytes = buffer.ToBytes();
            return System.Text.Encoding.UTF8.GetString(bytes);
        }
        finally
        {
            if (freeBuffer && !buffer.IsEmpty)
            {
                var status = RustCallStatus.Create();
                NativeMethods.FreeRustBuffer(buffer, ref status);
            }
        }
    }

    /// <summary>
    /// Checks a RustCallStatus and throws an exception if it indicates an error.
    /// </summary>
    /// <param name="status">The status to check.</param>
    /// <param name="operation">Description of the operation for error messages.</param>
    public static void CheckStatus(ref RustCallStatus status, string operation = "FFI call")
    {
        if (status.IsError)
        {
            throw new AntFfiException($"{operation} failed", status);
        }
    }

    /// <summary>
    /// Creates a RustBuffer from a string without UniFFI length prefix.
    /// Used for passing strings to FFI functions that expect raw UTF-8.
    /// </summary>
    /// <param name="str">The string to convert.</param>
    /// <returns>A RustBuffer containing the raw UTF-8 bytes.</returns>
    public static RustBuffer StringToRustBuffer(string str)
    {
        var utf8Bytes = System.Text.Encoding.UTF8.GetBytes(str);
        var pinnedHandle = GCHandle.Alloc(utf8Bytes, GCHandleType.Pinned);

        try
        {
            var foreignBytes = new ForeignBytes
            {
                Len = utf8Bytes.Length,
                Data = pinnedHandle.AddrOfPinnedObject()
            };

            var status = RustCallStatus.Create();
            var buffer = NativeMethods.RustBufferFromBytes(foreignBytes, ref status);

            if (status.IsError)
            {
                throw new AntFfiException("Failed to create RustBuffer from string", status);
            }

            return buffer;
        }
        finally
        {
            pinnedHandle.Free();
        }
    }

    /// <summary>
    /// Creates a RustBuffer from raw bytes (no UniFFI serialization applied).
    /// </summary>
    internal static RustBuffer RawToRustBuffer(byte[] rawBytes)
    {
        var pinnedHandle = GCHandle.Alloc(rawBytes, GCHandleType.Pinned);

        try
        {
            var foreignBytes = new ForeignBytes
            {
                Len = rawBytes.Length,
                Data = pinnedHandle.AddrOfPinnedObject()
            };

            var status = RustCallStatus.Create();
            var buffer = NativeMethods.RustBufferFromBytes(foreignBytes, ref status);

            if (status.IsError)
            {
                throw new AntFfiException("Failed to create RustBuffer", status);
            }

            return buffer;
        }
        finally
        {
            pinnedHandle.Free();
        }
    }

    /// <summary>
    /// Serializes a PaymentOption::WalletPayment enum to a RustBuffer.
    /// UniFFI enum format: i32 BE variant index (1-based) + variant fields.
    /// </summary>
    internal static RustBuffer LowerPaymentOption(IntPtr walletHandle)
    {
        var writer = new UniFFIWriter();
        writer.WriteI32(1); // Variant index 1 = WalletPayment
        writer.WritePointer(walletHandle); // wallet_ref: Arc<Wallet>
        return RawToRustBuffer(writer.ToArray());
    }

    /// <summary>
    /// Reads a UniFFI-serialized String from a RustBuffer (with length prefix).
    /// Used for string values inside compound return types (records).
    /// </summary>
    internal static string ReadStringFromRecordBuffer(RustBuffer buffer, bool freeBuffer = true)
    {
        try
        {
            if (buffer.IsEmpty)
                return string.Empty;

            var raw = buffer.ToBytes();
            var reader = new UniFFIReader(raw);
            return reader.ReadString();
        }
        finally
        {
            if (freeBuffer && !buffer.IsEmpty)
            {
                var status = RustCallStatus.Create();
                NativeMethods.FreeRustBuffer(buffer, ref status);
            }
        }
    }

    /// <summary>
    /// Creates a RustBuffer from an optional string in UniFFI Option format.
    /// None: 1 byte (0), Some: 1 byte (1) + 4-byte BE length + UTF-8 bytes.
    /// </summary>
    /// <param name="str">The optional string to convert.</param>
    /// <returns>A RustBuffer containing the serialized Option&lt;String&gt;.</returns>
    public static RustBuffer OptionStringToRustBuffer(string? str)
    {
        byte[] rawBytes;
        if (str == null)
        {
            // None variant: just a 0 byte
            rawBytes = new byte[] { 0 };
        }
        else
        {
            // Some variant: 1 byte + 4-byte BE length + UTF-8 data
            var utf8Bytes = System.Text.Encoding.UTF8.GetBytes(str);
            rawBytes = new byte[1 + 4 + utf8Bytes.Length];
            rawBytes[0] = 1; // Some
            rawBytes[1] = (byte)(utf8Bytes.Length >> 24);
            rawBytes[2] = (byte)(utf8Bytes.Length >> 16);
            rawBytes[3] = (byte)(utf8Bytes.Length >> 8);
            rawBytes[4] = (byte)utf8Bytes.Length;
            Buffer.BlockCopy(utf8Bytes, 0, rawBytes, 5, utf8Bytes.Length);
        }

        return RawToRustBuffer(rawBytes);
    }
}
