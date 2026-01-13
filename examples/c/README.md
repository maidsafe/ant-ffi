# C Examples for Autonomi

Examples demonstrating how to use the Autonomi C API.

> **Note**: This is a low-level API that requires manual serialization and memory management. It's generated directly from UniFFI bindings and may not always be ergonomic. Consider building helper functions or a wrapper library for production use.

## Quick Start

```bash
# From this directory:
make setup    # Build library and generate headers (one-time)
make          # Build examples
make run      # Run self_encryption example
```

## Examples

| File | Description |
|------|-------------|
| `self_encryption.c` | Encrypt and decrypt data using self-encryption |

## UniFFI Serialization

The C API uses UniFFI's serialization format. For `Vec<u8>` (byte arrays):
- 4-byte **big-endian** length prefix
- Followed by raw bytes

```c
// Serialize bytes for UniFFI
uint8_t *buf = malloc(4 + len);
buf[0] = (len >> 24) & 0xFF;  // Big-endian length
buf[1] = (len >> 16) & 0xFF;
buf[2] = (len >> 8) & 0xFF;
buf[3] = len & 0xFF;
memcpy(buf + 4, data, len);
```

## Documentation

See [C API Documentation](../../docs/C_API.md) for complete API reference.
