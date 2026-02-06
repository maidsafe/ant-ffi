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
*/
import "C"

import (
	"errors"
	"fmt"
)

// Common errors
var (
	// ErrDisposed is returned when an operation is attempted on a freed handle.
	ErrDisposed = errors.New("object has been disposed")

	// ErrNilPointer is returned when an unexpected nil pointer is encountered.
	ErrNilPointer = errors.New("nil pointer")

	// ErrInvalidArgument is returned when an invalid argument is provided.
	ErrInvalidArgument = errors.New("invalid argument")

	// ErrEncryption is returned when encryption fails.
	ErrEncryption = errors.New("encryption failed")

	// ErrDecryption is returned when decryption fails.
	ErrDecryption = errors.New("decryption failed")

	// ErrKey is returned when a key operation fails.
	ErrKey = errors.New("key operation failed")

	// ErrNetwork is returned when a network operation fails.
	ErrNetwork = errors.New("network operation failed")

	// ErrClient is returned when a client operation fails.
	ErrClient = errors.New("client operation failed")

	// ErrWallet is returned when a wallet operation fails.
	ErrWallet = errors.New("wallet operation failed")

	// ErrCancelled is returned when an operation is cancelled.
	ErrCancelled = errors.New("operation cancelled")
)

// AntFFIError represents an error from the Rust FFI layer.
type AntFFIError struct {
	Code    int8
	Message string
}

// Error implements the error interface.
func (e *AntFFIError) Error() string {
	if e.Message != "" {
		return e.Message
	}
	return fmt.Sprintf("ant_ffi error (code: %d)", e.Code)
}

// checkStatus checks the RustCallStatus and returns an error if the call failed.
func checkStatus(status *C.RustCallStatus, operation string) error {
	if status.code == 0 {
		return nil
	}

	// Extract error message from error_buf if present
	var message string
	if status.error_buf.len > 0 {
		message = stringFromRustBuffer(status.error_buf)
	}

	if message == "" {
		message = fmt.Sprintf("%s failed", operation)
	}

	return &AntFFIError{
		Code:    int8(status.code),
		Message: message,
	}
}

// EncryptionError represents an encryption-specific error.
type EncryptionError struct {
	Wrapped error
}

func (e *EncryptionError) Error() string {
	if e.Wrapped != nil {
		return fmt.Sprintf("encryption error: %v", e.Wrapped)
	}
	return "encryption error"
}

func (e *EncryptionError) Unwrap() error {
	return e.Wrapped
}

// DecryptionError represents a decryption-specific error.
type DecryptionError struct {
	Wrapped error
}

func (e *DecryptionError) Error() string {
	if e.Wrapped != nil {
		return fmt.Sprintf("decryption error: %v", e.Wrapped)
	}
	return "decryption error"
}

func (e *DecryptionError) Unwrap() error {
	return e.Wrapped
}

// KeyError represents a key operation error.
type KeyError struct {
	Wrapped error
}

func (e *KeyError) Error() string {
	if e.Wrapped != nil {
		return fmt.Sprintf("key error: %v", e.Wrapped)
	}
	return "key error"
}

func (e *KeyError) Unwrap() error {
	return e.Wrapped
}

// NetworkError represents a network operation error.
type NetworkError struct {
	Wrapped error
}

func (e *NetworkError) Error() string {
	if e.Wrapped != nil {
		return fmt.Sprintf("network error: %v", e.Wrapped)
	}
	return "network error"
}

func (e *NetworkError) Unwrap() error {
	return e.Wrapped
}

// ClientError represents a client operation error.
type ClientError struct {
	Wrapped error
}

func (e *ClientError) Error() string {
	if e.Wrapped != nil {
		return fmt.Sprintf("client error: %v", e.Wrapped)
	}
	return "client error"
}

func (e *ClientError) Unwrap() error {
	return e.Wrapped
}

// WalletError represents a wallet operation error.
type WalletError struct {
	Wrapped error
}

func (e *WalletError) Error() string {
	if e.Wrapped != nil {
		return fmt.Sprintf("wallet error: %v", e.Wrapped)
	}
	return "wallet error"
}

func (e *WalletError) Unwrap() error {
	return e.Wrapped
}
