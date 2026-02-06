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

// PointerAddress
extern void* uniffi_ant_ffi_fn_constructor_pointeraddress_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_pointeraddress_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_pointeraddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_pointeraddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_pointeraddress(void* ptr, RustCallStatus* status);

// PointerTarget
extern void* uniffi_ant_ffi_fn_constructor_pointertarget_chunk(void* addr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointertarget_pointer(void* addr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointertarget_graph_entry(void* addr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointertarget_scratchpad(void* addr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_pointertarget_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_pointertarget(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_pointertarget(void* ptr, RustCallStatus* status);

// NetworkPointer
extern void* uniffi_ant_ffi_fn_constructor_networkpointer_new(void* key, uint64_t counter, void* target, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_networkpointer_address(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_networkpointer_target(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_networkpointer_counter(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_networkpointer(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_networkpointer(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// PointerAddress represents the address of a pointer.
type PointerAddress struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewPointerAddress creates a PointerAddress from a PublicKey.
func NewPointerAddress(pk *PublicKey) (*PointerAddress, error) {
	if pk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := pk.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_pointeraddress_new(cloned, &status)

	if err := checkStatus(&status, "PointerAddress.New"); err != nil {
		return nil, err
	}

	return newPointerAddress(handle), nil
}

// PointerAddressFromHex creates a PointerAddress from a hex string.
func PointerAddressFromHex(hex string) (*PointerAddress, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "PointerAddress.FromHex"); err != nil {
		return nil, err
	}

	return newPointerAddress(handle), nil
}

func newPointerAddress(handle unsafe.Pointer) *PointerAddress {
	pa := &PointerAddress{handle: handle}
	runtime.SetFinalizer(pa, (*PointerAddress).Free)
	return pa
}

func (pa *PointerAddress) Free() {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed || pa.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_pointeraddress(pa.handle, &status)
	pa.freed = true
}

func (pa *PointerAddress) Owner() (*PublicKey, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return nil, ErrDisposed
	}

	cloned := pa.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_pointeraddress_owner(cloned, &status)

	if err := checkStatus(&status, "PointerAddress.Owner"); err != nil {
		return nil, err
	}

	return newPublicKey(handle), nil
}

func (pa *PointerAddress) ToHex() (string, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return "", ErrDisposed
	}

	cloned := pa.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_pointeraddress_to_hex(cloned, &status)

	if err := checkStatus(&status, "PointerAddress.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (pa *PointerAddress) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_pointeraddress(pa.handle, &status)
}

func (pa *PointerAddress) CloneHandle() unsafe.Pointer {
	pa.mu.Lock()
	defer pa.mu.Unlock()
	if pa.freed {
		return nil
	}
	return pa.cloneHandle()
}

// PointerTarget represents the target of a pointer.
type PointerTarget struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewPointerTargetChunk creates a PointerTarget pointing to a chunk.
func NewPointerTargetChunk(addr *ChunkAddress) (*PointerTarget, error) {
	if addr == nil {
		return nil, ErrInvalidArgument
	}

	cloned := addr.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_pointertarget_chunk(cloned, &status)

	if err := checkStatus(&status, "PointerTarget.Chunk"); err != nil {
		return nil, err
	}

	return newPointerTarget(handle), nil
}

// NewPointerTargetPointer creates a PointerTarget pointing to another pointer.
func NewPointerTargetPointer(addr *PointerAddress) (*PointerTarget, error) {
	if addr == nil {
		return nil, ErrInvalidArgument
	}

	cloned := addr.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_pointertarget_pointer(cloned, &status)

	if err := checkStatus(&status, "PointerTarget.Pointer"); err != nil {
		return nil, err
	}

	return newPointerTarget(handle), nil
}

// NewPointerTargetGraphEntry creates a PointerTarget pointing to a graph entry.
func NewPointerTargetGraphEntry(addr *GraphEntryAddress) (*PointerTarget, error) {
	if addr == nil {
		return nil, ErrInvalidArgument
	}

	cloned := addr.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_pointertarget_graph_entry(cloned, &status)

	if err := checkStatus(&status, "PointerTarget.GraphEntry"); err != nil {
		return nil, err
	}

	return newPointerTarget(handle), nil
}

// NewPointerTargetScratchpad creates a PointerTarget pointing to a scratchpad.
func NewPointerTargetScratchpad(addr *ScratchpadAddress) (*PointerTarget, error) {
	if addr == nil {
		return nil, ErrInvalidArgument
	}

	cloned := addr.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_pointertarget_scratchpad(cloned, &status)

	if err := checkStatus(&status, "PointerTarget.Scratchpad"); err != nil {
		return nil, err
	}

	return newPointerTarget(handle), nil
}

func newPointerTarget(handle unsafe.Pointer) *PointerTarget {
	pt := &PointerTarget{handle: handle}
	runtime.SetFinalizer(pt, (*PointerTarget).Free)
	return pt
}

func (pt *PointerTarget) Free() {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	if pt.freed || pt.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_pointertarget(pt.handle, &status)
	pt.freed = true
}

func (pt *PointerTarget) ToHex() (string, error) {
	pt.mu.Lock()
	defer pt.mu.Unlock()

	if pt.freed {
		return "", ErrDisposed
	}

	cloned := pt.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_pointertarget_to_hex(cloned, &status)

	if err := checkStatus(&status, "PointerTarget.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (pt *PointerTarget) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_pointertarget(pt.handle, &status)
}

func (pt *PointerTarget) CloneHandle() unsafe.Pointer {
	pt.mu.Lock()
	defer pt.mu.Unlock()
	if pt.freed {
		return nil
	}
	return pt.cloneHandle()
}

// NetworkPointer represents a pointer on the network.
type NetworkPointer struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewNetworkPointer creates a new NetworkPointer.
func NewNetworkPointer(key *SecretKey, counter uint64, target *PointerTarget) (*NetworkPointer, error) {
	if key == nil || target == nil {
		return nil, ErrInvalidArgument
	}

	clonedKey := key.CloneHandle()
	clonedTarget := target.CloneHandle()
	if clonedKey == nil || clonedTarget == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_networkpointer_new(clonedKey, C.uint64_t(counter), clonedTarget, &status)

	if err := checkStatus(&status, "NetworkPointer.New"); err != nil {
		return nil, err
	}

	return newNetworkPointer(handle), nil
}

func newNetworkPointer(handle unsafe.Pointer) *NetworkPointer {
	np := &NetworkPointer{handle: handle}
	runtime.SetFinalizer(np, (*NetworkPointer).Free)
	return np
}

func (np *NetworkPointer) Free() {
	np.mu.Lock()
	defer np.mu.Unlock()

	if np.freed || np.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_networkpointer(np.handle, &status)
	np.freed = true
}

func (np *NetworkPointer) Address() (*PointerAddress, error) {
	np.mu.Lock()
	defer np.mu.Unlock()

	if np.freed {
		return nil, ErrDisposed
	}

	cloned := np.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_networkpointer_address(cloned, &status)

	if err := checkStatus(&status, "NetworkPointer.Address"); err != nil {
		return nil, err
	}

	return newPointerAddress(handle), nil
}

func (np *NetworkPointer) Target() (*PointerTarget, error) {
	np.mu.Lock()
	defer np.mu.Unlock()

	if np.freed {
		return nil, ErrDisposed
	}

	cloned := np.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_networkpointer_target(cloned, &status)

	if err := checkStatus(&status, "NetworkPointer.Target"); err != nil {
		return nil, err
	}

	return newPointerTarget(handle), nil
}

func (np *NetworkPointer) Counter() (uint64, error) {
	np.mu.Lock()
	defer np.mu.Unlock()

	if np.freed {
		return 0, ErrDisposed
	}

	cloned := np.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_networkpointer_counter(cloned, &status)

	if err := checkStatus(&status, "NetworkPointer.Counter"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (np *NetworkPointer) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_networkpointer(np.handle, &status)
}

func (np *NetworkPointer) CloneHandle() unsafe.Pointer {
	np.mu.Lock()
	defer np.mu.Unlock()
	if np.freed {
		return nil
	}
	return np.cloneHandle()
}
