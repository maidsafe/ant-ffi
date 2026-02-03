package antffi

/*
#include <stdint.h>
#include <stdlib.h>

typedef struct {
    uint64_t capacity;
    uint64_t len;
    uint8_t* data;
} RustBuffer;

typedef struct {
    int32_t len;
    const uint8_t* data;
} ForeignBytes;

typedef struct {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;

extern RustBuffer ffi_ant_ffi_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus* status);
extern void ffi_ant_ffi_rustbuffer_free(RustBuffer buf, RustCallStatus* status);
*/
import "C"

import (
	"encoding/binary"
	"unsafe"
)

// toRustBuffer converts a Go byte slice to a RustBuffer with UniFFI serialization
// (4-byte big-endian length prefix).
func toRustBuffer(data []byte) C.RustBuffer {
	if len(data) == 0 {
		// For empty data, still need to send the length prefix
		buf := make([]byte, 4)
		binary.BigEndian.PutUint32(buf[0:4], 0)

		fb := C.ForeignBytes{
			len:  C.int32_t(4),
			data: (*C.uint8_t)(unsafe.Pointer(&buf[0])),
		}

		var status C.RustCallStatus
		return C.ffi_ant_ffi_rustbuffer_from_bytes(fb, &status)
	}

	// Serialize with 4-byte big-endian length prefix (UniFFI format)
	buf := make([]byte, 4+len(data))
	binary.BigEndian.PutUint32(buf[0:4], uint32(len(data)))
	copy(buf[4:], data)

	fb := C.ForeignBytes{
		len:  C.int32_t(len(buf)),
		data: (*C.uint8_t)(unsafe.Pointer(&buf[0])),
	}

	var status C.RustCallStatus
	return C.ffi_ant_ffi_rustbuffer_from_bytes(fb, &status)
}

// stringToRustBuffer converts a Go string to a RustBuffer WITHOUT UniFFI length prefix.
// UniFFI expects strings to be passed as raw UTF-8 bytes without length prefix.
func stringToRustBuffer(s string) C.RustBuffer {
	data := []byte(s)
	if len(data) == 0 {
		return C.RustBuffer{}
	}

	fb := C.ForeignBytes{
		len:  C.int32_t(len(data)),
		data: (*C.uint8_t)(unsafe.Pointer(&data[0])),
	}

	var status C.RustCallStatus
	return C.ffi_ant_ffi_rustbuffer_from_bytes(fb, &status)
}

// fromRustBuffer extracts a Go byte slice from a RustBuffer, deserializing
// the UniFFI format (skipping the 4-byte length prefix).
// If free is true, the RustBuffer is freed after extraction.
func fromRustBuffer(buf C.RustBuffer, free bool) []byte {
	if buf.len == 0 {
		if free {
			freeRustBuffer(buf)
		}
		return nil
	}

	// Copy data to Go
	data := C.GoBytes(unsafe.Pointer(buf.data), C.int(buf.len))

	if free {
		freeRustBuffer(buf)
	}

	// Deserialize - skip 4-byte length prefix if present
	if len(data) >= 4 {
		length := binary.BigEndian.Uint32(data[0:4])
		if int(length) == len(data)-4 {
			return data[4:]
		}
	}

	return data
}

// fromRustBufferRaw extracts raw bytes from a RustBuffer without UniFFI deserialization.
// If free is true, the RustBuffer is freed after extraction.
func fromRustBufferRaw(buf C.RustBuffer, free bool) []byte {
	if buf.len == 0 {
		if free {
			freeRustBuffer(buf)
		}
		return nil
	}

	data := C.GoBytes(unsafe.Pointer(buf.data), C.int(buf.len))

	if free {
		freeRustBuffer(buf)
	}

	return data
}

// stringFromRustBuffer extracts a Go string from a RustBuffer.
// UniFFI returns strings as raw UTF-8 bytes without length prefix.
// The RustBuffer is freed after extraction.
func stringFromRustBuffer(buf C.RustBuffer) string {
	if buf.len == 0 {
		freeRustBuffer(buf)
		return ""
	}

	// Copy raw bytes (no UniFFI deserialization for strings)
	data := C.GoBytes(unsafe.Pointer(buf.data), C.int(buf.len))
	freeRustBuffer(buf)

	return string(data)
}

// freeRustBuffer frees a RustBuffer.
func freeRustBuffer(buf C.RustBuffer) {
	if buf.data == nil {
		return
	}
	var status C.RustCallStatus
	C.ffi_ant_ffi_rustbuffer_free(buf, &status)
}

// lowerPaymentOption serializes a Wallet handle for PaymentOption::Wallet variant.
// UniFFI enum serialization: 4-byte variant tag + payload
func lowerPaymentOption(walletPtr unsafe.Pointer) C.RustBuffer {
	// PaymentOption::Wallet variant tag is 1 (0-indexed, so second variant)
	// Followed by the serialized Arc<Wallet> (which is just the pointer as uint64)
	buf := make([]byte, 4+8) // 4 bytes for variant tag, 8 bytes for pointer

	// Variant tag for WalletPayment (index 1)
	binary.BigEndian.PutUint32(buf[0:4], 1)

	// Pointer serialized as uint64
	binary.BigEndian.PutUint64(buf[4:12], uint64(uintptr(walletPtr)))

	fb := C.ForeignBytes{
		len:  C.int32_t(len(buf)),
		data: (*C.uint8_t)(unsafe.Pointer(&buf[0])),
	}

	var status C.RustCallStatus
	return C.ffi_ant_ffi_rustbuffer_from_bytes(fb, &status)
}

// UniFFIReader helps read UniFFI-serialized data.
type UniFFIReader struct {
	data   []byte
	offset int
}

// NewUniFFIReader creates a new UniFFIReader from raw bytes.
func NewUniFFIReader(data []byte) *UniFFIReader {
	return &UniFFIReader{data: data, offset: 0}
}

// ReadString reads a UniFFI-serialized string (4-byte length prefix + UTF-8 bytes).
func (r *UniFFIReader) ReadString() string {
	if r.offset+4 > len(r.data) {
		return ""
	}
	length := binary.BigEndian.Uint32(r.data[r.offset : r.offset+4])
	r.offset += 4

	if r.offset+int(length) > len(r.data) {
		return ""
	}
	s := string(r.data[r.offset : r.offset+int(length)])
	r.offset += int(length)
	return s
}

// ReadPointer reads a UniFFI-serialized pointer (uint64).
func (r *UniFFIReader) ReadPointer() unsafe.Pointer {
	if r.offset+8 > len(r.data) {
		return nil
	}
	ptr := binary.BigEndian.Uint64(r.data[r.offset : r.offset+8])
	r.offset += 8
	return unsafe.Pointer(uintptr(ptr))
}

// ReadBytes reads a UniFFI-serialized byte slice (4-byte length prefix + bytes).
func (r *UniFFIReader) ReadBytes() []byte {
	if r.offset+4 > len(r.data) {
		return nil
	}
	length := binary.BigEndian.Uint32(r.data[r.offset : r.offset+4])
	r.offset += 4

	if r.offset+int(length) > len(r.data) {
		return nil
	}
	data := make([]byte, length)
	copy(data, r.data[r.offset:r.offset+int(length)])
	r.offset += int(length)
	return data
}

// ReadUint64 reads a UniFFI-serialized uint64.
func (r *UniFFIReader) ReadUint64() uint64 {
	if r.offset+8 > len(r.data) {
		return 0
	}
	val := binary.BigEndian.Uint64(r.data[r.offset : r.offset+8])
	r.offset += 8
	return val
}

// ReadInt8 reads a UniFFI-serialized int8.
func (r *UniFFIReader) ReadInt8() int8 {
	if r.offset >= len(r.data) {
		return 0
	}
	val := int8(r.data[r.offset])
	r.offset++
	return val
}
