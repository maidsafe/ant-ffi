namespace AntFfi.Native;

/// <summary>
/// Base class for wrapping native Rust object handles with proper disposal.
/// </summary>
public abstract class NativeHandle : IDisposable
{
    /// <summary>
    /// The native pointer to the Rust object.
    /// </summary>
    protected internal IntPtr Handle { get; private set; }

    private bool _disposed;

    /// <summary>
    /// Creates a new NativeHandle wrapping the given pointer.
    /// </summary>
    protected NativeHandle(IntPtr handle)
    {
        if (handle == IntPtr.Zero)
            throw new ArgumentException("Handle cannot be zero", nameof(handle));
        Handle = handle;
    }

    /// <summary>
    /// Gets whether this handle has been disposed.
    /// </summary>
    public bool IsDisposed => _disposed;

    /// <summary>
    /// Throws if this handle has been disposed.
    /// </summary>
    internal void ThrowIfDisposed()
    {
        ObjectDisposedException.ThrowIf(_disposed, this);
    }

    /// <summary>
    /// Frees the native handle. Override in derived classes to call the appropriate free function.
    /// </summary>
    protected abstract void FreeHandle();

    /// <summary>
    /// Clones the native handle by calling the UniFFI clone function, which increments
    /// the Arc reference count. Must be called before passing the handle to any UniFFI
    /// method or constructor, because UniFFI's try_lift uses Arc::from_raw which
    /// consumes one reference.
    /// </summary>
    /// <returns>A cloned handle pointer (same address, incremented refcount).</returns>
    protected internal abstract IntPtr CloneHandle();

    /// <summary>
    /// Disposes this handle and frees the native resource.
    /// </summary>
    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    /// <summary>
    /// Disposes this handle.
    /// </summary>
    protected virtual void Dispose(bool disposing)
    {
        if (_disposed) return;

        if (Handle != IntPtr.Zero)
        {
            try
            {
                FreeHandle();
            }
            catch
            {
                // Ignore errors during disposal
            }
            Handle = IntPtr.Zero;
        }

        _disposed = true;
    }

    /// <summary>
    /// Finalizer to ensure native resources are freed.
    /// </summary>
    ~NativeHandle()
    {
        Dispose(false);
    }
}
