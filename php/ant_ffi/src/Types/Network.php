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
 * Network configuration.
 */
final class Network extends NativeHandle
{
    /**
     * Create a local network configuration.
     */
    public static function local(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_network_new(
            1, // true for local
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create a mainnet network configuration.
     */
    public static function mainnet(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_network_new(
            0, // false for mainnet
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create a custom network configuration.
     */
    public static function custom(string $rpcUrl, string $paymentTokenAddress, string $dataPaymentsAddress): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $rpcBuffer = RustBuffer::fromString($rpcUrl);
        $tokenBuffer = RustBuffer::fromString($paymentTokenAddress);
        $paymentsBuffer = RustBuffer::fromString($dataPaymentsAddress);

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_network_custom(
            $rpcBuffer,
            $tokenBuffer,
            $paymentsBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_network($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_network($this->handle, FFI::addr($status));
    }
}
