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
     * Create a RustBuffer from a PHP string (raw UTF-8, no prefix).
     * This is the standard format for string parameters in UniFFI.
     */
    public static function fromString(string $str): CData
    {
        return self::fromBytes($str);
    }

    /**
     * Create a RustBuffer from a PHP string with UniFFI length prefix.
     * UniFFI format: 4-byte big-endian length + UTF-8 data
     * Use this for Vec<u8> parameters that require serialization.
     */
    public static function fromStringWithPrefix(string $str): CData
    {
        $len = strlen($str);
        $prefixedData = pack('N', $len) . $str;
        return self::fromBytes($prefixedData);
    }

    /**
     * Alias for fromString (for clarity when passing raw string data).
     */
    public static function fromRawString(string $str): CData
    {
        return self::fromBytes($str);
    }

    /**
     * Create a RustBuffer from an optional string with UniFFI format.
     * UniFFI format: 1 byte (0=None, 1=Some) + if Some: 4-byte BE length + UTF-8 data
     */
    public static function fromOptionString(?string $str): CData
    {
        if ($str === null) {
            return self::fromBytes(pack('C', 0)); // None
        }
        $len = strlen($str);
        $data = pack('C', 1) . pack('N', $len) . $str; // Some + length + data
        return self::fromBytes($data);
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
     * Extract string from RustBuffer (auto-detects format).
     * Handles both length-prefixed (UniFFI) and raw strings.
     */
    public static function toString(CData $buffer): string
    {
        if ($buffer->len === 0) {
            return '';
        }

        $data = FFI::string($buffer->data, $buffer->len);

        if (strlen($data) < 4) {
            return $data; // Too short for prefix, return as-is
        }

        // Try to parse UniFFI format: 4-byte big-endian length + data
        $len = unpack('N', substr($data, 0, 4))[1];

        // Validate: length must make sense for the buffer
        if ($len > 0 && $len <= strlen($data) - 4) {
            return substr($data, 4, $len);
        }

        // No valid prefix found, return raw string
        return $data;
    }

    /**
     * Extract raw string/bytes from RustBuffer (no prefix parsing).
     */
    public static function toRawString(CData $buffer): string
    {
        if ($buffer->len === 0) {
            return '';
        }
        return FFI::string($buffer->data, $buffer->len);
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
                    $message = self::parseErrorBuffer($status->error_buf);
                } catch (\Throwable $e) {
                    // Fallback if we can't parse the error
                    $message = "FFI call failed with code {$status->code}";
                }
            }
            throw new AntFfiException($message, $status->code);
        }
    }

    /**
     * Parse UniFFI error buffer format.
     * Format: 4-byte variant + 4-byte string length + string data
     */
    private static function parseErrorBuffer(CData $buffer): string
    {
        if ($buffer->len < 8) {
            return self::toString($buffer);
        }

        $data = FFI::string($buffer->data, $buffer->len);

        // Skip 4-byte variant, read 4-byte string length
        $strLen = unpack('N', substr($data, 4, 4))[1];

        if ($strLen > 0 && $strLen <= strlen($data) - 8) {
            return substr($data, 8, $strLen);
        }

        // Fallback to regular parsing
        return self::toString($buffer);
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
