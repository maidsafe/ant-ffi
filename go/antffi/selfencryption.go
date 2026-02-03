package antffi

/*
#include <stdint.h>

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

extern RustBuffer uniffi_ant_ffi_fn_func_encrypt(RustBuffer data, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_func_decrypt(RustBuffer data, RustCallStatus* status);
extern RustBuffer ffi_ant_ffi_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus* status);
*/
import "C"

// EncryptedData represents encrypted data returned from self-encryption.
// This is an opaque blob that can be passed to Decrypt to recover the original data.
type EncryptedData struct {
	rawData []byte
}

// Size returns the size of the encrypted data in bytes.
func (e *EncryptedData) Size() int {
	return len(e.rawData)
}

// Bytes returns the raw encrypted data bytes.
// This can be stored and later used with DecryptBytes.
func (e *EncryptedData) Bytes() []byte {
	result := make([]byte, len(e.rawData))
	copy(result, e.rawData)
	return result
}

// Encrypt encrypts data using the self-encryption algorithm.
// Self-encryption is a content-based encryption scheme where the data is encrypted
// using keys derived from its own content.
func Encrypt(data []byte) (*EncryptedData, error) {
	if data == nil {
		return nil, ErrInvalidArgument
	}

	inputBuffer := toRustBuffer(data)
	var status C.RustCallStatus

	resultBuffer := C.uniffi_ant_ffi_fn_func_encrypt(inputBuffer, &status)

	if err := checkStatus(&status, "encrypt"); err != nil {
		return nil, &EncryptionError{Wrapped: err}
	}

	// Get raw bytes without UniFFI deserialization (this is the serialized EncryptedData record)
	encryptedBytes := fromRustBufferRaw(resultBuffer, true)

	return &EncryptedData{rawData: encryptedBytes}, nil
}

// EncryptString encrypts a string using the self-encryption algorithm.
func EncryptString(text string) (*EncryptedData, error) {
	return Encrypt([]byte(text))
}

// Decrypt decrypts data that was previously encrypted with Encrypt.
func Decrypt(encrypted *EncryptedData) ([]byte, error) {
	if encrypted == nil {
		return nil, ErrInvalidArgument
	}

	return DecryptBytes(encrypted.rawData)
}

// DecryptBytes decrypts raw encrypted bytes that were previously encrypted with Encrypt.
func DecryptBytes(encryptedBytes []byte) ([]byte, error) {
	if encryptedBytes == nil || len(encryptedBytes) == 0 {
		return nil, ErrInvalidArgument
	}

	// Create a RustBuffer from the raw encrypted data (no UniFFI prefix needed)
	fb := C.ForeignBytes{
		len:  C.int32_t(len(encryptedBytes)),
		data: (*C.uint8_t)(&encryptedBytes[0]),
	}

	var status C.RustCallStatus
	inputBuffer := C.ffi_ant_ffi_rustbuffer_from_bytes(fb, &status)
	if err := checkStatus(&status, "create input buffer"); err != nil {
		return nil, &DecryptionError{Wrapped: err}
	}

	resultBuffer := C.uniffi_ant_ffi_fn_func_decrypt(inputBuffer, &status)
	if err := checkStatus(&status, "decrypt"); err != nil {
		return nil, &DecryptionError{Wrapped: err}
	}

	return fromRustBuffer(resultBuffer, true), nil
}

// DecryptToString decrypts data and returns it as a UTF-8 string.
func DecryptToString(encrypted *EncryptedData) (string, error) {
	data, err := Decrypt(encrypted)
	if err != nil {
		return "", err
	}
	return string(data), nil
}
