using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Index for deriving child keys from a master key.
/// </summary>
/// <remarks>
/// DerivationIndex is a 32-byte value used in hierarchical key derivation.
/// </remarks>
public sealed class DerivationIndex : NativeHandle
{
    internal DerivationIndex(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Generates a random derivation index.
    /// </summary>
    public static DerivationIndex Random()
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DerivationIndexRandom(ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivationIndex.Random");
        return new DerivationIndex(handle);
    }

    /// <summary>
    /// Creates a derivation index from 32 bytes.
    /// </summary>
    /// <param name="bytes">Exactly 32 bytes.</param>
    /// <exception cref="KeyException">Thrown if bytes is not exactly 32 bytes.</exception>
    public static DerivationIndex FromBytes(byte[] bytes)
    {
        if (bytes.Length != 32)
            throw new KeyException($"DerivationIndex must be exactly 32 bytes, got {bytes.Length}");

        var buffer = UniFFIHelpers.ToRustBuffer(bytes);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DerivationIndexFromBytes(buffer, ref status);
        if (status.IsError)
            throw new KeyException("Failed to create derivation index", status);
        return new DerivationIndex(handle);
    }

    /// <summary>
    /// Returns the 32-byte representation of this derivation index.
    /// </summary>
    public byte[] ToBytes()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.DerivationIndexToBytes(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivationIndex.ToBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeDerivationIndex(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneDerivationIndex(Handle, ref status);
    }
}

/// <summary>
/// BLS Signature (96 bytes).
/// </summary>
public sealed class Signature : NativeHandle
{
    internal Signature(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a signature from raw bytes (96 bytes for BLS signatures).
    /// </summary>
    /// <param name="bytes">Exactly 96 bytes.</param>
    /// <exception cref="KeyException">Thrown if bytes is invalid.</exception>
    public static Signature FromBytes(byte[] bytes)
    {
        if (bytes.Length != 96)
            throw new KeyException($"Signature must be exactly 96 bytes, got {bytes.Length}");

        var buffer = UniFFIHelpers.ToRustBuffer(bytes);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.SignatureFromBytes(buffer, ref status);
        if (status.IsError)
            throw new KeyException("Failed to create signature", status);
        return new Signature(handle);
    }

    /// <summary>
    /// Returns the 96-byte representation of this signature.
    /// </summary>
    public byte[] ToBytes()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.SignatureToBytes(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Signature.ToBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Returns true if the signature contains an odd number of ones (parity bit).
    /// </summary>
    public bool Parity()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var result = NativeMethods.SignatureParity(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Signature.Parity");
        return result != 0;
    }

    /// <summary>
    /// Returns the hex representation of this signature.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.SignatureToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Signature.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeSignature(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneSignature(Handle, ref status);
    }
}

/// <summary>
/// Master secret key for hierarchical key derivation.
/// Can be used to derive multiple child keys.
/// </summary>
public sealed class MainSecretKey : NativeHandle
{
    internal MainSecretKey(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a MainSecretKey from a SecretKey.
    /// </summary>
    public static MainSecretKey FromSecretKey(SecretKey secretKey)
    {
        ArgumentNullException.ThrowIfNull(secretKey);
        secretKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainSecretKeyNew(secretKey.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainSecretKey.FromSecretKey");
        return new MainSecretKey(handle);
    }

    /// <summary>
    /// Generates a random MainSecretKey.
    /// </summary>
    public static MainSecretKey Random()
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainSecretKeyRandom(ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainSecretKey.Random");
        return new MainSecretKey(handle);
    }

    /// <summary>
    /// Returns the matching MainPubkey.
    /// </summary>
    public MainPubkey PublicKey()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainSecretKeyPublicKey(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainSecretKey.PublicKey");
        return new MainPubkey(handle);
    }

    /// <summary>
    /// Signs a message with this secret key.
    /// </summary>
    /// <param name="message">The message to sign.</param>
    /// <returns>The signature.</returns>
    public Signature Sign(byte[] message)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(message);

        var msgBuffer = UniFFIHelpers.ToRustBuffer(message);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainSecretKeySign(CloneHandle(), msgBuffer, ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainSecretKey.Sign");
        return new Signature(handle);
    }

    /// <summary>
    /// Derives a DerivedSecretKey from this master key using the given index.
    /// </summary>
    public DerivedSecretKey DeriveKey(DerivationIndex index)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(index);
        index.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainSecretKeyDeriveKey(CloneHandle(), index.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainSecretKey.DeriveKey");
        return new DerivedSecretKey(handle);
    }

    /// <summary>
    /// Generates a new random DerivedSecretKey from this master key.
    /// </summary>
    public DerivedSecretKey RandomDerivedKey()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainSecretKeyRandomDerivedKey(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainSecretKey.RandomDerivedKey");
        return new DerivedSecretKey(handle);
    }

    /// <summary>
    /// Returns the raw bytes of the secret key.
    /// </summary>
    public byte[] ToBytes()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.MainSecretKeyToBytes(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainSecretKey.ToBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeMainSecretKey(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneMainSecretKey(Handle, ref status);
    }
}

/// <summary>
/// Master public key for hierarchical key derivation.
/// </summary>
public sealed class MainPubkey : NativeHandle
{
    internal MainPubkey(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a MainPubkey from a PublicKey.
    /// </summary>
    public static MainPubkey FromPublicKey(PublicKey publicKey)
    {
        ArgumentNullException.ThrowIfNull(publicKey);
        publicKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainPubkeyNew(publicKey.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainPubkey.FromPublicKey");
        return new MainPubkey(handle);
    }

    /// <summary>
    /// Creates a MainPubkey from a hex string.
    /// </summary>
    public static MainPubkey FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainPubkeyFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new KeyException("Failed to parse MainPubkey from hex", status);
        return new MainPubkey(handle);
    }

    /// <summary>
    /// Verifies that a signature is valid for the given message.
    /// </summary>
    public bool Verify(Signature signature, byte[] message)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(signature);
        ArgumentNullException.ThrowIfNull(message);
        signature.ThrowIfDisposed();

        var msgBuffer = UniFFIHelpers.ToRustBuffer(message);
        var status = RustCallStatus.Create();
        var result = NativeMethods.MainPubkeyVerify(CloneHandle(), signature.CloneHandle(), msgBuffer, ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainPubkey.Verify");
        return result != 0;
    }

    /// <summary>
    /// Derives a DerivedPubkey from this master public key using the given index.
    /// </summary>
    public DerivedPubkey DeriveKey(DerivationIndex index)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(index);
        index.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.MainPubkeyDeriveKey(CloneHandle(), index.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainPubkey.DeriveKey");
        return new DerivedPubkey(handle);
    }

    /// <summary>
    /// Returns the bytes representation of this public key.
    /// </summary>
    public byte[] ToBytes()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.MainPubkeyToBytes(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainPubkey.ToBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Returns the hex representation of this public key.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.MainPubkeyToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "MainPubkey.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeMainPubkey(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneMainPubkey(Handle, ref status);
    }
}

/// <summary>
/// Derived secret key from hierarchical key derivation.
/// </summary>
public sealed class DerivedSecretKey : NativeHandle
{
    internal DerivedSecretKey(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a DerivedSecretKey from a SecretKey.
    /// </summary>
    public static DerivedSecretKey FromSecretKey(SecretKey secretKey)
    {
        ArgumentNullException.ThrowIfNull(secretKey);
        secretKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.DerivedSecretKeyNew(secretKey.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivedSecretKey.FromSecretKey");
        return new DerivedSecretKey(handle);
    }

    /// <summary>
    /// Gets the corresponding DerivedPubkey.
    /// </summary>
    public DerivedPubkey PublicKey()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DerivedSecretKeyPublicKey(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivedSecretKey.PublicKey");
        return new DerivedPubkey(handle);
    }

    /// <summary>
    /// Signs a message with this derived secret key.
    /// </summary>
    public Signature Sign(byte[] message)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(message);

        var msgBuffer = UniFFIHelpers.ToRustBuffer(message);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DerivedSecretKeySign(CloneHandle(), msgBuffer, ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivedSecretKey.Sign");
        return new Signature(handle);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeDerivedSecretKey(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneDerivedSecretKey(Handle, ref status);
    }
}

/// <summary>
/// Derived public key from hierarchical key derivation.
/// </summary>
public sealed class DerivedPubkey : NativeHandle
{
    internal DerivedPubkey(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a DerivedPubkey from a PublicKey.
    /// </summary>
    public static DerivedPubkey FromPublicKey(PublicKey publicKey)
    {
        ArgumentNullException.ThrowIfNull(publicKey);
        publicKey.ThrowIfDisposed();

        var status = RustCallStatus.Create();
        var handle = NativeMethods.DerivedPubkeyNew(publicKey.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivedPubkey.FromPublicKey");
        return new DerivedPubkey(handle);
    }

    /// <summary>
    /// Creates a DerivedPubkey from a hex string.
    /// </summary>
    public static DerivedPubkey FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DerivedPubkeyFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new KeyException("Failed to parse DerivedPubkey from hex", status);
        return new DerivedPubkey(handle);
    }

    /// <summary>
    /// Verifies that a signature is valid for the given message.
    /// </summary>
    public bool Verify(Signature signature, byte[] message)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(signature);
        ArgumentNullException.ThrowIfNull(message);
        signature.ThrowIfDisposed();

        var msgBuffer = UniFFIHelpers.ToRustBuffer(message);
        var status = RustCallStatus.Create();
        var result = NativeMethods.DerivedPubkeyVerify(CloneHandle(), signature.CloneHandle(), msgBuffer, ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivedPubkey.Verify");
        return result != 0;
    }

    /// <summary>
    /// Returns the bytes representation of this public key.
    /// </summary>
    public byte[] ToBytes()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.DerivedPubkeyToBytes(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivedPubkey.ToBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Returns the hex representation of this public key.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.DerivedPubkeyToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DerivedPubkey.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeDerivedPubkey(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneDerivedPubkey(Handle, ref status);
    }
}
