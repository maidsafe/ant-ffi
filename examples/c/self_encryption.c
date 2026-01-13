/**
 * Self-encryption example using the Autonomi C API
 *
 * This example demonstrates encrypting and decrypting data using
 * the self-encryption algorithm via the UniFFI C bindings.
 *
 * Build: see Makefile or run from repo root:
 *   make -C examples/c
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ant_ffiFFI.h"

int main() {
    RustCallStatus status = {0};
    const char *msg = "Hello from C! This is a test of self-encryption.";
    size_t len = strlen(msg);

    // Serialize: 4-byte big-endian length + data (UniFFI format)
    uint8_t *buf = malloc(4 + len);
    buf[0] = buf[1] = buf[2] = 0; buf[3] = (uint8_t)len;
    memcpy(buf + 4, msg, len);
    ForeignBytes fb = { .len = 4 + len, .data = buf };
    RustBuffer input = ffi_ant_ffi_rustbuffer_from_bytes(fb, &status);
    free(buf);

    // Encrypt -> Decrypt
    RustBuffer enc = uniffi_ant_ffi_fn_func_encrypt(input, &status);
    if (status.code) { printf("Encrypt failed\n"); return 1; }

    status = (RustCallStatus){0};
    RustBuffer dec = uniffi_ant_ffi_fn_func_decrypt(enc, &status);
    if (status.code) { printf("Decrypt failed\n"); return 1; }

    // Verify (skip 4-byte length prefix)
    int ok = (dec.data[3] == len && memcmp(dec.data + 4, msg, len) == 0);
    printf("Original:  %s\nDecrypted: %.*s\n%s\n", msg, (int)len, dec.data + 4, ok ? "SUCCESS!" : "FAILED!");

    ffi_ant_ffi_rustbuffer_free(dec, &status);
    return !ok;
}
