using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a client operation fails.
/// </summary>
public class ClientException : AntFfiException
{
    public ClientException(string message) : base(message) { }
    public ClientException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Client for interacting with the Autonomi network.
/// </summary>
/// <remarks>
/// The Client provides methods to store and retrieve data from the network.
/// All network operations are asynchronous.
/// </remarks>
public sealed class Client : NativeHandle
{
    internal Client(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Initializes and connects a new client to the network.
    /// </summary>
    /// <param name="network">The network configuration.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A connected Client instance.</returns>
    public static async Task<Client> InitAsync(Network network, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(network);
        network.ThrowIfDisposed();

        var futureHandle = network.IsLocal
            ? NativeMethods.ClientInitLocal()
            : NativeMethods.ClientInit();
        var handle = await AsyncFutureHelper.PollPointerAsync(futureHandle, cancellationToken);
        return new Client(handle);
    }

    #region Public Data Operations

    /// <summary>
    /// Stores public data on the network.
    /// </summary>
    /// <param name="data">The data to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The address of the stored data.</returns>
    /// <remarks>
    /// The Rust API returns an UploadResult record containing both the price
    /// paid and the hex-encoded data address. This method extracts the address.
    /// </remarks>
    public async Task<DataAddress> DataPutPublicAsync(byte[] data, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(data);
        ArgumentNullException.ThrowIfNull(wallet);
        wallet.ThrowIfDisposed();

        var dataBuffer = UniFFIHelpers.ToRustBuffer(data);
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        // Note: Rust async launcher consumes all RustBuffer params via try_lift, so no need to free them.
        var futureHandle = NativeMethods.ClientDataPutPublic(CloneHandle(), dataBuffer, paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize UploadResult { price: String, address: String }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var _price = reader.ReadString(); // price (unused for now)
        var addressHex = reader.ReadString(); // hex-encoded data address

        return DataAddress.FromHex(addressHex);
    }

    /// <summary>
    /// Retrieves public data from the network.
    /// </summary>
    /// <param name="address">The address of the data to retrieve.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The retrieved data.</returns>
    public async Task<byte[]> DataGetPublicAsync(DataAddress address, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        // Rust expects a hex string, not a DataAddress handle
        var addressHexBuffer = UniFFIHelpers.StringToRustBuffer(address.ToHex());
        var futureHandle = NativeMethods.ClientDataGetPublic(CloneHandle(), addressHexBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    #endregion

    #region Private Data Operations

    /// <summary>
    /// Stores private (encrypted) data on the network.
    /// </summary>
    /// <param name="data">The data to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A DataMapChunk that can be used to retrieve the data.</returns>
    /// <remarks>
    /// Private data is self-encrypted before storage, providing confidentiality.
    /// The returned DataMapChunk must be preserved to retrieve the data later.
    /// </remarks>
    public async Task<DataMapChunk> DataPutAsync(byte[] data, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(data);
        ArgumentNullException.ThrowIfNull(wallet);
        wallet.ThrowIfDisposed();

        var dataBuffer = UniFFIHelpers.ToRustBuffer(data);
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientDataPut(CloneHandle(), dataBuffer, paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize DataPutResult { cost: String, data_map: Arc<DataMapChunk> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var _cost = reader.ReadString(); // cost (unused for now)
        var dataMapPtr = reader.ReadPointer(); // data_map: Arc<DataMapChunk>

        return new DataMapChunk(dataMapPtr);
    }

    /// <summary>
    /// Retrieves private (encrypted) data from the network.
    /// </summary>
    /// <param name="dataMapChunk">The DataMapChunk returned from DataPutAsync.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The decrypted data.</returns>
    public async Task<byte[]> DataGetAsync(DataMapChunk dataMapChunk, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(dataMapChunk);
        dataMapChunk.ThrowIfDisposed();

        var futureHandle = NativeMethods.ClientDataGet(CloneHandle(), dataMapChunk.CloneHandle());
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Estimates the cost to store data on the network.
    /// </summary>
    /// <param name="data">The data to estimate cost for.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The estimated cost as a string (in tokens).</returns>
    public async Task<string> DataCostAsync(byte[] data, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(data);

        var dataBuffer = UniFFIHelpers.ToRustBuffer(data);
        var futureHandle = NativeMethods.ClientDataCost(CloneHandle(), dataBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    #endregion

    #region File Operations

    /// <summary>
    /// Uploads a file to the network as public data.
    /// </summary>
    /// <param name="filePath">The path to the file to upload.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The address of the stored file.</returns>
    public async Task<DataAddress> FileUploadPublicAsync(string filePath, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(filePath);
        ArgumentNullException.ThrowIfNull(wallet);
        wallet.ThrowIfDisposed();

        if (!File.Exists(filePath))
            throw new FileNotFoundException("File not found", filePath);

        var pathBuffer = UniFFIHelpers.StringToRustBuffer(filePath);
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientFileUploadPublic(CloneHandle(), pathBuffer, paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize FileUploadPublicResult { cost: String, address: Arc<DataAddress> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var _cost = reader.ReadString();
        var addressPtr = reader.ReadPointer();

        return new DataAddress(addressPtr);
    }

    /// <summary>
    /// Downloads a file from the network (public data) to a local path.
    /// </summary>
    /// <param name="address">The address of the file to download.</param>
    /// <param name="destPath">The destination path to save the file.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    public async Task FileDownloadPublicAsync(DataAddress address, string destPath, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        ArgumentNullException.ThrowIfNull(destPath);
        address.ThrowIfDisposed();

        var pathBuffer = UniFFIHelpers.StringToRustBuffer(destPath);
        var futureHandle = NativeMethods.ClientFileDownloadPublic(CloneHandle(), address.CloneHandle(), pathBuffer);
        await AsyncFutureHelper.PollVoidAsync(futureHandle, cancellationToken);
    }

    /// <summary>
    /// Uploads a file to the network as private (encrypted) data.
    /// </summary>
    /// <param name="filePath">The path to the file to upload.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>A DataMapChunk that can be used to retrieve the file.</returns>
    public async Task<DataMapChunk> FileUploadAsync(string filePath, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(filePath);
        ArgumentNullException.ThrowIfNull(wallet);
        wallet.ThrowIfDisposed();

        if (!File.Exists(filePath))
            throw new FileNotFoundException("File not found", filePath);

        var pathBuffer = UniFFIHelpers.StringToRustBuffer(filePath);
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientFileUpload(CloneHandle(), pathBuffer, paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize FileUploadResult { cost: String, data_map: Arc<DataMapChunk> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var _cost = reader.ReadString();
        var dataMapPtr = reader.ReadPointer();

        return new DataMapChunk(dataMapPtr);
    }

    /// <summary>
    /// Downloads a file from the network (private data) to a local path.
    /// </summary>
    /// <param name="dataMapChunk">The DataMapChunk returned from FileUploadAsync.</param>
    /// <param name="destPath">The destination path to save the file.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    public async Task FileDownloadAsync(DataMapChunk dataMapChunk, string destPath, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(dataMapChunk);
        ArgumentNullException.ThrowIfNull(destPath);
        dataMapChunk.ThrowIfDisposed();

        var pathBuffer = UniFFIHelpers.StringToRustBuffer(destPath);
        var futureHandle = NativeMethods.ClientFileDownload(CloneHandle(), dataMapChunk.CloneHandle(), pathBuffer);
        await AsyncFutureHelper.PollVoidAsync(futureHandle, cancellationToken);
    }

    /// <summary>
    /// Estimates the cost to upload a file to the network.
    /// </summary>
    /// <param name="filePath">The path to the file.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The estimated cost as a string (in tokens).</returns>
    public async Task<string> FileCostAsync(string filePath, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(filePath);

        if (!File.Exists(filePath))
            throw new FileNotFoundException("File not found", filePath);

        var pathBuffer = UniFFIHelpers.StringToRustBuffer(filePath);
        var futureHandle = NativeMethods.ClientFileCost(CloneHandle(), pathBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    #endregion

    #region Chunk Operations

    /// <summary>
    /// Retrieves a chunk's data from the network.
    /// </summary>
    /// <param name="address">The address of the chunk.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The chunk data as bytes.</returns>
    public async Task<byte[]> ChunkGetAsync(ChunkAddress address, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        // Rust returns Vec<u8>, not Arc<Chunk>
        var futureHandle = NativeMethods.ClientChunkGet(CloneHandle(), address.CloneHandle());
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Stores chunk data on the network.
    /// </summary>
    /// <param name="data">The chunk data to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The cost of storing the chunk.</returns>
    public async Task<string> ChunkPutAsync(byte[] data, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(data);
        ArgumentNullException.ThrowIfNull(wallet);
        wallet.ThrowIfDisposed();

        // Rust takes data: Vec<u8>, payment: PaymentOption
        var dataBuffer = UniFFIHelpers.ToRustBuffer(data);
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientChunkPut(CloneHandle(), dataBuffer, paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize ChunkPutResult { cost: String, address: Arc<ChunkAddress> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var cost = reader.ReadString();
        // address pointer is available but we just return cost for now
        return cost;
    }

    #endregion

    #region Pointer Operations

    /// <summary>
    /// Retrieves a pointer from the network.
    /// </summary>
    /// <param name="address">The address of the pointer.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The network pointer.</returns>
    public async Task<NetworkPointer> PointerGetAsync(PointerAddress address, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var futureHandle = NativeMethods.ClientPointerGet(CloneHandle(), address.CloneHandle());
        var handle = await AsyncFutureHelper.PollPointerAsync(futureHandle, cancellationToken);
        return new NetworkPointer(handle);
    }

    /// <summary>
    /// Stores a pointer on the network.
    /// </summary>
    /// <param name="pointer">The pointer to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The pointer address.</returns>
    public async Task<PointerAddress> PointerPutAsync(NetworkPointer pointer, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(pointer);
        ArgumentNullException.ThrowIfNull(wallet);
        pointer.ThrowIfDisposed();
        wallet.ThrowIfDisposed();

        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        // Rust returns Arc<PointerAddress> -> pointer future
        var futureHandle = NativeMethods.ClientPointerPut(CloneHandle(), pointer.CloneHandle(), paymentBuffer);
        var handle = await AsyncFutureHelper.PollPointerAsync(futureHandle, cancellationToken);
        return new PointerAddress(handle);
    }

    #endregion

    #region Graph Entry Operations

    /// <summary>
    /// Retrieves a graph entry from the network.
    /// </summary>
    /// <param name="address">The address of the graph entry.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The graph entry.</returns>
    public async Task<GraphEntry> GraphEntryGetAsync(GraphEntryAddress address, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var futureHandle = NativeMethods.ClientGraphEntryGet(CloneHandle(), address.CloneHandle());
        var handle = await AsyncFutureHelper.PollPointerAsync(futureHandle, cancellationToken);
        return new GraphEntry(handle);
    }

    /// <summary>
    /// Stores a graph entry on the network.
    /// </summary>
    /// <param name="entry">The graph entry to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The cost of storing the graph entry.</returns>
    public async Task<string> GraphEntryPutAsync(GraphEntry entry, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(entry);
        ArgumentNullException.ThrowIfNull(wallet);
        entry.ThrowIfDisposed();
        wallet.ThrowIfDisposed();

        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientGraphEntryPut(CloneHandle(), entry.CloneHandle(), paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize GraphEntryPutResult { cost: String, address: Arc<GraphEntryAddress> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var cost = reader.ReadString();
        return cost;
    }

    #endregion

    #region Scratchpad Operations

    /// <summary>
    /// Retrieves a scratchpad from the network.
    /// </summary>
    /// <param name="address">The address of the scratchpad.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The scratchpad.</returns>
    public async Task<Scratchpad> ScratchpadGetAsync(ScratchpadAddress address, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var futureHandle = NativeMethods.ClientScratchpadGet(CloneHandle(), address.CloneHandle());
        var handle = await AsyncFutureHelper.PollPointerAsync(futureHandle, cancellationToken);
        return new Scratchpad(handle);
    }

    /// <summary>
    /// Stores a scratchpad on the network.
    /// </summary>
    /// <param name="scratchpad">The scratchpad to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The cost of storing the scratchpad.</returns>
    public async Task<string> ScratchpadPutAsync(Scratchpad scratchpad, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(scratchpad);
        ArgumentNullException.ThrowIfNull(wallet);
        scratchpad.ThrowIfDisposed();
        wallet.ThrowIfDisposed();

        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientScratchpadPut(CloneHandle(), scratchpad.CloneHandle(), paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize ScratchpadCreateResult { cost: String, address: Arc<ScratchpadAddress> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var cost = reader.ReadString();
        return cost;
    }

    #endregion

    #region Register Operations

    /// <summary>
    /// Retrieves a register value from the network.
    /// </summary>
    /// <param name="address">The address of the register.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The register value (32 bytes).</returns>
    public async Task<byte[]> RegisterGetAsync(RegisterAddress address, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var futureHandle = NativeMethods.ClientRegisterGet(CloneHandle(), address.CloneHandle());
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Creates and stores a new register on the network.
    /// </summary>
    /// <param name="value">The initial value (32 bytes).</param>
    /// <param name="owner">The owner's secret key.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The register address.</returns>
    public async Task<RegisterAddress> RegisterCreateAsync(byte[] value, SecretKey owner, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(value);
        ArgumentNullException.ThrowIfNull(owner);
        ArgumentNullException.ThrowIfNull(wallet);
        owner.ThrowIfDisposed();
        wallet.ThrowIfDisposed();

        // Rust signature: register_create(owner: Arc<SecretKey>, value: Vec<u8>, payment: PaymentOption)
        var valueBuffer = UniFFIHelpers.ToRustBuffer(value);
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientRegisterCreate(CloneHandle(), owner.CloneHandle(), valueBuffer, paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize RegisterCreateResult { cost: String, address: Arc<RegisterAddress> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var _cost = reader.ReadString();
        var addressPtr = reader.ReadPointer();

        return new RegisterAddress(addressPtr);
    }

    /// <summary>
    /// Updates an existing register on the network.
    /// </summary>
    /// <param name="value">The new value (32 bytes).</param>
    /// <param name="owner">The owner's secret key.</param>
    /// <param name="wallet">The wallet to pay for the update.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The cost of the update.</returns>
    public async Task<string> RegisterUpdateAsync(byte[] value, SecretKey owner, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(value);
        ArgumentNullException.ThrowIfNull(owner);
        ArgumentNullException.ThrowIfNull(wallet);
        owner.ThrowIfDisposed();
        wallet.ThrowIfDisposed();

        // Rust signature: register_update(owner: Arc<SecretKey>, value: Vec<u8>, payment: PaymentOption)
        var valueBuffer = UniFFIHelpers.ToRustBuffer(value);
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientRegisterUpdate(CloneHandle(), owner.CloneHandle(), valueBuffer, paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    #endregion

    #region Vault Operations

    /// <summary>
    /// Retrieves user data from a vault.
    /// </summary>
    /// <param name="secretKey">The vault secret key.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The user data from the vault.</returns>
    public async Task<UserData> VaultFetchAsync(VaultSecretKey secretKey, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(secretKey);
        secretKey.ThrowIfDisposed();

        var futureHandle = NativeMethods.ClientVaultGetUserData(CloneHandle(), secretKey.CloneHandle());
        var handle = await AsyncFutureHelper.PollPointerAsync(futureHandle, cancellationToken);
        return new UserData(handle);
    }

    /// <summary>
    /// Stores user data in a vault.
    /// </summary>
    /// <param name="secretKey">The vault secret key.</param>
    /// <param name="userData">The user data to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The cost of storing the vault.</returns>
    public async Task<string> VaultStoreAsync(VaultSecretKey secretKey, UserData userData, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(secretKey);
        ArgumentNullException.ThrowIfNull(userData);
        ArgumentNullException.ThrowIfNull(wallet);
        secretKey.ThrowIfDisposed();
        userData.ThrowIfDisposed();
        wallet.ThrowIfDisposed();

        // Rust signature: vault_put_user_data(key, payment, user_data)
        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientVaultPutUserData(CloneHandle(), secretKey.CloneHandle(), paymentBuffer, userData.CloneHandle());
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    #endregion

    #region Archive Operations

    /// <summary>
    /// Retrieves a public archive from the network.
    /// </summary>
    /// <param name="address">The address of the archive.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The public archive.</returns>
    public async Task<PublicArchive> ArchiveGetPublicAsync(ArchiveAddress address, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        address.ThrowIfDisposed();

        var futureHandle = NativeMethods.ClientArchiveGetPublic(CloneHandle(), address.CloneHandle());
        var handle = await AsyncFutureHelper.PollPointerAsync(futureHandle, cancellationToken);
        return new PublicArchive(handle);
    }

    /// <summary>
    /// Stores a public archive on the network.
    /// </summary>
    /// <param name="archive">The archive to store.</param>
    /// <param name="wallet">The wallet to pay for storage.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The address of the stored archive.</returns>
    public async Task<ArchiveAddress> ArchivePutPublicAsync(PublicArchive archive, Wallet wallet, CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(archive);
        ArgumentNullException.ThrowIfNull(wallet);
        archive.ThrowIfDisposed();
        wallet.ThrowIfDisposed();

        var paymentBuffer = UniFFIHelpers.LowerPaymentOption(wallet.CloneHandle());
        var futureHandle = NativeMethods.ClientArchivePutPublic(CloneHandle(), archive.CloneHandle(), paymentBuffer);
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);

        // Deserialize PublicArchivePutResult { cost: String, address: Arc<ArchiveAddress> }
        var raw = buffer.ToBytes();
        var freeStatus = RustCallStatus.Create();
        NativeMethods.FreeRustBuffer(buffer, ref freeStatus);

        var reader = new UniFFIReader(raw);
        var _cost = reader.ReadString();
        var addressPtr = reader.ReadPointer();

        return new ArchiveAddress(addressPtr);
    }

    #endregion

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeClient(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneClient(Handle, ref status);
    }
}
