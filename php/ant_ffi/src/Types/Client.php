<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\AntFfiException;
use AntFfi\Async\AsyncFuture;
use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use React\Promise\PromiseInterface;
use FFI;
use FFI\CData;

/**
 * Result of a data put operation.
 */
final class DataPutResult
{
    public DataAddress $address;
    public string $cost;

    public function __construct(DataAddress $address, string $cost)
    {
        $this->address = $address;
        $this->cost = $cost;
    }
}

/**
 * Network client for the Autonomi network.
 */
final class Client extends NativeHandle
{
    /**
     * Initialize a client connected to the default network.
     *
     * @return PromiseInterface<Client> Promise that resolves to the client
     */
    public static function init(): PromiseInterface
    {
        $ffi = FFILoader::get();
        $futureHandle = $ffi->uniffi_ant_ffi_fn_constructor_client_init();

        return AsyncFuture::pollPointer($futureHandle)
            ->then(fn(CData $handle) => new self($handle));
    }

    /**
     * Initialize a client connected to the local network.
     *
     * @return PromiseInterface<Client> Promise that resolves to the client
     */
    public static function initLocal(): PromiseInterface
    {
        $ffi = FFILoader::get();
        $futureHandle = $ffi->uniffi_ant_ffi_fn_constructor_client_init_local();

        return AsyncFuture::pollPointer($futureHandle)
            ->then(fn(CData $handle) => new self($handle));
    }

    /**
     * Initialize a client with specific peer addresses.
     *
     * @param string[] $peers Array of multiaddr peer addresses
     * @param Network $network Network configuration
     * @return PromiseInterface<Client> Promise that resolves to the client
     */
    public static function initWithPeers(array $peers, Network $network): PromiseInterface
    {
        $ffi = FFILoader::get();

        $peersBuffer = self::serializeStringList($peers);
        $dataDirBuffer = self::serializeOptionString(null);

        $futureHandle = $ffi->uniffi_ant_ffi_fn_constructor_client_init_with_peers(
            $peersBuffer,
            $network->cloneForCall(),
            $dataDirBuffer
        );

        return AsyncFuture::pollPointer($futureHandle)
            ->then(fn(CData $handle) => new self($handle));
    }

    /**
     * Initialize a client synchronously (blocking).
     * Use for simple scripts that don't need ReactPHP.
     */
    public static function initLocalSync(): self
    {
        $ffi = FFILoader::get();
        $futureHandle = $ffi->uniffi_ant_ffi_fn_constructor_client_init_local();
        $handle = AsyncFuture::awaitPointer($futureHandle);
        return new self($handle);
    }

    /**
     * Upload public data to the network.
     *
     * @param string $data The data to upload
     * @param Wallet $wallet The wallet for payment
     * @return PromiseInterface<DataPutResult> Promise that resolves to the result
     */
    public function dataPutPublic(string $data, Wallet $wallet): PromiseInterface
    {
        $ffi = FFILoader::get();

        $dataBuffer = RustBuffer::fromString($data);
        $paymentBuffer = self::serializePaymentOption($wallet);

        $futureHandle = $ffi->uniffi_ant_ffi_fn_method_client_data_put_public(
            $this->cloneForCall(),
            $dataBuffer,
            $paymentBuffer
        );

        return AsyncFuture::pollRustBuffer($futureHandle)
            ->then(function (CData $resultBuffer) {
                return self::parseDataPutResult($resultBuffer);
            });
    }

    /**
     * Upload public data synchronously (blocking).
     */
    public function dataPutPublicSync(string $data, Wallet $wallet): DataPutResult
    {
        $ffi = FFILoader::get();

        $dataBuffer = RustBuffer::fromString($data);
        $paymentBuffer = self::serializePaymentOption($wallet);

        $futureHandle = $ffi->uniffi_ant_ffi_fn_method_client_data_put_public(
            $this->cloneForCall(),
            $dataBuffer,
            $paymentBuffer
        );

        $resultBuffer = AsyncFuture::awaitRustBuffer($futureHandle);
        return self::parseDataPutResult($resultBuffer);
    }

    /**
     * Download public data from the network.
     *
     * @param string $addressHex The data address in hex format
     * @return PromiseInterface<string> Promise that resolves to the data
     */
    public function dataGetPublic(string $addressHex): PromiseInterface
    {
        $ffi = FFILoader::get();

        $addressBuffer = RustBuffer::fromString($addressHex);

        $futureHandle = $ffi->uniffi_ant_ffi_fn_method_client_data_get_public(
            $this->cloneForCall(),
            $addressBuffer
        );

        return AsyncFuture::pollRustBuffer($futureHandle)
            ->then(function (CData $resultBuffer) {
                $data = RustBuffer::toString($resultBuffer);
                RustBuffer::free($resultBuffer);
                return $data;
            });
    }

    /**
     * Download public data synchronously (blocking).
     */
    public function dataGetPublicSync(string $addressHex): string
    {
        $ffi = FFILoader::get();

        $addressBuffer = RustBuffer::fromString($addressHex);

        $futureHandle = $ffi->uniffi_ant_ffi_fn_method_client_data_get_public(
            $this->cloneForCall(),
            $addressBuffer
        );

        $resultBuffer = AsyncFuture::awaitRustBuffer($futureHandle);
        $data = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);
        return $data;
    }

    /**
     * Serialize a list of strings for UniFFI.
     * Format: 4-byte BE count + each string with 4-byte BE length prefix
     */
    private static function serializeStringList(array $strings): CData
    {
        $count = count($strings);
        $data = pack('N', $count);

        foreach ($strings as $str) {
            $data .= pack('N', strlen($str)) . $str;
        }

        return RustBuffer::fromBytes($data);
    }

    /**
     * Serialize an optional string for UniFFI.
     * Format: 1 byte (0 = None, 1 = Some) + if Some: 4-byte BE length + string
     */
    private static function serializeOptionString(?string $str): CData
    {
        if ($str === null) {
            return RustBuffer::fromBytes(pack('C', 0));
        }
        return RustBuffer::fromBytes(pack('C', 1) . pack('N', strlen($str)) . $str);
    }

    /**
     * Serialize a PaymentOption for UniFFI.
     * PaymentOption::Wallet variant (index 0) + wallet handle
     */
    private static function serializePaymentOption(Wallet $wallet): CData
    {
        $ffi = FFILoader::get();

        // PaymentOption enum: 4-byte variant index + data
        // Variant 0 = Wallet
        $data = pack('N', 0); // Variant index

        // The wallet handle needs to be serialized as a pointer
        // In UniFFI, object handles are passed as pointers
        $walletHandle = $wallet->cloneForCall();
        $handleInt = FFI::cast('uintptr_t', $walletHandle)->cdata;
        $data .= pack('P', $handleInt); // 8-byte pointer

        return RustBuffer::fromBytes($data);
    }

    /**
     * Parse a DataPutResult from a RustBuffer.
     */
    private static function parseDataPutResult(CData $resultBuffer): DataPutResult
    {
        // The result is a serialized struct with address and cost
        // For now, return a simplified result
        $data = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        // Parse the address (first 32 bytes of hex encoded data)
        // This is a simplification - actual parsing depends on UniFFI serialization
        $addressHex = bin2hex(substr($data, 0, 32));
        $address = DataAddress::fromHex($addressHex);

        // Cost is typically after the address
        $cost = '0';

        return new DataPutResult($address, $cost);
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_client($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_client($this->handle, FFI::addr($status));
    }
}
