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

// Private Data Blocking
void uniffi_ant_ffi_fn_func_client_data_put_blocking(RustBuffer *out_result, void *client, RustBuffer data, void *wallet, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_data_get_blocking(RustBuffer *out_result, void *client, void *data_map, RustCallStatus *out_status);

// Pointer Blocking
void *uniffi_ant_ffi_fn_func_client_pointer_get_blocking(void *client, void *address, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_pointer_put_blocking(void *client, void *pointer, void *wallet, RustCallStatus *out_status);

// Scratchpad Blocking
void *uniffi_ant_ffi_fn_func_client_scratchpad_get_blocking(void *client, void *address, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_scratchpad_put_blocking(void *client, void *scratchpad, void *wallet, RustCallStatus *out_status);

// Register Blocking
void uniffi_ant_ffi_fn_func_client_register_get_blocking(RustBuffer *out_result, void *client, void *address, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_func_client_register_create_blocking(void *client, void *owner, RustBuffer value, void *wallet, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_register_update_blocking(void *client, void *owner, RustBuffer value, void *wallet, RustCallStatus *out_status);

// Graph Entry Blocking
void *uniffi_ant_ffi_fn_func_client_graph_entry_get_blocking(void *client, void *address, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_graph_entry_put_blocking(void *client, void *entry, void *wallet, RustCallStatus *out_status);

// Vault Blocking
void *uniffi_ant_ffi_fn_func_client_vault_get_user_data_blocking(void *client, void *secret_key, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_vault_put_user_data_blocking(void *client, void *secret_key, void *wallet, void *user_data, RustCallStatus *out_status);

// Archive Blocking
void *uniffi_ant_ffi_fn_func_client_archive_get_public_blocking(void *client, void *address, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_archive_put_public_blocking(void *client, void *archive, void *wallet, RustCallStatus *out_status);

// File Blocking
void uniffi_ant_ffi_fn_func_client_file_upload_blocking(RustBuffer *out_result, void *client, RustBuffer path, void *wallet, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_file_upload_public_blocking(RustBuffer *out_result, void *client, RustBuffer path, void *wallet, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_file_download_blocking(void *client, void *data_map, RustBuffer path, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_client_file_download_public_blocking(void *client, void *address, RustBuffer path, RustCallStatus *out_status);

// DerivationIndex
void *uniffi_ant_ffi_fn_constructor_derivationindex_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(RustBuffer bytes, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_derivationindex_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_derivationindex(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_derivationindex(void *ptr, RustCallStatus *out_status);

// Signature
void *uniffi_ant_ffi_fn_constructor_signature_from_bytes(RustBuffer bytes, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_signature_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_signature_parity(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_signature_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_signature(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_signature(void *ptr, RustCallStatus *out_status);

// MainSecretKey
void *uniffi_ant_ffi_fn_constructor_mainsecretkey_new(void *secret_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_mainsecretkey_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_public_key(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_sign(void *ptr, RustBuffer message, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(void *ptr, void *index, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_mainsecretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_mainsecretkey(void *ptr, RustCallStatus *out_status);

// MainPubkey
void *uniffi_ant_ffi_fn_constructor_mainpubkey_new(void *public_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_mainpubkey_verify(void *ptr, void *signature, RustBuffer message, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainpubkey_derive_key(void *ptr, void *index, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_mainpubkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_mainpubkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_mainpubkey(void *ptr, RustCallStatus *out_status);

// DerivedSecretKey
void *uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(void *secret_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_derivedsecretkey_sign(void *ptr, RustBuffer message, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_derivedsecretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_derivedsecretkey(void *ptr, RustCallStatus *out_status);

// DerivedPubkey
void *uniffi_ant_ffi_fn_constructor_derivedpubkey_new(void *public_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_derivedpubkey_verify(void *ptr, void *signature, RustBuffer message, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_derivedpubkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_derivedpubkey(void *ptr, RustCallStatus *out_status);

// DataMapChunk
void *uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_datamapchunk_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_datamapchunk(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_datamapchunk(void *ptr, RustCallStatus *out_status);

// PointerAddress
void *uniffi_ant_ffi_fn_constructor_pointeraddress_new(void *owner, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_pointeraddress_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_pointeraddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_pointeraddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_pointeraddress(void *ptr, RustCallStatus *out_status);

// PointerTarget
void *uniffi_ant_ffi_fn_constructor_pointertarget_from_chunk_address(void *address, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointertarget_from_graph_entry_address(void *address, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointertarget_from_pointer_address(void *address, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointertarget_from_scratchpad_address(void *address, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_pointertarget(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_pointertarget(void *ptr, RustCallStatus *out_status);

// NetworkPointer
void *uniffi_ant_ffi_fn_constructor_networkpointer_new(void *owner, int64_t counter, void *target, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_networkpointer_address(void *ptr, RustCallStatus *out_status);
int64_t uniffi_ant_ffi_fn_method_networkpointer_counter(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_networkpointer_owner(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_networkpointer_target(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_networkpointer(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_networkpointer(void *ptr, RustCallStatus *out_status);

// ScratchpadAddress
void *uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(void *owner, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_scratchpadaddress_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_scratchpadaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_scratchpadaddress(void *ptr, RustCallStatus *out_status);

// Scratchpad
void *uniffi_ant_ffi_fn_constructor_scratchpad_new(void *owner, int64_t content_type, RustBuffer data, int64_t counter, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_scratchpad_address(void *ptr, RustCallStatus *out_status);
int64_t uniffi_ant_ffi_fn_method_scratchpad_counter(void *ptr, RustCallStatus *out_status);
int64_t uniffi_ant_ffi_fn_method_scratchpad_content_type(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_scratchpad_data(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_scratchpad_is_valid(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_scratchpad_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_scratchpad(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_scratchpad(void *ptr, RustCallStatus *out_status);

// RegisterAddress
void *uniffi_ant_ffi_fn_constructor_registeraddress_new(void *owner, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_registeraddress_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_registeraddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_registeraddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_registeraddress(void *ptr, RustCallStatus *out_status);

// GraphEntryAddress
void *uniffi_ant_ffi_fn_constructor_graphentryaddress_new(void *owner, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_graphentryaddress_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_graphentryaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_graphentryaddress(void *ptr, RustCallStatus *out_status);

// GraphEntry
void *uniffi_ant_ffi_fn_constructor_graphentry_new(void *owner, RustBuffer parents, RustBuffer content, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_graphentry_address(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_graphentry_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_graphentry_content(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_graphentry(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_graphentry(void *ptr, RustCallStatus *out_status);

// VaultSecretKey
void *uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_vaultsecretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_vaultsecretkey(void *ptr, RustCallStatus *out_status);

// UserData
void *uniffi_ant_ffi_fn_constructor_userdata_new(RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_userdata_file_archives(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_userdata_private_file_archives(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_userdata(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_userdata(void *ptr, RustCallStatus *out_status);

// ArchiveAddress
void *uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_archiveaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_archiveaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_archiveaddress(void *ptr, RustCallStatus *out_status);

// PublicArchive
void *uniffi_ant_ffi_fn_constructor_publicarchive_new(RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_publicarchive_add_file(void *ptr, RustBuffer path, void *data_address, void *metadata, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_publicarchive_files(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_publicarchive(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_publicarchive(void *ptr, RustCallStatus *out_status);

// PrivateArchive
void *uniffi_ant_ffi_fn_constructor_privatearchive_new(RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_privatearchive_add_file(void *ptr, RustBuffer path, void *data_map, void *metadata, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_privatearchive_files(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_privatearchive(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_privatearchive(void *ptr, RustCallStatus *out_status);

// PrivateArchiveDataMap
void *uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_privatearchivedatamap(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_privatearchivedatamap(void *ptr, RustCallStatus *out_status);

// Metadata
void *uniffi_ant_ffi_fn_constructor_metadata_new(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_metadata_with_size(uint64_t size, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_metadata_size(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_metadata(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_metadata(void *ptr, RustCallStatus *out_status);
