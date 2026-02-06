package antffi_test

import (
	"testing"

	"github.com/maidsafe/ant-ffi/go/antffi"
)

func TestChunkNew(t *testing.T) {
	data := []byte("Hello, World! This is test chunk data.")

	chunk, err := antffi.NewChunk(data)
	if err != nil {
		t.Fatalf("NewChunk failed: %v", err)
	}
	defer chunk.Free()

	// Get value back
	value, err := chunk.Value()
	if err != nil {
		t.Fatalf("Value failed: %v", err)
	}

	if string(value) != string(data) {
		t.Fatalf("Chunk value mismatch: %s != %s", value, data)
	}
}

func TestChunkAddress(t *testing.T) {
	data := []byte("Test data for chunk address")

	chunk, err := antffi.NewChunk(data)
	if err != nil {
		t.Fatalf("NewChunk failed: %v", err)
	}
	defer chunk.Free()

	// Get address
	addr, err := chunk.Address()
	if err != nil {
		t.Fatalf("Address failed: %v", err)
	}
	defer addr.Free()

	// Get hex
	hex, err := addr.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex == "" {
		t.Fatal("Chunk address hex is empty")
	}

	t.Logf("Chunk address: %s", hex)
}

func TestChunkSize(t *testing.T) {
	data := []byte("Some test data for size check")

	chunk, err := antffi.NewChunk(data)
	if err != nil {
		t.Fatalf("NewChunk failed: %v", err)
	}
	defer chunk.Free()

	size, err := chunk.Size()
	if err != nil {
		t.Fatalf("Size failed: %v", err)
	}

	if size == 0 {
		t.Fatal("Chunk size is 0")
	}

	t.Logf("Chunk size: %d bytes", size)
}

func TestChunkIsTooBig(t *testing.T) {
	// Normal sized data should not be too big
	data := []byte("Normal sized test data")

	chunk, err := antffi.NewChunk(data)
	if err != nil {
		t.Fatalf("NewChunk failed: %v", err)
	}
	defer chunk.Free()

	tooBig, err := chunk.IsTooBig()
	if err != nil {
		t.Fatalf("IsTooBig failed: %v", err)
	}

	if tooBig {
		t.Fatal("Small chunk should not be too big")
	}
}

func TestChunkAddressFromHex(t *testing.T) {
	data := []byte("Test data for hex round trip")

	chunk, err := antffi.NewChunk(data)
	if err != nil {
		t.Fatalf("NewChunk failed: %v", err)
	}
	defer chunk.Free()

	addr1, err := chunk.Address()
	if err != nil {
		t.Fatalf("Address failed: %v", err)
	}
	defer addr1.Free()

	hex, err := addr1.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	// Create address from hex
	addr2, err := antffi.ChunkAddressFromHex(hex)
	if err != nil {
		t.Fatalf("ChunkAddressFromHex failed: %v", err)
	}
	defer addr2.Free()

	// Verify they produce the same hex
	hex2, err := addr2.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex != hex2 {
		t.Fatalf("Hex mismatch: %s != %s", hex, hex2)
	}
}

func TestChunkAddressFromContent(t *testing.T) {
	data := []byte("Test data for content-based address")

	// Create address from content
	addr, err := antffi.ChunkAddressFromContent(data)
	if err != nil {
		t.Fatalf("ChunkAddressFromContent failed: %v", err)
	}
	defer addr.Free()

	hex, err := addr.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex == "" {
		t.Fatal("Address hex is empty")
	}

	t.Logf("Content address: %s", hex)
}

func TestDataAddressFromHex(t *testing.T) {
	// First create a chunk to get a valid address
	data := []byte("Test data for data address")

	chunk, err := antffi.NewChunk(data)
	if err != nil {
		t.Fatalf("NewChunk failed: %v", err)
	}
	defer chunk.Free()

	chunkAddr, err := chunk.Address()
	if err != nil {
		t.Fatalf("Address failed: %v", err)
	}
	defer chunkAddr.Free()

	hex, err := chunkAddr.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	// Create DataAddress from hex
	dataAddr, err := antffi.DataAddressFromHex(hex)
	if err != nil {
		t.Fatalf("DataAddressFromHex failed: %v", err)
	}
	defer dataAddr.Free()

	// Verify they produce the same hex
	hex2, err := dataAddr.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex != hex2 {
		t.Fatalf("Hex mismatch: %s != %s", hex, hex2)
	}
}

func TestChunkConstants(t *testing.T) {
	maxSize, err := antffi.ChunkMaxSize()
	if err != nil {
		t.Fatalf("ChunkMaxSize failed: %v", err)
	}

	maxRawSize, err := antffi.ChunkMaxRawSize()
	if err != nil {
		t.Fatalf("ChunkMaxRawSize failed: %v", err)
	}

	if maxSize == 0 {
		t.Fatal("ChunkMaxSize returned 0")
	}

	if maxRawSize == 0 {
		t.Fatal("ChunkMaxRawSize returned 0")
	}

	t.Logf("ChunkMaxSize: %d", maxSize)
	t.Logf("ChunkMaxRawSize: %d", maxRawSize)

	// Max raw size should be less than or equal to max size
	if maxRawSize > maxSize {
		t.Fatal("MaxRawSize should be <= MaxSize")
	}
}

func TestMetadata(t *testing.T) {
	// Create metadata with size only
	meta1, err := antffi.NewMetadata(1234)
	if err != nil {
		t.Fatalf("NewMetadata failed: %v", err)
	}
	defer meta1.Free()

	size, err := meta1.Size()
	if err != nil {
		t.Fatalf("Size failed: %v", err)
	}

	if size != 1234 {
		t.Fatalf("Size mismatch: %d != 1234", size)
	}

	// Create metadata with timestamps
	meta2, err := antffi.NewMetadataWithTimestamps(5678, 1000000, 2000000)
	if err != nil {
		t.Fatalf("NewMetadataWithTimestamps failed: %v", err)
	}
	defer meta2.Free()

	size, err = meta2.Size()
	if err != nil {
		t.Fatalf("Size failed: %v", err)
	}

	if size != 5678 {
		t.Fatalf("Size mismatch: %d != 5678", size)
	}

	created, err := meta2.Created()
	if err != nil {
		t.Fatalf("Created failed: %v", err)
	}

	if created != 1000000 {
		t.Fatalf("Created mismatch: %d != 1000000", created)
	}

	modified, err := meta2.Modified()
	if err != nil {
		t.Fatalf("Modified failed: %v", err)
	}

	if modified != 2000000 {
		t.Fatalf("Modified mismatch: %d != 2000000", modified)
	}
}

func TestPublicArchive(t *testing.T) {
	// Create a new public archive
	archive, err := antffi.NewPublicArchive()
	if err != nil {
		t.Fatalf("NewPublicArchive failed: %v", err)
	}
	defer archive.Free()

	// Check initial file count
	count, err := archive.FileCount()
	if err != nil {
		t.Fatalf("FileCount failed: %v", err)
	}

	if count != 0 {
		t.Fatalf("Initial file count should be 0, got %d", count)
	}
}

func TestPrivateArchive(t *testing.T) {
	// Create a new private archive
	archive, err := antffi.NewPrivateArchive()
	if err != nil {
		t.Fatalf("NewPrivateArchive failed: %v", err)
	}
	defer archive.Free()

	// Check initial file count
	count, err := archive.FileCount()
	if err != nil {
		t.Fatalf("FileCount failed: %v", err)
	}

	if count != 0 {
		t.Fatalf("Initial file count should be 0, got %d", count)
	}
}

func TestVaultSecretKey(t *testing.T) {
	// Create a random vault secret key
	vsk, err := antffi.NewVaultSecretKey()
	if err != nil {
		t.Fatalf("NewVaultSecretKey failed: %v", err)
	}
	defer vsk.Free()

	// Get hex
	hex, err := vsk.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex == "" {
		t.Fatal("Vault secret key hex is empty")
	}

	t.Logf("Vault secret key: %s", hex)

	// Create from hex
	vsk2, err := antffi.VaultSecretKeyFromHex(hex)
	if err != nil {
		t.Fatalf("VaultSecretKeyFromHex failed: %v", err)
	}
	defer vsk2.Free()

	hex2, err := vsk2.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex != hex2 {
		t.Fatalf("Hex mismatch: %s != %s", hex, hex2)
	}
}

func TestUserData(t *testing.T) {
	// Create new user data
	ud, err := antffi.NewUserData()
	if err != nil {
		t.Fatalf("NewUserData failed: %v", err)
	}
	defer ud.Free()

	// User data should be created successfully
	if ud == nil {
		t.Fatal("NewUserData returned nil")
	}
}
