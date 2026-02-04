<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\Types\Network;
use AntFfi\Types\Wallet;
use AntFfi\AntFfiException;

/**
 * Tests for Network and Wallet types.
 *
 * Note: These tests require a local EVM testnet running.
 * Tests that require network are marked as @group integration.
 */
final class NetworkWalletTest extends TestCase
{
    private const DEFAULT_TEST_KEY = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

    public function testNetworkLocalCreation(): void
    {
        $network = Network::local();
        $this->assertFalse($network->isDisposed());
    }

    public function testNetworkMainnetCreation(): void
    {
        $network = Network::mainnet();
        $this->assertFalse($network->isDisposed());
    }

    public function testNetworkDisposal(): void
    {
        $network = Network::local();
        $this->assertFalse($network->isDisposed());

        $network->dispose();
        $this->assertTrue($network->isDisposed());
    }

    /**
     * @group integration
     */
    public function testWalletCreation(): void
    {
        $network = Network::local();
        $wallet = Wallet::fromPrivateKey($network, self::DEFAULT_TEST_KEY);

        $this->assertFalse($wallet->isDisposed());
    }

    /**
     * @group integration
     */
    public function testWalletAddress(): void
    {
        $network = Network::local();
        $wallet = Wallet::fromPrivateKey($network, self::DEFAULT_TEST_KEY);

        $address = $wallet->address();
        $this->assertNotEmpty($address);
        // Ethereum addresses are 40 hex chars (or 42 with 0x prefix)
        $this->assertMatchesRegularExpression('/^(0x)?[0-9a-f]{40}$/i', $address);
    }

    /**
     * @group integration
     */
    public function testWalletDisposal(): void
    {
        $network = Network::local();
        $wallet = Wallet::fromPrivateKey($network, self::DEFAULT_TEST_KEY);

        $this->assertFalse($wallet->isDisposed());
        $wallet->dispose();
        $this->assertTrue($wallet->isDisposed());
    }
}
