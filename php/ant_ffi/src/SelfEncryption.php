<?php

declare(strict_types=1);

namespace AntFfi;

use FFI;

/**
 * Self-encryption functions.
 */
final class SelfEncryption
{
    /**
     * Encrypt data using self-encryption.
     *
     * @param string $data The data to encrypt
     * @return string The encrypted data
     * @throws AntFfiException on error
     */
    public static function encrypt(string $data): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $inputBuffer = RustBuffer::fromStringWithPrefix($data);
        $resultBuffer = $ffi->uniffi_ant_ffi_fn_func_encrypt(
            $inputBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Decrypt self-encrypted data.
     *
     * @param string $encrypted The encrypted data
     * @return string The decrypted data
     * @throws AntFfiException on error
     */
    public static function decrypt(string $encrypted): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $inputBuffer = RustBuffer::fromBytes($encrypted);
        $resultBuffer = $ffi->uniffi_ant_ffi_fn_func_decrypt(
            $inputBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Get the maximum size for a chunk.
     */
    public static function chunkMaxSize(): int
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_func_chunk_max_size(FFI::addr($status));
    }

    /**
     * Get the maximum raw size for a chunk.
     */
    public static function chunkMaxRawSize(): int
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_func_chunk_max_raw_size(FFI::addr($status));
    }
}
