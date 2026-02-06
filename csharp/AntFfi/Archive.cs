using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when an archive operation fails.
/// </summary>
public class ArchiveException : AntFfiException
{
    public ArchiveException(string message) : base(message) { }
    public ArchiveException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// File metadata containing size and timestamps.
/// </summary>
public sealed class Metadata : NativeHandle
{
    internal Metadata(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates new metadata with the given file size.
    /// Creation and modification times are set to the current time.
    /// </summary>
    /// <param name="size">File size in bytes.</param>
    public static Metadata Create(ulong size)
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.MetadataNew(size, ref status);
        UniFFIHelpers.CheckStatus(ref status, "Metadata.Create");
        return new Metadata(handle);
    }

    /// <summary>
    /// Creates metadata with specific timestamps.
    /// </summary>
    /// <param name="size">File size in bytes.</param>
    /// <param name="created">Creation time as Unix timestamp in seconds.</param>
    /// <param name="modified">Modification time as Unix timestamp in seconds.</param>
    public static Metadata WithTimestamps(ulong size, ulong created, ulong modified)
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.MetadataWithTimestamps(size, created, modified, ref status);
        UniFFIHelpers.CheckStatus(ref status, "Metadata.WithTimestamps");
        return new Metadata(handle);
    }

    /// <summary>
    /// Gets the file size in bytes.
    /// </summary>
    public ulong Size
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.MetadataSize(CloneHandle(), ref status);
        }
    }

    /// <summary>
    /// Gets the creation time as Unix timestamp in seconds.
    /// </summary>
    public ulong Created
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.MetadataCreated(CloneHandle(), ref status);
        }
    }

    /// <summary>
    /// Gets the modification time as Unix timestamp in seconds.
    /// </summary>
    public ulong Modified
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.MetadataModified(CloneHandle(), ref status);
        }
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeMetadata(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneMetadata(Handle, ref status);
    }
}

/// <summary>
/// Address of a public archive on the network.
/// </summary>
public sealed class ArchiveAddress : NativeHandle
{
    internal ArchiveAddress(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates an ArchiveAddress from a hex string.
    /// </summary>
    public static ArchiveAddress FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.ArchiveAddressFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new ArchiveException("Failed to parse archive address from hex", status);
        return new ArchiveAddress(handle);
    }

    /// <summary>
    /// Returns the hex representation of this archive address.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.ArchiveAddressToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "ArchiveAddress.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeArchiveAddress(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneArchiveAddress(Handle, ref status);
    }
}

/// <summary>
/// Datamap for a private archive, used to retrieve the archive from the network.
/// </summary>
public sealed class PrivateArchiveDataMap : NativeHandle
{
    internal PrivateArchiveDataMap(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a PrivateArchiveDataMap from a hex string.
    /// </summary>
    public static PrivateArchiveDataMap FromHex(string hex)
    {
        var hexBuffer = UniFFIHelpers.StringToRustBuffer(hex);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PrivateArchiveDataMapFromHex(hexBuffer, ref status);
        if (status.IsError)
            throw new ArchiveException("Failed to parse private archive datamap from hex", status);
        return new PrivateArchiveDataMap(handle);
    }

    /// <summary>
    /// Returns the hex representation of this private archive datamap.
    /// </summary>
    public string ToHex()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.PrivateArchiveDataMapToHex(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PrivateArchiveDataMap.ToHex");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreePrivateArchiveDataMap(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.ClonePrivateArchiveDataMap(Handle, ref status);
    }
}

/// <summary>
/// A public archive containing files that can be accessed by anyone on the network.
/// </summary>
/// <remarks>
/// PublicArchive is immutable - operations like AddFile return a new archive.
/// </remarks>
public sealed class PublicArchive : NativeHandle
{
    internal PublicArchive(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a new empty public archive.
    /// </summary>
    public static PublicArchive Create()
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PublicArchiveNew(ref status);
        UniFFIHelpers.CheckStatus(ref status, "PublicArchive.Create");
        return new PublicArchive(handle);
    }

    /// <summary>
    /// Adds a file to the archive and returns a new archive.
    /// </summary>
    /// <param name="path">The path of the file in the archive.</param>
    /// <param name="address">The data address where the file content is stored.</param>
    /// <param name="metadata">Metadata about the file.</param>
    /// <returns>A new archive with the file added.</returns>
    public PublicArchive AddFile(string path, DataAddress address, Metadata metadata)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(address);
        ArgumentNullException.ThrowIfNull(metadata);
        address.ThrowIfDisposed();
        metadata.ThrowIfDisposed();

        var pathBuffer = UniFFIHelpers.StringToRustBuffer(path);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PublicArchiveAddFile(CloneHandle(), pathBuffer, address.CloneHandle(), metadata.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PublicArchive.AddFile");
        return new PublicArchive(handle);
    }

    /// <summary>
    /// Renames a file in the archive and returns a new archive.
    /// </summary>
    public PublicArchive RenameFile(string oldPath, string newPath)
    {
        ThrowIfDisposed();

        var oldPathBuffer = UniFFIHelpers.StringToRustBuffer(oldPath);
        var newPathBuffer = UniFFIHelpers.StringToRustBuffer(newPath);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PublicArchiveRenameFile(CloneHandle(), oldPathBuffer, newPathBuffer, ref status);
        if (status.IsError)
            throw new ArchiveException("Failed to rename file in archive", status);
        return new PublicArchive(handle);
    }

    /// <summary>
    /// Gets the number of files in the archive.
    /// </summary>
    public ulong FileCount
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.PublicArchiveFileCount(CloneHandle(), ref status);
        }
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreePublicArchive(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.ClonePublicArchive(Handle, ref status);
    }
}

/// <summary>
/// A private archive containing files with encrypted access.
/// </summary>
/// <remarks>
/// PrivateArchive is immutable - operations like AddFile return a new archive.
/// </remarks>
public sealed class PrivateArchive : NativeHandle
{
    internal PrivateArchive(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a new empty private archive.
    /// </summary>
    public static PrivateArchive Create()
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PrivateArchiveNew(ref status);
        UniFFIHelpers.CheckStatus(ref status, "PrivateArchive.Create");
        return new PrivateArchive(handle);
    }

    /// <summary>
    /// Adds a file to the archive and returns a new archive.
    /// </summary>
    /// <param name="path">The path of the file in the archive.</param>
    /// <param name="dataMap">The data map chunk to retrieve the file content.</param>
    /// <param name="metadata">Metadata about the file.</param>
    /// <returns>A new archive with the file added.</returns>
    public PrivateArchive AddFile(string path, DataMapChunk dataMap, Metadata metadata)
    {
        ThrowIfDisposed();
        ArgumentNullException.ThrowIfNull(dataMap);
        ArgumentNullException.ThrowIfNull(metadata);
        dataMap.ThrowIfDisposed();
        metadata.ThrowIfDisposed();

        var pathBuffer = UniFFIHelpers.StringToRustBuffer(path);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PrivateArchiveAddFile(CloneHandle(), pathBuffer, dataMap.CloneHandle(), metadata.CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "PrivateArchive.AddFile");
        return new PrivateArchive(handle);
    }

    /// <summary>
    /// Renames a file in the archive and returns a new archive.
    /// </summary>
    public PrivateArchive RenameFile(string oldPath, string newPath)
    {
        ThrowIfDisposed();

        var oldPathBuffer = UniFFIHelpers.StringToRustBuffer(oldPath);
        var newPathBuffer = UniFFIHelpers.StringToRustBuffer(newPath);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.PrivateArchiveRenameFile(CloneHandle(), oldPathBuffer, newPathBuffer, ref status);
        if (status.IsError)
            throw new ArchiveException("Failed to rename file in archive", status);
        return new PrivateArchive(handle);
    }

    /// <summary>
    /// Gets the number of files in the archive.
    /// </summary>
    public ulong FileCount
    {
        get
        {
            ThrowIfDisposed();
            var status = RustCallStatus.Create();
            return NativeMethods.PrivateArchiveFileCount(CloneHandle(), ref status);
        }
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreePrivateArchive(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.ClonePrivateArchive(Handle, ref status);
    }
}
