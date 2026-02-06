<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use FFI;
use FFI\CData;

/**
 * Address of a graph entry on the network.
 */
final class GraphEntryAddress extends NativeHandle
{
    /**
     * Create a graph entry address from the owner public key.
     */
    public static function fromOwner(PublicKey $owner): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_graphentryaddress_new(
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
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(
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

        $handle = $ffi->uniffi_ant_ffi_fn_method_graphentryaddress_owner(
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

        $ffi->uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(
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
        $ffi->uniffi_ant_ffi_fn_free_graphentryaddress($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_graphentryaddress($this->handle, FFI::addr($status));
    }
}

/**
 * A graph entry in the DAG structure.
 *
 * Graph entries form a directed acyclic graph (DAG) where each entry
 * can reference parent entries.
 */
final class GraphEntry extends NativeHandle
{
    /**
     * Create a new graph entry.
     *
     * @param SecretKey $owner The owner's secret key
     * @param string $parents Serialized parent addresses
     * @param string $content The content to store
     */
    public static function create(SecretKey $owner, string $parents, string $content): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $parentsBuffer = RustBuffer::fromStringWithPrefix($parents);
        $contentBuffer = RustBuffer::fromStringWithPrefix($content);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_graphentry_new(
            $owner->cloneForCall(),
            $parentsBuffer,
            $contentBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the address of this graph entry.
     */
    public function address(): GraphEntryAddress
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_graphentry_address(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new GraphEntryAddress($handle);
    }

    /**
     * Get the owner's public key.
     */
    public function owner(): PublicKey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_graphentry_owner(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new PublicKey($handle);
    }

    /**
     * Get the content.
     */
    public function content(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_graphentry_content(
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
        $ffi->uniffi_ant_ffi_fn_free_graphentry($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_graphentry($this->handle, FFI::addr($status));
    }
}
