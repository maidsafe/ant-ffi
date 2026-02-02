using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a pointer operation fails.
/// </summary>
public class PointerException : AntFfiException
{
    public PointerException(string message) : base(message) { }
    public PointerException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Address of a pointer on the network (derived from owner's public key).
/// </summary>
public sealed class PointerAddress : NativeHandle
{
    internal PointerAddress(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a PointerAddress from a PublicKey.
    /// </summary>
    public static PointerAddress FromPublicKey(PublicKey publicKey)
    {
        ArgumentNullException.ThrowIfNull(publicKey);
        publicKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.PointerAddressNew(publicKey.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerAddress.FromPublicKey");
        return new PointerAddress(handle);
    }

    /// <summary>
    /// Creates a PointerAddress from a hex string.
    /// </summary>
    public static PointerAddress FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PointerAddressFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new PointerException("Failed to parse pointer address from hex", status);
        return new PointerAddress(handle);
    }

    /// <summary>
    /// Gets the owner's PublicKey.
    /// </summary>
    public PublicKey Owner()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PointerAddressOwner(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerAddress.Owner");
        return new PublicKey(handle);
    }

    /// <summary>
    /// Returns the hex representation of this pointer address.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.PointerAddressToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerAddress.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreePointerAddress(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.ClonePointerAddress(Handle, ref status);
    }
}

/// <summary>
/// Target of a network pointer - can point to chunks, other pointers, graph entries, or scratchpads.
/// </summary>
public sealed class PointerTarget : NativeHandle
{
    internal PointerTarget(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a pointer target pointing to a chunk.
    /// </summary>
    public static PointerTarget ToChunk(ChunkAddress address)
    {
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.PointerTargetChunk(address.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerTarget.ToChunk");
        return new PointerTarget(handle);
    }

    /// <summary>
    /// Creates a pointer target pointing to another pointer.
    /// </summary>
    public static PointerTarget ToPointer(PointerAddress address)
    {
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.PointerTargetPointer(address.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerTarget.ToPointer");
        return new PointerTarget(handle);
    }

    /// <summary>
    /// Creates a pointer target pointing to a graph entry.
    /// </summary>
    public static PointerTarget ToGraphEntry(GraphEntryAddress address)
    {
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.PointerTargetGraphEntry(address.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerTarget.ToGraphEntry");
        return new PointerTarget(handle);
    }

    /// <summary>
    /// Creates a pointer target pointing to a scratchpad.
    /// </summary>
    public static PointerTarget ToScratchpad(ScratchpadAddress address)
    {
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.PointerTargetScratchpad(address.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerTarget.ToScratchpad");
        return new PointerTarget(handle);
    }

    /// <summary>
    /// Returns the hex representation of this pointer target.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.PointerTargetToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PointerTarget.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreePointerTarget(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.ClonePointerTarget(Handle, ref status);
    }
}

/// <summary>
/// A mutable pointer to network data.
/// </summary>
/// <remarks>
/// NetworkPointers allow updating references to data without changing the pointer address.
/// They are signed by the owner's key for authentication.
/// </remarks>
public sealed class NetworkPointer : NativeHandle
{
    internal NetworkPointer(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a new network pointer.
    /// </summary>
    /// <param name="key">The secret key to sign the pointer with.</param>
    /// <param name="counter">Version counter (increment for updates).</param>
    /// <param name="target">The target this pointer points to.</param>
    public static NetworkPointer Create(SecretKey key, ulong counter, PointerTarget target)
    {
        ArgumentNullException.ThrowIfNull(key);
        ArgumentNullException.ThrowIfNull(target);
        key.ThrowIfDisposed();
        target.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.NetworkPointerNew(key.CloneHandle(), counter, target.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "NetworkPointer.Create");
        return new NetworkPointer(handle);
    }

    /// <summary>
    /// Gets the address of this pointer.
    /// </summary>
    public PointerAddress Address()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.NetworkPointerAddress(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "NetworkPointer.Address");
        return new PointerAddress(handle);
    }

    /// <summary>
    /// Gets the target this pointer points to.
    /// </summary>
    public PointerTarget Target()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.NetworkPointerTarget(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "NetworkPointer.Target");
        return new PointerTarget(handle);
    }

    /// <summary>
    /// Gets the version counter of this pointer.
    /// </summary>
    public ulong Counter
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.NetworkPointerCounter(CloneHandle(), ref status);
        }
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeNetworkPointer(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneNetworkPointer(Handle, ref status);
    }
}
