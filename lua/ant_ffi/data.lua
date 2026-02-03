--[[
  Data types for ant_ffi

  This module provides data storage types:
  - Chunk: Content-addressable data storage
  - ChunkAddress: Address for chunks
  - DataAddress: Address for public data
  - DataMapChunk: Metadata for encrypted private data
]]

local ffi = require("ffi")

local M = {}

-- Will be set by init.lua
M._lib = nil
M._helpers = nil
M._errors = nil

-- Initialize module with dependencies
function M._init(lib, helpers, errors)
    M._lib = lib
    M._helpers = helpers
    M._errors = errors
end

-- =============================================================================
-- Constants
-- =============================================================================

--[[
  Get the maximum size of a chunk.
  @return number - Maximum chunk size in bytes
]]
function M.chunk_max_size()
    assert(M._lib, "data not initialized")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_func_chunk_max_size(status)
    M._errors.check_status(status, "chunk_max_size")
    return tonumber(result)
end

--[[
  Get the maximum raw size of chunk data.
  @return number - Maximum raw chunk size in bytes
]]
function M.chunk_max_raw_size()
    assert(M._lib, "data not initialized")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_func_chunk_max_raw_size(status)
    M._errors.check_status(status, "chunk_max_raw_size")
    return tonumber(result)
end

-- =============================================================================
-- Chunk
-- =============================================================================

local Chunk = {}
Chunk.__index = Chunk

function Chunk._wrap(handle)
    local self = setmetatable({}, Chunk)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_chunk(h, status)
        end
    end)
    return self
end

--[[
  Create a new Chunk from data.
  @param data (string) - The chunk data
  @return Chunk
]]
function Chunk.new(data)
    assert(M._lib, "data not initialized")
    local buf = M._helpers.string_to_rustbuffer(data)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_chunk_new(buf, status)
    M._errors.check_status(status, "Chunk.new")
    return Chunk._wrap(handle)
end

function Chunk:_clone()
    assert(not self._disposed, "Chunk has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_chunk(self._handle, status)
    M._errors.check_status(status, "Chunk.clone")
    return cloned
end

--[[
  Get the chunk value/data.
  @return string - The chunk data
]]
function Chunk:value()
    assert(not self._disposed, "Chunk has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_chunk_value(result, self:_clone(), status)
    M._errors.check_status(status, "Chunk.value")
    return M._helpers.rustbuffer_to_string(result[0])
end

--[[
  Get the chunk address.
  @return ChunkAddress
]]
function Chunk:address()
    assert(not self._disposed, "Chunk has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_chunk_address(self:_clone(), status)
    M._errors.check_status(status, "Chunk.address")
    return M.ChunkAddress._wrap(handle)
end

--[[
  Get the network address as hex string.
  @return string - Hex-encoded network address
]]
function Chunk:network_address()
    assert(not self._disposed, "Chunk has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_chunk_network_address(result, self:_clone(), status)
    M._errors.check_status(status, "Chunk.network_address")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

--[[
  Get the chunk size.
  @return number - Size in bytes
]]
function Chunk:size()
    assert(not self._disposed, "Chunk has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_chunk_size(self:_clone(), status)
    M._errors.check_status(status, "Chunk.size")
    return tonumber(result)
end

--[[
  Check if the chunk is too big for storage.
  @return boolean
]]
function Chunk:is_too_big()
    assert(not self._disposed, "Chunk has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_chunk_is_too_big(self:_clone(), status)
    M._errors.check_status(status, "Chunk.is_too_big")
    return result ~= 0
end

function Chunk:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_chunk(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.Chunk = Chunk

-- =============================================================================
-- ChunkAddress
-- =============================================================================

local ChunkAddress = {}
ChunkAddress.__index = ChunkAddress

function ChunkAddress._wrap(handle)
    local self = setmetatable({}, ChunkAddress)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_chunkaddress(h, status)
        end
    end)
    return self
end

--[[
  Create a ChunkAddress from raw bytes.
  @param bytes (table) - 32-byte address
  @return ChunkAddress
]]
function ChunkAddress.new(bytes)
    assert(M._lib, "data not initialized")
    local buf = M._helpers.bytes_to_rustbuffer(bytes)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_chunkaddress_new(buf, status)
    M._errors.check_status(status, "ChunkAddress.new")
    return ChunkAddress._wrap(handle)
end

--[[
  Create a ChunkAddress from content data (hash the content).
  @param data (string) - Content to hash
  @return ChunkAddress
]]
function ChunkAddress.from_content(data)
    assert(M._lib, "data not initialized")
    local buf = M._helpers.string_to_rustbuffer(data)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_chunkaddress_from_content(buf, status)
    M._errors.check_status(status, "ChunkAddress.from_content")
    return ChunkAddress._wrap(handle)
end

--[[
  Create a ChunkAddress from hex string.
  @param hex (string) - Hex-encoded address
  @return ChunkAddress
]]
function ChunkAddress.from_hex(hex)
    assert(M._lib, "data not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_chunkaddress_from_hex(buf, status)
    M._errors.check_status(status, "ChunkAddress.from_hex")
    return ChunkAddress._wrap(handle)
end

function ChunkAddress:_clone()
    assert(not self._disposed, "ChunkAddress has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_chunkaddress(self._handle, status)
    M._errors.check_status(status, "ChunkAddress.clone")
    return cloned
end

function ChunkAddress:to_hex()
    assert(not self._disposed, "ChunkAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_chunkaddress_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "ChunkAddress.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function ChunkAddress:to_bytes()
    assert(not self._disposed, "ChunkAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_chunkaddress_to_bytes(result, self:_clone(), status)
    M._errors.check_status(status, "ChunkAddress.to_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

function ChunkAddress:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_chunkaddress(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

function ChunkAddress:__tostring()
    if self._disposed then return "ChunkAddress(disposed)" end
    return string.format("ChunkAddress(%s...)", self:to_hex():sub(1, 16))
end

M.ChunkAddress = ChunkAddress

-- =============================================================================
-- DataAddress
-- =============================================================================

local DataAddress = {}
DataAddress.__index = DataAddress

function DataAddress._wrap(handle)
    local self = setmetatable({}, DataAddress)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_dataaddress(h, status)
        end
    end)
    return self
end

function DataAddress.new(bytes)
    assert(M._lib, "data not initialized")
    local buf = M._helpers.bytes_to_rustbuffer(bytes)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_dataaddress_new(buf, status)
    M._errors.check_status(status, "DataAddress.new")
    return DataAddress._wrap(handle)
end

function DataAddress.from_hex(hex)
    assert(M._lib, "data not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_dataaddress_from_hex(buf, status)
    M._errors.check_status(status, "DataAddress.from_hex")
    return DataAddress._wrap(handle)
end

function DataAddress:_clone()
    assert(not self._disposed, "DataAddress has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_dataaddress(self._handle, status)
    M._errors.check_status(status, "DataAddress.clone")
    return cloned
end

function DataAddress:to_hex()
    assert(not self._disposed, "DataAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_dataaddress_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "DataAddress.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function DataAddress:to_bytes()
    assert(not self._disposed, "DataAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_dataaddress_to_bytes(result, self:_clone(), status)
    M._errors.check_status(status, "DataAddress.to_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

function DataAddress:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_dataaddress(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

function DataAddress:__tostring()
    if self._disposed then return "DataAddress(disposed)" end
    return string.format("DataAddress(%s...)", self:to_hex():sub(1, 16))
end

M.DataAddress = DataAddress

-- =============================================================================
-- DataMapChunk
-- =============================================================================

local DataMapChunk = {}
DataMapChunk.__index = DataMapChunk

function DataMapChunk._wrap(handle)
    local self = setmetatable({}, DataMapChunk)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_datamapchunk(h, status)
        end
    end)
    return self
end

--[[
  Create a DataMapChunk from hex string.
  @param hex (string) - Hex-encoded data map
  @return DataMapChunk
]]
function DataMapChunk.from_hex(hex)
    assert(M._lib, "data not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_datamapchunk_from_hex(buf, status)
    M._errors.check_status(status, "DataMapChunk.from_hex")
    return DataMapChunk._wrap(handle)
end

function DataMapChunk:_clone()
    assert(not self._disposed, "DataMapChunk has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_datamapchunk(self._handle, status)
    M._errors.check_status(status, "DataMapChunk.clone")
    return cloned
end

function DataMapChunk:to_hex()
    assert(not self._disposed, "DataMapChunk has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_datamapchunk_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "DataMapChunk.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function DataMapChunk:address()
    assert(not self._disposed, "DataMapChunk has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_datamapchunk_address(result, self:_clone(), status)
    M._errors.check_status(status, "DataMapChunk.address")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function DataMapChunk:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_datamapchunk(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

function DataMapChunk:__tostring()
    if self._disposed then return "DataMapChunk(disposed)" end
    return string.format("DataMapChunk(%s...)", self:to_hex():sub(1, 16))
end

M.DataMapChunk = DataMapChunk

return M
