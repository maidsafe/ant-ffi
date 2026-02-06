--[[
  Network configuration for ant_ffi

  This module provides network configuration types:
  - Network: Network configuration for connecting to Autonomi
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
-- Network
-- =============================================================================

local Network = {}
Network.__index = Network

function Network._wrap(handle)
    local self = setmetatable({}, Network)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_network(h, status)
        end
    end)
    return self
end

--[[
  Create a new Network configuration.
  @param is_local (boolean) - True for local testnet, false for mainnet
  @return Network
]]
function Network.new(is_local)
    assert(M._lib, "network not initialized")
    local is_local_flag = is_local and 1 or 0
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_network_new(is_local_flag, status)
    M._errors.check_status(status, "Network.new")
    return Network._wrap(handle)
end

--[[
  Create a custom Network configuration.
  @param rpc_url (string) - RPC endpoint URL
  @param payment_token_address (string) - Payment token contract address
  @param data_payments_address (string) - Data payments contract address
  @return Network
]]
function Network.custom(rpc_url, payment_token_address, data_payments_address)
    assert(M._lib, "network not initialized")
    local rpc_buf = M._helpers.string_to_rustbuffer(rpc_url)
    local token_buf = M._helpers.string_to_rustbuffer(payment_token_address)
    local data_buf = M._helpers.string_to_rustbuffer(data_payments_address)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_network_custom(rpc_buf, token_buf, data_buf, status)
    M._errors.check_status(status, "Network.custom")
    return Network._wrap(handle)
end

function Network:_clone()
    assert(not self._disposed, "Network has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_network(self._handle, status)
    M._errors.check_status(status, "Network.clone")
    return cloned
end

function Network:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_network(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.Network = Network

return M
