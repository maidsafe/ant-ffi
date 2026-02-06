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

// Network functions
extern void* uniffi_ant_ffi_fn_constructor_network_new(int8_t local, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_network_custom(RustBuffer rpc_url, RustBuffer payment_token_address, RustBuffer data_payments_address, RustBuffer royalties_pk_hex, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_network(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_network(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// Network represents the network configuration for connecting to the Autonomi network.
type Network struct {
	handle  unsafe.Pointer
	freed   bool
	mu      sync.Mutex
	IsLocal bool
}

// NewNetwork creates a new network configuration.
// If local is true, connects to local testnet. If false, connects to production network.
func NewNetwork(local bool) (*Network, error) {
	var localFlag C.int8_t
	if local {
		localFlag = 1
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_network_new(localFlag, &status)

	if err := checkStatus(&status, "Network.New"); err != nil {
		return nil, err
	}

	return newNetwork(handle, local), nil
}

// NewNetworkCustom creates a custom network configuration with specific RPC URL and contract addresses.
// royaltiesPkHex is optional - pass nil if not needed.
func NewNetworkCustom(rpcURL, paymentTokenAddress, dataPaymentsAddress string, royaltiesPkHex *string) (*Network, error) {
	rpcURLBuffer := stringToRustBuffer(rpcURL)
	paymentTokenBuffer := stringToRustBuffer(paymentTokenAddress)
	dataPaymentsBuffer := stringToRustBuffer(dataPaymentsAddress)
	royaltiesBuffer := optionStringToRustBuffer(royaltiesPkHex)

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_network_custom(rpcURLBuffer, paymentTokenBuffer, dataPaymentsBuffer, royaltiesBuffer, &status)

	if err := checkStatus(&status, "Network.Custom"); err != nil {
		return nil, err
	}

	return newNetwork(handle, true), nil
}

func newNetwork(handle unsafe.Pointer, isLocal bool) *Network {
	n := &Network{handle: handle, IsLocal: isLocal}
	runtime.SetFinalizer(n, (*Network).Free)
	return n
}

// Free releases the network resources.
func (n *Network) Free() {
	n.mu.Lock()
	defer n.mu.Unlock()

	if n.freed || n.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_network(n.handle, &status)
	n.freed = true
}

func (n *Network) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_network(n.handle, &status)
}

// CloneHandle returns a cloned handle for FFI operations.
func (n *Network) CloneHandle() unsafe.Pointer {
	n.mu.Lock()
	defer n.mu.Unlock()
	if n.freed {
		return nil
	}
	return n.cloneHandle()
}
