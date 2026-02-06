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
 * Result of a public data put operation.
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
 * Result of a private data put operation.
 */
final class PrivateDataPutResult
{
    public DataMapChunk $dataMap;
    public string $cost;

    public function __construct(DataMapChunk $dataMap, string $cost)
    {
        $this->dataMap = $dataMap;
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
     *
     * Uses the dedicated blocking wrapper function that handles
     * Tokio runtime internally.
     */
    public static function initLocalSync(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_func_client_init_local_blocking(FFI::addr($status));

        RustBuffer::checkStatus($status);

        if ($handle === null) {
            throw new AntFfiException('Client initialization returned null');
        }

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

        $dataBuffer = RustBuffer::fromStringWithPrefix($data);
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
     *
     * Uses the dedicated blocking wrapper function that takes wallet directly.
     */
    public function dataPutPublicSync(string $data, Wallet $wallet): DataPutResult
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $dataBuffer = RustBuffer::fromStringWithPrefix($data);

        $ffi->uniffi_ant_ffi_fn_func_client_data_put_public_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $dataBuffer,
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
        return self::parseUploadResult($resultBuffer);
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
     *
     * Uses the dedicated blocking wrapper function.
     */
    public function dataGetPublicSync(string $addressHex): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $addressBuffer = RustBuffer::fromString($addressHex);

        $ffi->uniffi_ant_ffi_fn_func_client_data_get_public_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $addressBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        // The result is a Vec<u8>, serialized as 4-byte BE length + data
        $rawData = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        // Skip the 4-byte length prefix
        if (strlen($rawData) >= 4) {
            return substr($rawData, 4);
        }
        return $rawData;
    }

    /**
     * Get the estimated cost to upload data (blocking).
     *
     * Use this to show a quote before the user confirms an upload.
     *
     * @param string $data The data to estimate cost for
     * @return string The estimated cost in tokens
     */
    public function dataCostSync(string $data): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $dataBuffer = RustBuffer::fromStringWithPrefix($data);

        $ffi->uniffi_ant_ffi_fn_func_client_data_cost_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $dataBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        // The result is a String, serialized as 4-byte BE length + UTF-8 data
        $rawData = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        // Skip the 4-byte length prefix
        if (strlen($rawData) >= 4) {
            return substr($rawData, 4);
        }
        return $rawData;
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
     * PaymentOption::WalletPayment variant (index 0) + wallet_ref handle
     * UniFFI uses big-endian for all numeric values.
     */
    private static function serializePaymentOption(Wallet $wallet): CData
    {
        $ffi = FFILoader::get();

        // PaymentOption enum: 4-byte BE variant index + data
        // Variant 0 = WalletPayment { wallet_ref }
        $data = pack('N', 0); // Variant index (big-endian)

        // wallet_ref is Arc<Wallet> - serialized as 64-bit handle (big-endian)
        $walletHandle = $wallet->cloneForCall();
        $handleInt = FFI::cast('uintptr_t', $walletHandle)->cdata;
        $data .= pack('J', $handleInt); // 64-bit big-endian

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

    /**
     * Parse an UploadResult from a RustBuffer.
     * FileUploadPublicResult has: cost (String), address (Arc<DataAddress> = pointer)
     * UniFFI serializes strings as: 4-byte BE length + UTF-8 data
     * UniFFI serializes Arc pointers as: 8-byte pointer value
     */
    private static function parseUploadResult(CData $resultBuffer): DataPutResult
    {
        $ffi = FFILoader::get();
        $data = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        $offset = 0;

        // Parse cost string
        $costLen = unpack('N', substr($data, $offset, 4))[1];
        $offset += 4;
        $cost = substr($data, $offset, $costLen);
        $offset += $costLen;

        // Parse address pointer (8 bytes)
        $ptrBytes = substr($data, $offset, 8);
        $ptrValue = unpack('J', $ptrBytes)[1];
        $addressHandle = $ffi->cast('void*', $ptrValue);

        return new DataPutResult(new DataAddress($addressHandle), $cost);
    }

    // =========================================================================
    // Private Data Operations
    // =========================================================================

    /**
     * Upload private (encrypted) data synchronously.
     *
     * @param string $data The data to upload
     * @param Wallet $wallet The wallet for payment
     * @return PrivateDataPutResult The result with data map and cost
     */
    public function dataPutSync(string $data, Wallet $wallet): PrivateDataPutResult
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $dataBuffer = RustBuffer::fromStringWithPrefix($data);

        $ffi->uniffi_ant_ffi_fn_func_client_data_put_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $dataBuffer,
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
        return self::parsePrivateUploadResult($resultBuffer);
    }

    /**
     * Download private (encrypted) data synchronously.
     *
     * @param DataMapChunk $dataMap The data map from dataPutSync
     * @return string The decrypted data
     */
    public function dataGetSync(DataMapChunk $dataMap): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_func_client_data_get_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $dataMap->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $rawData = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        if (strlen($rawData) >= 4) {
            return substr($rawData, 4);
        }
        return $rawData;
    }

    // =========================================================================
    // Pointer Operations
    // =========================================================================

    /**
     * Get a network pointer by address.
     */
    public function pointerGetSync(PointerAddress $address): NetworkPointer
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_func_client_pointer_get_blocking(
            $this->cloneForCall(),
            $address->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new NetworkPointer($handle);
    }

    /**
     * Store a network pointer.
     */
    public function pointerPutSync(NetworkPointer $pointer, Wallet $wallet): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $ffi->uniffi_ant_ffi_fn_func_client_pointer_put_blocking(
            $this->cloneForCall(),
            $pointer->cloneForCall(),
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
    }

    // =========================================================================
    // Scratchpad Operations
    // =========================================================================

    /**
     * Get a scratchpad by address.
     */
    public function scratchpadGetSync(ScratchpadAddress $address): Scratchpad
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_func_client_scratchpad_get_blocking(
            $this->cloneForCall(),
            $address->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new Scratchpad($handle);
    }

    /**
     * Store a scratchpad on the network.
     */
    public function scratchpadPutSync(Scratchpad $scratchpad, Wallet $wallet): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_func_client_scratchpad_put_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $scratchpad->cloneForCall(),
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
        RustBuffer::free($resultBuffer);
    }

    // =========================================================================
    // Register Operations
    // =========================================================================

    /**
     * Get a register value by address.
     */
    public function registerGetSync(RegisterAddress $address): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_func_client_register_get_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $address->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $rawData = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        if (strlen($rawData) >= 4) {
            return substr($rawData, 4);
        }
        return $rawData;
    }

    /**
     * Create a new register on the network.
     * Note: Register value must be exactly 32 bytes.
     */
    public function registerCreateSync(SecretKey $owner, string $value, Wallet $wallet): RegisterAddress
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $valueBuffer = RustBuffer::fromStringWithPrefix($value);
        $ffi->uniffi_ant_ffi_fn_func_client_register_create_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $owner->cloneForCall(),
            $valueBuffer,
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        // Parse RegisterCreateResult: cost (String) + address (Arc<RegisterAddress>)
        $data = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        $offset = 0;

        // Parse cost string (4-byte BE length + UTF-8 data)
        $costLen = unpack('N', substr($data, $offset, 4))[1];
        $offset += 4;
        // Skip cost value - we don't need it for the return type
        $offset += $costLen;

        // Parse address pointer (8 bytes)
        $ptrBytes = substr($data, $offset, 8);
        $ptrValue = unpack('J', $ptrBytes)[1];
        $addressHandle = $ffi->cast('void*', $ptrValue);

        return new RegisterAddress($addressHandle);
    }

    /**
     * Update an existing register.
     */
    public function registerUpdateSync(SecretKey $owner, string $value, Wallet $wallet): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $valueBuffer = RustBuffer::fromStringWithPrefix($value);
        $ffi->uniffi_ant_ffi_fn_func_client_register_update_blocking(
            $this->cloneForCall(),
            $owner->cloneForCall(),
            $valueBuffer,
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
    }

    // =========================================================================
    // Graph Entry Operations
    // =========================================================================

    /**
     * Get a graph entry by address.
     */
    public function graphEntryGetSync(GraphEntryAddress $address): GraphEntry
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_func_client_graph_entry_get_blocking(
            $this->cloneForCall(),
            $address->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new GraphEntry($handle);
    }

    /**
     * Store a graph entry on the network.
     */
    public function graphEntryPutSync(GraphEntry $entry, Wallet $wallet): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_func_client_graph_entry_put_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $entry->cloneForCall(),
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
        RustBuffer::free($resultBuffer);
    }

    // =========================================================================
    // Vault Operations
    // =========================================================================

    /**
     * Get user data from a vault.
     */
    public function vaultGetUserDataSync(VaultSecretKey $secretKey): UserData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_func_client_vault_get_user_data_blocking(
            $this->cloneForCall(),
            $secretKey->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new UserData($handle);
    }

    /**
     * Store user data to a vault.
     */
    public function vaultPutUserDataSync(VaultSecretKey $secretKey, UserData $userData, Wallet $wallet): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_func_client_vault_put_user_data_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $secretKey->cloneForCall(),
            $wallet->cloneForCall(),
            $userData->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
        RustBuffer::free($resultBuffer);
    }

    // =========================================================================
    // Archive Operations
    // =========================================================================

    /**
     * Get a public archive by address.
     */
    public function archiveGetPublicSync(ArchiveAddress $address): PublicArchive
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_func_client_archive_get_public_blocking(
            $this->cloneForCall(),
            $address->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new PublicArchive($handle);
    }

    /**
     * Store a public archive on the network.
     */
    public function archivePutPublicSync(PublicArchive $archive, Wallet $wallet): ArchiveAddress
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_func_client_archive_put_public_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $archive->cloneForCall(),
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        // Parse PublicArchivePutResult: cost (String) + address (Arc<ArchiveAddress>)
        $data = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        $offset = 0;

        // Parse cost string (4-byte BE length + UTF-8 data)
        $costLen = unpack('N', substr($data, $offset, 4))[1];
        $offset += 4;
        // Skip cost value - we don't need it for the return type
        $offset += $costLen;

        // Parse address pointer (8 bytes)
        $ptrBytes = substr($data, $offset, 8);
        $ptrValue = unpack('J', $ptrBytes)[1];
        $addressHandle = $ffi->cast('void*', $ptrValue);

        return new ArchiveAddress($addressHandle);
    }

    // =========================================================================
    // File Operations
    // =========================================================================

    /**
     * Upload a file as private (encrypted) data.
     */
    public function fileUploadSync(string $path, Wallet $wallet): PrivateDataPutResult
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $pathBuffer = RustBuffer::fromString($path);

        $ffi->uniffi_ant_ffi_fn_func_client_file_upload_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $pathBuffer,
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
        return self::parsePrivateUploadResult($resultBuffer);
    }

    /**
     * Upload a file as public data.
     */
    public function fileUploadPublicSync(string $path, Wallet $wallet): DataPutResult
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $pathBuffer = RustBuffer::fromString($path);

        $ffi->uniffi_ant_ffi_fn_func_client_file_upload_public_blocking(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            $pathBuffer,
            $wallet->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
        return self::parseUploadResult($resultBuffer);
    }

    /**
     * Download a private file to a local path.
     */
    public function fileDownloadSync(DataMapChunk $dataMap, string $destPath): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $pathBuffer = RustBuffer::fromString($destPath);

        $ffi->uniffi_ant_ffi_fn_func_client_file_download_blocking(
            $this->cloneForCall(),
            $dataMap->cloneForCall(),
            $pathBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
    }

    /**
     * Download a public file to a local path.
     */
    public function fileDownloadPublicSync(DataAddress $address, string $destPath): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $pathBuffer = RustBuffer::fromString($destPath);

        $ffi->uniffi_ant_ffi_fn_func_client_file_download_public_blocking(
            $this->cloneForCall(),
            $address->cloneForCall(),
            $pathBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);
    }

    // =========================================================================
    // Helper Methods
    // =========================================================================

    /**
     * Parse a PrivateDataPutResult from a RustBuffer.
     * Result has: cost (String), data_map pointer (8 bytes BE)
     */
    private static function parsePrivateUploadResult(CData $resultBuffer): PrivateDataPutResult
    {
        $ffi = FFILoader::get();
        $data = RustBuffer::toBytes($resultBuffer);
        RustBuffer::free($resultBuffer);

        $offset = 0;

        // Parse cost string
        $costLen = unpack('N', substr($data, $offset, 4))[1];
        $offset += 4;
        $cost = substr($data, $offset, $costLen);
        $offset += $costLen;

        // Parse data_map pointer (8 bytes big-endian)
        $ptrBytes = substr($data, $offset, 8);
        $ptrValue = unpack('J', $ptrBytes)[1];
        $dataMapHandle = FFI::cast('void*', $ffi->new('uintptr_t', false));
        $dataMapHandle = $ffi->cast('void*', $ptrValue);

        return new PrivateDataPutResult(new DataMapChunk($dataMapHandle), $cost);
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
