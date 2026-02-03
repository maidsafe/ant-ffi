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

// Metadata
extern void* uniffi_ant_ffi_fn_constructor_metadata_new(uint64_t size, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_metadata_with_timestamps(uint64_t size, uint64_t created, uint64_t modified, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_metadata_size(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_metadata_created(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_metadata_modified(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_metadata(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_metadata(void* ptr, RustCallStatus* status);

// ArchiveAddress
extern void* uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_archiveaddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_archiveaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_archiveaddress(void* ptr, RustCallStatus* status);

// PrivateArchiveDataMap
extern void* uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_privatearchivedatamap(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_privatearchivedatamap(void* ptr, RustCallStatus* status);

// PublicArchive
extern void* uniffi_ant_ffi_fn_constructor_publicarchive_new(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_publicarchive_add_file(void* ptr, RustBuffer path, void* address, void* metadata, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_publicarchive_rename_file(void* ptr, RustBuffer oldPath, RustBuffer newPath, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_publicarchive_files(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_publicarchive_file_count(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_publicarchive_addresses(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_publicarchive(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_publicarchive(void* ptr, RustCallStatus* status);

// PrivateArchive
extern void* uniffi_ant_ffi_fn_constructor_privatearchive_new(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_privatearchive_add_file(void* ptr, RustBuffer path, void* dataMap, void* metadata, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_privatearchive_rename_file(void* ptr, RustBuffer oldPath, RustBuffer newPath, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_privatearchive_files(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_privatearchive_file_count(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_privatearchive_data_maps(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_privatearchive(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_privatearchive(void* ptr, RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// Metadata represents file metadata.
type Metadata struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewMetadata creates new metadata with the given size.
func NewMetadata(size uint64) (*Metadata, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_metadata_new(C.uint64_t(size), &status)

	if err := checkStatus(&status, "Metadata.New"); err != nil {
		return nil, err
	}

	return newMetadata(handle), nil
}

// NewMetadataWithTimestamps creates new metadata with size and timestamps.
func NewMetadataWithTimestamps(size, created, modified uint64) (*Metadata, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_metadata_with_timestamps(
		C.uint64_t(size), C.uint64_t(created), C.uint64_t(modified), &status)

	if err := checkStatus(&status, "Metadata.WithTimestamps"); err != nil {
		return nil, err
	}

	return newMetadata(handle), nil
}

func newMetadata(handle unsafe.Pointer) *Metadata {
	m := &Metadata{handle: handle}
	runtime.SetFinalizer(m, (*Metadata).Free)
	return m
}

func (m *Metadata) Free() {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.freed || m.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_metadata(m.handle, &status)
	m.freed = true
}

func (m *Metadata) Size() (uint64, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.freed {
		return 0, ErrDisposed
	}

	cloned := m.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_metadata_size(cloned, &status)

	if err := checkStatus(&status, "Metadata.Size"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (m *Metadata) Created() (uint64, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.freed {
		return 0, ErrDisposed
	}

	cloned := m.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_metadata_created(cloned, &status)

	if err := checkStatus(&status, "Metadata.Created"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (m *Metadata) Modified() (uint64, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.freed {
		return 0, ErrDisposed
	}

	cloned := m.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_metadata_modified(cloned, &status)

	if err := checkStatus(&status, "Metadata.Modified"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (m *Metadata) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_metadata(m.handle, &status)
}

func (m *Metadata) CloneHandle() unsafe.Pointer {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.freed {
		return nil
	}
	return m.cloneHandle()
}

// ArchiveAddress represents the address of an archive.
type ArchiveAddress struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// ArchiveAddressFromHex creates an ArchiveAddress from a hex string.
func ArchiveAddressFromHex(hex string) (*ArchiveAddress, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "ArchiveAddress.FromHex"); err != nil {
		return nil, err
	}

	return newArchiveAddress(handle), nil
}

func newArchiveAddress(handle unsafe.Pointer) *ArchiveAddress {
	aa := &ArchiveAddress{handle: handle}
	runtime.SetFinalizer(aa, (*ArchiveAddress).Free)
	return aa
}

func (aa *ArchiveAddress) Free() {
	aa.mu.Lock()
	defer aa.mu.Unlock()

	if aa.freed || aa.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_archiveaddress(aa.handle, &status)
	aa.freed = true
}

func (aa *ArchiveAddress) ToHex() (string, error) {
	aa.mu.Lock()
	defer aa.mu.Unlock()

	if aa.freed {
		return "", ErrDisposed
	}

	cloned := aa.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_archiveaddress_to_hex(cloned, &status)

	if err := checkStatus(&status, "ArchiveAddress.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (aa *ArchiveAddress) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_archiveaddress(aa.handle, &status)
}

func (aa *ArchiveAddress) CloneHandle() unsafe.Pointer {
	aa.mu.Lock()
	defer aa.mu.Unlock()
	if aa.freed {
		return nil
	}
	return aa.cloneHandle()
}

// PrivateArchiveDataMap represents a private archive data map.
type PrivateArchiveDataMap struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// PrivateArchiveDataMapFromHex creates a PrivateArchiveDataMap from a hex string.
func PrivateArchiveDataMapFromHex(hex string) (*PrivateArchiveDataMap, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "PrivateArchiveDataMap.FromHex"); err != nil {
		return nil, err
	}

	return newPrivateArchiveDataMap(handle), nil
}

func newPrivateArchiveDataMap(handle unsafe.Pointer) *PrivateArchiveDataMap {
	padm := &PrivateArchiveDataMap{handle: handle}
	runtime.SetFinalizer(padm, (*PrivateArchiveDataMap).Free)
	return padm
}

func (padm *PrivateArchiveDataMap) Free() {
	padm.mu.Lock()
	defer padm.mu.Unlock()

	if padm.freed || padm.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_privatearchivedatamap(padm.handle, &status)
	padm.freed = true
}

func (padm *PrivateArchiveDataMap) ToHex() (string, error) {
	padm.mu.Lock()
	defer padm.mu.Unlock()

	if padm.freed {
		return "", ErrDisposed
	}

	cloned := padm.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(cloned, &status)

	if err := checkStatus(&status, "PrivateArchiveDataMap.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (padm *PrivateArchiveDataMap) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_privatearchivedatamap(padm.handle, &status)
}

func (padm *PrivateArchiveDataMap) CloneHandle() unsafe.Pointer {
	padm.mu.Lock()
	defer padm.mu.Unlock()
	if padm.freed {
		return nil
	}
	return padm.cloneHandle()
}

// PublicArchive represents a public archive.
type PublicArchive struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewPublicArchive creates a new empty PublicArchive.
func NewPublicArchive() (*PublicArchive, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_publicarchive_new(&status)

	if err := checkStatus(&status, "PublicArchive.New"); err != nil {
		return nil, err
	}

	return newPublicArchive(handle), nil
}

func newPublicArchive(handle unsafe.Pointer) *PublicArchive {
	pa := &PublicArchive{handle: handle}
	runtime.SetFinalizer(pa, (*PublicArchive).Free)
	return pa
}

func (pa *PublicArchive) Free() {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed || pa.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_publicarchive(pa.handle, &status)
	pa.freed = true
}

// AddFile adds a file to the archive and returns a new archive with the file added.
func (pa *PublicArchive) AddFile(path string, address *DataAddress, metadata *Metadata) (*PublicArchive, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return nil, ErrDisposed
	}

	pathBuffer := stringToRustBuffer(path)
	clonedAddr := address.CloneHandle()
	clonedMeta := metadata.CloneHandle()

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_publicarchive_add_file(pa.handle, pathBuffer, clonedAddr, clonedMeta, &status)

	if err := checkStatus(&status, "PublicArchive.AddFile"); err != nil {
		return nil, err
	}

	return newPublicArchive(handle), nil
}

// RenameFile renames a file in the archive and returns a new archive with the rename applied.
func (pa *PublicArchive) RenameFile(oldPath, newPath string) (*PublicArchive, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return nil, ErrDisposed
	}

	oldPathBuffer := stringToRustBuffer(oldPath)
	newPathBuffer := stringToRustBuffer(newPath)

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_publicarchive_rename_file(pa.handle, oldPathBuffer, newPathBuffer, &status)

	if err := checkStatus(&status, "PublicArchive.RenameFile"); err != nil {
		return nil, err
	}

	return newPublicArchive(handle), nil
}

func (pa *PublicArchive) FileCount() (uint64, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return 0, ErrDisposed
	}

	cloned := pa.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_publicarchive_file_count(cloned, &status)

	if err := checkStatus(&status, "PublicArchive.FileCount"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (pa *PublicArchive) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_publicarchive(pa.handle, &status)
}

func (pa *PublicArchive) CloneHandle() unsafe.Pointer {
	pa.mu.Lock()
	defer pa.mu.Unlock()
	if pa.freed {
		return nil
	}
	return pa.cloneHandle()
}

// PrivateArchive represents a private archive.
type PrivateArchive struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewPrivateArchive creates a new empty PrivateArchive.
func NewPrivateArchive() (*PrivateArchive, error) {
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_constructor_privatearchive_new(&status)

	if err := checkStatus(&status, "PrivateArchive.New"); err != nil {
		return nil, err
	}

	return newPrivateArchive(handle), nil
}

func newPrivateArchive(handle unsafe.Pointer) *PrivateArchive {
	pa := &PrivateArchive{handle: handle}
	runtime.SetFinalizer(pa, (*PrivateArchive).Free)
	return pa
}

func (pa *PrivateArchive) Free() {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed || pa.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_privatearchive(pa.handle, &status)
	pa.freed = true
}

// AddFile adds a file to the private archive.
func (pa *PrivateArchive) AddFile(path string, dataMap *DataMapChunk, metadata *Metadata) (*PrivateArchive, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return nil, ErrDisposed
	}

	pathBuffer := stringToRustBuffer(path)
	clonedDataMap := dataMap.CloneHandle()
	clonedMeta := metadata.CloneHandle()

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_privatearchive_add_file(pa.handle, pathBuffer, clonedDataMap, clonedMeta, &status)

	if err := checkStatus(&status, "PrivateArchive.AddFile"); err != nil {
		return nil, err
	}

	return newPrivateArchive(handle), nil
}

// RenameFile renames a file in the private archive.
func (pa *PrivateArchive) RenameFile(oldPath, newPath string) (*PrivateArchive, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return nil, ErrDisposed
	}

	oldPathBuffer := stringToRustBuffer(oldPath)
	newPathBuffer := stringToRustBuffer(newPath)

	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_privatearchive_rename_file(pa.handle, oldPathBuffer, newPathBuffer, &status)

	if err := checkStatus(&status, "PrivateArchive.RenameFile"); err != nil {
		return nil, err
	}

	return newPrivateArchive(handle), nil
}

func (pa *PrivateArchive) FileCount() (uint64, error) {
	pa.mu.Lock()
	defer pa.mu.Unlock()

	if pa.freed {
		return 0, ErrDisposed
	}

	cloned := pa.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_privatearchive_file_count(cloned, &status)

	if err := checkStatus(&status, "PrivateArchive.FileCount"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (pa *PrivateArchive) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_privatearchive(pa.handle, &status)
}

func (pa *PrivateArchive) CloneHandle() unsafe.Pointer {
	pa.mu.Lock()
	defer pa.mu.Unlock()
	if pa.freed {
		return nil
	}
	return pa.cloneHandle()
}
