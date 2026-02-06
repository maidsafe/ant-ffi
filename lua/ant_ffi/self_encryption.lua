--[[
  Self-encryption functions for ant_ffi

  This module provides encrypt and decrypt functions using
  the self-encryption algorithm from the Autonomi network.
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

--[[
  Encrypt data using self-encryption.

  Self-encryption provides content-addressable encryption where
  identical data always produces identical encrypted output.

  @param data (string) - The data to encrypt
  @return string - The encrypted data
  @raises error if encryption fails
]]
function M.encrypt(data)
    assert(M._lib, "self_encryption not initialized")
    assert(type(data) == "string", "data must be a string")

    -- Convert input to RustBuffer with UniFFI serialization
    local input_buf = M._helpers.string_to_rustbuffer(data)

    -- Call encrypt (returns RustBuffer directly)
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_func_encrypt(input_buf, status)
    M._errors.check_status(status, "encrypt")

    -- Return raw buffer contents (includes UniFFI serialization for decrypt)
    return M._helpers.rustbuffer_to_raw_string(result)
end

--[[
  Decrypt self-encrypted data.

  @param encrypted_data (string) - The encrypted data from encrypt()
  @return string - The original decrypted data
  @raises error if decryption fails
]]
function M.decrypt(encrypted_data)
    assert(M._lib, "self_encryption not initialized")
    assert(type(encrypted_data) == "string", "encrypted_data must be a string")

    -- Convert input to RustBuffer WITHOUT adding prefix (encrypted data already serialized)
    local input_buf = M._helpers.raw_string_to_rustbuffer(encrypted_data)

    -- Call decrypt (returns RustBuffer directly)
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_func_decrypt(input_buf, status)
    M._errors.check_status(status, "decrypt")

    -- Parse UniFFI serialization to get original string
    return M._helpers.rustbuffer_to_string(result)
end

--[[
  Encrypt bytes (table of byte values) using self-encryption.

  @param bytes (table) - Array of byte values (0-255) to encrypt
  @return table - Array of encrypted byte values
  @raises error if encryption fails
]]
function M.encrypt_bytes(bytes)
    assert(M._lib, "self_encryption not initialized")
    assert(type(bytes) == "table", "bytes must be a table")

    -- Convert bytes to string, encrypt, return as byte table
    local str = ""
    for i = 1, #bytes do
        str = str .. string.char(bytes[i])
    end

    local encrypted_str = M.encrypt(str)

    -- Convert encrypted string back to byte table
    local result = {}
    for i = 1, #encrypted_str do
        result[i] = string.byte(encrypted_str, i)
    end
    return result
end

--[[
  Decrypt self-encrypted bytes.

  @param encrypted_bytes (table) - Array of encrypted byte values
  @return table - Array of original decrypted byte values
  @raises error if decryption fails
]]
function M.decrypt_bytes(encrypted_bytes)
    assert(M._lib, "self_encryption not initialized")
    assert(type(encrypted_bytes) == "table", "encrypted_bytes must be a table")

    -- Convert bytes to string, decrypt, return as byte table
    local str = ""
    for i = 1, #encrypted_bytes do
        str = str .. string.char(encrypted_bytes[i])
    end

    local decrypted_str = M.decrypt(str)

    -- Convert decrypted string back to byte table
    local result = {}
    for i = 1, #decrypted_str do
        result[i] = string.byte(decrypted_str, i)
    end
    return result
end

return M
