using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a key operation fails.
/// </summary>
public class KeyException : AntFfiException
{
    public KeyException(string message) : base(message) { }
    public KeyException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// BLS Secret Key for signing operations.
/// </summary>
/// <remarks>
/// Secret keys should be kept private and secure. Use <see cref="PublicKey"/> for sharing.
/// </remarks>
public sealed class SecretKey : NativeHandle
{
    internal SecretKey(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Generates a new random secret key.
    /// </summary>
    /// <returns>A new randomly generated secret key.</returns>
    public static SecretKey Random()
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.SecretKeyRandom(ref status);
        UniFFIHelpers.CheckStatus(ref status, "SecretKey.Random");
        return new SecretKey(handle);
    }

    /// <summary>
    /// Creates a secret key from a hex string.
    /// </summary>
    /// <param name="hex">The hex-encoded secret key.</param>
    /// <returns>The parsed secret key.</returns>
    /// <exception cref="KeyException">Thrown if the hex string is invalid.</exception>
    public static SecretKey FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.SecretKeyFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new KeyException("Failed to parse secret key from hex", status);
        return new SecretKey(handle);
    }

    /// <summary>
    /// Serializes this secret key to a hex string.
    /// </summary>
    /// <returns>The hex-encoded secret key.</returns>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.SecretKeyToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "SecretKey.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <summary>
    /// Gets the public key corresponding to this secret key.
    /// </summary>
    /// <returns>The corresponding public key.</returns>
    public PublicKey PublicKey()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.SecretKeyPublicKey(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "SecretKey.PublicKey");
        return new PublicKey(handle);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeSecretKey(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneSecretKey(Handle, ref status);
    }
}

/// <summary>
/// BLS Public Key derived from a secret key.
/// </summary>
/// <remarks>
/// Public keys can be safely shared and are used to verify signatures.
/// </remarks>
public sealed class PublicKey : NativeHandle
{
    internal PublicKey(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a public key from a hex string.
    /// </summary>
    /// <param name="hex">The hex-encoded public key.</param>
    /// <returns>The parsed public key.</returns>
    /// <exception cref="KeyException">Thrown if the hex string is invalid.</exception>
    public static PublicKey FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PublicKeyFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new KeyException("Failed to parse public key from hex", status);
        return new PublicKey(handle);
    }

    /// <summary>
    /// Serializes this public key to a hex string.
    /// </summary>
    /// <returns>The hex-encoded public key.</returns>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.PublicKeyToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PublicKey.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreePublicKey(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.ClonePublicKey(Handle, ref status);
    }
}
