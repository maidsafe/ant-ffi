<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\SelfEncryption;

final class SelfEncryptionTest extends TestCase
{
    public function testEncryptDecryptRoundtrip(): void
    {
        $original = 'Hello, Autonomi!';

        $encrypted = SelfEncryption::encrypt($original);
        $this->assertNotEmpty($encrypted);
        $this->assertNotEquals($original, $encrypted);

        $decrypted = SelfEncryption::decrypt($encrypted);
        $this->assertEquals($original, $decrypted);
    }

    public function testEncryptIsDeterministic(): void
    {
        $data = 'Test data for encryption';

        $encrypted1 = SelfEncryption::encrypt($data);
        $encrypted2 = SelfEncryption::encrypt($data);

        // Self-encryption is deterministic
        $this->assertEquals($encrypted1, $encrypted2);
    }

    public function testEncryptEmptyString(): void
    {
        $original = '';

        $encrypted = SelfEncryption::encrypt($original);
        $decrypted = SelfEncryption::decrypt($encrypted);

        $this->assertEquals($original, $decrypted);
    }

    public function testEncryptLargeData(): void
    {
        // Create 1KB of random data
        $original = random_bytes(1024);

        $encrypted = SelfEncryption::encrypt($original);
        $this->assertNotEquals($original, $encrypted);

        $decrypted = SelfEncryption::decrypt($encrypted);
        $this->assertEquals($original, $decrypted);
    }

    public function testChunkMaxSize(): void
    {
        $maxSize = SelfEncryption::chunkMaxSize();
        $this->assertGreaterThan(0, $maxSize);
    }

    public function testChunkMaxRawSize(): void
    {
        $maxRawSize = SelfEncryption::chunkMaxRawSize();
        $this->assertGreaterThan(0, $maxRawSize);
    }
}
