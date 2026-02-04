<?php

declare(strict_types=1);

namespace AntFfi\Tests;

use PHPUnit\Framework\TestCase;
use AntFfi\Types\Client;
use AntFfi\Types\Network;
use AntFfi\Types\Wallet;
use function React\Async\await;

/**
 * Round-trip integration test for PHP FFI bindings.
 *
 * This test:
 * 1. Initializes a client connected to local network
 * 2. Creates a wallet from EVM private key
 * 3. Uploads data to the network
 * 4. Downloads data from the network
 * 5. Verifies the downloaded data matches the original
 *
 * Requirements:
 * - Local Autonomi network running (antctl local status)
 * - Local EVM testnet running (evm-testnet)
 *
 * Run with: vendor/bin/phpunit --testsuite Integration
 *
 * @group e2e
 * @group integration
 */
final class RoundtripTest extends TestCase
{
    private const DEFAULT_TEST_KEY = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';

    private static ?Client $client = null;
    private static ?Network $network = null;
    private static ?Wallet $wallet = null;

    public static function setUpBeforeClass(): void
    {
        echo "\n=== Round-Trip Integration Test ===\n\n";

        // Get private key from environment or use default
        $privateKey = getenv('EVM_PRIVATE_KEY') ?: getenv('SECRET_KEY') ?: self::DEFAULT_TEST_KEY;
        echo "Using private key: " . substr($privateKey, 0, 10) . "...\n";

        // Create network
        echo "Creating network...\n";
        self::$network = Network::local();
        echo "  Network created (local mode)\n";

        // Initialize client
        echo "Initializing client...\n";
        try {
            self::$client = Client::initLocalSync();
            echo "  Client connected\n";
        } catch (\Throwable $e) {
            echo "  ERROR: Failed to connect: " . $e->getMessage() . "\n";
            echo "\n  Make sure local network is running (25+ nodes):\n";
            echo "    antctl local status\n\n";
            throw $e;
        }

        // Create wallet
        echo "Creating wallet...\n";
        try {
            self::$wallet = Wallet::fromPrivateKey(self::$network, $privateKey);
            echo "  Wallet address: " . self::$wallet->address() . "\n";
        } catch (\Throwable $e) {
            echo "  ERROR: Failed to create wallet: " . $e->getMessage() . "\n";
            echo "\n  Make sure EVM testnet is running\n";
            throw $e;
        }

        echo "\n";
    }

    public static function tearDownAfterClass(): void
    {
        echo "\nCleanup...\n";
        self::$wallet?->dispose();
        self::$network?->dispose();
        self::$client?->dispose();
        echo "  Resources disposed\n\n";
    }

    public function testUploadAndDownloadPublicDataRoundtrip(): void
    {
        $testData = 'Hello from PHP FFI round-trip test! ' . date('c') . ' ' . bin2hex(random_bytes(50));
        echo "Test data size: " . strlen($testData) . " bytes\n";

        // Upload data
        echo "Uploading data to network...\n";
        $result = self::$client->dataPutPublicSync($testData, self::$wallet);
        echo "  Upload successful!\n";
        echo "  Address: " . $result->address->toHex() . "\n";
        echo "  Cost: " . $result->cost . "\n";

        // Download data
        echo "Downloading data from network...\n";
        $downloadedData = self::$client->dataGetPublicSync($result->address->toHex());
        echo "  Download successful!\n";
        echo "  Downloaded size: " . strlen($downloadedData) . " bytes\n";

        // Verify data
        echo "Verifying data integrity...\n";
        $this->assertEquals($testData, $downloadedData, 'Downloaded data should match original');
        echo "  Data matches! Round-trip successful!\n";

        // Cleanup
        $result->address->dispose();
    }
}
