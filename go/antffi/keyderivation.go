package antffi

/*
#include <stdint.h>

typedef struct {
    uint64_t capacity;
    uint64_t len;
    uint8_t* data;
} RustBuffer;

typedef struct {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;

// DerivationIndex
extern void* uniffi_ant_ffi_fn_constructor_derivationindex_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(RustBuffer bytes, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_derivationindex_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_derivationindex(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_derivationindex(void* ptr, RustCallStatus* status);

// Signature
extern void* uniffi_ant_ffi_fn_constructor_signature_from_bytes(RustBuffer bytes, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_signature_to_bytes(void* ptr, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_signature_parity(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_signature_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_signature(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_signature(void* ptr, RustCallStatus* status);

// MainSecretKey
extern void* uniffi_ant_ffi_fn_constructor_mainsecretkey_new(void* secretKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_mainsecretkey_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_public_key(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_sign(void* ptr, RustBuffer msg, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(void* ptr, void* index, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_mainsecretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_mainsecretkey(void* ptr, RustCallStatus* status);

// MainPubkey
extern void* uniffi_ant_ffi_fn_constructor_mainpubkey_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_mainpubkey_verify(void* ptr, void* signature, RustBuffer msg, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainpubkey_derive_key(void* ptr, void* index, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_mainpubkey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_mainpubkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_mainpubkey(void* ptr, RustCallStatus* status);

// DerivedSecretKey
extern void* uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(void* secretKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_derivedsecretkey_sign(void* ptr, RustBuffer msg, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_derivedsecretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_derivedsecretkey(void* ptr, RustCallStatus* status);

// DerivedPubkey
extern void* uniffi_ant_ffi_fn_constructor_derivedpubkey_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_derivedpubkey_verify(void* ptr, void* signature, RustBuffer msg, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_derivedpubkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_derivedpubkey(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// DerivationIndex represents an index used for key derivation.
type DerivationIndex struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewDerivationIndex creates a new random DerivationIndex.
func NewDerivationIndex() (*DerivationIndex, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_derivationindex_random(&status)

	if err := checkStatus(&status, "DerivationIndex.Random"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivationIndex(handle), nil
}

// DerivationIndexFromBytes creates a DerivationIndex from bytes.
func DerivationIndexFromBytes(data []byte) (*DerivationIndex, error) {
	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(dataBuffer, &status)

	if err := checkStatus(&status, "DerivationIndex.FromBytes"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivationIndex(handle), nil
}

func newDerivationIndex(handle unsafe.Pointer) *DerivationIndex {
	di := &DerivationIndex{handle: handle}
	runtime.SetFinalizer(di, (*DerivationIndex).Free)
	return di
}

func (di *DerivationIndex) Free() {
	di.mu.Lock()
	defer di.mu.Unlock()

	if di.freed || di.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_derivationindex(di.handle, &status)
	di.freed = true
}

func (di *DerivationIndex) ToBytes() ([]byte, error) {
	di.mu.Lock()
	defer di.mu.Unlock()

	if di.freed {
		return nil, ErrDisposed
	}

	cloned := di.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_derivationindex_to_bytes(cloned, &status)

	if err := checkStatus(&status, "DerivationIndex.ToBytes"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return fromRustBuffer(result, true), nil
}

func (di *DerivationIndex) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_derivationindex(di.handle, &status)
}

func (di *DerivationIndex) CloneHandle() unsafe.Pointer {
	di.mu.Lock()
	defer di.mu.Unlock()
	if di.freed {
		return nil
	}
	return di.cloneHandle()
}

// Signature represents a BLS signature.
type Signature struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// SignatureFromBytes creates a Signature from bytes.
func SignatureFromBytes(data []byte) (*Signature, error) {
	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_signature_from_bytes(dataBuffer, &status)

	if err := checkStatus(&status, "Signature.FromBytes"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newSignature(handle), nil
}

func newSignature(handle unsafe.Pointer) *Signature {
	s := &Signature{handle: handle}
	runtime.SetFinalizer(s, (*Signature).Free)
	return s
}

func (s *Signature) Free() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed || s.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_signature(s.handle, &status)
	s.freed = true
}

func (s *Signature) ToBytes() ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return nil, ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_signature_to_bytes(cloned, &status)

	if err := checkStatus(&status, "Signature.ToBytes"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return fromRustBuffer(result, true), nil
}

func (s *Signature) ToHex() (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return "", ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_signature_to_hex(cloned, &status)

	if err := checkStatus(&status, "Signature.ToHex"); err != nil {
		return "", &KeyError{Wrapped: err}
	}

	return stringFromRustBuffer(result), nil
}

func (s *Signature) Parity() (int8, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return 0, ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_signature_parity(cloned, &status)

	if err := checkStatus(&status, "Signature.Parity"); err != nil {
		return 0, &KeyError{Wrapped: err}
	}

	return int8(result), nil
}

func (s *Signature) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_signature(s.handle, &status)
}

func (s *Signature) CloneHandle() unsafe.Pointer {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed {
		return nil
	}
	return s.cloneHandle()
}

// MainSecretKey represents a main secret key for key derivation.
type MainSecretKey struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewMainSecretKey creates a MainSecretKey from a SecretKey.
func NewMainSecretKey(sk *SecretKey) (*MainSecretKey, error) {
	if sk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := sk.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_mainsecretkey_new(cloned, &status)

	if err := checkStatus(&status, "MainSecretKey.New"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newMainSecretKey(handle), nil
}

// NewMainSecretKeyRandom creates a new random MainSecretKey.
func NewMainSecretKeyRandom() (*MainSecretKey, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_mainsecretkey_random(&status)

	if err := checkStatus(&status, "MainSecretKey.Random"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newMainSecretKey(handle), nil
}

func newMainSecretKey(handle unsafe.Pointer) *MainSecretKey {
	msk := &MainSecretKey{handle: handle}
	runtime.SetFinalizer(msk, (*MainSecretKey).Free)
	return msk
}

func (msk *MainSecretKey) Free() {
	msk.mu.Lock()
	defer msk.mu.Unlock()

	if msk.freed || msk.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_mainsecretkey(msk.handle, &status)
	msk.freed = true
}

func (msk *MainSecretKey) PublicKey() (*MainPubkey, error) {
	msk.mu.Lock()
	defer msk.mu.Unlock()

	if msk.freed {
		return nil, ErrDisposed
	}

	cloned := msk.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_mainsecretkey_public_key(cloned, &status)

	if err := checkStatus(&status, "MainSecretKey.PublicKey"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newMainPubkey(handle), nil
}

func (msk *MainSecretKey) Sign(msg []byte) (*Signature, error) {
	msk.mu.Lock()
	defer msk.mu.Unlock()

	if msk.freed {
		return nil, ErrDisposed
	}

	cloned := msk.cloneHandle()
	msgBuffer := toRustBuffer(msg)
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_mainsecretkey_sign(cloned, msgBuffer, &status)

	if err := checkStatus(&status, "MainSecretKey.Sign"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newSignature(handle), nil
}

func (msk *MainSecretKey) DeriveKey(index *DerivationIndex) (*DerivedSecretKey, error) {
	msk.mu.Lock()
	defer msk.mu.Unlock()

	if msk.freed {
		return nil, ErrDisposed
	}
	if index == nil {
		return nil, ErrInvalidArgument
	}

	clonedMsk := msk.cloneHandle()
	clonedIndex := index.CloneHandle()
	if clonedIndex == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(clonedMsk, clonedIndex, &status)

	if err := checkStatus(&status, "MainSecretKey.DeriveKey"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivedSecretKey(handle), nil
}

func (msk *MainSecretKey) RandomDerivedKey() (*DerivedSecretKey, error) {
	msk.mu.Lock()
	defer msk.mu.Unlock()

	if msk.freed {
		return nil, ErrDisposed
	}

	cloned := msk.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(cloned, &status)

	if err := checkStatus(&status, "MainSecretKey.RandomDerivedKey"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivedSecretKey(handle), nil
}

func (msk *MainSecretKey) ToBytes() ([]byte, error) {
	msk.mu.Lock()
	defer msk.mu.Unlock()

	if msk.freed {
		return nil, ErrDisposed
	}

	cloned := msk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(cloned, &status)

	if err := checkStatus(&status, "MainSecretKey.ToBytes"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return fromRustBuffer(result, true), nil
}

func (msk *MainSecretKey) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_mainsecretkey(msk.handle, &status)
}

// MainPubkey represents a main public key for key derivation.
type MainPubkey struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewMainPubkey creates a MainPubkey from a PublicKey.
func NewMainPubkey(pk *PublicKey) (*MainPubkey, error) {
	if pk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := pk.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_mainpubkey_new(cloned, &status)

	if err := checkStatus(&status, "MainPubkey.New"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newMainPubkey(handle), nil
}

// MainPubkeyFromHex creates a MainPubkey from a hex string.
func MainPubkeyFromHex(hex string) (*MainPubkey, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "MainPubkey.FromHex"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newMainPubkey(handle), nil
}

func newMainPubkey(handle unsafe.Pointer) *MainPubkey {
	mpk := &MainPubkey{handle: handle}
	runtime.SetFinalizer(mpk, (*MainPubkey).Free)
	return mpk
}

func (mpk *MainPubkey) Free() {
	mpk.mu.Lock()
	defer mpk.mu.Unlock()

	if mpk.freed || mpk.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_mainpubkey(mpk.handle, &status)
	mpk.freed = true
}

func (mpk *MainPubkey) Verify(sig *Signature, msg []byte) (bool, error) {
	mpk.mu.Lock()
	defer mpk.mu.Unlock()

	if mpk.freed {
		return false, ErrDisposed
	}
	if sig == nil {
		return false, ErrInvalidArgument
	}

	clonedMpk := mpk.cloneHandle()
	clonedSig := sig.CloneHandle()
	if clonedSig == nil {
		return false, ErrDisposed
	}
	msgBuffer := toRustBuffer(msg)

	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_mainpubkey_verify(clonedMpk, clonedSig, msgBuffer, &status)

	if err := checkStatus(&status, "MainPubkey.Verify"); err != nil {
		return false, &KeyError{Wrapped: err}
	}

	return result != 0, nil
}

func (mpk *MainPubkey) DeriveKey(index *DerivationIndex) (*DerivedPubkey, error) {
	mpk.mu.Lock()
	defer mpk.mu.Unlock()

	if mpk.freed {
		return nil, ErrDisposed
	}
	if index == nil {
		return nil, ErrInvalidArgument
	}

	clonedMpk := mpk.cloneHandle()
	clonedIndex := index.CloneHandle()
	if clonedIndex == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_mainpubkey_derive_key(clonedMpk, clonedIndex, &status)

	if err := checkStatus(&status, "MainPubkey.DeriveKey"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivedPubkey(handle), nil
}

func (mpk *MainPubkey) ToBytes() ([]byte, error) {
	mpk.mu.Lock()
	defer mpk.mu.Unlock()

	if mpk.freed {
		return nil, ErrDisposed
	}

	cloned := mpk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(cloned, &status)

	if err := checkStatus(&status, "MainPubkey.ToBytes"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return fromRustBuffer(result, true), nil
}

func (mpk *MainPubkey) ToHex() (string, error) {
	mpk.mu.Lock()
	defer mpk.mu.Unlock()

	if mpk.freed {
		return "", ErrDisposed
	}

	cloned := mpk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_mainpubkey_to_hex(cloned, &status)

	if err := checkStatus(&status, "MainPubkey.ToHex"); err != nil {
		return "", &KeyError{Wrapped: err}
	}

	return stringFromRustBuffer(result), nil
}

func (mpk *MainPubkey) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_mainpubkey(mpk.handle, &status)
}

// DerivedSecretKey represents a derived secret key.
type DerivedSecretKey struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewDerivedSecretKey creates a DerivedSecretKey from a SecretKey.
func NewDerivedSecretKey(sk *SecretKey) (*DerivedSecretKey, error) {
	if sk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := sk.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(cloned, &status)

	if err := checkStatus(&status, "DerivedSecretKey.New"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivedSecretKey(handle), nil
}

func newDerivedSecretKey(handle unsafe.Pointer) *DerivedSecretKey {
	dsk := &DerivedSecretKey{handle: handle}
	runtime.SetFinalizer(dsk, (*DerivedSecretKey).Free)
	return dsk
}

func (dsk *DerivedSecretKey) Free() {
	dsk.mu.Lock()
	defer dsk.mu.Unlock()

	if dsk.freed || dsk.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_derivedsecretkey(dsk.handle, &status)
	dsk.freed = true
}

func (dsk *DerivedSecretKey) PublicKey() (*DerivedPubkey, error) {
	dsk.mu.Lock()
	defer dsk.mu.Unlock()

	if dsk.freed {
		return nil, ErrDisposed
	}

	cloned := dsk.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(cloned, &status)

	if err := checkStatus(&status, "DerivedSecretKey.PublicKey"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivedPubkey(handle), nil
}

func (dsk *DerivedSecretKey) Sign(msg []byte) (*Signature, error) {
	dsk.mu.Lock()
	defer dsk.mu.Unlock()

	if dsk.freed {
		return nil, ErrDisposed
	}

	cloned := dsk.cloneHandle()
	msgBuffer := toRustBuffer(msg)
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_derivedsecretkey_sign(cloned, msgBuffer, &status)

	if err := checkStatus(&status, "DerivedSecretKey.Sign"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newSignature(handle), nil
}

func (dsk *DerivedSecretKey) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_derivedsecretkey(dsk.handle, &status)
}

// CloneHandle returns a cloned handle for FFI operations.
func (dsk *DerivedSecretKey) CloneHandle() unsafe.Pointer {
	dsk.mu.Lock()
	defer dsk.mu.Unlock()
	if dsk.freed {
		return nil
	}
	return dsk.cloneHandle()
}

// DerivedPubkey represents a derived public key.
type DerivedPubkey struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewDerivedPubkey creates a DerivedPubkey from a PublicKey.
func NewDerivedPubkey(pk *PublicKey) (*DerivedPubkey, error) {
	if pk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := pk.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_derivedpubkey_new(cloned, &status)

	if err := checkStatus(&status, "DerivedPubkey.New"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivedPubkey(handle), nil
}

// DerivedPubkeyFromHex creates a DerivedPubkey from a hex string.
func DerivedPubkeyFromHex(hex string) (*DerivedPubkey, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "DerivedPubkey.FromHex"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newDerivedPubkey(handle), nil
}

func newDerivedPubkey(handle unsafe.Pointer) *DerivedPubkey {
	dpk := &DerivedPubkey{handle: handle}
	runtime.SetFinalizer(dpk, (*DerivedPubkey).Free)
	return dpk
}

func (dpk *DerivedPubkey) Free() {
	dpk.mu.Lock()
	defer dpk.mu.Unlock()

	if dpk.freed || dpk.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_derivedpubkey(dpk.handle, &status)
	dpk.freed = true
}

func (dpk *DerivedPubkey) Verify(sig *Signature, msg []byte) (bool, error) {
	dpk.mu.Lock()
	defer dpk.mu.Unlock()

	if dpk.freed {
		return false, ErrDisposed
	}
	if sig == nil {
		return false, ErrInvalidArgument
	}

	clonedDpk := dpk.cloneHandle()
	clonedSig := sig.CloneHandle()
	if clonedSig == nil {
		return false, ErrDisposed
	}
	msgBuffer := toRustBuffer(msg)

	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_derivedpubkey_verify(clonedDpk, clonedSig, msgBuffer, &status)

	if err := checkStatus(&status, "DerivedPubkey.Verify"); err != nil {
		return false, &KeyError{Wrapped: err}
	}

	return result != 0, nil
}

func (dpk *DerivedPubkey) ToBytes() ([]byte, error) {
	dpk.mu.Lock()
	defer dpk.mu.Unlock()

	if dpk.freed {
		return nil, ErrDisposed
	}

	cloned := dpk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(cloned, &status)

	if err := checkStatus(&status, "DerivedPubkey.ToBytes"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return fromRustBuffer(result, true), nil
}

func (dpk *DerivedPubkey) ToHex() (string, error) {
	dpk.mu.Lock()
	defer dpk.mu.Unlock()

	if dpk.freed {
		return "", ErrDisposed
	}

	cloned := dpk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(cloned, &status)

	if err := checkStatus(&status, "DerivedPubkey.ToHex"); err != nil {
		return "", &KeyError{Wrapped: err}
	}

	return stringFromRustBuffer(result), nil
}

func (dpk *DerivedPubkey) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_derivedpubkey(dpk.handle, &status)
}
