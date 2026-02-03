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

extern void* uniffi_ant_ffi_fn_constructor_secretkey_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_secretkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_secretkey_to_hex(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_secretkey_public_key(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_secretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_secretkey(void* ptr, RustCallStatus* status);

extern void* uniffi_ant_ffi_fn_constructor_publickey_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_publickey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_publickey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_publickey(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// SecretKey represents a BLS secret key.
type SecretKey struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewSecretKey creates a new random SecretKey.
func NewSecretKey() (*SecretKey, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_secretkey_random(&status)

	if err := checkStatus(&status, "SecretKey.Random"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newSecretKey(handle), nil
}

// SecretKeyFromHex creates a SecretKey from a hex string.
func SecretKeyFromHex(hex string) (*SecretKey, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_secretkey_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "SecretKey.FromHex"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newSecretKey(handle), nil
}

func newSecretKey(handle unsafe.Pointer) *SecretKey {
	sk := &SecretKey{handle: handle}
	runtime.SetFinalizer(sk, (*SecretKey).Free)
	return sk
}

// Free releases the native resources associated with this SecretKey.
func (sk *SecretKey) Free() {
	sk.mu.Lock()
	defer sk.mu.Unlock()

	if sk.freed || sk.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_secretkey(sk.handle, &status)
	sk.freed = true
}

// ToHex returns the hex representation of the secret key.
func (sk *SecretKey) ToHex() (string, error) {
	sk.mu.Lock()
	defer sk.mu.Unlock()

	if sk.freed {
		return "", ErrDisposed
	}

	cloned := sk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_secretkey_to_hex(cloned, &status)

	if err := checkStatus(&status, "SecretKey.ToHex"); err != nil {
		return "", &KeyError{Wrapped: err}
	}

	return stringFromRustBuffer(result), nil
}

// PublicKey returns the public key corresponding to this secret key.
func (sk *SecretKey) PublicKey() (*PublicKey, error) {
	sk.mu.Lock()
	defer sk.mu.Unlock()

	if sk.freed {
		return nil, ErrDisposed
	}

	cloned := sk.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_secretkey_public_key(cloned, &status)

	if err := checkStatus(&status, "SecretKey.PublicKey"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newPublicKey(handle), nil
}

// cloneHandle clones the underlying handle for use in FFI calls.
func (sk *SecretKey) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_secretkey(sk.handle, &status)
}

// CloneHandle returns a cloned handle for external use (e.g., passing to other FFI functions).
func (sk *SecretKey) CloneHandle() unsafe.Pointer {
	sk.mu.Lock()
	defer sk.mu.Unlock()

	if sk.freed {
		return nil
	}
	return sk.cloneHandle()
}

// PublicKey represents a BLS public key.
type PublicKey struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// PublicKeyFromHex creates a PublicKey from a hex string.
func PublicKeyFromHex(hex string) (*PublicKey, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_publickey_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "PublicKey.FromHex"); err != nil {
		return nil, &KeyError{Wrapped: err}
	}

	return newPublicKey(handle), nil
}

func newPublicKey(handle unsafe.Pointer) *PublicKey {
	pk := &PublicKey{handle: handle}
	runtime.SetFinalizer(pk, (*PublicKey).Free)
	return pk
}

// Free releases the native resources associated with this PublicKey.
func (pk *PublicKey) Free() {
	pk.mu.Lock()
	defer pk.mu.Unlock()

	if pk.freed || pk.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_publickey(pk.handle, &status)
	pk.freed = true
}

// ToHex returns the hex representation of the public key.
func (pk *PublicKey) ToHex() (string, error) {
	pk.mu.Lock()
	defer pk.mu.Unlock()

	if pk.freed {
		return "", ErrDisposed
	}

	cloned := pk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_publickey_to_hex(cloned, &status)

	if err := checkStatus(&status, "PublicKey.ToHex"); err != nil {
		return "", &KeyError{Wrapped: err}
	}

	return stringFromRustBuffer(result), nil
}

// cloneHandle clones the underlying handle for use in FFI calls.
func (pk *PublicKey) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_publickey(pk.handle, &status)
}

// CloneHandle returns a cloned handle for external use.
func (pk *PublicKey) CloneHandle() unsafe.Pointer {
	pk.mu.Lock()
	defer pk.mu.Unlock()

	if pk.freed {
		return nil
	}
	return pk.cloneHandle()
}
