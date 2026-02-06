<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\Types\SecretKey;
use AntFfi\Types\PublicKey;

final class KeysTest extends TestCase
{
    public function testSecretKeyRandom(): void
    {
        $key = SecretKey::random();
        $hex = $key->toHex();

        $this->assertNotEmpty($hex);
        $this->assertMatchesRegularExpression('/^[0-9a-f]+$/i', $hex);
    }

    public function testSecretKeyFromHexRoundtrip(): void
    {
        $key1 = SecretKey::random();
        $hex = $key1->toHex();

        $key2 = SecretKey::fromHex($hex);
        $this->assertEquals($hex, $key2->toHex());
    }

    public function testPublicKeyDerivation(): void
    {
        $secret = SecretKey::random();
        $public = $secret->publicKey();

        $this->assertNotEmpty($public->toHex());
        $this->assertNotEquals($secret->toHex(), $public->toHex());
    }

    public function testMultipleRandomKeysAreDifferent(): void
    {
        $key1 = SecretKey::random();
        $key2 = SecretKey::random();

        $this->assertNotEquals($key1->toHex(), $key2->toHex());
    }

    public function testPublicKeyFromHexRoundtrip(): void
    {
        $secret = SecretKey::random();
        $public = $secret->publicKey();
        $hex = $public->toHex();

        $public2 = PublicKey::fromHex($hex);
        $this->assertEquals($hex, $public2->toHex());
    }

    public function testKeyDisposal(): void
    {
        $key = SecretKey::random();
        $this->assertFalse($key->isDisposed());

        $key->dispose();
        $this->assertTrue($key->isDisposed());
    }
}
