<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use FFI;
use FFI\CData;

/**
 * Address of a scratchpad on the network.
 */
final class ScratchpadAddress extends NativeHandle
{
    /**
     * Create a scratchpad address from the owner public key.
     */
    public static function fromOwner(PublicKey $owner): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(
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
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(
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

        $handle = $ffi->uniffi_ant_ffi_fn_method_scratchpadaddress_owner(
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

        $ffi->uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(
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
        $ffi->uniffi_ant_ffi_fn_free_scratchpadaddress($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_scratchpadaddress($this->handle, FFI::addr($status));
    }
}

/**
 * A mutable scratchpad on the network.
 *
 * Scratchpads can be updated by the owner and are useful for storing
 * frequently changing data.
 */
final class Scratchpad extends NativeHandle
{
    /**
     * Create a new scratchpad.
     *
     * @param SecretKey $owner The owner's secret key
     * @param int $contentType Content type identifier
     * @param string $data The data to store
     * @param int $counter Monotonically increasing counter
     */
    public static function create(SecretKey $owner, int $contentType, string $data, int $counter): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $dataBuffer = RustBuffer::fromStringWithPrefix($data);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_scratchpad_new(
            $owner->cloneForCall(),
            $contentType,
            $dataBuffer,
            $counter,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the address of this scratchpad.
     */
    public function address(): ScratchpadAddress
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_scratchpad_address(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new ScratchpadAddress($handle);
    }

    /**
     * Get the counter value.
     */
    public function counter(): int
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $result = $ffi->uniffi_ant_ffi_fn_method_scratchpad_counter(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return $result;
    }

    /**
     * Get the data encoding type.
     */
    public function dataEncoding(): int
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $result = $ffi->uniffi_ant_ffi_fn_method_scratchpad_data_encoding(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return $result;
    }

    /**
     * Alias for dataEncoding() for backwards compatibility.
     */
    public function contentType(): int
    {
        return $this->dataEncoding();
    }

    /**
     * Get the encrypted data.
     */
    public function encryptedData(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_scratchpad_encrypted_data(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Alias for encryptedData() for backwards compatibility.
     */
    public function data(): string
    {
        return $this->encryptedData();
    }

    /**
     * Decrypt the scratchpad data with the owner's secret key.
     */
    public function decryptData(SecretKey $sk): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_scratchpad_decrypt_data(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $sk->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Verify the scratchpad signature is valid.
     * Throws an exception if invalid.
     */
    public function verify(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $ffi->uniffi_ant_ffi_fn_func_scratchpad_verify(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
    }

    /**
     * Check if the scratchpad signature is valid.
     */
    public function isValid(): bool
    {
        try {
            $this->verify();
            return true;
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * Get the owner's public key.
     */
    public function owner(): PublicKey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_scratchpad_owner(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new PublicKey($handle);
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_scratchpad($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_scratchpad($this->handle, FFI::addr($status));
    }
}
