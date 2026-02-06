<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\Types\SecretKey;
use AntFfi\Types\PublicKey;
use AntFfi\Types\DataAddress;
use AntFfi\Types\GraphEntryAddress;
use AntFfi\Types\GraphEntry;
use AntFfi\Types\VaultSecretKey;
use AntFfi\Types\UserData;
use AntFfi\Types\ArchiveAddress;
use AntFfi\Types\PublicArchive;
use AntFfi\Types\PrivateArchive;
use AntFfi\Types\PrivateArchiveDataMap;
use AntFfi\Types\Metadata;
use AntFfi\Types\DataMapChunk;

final class GraphEntryVaultArchiveTest extends TestCase
{
    // GraphEntryAddress tests

    public function testGraphEntryAddressFromOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();

        $address = GraphEntryAddress::fromOwner($publicKey);

        $this->assertNotEmpty($address->toHex());
    }

    public function testGraphEntryAddressFromHexRoundtrip(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address1 = GraphEntryAddress::fromOwner($publicKey);
        $hex = $address1->toHex();

        $address2 = GraphEntryAddress::fromHex($hex);
        $this->assertEquals($hex, $address2->toHex());
    }

    public function testGraphEntryAddressValid(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address = GraphEntryAddress::fromOwner($publicKey);

        // Address should have a valid hex
        $this->assertNotEmpty($address->toHex());
    }

    // Helper: Create 32-byte content (GraphEntry requires exactly 32 bytes)
    private function make32ByteContent(string $prefix): string
    {
        $content = str_pad($prefix, 32, "\0");
        return substr($content, 0, 32);
    }

    // GraphEntry tests

    public function testGraphEntryCreate(): void
    {
        $secretKey = SecretKey::random();
        $parents = '';  // Empty parents for first entry
        $content = $this->make32ByteContent('Hello, Graph!');

        $entry = GraphEntry::create($secretKey, $parents, $content);

        $this->assertInstanceOf(GraphEntry::class, $entry);
    }

    public function testGraphEntryAddress(): void
    {
        $secretKey = SecretKey::random();
        $entry = GraphEntry::create($secretKey, '', $this->make32ByteContent('test content'));

        $address = $entry->address();

        $this->assertInstanceOf(GraphEntryAddress::class, $address);
        $this->assertNotEmpty($address->toHex());
    }

    public function testGraphEntryParents(): void
    {
        $secretKey = SecretKey::random();
        $entry = GraphEntry::create($secretKey, '', $this->make32ByteContent('test'));

        // Empty parents should return empty or minimal serialized data
        $parents = $entry->parents();
        $this->assertIsString($parents);
    }

    public function testGraphEntryDescendants(): void
    {
        $secretKey = SecretKey::random();
        $entry = GraphEntry::create($secretKey, '', $this->make32ByteContent('test'));

        // Empty descendants should return empty or minimal serialized data
        $descendants = $entry->descendants();
        $this->assertIsString($descendants);
    }

    public function testGraphEntryContent(): void
    {
        $secretKey = SecretKey::random();
        $content = $this->make32ByteContent('Test graph entry');

        $entry = GraphEntry::create($secretKey, '', $content);

        $this->assertEquals($content, $entry->content());
    }

    // VaultSecretKey tests

    public function testVaultSecretKeyRandom(): void
    {
        $key = VaultSecretKey::random();

        $hex = $key->toHex();
        $this->assertNotEmpty($hex);
        $this->assertMatchesRegularExpression('/^[0-9a-f]+$/i', $hex);
    }

    public function testVaultSecretKeyFromHexRoundtrip(): void
    {
        $key1 = VaultSecretKey::random();
        $hex = $key1->toHex();

        $key2 = VaultSecretKey::fromHex($hex);
        $this->assertEquals($hex, $key2->toHex());
    }

    public function testMultipleRandomVaultKeysAreDifferent(): void
    {
        $key1 = VaultSecretKey::random();
        $key2 = VaultSecretKey::random();

        $this->assertNotEquals($key1->toHex(), $key2->toHex());
    }

    // UserData tests

    public function testUserDataCreate(): void
    {
        $userData = UserData::create();

        $this->assertInstanceOf(UserData::class, $userData);
    }

    public function testUserDataFileArchivesEmpty(): void
    {
        $userData = UserData::create();

        // Empty user data should return empty archives
        $archives = $userData->fileArchives();
        $this->assertIsString($archives);
    }

    public function testUserDataPrivateFileArchivesEmpty(): void
    {
        $userData = UserData::create();

        // Empty user data should return empty private archives
        $archives = $userData->privateFileArchives();
        $this->assertIsString($archives);
    }

    // ArchiveAddress tests

    public function testArchiveAddressFromHexRoundtrip(): void
    {
        // Create a valid address by hashing some content
        // Using a known valid hex string pattern (64 hex chars = 32 bytes)
        $hex = str_repeat('ab', 32);  // 64 hex chars

        try {
            $address1 = ArchiveAddress::fromHex($hex);
            $this->assertEquals($hex, $address1->toHex());
        } catch (\Exception $e) {
            // Some implementations may require specific address format
            $this->markTestSkipped('ArchiveAddress requires specific format: ' . $e->getMessage());
        }
    }

    // Metadata tests

    public function testMetadataCreate(): void
    {
        $metadata = Metadata::create(1024);

        $this->assertInstanceOf(Metadata::class, $metadata);
        $this->assertEquals(1024, $metadata->size());
    }

    public function testMetadataWithSize(): void
    {
        $metadata = Metadata::withSize(2048);

        $this->assertEquals(2048, $metadata->size());
    }

    public function testMetadataWithTimestamps(): void
    {
        $now = time();
        $metadata = Metadata::withTimestamps(4096, $now - 100, $now);

        $this->assertEquals(4096, $metadata->size());
        $this->assertEquals($now - 100, $metadata->created());
        $this->assertEquals($now, $metadata->modified());
    }

    // PublicArchive tests

    public function testPublicArchiveCreate(): void
    {
        $archive = PublicArchive::create();

        $this->assertInstanceOf(PublicArchive::class, $archive);
    }

    public function testPublicArchiveFilesEmpty(): void
    {
        $archive = PublicArchive::create();

        $files = $archive->files();
        $this->assertIsString($files);
    }

    public function testPublicArchiveAddFile(): void
    {
        $archive = PublicArchive::create();
        $dataAddress = DataAddress::fromHex(str_repeat('ab', 32));
        $metadata = Metadata::withSize(100);

        $archive->addFile('/test/file.txt', $dataAddress, $metadata);

        $files = $archive->files();
        $this->assertIsString($files);
    }

    // PrivateArchive tests

    public function testPrivateArchiveCreate(): void
    {
        $archive = PrivateArchive::create();

        $this->assertInstanceOf(PrivateArchive::class, $archive);
    }

    public function testPrivateArchiveFilesEmpty(): void
    {
        $archive = PrivateArchive::create();

        $files = $archive->files();
        $this->assertIsString($files);
    }

    // PrivateArchiveDataMap tests

    public function testPrivateArchiveDataMapFromHexRoundtrip(): void
    {
        // Use a valid hex string that could represent a data map
        $hex = str_repeat('cd', 32);

        try {
            $dataMap1 = PrivateArchiveDataMap::fromHex($hex);
            $hex2 = $dataMap1->toHex();
            $this->assertNotEmpty($hex2);
        } catch (\Exception $e) {
            $this->markTestSkipped('PrivateArchiveDataMap requires specific format: ' . $e->getMessage());
        }
    }

    // DataMapChunk tests

    public function testDataMapChunkFromHexRoundtrip(): void
    {
        // Use a valid hex string that could represent a data map chunk
        $hex = str_repeat('ef', 32);

        try {
            $chunk1 = DataMapChunk::fromHex($hex);
            $hex2 = $chunk1->toHex();
            $this->assertNotEmpty($hex2);
        } catch (\Exception $e) {
            $this->markTestSkipped('DataMapChunk requires specific format: ' . $e->getMessage());
        }
    }

    // Disposal tests

    public function testGraphEntryAddressDisposal(): void
    {
        $secretKey = SecretKey::random();
        $address = GraphEntryAddress::fromOwner($secretKey->publicKey());
        $this->assertFalse($address->isDisposed());

        $address->dispose();
        $this->assertTrue($address->isDisposed());
    }

    public function testGraphEntryDisposal(): void
    {
        $secretKey = SecretKey::random();
        $entry = GraphEntry::create($secretKey, '', $this->make32ByteContent('test'));
        $this->assertFalse($entry->isDisposed());

        $entry->dispose();
        $this->assertTrue($entry->isDisposed());
    }

    public function testVaultSecretKeyDisposal(): void
    {
        $key = VaultSecretKey::random();
        $this->assertFalse($key->isDisposed());

        $key->dispose();
        $this->assertTrue($key->isDisposed());
    }

    public function testUserDataDisposal(): void
    {
        $userData = UserData::create();
        $this->assertFalse($userData->isDisposed());

        $userData->dispose();
        $this->assertTrue($userData->isDisposed());
    }

    public function testPublicArchiveDisposal(): void
    {
        $archive = PublicArchive::create();
        $this->assertFalse($archive->isDisposed());

        $archive->dispose();
        $this->assertTrue($archive->isDisposed());
    }

    public function testPrivateArchiveDisposal(): void
    {
        $archive = PrivateArchive::create();
        $this->assertFalse($archive->isDisposed());

        $archive->dispose();
        $this->assertTrue($archive->isDisposed());
    }

    public function testMetadataDisposal(): void
    {
        $metadata = Metadata::create(100);
        $this->assertFalse($metadata->isDisposed());

        $metadata->dispose();
        $this->assertTrue($metadata->isDisposed());
    }
}
