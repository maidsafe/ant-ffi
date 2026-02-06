--[[
  Scratchpad types for ant_ffi

  This module provides encrypted mutable storage types:
  - ScratchpadAddress: Address for a scratchpad
  - Scratchpad: Encrypted mutable data with versioning
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
-- ScratchpadAddress
-- =============================================================================

local ScratchpadAddress = {}
ScratchpadAddress.__index = ScratchpadAddress

function ScratchpadAddress._wrap(handle)
    local self = setmetatable({}, ScratchpadAddress)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_scratchpadaddress(h, status)
        end
    end)
    return self
end

function ScratchpadAddress.new(public_key)
    assert(M._lib, "scratchpad not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_scratchpadaddress_new(public_key:_clone(), status)
    M._errors.check_status(status, "ScratchpadAddress.new")
    return ScratchpadAddress._wrap(handle)
end

function ScratchpadAddress.from_hex(hex)
    assert(M._lib, "scratchpad not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_scratchpadaddress_from_hex(buf, status)
    M._errors.check_status(status, "ScratchpadAddress.from_hex")
    return ScratchpadAddress._wrap(handle)
end

function ScratchpadAddress:_clone()
    assert(not self._disposed, "ScratchpadAddress has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_scratchpadaddress(self._handle, status)
    M._errors.check_status(status, "ScratchpadAddress.clone")
    return cloned
end

function ScratchpadAddress:owner()
    assert(not self._disposed, "ScratchpadAddress has been disposed")
    local keys = require("ant_ffi.keys")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_scratchpadaddress_owner(self:_clone(), status)
    M._errors.check_status(status, "ScratchpadAddress.owner")
    return keys.PublicKey._wrap(handle)
end

function ScratchpadAddress:to_hex()
    assert(not self._disposed, "ScratchpadAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_scratchpadaddress_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "ScratchpadAddress.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function ScratchpadAddress:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_scratchpadaddress(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.ScratchpadAddress = ScratchpadAddress

-- =============================================================================
-- Scratchpad
-- =============================================================================

local Scratchpad = {}
Scratchpad.__index = Scratchpad

function Scratchpad._wrap(handle)
    local self = setmetatable({}, Scratchpad)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_scratchpad(h, status)
        end
    end)
    return self
end

--[[
  Create a new Scratchpad.
  @param owner (SecretKey) - Owner of the scratchpad
  @param data_encoding (number) - Encoding type for the data
  @param data (string) - The data to store
  @param counter (number) - Version counter
  @return Scratchpad
]]
function Scratchpad.new(owner, data_encoding, data, counter)
    assert(M._lib, "scratchpad not initialized")
    local data_buf = M._helpers.string_to_rustbuffer(data)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_scratchpad_new(
        owner:_clone(), data_encoding, data_buf, counter, status)
    M._errors.check_status(status, "Scratchpad.new")
    return Scratchpad._wrap(handle)
end

function Scratchpad:_clone()
    assert(not self._disposed, "Scratchpad has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_scratchpad(self._handle, status)
    M._errors.check_status(status, "Scratchpad.clone")
    return cloned
end

function Scratchpad:address()
    assert(not self._disposed, "Scratchpad has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_scratchpad_address(self:_clone(), status)
    M._errors.check_status(status, "Scratchpad.address")
    return ScratchpadAddress._wrap(handle)
end

function Scratchpad:data_encoding()
    assert(not self._disposed, "Scratchpad has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_scratchpad_data_encoding(self:_clone(), status)
    M._errors.check_status(status, "Scratchpad.data_encoding")
    return tonumber(result)
end

function Scratchpad:counter()
    assert(not self._disposed, "Scratchpad has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_scratchpad_counter(self:_clone(), status)
    M._errors.check_status(status, "Scratchpad.counter")
    return tonumber(result)
end

function Scratchpad:owner()
    assert(not self._disposed, "Scratchpad has been disposed")
    local keys = require("ant_ffi.keys")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_scratchpad_owner(self:_clone(), status)
    M._errors.check_status(status, "Scratchpad.owner")
    return keys.PublicKey._wrap(handle)
end

function Scratchpad:encrypted_data()
    assert(not self._disposed, "Scratchpad has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_scratchpad_encrypted_data(result, self:_clone(), status)
    M._errors.check_status(status, "Scratchpad.encrypted_data")
    return M._helpers.rustbuffer_to_string(result[0])
end

function Scratchpad:decrypt_data(secret_key)
    assert(not self._disposed, "Scratchpad has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_scratchpad_decrypt_data(result, self:_clone(), secret_key:_clone(), status)
    M._errors.check_status(status, "Scratchpad.decrypt_data")
    return M._helpers.rustbuffer_to_string(result[0])
end

function Scratchpad:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_scratchpad(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.Scratchpad = Scratchpad

return M
