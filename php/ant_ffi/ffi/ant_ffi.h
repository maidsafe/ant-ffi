// PHP FFI header for ant_ffi
// Simplified version compatible with PHP FFI::cdef()

typedef struct RustBuffer {
    uint64_t capacity;
    uint64_t len;
    uint8_t *data;
} RustBuffer;

typedef struct ForeignBytes {
    int32_t len;
    const uint8_t *data;
} ForeignBytes;

typedef struct RustCallStatus {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;

// Callback type for async future polling
// poll_result: 0 = WAKE (poll again), 1 = READY (can complete)
typedef void (*UniFfiRustFutureContinuationCallback)(void* callback_data, int8_t poll_result);

// Buffer Management
RustBuffer ffi_ant_ffi_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus *out_status);
void ffi_ant_ffi_rustbuffer_free(RustBuffer buf, RustCallStatus *out_status);
RustBuffer ffi_ant_ffi_rustbuffer_alloc(uint64_t size, RustCallStatus *out_status);

// Self-Encryption
RustBuffer uniffi_ant_ffi_fn_func_encrypt(RustBuffer data, RustCallStatus *out_status);
RustBuffer uniffi_ant_ffi_fn_func_decrypt(RustBuffer encrypted_data, RustCallStatus *out_status);

// Data Constants
uint64_t uniffi_ant_ffi_fn_func_chunk_max_size(RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_func_chunk_max_raw_size(RustCallStatus *out_status);

// SecretKey
void *uniffi_ant_ffi_fn_constructor_secretkey_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_secretkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_secretkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_secretkey_public_key(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_secretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_secretkey(void *ptr, RustCallStatus *out_status);

// PublicKey
void *uniffi_ant_ffi_fn_constructor_publickey_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_publickey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_publickey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_publickey(void *ptr, RustCallStatus *out_status);

// Chunk
void *uniffi_ant_ffi_fn_constructor_chunk_new(RustBuffer value, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_chunk_value(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_chunk_address(void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_chunk_size(void *ptr, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_chunk_is_too_big(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_chunk(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_chunk(void *ptr, RustCallStatus *out_status);

// ChunkAddress
void *uniffi_ant_ffi_fn_constructor_chunkaddress_new(RustBuffer bytes, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_chunkaddress_from_content(RustBuffer data, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_chunkaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_chunkaddress_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_chunkaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_chunkaddress(void *ptr, RustCallStatus *out_status);

// DataAddress
void *uniffi_ant_ffi_fn_constructor_dataaddress_new(RustBuffer bytes, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_dataaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_dataaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_dataaddress_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_dataaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_dataaddress(void *ptr, RustCallStatus *out_status);

// Network
void *uniffi_ant_ffi_fn_constructor_network_new(int8_t is_local, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_network_custom(RustBuffer rpc_url, RustBuffer payment_token_address, RustBuffer data_payments_address, RustBuffer royalties_pk_hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_network(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_network(void *ptr, RustCallStatus *out_status);

// Wallet
void *uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(void *network, RustBuffer private_key, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_wallet_address(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_wallet(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_wallet(void *ptr, RustCallStatus *out_status);

// Client - Constructors (Async - returns future handle)
uint64_t uniffi_ant_ffi_fn_constructor_client_init(void);
uint64_t uniffi_ant_ffi_fn_constructor_client_init_local(void);
uint64_t uniffi_ant_ffi_fn_constructor_client_init_with_peers(RustBuffer peers, void *network, RustBuffer data_dir);

void uniffi_ant_ffi_fn_free_client(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_client(void *ptr, RustCallStatus *out_status);

// Client - Data Operations (Async - returns future handle)
uint64_t uniffi_ant_ffi_fn_method_client_data_put_public(void *ptr, RustBuffer data, RustBuffer payment);
uint64_t uniffi_ant_ffi_fn_method_client_data_get_public(void *ptr, RustBuffer address_hex);

// Async Future Handling - Pointer results
void ffi_ant_ffi_rust_future_poll_pointer(uint64_t handle, UniFfiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_pointer(uint64_t handle);
void *ffi_ant_ffi_rust_future_complete_pointer(uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_pointer(uint64_t handle);

// Async Future Handling - RustBuffer results
void ffi_ant_ffi_rust_future_poll_rust_buffer(uint64_t handle, UniFfiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_rust_buffer(uint64_t handle);
void ffi_ant_ffi_rust_future_complete_rust_buffer(RustBuffer *out_result, uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_rust_buffer(uint64_t handle);

// Async Future Handling - void results
void ffi_ant_ffi_rust_future_poll_void(uint64_t handle, UniFfiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_void(uint64_t handle);
void ffi_ant_ffi_rust_future_complete_void(uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_void(uint64_t handle);

// Async Future Handling - u64 results
void ffi_ant_ffi_rust_future_poll_u64(uint64_t handle, UniFfiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_u64(uint64_t handle);
uint64_t ffi_ant_ffi_rust_future_complete_u64(uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_u64(uint64_t handle);

// Blocking (synchronous) wrapper functions for languages without async support
void *uniffi_ant_ffi_fn_func_client_init_local_blocking(RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_data_put_public_blocking(RustBuffer *out_result, void *client, RustBuffer data, void *wallet, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_data_get_public_blocking(RustBuffer *out_result, void *client, RustBuffer address_hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_data_cost_blocking(RustBuffer *out_result, void *client, RustBuffer data, RustCallStatus *out_status);
