package antffi_test

import (
	"bytes"
	"testing"

	"github.com/maidsafe/ant-ffi/go/antffi"
)

func TestEncryptDecrypt(t *testing.T) {
	// Test data - needs to be at least MIN_ENCRYPTABLE_BYTES (3 chunks worth)
	// For self-encryption to work, data needs to be large enough
	testData := make([]byte, 4*1024*1024) // 4MB
	for i := range testData {
		testData[i] = byte(i % 256)
	}

	// Encrypt the data
	encrypted, err := antffi.Encrypt(testData)
	if err != nil {
		t.Fatalf("Encrypt failed: %v", err)
	}

	if encrypted == nil {
		t.Fatal("Encrypt returned nil")
	}

	// Check that encrypted data has size
	if encrypted.Size() == 0 {
		t.Fatal("Encrypted data size is 0")
	}

	t.Logf("Encrypted data size: %d bytes", encrypted.Size())

	// Decrypt the data
	decrypted, err := antffi.Decrypt(encrypted)
	if err != nil {
		t.Fatalf("Decrypt failed: %v", err)
	}

	// Verify the decrypted data matches original
	if !bytes.Equal(decrypted, testData) {
		t.Fatalf("Decrypted data does not match original. Got %d bytes, expected %d bytes", len(decrypted), len(testData))
	}
}

func TestEncryptString(t *testing.T) {
	// Create a large test string
	testStr := ""
	for i := 0; i < 100000; i++ {
		testStr += "Hello, World! "
	}

	// Encrypt the string
	encrypted, err := antffi.EncryptString(testStr)
	if err != nil {
		t.Fatalf("EncryptString failed: %v", err)
	}

	if encrypted == nil {
		t.Fatal("EncryptString returned nil")
	}

	// Decrypt back to string
	decrypted, err := antffi.DecryptToString(encrypted)
	if err != nil {
		t.Fatalf("DecryptToString failed: %v", err)
	}

	if decrypted != testStr {
		t.Fatalf("Decrypted string does not match original")
	}
}

func TestDecryptBytes(t *testing.T) {
	// Test data - needs to be large enough for self-encryption
	testData := make([]byte, 4*1024*1024) // 4MB
	for i := range testData {
		testData[i] = byte((i * 7) % 256)
	}

	// Encrypt the data
	encrypted, err := antffi.Encrypt(testData)
	if err != nil {
		t.Fatalf("Encrypt failed: %v", err)
	}

	// Get raw bytes from encrypted data
	encryptedBytes := encrypted.Bytes()

	// Decrypt using DecryptBytes
	decrypted, err := antffi.DecryptBytes(encryptedBytes)
	if err != nil {
		t.Fatalf("DecryptBytes failed: %v", err)
	}

	// Verify
	if !bytes.Equal(decrypted, testData) {
		t.Fatalf("Decrypted data does not match original")
	}
}

func TestEncryptSmallData(t *testing.T) {
	// Small data should still be encryptable
	smallData := []byte("small data")

	encrypted, err := antffi.Encrypt(smallData)
	if err != nil {
		t.Fatalf("Encrypt failed for small data: %v", err)
	}

	// Decrypt and verify
	decrypted, err := antffi.Decrypt(encrypted)
	if err != nil {
		t.Fatalf("Decrypt failed: %v", err)
	}

	if !bytes.Equal(decrypted, smallData) {
		t.Fatalf("Decrypted data mismatch for small data")
	}

	t.Logf("Small data encryption worked: %d bytes -> %d bytes", len(smallData), encrypted.Size())
}

func TestEncryptedDataBytes(t *testing.T) {
	// Create test data
	testData := make([]byte, 4*1024*1024) // 4MB
	for i := range testData {
		testData[i] = byte(i % 256)
	}

	// Encrypt
	encrypted, err := antffi.Encrypt(testData)
	if err != nil {
		t.Fatalf("Encrypt failed: %v", err)
	}

	// Get bytes
	encryptedBytes := encrypted.Bytes()
	if len(encryptedBytes) == 0 {
		t.Fatal("Encrypted bytes should not be empty")
	}

	// Verify we can round-trip through DecryptBytes
	decrypted, err := antffi.DecryptBytes(encryptedBytes)
	if err != nil {
		t.Fatalf("DecryptBytes failed: %v", err)
	}

	if !bytes.Equal(decrypted, testData) {
		t.Fatal("Data mismatch after round-trip through bytes")
	}
}
