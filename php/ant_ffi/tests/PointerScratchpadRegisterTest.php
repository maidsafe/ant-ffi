<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\Types\SecretKey;
use AntFfi\Types\PublicKey;
use AntFfi\Types\ChunkAddress;
use AntFfi\Types\PointerAddress;
use AntFfi\Types\PointerTarget;
use AntFfi\Types\NetworkPointer;
use AntFfi\Types\ScratchpadAddress;
use AntFfi\Types\Scratchpad;
use AntFfi\Types\RegisterAddress;
use AntFfi\Types\GraphEntryAddress;

final class PointerScratchpadRegisterTest extends TestCase
{
    // PointerAddress tests

    public function testPointerAddressFromOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();

        $address = PointerAddress::fromOwner($publicKey);

        $this->assertNotEmpty($address->toHex());
    }

    public function testPointerAddressFromHexRoundtrip(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address1 = PointerAddress::fromOwner($publicKey);
        $hex = $address1->toHex();

        $address2 = PointerAddress::fromHex($hex);
        $this->assertEquals($hex, $address2->toHex());
    }

    public function testPointerAddressOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address = PointerAddress::fromOwner($publicKey);

        $owner = $address->owner();
        $this->assertEquals($publicKey->toHex(), $owner->toHex());
    }

    // PointerTarget tests

    public function testPointerTargetFromChunkAddress(): void
    {
        $chunkAddress = ChunkAddress::fromContent('test content');
        $target = PointerTarget::fromChunkAddress($chunkAddress);

        $this->assertInstanceOf(PointerTarget::class, $target);
        $this->assertFalse($target->isDisposed());
    }

    public function testPointerTargetFromPointerAddress(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $pointerAddress = PointerAddress::fromOwner($publicKey);

        $target = PointerTarget::fromPointerAddress($pointerAddress);

        $this->assertInstanceOf(PointerTarget::class, $target);
    }

    public function testPointerTargetFromScratchpadAddress(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $scratchpadAddress = ScratchpadAddress::fromOwner($publicKey);

        $target = PointerTarget::fromScratchpadAddress($scratchpadAddress);

        $this->assertInstanceOf(PointerTarget::class, $target);
    }

    public function testPointerTargetFromGraphEntryAddress(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $graphEntryAddress = GraphEntryAddress::fromOwner($publicKey);

        $target = PointerTarget::fromGraphEntryAddress($graphEntryAddress);

        $this->assertInstanceOf(PointerTarget::class, $target);
    }

    // NetworkPointer tests

    public function testNetworkPointerCreate(): void
    {
        $secretKey = SecretKey::random();
        $chunkAddress = ChunkAddress::fromContent('test content');
        $target = PointerTarget::fromChunkAddress($chunkAddress);

        $pointer = NetworkPointer::create($secretKey, 0, $target);

        $this->assertInstanceOf(NetworkPointer::class, $pointer);
    }

    public function testNetworkPointerCounter(): void
    {
        $secretKey = SecretKey::random();
        $chunkAddress = ChunkAddress::fromContent('test content');
        $target = PointerTarget::fromChunkAddress($chunkAddress);

        $pointer = NetworkPointer::create($secretKey, 42, $target);

        $this->assertEquals(42, $pointer->counter());
    }

    public function testNetworkPointerAddress(): void
    {
        $secretKey = SecretKey::random();
        $chunkAddress = ChunkAddress::fromContent('test content');
        $target = PointerTarget::fromChunkAddress($chunkAddress);
        $pointer = NetworkPointer::create($secretKey, 0, $target);

        $address = $pointer->address();

        $this->assertInstanceOf(PointerAddress::class, $address);
        $this->assertNotEmpty($address->toHex());
    }

    public function testNetworkPointerOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $chunkAddress = ChunkAddress::fromContent('test content');
        $target = PointerTarget::fromChunkAddress($chunkAddress);
        $pointer = NetworkPointer::create($secretKey, 0, $target);

        $owner = $pointer->owner();

        $this->assertEquals($publicKey->toHex(), $owner->toHex());
    }

    public function testNetworkPointerTarget(): void
    {
        $secretKey = SecretKey::random();
        $chunkAddress = ChunkAddress::fromContent('test content');
        $target = PointerTarget::fromChunkAddress($chunkAddress);
        $pointer = NetworkPointer::create($secretKey, 0, $target);

        $retrievedTarget = $pointer->target();

        $this->assertInstanceOf(PointerTarget::class, $retrievedTarget);
    }

    // ScratchpadAddress tests

    public function testScratchpadAddressFromOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();

        $address = ScratchpadAddress::fromOwner($publicKey);

        $this->assertNotEmpty($address->toHex());
    }

    public function testScratchpadAddressFromHexRoundtrip(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address1 = ScratchpadAddress::fromOwner($publicKey);
        $hex = $address1->toHex();

        $address2 = ScratchpadAddress::fromHex($hex);
        $this->assertEquals($hex, $address2->toHex());
    }

    public function testScratchpadAddressOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address = ScratchpadAddress::fromOwner($publicKey);

        $owner = $address->owner();
        $this->assertEquals($publicKey->toHex(), $owner->toHex());
    }

    // Scratchpad tests

    public function testScratchpadCreate(): void
    {
        $secretKey = SecretKey::random();
        $data = 'Hello, Scratchpad!';

        $scratchpad = Scratchpad::create($secretKey, 1, $data, 0);

        $this->assertInstanceOf(Scratchpad::class, $scratchpad);
    }

    public function testScratchpadCounter(): void
    {
        $secretKey = SecretKey::random();

        $scratchpad = Scratchpad::create($secretKey, 1, 'test', 42);

        $this->assertEquals(42, $scratchpad->counter());
    }

    public function testScratchpadContentType(): void
    {
        $secretKey = SecretKey::random();

        $scratchpad = Scratchpad::create($secretKey, 99, 'test', 0);

        $this->assertEquals(99, $scratchpad->contentType());
    }

    public function testScratchpadData(): void
    {
        $secretKey = SecretKey::random();
        $data = 'Test scratchpad data';

        $scratchpad = Scratchpad::create($secretKey, 1, $data, 0);

        // Scratchpad stores encrypted data, so we need to decrypt to get original
        $this->assertEquals($data, $scratchpad->decryptData($secretKey));
    }

    public function testScratchpadEncryptedData(): void
    {
        $secretKey = SecretKey::random();
        $data = 'Test scratchpad data';

        $scratchpad = Scratchpad::create($secretKey, 1, $data, 0);

        // encryptedData() should return non-empty binary data
        $encrypted = $scratchpad->encryptedData();
        $this->assertNotEmpty($encrypted);
        $this->assertNotEquals($data, $encrypted); // Should be encrypted
    }

    public function testScratchpadAddress(): void
    {
        $secretKey = SecretKey::random();
        $scratchpad = Scratchpad::create($secretKey, 1, 'test', 0);

        $address = $scratchpad->address();

        $this->assertInstanceOf(ScratchpadAddress::class, $address);
        $this->assertNotEmpty($address->toHex());
    }

    public function testScratchpadOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $scratchpad = Scratchpad::create($secretKey, 1, 'test', 0);

        $owner = $scratchpad->owner();

        $this->assertEquals($publicKey->toHex(), $owner->toHex());
    }

    public function testScratchpadIsValid(): void
    {
        $secretKey = SecretKey::random();
        $scratchpad = Scratchpad::create($secretKey, 1, 'test', 0);

        $this->assertTrue($scratchpad->isValid());
    }

    // RegisterAddress tests

    public function testRegisterAddressFromOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();

        $address = RegisterAddress::fromOwner($publicKey);

        $this->assertNotEmpty($address->toHex());
    }

    public function testRegisterAddressFromHexRoundtrip(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address1 = RegisterAddress::fromOwner($publicKey);
        $hex = $address1->toHex();

        $address2 = RegisterAddress::fromHex($hex);
        $this->assertEquals($hex, $address2->toHex());
    }

    public function testRegisterAddressOwner(): void
    {
        $secretKey = SecretKey::random();
        $publicKey = $secretKey->publicKey();
        $address = RegisterAddress::fromOwner($publicKey);

        $owner = $address->owner();
        $this->assertEquals($publicKey->toHex(), $owner->toHex());
    }

    // Disposal tests

    public function testPointerAddressDisposal(): void
    {
        $secretKey = SecretKey::random();
        $address = PointerAddress::fromOwner($secretKey->publicKey());
        $this->assertFalse($address->isDisposed());

        $address->dispose();
        $this->assertTrue($address->isDisposed());
    }

    public function testNetworkPointerDisposal(): void
    {
        $secretKey = SecretKey::random();
        $chunkAddress = ChunkAddress::fromContent('test');
        $target = PointerTarget::fromChunkAddress($chunkAddress);
        $pointer = NetworkPointer::create($secretKey, 0, $target);
        $this->assertFalse($pointer->isDisposed());

        $pointer->dispose();
        $this->assertTrue($pointer->isDisposed());
    }

    public function testScratchpadDisposal(): void
    {
        $secretKey = SecretKey::random();
        $scratchpad = Scratchpad::create($secretKey, 1, 'test', 0);
        $this->assertFalse($scratchpad->isDisposed());

        $scratchpad->dispose();
        $this->assertTrue($scratchpad->isDisposed());
    }

    public function testRegisterAddressDisposal(): void
    {
        $secretKey = SecretKey::random();
        $address = RegisterAddress::fromOwner($secretKey->publicKey());
        $this->assertFalse($address->isDisposed());

        $address->dispose();
        $this->assertTrue($address->isDisposed());
    }
}
