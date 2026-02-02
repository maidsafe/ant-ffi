using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a scratchpad operation fails.
/// </summary>
public class ScratchpadException : AntFfiException
{
    public ScratchpadException(string message) : base(message) { }
    public ScratchpadException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Address of a scratchpad on the network (derived from owner's public key).
/// </summary>
public sealed class ScratchpadAddress : NativeHandle
{
    internal ScratchpadAddress(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a ScratchpadAddress from a PublicKey.
    /// </summary>
    public static ScratchpadAddress FromPublicKey(PublicKey publicKey)
    {
        ArgumentNullException.ThrowIfNull(publicKey);
        publicKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.ScratchpadAddressNew(publicKey.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "ScratchpadAddress.FromPublicKey");
        return new ScratchpadAddress(handle);
    }

    /// <summary>
    /// Creates a ScratchpadAddress from a hex string.
    /// </summary>
    public static ScratchpadAddress FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ScratchpadAddressFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new ScratchpadException("Failed to parse scratchpad address from hex", status);
        return new ScratchpadAddress(handle);
    }

    /// <summary>
    /// Gets the owner's PublicKey.
    /// </summary>
    public PublicKey Owner()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ScratchpadAddressOwner(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "ScratchpadAddress.Owner");
        return new PublicKey(handle);
    }

    /// <summary>
    /// Returns the hex representation of this scratchpad address.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.ScratchpadAddressToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "ScratchpadAddress.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeScratchpadAddress(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneScratchpadAddress(Handle, ref status);
    }
}

/// <summary>
/// Encrypted mutable data with versioning.
/// </summary>
/// <remarks>
/// Scratchpads allow storing encrypted data that can be updated by the owner.
/// The data is encrypted and can only be decrypted with the owner's secret key.
/// </remarks>
public sealed class Scratchpad : NativeHandle
{
    internal Scratchpad(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a new scratchpad.
    /// </summary>
    /// <param name="owner">The secret key of the owner.</param>
    /// <param name="dataEncoding">The encoding type of the data.</param>
    /// <param name="unencryptedData">The data to store (will be encrypted).</param>
    /// <param name="counter">Version counter.</param>
    public static Scratchpad Create(SecretKey owner, ulong dataEncoding, byte[] unencryptedData, ulong counter)
    {
        ArgumentNullException.ThrowIfNull(owner);
        ArgumentNullException.ThrowIfNull(unencryptedData);
        owner.ThrowIfDisposed();

        var dataBuffer = UniFFIHelpers.ToRustBuffer(unencryptedData);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ScratchpadNew(owner.CloneHandle(), dataEncoding, dataBuffer, counter, ref status);
        if (status.IsError)
            throw new ScratchpadException("Failed to create scratchpad", status);
        return new Scratchpad(handle);
    }

    /// <summary>
    /// Gets the address of this scratchpad.
    /// </summary>
    public ScratchpadAddress Address()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ScratchpadAddress(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Scratchpad.Address");
        return new ScratchpadAddress(handle);
    }

    /// <summary>
    /// Gets the data encoding type.
    /// </summary>
    public ulong DataEncoding
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.ScratchpadDataEncoding(CloneHandle(), ref status);
        }
    }

    /// <summary>
    /// Gets the version counter.
    /// </summary>
    public ulong Counter
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.ScratchpadCounter(CloneHandle(), ref status);
        }
    }

    /// <summary>
    /// Decrypts the data using the owner's secret key.
    /// </summary>
    /// <param name="secretKey">The owner's secret key.</param>
    /// <returns>The decrypted data.</returns>
    public byte[] DecryptData(SecretKey secretKey)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(secretKey);
        secretKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        NativeMethods.ScratchpadDecryptData(out var buffer, CloneHandle(), secretKey.CloneHandle(), ref status);
        if (status.IsError)
            throw new ScratchpadException("Failed to decrypt scratchpad data", status);
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Gets the owner's PublicKey.
    /// </summary>
    public PublicKey Owner()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ScratchpadOwner(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Scratchpad.Owner");
        return new PublicKey(handle);
    }

    /// <summary>
    /// Gets the encrypted data bytes.
    /// </summary>
    public byte[] EncryptedData()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.ScratchpadEncryptedData(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Scratchpad.EncryptedData");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeScratchpad(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneScratchpad(Handle, ref status);
    }
}
