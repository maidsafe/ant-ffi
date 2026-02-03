// +build integration

package antffi_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/maidsafe/ant-ffi/go/antffi"
)

// TestPrivateKey is the well-known Hardhat/Anvil test account #0 private key.
// Safe to use for testing as it's publicly documented.
const TestPrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

func TestNetworkNew(t *testing.T) {
	// Create local network
	network, err := antffi.NewNetwork(true)
	if err != nil {
		t.Fatalf("NewNetwork failed: %v", err)
	}
	defer network.Free()

	if !network.IsLocal {
		t.Fatal("Expected local network")
	}
}

func TestNetworkCustom(t *testing.T) {
	rpcURL := os.Getenv("ANT_RPC_URL")
	if rpcURL == "" {
		t.Skip("ANT_RPC_URL not set, skipping custom network test")
	}

	paymentToken := os.Getenv("ANT_PAYMENT_TOKEN_ADDRESS")
	dataPayments := os.Getenv("ANT_DATA_PAYMENTS_ADDRESS")

	network, err := antffi.NewNetworkCustom(rpcURL, paymentToken, dataPayments)
	if err != nil {
		t.Fatalf("NewNetworkCustom failed: %v", err)
	}
	defer network.Free()
}

func TestWalletFromPrivateKey(t *testing.T) {
	network, err := antffi.NewNetwork(true)
	if err != nil {
		t.Fatalf("NewNetwork failed: %v", err)
	}
	defer network.Free()

	wallet, err := antffi.NewWalletFromPrivateKey(network, TestPrivateKey)
	if err != nil {
		t.Fatalf("NewWalletFromPrivateKey failed: %v", err)
	}
	defer wallet.Free()

	address, err := wallet.Address()
	if err != nil {
		t.Fatalf("Address failed: %v", err)
	}

	if address == "" {
		t.Fatal("Wallet address is empty")
	}

	t.Logf("Wallet address: %s", address)
}

func TestClientInit(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := antffi.NewClientLocal(ctx)
	if err != nil {
		t.Fatalf("NewClientLocal failed: %v", err)
	}
	defer client.Free()
}

func TestClientDataPublic(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// Create client
	client, err := antffi.NewClientLocal(ctx)
	if err != nil {
		t.Fatalf("NewClientLocal failed: %v", err)
	}
	defer client.Free()

	// Create network and wallet
	network, err := antffi.NewNetwork(true)
	if err != nil {
		t.Fatalf("NewNetwork failed: %v", err)
	}
	defer network.Free()

	wallet, err := antffi.NewWalletFromPrivateKey(network, TestPrivateKey)
	if err != nil {
		t.Fatalf("NewWalletFromPrivateKey failed: %v", err)
	}
	defer wallet.Free()

	// Upload public data
	testData := []byte("Hello, Autonomi Network!")
	payment := &antffi.PaymentOption{Wallet: wallet}

	result, err := client.DataPutPublic(ctx, testData, payment)
	if err != nil {
		t.Fatalf("DataPutPublic failed: %v", err)
	}

	t.Logf("Data uploaded to: %s (cost: %s)", result.Address, result.Price)

	// Download the data
	downloaded, err := client.DataGetPublic(ctx, result.Address)
	if err != nil {
		t.Fatalf("DataGetPublic failed: %v", err)
	}

	if string(downloaded) != string(testData) {
		t.Fatalf("Data mismatch: %s != %s", downloaded, testData)
	}
}

func TestClientDataPrivate(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// Create client
	client, err := antffi.NewClientLocal(ctx)
	if err != nil {
		t.Fatalf("NewClientLocal failed: %v", err)
	}
	defer client.Free()

	// Create network and wallet
	network, err := antffi.NewNetwork(true)
	if err != nil {
		t.Fatalf("NewNetwork failed: %v", err)
	}
	defer network.Free()

	wallet, err := antffi.NewWalletFromPrivateKey(network, TestPrivateKey)
	if err != nil {
		t.Fatalf("NewWalletFromPrivateKey failed: %v", err)
	}
	defer wallet.Free()

	// Upload private data (self-encrypted)
	// Data needs to be large enough for self-encryption
	testData := make([]byte, 4*1024*1024) // 4MB
	for i := range testData {
		testData[i] = byte(i % 256)
	}

	payment := &antffi.PaymentOption{Wallet: wallet}

	result, err := client.DataPut(ctx, testData, payment)
	if err != nil {
		t.Fatalf("DataPut failed: %v", err)
	}
	defer result.DataMap.Free()

	t.Logf("Data uploaded (cost: %s)", result.Cost)

	// Download the data
	downloaded, err := client.DataGet(ctx, result.DataMap)
	if err != nil {
		t.Fatalf("DataGet failed: %v", err)
	}

	if len(downloaded) != len(testData) {
		t.Fatalf("Data length mismatch: %d != %d", len(downloaded), len(testData))
	}

	for i := range testData {
		if downloaded[i] != testData[i] {
			t.Fatalf("Data mismatch at index %d", i)
		}
	}
}

func TestClientDataCost(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := antffi.NewClientLocal(ctx)
	if err != nil {
		t.Fatalf("NewClientLocal failed: %v", err)
	}
	defer client.Free()

	testData := []byte("Test data for cost calculation")

	cost, err := client.DataCost(ctx, testData)
	if err != nil {
		t.Fatalf("DataCost failed: %v", err)
	}

	t.Logf("Data cost: %s", cost)
}

func TestWalletBalanceOfTokens(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	network, err := antffi.NewNetwork(true)
	if err != nil {
		t.Fatalf("NewNetwork failed: %v", err)
	}
	defer network.Free()

	wallet, err := antffi.NewWalletFromPrivateKey(network, TestPrivateKey)
	if err != nil {
		t.Fatalf("NewWalletFromPrivateKey failed: %v", err)
	}
	defer wallet.Free()

	balance, err := wallet.BalanceOfTokens(ctx)
	if err != nil {
		t.Fatalf("BalanceOfTokens failed: %v", err)
	}

	t.Logf("Wallet balance: %s", balance)
}

func TestClientPointerOperations(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// Create client
	client, err := antffi.NewClientLocal(ctx)
	if err != nil {
		t.Fatalf("NewClientLocal failed: %v", err)
	}
	defer client.Free()

	// Create network and wallet
	network, err := antffi.NewNetwork(true)
	if err != nil {
		t.Fatalf("NewNetwork failed: %v", err)
	}
	defer network.Free()

	wallet, err := antffi.NewWalletFromPrivateKey(network, TestPrivateKey)
	if err != nil {
		t.Fatalf("NewWalletFromPrivateKey failed: %v", err)
	}
	defer wallet.Free()

	// Create a secret key for the pointer
	sk, err := antffi.NewSecretKey()
	if err != nil {
		t.Fatalf("NewSecretKey failed: %v", err)
	}
	defer sk.Free()

	// Create a chunk first as the target
	chunkData := []byte("Target chunk data")
	chunk, err := antffi.NewChunk(chunkData)
	if err != nil {
		t.Fatalf("NewChunk failed: %v", err)
	}
	defer chunk.Free()

	chunkAddr, err := chunk.Address()
	if err != nil {
		t.Fatalf("Address failed: %v", err)
	}
	defer chunkAddr.Free()

	// Create a pointer target
	target, err := antffi.NewPointerTargetChunk(chunkAddr)
	if err != nil {
		t.Fatalf("NewPointerTargetChunk failed: %v", err)
	}
	defer target.Free()

	// Create the network pointer
	pointer, err := antffi.NewNetworkPointer(sk, 0, target)
	if err != nil {
		t.Fatalf("NewNetworkPointer failed: %v", err)
	}
	defer pointer.Free()

	// Put the pointer
	payment := &antffi.PaymentOption{Wallet: wallet}
	err = client.PointerPut(ctx, pointer, payment)
	if err != nil {
		t.Fatalf("PointerPut failed: %v", err)
	}

	// Get the pointer address
	pointerAddr, err := pointer.Address()
	if err != nil {
		t.Fatalf("Address failed: %v", err)
	}
	defer pointerAddr.Free()

	// Get the pointer back
	retrievedPointer, err := client.PointerGet(ctx, pointerAddr)
	if err != nil {
		t.Fatalf("PointerGet failed: %v", err)
	}
	defer retrievedPointer.Free()

	// Verify counter
	counter, err := retrievedPointer.Counter()
	if err != nil {
		t.Fatalf("Counter failed: %v", err)
	}

	if counter != 0 {
		t.Fatalf("Counter mismatch: %d != 0", counter)
	}
}

func TestContextCancellation(t *testing.T) {
	// Create a context that's already cancelled
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	_, err := antffi.NewClientLocal(ctx)
	if err == nil {
		t.Fatal("Expected error for cancelled context")
	}

	if err != context.Canceled {
		t.Logf("Got expected error: %v", err)
	}
}
