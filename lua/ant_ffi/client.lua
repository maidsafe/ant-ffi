--[[
  Client for ant_ffi

  This module provides the main Client type for interacting with
  the Autonomi network. Client operations are async and use
  the async_helper library for thread-safe callback handling.

  The async_helper library (written in Rust) provides atomic operations
  for storing callback results, avoiding LuaJIT's callback thread-safety
  issues with UniFFI's async futures.

  All operations are blocking (synchronous from Lua's perspective).
]]

local ffi = require("ffi")

local M = {}

M._lib = nil
M._helpers = nil
M._errors = nil
M._async_helper = nil
M._async_available = false

function M._init(lib, helpers, errors)
    M._lib = lib
    M._helpers = helpers
    M._errors = errors

    -- Try to load the async helper
    local ok, async_helper = pcall(require, "ant_ffi.async_helper")
    if ok then
        local available, err = async_helper.is_available()
        if available then
            M._async_helper = async_helper
            M._async_available = true
        end
    end
end

-- =============================================================================
-- Async Future Polling Helpers (using async_helper)
-- =============================================================================

-- Simple blocking poll for pointer futures
local function poll_pointer_sync(lib, future_handle)
    if not M._async_available then
        error("async_helper not available - cannot perform async operations. " ..
              "Build the async_helper library first: cd lua/async_helper && cargo build --release")
    end
    return M._async_helper.poll_pointer_sync(lib, future_handle)
end

-- Simple blocking poll for RustBuffer futures
local function poll_rust_buffer_sync(lib, future_handle)
    if not M._async_available then
        error("async_helper not available - cannot perform async operations. " ..
              "Build the async_helper library first: cd lua/async_helper && cargo build --release")
    end
    return M._async_helper.poll_rust_buffer_sync(lib, future_handle)
end

-- Simple blocking poll for void futures
local function poll_void_sync(lib, future_handle)
    if not M._async_available then
        error("async_helper not available - cannot perform async operations. " ..
              "Build the async_helper library first: cd lua/async_helper && cargo build --release")
    end
    return M._async_helper.poll_void_sync(lib, future_handle)
end

--[[
  Check if async operations are available.
  @return boolean, string - true if available, false with error message otherwise
]]
function M.is_async_available()
    if M._async_available then
        return true
    else
        return false, "async_helper not loaded. Build it with: cd lua/async_helper && cargo build --release"
    end
end

-- =============================================================================
-- Client
-- =============================================================================

local Client = {}
Client.__index = Client

function Client._wrap(handle)
    local self = setmetatable({}, Client)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_client(h, status)
        end
    end)
    return self
end

--[[
  Initialize a Client for mainnet (blocking).
  @return Client
]]
function Client.init()
    assert(M._lib, "client not initialized")
    local future = M._lib.uniffi_ant_ffi_fn_constructor_client_init()
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.init")
    return Client._wrap(handle)
end

--[[
  Initialize a Client for local testnet (blocking).
  @return Client
]]
function Client.init_local()
    assert(M._lib, "client not initialized")
    local future = M._lib.uniffi_ant_ffi_fn_constructor_client_init_local()
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.init_local")
    return Client._wrap(handle)
end

function Client:_clone()
    assert(not self._disposed, "Client has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_client(self._handle, status)
    M._errors.check_status(status, "Client.clone")
    return cloned
end

-- =============================================================================
-- Data Operations
-- =============================================================================

--[[
  Store public data on the network (blocking).
  @param data (string) - Data to store
  @param wallet (Wallet) - Wallet for payment
  @return DataAddress, string (address, cost)
]]
function Client:data_put_public(data, wallet)
    assert(not self._disposed, "Client has been disposed")
    local data_mod = require("ant_ffi.data")
    local bit = require("bit")

    local data_buf = M._helpers.string_to_rustbuffer(data)
    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_data_put_public(
        self:_clone(), data_buf, payment_buf)
    -- Returns RustBuffer containing UploadResult { price: String, address: String }
    local result_buf, status = poll_rust_buffer_sync(M._lib, future)
    M._errors.check_status(status, "Client.data_put_public")

    -- Deserialize UploadResult: two strings with 4-byte BE length prefixes
    -- Read price string
    local price_len = bit.bor(
        bit.lshift(result_buf.data[0], 24),
        bit.lshift(result_buf.data[1], 16),
        bit.lshift(result_buf.data[2], 8),
        result_buf.data[3]
    )
    local price = ffi.string(result_buf.data + 4, price_len)

    -- Read address string (starts after price)
    local offset = 4 + price_len
    local addr_len = bit.bor(
        bit.lshift(result_buf.data[offset], 24),
        bit.lshift(result_buf.data[offset + 1], 16),
        bit.lshift(result_buf.data[offset + 2], 8),
        result_buf.data[offset + 3]
    )
    local address_hex = ffi.string(result_buf.data + offset + 4, addr_len)

    M._helpers.free_rustbuffer(result_buf)

    return data_mod.DataAddress.from_hex(address_hex), price
end

--[[
  Get public data from the network (blocking).
  @param address_hex (string) - Hex-encoded address
  @return string - The data
]]
function Client:data_get_public(address_hex)
    assert(not self._disposed, "Client has been disposed")

    -- Use raw_string_to_rustbuffer (no length prefix) to match C# StringToRustBuffer
    local addr_buf = M._helpers.raw_string_to_rustbuffer(address_hex)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_data_get_public(
        self:_clone(), addr_buf)
    local result, status = poll_rust_buffer_sync(M._lib, future)
    M._errors.check_status(status, "Client.data_get_public")

    return M._helpers.rustbuffer_to_string(result)
end

--[[
  Store private (encrypted) data on the network (blocking).
  @param data (string) - Data to store
  @param wallet (Wallet) - Wallet for payment
  @return DataMapChunk
]]
function Client:data_put(data, wallet)
    assert(not self._disposed, "Client has been disposed")
    local data_mod = require("ant_ffi.data")

    local data_buf = M._helpers.string_to_rustbuffer(data)
    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_data_put(
        self:_clone(), data_buf, payment_buf)
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.data_put")

    return data_mod.DataMapChunk._wrap(handle)
end

--[[
  Get private (encrypted) data from the network (blocking).
  @param data_map_chunk (DataMapChunk) - Data map for the encrypted data
  @return string - The decrypted data
]]
function Client:data_get(data_map_chunk)
    assert(not self._disposed, "Client has been disposed")

    local future = M._lib.uniffi_ant_ffi_fn_method_client_data_get(
        self:_clone(), data_map_chunk:_clone())
    local result, status = poll_rust_buffer_sync(M._lib, future)
    M._errors.check_status(status, "Client.data_get")

    return M._helpers.rustbuffer_to_string(result)
end

--[[
  Get the estimated cost to store data on the network (blocking).
  @param data (string) - Data to estimate cost for
  @return string - The estimated cost in tokens
]]
function Client:data_cost(data)
    assert(not self._disposed, "Client has been disposed")

    local data_buf = M._helpers.string_to_rustbuffer(data)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_data_cost(
        self:_clone(), data_buf)
    local result, status = poll_rust_buffer_sync(M._lib, future)
    M._errors.check_status(status, "Client.data_cost")

    return M._helpers.rustbuffer_to_string(result)
end

-- =============================================================================
-- Chunk Operations
-- =============================================================================

--[[
  Store a chunk on the network (blocking).
  @param data (string) - Chunk data
  @param wallet (Wallet) - Wallet for payment
  @return ChunkAddress
]]
function Client:chunk_put(data, wallet)
    assert(not self._disposed, "Client has been disposed")
    local data_mod = require("ant_ffi.data")

    local data_buf = M._helpers.string_to_rustbuffer(data)
    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_chunk_put(
        self:_clone(), data_buf, payment_buf)
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.chunk_put")

    return data_mod.ChunkAddress._wrap(handle)
end

--[[
  Get a chunk from the network (blocking).
  @param address (ChunkAddress) - Address of the chunk
  @return Chunk
]]
function Client:chunk_get(address)
    assert(not self._disposed, "Client has been disposed")
    local data_mod = require("ant_ffi.data")

    local future = M._lib.uniffi_ant_ffi_fn_method_client_chunk_get(
        self:_clone(), address:_clone())
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.chunk_get")

    return data_mod.Chunk._wrap(handle)
end

-- =============================================================================
-- Pointer Operations
-- =============================================================================

--[[
  Get a pointer from the network (blocking).
  @param address (PointerAddress) - Address of the pointer
  @return NetworkPointer
]]
function Client:pointer_get(address)
    assert(not self._disposed, "Client has been disposed")
    local pointer_mod = require("ant_ffi.pointer")

    local future = M._lib.uniffi_ant_ffi_fn_method_client_pointer_get(
        self:_clone(), address:_clone())
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.pointer_get")

    return pointer_mod.NetworkPointer._wrap(handle)
end

--[[
  Store a pointer on the network (blocking).
  @param pointer (NetworkPointer) - Pointer to store
  @param wallet (Wallet) - Wallet for payment
]]
function Client:pointer_put(pointer, wallet)
    assert(not self._disposed, "Client has been disposed")

    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_pointer_put(
        self:_clone(), pointer:_clone(), payment_buf)
    local status = poll_void_sync(M._lib, future)
    M._errors.check_status(status, "Client.pointer_put")
end

-- =============================================================================
-- Scratchpad Operations
-- =============================================================================

--[[
  Get a scratchpad from the network (blocking).
  @param address (ScratchpadAddress) - Address of the scratchpad
  @return Scratchpad
]]
function Client:scratchpad_get(address)
    assert(not self._disposed, "Client has been disposed")
    local scratchpad_mod = require("ant_ffi.scratchpad")

    local future = M._lib.uniffi_ant_ffi_fn_method_client_scratchpad_get(
        self:_clone(), address:_clone())
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.scratchpad_get")

    return scratchpad_mod.Scratchpad._wrap(handle)
end

--[[
  Store a scratchpad on the network (blocking).
  @param scratchpad (Scratchpad) - Scratchpad to store
  @param wallet (Wallet) - Wallet for payment
]]
function Client:scratchpad_put(scratchpad, wallet)
    assert(not self._disposed, "Client has been disposed")

    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_scratchpad_put(
        self:_clone(), scratchpad:_clone(), payment_buf)
    local status = poll_void_sync(M._lib, future)
    M._errors.check_status(status, "Client.scratchpad_put")
end

-- =============================================================================
-- Register Operations
-- =============================================================================

--[[
  Get a register value from the network (blocking).
  @param address (RegisterAddress) - Address of the register
  @return string - Register value
]]
function Client:register_get(address)
    assert(not self._disposed, "Client has been disposed")

    local future = M._lib.uniffi_ant_ffi_fn_method_client_register_get(
        self:_clone(), address:_clone())
    local result, status = poll_rust_buffer_sync(M._lib, future)
    M._errors.check_status(status, "Client.register_get")

    return M._helpers.rustbuffer_to_string(result)
end

--[[
  Create a register on the network (blocking).
  @param owner (SecretKey) - Owner of the register
  @param value (string) - Initial value
  @param wallet (Wallet) - Wallet for payment
  @return RegisterAddress
]]
function Client:register_create(owner, value, wallet)
    assert(not self._disposed, "Client has been disposed")
    local register_mod = require("ant_ffi.register")

    local value_buf = M._helpers.string_to_rustbuffer(value)
    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_register_create(
        self:_clone(), owner:_clone(), value_buf, payment_buf)
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.register_create")

    return register_mod.RegisterAddress._wrap(handle)
end

--[[
  Update a register on the network (blocking).
  @param owner (SecretKey) - Owner of the register
  @param value (string) - New value
  @param wallet (Wallet) - Wallet for payment
]]
function Client:register_update(owner, value, wallet)
    assert(not self._disposed, "Client has been disposed")

    local value_buf = M._helpers.string_to_rustbuffer(value)
    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_register_update(
        self:_clone(), owner:_clone(), value_buf, payment_buf)
    local status = poll_void_sync(M._lib, future)
    M._errors.check_status(status, "Client.register_update")
end

-- =============================================================================
-- Graph Entry Operations
-- =============================================================================

--[[
  Get a graph entry from the network (blocking).
  @param address (GraphEntryAddress) - Address of the graph entry
  @return GraphEntry
]]
function Client:graph_entry_get(address)
    assert(not self._disposed, "Client has been disposed")
    local graph_mod = require("ant_ffi.graph_entry")

    local future = M._lib.uniffi_ant_ffi_fn_method_client_graph_entry_get(
        self:_clone(), address:_clone())
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.graph_entry_get")

    return graph_mod.GraphEntry._wrap(handle)
end

--[[
  Store a graph entry on the network (blocking).
  @param entry (GraphEntry) - Entry to store
  @param wallet (Wallet) - Wallet for payment
]]
function Client:graph_entry_put(entry, wallet)
    assert(not self._disposed, "Client has been disposed")

    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_graph_entry_put(
        self:_clone(), entry:_clone(), payment_buf)
    local status = poll_void_sync(M._lib, future)
    M._errors.check_status(status, "Client.graph_entry_put")
end

-- =============================================================================
-- Archive Operations
-- =============================================================================

--[[
  Get a public archive from the network (blocking).
  @param address (ArchiveAddress) - Address of the archive
  @return PublicArchive
]]
function Client:archive_get_public(address)
    assert(not self._disposed, "Client has been disposed")
    local archive_mod = require("ant_ffi.archive")

    local future = M._lib.uniffi_ant_ffi_fn_method_client_archive_get_public(
        self:_clone(), address:_clone())
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.archive_get_public")

    return archive_mod.PublicArchive._wrap(handle)
end

--[[
  Store a public archive on the network (blocking).
  @param archive (PublicArchive) - Archive to store
  @param wallet (Wallet) - Wallet for payment
  @return ArchiveAddress
]]
function Client:archive_put_public(archive, wallet)
    assert(not self._disposed, "Client has been disposed")
    local archive_mod = require("ant_ffi.archive")

    local payment_buf = M._helpers.lower_payment_option(wallet)

    local future = M._lib.uniffi_ant_ffi_fn_method_client_archive_put_public(
        self:_clone(), archive:_clone(), payment_buf)
    local handle, status = poll_pointer_sync(M._lib, future)
    M._errors.check_status(status, "Client.archive_put_public")

    return archive_mod.ArchiveAddress._wrap(handle)
end

function Client:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_client(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.Client = Client

return M
