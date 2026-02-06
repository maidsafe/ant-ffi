package antffi_test

import (
	"testing"

	"github.com/maidsafe/ant-ffi/go/antffi"
)

func TestSecretKeyRandom(t *testing.T) {
	sk, err := antffi.NewSecretKey()
	if err != nil {
		t.Fatalf("NewSecretKey failed: %v", err)
	}
	defer sk.Free()

	// Get hex representation
	hex, err := sk.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex == "" {
		t.Fatal("ToHex returned empty string")
	}

	t.Logf("Secret key hex: %s", hex)
}

func TestSecretKeyFromHex(t *testing.T) {
	// Create a random key first
	sk1, err := antffi.NewSecretKey()
	if err != nil {
		t.Fatalf("NewSecretKey failed: %v", err)
	}
	defer sk1.Free()

	// Get hex
	hex, err := sk1.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	// Create key from hex
	sk2, err := antffi.SecretKeyFromHex(hex)
	if err != nil {
		t.Fatalf("SecretKeyFromHex failed: %v", err)
	}
	defer sk2.Free()

	// Verify they produce the same hex
	hex2, err := sk2.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex != hex2 {
		t.Fatalf("Hex mismatch: %s != %s", hex, hex2)
	}
}

func TestSecretKeyPublicKey(t *testing.T) {
	sk, err := antffi.NewSecretKey()
	if err != nil {
		t.Fatalf("NewSecretKey failed: %v", err)
	}
	defer sk.Free()

	pk, err := sk.PublicKey()
	if err != nil {
		t.Fatalf("PublicKey failed: %v", err)
	}
	defer pk.Free()

	hex, err := pk.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex == "" {
		t.Fatal("Public key hex is empty")
	}

	t.Logf("Public key hex: %s", hex)
}

func TestPublicKeyFromHex(t *testing.T) {
	// Create a secret key first
	sk, err := antffi.NewSecretKey()
	if err != nil {
		t.Fatalf("NewSecretKey failed: %v", err)
	}
	defer sk.Free()

	// Get public key
	pk1, err := sk.PublicKey()
	if err != nil {
		t.Fatalf("PublicKey failed: %v", err)
	}
	defer pk1.Free()

	// Get hex
	hex, err := pk1.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	// Create public key from hex
	pk2, err := antffi.PublicKeyFromHex(hex)
	if err != nil {
		t.Fatalf("PublicKeyFromHex failed: %v", err)
	}
	defer pk2.Free()

	// Verify they produce the same hex
	hex2, err := pk2.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex != hex2 {
		t.Fatalf("Hex mismatch: %s != %s", hex, hex2)
	}
}

func TestMainSecretKey(t *testing.T) {
	// Create a random main secret key
	msk, err := antffi.NewMainSecretKeyRandom()
	if err != nil {
		t.Fatalf("NewMainSecretKeyRandom failed: %v", err)
	}
	defer msk.Free()

	// Get public key
	mpk, err := msk.PublicKey()
	if err != nil {
		t.Fatalf("PublicKey failed: %v", err)
	}
	defer mpk.Free()

	hex, err := mpk.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex == "" {
		t.Fatal("Main public key hex is empty")
	}

	t.Logf("Main public key hex: %s", hex)
}

func TestKeyDerivation(t *testing.T) {
	// Create a main secret key
	msk, err := antffi.NewMainSecretKeyRandom()
	if err != nil {
		t.Fatalf("NewMainSecretKeyRandom failed: %v", err)
	}
	defer msk.Free()

	// Create a derivation index
	idx, err := antffi.NewDerivationIndex()
	if err != nil {
		t.Fatalf("NewDerivationIndexRandom failed: %v", err)
	}
	defer idx.Free()

	// Derive a key
	dsk, err := msk.DeriveKey(idx)
	if err != nil {
		t.Fatalf("DeriveKey failed: %v", err)
	}
	defer dsk.Free()

	// Get public key from derived key
	dpk, err := dsk.PublicKey()
	if err != nil {
		t.Fatalf("PublicKey failed: %v", err)
	}
	defer dpk.Free()

	hex, err := dpk.ToHex()
	if err != nil {
		t.Fatalf("ToHex failed: %v", err)
	}

	if hex == "" {
		t.Fatal("Derived public key hex is empty")
	}

	t.Logf("Derived public key hex: %s", hex)
}

func TestMainSecretKeySign(t *testing.T) {
	// Create a main secret key
	msk, err := antffi.NewMainSecretKeyRandom()
	if err != nil {
		t.Fatalf("NewMainSecretKeyRandom failed: %v", err)
	}
	defer msk.Free()

	// Sign a message
	message := []byte("Hello, World!")
	sig, err := msk.Sign(message)
	if err != nil {
		t.Fatalf("Sign failed: %v", err)
	}
	defer sig.Free()

	// Get signature bytes
	sigBytes, err := sig.ToBytes()
	if err != nil {
		t.Fatalf("ToBytes failed: %v", err)
	}

	if len(sigBytes) == 0 {
		t.Fatal("Signature bytes are empty")
	}

	t.Logf("Signature length: %d bytes", len(sigBytes))

	// Verify with public key
	mpk, err := msk.PublicKey()
	if err != nil {
		t.Fatalf("PublicKey failed: %v", err)
	}
	defer mpk.Free()

	verified, err := mpk.Verify(sig, message)
	if err != nil {
		t.Fatalf("Verify failed: %v", err)
	}

	if !verified {
		t.Fatal("Signature verification failed")
	}
}

func TestDerivationIndexToFromBytes(t *testing.T) {
	// Create a random index
	idx1, err := antffi.NewDerivationIndex()
	if err != nil {
		t.Fatalf("NewDerivationIndexRandom failed: %v", err)
	}
	defer idx1.Free()

	// Get bytes
	bytes, err := idx1.ToBytes()
	if err != nil {
		t.Fatalf("ToBytes failed: %v", err)
	}

	if len(bytes) == 0 {
		t.Fatal("Index bytes are empty")
	}

	// Create from bytes
	idx2, err := antffi.DerivationIndexFromBytes(bytes)
	if err != nil {
		t.Fatalf("DerivationIndexFromBytes failed: %v", err)
	}
	defer idx2.Free()

	// Verify they produce the same bytes
	bytes2, err := idx2.ToBytes()
	if err != nil {
		t.Fatalf("ToBytes failed: %v", err)
	}

	if len(bytes) != len(bytes2) {
		t.Fatalf("Byte length mismatch: %d != %d", len(bytes), len(bytes2))
	}

	for i := range bytes {
		if bytes[i] != bytes2[i] {
			t.Fatalf("Byte mismatch at index %d", i)
		}
	}
}
