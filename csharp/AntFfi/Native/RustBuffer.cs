using System.Runtime.InteropServices;

namespace AntFfi.Native;

/// <summary>
/// Represents a buffer owned by Rust. Used to pass byte arrays between C# and Rust.
/// </summary>
/// <remarks>
/// This struct must match the memory layout of the C RustBuffer struct.
/// All RustBuffers returned from Rust must be freed using <see cref="NativeMethods.FreeRustBuffer"/>.
/// </remarks>
[StructLayout(LayoutKind.Sequential)]
public struct RustBuffer
{
    /// <summary>
    /// Allocated capacity of the buffer.
    /// </summary>
    public ulong Capacity;

    /// <summary>
    /// Actual length of data in the buffer.
    /// </summary>
    public ulong Len;

    /// <summary>
    /// Pointer to the buffer data.
    /// </summary>
    public IntPtr Data;

    /// <summary>
    /// Gets whether this buffer is empty.
    /// </summary>
    public readonly bool IsEmpty => Len == 0 || Data == IntPtr.Zero;

    /// <summary>
    /// Copies the buffer data to a managed byte array.
    /// </summary>
    /// <returns>A new byte array containing the buffer data.</returns>
    public readonly byte[] ToBytes()
    {
        if (IsEmpty)
            return Array.Empty<byte>();

        var bytes = new byte[Len];
        Marshal.Copy(Data, bytes, 0, (int)Len);
        return bytes;
    }
}
