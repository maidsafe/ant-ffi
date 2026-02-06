<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use FFI;
use FFI\CData;

/**
 * Address of a register on the network.
 */
final class RegisterAddress extends NativeHandle
{
    /**
     * Create a register address from the owner public key.
     */
    public static function fromOwner(PublicKey $owner): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_registeraddress_new(
            $owner->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create from a hex string.
     */
    public static function fromHex(string $hex): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $hexBuffer = RustBuffer::fromString($hex);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(
            $hexBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the owner public key.
     */
    public function owner(): PublicKey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_registeraddress_owner(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new PublicKey($handle);
    }

    /**
     * Convert to hex string.
     */
    public function toHex(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_registeraddress_to_hex(
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
        $ffi->uniffi_ant_ffi_fn_free_registeraddress($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_registeraddress($this->handle, FFI::addr($status));
    }
}
