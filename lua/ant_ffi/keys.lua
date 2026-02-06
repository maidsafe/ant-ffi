--[[
  Cryptographic keys for ant_ffi

  This module provides SecretKey and PublicKey types for
  BLS cryptographic operations.
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
-- SecretKey
-- =============================================================================

local SecretKey = {}
SecretKey.__index = SecretKey

--[[
  Create a new SecretKey wrapper.
  Internal - use SecretKey.random() or SecretKey.from_hex() instead.
]]
function SecretKey._wrap(handle)
    local self = setmetatable({}, SecretKey)
    self._handle = handle
    self._disposed = false

    -- Register GC callback to free the handle
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_secretkey(h, status)
        end
    end)

    return self
end

--[[
  Create a new random SecretKey.

  @return SecretKey - A new randomly generated secret key
  @raises error if key generation fails
]]
function SecretKey.random()
    assert(M._lib, "keys not initialized")

    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_secretkey_random(status)
    M._errors.check_status(status, "SecretKey.random")

    return SecretKey._wrap(handle)
end

--[[
  Create a SecretKey from a hex string.

  @param hex (string) - The hex-encoded secret key
  @return SecretKey - The secret key
  @raises error if the hex string is invalid
]]
function SecretKey.from_hex(hex)
    assert(M._lib, "keys not initialized")
    assert(type(hex) == "string", "hex must be a string")

    -- from_hex expects raw hex string (no UniFFI length prefix)
    local hex_buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_secretkey_from_hex(hex_buf, status)
    M._errors.check_status(status, "SecretKey.from_hex")

    return SecretKey._wrap(handle)
end

--[[
  Check if this key has been disposed.
]]
function SecretKey:is_disposed()
    return self._disposed
end

--[[
  Clone the internal handle for passing to FFI.
  Required because UniFFI consumes one Arc reference per call.
]]
function SecretKey:_clone()
    assert(not self._disposed, "SecretKey has been disposed")

    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_secretkey(self._handle, status)
    M._errors.check_status(status, "SecretKey.clone")

    return cloned
end

--[[
  Get the raw handle (for internal use).
  The handle is cloned to maintain proper reference counting.
]]
function SecretKey:_get_handle()
    return self:_clone()
end

--[[
  Convert the secret key to a hex string.

  @return string - The hex-encoded secret key
]]
function SecretKey:to_hex()
    assert(not self._disposed, "SecretKey has been disposed")

    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_secretkey_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "SecretKey.to_hex")

    -- to_hex returns raw string data (not UniFFI serialized)
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

--[[
  Get the PublicKey corresponding to this SecretKey.

  @return PublicKey - The public key
]]
function SecretKey:public_key()
    assert(not self._disposed, "SecretKey has been disposed")

    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_secretkey_public_key(self:_clone(), status)
    M._errors.check_status(status, "SecretKey.public_key")

    return M.PublicKey._wrap(handle)
end

--[[
  Explicitly dispose of this key (optional - GC handles it automatically).
]]
function SecretKey:dispose()
    if not self._disposed and self._handle ~= nil then
        -- Remove GC callback and free manually
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_secretkey(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

-- String representation
function SecretKey:__tostring()
    if self._disposed then
        return "SecretKey(disposed)"
    end
    return string.format("SecretKey(%s...)", self:to_hex():sub(1, 16))
end

M.SecretKey = SecretKey

-- =============================================================================
-- PublicKey
-- =============================================================================

local PublicKey = {}
PublicKey.__index = PublicKey

--[[
  Create a new PublicKey wrapper.
  Internal - use SecretKey:public_key() or PublicKey.from_hex() instead.
]]
function PublicKey._wrap(handle)
    local self = setmetatable({}, PublicKey)
    self._handle = handle
    self._disposed = false

    -- Register GC callback to free the handle
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_publickey(h, status)
        end
    end)

    return self
end

--[[
  Create a PublicKey from a hex string.

  @param hex (string) - The hex-encoded public key
  @return PublicKey - The public key
  @raises error if the hex string is invalid
]]
function PublicKey.from_hex(hex)
    assert(M._lib, "keys not initialized")
    assert(type(hex) == "string", "hex must be a string")

    -- from_hex expects raw hex string (no UniFFI length prefix)
    local hex_buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_publickey_from_hex(hex_buf, status)
    M._errors.check_status(status, "PublicKey.from_hex")

    return PublicKey._wrap(handle)
end

--[[
  Check if this key has been disposed.
]]
function PublicKey:is_disposed()
    return self._disposed
end

--[[
  Clone the internal handle for passing to FFI.
]]
function PublicKey:_clone()
    assert(not self._disposed, "PublicKey has been disposed")

    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_publickey(self._handle, status)
    M._errors.check_status(status, "PublicKey.clone")

    return cloned
end

--[[
  Get the raw handle (for internal use).
]]
function PublicKey:_get_handle()
    return self:_clone()
end

--[[
  Convert the public key to a hex string.

  @return string - The hex-encoded public key
]]
function PublicKey:to_hex()
    assert(not self._disposed, "PublicKey has been disposed")

    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_publickey_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "PublicKey.to_hex")

    -- to_hex returns raw string data (not UniFFI serialized)
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

--[[
  Explicitly dispose of this key (optional - GC handles it automatically).
]]
function PublicKey:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_publickey(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

-- String representation
function PublicKey:__tostring()
    if self._disposed then
        return "PublicKey(disposed)"
    end
    return string.format("PublicKey(%s...)", self:to_hex():sub(1, 16))
end

M.PublicKey = PublicKey

return M
