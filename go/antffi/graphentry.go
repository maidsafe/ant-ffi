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

// GraphEntryAddress
extern void* uniffi_ant_ffi_fn_constructor_graphentryaddress_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_graphentryaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_graphentryaddress(void* ptr, RustCallStatus* status);

// GraphEntry
extern void* uniffi_ant_ffi_fn_constructor_graphentry_new(void* owner, RustBuffer parents, RustBuffer content, RustBuffer descendants, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_graphentry_address(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentry_content(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentry_parents(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentry_descendants(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_graphentry(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_graphentry(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// GraphEntryAddress represents the address of a graph entry.
type GraphEntryAddress struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewGraphEntryAddress creates a GraphEntryAddress from a PublicKey.
func NewGraphEntryAddress(pk *PublicKey) (*GraphEntryAddress, error) {
	if pk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := pk.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_graphentryaddress_new(cloned, &status)

	if err := checkStatus(&status, "GraphEntryAddress.New"); err != nil {
		return nil, err
	}

	return newGraphEntryAddress(handle), nil
}

// GraphEntryAddressFromHex creates a GraphEntryAddress from a hex string.
func GraphEntryAddressFromHex(hex string) (*GraphEntryAddress, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "GraphEntryAddress.FromHex"); err != nil {
		return nil, err
	}

	return newGraphEntryAddress(handle), nil
}

func newGraphEntryAddress(handle unsafe.Pointer) *GraphEntryAddress {
	gea := &GraphEntryAddress{handle: handle}
	runtime.SetFinalizer(gea, (*GraphEntryAddress).Free)
	return gea
}

func (gea *GraphEntryAddress) Free() {
	gea.mu.Lock()
	defer gea.mu.Unlock()

	if gea.freed || gea.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_graphentryaddress(gea.handle, &status)
	gea.freed = true
}

func (gea *GraphEntryAddress) ToHex() (string, error) {
	gea.mu.Lock()
	defer gea.mu.Unlock()

	if gea.freed {
		return "", ErrDisposed
	}

	cloned := gea.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(cloned, &status)

	if err := checkStatus(&status, "GraphEntryAddress.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (gea *GraphEntryAddress) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_graphentryaddress(gea.handle, &status)
}

func (gea *GraphEntryAddress) CloneHandle() unsafe.Pointer {
	gea.mu.Lock()
	defer gea.mu.Unlock()
	if gea.freed {
		return nil
	}
	return gea.cloneHandle()
}

// GraphEntry represents a graph entry.
type GraphEntry struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewGraphEntry creates a new GraphEntry.
func NewGraphEntry(owner *SecretKey, parents, content, descendants []byte) (*GraphEntry, error) {
	if owner == nil {
		return nil, ErrInvalidArgument
	}

	clonedOwner := owner.CloneHandle()
	if clonedOwner == nil {
		return nil, ErrDisposed
	}

	parentsBuffer := toRustBuffer(parents)
	contentBuffer := toRustBuffer(content)
	descendantsBuffer := toRustBuffer(descendants)

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_graphentry_new(
		clonedOwner, parentsBuffer, contentBuffer, descendantsBuffer, &status)

	if err := checkStatus(&status, "GraphEntry.New"); err != nil {
		return nil, err
	}

	return newGraphEntry(handle), nil
}

func newGraphEntry(handle unsafe.Pointer) *GraphEntry {
	ge := &GraphEntry{handle: handle}
	runtime.SetFinalizer(ge, (*GraphEntry).Free)
	return ge
}

func (ge *GraphEntry) Free() {
	ge.mu.Lock()
	defer ge.mu.Unlock()

	if ge.freed || ge.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_graphentry(ge.handle, &status)
	ge.freed = true
}

func (ge *GraphEntry) Address() (*GraphEntryAddress, error) {
	ge.mu.Lock()
	defer ge.mu.Unlock()

	if ge.freed {
		return nil, ErrDisposed
	}

	cloned := ge.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_graphentry_address(cloned, &status)

	if err := checkStatus(&status, "GraphEntry.Address"); err != nil {
		return nil, err
	}

	return newGraphEntryAddress(handle), nil
}

func (ge *GraphEntry) Content() ([]byte, error) {
	ge.mu.Lock()
	defer ge.mu.Unlock()

	if ge.freed {
		return nil, ErrDisposed
	}

	cloned := ge.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_graphentry_content(cloned, &status)

	if err := checkStatus(&status, "GraphEntry.Content"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (ge *GraphEntry) Parents() ([]byte, error) {
	ge.mu.Lock()
	defer ge.mu.Unlock()

	if ge.freed {
		return nil, ErrDisposed
	}

	cloned := ge.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_graphentry_parents(cloned, &status)

	if err := checkStatus(&status, "GraphEntry.Parents"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (ge *GraphEntry) Descendants() ([]byte, error) {
	ge.mu.Lock()
	defer ge.mu.Unlock()

	if ge.freed {
		return nil, ErrDisposed
	}

	cloned := ge.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_graphentry_descendants(cloned, &status)

	if err := checkStatus(&status, "GraphEntry.Descendants"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (ge *GraphEntry) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_graphentry(ge.handle, &status)
}

func (ge *GraphEntry) CloneHandle() unsafe.Pointer {
	ge.mu.Lock()
	defer ge.mu.Unlock()
	if ge.freed {
		return nil
	}
	return ge.cloneHandle()
}
