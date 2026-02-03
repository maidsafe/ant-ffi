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

// VaultSecretKey
extern void* uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_vaultsecretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_vaultsecretkey(void* ptr, RustCallStatus* status);

// UserData
extern void* uniffi_ant_ffi_fn_constructor_userdata_new(RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_userdata_file_archives(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_userdata_private_file_archives(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_userdata(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_userdata(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// VaultSecretKey represents a secret key for vault operations.
type VaultSecretKey struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewVaultSecretKey creates a new random VaultSecretKey.
func NewVaultSecretKey() (*VaultSecretKey, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(&status)

	if err := checkStatus(&status, "VaultSecretKey.Random"); err != nil {
		return nil, err
	}

	return newVaultSecretKey(handle), nil
}

// VaultSecretKeyFromHex creates a VaultSecretKey from a hex string.
func VaultSecretKeyFromHex(hex string) (*VaultSecretKey, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "VaultSecretKey.FromHex"); err != nil {
		return nil, err
	}

	return newVaultSecretKey(handle), nil
}

func newVaultSecretKey(handle unsafe.Pointer) *VaultSecretKey {
	vsk := &VaultSecretKey{handle: handle}
	runtime.SetFinalizer(vsk, (*VaultSecretKey).Free)
	return vsk
}

func (vsk *VaultSecretKey) Free() {
	vsk.mu.Lock()
	defer vsk.mu.Unlock()

	if vsk.freed || vsk.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_vaultsecretkey(vsk.handle, &status)
	vsk.freed = true
}

func (vsk *VaultSecretKey) ToHex() (string, error) {
	vsk.mu.Lock()
	defer vsk.mu.Unlock()

	if vsk.freed {
		return "", ErrDisposed
	}

	cloned := vsk.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(cloned, &status)

	if err := checkStatus(&status, "VaultSecretKey.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (vsk *VaultSecretKey) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_vaultsecretkey(vsk.handle, &status)
}

func (vsk *VaultSecretKey) CloneHandle() unsafe.Pointer {
	vsk.mu.Lock()
	defer vsk.mu.Unlock()
	if vsk.freed {
		return nil
	}
	return vsk.cloneHandle()
}

// UserData represents user data stored in a vault.
type UserData struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewUserData creates a new empty UserData.
func NewUserData() (*UserData, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_userdata_new(&status)

	if err := checkStatus(&status, "UserData.New"); err != nil {
		return nil, err
	}

	return newUserData(handle), nil
}

func newUserData(handle unsafe.Pointer) *UserData {
	ud := &UserData{handle: handle}
	runtime.SetFinalizer(ud, (*UserData).Free)
	return ud
}

func (ud *UserData) Free() {
	ud.mu.Lock()
	defer ud.mu.Unlock()

	if ud.freed || ud.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_userdata(ud.handle, &status)
	ud.freed = true
}

func (ud *UserData) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_userdata(ud.handle, &status)
}

func (ud *UserData) CloneHandle() unsafe.Pointer {
	ud.mu.Lock()
	defer ud.mu.Unlock()
	if ud.freed {
		return nil
	}
	return ud.cloneHandle()
}
