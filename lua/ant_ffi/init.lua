--[[
  Lua FFI Bindings for Autonomi Network (ant_ffi)

  This is the main entry point for the ant_ffi Lua bindings.
  It initializes all modules and exports the public API.

  STABLE FEATURES:
    - Self-encryption (encrypt/decrypt)
    - Key management (SecretKey, PublicKey)
    - Key derivation (MainSecretKey, DerivedSecretKey, etc.)
    - Data structures (Chunk, ChunkAddress, DataAddress, DataMapChunk)
    - Pointer types (PointerAddress, PointerTarget, NetworkPointer)
    - Scratchpad types (ScratchpadAddress, Scratchpad)
    - Register types (RegisterAddress, key_from_name, value_from_bytes)
    - Graph entry types (GraphEntryAddress, GraphEntry)
    - Archive types (Metadata, PublicArchive, PrivateArchive)
    - Wallet types (VaultSecretKey, UserData)
    - Network operations (Client.init, data_put, data_get, etc.)
      (requires async_helper library)

  ASYNC HELPER REQUIREMENT:
    Network operations require the async_helper library to provide
    thread-safe callback handling for UniFFI async futures.

    Build it with:
      cd lua/async_helper && cargo build --release

    The async_helper library uses atomic operations to safely store
    callback results from Rust worker threads.

  Usage:
    local ant = require("ant_ffi")

    -- Self-encryption
    local encrypted = ant.encrypt("Hello, Autonomi!")
    local decrypted = ant.decrypt(encrypted)

    -- Keys
    local key = ant.SecretKey.random()
    print(key:to_hex())
    local pubkey = key:public_key()

    -- Key derivation
    local main_key = ant.MainSecretKey.random()
    local derived = main_key:random_derived_key()

    -- Network operations (requires async_helper)
    local client = ant.Client.init_local()
    -- ... use client for data operations ...
    client:dispose()
]]

-- Load native library and FFI definitions
local native = require("ant_ffi.native")
local helpers = require("ant_ffi.helpers")
local errors = require("ant_ffi.errors")

-- Initialize core modules with native library
helpers.init(native.lib)
errors.init(native.lib)

-- Load all domain modules
local self_encryption = require("ant_ffi.self_encryption")
local keys = require("ant_ffi.keys")
local key_derivation = require("ant_ffi.key_derivation")
local data = require("ant_ffi.data")
local pointer = require("ant_ffi.pointer")
local scratchpad = require("ant_ffi.scratchpad")
local register = require("ant_ffi.register")
local graph_entry = require("ant_ffi.graph_entry")
local archive = require("ant_ffi.archive")
local network = require("ant_ffi.network")
local wallet = require("ant_ffi.wallet")
local client = require("ant_ffi.client")

-- Initialize all domain modules with native library
self_encryption._init(native.lib, helpers, errors)
keys._init(native.lib, helpers, errors)
key_derivation._init(native.lib, helpers, errors)
data._init(native.lib, helpers, errors)
pointer._init(native.lib, helpers, errors)
scratchpad._init(native.lib, helpers, errors)
register._init(native.lib, helpers, errors)
graph_entry._init(native.lib, helpers, errors)
archive._init(native.lib, helpers, errors)
network._init(native.lib, helpers, errors)
wallet._init(native.lib, helpers, errors)
client._init(native.lib, helpers, errors)

-- Build public API
local M = {}

-- Version info
M.VERSION = "0.0.1"

-- =============================================================================
-- Self-Encryption
-- =============================================================================

M.encrypt = self_encryption.encrypt
M.decrypt = self_encryption.decrypt
M.encrypt_bytes = self_encryption.encrypt_bytes
M.decrypt_bytes = self_encryption.decrypt_bytes

-- =============================================================================
-- Keys
-- =============================================================================

M.SecretKey = keys.SecretKey
M.PublicKey = keys.PublicKey

-- =============================================================================
-- Key Derivation
-- =============================================================================

M.DerivationIndex = key_derivation.DerivationIndex
M.Signature = key_derivation.Signature
M.MainSecretKey = key_derivation.MainSecretKey
M.MainPubkey = key_derivation.MainPubkey
M.DerivedSecretKey = key_derivation.DerivedSecretKey
M.DerivedPubkey = key_derivation.DerivedPubkey

-- =============================================================================
-- Data Types
-- =============================================================================

M.Chunk = data.Chunk
M.ChunkAddress = data.ChunkAddress
M.DataAddress = data.DataAddress
M.DataMapChunk = data.DataMapChunk
M.chunk_max_size = data.chunk_max_size
M.chunk_max_raw_size = data.chunk_max_raw_size

-- =============================================================================
-- Pointer Types
-- =============================================================================

M.PointerAddress = pointer.PointerAddress
M.PointerTarget = pointer.PointerTarget
M.NetworkPointer = pointer.NetworkPointer

-- =============================================================================
-- Scratchpad Types
-- =============================================================================

M.ScratchpadAddress = scratchpad.ScratchpadAddress
M.Scratchpad = scratchpad.Scratchpad

-- =============================================================================
-- Register Types
-- =============================================================================

M.RegisterAddress = register.RegisterAddress
M.register_key_from_name = register.key_from_name
M.register_value_from_bytes = register.value_from_bytes

-- =============================================================================
-- Graph Entry Types
-- =============================================================================

M.GraphEntryAddress = graph_entry.GraphEntryAddress
M.GraphEntry = graph_entry.GraphEntry

-- =============================================================================
-- Archive Types
-- =============================================================================

M.Metadata = archive.Metadata
M.ArchiveAddress = archive.ArchiveAddress
M.PrivateArchiveDataMap = archive.PrivateArchiveDataMap
M.PublicArchive = archive.PublicArchive
M.PrivateArchive = archive.PrivateArchive

-- =============================================================================
-- Network & Wallet
-- =============================================================================

M.Network = network.Network
M.Wallet = wallet.Wallet
M.VaultSecretKey = wallet.VaultSecretKey
M.UserData = wallet.UserData

-- =============================================================================
-- Client
-- =============================================================================

M.Client = client.Client

-- =============================================================================
-- Internal/Advanced
-- =============================================================================

-- Expose internal modules for advanced usage
M._internal = {
    native = native,
    helpers = helpers,
    errors = errors,
    ffi = require("ffi"),
}

return M
