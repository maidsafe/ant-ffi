using System.Runtime.InteropServices;

namespace AntFfi.Native;

/// <summary>
/// P/Invoke declarations for the ant_ffi native library.
/// </summary>
internal static partial class NativeMethods
{
    private const string LibName = "ant_ffi";

    #region Buffer Management

    /// <summary>
    /// Creates a RustBuffer from foreign bytes.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rustbuffer_from_bytes")]
    public static extern RustBuffer RustBufferFromBytes(ForeignBytes bytes, ref RustCallStatus status);

    /// <summary>
    /// Frees a RustBuffer.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rustbuffer_free")]
    public static extern void FreeRustBuffer(RustBuffer buf, ref RustCallStatus status);

    /// <summary>
    /// Allocates an empty RustBuffer with the specified capacity.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rustbuffer_alloc")]
    public static extern RustBuffer AllocRustBuffer(ulong size, ref RustCallStatus status);

    #endregion

    #region Handle Cloning
    // UniFFI uses Arc::from_raw in try_lift, which consumes one Arc reference.
    // Every method/constructor call that takes an object handle must clone it first
    // to avoid use-after-free. These functions call Arc::increment_strong_count.

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_secretkey")]
    public static extern IntPtr CloneSecretKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_publickey")]
    public static extern IntPtr ClonePublicKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_derivationindex")]
    public static extern IntPtr CloneDerivationIndex(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_signature")]
    public static extern IntPtr CloneSignature(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_mainsecretkey")]
    public static extern IntPtr CloneMainSecretKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_mainpubkey")]
    public static extern IntPtr CloneMainPubkey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_derivedsecretkey")]
    public static extern IntPtr CloneDerivedSecretKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_derivedpubkey")]
    public static extern IntPtr CloneDerivedPubkey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_chunk")]
    public static extern IntPtr CloneChunk(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_chunkaddress")]
    public static extern IntPtr CloneChunkAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_dataaddress")]
    public static extern IntPtr CloneDataAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_datamapchunk")]
    public static extern IntPtr CloneDataMapChunk(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_metadata")]
    public static extern IntPtr CloneMetadata(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_archiveaddress")]
    public static extern IntPtr CloneArchiveAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_privatearchivedatamap")]
    public static extern IntPtr ClonePrivateArchiveDataMap(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_publicarchive")]
    public static extern IntPtr ClonePublicArchive(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_privatearchive")]
    public static extern IntPtr ClonePrivateArchive(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_pointeraddress")]
    public static extern IntPtr ClonePointerAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_pointertarget")]
    public static extern IntPtr ClonePointerTarget(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_networkpointer")]
    public static extern IntPtr CloneNetworkPointer(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_scratchpadaddress")]
    public static extern IntPtr CloneScratchpadAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_scratchpad")]
    public static extern IntPtr CloneScratchpad(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_registeraddress")]
    public static extern IntPtr CloneRegisterAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_graphentryaddress")]
    public static extern IntPtr CloneGraphEntryAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_graphentry")]
    public static extern IntPtr CloneGraphEntry(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_vaultsecretkey")]
    public static extern IntPtr CloneVaultSecretKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_userdata")]
    public static extern IntPtr CloneUserData(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_network")]
    public static extern IntPtr CloneNetwork(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_wallet")]
    public static extern IntPtr CloneWallet(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_client")]
    public static extern IntPtr CloneClient(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_clone_datastream")]
    public static extern IntPtr CloneDataStream(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Self-Encryption

    /// <summary>
    /// Encrypts data using self-encryption.
    /// </summary>
    /// <param name="data">The data to encrypt (serialized with UniFFI format).</param>
    /// <param name="status">Status of the call.</param>
    /// <returns>The encrypted data as a RustBuffer.</returns>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_func_encrypt")]
    public static extern RustBuffer Encrypt(RustBuffer data, ref RustCallStatus status);

    /// <summary>
    /// Decrypts self-encrypted data.
    /// </summary>
    /// <param name="encryptedData">The encrypted data to decrypt.</param>
    /// <param name="status">Status of the call.</param>
    /// <returns>The decrypted data as a RustBuffer.</returns>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_func_decrypt")]
    public static extern RustBuffer Decrypt(RustBuffer encryptedData, ref RustCallStatus status);

    #endregion

    #region Keys

    /// <summary>
    /// Creates a new random SecretKey.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_secretkey_random")]
    public static extern IntPtr SecretKeyRandom(ref RustCallStatus status);

    /// <summary>
    /// Creates a SecretKey from a hex string.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_secretkey_from_hex")]
    public static extern IntPtr SecretKeyFromHex(RustBuffer hex, ref RustCallStatus status);

    /// <summary>
    /// Converts a SecretKey to a hex string.
    /// Uses out parameter to fix Windows x64 struct return ABI.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_secretkey_to_hex")]
    public static extern void SecretKeyToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    /// <summary>
    /// Gets the PublicKey from a SecretKey.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_secretkey_public_key")]
    public static extern IntPtr SecretKeyPublicKey(IntPtr ptr, ref RustCallStatus status);

    /// <summary>
    /// Frees a SecretKey.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_secretkey")]
    public static extern void FreeSecretKey(IntPtr ptr, ref RustCallStatus status);

    /// <summary>
    /// Creates a PublicKey from a hex string.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_publickey_from_hex")]
    public static extern IntPtr PublicKeyFromHex(RustBuffer hex, ref RustCallStatus status);

    /// <summary>
    /// Converts a PublicKey to a hex string.
    /// Uses out parameter to fix Windows x64 struct return ABI.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_publickey_to_hex")]
    public static extern void PublicKeyToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    /// <summary>
    /// Frees a PublicKey.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_publickey")]
    public static extern void FreePublicKey(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Key Derivation - DerivationIndex

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_derivationindex_random")]
    public static extern IntPtr DerivationIndexRandom(ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes")]
    public static extern IntPtr DerivationIndexFromBytes(RustBuffer bytes, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_derivationindex_to_bytes")]
    public static extern void DerivationIndexToBytes(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_derivationindex")]
    public static extern void FreeDerivationIndex(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Key Derivation - Signature

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_signature_from_bytes")]
    public static extern IntPtr SignatureFromBytes(RustBuffer bytes, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_signature_to_bytes")]
    public static extern void SignatureToBytes(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_signature_parity")]
    public static extern sbyte SignatureParity(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_signature_to_hex")]
    public static extern void SignatureToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_signature")]
    public static extern void FreeSignature(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Key Derivation - MainSecretKey

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_mainsecretkey_new")]
    public static extern IntPtr MainSecretKeyNew(IntPtr secretKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_mainsecretkey_random")]
    public static extern IntPtr MainSecretKeyRandom(ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainsecretkey_public_key")]
    public static extern IntPtr MainSecretKeyPublicKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainsecretkey_sign")]
    public static extern IntPtr MainSecretKeySign(IntPtr ptr, RustBuffer msg, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainsecretkey_derive_key")]
    public static extern IntPtr MainSecretKeyDeriveKey(IntPtr ptr, IntPtr index, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key")]
    public static extern IntPtr MainSecretKeyRandomDerivedKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes")]
    public static extern void MainSecretKeyToBytes(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_mainsecretkey")]
    public static extern void FreeMainSecretKey(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Key Derivation - MainPubkey

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_mainpubkey_new")]
    public static extern IntPtr MainPubkeyNew(IntPtr publicKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex")]
    public static extern IntPtr MainPubkeyFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainpubkey_verify")]
    public static extern sbyte MainPubkeyVerify(IntPtr ptr, IntPtr signature, RustBuffer msg, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainpubkey_derive_key")]
    public static extern IntPtr MainPubkeyDeriveKey(IntPtr ptr, IntPtr index, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainpubkey_to_bytes")]
    public static extern void MainPubkeyToBytes(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_mainpubkey_to_hex")]
    public static extern void MainPubkeyToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_mainpubkey")]
    public static extern void FreeMainPubkey(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Key Derivation - DerivedSecretKey

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_derivedsecretkey_new")]
    public static extern IntPtr DerivedSecretKeyNew(IntPtr secretKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_derivedsecretkey_public_key")]
    public static extern IntPtr DerivedSecretKeyPublicKey(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_derivedsecretkey_sign")]
    public static extern IntPtr DerivedSecretKeySign(IntPtr ptr, RustBuffer msg, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_derivedsecretkey")]
    public static extern void FreeDerivedSecretKey(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Key Derivation - DerivedPubkey

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_derivedpubkey_new")]
    public static extern IntPtr DerivedPubkeyNew(IntPtr publicKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex")]
    public static extern IntPtr DerivedPubkeyFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_derivedpubkey_verify")]
    public static extern sbyte DerivedPubkeyVerify(IntPtr ptr, IntPtr signature, RustBuffer msg, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes")]
    public static extern void DerivedPubkeyToBytes(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_derivedpubkey_to_hex")]
    public static extern void DerivedPubkeyToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_derivedpubkey")]
    public static extern void FreeDerivedPubkey(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Data - Chunk

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_chunk_new")]
    public static extern IntPtr ChunkNew(RustBuffer value, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_chunk_value")]
    public static extern void ChunkValue(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_chunk_address")]
    public static extern IntPtr ChunkAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_chunk_network_address")]
    public static extern void ChunkNetworkAddress(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_chunk_size")]
    public static extern ulong ChunkSize(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_chunk_is_too_big")]
    public static extern sbyte ChunkIsTooBig(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_chunk")]
    public static extern void FreeChunk(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Data - ChunkAddress

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_chunkaddress_new")]
    public static extern IntPtr ChunkAddressNew(RustBuffer bytes, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_chunkaddress_from_content")]
    public static extern IntPtr ChunkAddressFromContent(RustBuffer data, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex")]
    public static extern IntPtr ChunkAddressFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_chunkaddress_to_hex")]
    public static extern void ChunkAddressToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_chunkaddress_to_bytes")]
    public static extern void ChunkAddressToBytes(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_chunkaddress")]
    public static extern void FreeChunkAddress(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Data - DataAddress

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_dataaddress_new")]
    public static extern IntPtr DataAddressNew(RustBuffer bytes, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_dataaddress_from_hex")]
    public static extern IntPtr DataAddressFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_dataaddress_to_hex")]
    public static extern void DataAddressToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_dataaddress_to_bytes")]
    public static extern void DataAddressToBytes(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_dataaddress")]
    public static extern void FreeDataAddress(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Data - DataMapChunk

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex")]
    public static extern IntPtr DataMapChunkFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_datamapchunk_to_hex")]
    public static extern void DataMapChunkToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_datamapchunk_address")]
    public static extern void DataMapChunkAddress(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_datamapchunk")]
    public static extern void FreeDataMapChunk(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Data - Constants

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_func_chunk_max_size")]
    public static extern ulong ChunkMaxSize(ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_func_chunk_max_raw_size")]
    public static extern ulong ChunkMaxRawSize(ref RustCallStatus status);

    #endregion

    #region Archive - Metadata

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_metadata_new")]
    public static extern IntPtr MetadataNew(ulong size, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_metadata_with_timestamps")]
    public static extern IntPtr MetadataWithTimestamps(ulong size, ulong created, ulong modified, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_metadata_size")]
    public static extern ulong MetadataSize(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_metadata_created")]
    public static extern ulong MetadataCreated(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_metadata_modified")]
    public static extern ulong MetadataModified(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_metadata")]
    public static extern void FreeMetadata(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Archive - ArchiveAddress

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex")]
    public static extern IntPtr ArchiveAddressFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_archiveaddress_to_hex")]
    public static extern void ArchiveAddressToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_archiveaddress")]
    public static extern void FreeArchiveAddress(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Archive - PrivateArchiveDataMap

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex")]
    public static extern IntPtr PrivateArchiveDataMapFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex")]
    public static extern void PrivateArchiveDataMapToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_privatearchivedatamap")]
    public static extern void FreePrivateArchiveDataMap(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Archive - PublicArchive

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_publicarchive_new")]
    public static extern IntPtr PublicArchiveNew(ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_publicarchive_add_file")]
    public static extern IntPtr PublicArchiveAddFile(IntPtr ptr, RustBuffer path, IntPtr address, IntPtr metadata, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_publicarchive_rename_file")]
    public static extern IntPtr PublicArchiveRenameFile(IntPtr ptr, RustBuffer oldPath, RustBuffer newPath, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_publicarchive_files")]
    public static extern void PublicArchiveFiles(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_publicarchive_file_count")]
    public static extern ulong PublicArchiveFileCount(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_publicarchive_addresses")]
    public static extern void PublicArchiveAddresses(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_publicarchive")]
    public static extern void FreePublicArchive(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Archive - PrivateArchive

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_privatearchive_new")]
    public static extern IntPtr PrivateArchiveNew(ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_privatearchive_add_file")]
    public static extern IntPtr PrivateArchiveAddFile(IntPtr ptr, RustBuffer path, IntPtr dataMap, IntPtr metadata, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_privatearchive_rename_file")]
    public static extern IntPtr PrivateArchiveRenameFile(IntPtr ptr, RustBuffer oldPath, RustBuffer newPath, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_privatearchive_files")]
    public static extern void PrivateArchiveFiles(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_privatearchive_file_count")]
    public static extern ulong PrivateArchiveFileCount(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_privatearchive_data_maps")]
    public static extern void PrivateArchiveDataMaps(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_privatearchive")]
    public static extern void FreePrivateArchive(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Pointer - PointerAddress

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_pointeraddress_new")]
    public static extern IntPtr PointerAddressNew(IntPtr publicKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex")]
    public static extern IntPtr PointerAddressFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_pointeraddress_owner")]
    public static extern IntPtr PointerAddressOwner(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_pointeraddress_to_hex")]
    public static extern void PointerAddressToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_pointeraddress")]
    public static extern void FreePointerAddress(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Pointer - PointerTarget

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_pointertarget_chunk")]
    public static extern IntPtr PointerTargetChunk(IntPtr addr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_pointertarget_pointer")]
    public static extern IntPtr PointerTargetPointer(IntPtr addr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_pointertarget_graph_entry")]
    public static extern IntPtr PointerTargetGraphEntry(IntPtr addr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_pointertarget_scratchpad")]
    public static extern IntPtr PointerTargetScratchpad(IntPtr addr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_pointertarget_to_hex")]
    public static extern void PointerTargetToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_pointertarget")]
    public static extern void FreePointerTarget(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Pointer - NetworkPointer

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_networkpointer_new")]
    public static extern IntPtr NetworkPointerNew(IntPtr key, ulong counter, IntPtr target, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_networkpointer_address")]
    public static extern IntPtr NetworkPointerAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_networkpointer_target")]
    public static extern IntPtr NetworkPointerTarget(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_networkpointer_counter")]
    public static extern ulong NetworkPointerCounter(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_networkpointer")]
    public static extern void FreeNetworkPointer(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Scratchpad - ScratchpadAddress

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_scratchpadaddress_new")]
    public static extern IntPtr ScratchpadAddressNew(IntPtr publicKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex")]
    public static extern IntPtr ScratchpadAddressFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpadaddress_owner")]
    public static extern IntPtr ScratchpadAddressOwner(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex")]
    public static extern void ScratchpadAddressToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_scratchpadaddress")]
    public static extern void FreeScratchpadAddress(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Scratchpad - Scratchpad

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_scratchpad_new")]
    public static extern IntPtr ScratchpadNew(IntPtr owner, ulong dataEncoding, RustBuffer data, ulong counter, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpad_address")]
    public static extern IntPtr ScratchpadAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpad_data_encoding")]
    public static extern ulong ScratchpadDataEncoding(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpad_counter")]
    public static extern ulong ScratchpadCounter(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpad_decrypt_data")]
    public static extern void ScratchpadDecryptData(out RustBuffer result, IntPtr ptr, IntPtr secretKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpad_owner")]
    public static extern IntPtr ScratchpadOwner(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_scratchpad_encrypted_data")]
    public static extern void ScratchpadEncryptedData(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_scratchpad")]
    public static extern void FreeScratchpad(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Register - RegisterAddress

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_registeraddress_new")]
    public static extern IntPtr RegisterAddressNew(IntPtr owner, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_registeraddress_from_hex")]
    public static extern IntPtr RegisterAddressFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_registeraddress_owner")]
    public static extern IntPtr RegisterAddressOwner(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_registeraddress_to_hex")]
    public static extern void RegisterAddressToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_registeraddress")]
    public static extern void FreeRegisterAddress(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Register - Functions

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_func_register_key_from_name")]
    public static extern IntPtr RegisterKeyFromName(IntPtr owner, RustBuffer name, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_func_register_value_from_bytes")]
    public static extern RustBuffer RegisterValueFromBytes(RustBuffer bytes, ref RustCallStatus status);

    #endregion

    #region GraphEntry - GraphEntryAddress

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_graphentryaddress_new")]
    public static extern IntPtr GraphEntryAddressNew(IntPtr publicKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex")]
    public static extern IntPtr GraphEntryAddressFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_graphentryaddress_to_hex")]
    public static extern void GraphEntryAddressToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_graphentryaddress")]
    public static extern void FreeGraphEntryAddress(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region GraphEntry - GraphEntry

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_graphentry_new")]
    public static extern IntPtr GraphEntryNew(IntPtr owner, RustBuffer parents, RustBuffer content, RustBuffer descendants, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_graphentry_address")]
    public static extern IntPtr GraphEntryAddress(IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_graphentry_content")]
    public static extern void GraphEntryContent(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_graphentry_parents")]
    public static extern void GraphEntryParents(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_graphentry_descendants")]
    public static extern void GraphEntryDescendants(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_graphentry")]
    public static extern void FreeGraphEntry(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Vault - VaultSecretKey

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_vaultsecretkey_random")]
    public static extern IntPtr VaultSecretKeyRandom(ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex")]
    public static extern IntPtr VaultSecretKeyFromHex(RustBuffer hex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex")]
    public static extern void VaultSecretKeyToHex(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_vaultsecretkey")]
    public static extern void FreeVaultSecretKey(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Vault - UserData

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_userdata_new")]
    public static extern IntPtr UserDataNew(ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_userdata_file_archives")]
    public static extern void UserDataFileArchives(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_userdata_private_file_archives")]
    public static extern void UserDataPrivateFileArchives(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_userdata")]
    public static extern void FreeUserData(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Network

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_network_new")]
    public static extern IntPtr NetworkNew(sbyte isLocal, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_network_custom")]
    public static extern IntPtr NetworkCustom(RustBuffer rpcUrl, RustBuffer paymentTokenAddress, RustBuffer dataPaymentsAddress, RustBuffer royaltiesPkHex, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_network")]
    public static extern void FreeNetwork(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Wallet

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key")]
    public static extern IntPtr WalletFromPrivateKey(IntPtr network, RustBuffer privateKey, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_wallet_address")]
    public static extern void WalletAddress(out RustBuffer result, IntPtr ptr, ref RustCallStatus status);

    /// <summary>
    /// Async: Returns a future handle for balance_of_tokens.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_wallet_balance_of_tokens")]
    public static extern ulong WalletBalanceOfTokens(IntPtr ptr);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_wallet")]
    public static extern void FreeWallet(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Client - Constructors (Async)

    /// <summary>
    /// Async: Returns a future handle for client initialization with a network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_client_init")]
    public static extern ulong ClientInit();

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_constructor_client_init_local")]
    public static extern ulong ClientInitLocal();

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_free_client")]
    public static extern void FreeClient(IntPtr ptr, ref RustCallStatus status);

    #endregion

    #region Client - Data Operations (Async)

    /// <summary>
    /// Async: Stores public data on the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_data_put_public")]
    public static extern ulong ClientDataPutPublic(IntPtr ptr, RustBuffer data, RustBuffer payment);

    /// <summary>
    /// Async: Retrieves public data from the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_data_get_public")]
    public static extern ulong ClientDataGetPublic(IntPtr ptr, RustBuffer addressHex);

    /// <summary>
    /// Async: Stores private (encrypted) data on the network.
    /// Returns a DataMapChunk that can be used to retrieve the data.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_data_put")]
    public static extern ulong ClientDataPut(IntPtr ptr, RustBuffer data, RustBuffer payment);

    /// <summary>
    /// Async: Retrieves private (encrypted) data from the network using a DataMapChunk.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_data_get")]
    public static extern ulong ClientDataGet(IntPtr ptr, IntPtr dataMapChunk);

    /// <summary>
    /// Async: Estimates the cost to store data on the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_data_cost")]
    public static extern ulong ClientDataCost(IntPtr ptr, RustBuffer data);

    #endregion

    #region Client - File Operations (Async)

    /// <summary>
    /// Async: Uploads a file to the network as public data.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_file_upload_public")]
    public static extern ulong ClientFileUploadPublic(IntPtr ptr, RustBuffer filePath, RustBuffer payment);

    /// <summary>
    /// Async: Downloads a file from the network (public data).
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_file_download_public")]
    public static extern ulong ClientFileDownloadPublic(IntPtr ptr, IntPtr address, RustBuffer destPath);

    /// <summary>
    /// Async: Uploads a file to the network as private (encrypted) data.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_file_upload")]
    public static extern ulong ClientFileUpload(IntPtr ptr, RustBuffer filePath, RustBuffer payment);

    /// <summary>
    /// Async: Downloads a file from the network (private data).
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_file_download")]
    public static extern ulong ClientFileDownload(IntPtr ptr, IntPtr dataMapChunk, RustBuffer destPath);

    /// <summary>
    /// Async: Estimates the cost to upload a file to the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_file_cost")]
    public static extern ulong ClientFileCost(IntPtr ptr, RustBuffer filePath, sbyte followSymlinks, sbyte includeHidden);

    #endregion

    #region Client - Chunk Operations (Async)

    /// <summary>
    /// Async: Stores a chunk on the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_chunk_put")]
    public static extern ulong ClientChunkPut(IntPtr ptr, RustBuffer data, RustBuffer payment);

    /// <summary>
    /// Async: Retrieves a chunk from the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_chunk_get")]
    public static extern ulong ClientChunkGet(IntPtr ptr, IntPtr address);

    #endregion

    #region Client - Pointer Operations (Async)

    /// <summary>
    /// Async: Retrieves a pointer from the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_pointer_get")]
    public static extern ulong ClientPointerGet(IntPtr ptr, IntPtr address);

    /// <summary>
    /// Async: Stores a pointer on the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_pointer_put")]
    public static extern ulong ClientPointerPut(IntPtr ptr, IntPtr pointer, RustBuffer payment);

    #endregion

    #region Client - GraphEntry Operations (Async)

    /// <summary>
    /// Async: Retrieves a graph entry from the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_graph_entry_get")]
    public static extern ulong ClientGraphEntryGet(IntPtr ptr, IntPtr address);

    /// <summary>
    /// Async: Stores a graph entry on the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_graph_entry_put")]
    public static extern ulong ClientGraphEntryPut(IntPtr ptr, IntPtr entry, RustBuffer payment);

    #endregion

    #region Client - Scratchpad Operations (Async)

    /// <summary>
    /// Async: Retrieves a scratchpad from the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_scratchpad_get")]
    public static extern ulong ClientScratchpadGet(IntPtr ptr, IntPtr address);

    /// <summary>
    /// Async: Stores a scratchpad on the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_scratchpad_put")]
    public static extern ulong ClientScratchpadPut(IntPtr ptr, IntPtr scratchpad, RustBuffer payment);

    #endregion

    #region Client - Register Operations (Async)

    /// <summary>
    /// Async: Retrieves a register value from the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_register_get")]
    public static extern ulong ClientRegisterGet(IntPtr ptr, IntPtr address);

    /// <summary>
    /// Async: Creates a new register on the network.
    /// Rust signature: register_create(owner: Arc&lt;SecretKey&gt;, value: Vec&lt;u8&gt;, payment: PaymentOption)
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_register_create")]
    public static extern ulong ClientRegisterCreate(IntPtr ptr, IntPtr owner, RustBuffer value, RustBuffer payment);

    /// <summary>
    /// Async: Updates an existing register on the network.
    /// Rust signature: register_update(owner: Arc&lt;SecretKey&gt;, value: Vec&lt;u8&gt;, payment: PaymentOption)
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_register_update")]
    public static extern ulong ClientRegisterUpdate(IntPtr ptr, IntPtr owner, RustBuffer value, RustBuffer payment);

    #endregion

    #region Client - Vault Operations (Async)

    /// <summary>
    /// Async: Retrieves user data from a vault.
    /// Rust signature: vault_get_user_data(key: Arc&lt;VaultSecretKey&gt;)
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_vault_get_user_data")]
    public static extern ulong ClientVaultGetUserData(IntPtr ptr, IntPtr secretKey);

    /// <summary>
    /// Async: Stores user data in a vault.
    /// Rust signature: vault_put_user_data(key: Arc&lt;VaultSecretKey&gt;, payment: PaymentOption, user_data: Arc&lt;UserData&gt;)
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_vault_put_user_data")]
    public static extern ulong ClientVaultPutUserData(IntPtr ptr, IntPtr secretKey, RustBuffer payment, IntPtr userData);

    #endregion

    #region Client - Archive Operations (Async)

    /// <summary>
    /// Async: Retrieves a public archive from the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_archive_get_public")]
    public static extern ulong ClientArchiveGetPublic(IntPtr ptr, IntPtr address);

    /// <summary>
    /// Async: Stores a public archive on the network.
    /// </summary>
    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "uniffi_ant_ffi_fn_method_client_archive_put_public")]
    public static extern ulong ClientArchivePutPublic(IntPtr ptr, IntPtr archive, RustBuffer payment);

    #endregion
}
