using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a data operation fails.
/// </summary>
public class DataException : AntFfiException
{
    public DataException(string message) : base(message) { }
    public DataException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Provides constants for chunk size limits.
/// </summary>
public static class ChunkConstants
{
    private static ulong? _maxSize;
    private static ulong? _maxRawSize;

    /// <summary>
    /// Gets the maximum size of an encrypted chunk (4MB + 32 bytes).
    /// </summary>
    public static ulong MaxSize
    {
        get
        {
            if (!_maxSize.HasValue)
            {
                var status = RustCallStatus.Create();
                _maxSize = NativeMethods.ChunkMaxSize(ref status);
            }
            return _maxSize.Value;
        }
    }

    /// <summary>
    /// Gets the maximum size of raw unencrypted data (4MB).
    /// </summary>
    public static ulong MaxRawSize
    {
        get
        {
            if (!_maxRawSize.HasValue)
            {
                var status = RustCallStatus.Create();
                _maxRawSize = NativeMethods.ChunkMaxRawSize(ref status);
            }
            return _maxRawSize.Value;
        }
    }
}

/// <summary>
/// Content-addressable data storage chunk.
/// </summary>
/// <remarks>
/// Chunks are the fundamental unit of storage in the Autonomi network.
/// Each chunk has an address derived from its content (content-addressable storage).
/// </remarks>
public sealed class Chunk : NativeHandle
{
    internal Chunk(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a new chunk from the given data.
    /// </summary>
    /// <param name="value">The data to store in the chunk.</param>
    /// <returns>A new chunk containing the data.</returns>
    public static Chunk Create(byte[] value)
    {
        ArgumentNullException.ThrowIfNull(value);

        var buffer = UniFFIHelpers.ToRustBuffer(value);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ChunkNew(buffer, ref status);
        if (status.IsError)
            throw new DataException("Failed to create chunk", status);
        return new Chunk(handle);
    }

    /// <summary>
    /// Gets the content of this chunk.
    /// </summary>
    public byte[] Value()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.ChunkValue(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Chunk.Value");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <summary>
    /// Gets the address of this chunk.
    /// </summary>
    public ChunkAddress Address()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ChunkAddress(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Chunk.Address");
        return new ChunkAddress(handle);
    }

    /// <summary>
    /// Gets the network address of this chunk as a string.
    /// </summary>
    public string NetworkAddress()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.ChunkNetworkAddress(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Chunk.NetworkAddress");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <summary>
    /// Gets the serialized size of this chunk.
    /// </summary>
    public ulong Size()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var size = NativeMethods.ChunkSize(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Chunk.Size");
        return size;
    }

    /// <summary>
    /// Checks if this chunk exceeds the maximum allowed size.
    /// </summary>
    public bool IsTooBig()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        var result = NativeMethods.ChunkIsTooBig(CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Chunk.IsTooBig");
        return result != 0;
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeChunk(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneChunk(Handle, ref status);
    }
}

/// <summary>
/// Address of a chunk (32 bytes, derived from content hash).
/// </summary>
public sealed class ChunkAddress : NativeHandle
{
    internal ChunkAddress(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a ChunkAddress from 32 raw bytes.
    /// </summary>
    /// <param name="bytes">Exactly 32 bytes.</param>
    public static ChunkAddress FromBytes(byte[] bytes)
    {
        if (bytes.Length != 32)
            throw new DataException($"ChunkAddress must be exactly 32 bytes, got {bytes.Length}");

        var buffer = UniFFIHelpers.ToRustBuffer(bytes);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ChunkAddressNew(buffer, ref status);
        if (status.IsError)
            throw new DataException("Failed to create chunk address", status);
        return new ChunkAddress(handle);
    }

    /// <summary>
    /// Creates a ChunkAddress from content data (content-addressable).
    /// </summary>
    /// <param name="data">The content data to derive the address from.</param>
    public static ChunkAddress FromContent(byte[] data)
    {
        ArgumentNullException.ThrowIfNull(data);

        var buffer = UniFFIHelpers.ToRustBuffer(data);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ChunkAddressFromContent(buffer, ref status);
        if (status.IsError)
            throw new DataException("Failed to create chunk address from content", status);
        return new ChunkAddress(handle);
    }

    /// <summary>
    /// Creates a ChunkAddress from a hex string.
    /// </summary>
    public static ChunkAddress FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ChunkAddressFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new DataException("Failed to parse chunk address from hex", status);
        return new ChunkAddress(handle);
    }

    /// <summary>
    /// Returns the hex representation of this address.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.ChunkAddressToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "ChunkAddress.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <summary>
    /// Returns the raw 32 bytes of this address.
    /// </summary>
    public byte[] ToBytes()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.ChunkAddressToBytes(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "ChunkAddress.ToBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeChunkAddress(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneChunkAddress(Handle, ref status);
    }
}

/// <summary>
/// Address of public data (32 bytes).
/// </summary>
public sealed class DataAddress : NativeHandle
{
    internal DataAddress(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a DataAddress from 32 raw bytes.
    /// </summary>
    /// <param name="bytes">Exactly 32 bytes.</param>
    public static DataAddress FromBytes(byte[] bytes)
    {
        if (bytes.Length != 32)
            throw new DataException($"DataAddress must be exactly 32 bytes, got {bytes.Length}");

        var buffer = UniFFIHelpers.ToRustBuffer(bytes);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DataAddressNew(buffer, ref status);
        if (status.IsError)
            throw new DataException("Failed to create data address", status);
        return new DataAddress(handle);
    }

    /// <summary>
    /// Creates a DataAddress from a hex string.
    /// </summary>
    public static DataAddress FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DataAddressFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new DataException("Failed to parse data address from hex", status);
        return new DataAddress(handle);
    }

    /// <summary>
    /// Returns the hex representation of this address.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.DataAddressToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DataAddress.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <summary>
    /// Returns the raw 32 bytes of this address.
    /// </summary>
    public byte[] ToBytes()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.DataAddressToBytes(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DataAddress.ToBytes");
        return UniFFIHelpers.FromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeDataAddress(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneDataAddress(Handle, ref status);
    }
}

/// <summary>
/// Metadata chunk for encrypted private data.
/// </summary>
/// <remarks>
/// A DataMapChunk contains the information needed to decrypt and reconstruct
/// private data stored on the network.
/// </remarks>
public sealed class DataMapChunk : NativeHandle
{
    internal DataMapChunk(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a DataMapChunk from a hex string.
    /// </summary>
    public static DataMapChunk FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.DataMapChunkFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new DataException("Failed to parse data map chunk from hex", status);
        return new DataMapChunk(handle);
    }

    /// <summary>
    /// Returns the hex representation of this data map chunk.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.DataMapChunkToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DataMapChunk.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <summary>
    /// Gets the address string for this data map (not a network address).
    /// </summary>
    public string Address()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.DataMapChunkAddress(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "DataMapChunk.Address");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeDataMapChunk(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneDataMapChunk(Handle, ref status);
    }
}
