using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a register operation fails.
/// </summary>
public class RegisterException : AntFfiException
{
    public RegisterException(string message) : base(message) { }
    public RegisterException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Address of a register on the network (derived from owner's public key).
/// </summary>
public sealed class RegisterAddress : NativeHandle
{
    internal RegisterAddress(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a RegisterAddress from a PublicKey.
    /// </summary>
    public static RegisterAddress FromPublicKey(PublicKey owner)
    {
        ArgumentNullException.ThrowIfNull(owner);
        owner.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.RegisterAddressNew(owner.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "RegisterAddress.FromPublicKey");
        return new RegisterAddress(handle);
    }

    /// <summary>
    /// Creates a RegisterAddress from a hex string.
    /// </summary>
    public static RegisterAddress FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.RegisterAddressFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new RegisterException("Failed to parse register address from hex", status);
        return new RegisterAddress(handle);
    }

    /// <summary>
    /// Gets the owner's PublicKey.
    /// </summary>
    public PublicKey Owner()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.RegisterAddressOwner(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "RegisterAddress.Owner");
        return new PublicKey(handle);
    }

    /// <summary>
    /// Returns the hex representation of this register address.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.RegisterAddressToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "RegisterAddress.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeRegisterAddress(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneRegisterAddress(Handle, ref status);
    }
}

/// <summary>
/// Helper functions for registers.
/// </summary>
public static class RegisterHelpers
{
    /// <summary>
    /// Derives a register key from a secret key and a name.
    /// </summary>
    /// <param name="owner">The owner's secret key.</param>
    /// <param name="name">The name to derive the key from.</param>
    /// <returns>A new PublicKey for the register.</returns>
    public static PublicKey KeyFromName(SecretKey owner, string name)
    {
        ArgumentNullException.ThrowIfNull(owner);
        ArgumentNullException.ThrowIfNull(name);
        owner.ThrowIfDisposed();

        var nameBuffer = UniFFIHelpers.StringToRustBuffer(name);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.RegisterKeyFromName(owner.CloneHandle(), nameBuffer, ref status);
        UniFFIHelpers.CheckStatus(ref status, "RegisterHelpers.KeyFromName");
        return new PublicKey(handle);
    }

    /// <summary>
    /// Creates a 32-byte register value from input bytes.
    /// </summary>
    /// <param name="bytes">Input bytes (will be hashed or padded to 32 bytes).</param>
    /// <returns>A 32-byte register value.</returns>
    public static byte[] ValueFromBytes(byte[] bytes)
    {
        ArgumentNullException.ThrowIfNull(bytes);

        var bytesBuffer = UniFFIHelpers.ToRustBuffer(bytes);
        var status = RustCallStatus.Create();
        var buffer = NativeMethods.RegisterValueFromBytes(bytesBuffer, ref status);
        UniFFIHelpers.CheckStatus(ref status, "RegisterHelpers.ValueFromBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }
}
