// +build integration

package antffi_test

import (
	"context"
	"testing"
	"time"

	"github.com/maidsafe/ant-ffi/go/antffi"
)

// TestDataStreamPublic tests streaming public data from the network.
// This test requires a running local testnet with uploaded data.
func TestDataStreamPublic(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
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

	// Upload test data first
	testData := []byte("Hello, this is test data for streaming! " + time.Now().String())
	payment := &antffi.PaymentOption{Wallet: wallet}

	result, err := client.DataPutPublic(ctx, testData, payment)
	if err != nil {
		t.Fatalf("DataPutPublic failed: %v", err)
	}
	t.Logf("Uploaded data to address: %s", result.Address)

	// Parse the address
	address, err := antffi.NewDataAddressFromHex(result.Address)
	if err != nil {
		t.Fatalf("NewDataAddressFromHex failed: %v", err)
	}
	defer address.Free()

	// Create a stream for the uploaded data
	stream, err := client.DataStreamPublic(ctx, address)
	if err != nil {
		t.Fatalf("DataStreamPublic failed: %v", err)
	}
	defer stream.Free()

	// Get data size
	size, err := stream.DataSize()
	if err != nil {
		t.Fatalf("DataSize failed: %v", err)
	}
	t.Logf("Stream data size: %d bytes", size)

	if size != uint64(len(testData)) {
		t.Errorf("Expected size %d, got %d", len(testData), size)
	}

	// Collect all data
	collected, err := stream.CollectAll()
	if err != nil {
		t.Fatalf("CollectAll failed: %v", err)
	}

	if string(collected) != string(testData) {
		t.Errorf("Collected data mismatch.\nExpected: %s\nGot: %s", testData, collected)
	}

	t.Log("DataStreamPublic test passed!")
}

// TestDataStreamGetRange tests getting a specific range from streamed data.
func TestDataStreamGetRange(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
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

	// Upload test data
	testData := []byte("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
	payment := &antffi.PaymentOption{Wallet: wallet}

	result, err := client.DataPutPublic(ctx, testData, payment)
	if err != nil {
		t.Fatalf("DataPutPublic failed: %v", err)
	}
	t.Logf("Uploaded data to address: %s", result.Address)

	// Parse the address
	address, err := antffi.NewDataAddressFromHex(result.Address)
	if err != nil {
		t.Fatalf("NewDataAddressFromHex failed: %v", err)
	}
	defer address.Free()

	// Create a stream
	stream, err := client.DataStreamPublic(ctx, address)
	if err != nil {
		t.Fatalf("DataStreamPublic failed: %v", err)
	}
	defer stream.Free()

	// Get a specific range (bytes 10-19, which is "KLMNOPQRST")
	rangeData, err := stream.GetRange(10, 10)
	if err != nil {
		t.Fatalf("GetRange failed: %v", err)
	}

	expected := "KLMNOPQRST"
	if string(rangeData) != expected {
		t.Errorf("Range data mismatch.\nExpected: %s\nGot: %s", expected, string(rangeData))
	}

	t.Log("DataStreamGetRange test passed!")
}

// TestDataStreamNextChunk tests iterating through chunks.
func TestDataStreamNextChunk(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
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

	// Upload test data
	testData := []byte("Test data for chunk iteration")
	payment := &antffi.PaymentOption{Wallet: wallet}

	result, err := client.DataPutPublic(ctx, testData, payment)
	if err != nil {
		t.Fatalf("DataPutPublic failed: %v", err)
	}

	// Parse the address
	address, err := antffi.NewDataAddressFromHex(result.Address)
	if err != nil {
		t.Fatalf("NewDataAddressFromHex failed: %v", err)
	}
	defer address.Free()

	// Create a stream
	stream, err := client.DataStreamPublic(ctx, address)
	if err != nil {
		t.Fatalf("DataStreamPublic failed: %v", err)
	}
	defer stream.Free()

	// Iterate through chunks
	var allData []byte
	chunkCount := 0
	for {
		chunk, err := stream.NextChunk()
		if err != nil {
			t.Fatalf("NextChunk failed: %v", err)
		}
		if chunk == nil {
			break // Stream exhausted
		}
		allData = append(allData, chunk...)
		chunkCount++
		t.Logf("Chunk %d: %d bytes", chunkCount, len(chunk))
	}

	t.Logf("Total chunks: %d, total bytes: %d", chunkCount, len(allData))

	if string(allData) != string(testData) {
		t.Errorf("Chunked data mismatch.\nExpected: %s\nGot: %s", testData, allData)
	}

	t.Log("DataStreamNextChunk test passed!")
}
