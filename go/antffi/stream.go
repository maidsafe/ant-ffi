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

// DataStream lifecycle
extern void* uniffi_ant_ffi_fn_clone_datastream(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_datastream(void* ptr, RustCallStatus* status);

// DataStream methods (synchronous)
extern RustBuffer uniffi_ant_ffi_fn_method_datastream_collect_all(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_datastream_data_size(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_datastream_get_range(void* ptr, uint64_t start, uint64_t length, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_datastream_next_chunk(void* ptr, RustCallStatus* status);

// Client lifecycle
extern void* uniffi_ant_ffi_fn_clone_client(void* ptr, RustCallStatus* status);

// Client streaming methods (async)
extern uint64_t uniffi_ant_ffi_fn_method_client_data_stream(void* ptr, void* dataMap);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_stream_public(void* ptr, void* address);
*/
import "C"

import (
	"context"
	"runtime"
	"sync"
	"unsafe"
)

// DataStream provides memory-efficient streaming for large data.
// Use NextChunk() to iterate through chunks, or CollectAll() to get all data at once.
type DataStream struct {
	handle unsafe.Pointer
	freed  bool
	mu     sync.Mutex
}

func newDataStream(handle unsafe.Pointer) *DataStream {
	s := &DataStream{handle: handle}
	runtime.SetFinalizer(s, (*DataStream).Free)
	return s
}

// Free releases the DataStream resources.
func (s *DataStream) Free() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed || s.handle == nil {
		return
	}
	var status C.RustCallStatus
	C.uniffi_ant_ffi_fn_free_datastream(s.handle, &status)
	s.freed = true
	s.handle = nil
}

// CloneHandle returns a cloned handle for FFI calls.
func (s *DataStream) CloneHandle() unsafe.Pointer {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed || s.handle == nil {
		return nil
	}
	var status C.RustCallStatus
	return C.uniffi_ant_ffi_fn_clone_datastream(s.handle, &status)
}

// NextChunk returns the next chunk of data from the stream.
// Returns nil when the stream is exhausted.
func (s *DataStream) NextChunk() ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed || s.handle == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	cloned := C.uniffi_ant_ffi_fn_clone_datastream(s.handle, &status)
	if err := checkStatus(&status, "clone datastream"); err != nil {
		return nil, err
	}

	result := C.uniffi_ant_ffi_fn_method_datastream_next_chunk(cloned, &status)
	if err := checkStatus(&status, "next_chunk"); err != nil {
		return nil, err
	}

	// Result is an Option<Vec<u8>> serialized as RustBuffer
	// Format: 1 byte flag (0=None, 1=Some) + if Some: 4-byte length + data
	if result.len == 0 {
		return nil, nil // Empty means None/exhausted
	}

	data := fromRustBufferRaw(result, true)
	if len(data) == 0 {
		return nil, nil
	}

	// Check the Option flag
	if data[0] == 0 {
		return nil, nil // None - stream exhausted
	}

	// Skip the flag byte and parse the Vec<u8> (4-byte length prefix + data)
	if len(data) > 5 {
		return data[5:], nil // Skip: 1 byte flag + 4 bytes length
	}
	return nil, nil
}

// CollectAll collects all remaining chunks into a single buffer.
// This loads all data into memory, so use with caution for large data.
func (s *DataStream) CollectAll() ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed || s.handle == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	cloned := C.uniffi_ant_ffi_fn_clone_datastream(s.handle, &status)
	if err := checkStatus(&status, "clone datastream"); err != nil {
		return nil, err
	}

	result := C.uniffi_ant_ffi_fn_method_datastream_collect_all(cloned, &status)
	if err := checkStatus(&status, "collect_all"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

// DataSize returns the original data size in bytes.
func (s *DataStream) DataSize() (uint64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed || s.handle == nil {
		return 0, ErrDisposed
	}

	var status C.RustCallStatus
	cloned := C.uniffi_ant_ffi_fn_clone_datastream(s.handle, &status)
	if err := checkStatus(&status, "clone datastream"); err != nil {
		return 0, err
	}

	size := C.uniffi_ant_ffi_fn_method_datastream_data_size(cloned, &status)
	if err := checkStatus(&status, "data_size"); err != nil {
		return 0, err
	}

	return uint64(size), nil
}

// GetRange decrypts and returns a specific byte range from the encrypted data.
func (s *DataStream) GetRange(start, length uint64) ([]byte, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.freed || s.handle == nil {
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	cloned := C.uniffi_ant_ffi_fn_clone_datastream(s.handle, &status)
	if err := checkStatus(&status, "clone datastream"); err != nil {
		return nil, err
	}

	result := C.uniffi_ant_ffi_fn_method_datastream_get_range(
		cloned,
		C.uint64_t(start),
		C.uint64_t(length),
		&status,
	)
	if err := checkStatus(&status, "get_range"); err != nil {
		return nil, err
	}

	return fromRustBuffer(result, true), nil
}

// DataStream creates a stream for reading private data in chunks.
// Use this for large data to avoid loading everything into memory.
func (c *Client) DataStream(ctx context.Context, dataMap *DataMapChunk) (*DataStream, error) {
	c.mu.Lock()
	if c.freed || c.handle == nil {
		c.mu.Unlock()
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	cloned := C.uniffi_ant_ffi_fn_clone_client(c.handle, &status)
	if err := checkStatus(&status, "clone client"); err != nil {
		c.mu.Unlock()
		return nil, err
	}
	c.mu.Unlock()

	dataMapCloned := dataMap.CloneHandle()
	if dataMapCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_data_stream(cloned, dataMapCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newDataStream(ptr), nil
}

// DataStreamPublic creates a stream for reading public data in chunks.
// Use this for large data to avoid loading everything into memory.
func (c *Client) DataStreamPublic(ctx context.Context, address *DataAddress) (*DataStream, error) {
	c.mu.Lock()
	if c.freed || c.handle == nil {
		c.mu.Unlock()
		return nil, ErrDisposed
	}

	var status C.RustCallStatus
	cloned := C.uniffi_ant_ffi_fn_clone_client(c.handle, &status)
	if err := checkStatus(&status, "clone client"); err != nil {
		c.mu.Unlock()
		return nil, err
	}
	c.mu.Unlock()

	addressCloned := address.CloneHandle()
	if addressCloned == nil {
		return nil, ErrDisposed
	}

	futureHandle := uint64(C.uniffi_ant_ffi_fn_method_client_data_stream_public(cloned, addressCloned))
	ptr, err := pollPointerFuture(ctx, futureHandle)
	if err != nil {
		return nil, err
	}

	return newDataStream(ptr), nil
}
