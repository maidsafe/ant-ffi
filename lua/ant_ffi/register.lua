--[[
  Register types for ant_ffi

  This module provides mutable versioned storage:
  - RegisterAddress: Address for a register
  - Helper functions for register keys and values
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
-- RegisterAddress
-- =============================================================================

local RegisterAddress = {}
RegisterAddress.__index = RegisterAddress

function RegisterAddress._wrap(handle)
    local self = setmetatable({}, RegisterAddress)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_registeraddress(h, status)
        end
    end)
    return self
end

function RegisterAddress.new(owner)
    assert(M._lib, "register not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_registeraddress_new(owner:_clone(), status)
    M._errors.check_status(status, "RegisterAddress.new")
    return RegisterAddress._wrap(handle)
end

function RegisterAddress.from_hex(hex)
    assert(M._lib, "register not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_registeraddress_from_hex(buf, status)
    M._errors.check_status(status, "RegisterAddress.from_hex")
    return RegisterAddress._wrap(handle)
end

function RegisterAddress:_clone()
    assert(not self._disposed, "RegisterAddress has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_registeraddress(self._handle, status)
    M._errors.check_status(status, "RegisterAddress.clone")
    return cloned
end

function RegisterAddress:owner()
    assert(not self._disposed, "RegisterAddress has been disposed")
    local keys = require("ant_ffi.keys")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_registeraddress_owner(self:_clone(), status)
    M._errors.check_status(status, "RegisterAddress.owner")
    return keys.PublicKey._wrap(handle)
end

function RegisterAddress:to_hex()
    assert(not self._disposed, "RegisterAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_registeraddress_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "RegisterAddress.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function RegisterAddress:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_registeraddress(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.RegisterAddress = RegisterAddress

-- =============================================================================
-- Helper Functions
-- =============================================================================

--[[
  Create a register key from owner and name.
  @param owner (SecretKey) - Owner of the register
  @param name (string) - Name for the register
  @return PublicKey - The derived key for this register
]]
function M.key_from_name(owner, name)
    assert(M._lib, "register not initialized")
    local keys = require("ant_ffi.keys")
    local name_buf = M._helpers.string_to_rustbuffer(name)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_func_register_key_from_name(owner:_clone(), name_buf, status)
    M._errors.check_status(status, "register_key_from_name")
    return keys.PublicKey._wrap(handle)
end

--[[
  Create a register value from bytes.
  @param bytes (string) - Raw bytes to use as value
  @return string - Serialized register value (32 bytes)
]]
function M.value_from_bytes(bytes)
    assert(M._lib, "register not initialized")
    local buf = M._helpers.string_to_rustbuffer(bytes)
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_func_register_value_from_bytes(result, buf, status)
    M._errors.check_status(status, "register_value_from_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

return M
