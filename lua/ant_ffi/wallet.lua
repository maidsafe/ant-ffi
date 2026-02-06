--[[
  Wallet types for ant_ffi

  This module provides wallet types:
  - Wallet: Payment wallet for network operations
  - VaultSecretKey: Secret key for vault operations
  - UserData: User data stored in vault
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
-- VaultSecretKey
-- =============================================================================

local VaultSecretKey = {}
VaultSecretKey.__index = VaultSecretKey

function VaultSecretKey._wrap(handle)
    local self = setmetatable({}, VaultSecretKey)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_vaultsecretkey(h, status)
        end
    end)
    return self
end

function VaultSecretKey.random()
    assert(M._lib, "wallet not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_vaultsecretkey_random(status)
    M._errors.check_status(status, "VaultSecretKey.random")
    return VaultSecretKey._wrap(handle)
end

function VaultSecretKey.from_hex(hex)
    assert(M._lib, "wallet not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_vaultsecretkey_from_hex(buf, status)
    M._errors.check_status(status, "VaultSecretKey.from_hex")
    return VaultSecretKey._wrap(handle)
end

function VaultSecretKey:_clone()
    assert(not self._disposed, "VaultSecretKey has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_vaultsecretkey(self._handle, status)
    M._errors.check_status(status, "VaultSecretKey.clone")
    return cloned
end

function VaultSecretKey:to_hex()
    assert(not self._disposed, "VaultSecretKey has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_vaultsecretkey_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "VaultSecretKey.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function VaultSecretKey:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_vaultsecretkey(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.VaultSecretKey = VaultSecretKey

-- =============================================================================
-- UserData
-- =============================================================================

local UserData = {}
UserData.__index = UserData

function UserData._wrap(handle)
    local self = setmetatable({}, UserData)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_userdata(h, status)
        end
    end)
    return self
end

function UserData.new()
    assert(M._lib, "wallet not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_userdata_new(status)
    M._errors.check_status(status, "UserData.new")
    return UserData._wrap(handle)
end

function UserData:_clone()
    assert(not self._disposed, "UserData has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_userdata(self._handle, status)
    M._errors.check_status(status, "UserData.clone")
    return cloned
end

function UserData:file_archives()
    assert(not self._disposed, "UserData has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_userdata_file_archives(result, self:_clone(), status)
    M._errors.check_status(status, "UserData.file_archives")
    return M._helpers.rustbuffer_to_string(result[0])
end

function UserData:private_file_archives()
    assert(not self._disposed, "UserData has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_userdata_private_file_archives(result, self:_clone(), status)
    M._errors.check_status(status, "UserData.private_file_archives")
    return M._helpers.rustbuffer_to_string(result[0])
end

function UserData:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_userdata(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.UserData = UserData

-- =============================================================================
-- Wallet
-- =============================================================================

local Wallet = {}
Wallet.__index = Wallet

function Wallet._wrap(handle)
    local self = setmetatable({}, Wallet)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_wallet(h, status)
        end
    end)
    return self
end

--[[
  Create a Wallet from a private key.
  @param network (Network) - Network configuration
  @param private_key (string) - Hex-encoded private key
  @return Wallet
]]
function Wallet.from_private_key(network, private_key)
    assert(M._lib, "wallet not initialized")
    -- Use raw_string_to_rustbuffer (no length prefix) to match C# StringToRustBuffer
    local key_buf = M._helpers.raw_string_to_rustbuffer(private_key)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_wallet_new_from_private_key(
        network:_clone(), key_buf, status)
    M._errors.check_status(status, "Wallet.from_private_key")
    return Wallet._wrap(handle)
end

function Wallet:_clone()
    assert(not self._disposed, "Wallet has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_wallet(self._handle, status)
    M._errors.check_status(status, "Wallet.clone")
    return cloned
end

--[[
  Get the wallet address.
  @return string - Hex-encoded wallet address
]]
function Wallet:address()
    assert(not self._disposed, "Wallet has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_wallet_address(result, self:_clone(), status)
    M._errors.check_status(status, "Wallet.address")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

--[[
  Get the token balance (async).
  Note: This is an async operation that requires polling.
  For sync usage, use the Client's polling helpers.
  @return number - Future handle for polling
]]
function Wallet:balance_of_tokens_async()
    assert(not self._disposed, "Wallet has been disposed")
    -- Returns future handle - need to poll to completion
    return M._lib.uniffi_ant_ffi_fn_method_wallet_balance_of_tokens(self:_clone())
end

function Wallet:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_wallet(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.Wallet = Wallet

return M
