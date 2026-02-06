<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use FFI;
use FFI\CData;

/**
 * Secret key for accessing a user's vault.
 */
final class VaultSecretKey extends NativeHandle
{
    /**
     * Generate a random vault secret key.
     */
    public static function random(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create a vault secret key from a hex string.
     */
    public static function fromHex(string $hex): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $hexBuffer = RustBuffer::fromString($hex);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(
            $hexBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Convert to hex string.
     */
    public function toHex(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_vaultsecretkey($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_vaultsecretkey($this->handle, FFI::addr($status));
    }
}

/**
 * User data stored in a vault.
 */
final class UserData extends NativeHandle
{
    /**
     * Create new empty user data.
     */
    public static function create(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_userdata_new(
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the file archives (serialized).
     */
    public function fileArchives(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_userdata_file_archives(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toStringWithPrefix($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Get the private file archives (serialized).
     */
    public function privateFileArchives(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_userdata_private_file_archives(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toStringWithPrefix($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_userdata($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_userdata($this->handle, FFI::addr($status));
    }
}
