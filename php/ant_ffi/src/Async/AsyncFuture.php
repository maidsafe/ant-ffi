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
 * Uses ReactPHP event loop for non-blocking operations.
 * Since PHP FFI doesn't support callbacks directly, we use
 * a polling approach with timers.
 */
final class AsyncFuture
{
    private const POLL_INTERVAL_MS = 1;
    private const MAX_POLL_ATTEMPTS = 100000; // Prevent infinite loops

    /**
     * Poll a Rust future that returns a pointer.
     *
     * @return PromiseInterface<CData> Promise that resolves to the pointer
     */
    public static function pollPointer(int $futureHandle): PromiseInterface
    {
        $deferred = new Deferred();

        // Use a timer to poll
        $attempts = 0;
        $poll = null;
        $poll = function () use ($futureHandle, $deferred, &$attempts, &$poll) {
            $attempts++;

            if ($attempts > self::MAX_POLL_ATTEMPTS) {
                $deferred->reject(new AntFfiException('Future polling timed out'));
                return;
            }

            try {
                $result = self::tryCompletePointer($futureHandle);
                if ($result !== null) {
                    $deferred->resolve($result);
                } else {
                    // Schedule next poll
                    Loop::addTimer(self::POLL_INTERVAL_MS / 1000, $poll);
                }
            } catch (AntFfiException $e) {
                $deferred->reject($e);
            }
        };

        // Start polling on next tick
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
                $result = self::tryCompleteRustBuffer($futureHandle);
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
     */
    public static function awaitPointer(int $futureHandle): CData
    {
        $attempts = 0;
        while ($attempts < self::MAX_POLL_ATTEMPTS) {
            $result = self::tryCompletePointer($futureHandle);
            if ($result !== null) {
                return $result;
            }
            usleep(self::POLL_INTERVAL_MS * 1000);
            $attempts++;
        }
        throw new AntFfiException('Future polling timed out');
    }

    /**
     * Synchronously wait for a RustBuffer future to complete.
     */
    public static function awaitRustBuffer(int $futureHandle): CData
    {
        $attempts = 0;
        while ($attempts < self::MAX_POLL_ATTEMPTS) {
            $result = self::tryCompleteRustBuffer($futureHandle);
            if ($result !== null) {
                return $result;
            }
            usleep(self::POLL_INTERVAL_MS * 1000);
            $attempts++;
        }
        throw new AntFfiException('Future polling timed out');
    }

    /**
     * Try to complete a pointer future.
     * Returns null if not ready, the result if ready.
     */
    private static function tryCompletePointer(int $futureHandle): ?CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        // Poll with null callback - we'll just check if complete
        // The Rust side will mark it ready after enough polling
        $ffi->ffi_ant_ffi_rust_future_poll_pointer($futureHandle, null, 0);

        // Try to complete
        $result = $ffi->ffi_ant_ffi_rust_future_complete_pointer($futureHandle, FFI::addr($status));

        // Check if there was an error indicating not ready
        if ($status->code === 0 && $result !== null) {
            $ffi->ffi_ant_ffi_rust_future_free_pointer($futureHandle);
            return $result;
        }

        // Not ready yet or error
        if ($status->code !== 0) {
            RustBuffer::checkStatus($status);
        }

        return null;
    }

    /**
     * Try to complete a RustBuffer future.
     */
    private static function tryCompleteRustBuffer(int $futureHandle): ?CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        // Poll
        $ffi->ffi_ant_ffi_rust_future_poll_rust_buffer($futureHandle, null, 0);

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

        // Not ready or error
        if ($status->code !== 0 && $status->code !== 1) {
            // Code 1 typically means "not ready"
            RustBuffer::checkStatus($status);
        }

        return null;
    }
}
