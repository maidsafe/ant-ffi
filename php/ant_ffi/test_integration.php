<?php
/**
 * Integration test: upload and download data from local testnet
 */

require_once __DIR__ . '/vendor/autoload.php';

use AntFfi\FFILoader;
use AntFfi\RustBuffer;
use AntFfi\Async\AsyncHelper;
use AntFfi\Types\Client;
use AntFfi\Types\Network;
use AntFfi\Types\Wallet;

echo "=== PHP FFI Integration Test ===\n\n";

$privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
$testData = "Hello from PHP integration test! " . date('Y-m-d H:i:s');

try {
    // Setup
    echo "1. Creating network and wallet...\n";
    $network = Network::local();
    $wallet = Wallet::fromPrivateKey($network, $privateKey);
    echo "   Wallet: " . $wallet->address() . "\n";

    echo "\n2. Connecting to local network (sync)...\n";
    $client = Client::initLocalSync();
    echo "   Client connected!\n";

    echo "\n3. Uploading data...\n";
    echo "   Data: '$testData'\n";

    $result = $client->dataPutPublicSync($testData, $wallet);

    echo "   Address: " . $result->address->toHex() . "\n";
    echo "   Cost: " . $result->cost . "\n";

    echo "\n4. Downloading data...\n";
    $downloaded = $client->dataGetPublicSync($result->address->toHex());
    echo "   Downloaded: '$downloaded'\n";

    echo "\n5. Verification...\n";
    if ($downloaded === $testData) {
        echo "   ✓ SUCCESS: Data matches!\n";
    } else {
        echo "   ✗ FAILURE: Data mismatch!\n";
        echo "   Expected: '$testData'\n";
        echo "   Got: '$downloaded'\n";
        exit(1);
    }

    echo "\n=== Integration Test PASSED ===\n";

} catch (Throwable $e) {
    echo "\n   ✗ ERROR: " . $e->getMessage() . "\n";
    echo "   File: " . $e->getFile() . ":" . $e->getLine() . "\n";
    echo "   Trace:\n" . $e->getTraceAsString() . "\n";
    exit(1);
}
