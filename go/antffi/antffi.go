// Package antffi provides Go bindings for the Autonomi network FFI library.
package antffi

/*
#cgo CFLAGS: -I${SRCDIR}/../../rust/target/release
#cgo !windows LDFLAGS: -L${SRCDIR}/../../rust/target/release -lant_ffi

#cgo linux LDFLAGS: -Wl,-rpath,${SRCDIR}/../../rust/target/release
#cgo darwin LDFLAGS: -Wl,-rpath,${SRCDIR}/../../rust/target/release
#cgo windows LDFLAGS: -L${SRCDIR}/../../rust/target/release -l:ant_ffi.dll.lib -lws2_32 -luserenv -lbcrypt -lntdll -ladvapi32 -lcrypt32 -liphlpapi

#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

// RustBuffer structure - matches UniFFI's RustBuffer
typedef struct {
    uint64_t capacity;
    uint64_t len;
    uint8_t* data;
} RustBuffer;

// ForeignBytes structure - for passing Go bytes to Rust
typedef struct {
    int32_t len;
    const uint8_t* data;
} ForeignBytes;

// RustCallStatus structure - for error handling
typedef struct {
    int8_t code;
    RustBuffer error_buf;
} RustCallStatus;

// ========== Buffer Management ==========

extern RustBuffer ffi_ant_ffi_rustbuffer_from_bytes(ForeignBytes bytes, RustCallStatus* status);
extern void ffi_ant_ffi_rustbuffer_free(RustBuffer buf, RustCallStatus* status);
extern RustBuffer ffi_ant_ffi_rustbuffer_alloc(uint64_t size, RustCallStatus* status);

// ========== Self-Encryption ==========

extern RustBuffer uniffi_ant_ffi_fn_func_encrypt(RustBuffer data, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_func_decrypt(RustBuffer data, RustCallStatus* status);

// ========== Keys - SecretKey ==========

extern void* uniffi_ant_ffi_fn_constructor_secretkey_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_secretkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_secretkey_to_hex(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_secretkey_public_key(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_secretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_secretkey(void* ptr, RustCallStatus* status);

// ========== Keys - PublicKey ==========

extern void* uniffi_ant_ffi_fn_constructor_publickey_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_publickey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_publickey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_publickey(void* ptr, RustCallStatus* status);

// ========== Key Derivation - DerivationIndex ==========

extern void* uniffi_ant_ffi_fn_constructor_derivationindex_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(RustBuffer bytes, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_derivationindex_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_derivationindex(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_derivationindex(void* ptr, RustCallStatus* status);

// ========== Key Derivation - Signature ==========

extern void* uniffi_ant_ffi_fn_constructor_signature_from_bytes(RustBuffer bytes, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_signature_to_bytes(void* ptr, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_signature_parity(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_signature_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_signature(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_signature(void* ptr, RustCallStatus* status);

// ========== Key Derivation - MainSecretKey ==========

extern void* uniffi_ant_ffi_fn_constructor_mainsecretkey_new(void* secretKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_mainsecretkey_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_public_key(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_sign(void* ptr, RustBuffer msg, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(void* ptr, void* index, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_mainsecretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_mainsecretkey(void* ptr, RustCallStatus* status);

// ========== Key Derivation - MainPubkey ==========

extern void* uniffi_ant_ffi_fn_constructor_mainpubkey_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_mainpubkey_verify(void* ptr, void* signature, RustBuffer msg, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_mainpubkey_derive_key(void* ptr, void* index, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_mainpubkey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_mainpubkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_mainpubkey(void* ptr, RustCallStatus* status);

// ========== Key Derivation - DerivedSecretKey ==========

extern void* uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(void* secretKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_derivedsecretkey_sign(void* ptr, RustBuffer msg, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_derivedsecretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_derivedsecretkey(void* ptr, RustCallStatus* status);

// ========== Key Derivation - DerivedPubkey ==========

extern void* uniffi_ant_ffi_fn_constructor_derivedpubkey_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_derivedpubkey_verify(void* ptr, void* signature, RustBuffer msg, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_derivedpubkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_derivedpubkey(void* ptr, RustCallStatus* status);

// ========== Data - Chunk ==========

extern void* uniffi_ant_ffi_fn_constructor_chunk_new(RustBuffer value, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunk_value(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_chunk_address(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunk_network_address(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_chunk_size(void* ptr, RustCallStatus* status);
extern int8_t uniffi_ant_ffi_fn_method_chunk_is_too_big(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_chunk(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_chunk(void* ptr, RustCallStatus* status);

// ========== Data - ChunkAddress ==========

extern void* uniffi_ant_ffi_fn_constructor_chunkaddress_new(RustBuffer bytes, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_chunkaddress_from_content(RustBuffer data, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunkaddress_to_hex(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_chunkaddress_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_chunkaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_chunkaddress(void* ptr, RustCallStatus* status);

// ========== Data - DataAddress ==========

extern void* uniffi_ant_ffi_fn_constructor_dataaddress_new(RustBuffer bytes, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_dataaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_dataaddress_to_hex(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_dataaddress_to_bytes(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_dataaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_dataaddress(void* ptr, RustCallStatus* status);

// ========== Data - DataMapChunk ==========

extern void* uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_datamapchunk_to_hex(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_datamapchunk_address(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_datamapchunk(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_datamapchunk(void* ptr, RustCallStatus* status);

// ========== Data - Constants ==========

extern uint64_t uniffi_ant_ffi_fn_func_chunk_max_size(RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_func_chunk_max_raw_size(RustCallStatus* status);

// ========== Archive - Metadata ==========

extern void* uniffi_ant_ffi_fn_constructor_metadata_new(uint64_t size, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_metadata_with_timestamps(uint64_t size, uint64_t created, uint64_t modified, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_metadata_size(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_metadata_created(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_metadata_modified(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_metadata(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_metadata(void* ptr, RustCallStatus* status);

// ========== Archive - ArchiveAddress ==========

extern void* uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_archiveaddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_archiveaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_archiveaddress(void* ptr, RustCallStatus* status);

// ========== Archive - PrivateArchiveDataMap ==========

extern void* uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_privatearchivedatamap(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_privatearchivedatamap(void* ptr, RustCallStatus* status);

// ========== Archive - PublicArchive ==========

extern void* uniffi_ant_ffi_fn_constructor_publicarchive_new(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_publicarchive_add_file(void* ptr, RustBuffer path, void* address, void* metadata, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_publicarchive_rename_file(void* ptr, RustBuffer oldPath, RustBuffer newPath, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_publicarchive_files(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_publicarchive_file_count(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_publicarchive_addresses(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_publicarchive(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_publicarchive(void* ptr, RustCallStatus* status);

// ========== Archive - PrivateArchive ==========

extern void* uniffi_ant_ffi_fn_constructor_privatearchive_new(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_privatearchive_add_file(void* ptr, RustBuffer path, void* dataMap, void* metadata, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_privatearchive_rename_file(void* ptr, RustBuffer oldPath, RustBuffer newPath, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_privatearchive_files(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_privatearchive_file_count(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_privatearchive_data_maps(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_privatearchive(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_privatearchive(void* ptr, RustCallStatus* status);

// ========== Pointer - PointerAddress ==========

extern void* uniffi_ant_ffi_fn_constructor_pointeraddress_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_pointeraddress_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_pointeraddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_pointeraddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_pointeraddress(void* ptr, RustCallStatus* status);

// ========== Pointer - PointerTarget ==========

extern void* uniffi_ant_ffi_fn_constructor_pointertarget_chunk(void* addr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointertarget_pointer(void* addr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointertarget_graph_entry(void* addr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_pointertarget_scratchpad(void* addr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_pointertarget_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_pointertarget(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_pointertarget(void* ptr, RustCallStatus* status);

// ========== Pointer - NetworkPointer ==========

extern void* uniffi_ant_ffi_fn_constructor_networkpointer_new(void* key, uint64_t counter, void* target, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_networkpointer_address(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_networkpointer_target(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_networkpointer_counter(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_networkpointer(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_networkpointer(void* ptr, RustCallStatus* status);

// ========== Scratchpad - ScratchpadAddress ==========

extern void* uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_scratchpadaddress_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_scratchpadaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_scratchpadaddress(void* ptr, RustCallStatus* status);

// ========== Scratchpad - Scratchpad ==========

extern void* uniffi_ant_ffi_fn_constructor_scratchpad_new(void* owner, uint64_t dataEncoding, RustBuffer data, uint64_t counter, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_scratchpad_address(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_scratchpad_data_encoding(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_scratchpad_counter(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_scratchpad_decrypt_data(void* ptr, void* secretKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_scratchpad_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_scratchpad_encrypted_data(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_scratchpad(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_scratchpad(void* ptr, RustCallStatus* status);

// ========== Register - RegisterAddress ==========

extern void* uniffi_ant_ffi_fn_constructor_registeraddress_new(void* owner, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_registeraddress_owner(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_registeraddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_registeraddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_registeraddress(void* ptr, RustCallStatus* status);

// ========== Register - Functions ==========

extern void* uniffi_ant_ffi_fn_func_register_key_from_name(void* owner, RustBuffer name, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_func_register_value_from_bytes(RustBuffer bytes, RustCallStatus* status);

// ========== GraphEntry - GraphEntryAddress ==========

extern void* uniffi_ant_ffi_fn_constructor_graphentryaddress_new(void* publicKey, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_graphentryaddress(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_graphentryaddress(void* ptr, RustCallStatus* status);

// ========== GraphEntry - GraphEntry ==========

extern void* uniffi_ant_ffi_fn_constructor_graphentry_new(void* owner, RustBuffer parents, RustBuffer content, RustBuffer descendants, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_method_graphentry_address(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentry_content(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentry_parents(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_graphentry_descendants(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_graphentry(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_graphentry(void* ptr, RustCallStatus* status);

// ========== Vault - VaultSecretKey ==========

extern void* uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(RustBuffer hex, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_vaultsecretkey(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_vaultsecretkey(void* ptr, RustCallStatus* status);

// ========== Vault - UserData ==========

extern void* uniffi_ant_ffi_fn_constructor_userdata_new(RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_userdata_file_archives(void* ptr, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_userdata_private_file_archives(void* ptr, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_userdata(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_userdata(void* ptr, RustCallStatus* status);

// ========== Network ==========

extern void* uniffi_ant_ffi_fn_constructor_network_new(int8_t isLocal, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_constructor_network_custom(RustBuffer rpcUrl, RustBuffer paymentTokenAddress, RustBuffer dataPaymentsAddress, RustCallStatus* status);
extern void uniffi_ant_ffi_fn_free_network(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_network(void* ptr, RustCallStatus* status);

// ========== Wallet ==========

extern void* uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(void* network, RustBuffer privateKey, RustCallStatus* status);
extern RustBuffer uniffi_ant_ffi_fn_method_wallet_address(void* ptr, RustCallStatus* status);
extern uint64_t uniffi_ant_ffi_fn_method_wallet_balance_of_tokens(void* ptr);
extern void uniffi_ant_ffi_fn_free_wallet(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_wallet(void* ptr, RustCallStatus* status);

// ========== Client - Constructors (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_constructor_client_init();
extern uint64_t uniffi_ant_ffi_fn_constructor_client_init_local();
extern void uniffi_ant_ffi_fn_free_client(void* ptr, RustCallStatus* status);
extern void* uniffi_ant_ffi_fn_clone_client(void* ptr, RustCallStatus* status);

// ========== Client - Data Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_data_put_public(void* ptr, RustBuffer data, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_get_public(void* ptr, RustBuffer addressHex);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_put(void* ptr, RustBuffer data, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_get(void* ptr, void* dataMapChunk);
extern uint64_t uniffi_ant_ffi_fn_method_client_data_cost(void* ptr, RustBuffer data);

// ========== Client - File Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_file_upload_public(void* ptr, RustBuffer filePath, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_download_public(void* ptr, void* address, RustBuffer destPath);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_upload(void* ptr, RustBuffer filePath, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_download(void* ptr, void* dataMapChunk, RustBuffer destPath);
extern uint64_t uniffi_ant_ffi_fn_method_client_file_cost(void* ptr, RustBuffer filePath);

// ========== Client - Chunk Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_chunk_put(void* ptr, RustBuffer data, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_chunk_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_chunk_cost(void* ptr, void* address);

// ========== Client - Pointer Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_put(void* ptr, void* pointer, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_create(void* ptr, void* owner, void* target, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_update(void* ptr, void* owner, void* target, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_cost(void* ptr, void* key);
extern uint64_t uniffi_ant_ffi_fn_method_client_pointer_check_existence(void* ptr, void* address);

// ========== Client - GraphEntry Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_put(void* ptr, void* entry, RustBuffer payment);

// ========== Client - Scratchpad Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_put(void* ptr, void* scratchpad, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_get_from_public_key(void* ptr, void* publicKey);
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_create(void* ptr, void* owner, uint64_t contentType, RustBuffer initialData, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_update(void* ptr, void* owner, uint64_t contentType, RustBuffer data, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_cost(void* ptr, void* publicKey);
extern uint64_t uniffi_ant_ffi_fn_method_client_scratchpad_check_existence(void* ptr, void* address);

// ========== Client - Register Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_register_get(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_register_create(void* ptr, void* owner, RustBuffer value, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_register_update(void* ptr, void* owner, RustBuffer value, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_register_cost(void* ptr, void* owner);

// ========== Client - Vault Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_vault_get_user_data(void* ptr, void* secretKey);
extern uint64_t uniffi_ant_ffi_fn_method_client_vault_put_user_data(void* ptr, void* secretKey, RustBuffer payment, void* userData);
extern uint64_t uniffi_ant_ffi_fn_method_client_vault_cost(void* ptr, void* key, uint64_t maxSize);

// ========== Client - Archive Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_archive_get_public(void* ptr, void* address);
extern uint64_t uniffi_ant_ffi_fn_method_client_archive_put_public(void* ptr, void* archive, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_archive_cost(void* ptr, void* archive);

// ========== Client - GraphEntry Operations (Async) - Additional ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_cost(void* ptr, void* key);
extern uint64_t uniffi_ant_ffi_fn_method_client_graph_entry_check_existence(void* ptr, void* address);

// ========== Client - Directory Operations (Async) ==========

extern uint64_t uniffi_ant_ffi_fn_method_client_dir_upload(void* ptr, RustBuffer path, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_dir_upload_public(void* ptr, RustBuffer path, RustBuffer payment);
extern uint64_t uniffi_ant_ffi_fn_method_client_dir_download(void* ptr, void* dataMap, RustBuffer destPath);
extern uint64_t uniffi_ant_ffi_fn_method_client_dir_download_public(void* ptr, void* address, RustBuffer destPath);

// ========== Async Future Polling ==========

typedef void (*UniffiRustFutureContinuationCallback)(uint64_t callback_data, int8_t poll_result);

// Pointer futures
extern void ffi_ant_ffi_rust_future_poll_pointer(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
extern void* ffi_ant_ffi_rust_future_complete_pointer(uint64_t handle, RustCallStatus* status);
extern void ffi_ant_ffi_rust_future_cancel_pointer(uint64_t handle);
extern void ffi_ant_ffi_rust_future_free_pointer(uint64_t handle);

// RustBuffer futures
extern void ffi_ant_ffi_rust_future_poll_rust_buffer(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
extern RustBuffer ffi_ant_ffi_rust_future_complete_rust_buffer(uint64_t handle, RustCallStatus* status);
extern void ffi_ant_ffi_rust_future_cancel_rust_buffer(uint64_t handle);
extern void ffi_ant_ffi_rust_future_free_rust_buffer(uint64_t handle);

// Void futures (for operations that return nothing)
extern void ffi_ant_ffi_rust_future_poll_void(uint64_t handle, UniffiRustFutureContinuationCallback callback, uint64_t callback_data);
extern void ffi_ant_ffi_rust_future_complete_void(uint64_t handle, RustCallStatus* status);
extern void ffi_ant_ffi_rust_future_cancel_void(uint64_t handle);
extern void ffi_ant_ffi_rust_future_free_void(uint64_t handle);

*/
import "C"

import (
	"unsafe"
)

// cRustBuffer is the Go type matching C.RustBuffer
type cRustBuffer = C.RustBuffer

// cForeignBytes is the Go type matching C.ForeignBytes
type cForeignBytes = C.ForeignBytes

// cRustCallStatus is the Go type matching C.RustCallStatus
type cRustCallStatus = C.RustCallStatus

// unsafePointer is a type alias for unsafe.Pointer for clarity
type unsafePointer = unsafe.Pointer
