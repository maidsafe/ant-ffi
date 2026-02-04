<?php

declare(strict_types=1);

namespace AntFfi;

use FFI;
use FFI\CData;

/**
 * Helper class for working with RustBuffer.
 */
final class RustBuffer
{
    /**
     * Create a RustBuffer from a PHP string with UniFFI length prefix.
     * UniFFI format: 4-byte big-endian length + UTF-8 data
     */
    public static function fromString(string $str): CData
    {
        $len = strlen($str);
        $prefixedData = pack('N', $len) . $str;
        return self::fromBytes($prefixedData);
    }

    /**
     * Create a RustBuffer from raw bytes (no length prefix).
     */
    public static function fromBytes(string $bytes): CData
    {
        $ffi = FFILoader::get();
        $len = strlen($bytes);

        // Create ForeignBytes
        $foreignBytes = $ffi->new('ForeignBytes');
        $foreignBytes->len = $len;

        if ($len > 0) {
            $foreignBytes->data = FFI::new("uint8_t[$len]", false);
            FFI::memcpy($foreignBytes->data, $bytes, $len);
        } else {
            $foreignBytes->data = null;
        }

        // Convert to RustBuffer
        $status = $ffi->new('RustCallStatus');
        $buffer = $ffi->ffi_ant_ffi_rustbuffer_from_bytes($foreignBytes, FFI::addr($status));

        self::checkStatus($status);

        return $buffer;
    }

    /**
     * Extract string from RustBuffer (with UniFFI length prefix).
     */
    public static function toString(CData $buffer): string
    {
        if ($buffer->len === 0) {
            return '';
        }

        $data = FFI::string($buffer->data, $buffer->len);

        // Parse UniFFI format: 4-byte big-endian length + data
        if (strlen($data) < 4) {
            return '';
        }

        $len = unpack('N', substr($data, 0, 4))[1];
        return substr($data, 4, $len);
    }

    /**
     * Extract raw bytes from RustBuffer (no parsing).
     */
    public static function toBytes(CData $buffer): string
    {
        if ($buffer->len === 0) {
            return '';
        }
        return FFI::string($buffer->data, $buffer->len);
    }

    /**
     * Free a RustBuffer.
     */
    public static function free(CData $buffer): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->ffi_ant_ffi_rustbuffer_free($buffer, FFI::addr($status));
    }

    /**
     * Check RustCallStatus and throw on error.
     */
    public static function checkStatus(CData $status): void
    {
        if ($status->code !== 0) {
            $message = 'FFI call failed';
            if ($status->error_buf->len > 0) {
                try {
                    $message = self::toString($status->error_buf);
                } catch (\Throwable $e) {
                    // Fallback if we can't parse the error
                    $message = "FFI call failed with code {$status->code}";
                }
            }
            throw new AntFfiException($message, $status->code);
        }
    }

    /**
     * Create an empty RustBuffer.
     */
    public static function empty(): CData
    {
        $ffi = FFILoader::get();
        $buffer = $ffi->new('RustBuffer');
        $buffer->capacity = 0;
        $buffer->len = 0;
        $buffer->data = null;
        return $buffer;
    }
}
