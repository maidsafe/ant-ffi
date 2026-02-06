using System.Runtime.InteropServices;

namespace AntFfi.Native;

/// <summary>
/// Callback delegate for UniFFI async future polling.
/// </summary>
/// <param name="callbackData">User-provided callback data.</param>
/// <param name="pollResult">0 if the future is ready, non-zero if it needs more polling.</param>
[UnmanagedFunctionPointer(CallingConvention.Cdecl)]
public delegate void UniffiRustFutureContinuationCallback(ulong callbackData, sbyte pollResult);

/// <summary>
/// P/Invoke declarations for async future handling.
/// </summary>
internal static partial class NativeMethods
{
    #region Async Future - Pointer

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_poll_pointer")]
    public static extern void RustFuturePollPointer(ulong handle, UniffiRustFutureContinuationCallback callback, ulong callbackData);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_complete_pointer")]
    public static extern IntPtr RustFutureCompletePointer(ulong handle, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_free_pointer")]
    public static extern void RustFutureFreePointer(ulong handle);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_cancel_pointer")]
    public static extern void RustFutureCancelPointer(ulong handle);

    #endregion

    #region Async Future - RustBuffer

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_poll_rust_buffer")]
    public static extern void RustFuturePollRustBuffer(ulong handle, UniffiRustFutureContinuationCallback callback, ulong callbackData);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_complete_rust_buffer")]
    public static extern void RustFutureCompleteRustBuffer(out RustBuffer result, ulong handle, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_free_rust_buffer")]
    public static extern void RustFutureFreeRustBuffer(ulong handle);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_cancel_rust_buffer")]
    public static extern void RustFutureCancelRustBuffer(ulong handle);

    #endregion

    #region Async Future - Void

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_poll_void")]
    public static extern void RustFuturePollVoid(ulong handle, UniffiRustFutureContinuationCallback callback, ulong callbackData);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_complete_void")]
    public static extern void RustFutureCompleteVoid(ulong handle, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_free_void")]
    public static extern void RustFutureFreeVoid(ulong handle);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_cancel_void")]
    public static extern void RustFutureCancelVoid(ulong handle);

    #endregion

    #region Async Future - u64

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_poll_u64")]
    public static extern void RustFuturePollU64(ulong handle, UniffiRustFutureContinuationCallback callback, ulong callbackData);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_complete_u64")]
    public static extern ulong RustFutureCompleteU64(ulong handle, ref RustCallStatus status);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_free_u64")]
    public static extern void RustFutureFreeU64(ulong handle);

    [DllImport(LibName, CallingConvention = CallingConvention.Cdecl, EntryPoint = "ffi_ant_ffi_rust_future_cancel_u64")]
    public static extern void RustFutureCancelU64(ulong handle);

    #endregion
}

/// <summary>
/// Helper class for managing async futures from Rust.
/// </summary>
internal static class AsyncFutureHelper
{
    private static ulong _nextCallbackId;
    private static readonly object _lock = new();
    private static readonly Dictionary<ulong, TaskCompletionSource<bool>> _pendingCallbacks = new();
    private static readonly Dictionary<ulong, UniffiRustFutureContinuationCallback> _callbackDelegates = new();

    /// <summary>
    /// Polls a pointer-returning future and waits for completion.
    /// </summary>
    public static async Task<IntPtr> PollPointerAsync(ulong futureHandle, CancellationToken cancellationToken = default)
    {
        try
        {
            await PollFutureAsync(futureHandle, NativeMethods.RustFuturePollPointer, cancellationToken);

            var status = RustCallStatus.Create();
            var result = NativeMethods.RustFutureCompletePointer(futureHandle, ref status);
            UniFFIHelpers.CheckStatus(ref status, "Async future completion");
            return result;
        }
        finally
        {
            NativeMethods.RustFutureFreePointer(futureHandle);
        }
    }

    /// <summary>
    /// Polls a RustBuffer-returning future and waits for completion.
    /// </summary>
    public static async Task<RustBuffer> PollRustBufferAsync(ulong futureHandle, CancellationToken cancellationToken = default)
    {
        try
        {
            await PollFutureAsync(futureHandle, NativeMethods.RustFuturePollRustBuffer, cancellationToken);

            var status = RustCallStatus.Create();
            NativeMethods.RustFutureCompleteRustBuffer(out var result, futureHandle, ref status);
            UniFFIHelpers.CheckStatus(ref status, "Async future completion");
            return result;
        }
        finally
        {
            NativeMethods.RustFutureFreeRustBuffer(futureHandle);
        }
    }

    /// <summary>
    /// Polls a void-returning future and waits for completion.
    /// </summary>
    public static async Task PollVoidAsync(ulong futureHandle, CancellationToken cancellationToken = default)
    {
        try
        {
            await PollFutureAsync(futureHandle, NativeMethods.RustFuturePollVoid, cancellationToken);

            var status = RustCallStatus.Create();
            NativeMethods.RustFutureCompleteVoid(futureHandle, ref status);
            UniFFIHelpers.CheckStatus(ref status, "Async future completion");
        }
        finally
        {
            NativeMethods.RustFutureFreeVoid(futureHandle);
        }
    }

    private delegate void PollDelegate(ulong handle, UniffiRustFutureContinuationCallback callback, ulong callbackData);

    private static async Task PollFutureAsync(ulong futureHandle, PollDelegate pollFunc, CancellationToken cancellationToken)
    {
        while (true)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var tcs = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
            ulong callbackId;

            // Create callback delegate that will be called when future is ready
            UniffiRustFutureContinuationCallback callback = (cbData, pollResult) =>
            {
                lock (_lock)
                {
                    if (_pendingCallbacks.TryGetValue(cbData, out var pendingTcs))
                    {
                        _pendingCallbacks.Remove(cbData);
                        _callbackDelegates.Remove(cbData);
                        // pollResult == 0 means ready
                        pendingTcs.TrySetResult(pollResult == 0);
                    }
                }
            };

            lock (_lock)
            {
                callbackId = ++_nextCallbackId;
                _pendingCallbacks[callbackId] = tcs;
                _callbackDelegates[callbackId] = callback; // Keep delegate alive
            }

            // Poll the future
            pollFunc(futureHandle, callback, callbackId);

            // Wait for callback
            var isReady = await tcs.Task;

            if (isReady)
            {
                return; // Future is complete
            }

            // Not ready yet, will poll again
            await Task.Yield();
        }
    }
}
