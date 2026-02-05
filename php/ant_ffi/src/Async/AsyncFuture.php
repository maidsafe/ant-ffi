<?php

declare(strict_types=1);

namespace AntFfi\Async;

use AntFfi\AntFfiException;
use AntFfi\FFILoader;
use AntFfi\RustBuffer;
use React\Promise\Deferred;
use React\Promise\PromiseInterface;
use React\EventLoop\Loop;
use FFI;
use FFI\CData;

/**
 * Async future handling for UniFFI operations.
 *
 * Uses a callback mechanism with PHP FFI closures for proper async handling.
 */
final class AsyncFuture
{
    private const POLL_INTERVAL_MS = 10;
    private const MAX_POLL_ATTEMPTS = 30000; // 5 minutes at 10ms intervals

    /** @var array<int, bool> Tracks which futures are ready */
    private static array $readyFutures = [];

    /**
     * Create a callback closure for the Rust future poll.
     * Returns a callable that can be passed to ffi_ant_ffi_rust_future_poll_*.
     */
    private static function createCallback(): callable
    {
        // Create the PHP callback that Rust will call
        // Signature: void callback(void* data, int8_t poll_result)
        return function ($data, int $pollResult): void {
            // pollResult: 0 = WAKE (poll again), 1 = READY
            if ($pollResult === 1) {
                // Use the callback_data as a marker index
                $index = (int)$data;
                self::$readyFutures[$index] = true;
            }
        };
    }

    /**
     * Poll a Rust future that returns a pointer.
     *
     * @return PromiseInterface<CData> Promise that resolves to the pointer
     */
    public static function pollPointer(int $futureHandle): PromiseInterface
    {
        $deferred = new Deferred();

        $attempts = 0;
        $poll = null;
        $poll = function () use ($futureHandle, $deferred, &$attempts, &$poll) {
            $attempts++;

            if ($attempts > self::MAX_POLL_ATTEMPTS) {
                $deferred->reject(new AntFfiException('Future polling timed out'));
                return;
            }

            try {
                $result = self::tryCompletePointerWithCallback($futureHandle);
                if ($result !== null) {
                    $deferred->resolve($result);
                } else {
                    Loop::addTimer(self::POLL_INTERVAL_MS / 1000, $poll);
                }
            } catch (AntFfiException $e) {
                $deferred->reject($e);
            }
        };

        Loop::futureTick($poll);

        return $deferred->promise();
    }

    /**
     * Poll a Rust future that returns a RustBuffer.
     *
     * @return PromiseInterface<CData> Promise that resolves to the RustBuffer
     */
    public static function pollRustBuffer(int $futureHandle): PromiseInterface
    {
        $deferred = new Deferred();

        $attempts = 0;
        $poll = null;
        $poll = function () use ($futureHandle, $deferred, &$attempts, &$poll) {
            $attempts++;

            if ($attempts > self::MAX_POLL_ATTEMPTS) {
                $deferred->reject(new AntFfiException('Future polling timed out'));
                return;
            }

            try {
                $result = self::tryCompleteRustBufferWithCallback($futureHandle);
                if ($result !== null) {
                    $deferred->resolve($result);
                } else {
                    Loop::addTimer(self::POLL_INTERVAL_MS / 1000, $poll);
                }
            } catch (AntFfiException $e) {
                $deferred->reject($e);
            }
        };

        Loop::futureTick($poll);

        return $deferred->promise();
    }

    /**
     * Synchronously wait for a pointer future to complete.
     * Use this for simple scripts that don't need ReactPHP.
     *
     * Note: UniFFI async futures run on a Tokio runtime spawned when the
     * async function is called. We just need to wait for it to complete.
     */
    public static function awaitPointer(int $futureHandle): CData
    {
        $ffi = FFILoader::get();
        $attempts = 0;

        while ($attempts < self::MAX_POLL_ATTEMPTS) {
            // Give Tokio runtime time to process the async work
            usleep(self::POLL_INTERVAL_MS * 1000);

            // Try to complete
            $status = $ffi->new('RustCallStatus');
            $result = $ffi->ffi_ant_ffi_rust_future_complete_pointer($futureHandle, FFI::addr($status));

            // Check status - code 0 means success
            if ($status->code === 0) {
                $ffi->ffi_ant_ffi_rust_future_free_pointer($futureHandle);
                if ($result === null) {
                    throw new AntFfiException('Future completed but returned null');
                }
                return $result;
            }

            // Code 1 = panic (should not happen)
            // Code 2 = error
            if ($status->code !== 0 && $status->error_buf->len > 0) {
                $ffi->ffi_ant_ffi_rust_future_free_pointer($futureHandle);
                RustBuffer::checkStatus($status);
            }

            $attempts++;
        }

        $ffi->ffi_ant_ffi_rust_future_free_pointer($futureHandle);
        throw new AntFfiException('Future polling timed out after ' . $attempts . ' attempts');
    }

    /**
     * Synchronously wait for a RustBuffer future to complete.
     */
    public static function awaitRustBuffer(int $futureHandle): CData
    {
        $ffi = FFILoader::get();
        $attempts = 0;

        while ($attempts < self::MAX_POLL_ATTEMPTS) {
            // Give Tokio runtime time to process
            usleep(self::POLL_INTERVAL_MS * 1000);

            // Try to complete
            $status = $ffi->new('RustCallStatus');
            $resultBuffer = $ffi->new('RustBuffer');
            $ffi->ffi_ant_ffi_rust_future_complete_rust_buffer(
                FFI::addr($resultBuffer),
                $futureHandle,
                FFI::addr($status)
            );

            if ($status->code === 0) {
                $ffi->ffi_ant_ffi_rust_future_free_rust_buffer($futureHandle);
                return $resultBuffer;
            }

            // If there's a real error, throw
            if ($status->code !== 0 && $status->error_buf->len > 0) {
                $ffi->ffi_ant_ffi_rust_future_free_rust_buffer($futureHandle);
                RustBuffer::checkStatus($status);
            }

            $attempts++;
        }

        $ffi->ffi_ant_ffi_rust_future_free_rust_buffer($futureHandle);
        throw new AntFfiException('Future polling timed out after ' . $attempts . ' attempts');
    }

    /**
     * Try to complete a pointer future.
     */
    private static function tryCompletePointerWithCallback(int $futureHandle): ?CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        // Try to complete
        $result = $ffi->ffi_ant_ffi_rust_future_complete_pointer($futureHandle, FFI::addr($status));

        if ($status->code === 0 && $result !== null) {
            $ffi->ffi_ant_ffi_rust_future_free_pointer($futureHandle);
            return $result;
        }

        if ($status->code !== 0 && $status->error_buf->len > 0) {
            $ffi->ffi_ant_ffi_rust_future_free_pointer($futureHandle);
            RustBuffer::checkStatus($status);
        }

        return null;
    }

    /**
     * Try to complete a RustBuffer future.
     */
    private static function tryCompleteRustBufferWithCallback(int $futureHandle): ?CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        // Try to complete
        $ffi->ffi_ant_ffi_rust_future_complete_rust_buffer(
            FFI::addr($resultBuffer),
            $futureHandle,
            FFI::addr($status)
        );

        if ($status->code === 0) {
            $ffi->ffi_ant_ffi_rust_future_free_rust_buffer($futureHandle);
            return $resultBuffer;
        }

        if ($status->code !== 0 && $status->error_buf->len > 0) {
            $ffi->ffi_ant_ffi_rust_future_free_rust_buffer($futureHandle);
            RustBuffer::checkStatus($status);
        }

        return null;
    }
}
