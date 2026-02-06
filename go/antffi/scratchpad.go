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

// ScratchpadAddress
extern void* uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_scratchpadaddress_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_scratchpadaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_scratchpadaddress(void* ptr, RustCallStatus* status);

// Scratchpad
extern void* uniffi_ant_ffi_fn_constructor_scratchpad_new(void* owner, uint64_t dataEncoding, RustBuffer data, uint64_t counter, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_scratchpad_address(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_scratchpad_data_encoding(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_scratchpad_counter(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_scratchpad_decrypt_data(void* ptr, void* secretKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_scratchpad_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_scratchpad_encrypted_data(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_scratchpad(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_scratchpad(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// ScratchpadAddress represents the address of a scratchpad.
type ScratchpadAddress struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewScratchpadAddress creates a ScratchpadAddress from a PublicKey.
func NewScratchpadAddress(pk *PublicKey) (*ScratchpadAddress, error) {
	if pk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := pk.CloneHandle()
	if cloned == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(cloned, &status)

	if err := checkStatus(&status, "ScratchpadAddress.New"); err != nil {
		return nil, err
	}

	return newScratchpadAddress(handle), nil
}

// ScratchpadAddressFromHex creates a ScratchpadAddress from a hex string.
func ScratchpadAddressFromHex(hex string) (*ScratchpadAddress, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "ScratchpadAddress.FromHex"); err != nil {
		return nil, err
	}

	return newScratchpadAddress(handle), nil
}

func newScratchpadAddress(handle unsafe.Pointer) *ScratchpadAddress {
	sa := &ScratchpadAddress{handle: handle}
	runtime.SetFinalizer(sa, (*ScratchpadAddress).Free)
	return sa
}

func (sa *ScratchpadAddress) Free() {
	sa.mu.Lock()
	defer sa.mu.Unlock()

	if sa.freed || sa.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_scratchpadaddress(sa.handle, &status)
	sa.freed = true
}

func (sa *ScratchpadAddress) Owner() (*PublicKey, error) {
	sa.mu.Lock()
	defer sa.mu.Unlock()

	if sa.freed {
		return nil, ErrDisposed
	}

	cloned := sa.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_scratchpadaddress_owner(cloned, &status)

	if err := checkStatus(&status, "ScratchpadAddress.Owner"); err != nil {
		return nil, err
	}

	return newPublicKey(handle), nil
}

func (sa *ScratchpadAddress) ToHex() (string, error) {
	sa.mu.Lock()
	defer sa.mu.Unlock()

	if sa.freed {
		return "", ErrDisposed
	}

	cloned := sa.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(cloned, &status)

	if err := checkStatus(&status, "ScratchpadAddress.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (sa *ScratchpadAddress) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_scratchpadaddress(sa.handle, &status)
}

func (sa *ScratchpadAddress) CloneHandle() unsafe.Pointer {
	sa.mu.Lock()
	defer sa.mu.Unlock()
	if sa.freed {
		return nil
	}
	return sa.cloneHandle()
}

// Scratchpad represents an encrypted mutable data store.
type Scratchpad struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewScratchpad creates a new Scratchpad.
func NewScratchpad(owner *SecretKey, dataEncoding uint64, data []byte, counter uint64) (*Scratchpad, error) {
	if owner == nil {
		return nil, ErrInvalidArgument
	}

	clonedOwner := owner.CloneHandle()
	if clonedOwner == nil {
		return nil, ErrDisposed
	}

	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_scratchpad_new(
		clonedOwner, C.uint64_t(dataEncoding), dataBuffer, C.uint64_t(counter), &status)

	if err := checkStatus(&status, "Scratchpad.New"); err != nil {
		return nil, err
	}

	return newScratchpad(handle), nil
}

func newScratchpad(handle unsafe.Pointer) *Scratchpad {
	s := &Scratchpad{handle: handle}
	runtime.SetFinalizer(s, (*Scratchpad).Free)
	return s
}

func (s *Scratchpad) Free() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed || s.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_scratchpad(s.handle, &status)
	s.freed = true
}

func (s *Scratchpad) Address() (*ScratchpadAddress, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return nil, ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_scratchpad_address(cloned, &status)

	if err := checkStatus(&status, "Scratchpad.Address"); err != nil {
		return nil, err
	}

	return newScratchpadAddress(handle), nil
}

func (s *Scratchpad) DataEncoding() (uint64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return 0, ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_scratchpad_data_encoding(cloned, &status)

	if err := checkStatus(&status, "Scratchpad.DataEncoding"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (s *Scratchpad) Counter() (uint64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return 0, ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_scratchpad_counter(cloned, &status)

	if err := checkStatus(&status, "Scratchpad.Counter"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (s *Scratchpad) DecryptData(sk *SecretKey) ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return nil, ErrDisposed
	}
	if sk == nil {
		return nil, ErrInvalidArgument
	}

	cloned := s.cloneHandle()
	clonedSk := sk.CloneHandle()
	if clonedSk == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_scratchpad_decrypt_data(cloned, clonedSk, &status)

	if err := checkStatus(&status, "Scratchpad.DecryptData"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (s *Scratchpad) Owner() (*PublicKey, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return nil, ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_scratchpad_owner(cloned, &status)

	if err := checkStatus(&status, "Scratchpad.Owner"); err != nil {
		return nil, err
	}

	return newPublicKey(handle), nil
}

func (s *Scratchpad) EncryptedData() ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.freed {
		return nil, ErrDisposed
	}

	cloned := s.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_scratchpad_encrypted_data(cloned, &status)

	if err := checkStatus(&status, "Scratchpad.EncryptedData"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (s *Scratchpad) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_scratchpad(s.handle, &status)
}

func (s *Scratchpad) CloneHandle() unsafe.Pointer {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed {
		return nil
	}
	return s.cloneHandle()
}
