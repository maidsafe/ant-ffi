using System.Runtime.InteropServices;

namespace AntFfi.Native;

/// <summary>
/// Represents the status of a Rust FFI call, including error information.
/// </summary>
/// <remarks>
/// This struct must match the memory layout of the C RustCallStatus struct.
/// After checking for errors, the errorBuf must be freed if it contains data.
/// </remarks>
[StructLayout(LayoutKind.Sequential)]
public struct RustCallStatus
{
    /// <summary>
    /// Status code. 0 indicates success, non-zero indicates an error.
    /// </summary>
    public sbyte Code;

    /// <summary>
    /// Buffer containing the error message (if Code != 0).
    /// </summary>
    public RustBuffer ErrorBuf;

    /// <summary>
    /// Gets whether this status indicates success.
    /// </summary>
    public readonly bool IsSuccess => Code == 0;

    /// <summary>
    /// Gets whether this status indicates an error.
    /// </summary>
    public readonly bool IsError => Code != 0;

    /// <summary>
    /// Creates a new empty RustCallStatus (for passing to FFI calls).
    /// </summary>
    public static RustCallStatus Create() => new();
}
