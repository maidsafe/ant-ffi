--[[
  GraphEntry types for ant_ffi

  This module provides graph-based data structures:
  - GraphEntryAddress: Address for a graph entry
  - GraphEntry: Entry in a graph data structure
]]

local ffi = require("ffi")

local M = {}

M._lib = nil
M._helpers = nil
M._errors = nil

function M._init(lib, helpers, errors)
    M._lib = lib
    M._helpers = helpers
    M._errors = errors
end

-- =============================================================================
-- GraphEntryAddress
-- =============================================================================

local GraphEntryAddress = {}
GraphEntryAddress.__index = GraphEntryAddress

function GraphEntryAddress._wrap(handle)
    local self = setmetatable({}, GraphEntryAddress)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_graphentryaddress(h, status)
        end
    end)
    return self
end

function GraphEntryAddress.new(public_key)
    assert(M._lib, "graph_entry not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_graphentryaddress_new(public_key:_clone(), status)
    M._errors.check_status(status, "GraphEntryAddress.new")
    return GraphEntryAddress._wrap(handle)
end

function GraphEntryAddress.from_hex(hex)
    assert(M._lib, "graph_entry not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_graphentryaddress_from_hex(buf, status)
    M._errors.check_status(status, "GraphEntryAddress.from_hex")
    return GraphEntryAddress._wrap(handle)
end

function GraphEntryAddress:_clone()
    assert(not self._disposed, "GraphEntryAddress has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_graphentryaddress(self._handle, status)
    M._errors.check_status(status, "GraphEntryAddress.clone")
    return cloned
end

function GraphEntryAddress:to_hex()
    assert(not self._disposed, "GraphEntryAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_graphentryaddress_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "GraphEntryAddress.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function GraphEntryAddress:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_graphentryaddress(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.GraphEntryAddress = GraphEntryAddress

-- =============================================================================
-- GraphEntry
-- =============================================================================

local GraphEntry = {}
GraphEntry.__index = GraphEntry

function GraphEntry._wrap(handle)
    local self = setmetatable({}, GraphEntry)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_graphentry(h, status)
        end
    end)
    return self
end

--[[
  Create a new GraphEntry.
  @param owner (SecretKey) - Owner of the graph entry
  @param parents (string) - Serialized parent addresses
  @param content (string) - Content data
  @param descendants (string) - Serialized descendant addresses
  @return GraphEntry
]]
function GraphEntry.new(owner, parents, content, descendants)
    assert(M._lib, "graph_entry not initialized")
    local parents_buf = M._helpers.string_to_rustbuffer(parents)
    local content_buf = M._helpers.string_to_rustbuffer(content)
    local descendants_buf = M._helpers.string_to_rustbuffer(descendants)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_graphentry_new(
        owner:_clone(), parents_buf, content_buf, descendants_buf, status)
    M._errors.check_status(status, "GraphEntry.new")
    return GraphEntry._wrap(handle)
end

function GraphEntry:_clone()
    assert(not self._disposed, "GraphEntry has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_graphentry(self._handle, status)
    M._errors.check_status(status, "GraphEntry.clone")
    return cloned
end

function GraphEntry:address()
    assert(not self._disposed, "GraphEntry has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_graphentry_address(self:_clone(), status)
    M._errors.check_status(status, "GraphEntry.address")
    return GraphEntryAddress._wrap(handle)
end

function GraphEntry:content()
    assert(not self._disposed, "GraphEntry has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_graphentry_content(result, self:_clone(), status)
    M._errors.check_status(status, "GraphEntry.content")
    return M._helpers.rustbuffer_to_string(result[0])
end

function GraphEntry:parents()
    assert(not self._disposed, "GraphEntry has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_graphentry_parents(result, self:_clone(), status)
    M._errors.check_status(status, "GraphEntry.parents")
    return M._helpers.rustbuffer_to_string(result[0])
end

function GraphEntry:descendants()
    assert(not self._disposed, "GraphEntry has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_graphentry_descendants(result, self:_clone(), status)
    M._errors.check_status(status, "GraphEntry.descendants")
    return M._helpers.rustbuffer_to_string(result[0])
end

function GraphEntry:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_graphentry(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.GraphEntry = GraphEntry

return M
