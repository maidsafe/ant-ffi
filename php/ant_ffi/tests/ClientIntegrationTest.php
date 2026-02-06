<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\Types\Client;
use AntFfi\Types\Network;
use AntFfi\Types\Wallet;
use AntFfi\Types\SecretKey;
use AntFfi\Types\ChunkAddress;
use AntFfi\Types\DataAddress;
use AntFfi\Types\DataMapChunk;
use AntFfi\Types\PointerAddress;
use AntFfi\Types\PointerTarget;
use AntFfi\Types\NetworkPointer;
use AntFfi\Types\ScratchpadAddress;
use AntFfi\Types\Scratchpad;
use AntFfi\Types\RegisterAddress;
use AntFfi\Types\GraphEntryAddress;
use AntFfi\Types\GraphEntry;
use AntFfi\Types\VaultSecretKey;
use AntFfi\Types\UserData;
use AntFfi\Types\PublicArchive;
use AntFfi\Types\Metadata;

/**
 * End-to-end integration tests for client operations.
 *
 * These tests require a local Autonomi testnet running.
 * Run with: vendor/bin/phpunit --group integration
 *
 * To start a local testnet:
 * cd C:\tools\ant && setup-testnet.bat
 *
 * @group integration
 */
final class ClientIntegrationTest extends TestCase
{
    private const DEFAULT_TEST_KEY = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

    private ?Client $client = null;
    private ?Wallet $wallet = null;

    protected function setUp(): void
    {
        // Initialize client and wallet for tests
        try {
            $this->client = Client::initLocalSync();
            $network = Network::local();
            $this->wallet = Wallet::fromPrivateKey($network, self::DEFAULT_TEST_KEY);
        } catch (\Exception $e) {
            $this->markTestSkipped('Local testnet not available: ' . $e->getMessage());
        }
    }

    protected function tearDown(): void
    {
        if ($this->client !== null) {
            $this->client->dispose();
        }
        if ($this->wallet !== null) {
            $this->wallet->dispose();
        }
    }

    // =========================================================================
    // Public Data Operations
    // =========================================================================

    public function testDataPutPublicAndGetSync(): void
    {
        $data = 'Hello, Autonomi Network! ' . uniqid();

        $result = $this->client->dataPutPublicSync($data, $this->wallet);

        $this->assertNotEmpty($result->address->toHex());
        $this->assertNotEmpty($result->cost);

        // Retrieve the data
        $retrieved = $this->client->dataGetPublicSync($result->address->toHex());
        $this->assertEquals($data, $retrieved);
    }

    public function testDataCostSync(): void
    {
        $data = str_repeat('X', 1000); // 1KB of data

        $cost = $this->client->dataCostSync($data);

        $this->assertNotEmpty($cost);
        $this->assertIsString($cost);
    }

    // =========================================================================
    // Private Data Operations
    // =========================================================================

    public function testPrivateDataPutAndGetSync(): void
    {
        $data = 'Secret data: ' . uniqid();

        $result = $this->client->dataPutSync($data, $this->wallet);

        $this->assertInstanceOf(DataMapChunk::class, $result->dataMap);
        $this->assertNotEmpty($result->cost);

        // Retrieve the private data using the data map
        $retrieved = $this->client->dataGetSync($result->dataMap);
        $this->assertEquals($data, $retrieved);
    }

    // =========================================================================
    // Pointer Operations
    // =========================================================================

    public function testPointerPutAndGetSync(): void
    {
        $ownerKey = SecretKey::random();

        // Create a chunk address to point to
        $chunkAddress = ChunkAddress::fromContent('target content');
        $target = PointerTarget::fromChunkAddress($chunkAddress);

        // Create and store the pointer
        $pointer = NetworkPointer::create($ownerKey, 0, $target);
        $this->client->pointerPutSync($pointer, $this->wallet);

        // Retrieve the pointer
        $address = $pointer->address();
        $retrieved = $this->client->pointerGetSync($address);

        $this->assertEquals($pointer->counter(), $retrieved->counter());
        $this->assertEquals($pointer->owner()->toHex(), $retrieved->owner()->toHex());
    }

    public function testPointerUpdate(): void
    {
        $ownerKey = SecretKey::random();

        // Create initial pointer
        $target1 = PointerTarget::fromChunkAddress(ChunkAddress::fromContent('target1'));
        $pointer1 = NetworkPointer::create($ownerKey, 0, $target1);
        $this->client->pointerPutSync($pointer1, $this->wallet);

        // Update the pointer with higher counter
        $target2 = PointerTarget::fromChunkAddress(ChunkAddress::fromContent('target2'));
        $pointer2 = NetworkPointer::create($ownerKey, 1, $target2);
        $this->client->pointerPutSync($pointer2, $this->wallet);

        // Retrieve and verify the updated pointer
        $address = $pointer2->address();
        $retrieved = $this->client->pointerGetSync($address);

        $this->assertEquals(1, $retrieved->counter());
    }

    // =========================================================================
    // Scratchpad Operations
    // =========================================================================

    public function testScratchpadPutAndGetSync(): void
    {
        $ownerKey = SecretKey::random();
        $data = 'Scratchpad content: ' . uniqid();

        // Create and store the scratchpad
        $scratchpad = Scratchpad::create($ownerKey, 1, $data, 0);
        $this->client->scratchpadPutSync($scratchpad, $this->wallet);

        // Retrieve the scratchpad
        $address = $scratchpad->address();
        $retrieved = $this->client->scratchpadGetSync($address);

        // Scratchpad stores encrypted data - use decryptData to get original
        $this->assertEquals($data, $retrieved->decryptData($ownerKey));
        $this->assertEquals(0, $retrieved->counter());
        $this->assertEquals(1, $retrieved->dataEncoding());
        $this->assertTrue($retrieved->isValid());
    }

    public function testScratchpadUpdate(): void
    {
        $ownerKey = SecretKey::random();

        // Create initial scratchpad
        $scratchpad1 = Scratchpad::create($ownerKey, 1, 'initial data', 0);
        $this->client->scratchpadPutSync($scratchpad1, $this->wallet);

        // Update the scratchpad with higher counter
        $scratchpad2 = Scratchpad::create($ownerKey, 1, 'updated data', 1);
        $this->client->scratchpadPutSync($scratchpad2, $this->wallet);

        // Retrieve and verify the updated scratchpad
        $address = $scratchpad2->address();
        $retrieved = $this->client->scratchpadGetSync($address);

        // Scratchpad stores encrypted data - use decryptData to get original
        $this->assertEquals('updated data', $retrieved->decryptData($ownerKey));
        $this->assertEquals(1, $retrieved->counter());
    }

    // =========================================================================
    // Register Operations
    // =========================================================================

    private function make32ByteValue(string $prefix): string
    {
        $value = str_pad($prefix, 32, "\0");
        return substr($value, 0, 32);
    }

    public function testRegisterCreateAndGetSync(): void
    {
        $ownerKey = SecretKey::random();
        // Register value must be exactly 32 bytes
        $value = $this->make32ByteValue('Reg value: ' . substr(uniqid(), 0, 10));

        // Create the register
        $address = $this->client->registerCreateSync($ownerKey, $value, $this->wallet);

        $this->assertInstanceOf(RegisterAddress::class, $address);

        // Retrieve the register value
        $retrieved = $this->client->registerGetSync($address);
        $this->assertEquals($value, $retrieved);
    }

    public function testRegisterUpdate(): void
    {
        $ownerKey = SecretKey::random();
        // Register value must be exactly 32 bytes
        $initialValue = $this->make32ByteValue('initial');

        // Create the register
        $address = $this->client->registerCreateSync($ownerKey, $initialValue, $this->wallet);

        // Update the register with new 32-byte value
        $updatedValue = $this->make32ByteValue('updated');
        $this->client->registerUpdateSync($ownerKey, $updatedValue, $this->wallet);

        // Retrieve and verify the updated value
        $retrieved = $this->client->registerGetSync($address);
        $this->assertEquals($updatedValue, $retrieved);
    }

    // =========================================================================
    // Graph Entry Operations
    // =========================================================================

    private function make32ByteContent(string $prefix): string
    {
        $content = str_pad($prefix, 32, "\0");
        return substr($content, 0, 32);
    }

    public function testGraphEntryPutAndGetSync(): void
    {
        $ownerKey = SecretKey::random();
        // GraphEntry content must be exactly 32 bytes
        $content = $this->make32ByteContent('Graph entry: ' . substr(uniqid(), 0, 10));

        // Create and store the graph entry
        $entry = GraphEntry::create($ownerKey, '', $content);
        $this->client->graphEntryPutSync($entry, $this->wallet);

        // Retrieve the graph entry
        $address = $entry->address();
        $retrieved = $this->client->graphEntryGetSync($address);

        $this->assertEquals($content, $retrieved->content());
        // Verify addresses match (owner method not available on GraphEntry)
        $this->assertEquals($entry->address()->toHex(), $retrieved->address()->toHex());
    }

    // =========================================================================
    // Vault Operations
    // =========================================================================

    public function testVaultPutAndGetUserDataSync(): void
    {
        $vaultKey = VaultSecretKey::random();
        $userData = UserData::create();

        // Store user data to the vault
        $this->client->vaultPutUserDataSync($vaultKey, $userData, $this->wallet);

        // Retrieve user data from the vault
        $retrieved = $this->client->vaultGetUserDataSync($vaultKey);

        $this->assertInstanceOf(UserData::class, $retrieved);
    }

    // =========================================================================
    // Archive Operations
    // =========================================================================

    public function testArchivePutAndGetPublicSync(): void
    {
        // Create an empty archive first (simpler test)
        $archive = PublicArchive::create();

        // Store the empty archive
        $address = $this->client->archivePutPublicSync($archive, $this->wallet);

        $this->assertNotEmpty($address->toHex());

        // Retrieve the archive
        $retrieved = $this->client->archiveGetPublicSync($address);

        $this->assertInstanceOf(PublicArchive::class, $retrieved);
    }

    public function testArchiveWithFileSync(): void
    {
        // TODO: Investigate crash in addFile method - possibly handle update issue
        $this->markTestSkipped('Archive addFile crashes - needs investigation');
    }

    // =========================================================================
    // File Operations
    // =========================================================================

    public function testFileUploadPublicSync(): void
    {
        // Create a temporary file
        $tempFile = sys_get_temp_dir() . '/ant_test_' . uniqid() . '.txt';
        file_put_contents($tempFile, 'Test file content: ' . uniqid());

        try {
            $result = $this->client->fileUploadPublicSync($tempFile, $this->wallet);

            $this->assertNotEmpty($result->address->toHex());
            $this->assertNotEmpty($result->cost);

            // Verify we can download the file content
            $downloaded = $this->client->dataGetPublicSync($result->address->toHex());
            $this->assertEquals(file_get_contents($tempFile), $downloaded);
        } finally {
            unlink($tempFile);
        }
    }

    public function testFileUploadSync(): void
    {
        // Create a temporary file
        $tempFile = sys_get_temp_dir() . '/ant_test_private_' . uniqid() . '.txt';
        file_put_contents($tempFile, 'Private file content: ' . uniqid());

        try {
            $result = $this->client->fileUploadSync($tempFile, $this->wallet);

            $this->assertInstanceOf(DataMapChunk::class, $result->dataMap);
            $this->assertNotEmpty($result->cost);

            // Verify we can download the file content
            $downloaded = $this->client->dataGetSync($result->dataMap);
            $this->assertEquals(file_get_contents($tempFile), $downloaded);
        } finally {
            unlink($tempFile);
        }
    }

    public function testFileDownloadPublicSync(): void
    {
        // Upload a file first
        $tempUpload = sys_get_temp_dir() . '/ant_upload_' . uniqid() . '.txt';
        $content = 'Content for download test: ' . uniqid();
        file_put_contents($tempUpload, $content);

        try {
            $result = $this->client->fileUploadPublicSync($tempUpload, $this->wallet);

            // Download to a new file
            $tempDownload = sys_get_temp_dir() . '/ant_download_' . uniqid() . '.txt';
            $this->client->fileDownloadPublicSync($result->address, $tempDownload);

            $this->assertFileExists($tempDownload);
            $this->assertEquals($content, file_get_contents($tempDownload));

            unlink($tempDownload);
        } finally {
            unlink($tempUpload);
        }
    }

    public function testFileDownloadSync(): void
    {
        // Upload a private file first
        $tempUpload = sys_get_temp_dir() . '/ant_private_upload_' . uniqid() . '.txt';
        $content = 'Private content for download test: ' . uniqid();
        file_put_contents($tempUpload, $content);

        try {
            $result = $this->client->fileUploadSync($tempUpload, $this->wallet);

            // Download to a new file
            $tempDownload = sys_get_temp_dir() . '/ant_private_download_' . uniqid() . '.txt';
            $this->client->fileDownloadSync($result->dataMap, $tempDownload);

            $this->assertFileExists($tempDownload);
            $this->assertEquals($content, file_get_contents($tempDownload));

            unlink($tempDownload);
        } finally {
            unlink($tempUpload);
        }
    }

    // =========================================================================
    // Error Handling Tests
    // =========================================================================

    public function testGetNonExistentPointer(): void
    {
        $ownerKey = SecretKey::random();
        $address = PointerAddress::fromOwner($ownerKey->publicKey());

        $this->expectException(\AntFfi\AntFfiException::class);
        $this->client->pointerGetSync($address);
    }

    public function testGetNonExistentScratchpad(): void
    {
        $ownerKey = SecretKey::random();
        $address = ScratchpadAddress::fromOwner($ownerKey->publicKey());

        $this->expectException(\AntFfi\AntFfiException::class);
        $this->client->scratchpadGetSync($address);
    }

    public function testGetNonExistentRegister(): void
    {
        $ownerKey = SecretKey::random();
        $address = RegisterAddress::fromOwner($ownerKey->publicKey());

        $this->expectException(\AntFfi\AntFfiException::class);
        $this->client->registerGetSync($address);
    }

    public function testGetNonExistentGraphEntry(): void
    {
        $ownerKey = SecretKey::random();
        $address = GraphEntryAddress::fromOwner($ownerKey->publicKey());

        $this->expectException(\AntFfi\AntFfiException::class);
        $this->client->graphEntryGetSync($address);
    }
}
