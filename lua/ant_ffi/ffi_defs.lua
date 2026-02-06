--[[
  FFI type declarations for ant_ffi

  This module defines all C types and function declarations needed
  to call the Rust FFI library via LuaJIT FFI (or cffi-lua).
]]

local ffi = require("ffi")

ffi.cdef[[
// =============================================================================
// Core Types
// =============================================================================

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

// Async callback type
typedef void (*UniffiRustFutureContinuationCallback)(uint64_t callback_data, int8_t poll_result);

// =============================================================================
// Buffer Management
// =============================================================================

RustBuffer ffi_ant_ffi_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus *out_status);
void ffi_ant_ffi_rustbuffer_free(RustBuffer buf, RustCallStatus *out_status);
RustBuffer ffi_ant_ffi_rustbuffer_alloc(uint64_t size, RustCallStatus *out_status);

// =============================================================================
// Self-Encryption
// =============================================================================

// Note: These functions return RustBuffer directly (unlike methods which use out param)
RustBuffer uniffi_ant_ffi_fn_func_encrypt(RustBuffer data, RustCallStatus *out_status);
RustBuffer uniffi_ant_ffi_fn_func_decrypt(RustBuffer encrypted_data, RustCallStatus *out_status);

// =============================================================================
// SecretKey
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_secretkey_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_secretkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_secretkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_secretkey_public_key(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_secretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_secretkey(void *ptr, RustCallStatus *out_status);

// =============================================================================
// PublicKey
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_publickey_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_publickey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_publickey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_publickey(void *ptr, RustCallStatus *out_status);

// =============================================================================
// DerivationIndex
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_derivationindex_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(RustBuffer bytes, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_derivationindex_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_derivationindex(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_derivationindex(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Signature
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_signature_from_bytes(RustBuffer bytes, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_signature_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_signature_parity(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_signature_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_signature(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_signature(void *ptr, RustCallStatus *out_status);

// =============================================================================
// MainSecretKey
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_mainsecretkey_new(void *secret_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_mainsecretkey_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_public_key(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_sign(void *ptr, RustBuffer msg, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(void *ptr, void *index, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_mainsecretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_mainsecretkey(void *ptr, RustCallStatus *out_status);

// =============================================================================
// MainPubkey
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_mainpubkey_new(void *public_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_mainpubkey_verify(void *ptr, void *signature, RustBuffer msg, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_mainpubkey_derive_key(void *ptr, void *index, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_mainpubkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_mainpubkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_mainpubkey(void *ptr, RustCallStatus *out_status);

// =============================================================================
// DerivedSecretKey
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(void *secret_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_derivedsecretkey_sign(void *ptr, RustBuffer msg, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_derivedsecretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_derivedsecretkey(void *ptr, RustCallStatus *out_status);

// =============================================================================
// DerivedPubkey
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_derivedpubkey_new(void *public_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_derivedpubkey_verify(void *ptr, void *signature, RustBuffer msg, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_derivedpubkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_derivedpubkey(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Chunk
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_chunk_new(RustBuffer value, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_chunk_value(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_chunk_address(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_chunk_network_address(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_chunk_size(void *ptr, RustCallStatus *out_status);
int8_t uniffi_ant_ffi_fn_method_chunk_is_too_big(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_chunk(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_chunk(void *ptr, RustCallStatus *out_status);

// =============================================================================
// ChunkAddress
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_chunkaddress_new(RustBuffer bytes, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_chunkaddress_from_content(RustBuffer data, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_chunkaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_chunkaddress_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_chunkaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_chunkaddress(void *ptr, RustCallStatus *out_status);

// =============================================================================
// DataAddress
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_dataaddress_new(RustBuffer bytes, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_dataaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_dataaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_dataaddress_to_bytes(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_dataaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_dataaddress(void *ptr, RustCallStatus *out_status);

// =============================================================================
// DataMapChunk
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_datamapchunk_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_datamapchunk_address(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_datamapchunk(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_datamapchunk(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Data Constants
// =============================================================================

uint64_t uniffi_ant_ffi_fn_func_chunk_max_size(RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_func_chunk_max_raw_size(RustCallStatus *out_status);

// =============================================================================
// Metadata
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_metadata_new(uint64_t size, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_metadata_with_timestamps(uint64_t size, uint64_t created, uint64_t modified, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_metadata_size(void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_metadata_created(void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_metadata_modified(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_metadata(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_metadata(void *ptr, RustCallStatus *out_status);

// =============================================================================
// ArchiveAddress
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_archiveaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_archiveaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_archiveaddress(void *ptr, RustCallStatus *out_status);

// =============================================================================
// PrivateArchiveDataMap
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_privatearchivedatamap(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_privatearchivedatamap(void *ptr, RustCallStatus *out_status);

// =============================================================================
// PublicArchive
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_publicarchive_new(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_publicarchive_add_file(void *ptr, RustBuffer path, void *address, void *metadata, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_publicarchive_rename_file(void *ptr, RustBuffer old_path, RustBuffer new_path, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_publicarchive_files(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_publicarchive_file_count(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_publicarchive_addresses(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_publicarchive(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_publicarchive(void *ptr, RustCallStatus *out_status);

// =============================================================================
// PrivateArchive
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_privatearchive_new(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_privatearchive_add_file(void *ptr, RustBuffer path, void *data_map, void *metadata, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_privatearchive_rename_file(void *ptr, RustBuffer old_path, RustBuffer new_path, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_privatearchive_files(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_privatearchive_file_count(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_privatearchive_data_maps(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_privatearchive(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_privatearchive(void *ptr, RustCallStatus *out_status);

// =============================================================================
// PointerAddress
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_pointeraddress_new(void *public_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_pointeraddress_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_pointeraddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_pointeraddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_pointeraddress(void *ptr, RustCallStatus *out_status);

// =============================================================================
// PointerTarget
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_pointertarget_chunk(void *addr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointertarget_pointer(void *addr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointertarget_graph_entry(void *addr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_pointertarget_scratchpad(void *addr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_pointertarget_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_pointertarget(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_pointertarget(void *ptr, RustCallStatus *out_status);

// =============================================================================
// NetworkPointer
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_networkpointer_new(void *key, uint64_t counter, void *target, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_networkpointer_address(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_networkpointer_target(void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_networkpointer_counter(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_networkpointer(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_networkpointer(void *ptr, RustCallStatus *out_status);

// =============================================================================
// ScratchpadAddress
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(void *public_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_scratchpadaddress_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_scratchpadaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_scratchpadaddress(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Scratchpad
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_scratchpad_new(void *owner, uint64_t data_encoding, RustBuffer data, uint64_t counter, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_scratchpad_address(void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_scratchpad_data_encoding(void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_scratchpad_counter(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_scratchpad_decrypt_data(RustBuffer *out_result, void *ptr, void *secret_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_scratchpad_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_scratchpad_encrypted_data(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_scratchpad(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_scratchpad(void *ptr, RustCallStatus *out_status);

// =============================================================================
// RegisterAddress
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_registeraddress_new(void *owner, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_registeraddress_owner(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_registeraddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_registeraddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_registeraddress(void *ptr, RustCallStatus *out_status);

// Register helper functions
void *uniffi_ant_ffi_fn_func_register_key_from_name(void *owner, RustBuffer name, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_func_register_value_from_bytes(RustBuffer *out_result, RustBuffer bytes, RustCallStatus *out_status);

// =============================================================================
// GraphEntryAddress
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_graphentryaddress_new(void *public_key, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_graphentryaddress(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_graphentryaddress(void *ptr, RustCallStatus *out_status);

// =============================================================================
// GraphEntry
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_graphentry_new(void *owner, RustBuffer parents, RustBuffer content, RustBuffer descendants, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_method_graphentry_address(void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_graphentry_content(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_graphentry_parents(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_graphentry_descendants(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_graphentry(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_graphentry(void *ptr, RustCallStatus *out_status);

// =============================================================================
// VaultSecretKey
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(RustBuffer hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_vaultsecretkey(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_vaultsecretkey(void *ptr, RustCallStatus *out_status);

// =============================================================================
// UserData
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_userdata_new(RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_userdata_file_archives(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_userdata_private_file_archives(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_userdata(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_userdata(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Network
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_network_new(int8_t is_local, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_constructor_network_custom(RustBuffer rpc_url, RustBuffer payment_token_address, RustBuffer data_payments_address, RustBuffer royalties_pk_hex, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_free_network(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_network(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Wallet
// =============================================================================

void *uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(void *network, RustBuffer private_key, RustCallStatus *out_status);
void uniffi_ant_ffi_fn_method_wallet_address(RustBuffer *out_result, void *ptr, RustCallStatus *out_status);
uint64_t uniffi_ant_ffi_fn_method_wallet_balance_of_tokens(void *ptr);  // Async: returns future handle
void uniffi_ant_ffi_fn_free_wallet(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_wallet(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Client - Constructors (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_constructor_client_init(void);  // Async: returns future handle
uint64_t uniffi_ant_ffi_fn_constructor_client_init_local(void);  // Async: returns future handle
void uniffi_ant_ffi_fn_free_client(void *ptr, RustCallStatus *out_status);
void *uniffi_ant_ffi_fn_clone_client(void *ptr, RustCallStatus *out_status);

// =============================================================================
// Client - Data Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_data_put_public(void *ptr, RustBuffer data, RustBuffer payment);
uint64_t uniffi_ant_ffi_fn_method_client_data_get_public(void *ptr, RustBuffer address_hex);
uint64_t uniffi_ant_ffi_fn_method_client_data_put(void *ptr, RustBuffer data, RustBuffer payment);
uint64_t uniffi_ant_ffi_fn_method_client_data_get(void *ptr, void *data_map_chunk);
uint64_t uniffi_ant_ffi_fn_method_client_data_cost(void *ptr, RustBuffer data);

// =============================================================================
// Client - File Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_file_upload_public(void *ptr, RustBuffer file_path, RustBuffer payment);
uint64_t uniffi_ant_ffi_fn_method_client_file_download_public(void *ptr, void *address, RustBuffer dest_path);
uint64_t uniffi_ant_ffi_fn_method_client_file_upload(void *ptr, RustBuffer file_path, RustBuffer payment);
uint64_t uniffi_ant_ffi_fn_method_client_file_download(void *ptr, void *data_map_chunk, RustBuffer dest_path);
uint64_t uniffi_ant_ffi_fn_method_client_file_cost(void *ptr, RustBuffer file_path, int8_t follow_symlinks, int8_t include_hidden);

// =============================================================================
// Client - Chunk Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_chunk_put(void *ptr, RustBuffer data, RustBuffer payment);
uint64_t uniffi_ant_ffi_fn_method_client_chunk_get(void *ptr, void *address);

// =============================================================================
// Client - Pointer Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_pointer_get(void *ptr, void *address);
uint64_t uniffi_ant_ffi_fn_method_client_pointer_put(void *ptr, void *pointer, RustBuffer payment);

// =============================================================================
// Client - GraphEntry Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_get(void *ptr, void *address);
uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_put(void *ptr, void *entry, RustBuffer payment);

// =============================================================================
// Client - Scratchpad Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_get(void *ptr, void *address);
uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_put(void *ptr, void *scratchpad, RustBuffer payment);

// =============================================================================
// Client - Register Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_register_get(void *ptr, void *address);
uint64_t uniffi_ant_ffi_fn_method_client_register_create(void *ptr, void *owner, RustBuffer value, RustBuffer payment);
uint64_t uniffi_ant_ffi_fn_method_client_register_update(void *ptr, void *owner, RustBuffer value, RustBuffer payment);

// =============================================================================
// Client - Vault Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_vault_get_user_data(void *ptr, void *secret_key);
uint64_t uniffi_ant_ffi_fn_method_client_vault_put_user_data(void *ptr, void *secret_key, RustBuffer payment, void *user_data);

// =============================================================================
// Client - Archive Operations (Async)
// =============================================================================

uint64_t uniffi_ant_ffi_fn_method_client_archive_get_public(void *ptr, void *address);
uint64_t uniffi_ant_ffi_fn_method_client_archive_put_public(void *ptr, void *archive, RustBuffer payment);

// =============================================================================
// Async Future Handling
// =============================================================================

// For pointer results (Client, objects, etc.)
void ffi_ant_ffi_rust_future_poll_pointer(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_pointer(uint64_t handle);
void *ffi_ant_ffi_rust_future_complete_pointer(uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_pointer(uint64_t handle);

// For RustBuffer results (data, strings, etc.)
void ffi_ant_ffi_rust_future_poll_rust_buffer(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_rust_buffer(uint64_t handle);
void ffi_ant_ffi_rust_future_complete_rust_buffer(RustBuffer *out_result, uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_rust_buffer(uint64_t handle);

// For void results
void ffi_ant_ffi_rust_future_poll_void(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_void(uint64_t handle);
void ffi_ant_ffi_rust_future_complete_void(uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_void(uint64_t handle);

// For u64 results (balance, etc.)
void ffi_ant_ffi_rust_future_poll_u64(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
void ffi_ant_ffi_rust_future_cancel_u64(uint64_t handle);
uint64_t ffi_ant_ffi_rust_future_complete_u64(uint64_t handle, RustCallStatus *out_status);
void ffi_ant_ffi_rust_future_free_u64(uint64_t handle);
]]

return true
