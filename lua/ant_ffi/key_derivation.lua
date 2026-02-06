--[[
  Key derivation types for ant_ffi

  This module provides hierarchical key derivation types:
  - DerivationIndex: Index for deriving child keys
  - Signature: BLS signature type
  - MainSecretKey: Master key for hierarchical derivation
  - MainPubkey: Master public key
  - DerivedSecretKey: Derived child secret key
  - DerivedPubkey: Derived child public key
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
-- DerivationIndex
-- =============================================================================

local DerivationIndex = {}
DerivationIndex.__index = DerivationIndex

function DerivationIndex._wrap(handle)
    local self = setmetatable({}, DerivationIndex)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_derivationindex(h, status)
        end
    end)
    return self
end

function DerivationIndex.random()
    assert(M._lib, "key_derivation not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_derivationindex_random(status)
    M._errors.check_status(status, "DerivationIndex.random")
    return DerivationIndex._wrap(handle)
end

function DerivationIndex.from_bytes(bytes)
    assert(M._lib, "key_derivation not initialized")
    local buf = M._helpers.bytes_to_rustbuffer(bytes)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(buf, status)
    M._errors.check_status(status, "DerivationIndex.from_bytes")
    return DerivationIndex._wrap(handle)
end

function DerivationIndex:_clone()
    assert(not self._disposed, "DerivationIndex has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_derivationindex(self._handle, status)
    M._errors.check_status(status, "DerivationIndex.clone")
    return cloned
end

function DerivationIndex:to_bytes()
    assert(not self._disposed, "DerivationIndex has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_derivationindex_to_bytes(result, self:_clone(), status)
    M._errors.check_status(status, "DerivationIndex.to_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

function DerivationIndex:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_derivationindex(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.DerivationIndex = DerivationIndex

-- =============================================================================
-- Signature
-- =============================================================================

local Signature = {}
Signature.__index = Signature

function Signature._wrap(handle)
    local self = setmetatable({}, Signature)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_signature(h, status)
        end
    end)
    return self
end

function Signature.from_bytes(bytes)
    assert(M._lib, "key_derivation not initialized")
    local buf = M._helpers.bytes_to_rustbuffer(bytes)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_signature_from_bytes(buf, status)
    M._errors.check_status(status, "Signature.from_bytes")
    return Signature._wrap(handle)
end

function Signature:_clone()
    assert(not self._disposed, "Signature has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_signature(self._handle, status)
    M._errors.check_status(status, "Signature.clone")
    return cloned
end

function Signature:to_bytes()
    assert(not self._disposed, "Signature has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_signature_to_bytes(result, self:_clone(), status)
    M._errors.check_status(status, "Signature.to_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

function Signature:to_hex()
    assert(not self._disposed, "Signature has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_signature_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "Signature.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function Signature:parity()
    assert(not self._disposed, "Signature has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_signature_parity(self:_clone(), status)
    M._errors.check_status(status, "Signature.parity")
    return result ~= 0
end

function Signature:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_signature(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.Signature = Signature

-- =============================================================================
-- MainSecretKey
-- =============================================================================

local MainSecretKey = {}
MainSecretKey.__index = MainSecretKey

function MainSecretKey._wrap(handle)
    local self = setmetatable({}, MainSecretKey)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_mainsecretkey(h, status)
        end
    end)
    return self
end

function MainSecretKey.new(secret_key)
    assert(M._lib, "key_derivation not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_mainsecretkey_new(secret_key:_clone(), status)
    M._errors.check_status(status, "MainSecretKey.new")
    return MainSecretKey._wrap(handle)
end

function MainSecretKey.random()
    assert(M._lib, "key_derivation not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_mainsecretkey_random(status)
    M._errors.check_status(status, "MainSecretKey.random")
    return MainSecretKey._wrap(handle)
end

function MainSecretKey:_clone()
    assert(not self._disposed, "MainSecretKey has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_mainsecretkey(self._handle, status)
    M._errors.check_status(status, "MainSecretKey.clone")
    return cloned
end

function MainSecretKey:public_key()
    assert(not self._disposed, "MainSecretKey has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_mainsecretkey_public_key(self:_clone(), status)
    M._errors.check_status(status, "MainSecretKey.public_key")
    return M.MainPubkey._wrap(handle)
end

function MainSecretKey:sign(msg)
    assert(not self._disposed, "MainSecretKey has been disposed")
    local msg_buf = M._helpers.string_to_rustbuffer(msg)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_mainsecretkey_sign(self:_clone(), msg_buf, status)
    M._errors.check_status(status, "MainSecretKey.sign")
    return Signature._wrap(handle)
end

function MainSecretKey:derive_key(index)
    assert(not self._disposed, "MainSecretKey has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(self:_clone(), index:_clone(), status)
    M._errors.check_status(status, "MainSecretKey.derive_key")
    return M.DerivedSecretKey._wrap(handle)
end

function MainSecretKey:random_derived_key()
    assert(not self._disposed, "MainSecretKey has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(self:_clone(), status)
    M._errors.check_status(status, "MainSecretKey.random_derived_key")
    return M.DerivedSecretKey._wrap(handle)
end

function MainSecretKey:to_bytes()
    assert(not self._disposed, "MainSecretKey has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(result, self:_clone(), status)
    M._errors.check_status(status, "MainSecretKey.to_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

function MainSecretKey:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_mainsecretkey(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.MainSecretKey = MainSecretKey

-- =============================================================================
-- MainPubkey
-- =============================================================================

local MainPubkey = {}
MainPubkey.__index = MainPubkey

function MainPubkey._wrap(handle)
    local self = setmetatable({}, MainPubkey)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_mainpubkey(h, status)
        end
    end)
    return self
end

function MainPubkey.new(public_key)
    assert(M._lib, "key_derivation not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_mainpubkey_new(public_key:_clone(), status)
    M._errors.check_status(status, "MainPubkey.new")
    return MainPubkey._wrap(handle)
end

function MainPubkey.from_hex(hex)
    assert(M._lib, "key_derivation not initialized")
    local hex_buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(hex_buf, status)
    M._errors.check_status(status, "MainPubkey.from_hex")
    return MainPubkey._wrap(handle)
end

function MainPubkey:_clone()
    assert(not self._disposed, "MainPubkey has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_mainpubkey(self._handle, status)
    M._errors.check_status(status, "MainPubkey.clone")
    return cloned
end

function MainPubkey:verify(signature, msg)
    assert(not self._disposed, "MainPubkey has been disposed")
    local msg_buf = M._helpers.string_to_rustbuffer(msg)
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_mainpubkey_verify(self:_clone(), signature:_clone(), msg_buf, status)
    M._errors.check_status(status, "MainPubkey.verify")
    return result ~= 0
end

function MainPubkey:derive_key(index)
    assert(not self._disposed, "MainPubkey has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_mainpubkey_derive_key(self:_clone(), index:_clone(), status)
    M._errors.check_status(status, "MainPubkey.derive_key")
    return M.DerivedPubkey._wrap(handle)
end

function MainPubkey:to_bytes()
    assert(not self._disposed, "MainPubkey has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(result, self:_clone(), status)
    M._errors.check_status(status, "MainPubkey.to_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

function MainPubkey:to_hex()
    assert(not self._disposed, "MainPubkey has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_mainpubkey_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "MainPubkey.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function MainPubkey:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_mainpubkey(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.MainPubkey = MainPubkey

-- =============================================================================
-- DerivedSecretKey
-- =============================================================================

local DerivedSecretKey = {}
DerivedSecretKey.__index = DerivedSecretKey

function DerivedSecretKey._wrap(handle)
    local self = setmetatable({}, DerivedSecretKey)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_derivedsecretkey(h, status)
        end
    end)
    return self
end

function DerivedSecretKey.new(secret_key)
    assert(M._lib, "key_derivation not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(secret_key:_clone(), status)
    M._errors.check_status(status, "DerivedSecretKey.new")
    return DerivedSecretKey._wrap(handle)
end

function DerivedSecretKey:_clone()
    assert(not self._disposed, "DerivedSecretKey has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_derivedsecretkey(self._handle, status)
    M._errors.check_status(status, "DerivedSecretKey.clone")
    return cloned
end

function DerivedSecretKey:public_key()
    assert(not self._disposed, "DerivedSecretKey has been disposed")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(self:_clone(), status)
    M._errors.check_status(status, "DerivedSecretKey.public_key")
    return M.DerivedPubkey._wrap(handle)
end

function DerivedSecretKey:sign(msg)
    assert(not self._disposed, "DerivedSecretKey has been disposed")
    local msg_buf = M._helpers.string_to_rustbuffer(msg)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_method_derivedsecretkey_sign(self:_clone(), msg_buf, status)
    M._errors.check_status(status, "DerivedSecretKey.sign")
    return Signature._wrap(handle)
end

function DerivedSecretKey:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_derivedsecretkey(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.DerivedSecretKey = DerivedSecretKey

-- =============================================================================
-- DerivedPubkey
-- =============================================================================

local DerivedPubkey = {}
DerivedPubkey.__index = DerivedPubkey

function DerivedPubkey._wrap(handle)
    local self = setmetatable({}, DerivedPubkey)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_derivedpubkey(h, status)
        end
    end)
    return self
end

function DerivedPubkey.new(public_key)
    assert(M._lib, "key_derivation not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_derivedpubkey_new(public_key:_clone(), status)
    M._errors.check_status(status, "DerivedPubkey.new")
    return DerivedPubkey._wrap(handle)
end

function DerivedPubkey.from_hex(hex)
    assert(M._lib, "key_derivation not initialized")
    local hex_buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(hex_buf, status)
    M._errors.check_status(status, "DerivedPubkey.from_hex")
    return DerivedPubkey._wrap(handle)
end

function DerivedPubkey:_clone()
    assert(not self._disposed, "DerivedPubkey has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_derivedpubkey(self._handle, status)
    M._errors.check_status(status, "DerivedPubkey.clone")
    return cloned
end

function DerivedPubkey:verify(signature, msg)
    assert(not self._disposed, "DerivedPubkey has been disposed")
    local msg_buf = M._helpers.string_to_rustbuffer(msg)
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_derivedpubkey_verify(self:_clone(), signature:_clone(), msg_buf, status)
    M._errors.check_status(status, "DerivedPubkey.verify")
    return result ~= 0
end

function DerivedPubkey:to_bytes()
    assert(not self._disposed, "DerivedPubkey has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(result, self:_clone(), status)
    M._errors.check_status(status, "DerivedPubkey.to_bytes")
    return M._helpers.rustbuffer_to_bytes(result[0])
end

function DerivedPubkey:to_hex()
    assert(not self._disposed, "DerivedPubkey has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "DerivedPubkey.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function DerivedPubkey:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_derivedpubkey(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.DerivedPubkey = DerivedPubkey

return M
