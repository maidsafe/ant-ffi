--[[
  Pointer types for ant_ffi

  This module provides mutable pointer types:
  - PointerAddress: Address for a pointer
  - PointerTarget: Target of a pointer (chunk, pointer, graph entry, or scratchpad)
  - NetworkPointer: Mutable pointer to network data
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
-- PointerAddress
-- =============================================================================

local PointerAddress = {}
PointerAddress.__index = PointerAddress

function PointerAddress._wrap(handle)
    local self = setmetatable({}, PointerAddress)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_pointeraddress(h, status)
        end
    end)
    return self
end

function PointerAddress.new(public_key)
    assert(M._lib, "pointer not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_pointeraddress_new(public_key:_clone(), status)
    M._errors.check_status(status, "PointerAddress.new")
    return PointerAddress._wrap(handle)
end

function PointerAddress.from_hex(hex)
    assert(M._lib, "pointer not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_pointeraddress_from_hex(buf, status)
    M._errors.check_status(status, "PointerAddress.from_hex")
    return PointerAddress._wrap(handle)
end

function PointerAddress:_clone()
    assert(not self._disposed, "PointerAddress has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_pointeraddress(self._handle, status)
    M._errors.check_status(status, "PointerAddress.clone")
    return cloned
end

function PointerAddress:owner()
    assert(not self._disposed, "PointerAddress has been disposed")
    local keys = require("ant_ffi.keys")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_pointeraddress_owner(self:_clone(), status)
    M._errors.check_status(status, "PointerAddress.owner")
    return keys.PublicKey._wrap(handle)
end

function PointerAddress:to_hex()
    assert(not self._disposed, "PointerAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_pointeraddress_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "PointerAddress.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function PointerAddress:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_pointeraddress(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.PointerAddress = PointerAddress

-- =============================================================================
-- PointerTarget
-- =============================================================================

local PointerTarget = {}
PointerTarget.__index = PointerTarget

function PointerTarget._wrap(handle)
    local self = setmetatable({}, PointerTarget)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_pointertarget(h, status)
        end
    end)
    return self
end

function PointerTarget.chunk(chunk_address)
    assert(M._lib, "pointer not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_pointertarget_chunk(chunk_address:_clone(), status)
    M._errors.check_status(status, "PointerTarget.chunk")
    return PointerTarget._wrap(handle)
end

function PointerTarget.pointer(pointer_address)
    assert(M._lib, "pointer not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_pointertarget_pointer(pointer_address:_clone(), status)
    M._errors.check_status(status, "PointerTarget.pointer")
    return PointerTarget._wrap(handle)
end

function PointerTarget.graph_entry(graph_entry_address)
    assert(M._lib, "pointer not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_pointertarget_graph_entry(graph_entry_address:_clone(), status)
    M._errors.check_status(status, "PointerTarget.graph_entry")
    return PointerTarget._wrap(handle)
end

function PointerTarget.scratchpad(scratchpad_address)
    assert(M._lib, "pointer not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_pointertarget_scratchpad(scratchpad_address:_clone(), status)
    M._errors.check_status(status, "PointerTarget.scratchpad")
    return PointerTarget._wrap(handle)
end

function PointerTarget:_clone()
    assert(not self._disposed, "PointerTarget has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_pointertarget(self._handle, status)
    M._errors.check_status(status, "PointerTarget.clone")
    return cloned
end

function PointerTarget:to_hex()
    assert(not self._disposed, "PointerTarget has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_pointertarget_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "PointerTarget.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function PointerTarget:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_pointertarget(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.PointerTarget = PointerTarget

-- =============================================================================
-- NetworkPointer
-- =============================================================================

local NetworkPointer = {}
NetworkPointer.__index = NetworkPointer

function NetworkPointer._wrap(handle)
    local self = setmetatable({}, NetworkPointer)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_networkpointer(h, status)
        end
    end)
    return self
end

function NetworkPointer.new(secret_key, counter, target)
    assert(M._lib, "pointer not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_networkpointer_new(
        secret_key:_clone(), counter, target:_clone(), status)
    M._errors.check_status(status, "NetworkPointer.new")
    return NetworkPointer._wrap(handle)
end

function NetworkPointer:_clone()
    assert(not self._disposed, "NetworkPointer has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_networkpointer(self._handle, status)
    M._errors.check_status(status, "NetworkPointer.clone")
    return cloned
end

function NetworkPointer:address()
    assert(not self._disposed, "NetworkPointer has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_networkpointer_address(self:_clone(), status)
    M._errors.check_status(status, "NetworkPointer.address")
    return PointerAddress._wrap(handle)
end

function NetworkPointer:target()
    assert(not self._disposed, "NetworkPointer has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_networkpointer_target(self:_clone(), status)
    M._errors.check_status(status, "NetworkPointer.target")
    return PointerTarget._wrap(handle)
end

function NetworkPointer:counter()
    assert(not self._disposed, "NetworkPointer has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_networkpointer_counter(self:_clone(), status)
    M._errors.check_status(status, "NetworkPointer.counter")
    return tonumber(result)
end

function NetworkPointer:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_networkpointer(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.NetworkPointer = NetworkPointer

return M
