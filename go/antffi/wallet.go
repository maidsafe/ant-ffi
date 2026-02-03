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

// Wallet functions
extern void* uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(void* network, RustBuffer private_key, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_wallet_address(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_wallet_balance_of_tokens(void* ptr);
extern void uniffi_ant_ffi_fn_free_wallet(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_wallet(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"context"
	"runtime"
	"sync"
	"unsafe"
)

// Wallet represents an EVM wallet for managing tokens and payments on the Autonomi network.
type Wallet struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewWalletFromPrivateKey creates a wallet from a private key.
// The private key should be a hex string with or without 0x prefix.
func NewWalletFromPrivateKey(network *Network, privateKey string) (*Wallet, error) {
	if network == nil {
		return nil, ErrNilPointer
	}

	network.mu.Lock()
	if network.freed {
		network.mu.Unlock()
		return nil, ErrDisposed
	}
	networkHandle := network.cloneHandle()
	network.mu.Unlock()

	privateKeyBuffer := stringToRustBuffer(privateKey)
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(networkHandle, privateKeyBuffer, &status)

	if err := checkStatus(&status, "Wallet.FromPrivateKey"); err != nil {
		return nil, err
	}

	return newWallet(handle), nil
}

func newWallet(handle unsafe.Pointer) *Wallet {
	w := &Wallet{handle: handle}
	runtime.SetFinalizer(w, (*Wallet).Free)
	return w
}

// Free releases the wallet resources.
func (w *Wallet) Free() {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.freed || w.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_wallet(w.handle, &status)
	w.freed = true
}

// Address returns the wallet's EVM address as a hex string.
func (w *Wallet) Address() (string, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.freed {
		return "", ErrDisposed
	}

	cloned := w.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_wallet_address(cloned, &status)

	if err := checkStatus(&status, "Wallet.Address"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

// BalanceOfTokens returns the balance of tokens in the wallet.
func (w *Wallet) BalanceOfTokens(ctx context.Context) (string, error) {
	w.mu.Lock()
	if w.freed {
		w.mu.Unlock()
		return "", ErrDisposed
	}
	cloned := w.cloneHandle()
	w.mu.Unlock()

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_wallet_balance_of_tokens(cloned))
	buf, err := pollRustBufferFuture(ctx, futureHandle)
	if err != nil {
		return "", err
	}

	return stringFromRustBuffer(buf), nil
}

func (w *Wallet) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_wallet(w.handle, &status)
}

// CloneHandle returns a cloned handle for FFI operations.
func (w *Wallet) CloneHandle() unsafe.Pointer {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.freed {
		return nil
	}
	return w.cloneHandle()
}
