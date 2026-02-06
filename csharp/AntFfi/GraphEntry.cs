using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a graph entry operation fails.
/// </summary>
public class GraphEntryException : AntFfiException
{
    public GraphEntryException(string message) : base(message) { }
    public GraphEntryException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Address of a graph entry on the network.
/// </summary>
public sealed class GraphEntryAddress : NativeHandle
{
    internal GraphEntryAddress(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a GraphEntryAddress from a PublicKey.
    /// </summary>
    public static GraphEntryAddress FromPublicKey(PublicKey publicKey)
    {
        ArgumentNullException.ThrowIfNull(publicKey);
        publicKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.GraphEntryAddressNew(publicKey.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "GraphEntryAddress.FromPublicKey");
        return new GraphEntryAddress(handle);
    }

    /// <summary>
    /// Creates a GraphEntryAddress from a hex string.
    /// </summary>
    public static GraphEntryAddress FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.GraphEntryAddressFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new GraphEntryException("Failed to parse graph entry address from hex", status);
        return new GraphEntryAddress(handle);
    }

    /// <summary>
    /// Returns the hex representation of this graph entry address.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.GraphEntryAddressToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "GraphEntryAddress.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeGraphEntryAddress(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneGraphEntryAddress(Handle, ref status);
    }
}

/// <summary>
/// A graph-based data structure entry.
/// </summary>
/// <remarks>
/// GraphEntry allows creating directed acyclic graphs (DAGs) on the network.
/// Each entry has exactly 32 bytes of content, parents, and descendants.
/// </remarks>
public sealed class GraphEntry : NativeHandle
{
    internal GraphEntry(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Gets the address of this graph entry.
    /// </summary>
    public GraphEntryAddress Address()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.GraphEntryAddress(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "GraphEntry.Address");
        return new GraphEntryAddress(handle);
    }

    /// <summary>
    /// Gets the 32-byte content of this graph entry.
    /// </summary>
    public byte[] Content()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.GraphEntryContent(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "GraphEntry.Content");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeGraphEntry(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneGraphEntry(Handle, ref status);
    }
}
