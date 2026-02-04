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
 * A payment wallet.
 */
final class Wallet extends NativeHandle
{
    /**
     * Create a wallet from a private key.
     *
     * @param Network $network The network configuration
     * @param string $privateKey The EVM private key (with or without 0x prefix)
     */
    public static function fromPrivateKey(Network $network, string $privateKey): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $keyBuffer = RustBuffer::fromString($privateKey);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(
            $network->cloneForCall(),
            $keyBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the wallet address.
     */
    public function address(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_wallet_address(
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
        $ffi->uniffi_ant_ffi_fn_free_wallet($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_wallet($this->handle, FFI::addr($status));
    }
}
