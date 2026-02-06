<?php

declare(strict_types=1);

namespace AntFfi\Async;

use FFI;
use FFI\CData;

/**
 * Thread-safe async callback helper for UniFFI operations.
 *
 * This class wraps the async_helper native library which provides
 * a thread-safe callback mechanism for UniFFI async futures.
 * Since PHP FFI callbacks cannot be called from other threads,
 * we use this native shim with atomic operations instead.
 */
final class AsyncHelper
{
    private static ?FFI $ffi = null;
    private static bool $available = false;
    private static bool $initialized = false;

    /**
     * Initialize the async helper library.
     */
    private static function init(): void
    {
        if (self::$initialized) {
            return;
        }

        self::$initialized = true;

        // Define the async_helper FFI interface
        $cdef = <<<'CDEF'
void uniffi_async_callback(uint64_t callback_data, int8_t poll_result);
int32_t async_helper_alloc_slot(void);
void async_helper_free_slot(int32_t slot);
int8_t async_helper_get_result(int32_t slot);
void async_helper_reset_result(int32_t slot);
void* async_helper_get_callback(void);
CDEF;

        // Try to load the library
        $searchPaths = [
            __DIR__ . '/../../async_helper.dll',
            __DIR__ . '/../../libasync_helper.so',
            __DIR__ . '/../../libasync_helper.dylib',
            __DIR__ . '/../../../async_helper.dll',
        ];

        foreach ($searchPaths as $path) {
            if (file_exists($path)) {
                try {
                    self::$ffi = FFI::cdef($cdef, $path);
                    self::$available = true;
                    return;
                } catch (\Throwable $e) {
                    // Try next path
                }
            }
        }

        // Try system path
        try {
            $libName = PHP_OS_FAMILY === 'Windows' ? 'async_helper.dll' :
                      (PHP_OS_FAMILY === 'Darwin' ? 'libasync_helper.dylib' : 'libasync_helper.so');
            self::$ffi = FFI::cdef($cdef, $libName);
            self::$available = true;
        } catch (\Throwable $e) {
            self::$available = false;
        }
    }

    /**
     * Check if the async helper is available.
     */
    public static function isAvailable(): bool
    {
        self::init();
        return self::$available;
    }

    /**
     * Allocate a slot for tracking a future's poll result.
     *
     * @return int The slot index (0-255), or -1 if no slots available
     */
    public static function allocSlot(): int
    {
        self::init();
        if (!self::$available) {
            return -1;
        }
        return self::$ffi->async_helper_alloc_slot();
    }

    /**
     * Free a previously allocated slot.
     */
    public static function freeSlot(int $slot): void
    {
        if (self::$available && $slot >= 0) {
            self::$ffi->async_helper_free_slot($slot);
        }
    }

    /**
     * Get the current poll result for a slot.
     *
     * @return int -1 = pending, 0 = ready, 1 = wake/poll again
     */
    public static function getResult(int $slot): int
    {
        if (!self::$available || $slot < 0) {
            return -1;
        }
        return self::$ffi->async_helper_get_result($slot);
    }

    /**
     * Reset the poll result for a slot to pending.
     */
    public static function resetResult(int $slot): void
    {
        if (self::$available && $slot >= 0) {
            self::$ffi->async_helper_reset_result($slot);
        }
    }

    /**
     * Get the callback function pointer for passing to UniFFI.
     *
     * @return CData|null The callback function pointer, or null if not available
     */
    public static function getCallback(): ?CData
    {
        self::init();
        if (!self::$available) {
            return null;
        }
        return self::$ffi->async_helper_get_callback();
    }

    /**
     * Get the callback pointer as an integer for FFI calls.
     */
    public static function getCallbackInt(): int
    {
        $callback = self::getCallback();
        if ($callback === null) {
            return 0;
        }
        return FFI::cast('uintptr_t', $callback)->cdata;
    }
}
