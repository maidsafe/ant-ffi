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

// Chunk
extern void* uniffi_ant_ffi_fn_constructor_chunk_new(RustBuffer value, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunk_value(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_chunk_address(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunk_network_address(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_chunk_size(void* ptr, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_chunk_is_too_big(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_chunk(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_chunk(void* ptr, RustCallStatus* status);

// ChunkAddress
extern void* uniffi_ant_ffi_fn_constructor_chunkaddress_new(RustBuffer bytes, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_chunkaddress_from_content(RustBuffer data, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunkaddress_to_hex(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunkaddress_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_chunkaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_chunkaddress(void* ptr, RustCallStatus* status);

// DataAddress
extern void* uniffi_ant_ffi_fn_constructor_dataaddress_new(RustBuffer bytes, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_dataaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_dataaddress_to_hex(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_dataaddress_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_dataaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_dataaddress(void* ptr, RustCallStatus* status);

// DataMapChunk
extern void* uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_datamapchunk_to_hex(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_datamapchunk_address(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_datamapchunk(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_datamapchunk(void* ptr, RustCallStatus* status);

// Constants
extern uint64_t uniffi_ant_ffi_fn_func_chunk_max_size(RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_func_chunk_max_raw_size(RustCallStatus* status);
*/
import "C"

import (
	"runtime"
	"sync"
	"unsafe"
)

// ChunkMaxSize returns the maximum size of a chunk in bytes.
func ChunkMaxSize() (uint64, error) {
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_func_chunk_max_size(&status)

	if err := checkStatus(&status, "ChunkMaxSize"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

// ChunkMaxRawSize returns the maximum raw size of a chunk in bytes.
func ChunkMaxRawSize() (uint64, error) {
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_func_chunk_max_raw_size(&status)

	if err := checkStatus(&status, "ChunkMaxRawSize"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

// Chunk represents a data chunk.
type Chunk struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewChunk creates a new Chunk from data.
func NewChunk(data []byte) (*Chunk, error) {
	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_chunk_new(dataBuffer, &status)

	if err := checkStatus(&status, "Chunk.New"); err != nil {
		return nil, err
	}

	return newChunk(handle), nil
}

func newChunk(handle unsafe.Pointer) *Chunk {
	c := &Chunk{handle: handle}
	runtime.SetFinalizer(c, (*Chunk).Free)
	return c
}

func (c *Chunk) Free() {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.freed || c.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_chunk(c.handle, &status)
	c.freed = true
}

func (c *Chunk) Value() ([]byte, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.freed {
		return nil, ErrDisposed
	}

	cloned := c.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_chunk_value(cloned, &status)

	if err := checkStatus(&status, "Chunk.Value"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (c *Chunk) Address() (*ChunkAddress, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.freed {
		return nil, ErrDisposed
	}

	cloned := c.cloneHandle()
	var status C.RustCallStatus
	handle := C.uniffi_ant_ffi_fn_method_chunk_address(cloned, &status)

	if err := checkStatus(&status, "Chunk.Address"); err != nil {
		return nil, err
	}

	return newChunkAddress(handle), nil
}

func (c *Chunk) NetworkAddress() (string, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.freed {
		return "", ErrDisposed
	}

	cloned := c.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_chunk_network_address(cloned, &status)

	if err := checkStatus(&status, "Chunk.NetworkAddress"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (c *Chunk) Size() (uint64, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.freed {
		return 0, ErrDisposed
	}

	cloned := c.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_chunk_size(cloned, &status)

	if err := checkStatus(&status, "Chunk.Size"); err != nil {
		return 0, err
	}

	return uint64(result), nil
}

func (c *Chunk) IsTooBig() (bool, error) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.freed {
		return false, ErrDisposed
	}

	cloned := c.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_chunk_is_too_big(cloned, &status)

	if err := checkStatus(&status, "Chunk.IsTooBig"); err != nil {
		return false, err
	}

	return result != 0, nil
}

func (c *Chunk) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_chunk(c.handle, &status)
}

func (c *Chunk) CloneHandle() unsafe.Pointer {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.freed {
		return nil
	}
	return c.cloneHandle()
}

// ChunkAddress represents the address of a chunk.
type ChunkAddress struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewChunkAddress creates a ChunkAddress from bytes.
func NewChunkAddress(data []byte) (*ChunkAddress, error) {
	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_chunkaddress_new(dataBuffer, &status)

	if err := checkStatus(&status, "ChunkAddress.New"); err != nil {
		return nil, err
	}

	return newChunkAddress(handle), nil
}

// ChunkAddressFromContent creates a ChunkAddress by hashing content.
func ChunkAddressFromContent(data []byte) (*ChunkAddress, error) {
	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_chunkaddress_from_content(dataBuffer, &status)

	if err := checkStatus(&status, "ChunkAddress.FromContent"); err != nil {
		return nil, err
	}

	return newChunkAddress(handle), nil
}

// ChunkAddressFromHex creates a ChunkAddress from a hex string.
func ChunkAddressFromHex(hex string) (*ChunkAddress, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "ChunkAddress.FromHex"); err != nil {
		return nil, err
	}

	return newChunkAddress(handle), nil
}

func newChunkAddress(handle unsafe.Pointer) *ChunkAddress {
	ca := &ChunkAddress{handle: handle}
	runtime.SetFinalizer(ca, (*ChunkAddress).Free)
	return ca
}

func (ca *ChunkAddress) Free() {
	ca.mu.Lock()
	defer ca.mu.Unlock()

	if ca.freed || ca.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_chunkaddress(ca.handle, &status)
	ca.freed = true
}

func (ca *ChunkAddress) ToHex() (string, error) {
	ca.mu.Lock()
	defer ca.mu.Unlock()

	if ca.freed {
		return "", ErrDisposed
	}

	cloned := ca.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_chunkaddress_to_hex(cloned, &status)

	if err := checkStatus(&status, "ChunkAddress.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (ca *ChunkAddress) ToBytes() ([]byte, error) {
	ca.mu.Lock()
	defer ca.mu.Unlock()

	if ca.freed {
		return nil, ErrDisposed
	}

	cloned := ca.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_chunkaddress_to_bytes(cloned, &status)

	if err := checkStatus(&status, "ChunkAddress.ToBytes"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (ca *ChunkAddress) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_chunkaddress(ca.handle, &status)
}

func (ca *ChunkAddress) CloneHandle() unsafe.Pointer {
	ca.mu.Lock()
	defer ca.mu.Unlock()
	if ca.freed {
		return nil
	}
	return ca.cloneHandle()
}

// DataAddress represents the address of data on the network.
type DataAddress struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// NewDataAddress creates a DataAddress from bytes.
func NewDataAddress(data []byte) (*DataAddress, error) {
	dataBuffer := toRustBuffer(data)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_dataaddress_new(dataBuffer, &status)

	if err := checkStatus(&status, "DataAddress.New"); err != nil {
		return nil, err
	}

	return newDataAddress(handle), nil
}

// DataAddressFromHex creates a DataAddress from a hex string.
func DataAddressFromHex(hex string) (*DataAddress, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_dataaddress_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "DataAddress.FromHex"); err != nil {
		return nil, err
	}

	return newDataAddress(handle), nil
}

func newDataAddress(handle unsafe.Pointer) *DataAddress {
	da := &DataAddress{handle: handle}
	runtime.SetFinalizer(da, (*DataAddress).Free)
	return da
}

func (da *DataAddress) Free() {
	da.mu.Lock()
	defer da.mu.Unlock()

	if da.freed || da.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_dataaddress(da.handle, &status)
	da.freed = true
}

func (da *DataAddress) ToHex() (string, error) {
	da.mu.Lock()
	defer da.mu.Unlock()

	if da.freed {
		return "", ErrDisposed
	}

	cloned := da.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_dataaddress_to_hex(cloned, &status)

	if err := checkStatus(&status, "DataAddress.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (da *DataAddress) ToBytes() ([]byte, error) {
	da.mu.Lock()
	defer da.mu.Unlock()

	if da.freed {
		return nil, ErrDisposed
	}

	cloned := da.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_dataaddress_to_bytes(cloned, &status)

	if err := checkStatus(&status, "DataAddress.ToBytes"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

func (da *DataAddress) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_dataaddress(da.handle, &status)
}

func (da *DataAddress) CloneHandle() unsafe.Pointer {
	da.mu.Lock()
	defer da.mu.Unlock()
	if da.freed {
		return nil
	}
	return da.cloneHandle()
}

// DataMapChunk represents a data map chunk for private data.
type DataMapChunk struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

// DataMapChunkFromHex creates a DataMapChunk from a hex string.
func DataMapChunkFromHex(hex string) (*DataMapChunk, error) {
	hexBuffer := stringToRustBuffer(hex)
	var status C.RustCallStatus

	handle := C.uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex(hexBuffer, &status)

	if err := checkStatus(&status, "DataMapChunk.FromHex"); err != nil {
		return nil, err
	}

	return newDataMapChunk(handle), nil
}

func newDataMapChunk(handle unsafe.Pointer) *DataMapChunk {
	dmc := &DataMapChunk{handle: handle}
	runtime.SetFinalizer(dmc, (*DataMapChunk).Free)
	return dmc
}

func (dmc *DataMapChunk) Free() {
	dmc.mu.Lock()
	defer dmc.mu.Unlock()

	if dmc.freed || dmc.handle == nil {
		return
	}

	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_datamapchunk(dmc.handle, &status)
	dmc.freed = true
}

func (dmc *DataMapChunk) ToHex() (string, error) {
	dmc.mu.Lock()
	defer dmc.mu.Unlock()

	if dmc.freed {
		return "", ErrDisposed
	}

	cloned := dmc.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_datamapchunk_to_hex(cloned, &status)

	if err := checkStatus(&status, "DataMapChunk.ToHex"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (dmc *DataMapChunk) Address() (string, error) {
	dmc.mu.Lock()
	defer dmc.mu.Unlock()

	if dmc.freed {
		return "", ErrDisposed
	}

	cloned := dmc.cloneHandle()
	var status C.RustCallStatus
	result := C.uniffi_ant_ffi_fn_method_datamapchunk_address(cloned, &status)

	if err := checkStatus(&status, "DataMapChunk.Address"); err != nil {
		return "", err
	}

	return stringFromRustBuffer(result), nil
}

func (dmc *DataMapChunk) cloneHandle() unsafe.Pointer {
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_datamapchunk(dmc.handle, &status)
}

func (dmc *DataMapChunk) CloneHandle() unsafe.Pointer {
	dmc.mu.Lock()
	defer dmc.mu.Unlock()
	if dmc.freed {
		return nil
	}
	return dmc.cloneHandle()
}
