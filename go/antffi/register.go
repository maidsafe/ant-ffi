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

// RegisterAddress
extern void* uniffi_ant_ffi_fn_constructor_registeraddress_new(void* owner, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_registeraddress_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_registeraddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_registeraddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_registeraddress(void* ptr, RustCallStatus* status);

// Register Functions
extern void* uniffi_ant_ffi_fn_func_register_key_from_name(void* owner, RustBuffer name, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_func_register_value_from_bytes(RustBuffer bytes, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// RegisterAddress represents the address of a register.
type RegisterAddress struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewRegisterAddress creates a RegisterAddress from a PublicKey.
func NewRegisterAddress(owner *PublicKey) (*RegisterAddress, error) {
	if owner == nil {
		return nil, ErrInvalidArgument
	}

	cloned := owner.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_registeraddress_new(cloned, &status)

	if err := checkStatus(&status, "RegisterAddress.New"); err != nil {
		return nil, err
	}

	return newRegisterAddress(handle), nil
}

// RegisterAddressFromHex creates a RegisterAddress from a hex string.
func RegisterAddressFromHex(hex string) (*RegisterAddress, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "RegisterAddress.FromHex"); err != nil {
		return nil, err
	}

	return newRegisterAddress(handle), nil
}

func newRegisterAddress(handle unsafe.Pointer) *RegisterAddress {
	ra := &RegisterAddress{handle: handle}
	runtime.SetFinalizer(ra, (*RegisterAddress).Free)
	return ra
}

func (ra *RegisterAddress) Free() {
	ra.mu.Lock()
	defer ra.mu.Unlock()

	if ra.freed || ra.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_registeraddress(ra.handle, &status)
	ra.freed = true
}

func (ra *RegisterAddress) Owner() (*PublicKey, error) {
	ra.mu.Lock()
	defer ra.mu.Unlock()

	if ra.freed {
		return nil, ErrDisposed
	}

	cloned := ra.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_registeraddress_owner(cloned, &status)

	if err := checkStatus(&status, "RegisterAddress.Owner"); err != nil {
		return nil, err
	}

	return newPublicKey(handle), nil
}

func (ra *RegisterAddress) ToHex() (string, error) {
	ra.mu.Lock()
	defer ra.mu.Unlock()

	if ra.freed {
		return "", ErrDisposed
	}

	cloned := ra.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_registeraddress_to_hex(cloned, &status)

	if err := checkStatus(&status, "RegisterAddress.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (ra *RegisterAddress) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_registeraddress(ra.handle, &status)
}

func (ra *RegisterAddress) CloneHandle() unsafe.Pointer {
	ra.mu.Lock()
	defer ra.mu.Unlock()
	if ra.freed {
		return nil
	}
	return ra.cloneHandle()
}

// RegisterKeyFromName creates a register key (SecretKey) from an owner and a name.
func RegisterKeyFromName(owner *SecretKey, name string) (*SecretKey, error) {
	if owner == nil {
		return nil, ErrInvalidArgument
	}

	clonedOwner := owner.CloneHandle()
	if clonedOwner == nil {
		return nil, ErrDisposed
	}

	nameBuffer := stringToRustBuffer(name)
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_func_register_key_from_name(clonedOwner, nameBuffer, &status)

	if err := checkStatus(&status, "RegisterKeyFromName"); err != nil {
		return nil, err
	}

	return newSecretKey(handle), nil
}

// RegisterValueFromBytes converts bytes to a register value (ensuring proper format).
func RegisterValueFromBytes(data []byte) ([]byte, error) {
	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_func_register_value_from_bytes(dataBuffer, &status)

	if err := checkStatus(&status, "RegisterValueFromBytes"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}
