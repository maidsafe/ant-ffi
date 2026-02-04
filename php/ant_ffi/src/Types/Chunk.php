<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\AntFfiException;
use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use FFI;
use FFI\CData;

/**
 * A data chunk.
 */
final class Chunk extends NativeHandle
{
    /**
     * Create a new chunk from data.
     */
    public function __construct(string $data)
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $dataBuffer = RustBuffer::fromString($data);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_chunk_new(
            $dataBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        parent::__construct($handle);
    }

    /**
     * Create a chunk from an existing handle.
     * @internal
     */
    public static function fromHandle(CData $handle): self
    {
        $instance = new self('');
        // Override the handle that was set in constructor
        $instance->handle = $handle;
        return $instance;
    }

    /**
     * Get the chunk data.
     */
    public function value(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_chunk_value(
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
     * Get the chunk address.
     */
    public function address(): ChunkAddress
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_chunk_address(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new ChunkAddress($handle);
    }

    /**
     * Get the chunk size in bytes.
     */
    public function size(): int
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        return $ffi->uniffi_ant_ffi_fn_method_chunk_size(
            $this->cloneForCall(),
            FFI::addr($status)
        );
    }

    /**
     * Check if the chunk is too big.
     */
    public function isTooBig(): bool
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        return $ffi->uniffi_ant_ffi_fn_method_chunk_is_too_big(
            $this->cloneForCall(),
            FFI::addr($status)
        ) !== 0;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_chunk($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_chunk($this->handle, FFI::addr($status));
    }
}
