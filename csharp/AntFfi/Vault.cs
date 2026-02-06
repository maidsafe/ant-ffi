using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a vault operation fails.
/// </summary>
public class VaultException : AntFfiException
{
    public VaultException(string message) : base(message) { }
    public VaultException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Secret key for vault encryption/decryption.
/// </summary>
public sealed class VaultSecretKey : NativeHandle
{
    internal VaultSecretKey(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Generates a random VaultSecretKey.
    /// </summary>
    public static VaultSecretKey Random()
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.VaultSecretKeyRandom(ref status);
        UniFFIHelpers.CheckStatus(ref status, "VaultSecretKey.Random");
        return new VaultSecretKey(handle);
    }

    /// <summary>
    /// Creates a VaultSecretKey from a hex string.
    /// </summary>
    public static VaultSecretKey FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.VaultSecretKeyFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new VaultException("Failed to parse vault secret key from hex", status);
        return new VaultSecretKey(handle);
    }

    /// <summary>
    /// Returns the hex representation of this vault secret key.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.VaultSecretKeyToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "VaultSecretKey.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeVaultSecretKey(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneVaultSecretKey(Handle, ref status);
    }
}

/// <summary>
/// Container for user's file archive references.
/// </summary>
/// <remarks>
/// UserData stores references to both public and private file archives,
/// allowing users to track their stored files on the network.
/// </remarks>
public sealed class UserData : NativeHandle
{
    internal UserData(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a new empty UserData container.
    /// </summary>
    public static UserData Create()
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.UserDataNew(ref status);
        UniFFIHelpers.CheckStatus(ref status, "UserData.Create");
        return new UserData(handle);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeUserData(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneUserData(Handle, ref status);
    }
}
