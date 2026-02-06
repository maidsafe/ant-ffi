<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use FFI;
use FFI\CData;

/**
 * Address of an archive on the network.
 */
final class ArchiveAddress extends NativeHandle
{
    /**
     * Create from a hex string.
     */
    public static function fromHex(string $hex): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $hexBuffer = RustBuffer::fromString($hex);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(
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

        $ffi->uniffi_ant_ffi_fn_method_archiveaddress_to_hex(
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
        $ffi->uniffi_ant_ffi_fn_free_archiveaddress($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_archiveaddress($this->handle, FFI::addr($status));
    }
}

/**
 * Metadata for a file in an archive.
 */
final class Metadata extends NativeHandle
{
    /**
     * Create new empty metadata.
     */
    public static function create(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_metadata_new(
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create metadata with a file size.
     */
    public static function withSize(int $size): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_metadata_with_size(
            $size,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the file size.
     */
    public function size(): int
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $result = $ffi->uniffi_ant_ffi_fn_method_metadata_size(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_metadata($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_metadata($this->handle, FFI::addr($status));
    }
}

/**
 * A public archive containing files and their addresses.
 */
final class PublicArchive extends NativeHandle
{
    /**
     * Create a new empty public archive.
     */
    public static function create(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_publicarchive_new(
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Add a file to the archive.
     *
     * @param string $path The file path within the archive
     * @param DataAddress $dataAddress The address where the file data is stored
     * @param Metadata $metadata File metadata
     */
    public function addFile(string $path, DataAddress $dataAddress, Metadata $metadata): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $pathBuffer = RustBuffer::fromString($path);
        $ffi->uniffi_ant_ffi_fn_method_publicarchive_add_file(
            $this->cloneForCall(),
            $pathBuffer,
            $dataAddress->cloneForCall(),
            $metadata->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
    }

    /**
     * Get the files in this archive (serialized).
     */
    public function files(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_publicarchive_files(
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
        $ffi->uniffi_ant_ffi_fn_free_publicarchive($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_publicarchive($this->handle, FFI::addr($status));
    }
}

/**
 * A private archive containing files and their encrypted data maps.
 */
final class PrivateArchive extends NativeHandle
{
    /**
     * Create a new empty private archive.
     */
    public static function create(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_privatearchive_new(
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Add a file to the archive.
     *
     * @param string $path The file path within the archive
     * @param DataMapChunk $dataMap The data map for the encrypted file
     * @param Metadata $metadata File metadata
     */
    public function addFile(string $path, DataMapChunk $dataMap, Metadata $metadata): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $pathBuffer = RustBuffer::fromString($path);
        $ffi->uniffi_ant_ffi_fn_method_privatearchive_add_file(
            $this->cloneForCall(),
            $pathBuffer,
            $dataMap->cloneForCall(),
            $metadata->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
    }

    /**
     * Get the files in this archive (serialized).
     */
    public function files(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_privatearchive_files(
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
        $ffi->uniffi_ant_ffi_fn_free_privatearchive($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_privatearchive($this->handle, FFI::addr($status));
    }
}

/**
 * Data map for a private archive.
 */
final class PrivateArchiveDataMap extends NativeHandle
{
    /**
     * Create from a hex string.
     */
    public static function fromHex(string $hex): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $hexBuffer = RustBuffer::fromString($hex);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(
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

        $ffi->uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(
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
        $ffi->uniffi_ant_ffi_fn_free_privatearchivedatamap($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_privatearchivedatamap($this->handle, FFI::addr($status));
    }
}
