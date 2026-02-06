using System.Runtime.InteropServices;

namespace AntFfi.Native;

/// <summary>
/// Represents read-only byte data passed from C# to Rust.
/// </summary>
/// <remarks>
/// This struct must match the memory layout of the C ForeignBytes struct.
/// The data pointer must remain valid for the duration of the FFI call.
/// </remarks>
[StructLayout(LayoutKind.Sequential)]
public struct ForeignBytes
{
    /// <summary>
    /// Length of the data in bytes.
    /// </summary>
    public int Len;

    /// <summary>
    /// Pointer to the data.
    /// </summary>
    public IntPtr Data;

    /// <summary>
    /// Creates a ForeignBytes struct from a byte array.
    /// </summary>
    /// <param name="data">The byte array to wrap.</param>
    /// <param name="pinnedHandle">The GCHandle that pins the array (must be freed by caller).</param>
    /// <returns>A ForeignBytes struct pointing to the pinned array.</returns>
    public static ForeignBytes FromBytes(byte[] data, out GCHandle pinnedHandle)
    {
        pinnedHandle = GCHandle.Alloc(data, GCHandleType.Pinned);
        return new ForeignBytes
        {
            Len = data.Length,
            Data = pinnedHandle.AddrOfPinnedObject()
        };
    }
}
