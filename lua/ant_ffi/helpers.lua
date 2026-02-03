--[[
  RustBuffer and ForeignBytes helper functions

  This module provides utilities for converting between Lua strings
  and UniFFI's RustBuffer/ForeignBytes types.

  UniFFI serialization format:
  - Vec<u8> uses 4-byte big-endian length prefix followed by raw bytes
  - Strings are serialized the same way
]]

local ffi = require("ffi")
local bit = require("bit")

local M = {}

-- Will be set by init.lua after native is loaded
M.lib = nil

-- Initialize with the native library
function M.init(lib)
    M.lib = lib
end

--[[
  Create a new RustCallStatus structure.
  @return RustCallStatus - initialized status structure
]]
function M.new_status()
    return ffi.new("RustCallStatus")
end

--[[
  Convert a Lua string to RustBuffer with UniFFI serialization.
  The buffer includes a 4-byte big-endian length prefix.

  @param str (string) - The Lua string to convert
  @return RustBuffer - The serialized buffer
]]
function M.string_to_rustbuffer(str)
    assert(M.lib, "helpers not initialized - call helpers.init(lib) first")

    local len = #str
    local total_len = 4 + len

    -- Allocate buffer for length prefix + data
    local buf = ffi.new("uint8_t[?]", total_len)

    -- Write 4-byte big-endian length prefix
    buf[0] = bit.band(bit.rshift(len, 24), 0xFF)
    buf[1] = bit.band(bit.rshift(len, 16), 0xFF)
    buf[2] = bit.band(bit.rshift(len, 8), 0xFF)
    buf[3] = bit.band(len, 0xFF)

    -- Copy string data after prefix
    if len > 0 then
        ffi.copy(buf + 4, str, len)
    end

    -- Create ForeignBytes pointing to our buffer
    local fb = ffi.new("ForeignBytes")
    fb.len = total_len
    fb.data = buf

    -- Convert to RustBuffer
    local status = M.new_status()
    local result = M.lib.ffi_ant_ffi_rustbuffer_from_bytes(fb, status)

    -- Check for errors
    local errors = require("ant_ffi.errors")
    errors.check_status(status, "string_to_rustbuffer")

    return result
end

--[[
  Convert a Lua byte table to RustBuffer with UniFFI serialization.

  @param bytes (table) - Array of byte values (0-255)
  @return RustBuffer - The serialized buffer
]]
function M.bytes_to_rustbuffer(bytes)
    assert(M.lib, "helpers not initialized - call helpers.init(lib) first")

    local len = #bytes
    local total_len = 4 + len

    -- Allocate buffer for length prefix + data
    local buf = ffi.new("uint8_t[?]", total_len)

    -- Write 4-byte big-endian length prefix
    buf[0] = bit.band(bit.rshift(len, 24), 0xFF)
    buf[1] = bit.band(bit.rshift(len, 16), 0xFF)
    buf[2] = bit.band(bit.rshift(len, 8), 0xFF)
    buf[3] = bit.band(len, 0xFF)

    -- Copy byte data after prefix
    for i = 1, len do
        buf[3 + i] = bytes[i]
    end

    -- Create ForeignBytes pointing to our buffer
    local fb = ffi.new("ForeignBytes")
    fb.len = total_len
    fb.data = buf

    -- Convert to RustBuffer
    local status = M.new_status()
    local result = M.lib.ffi_ant_ffi_rustbuffer_from_bytes(fb, status)

    -- Check for errors
    local errors = require("ant_ffi.errors")
    errors.check_status(status, "bytes_to_rustbuffer")

    return result
end

--[[
  Convert RustBuffer to Lua string, parsing UniFFI serialization.
  Skips the 4-byte big-endian length prefix.

  @param buffer (RustBuffer) - The buffer to convert
  @param free_buffer (boolean, optional) - Whether to free the buffer (default true)
  @return string - The decoded Lua string
]]
function M.rustbuffer_to_string(buffer, free_buffer)
    if free_buffer == nil then free_buffer = true end

    -- Handle empty buffer
    if buffer.len < 4 then
        if free_buffer then
            M.free_rustbuffer(buffer)
        end
        return ""
    end

    -- Read 4-byte big-endian length from prefix
    local str_len = bit.bor(
        bit.lshift(buffer.data[0], 24),
        bit.lshift(buffer.data[1], 16),
        bit.lshift(buffer.data[2], 8),
        buffer.data[3]
    )

    -- Validate length
    if str_len < 0 or str_len + 4 > tonumber(buffer.len) then
        if free_buffer then
            M.free_rustbuffer(buffer)
        end
        error(string.format("Invalid string length in RustBuffer: %d (buffer len: %d)",
            str_len, tonumber(buffer.len)))
    end

    -- Extract string
    local str = ""
    if str_len > 0 then
        str = ffi.string(buffer.data + 4, str_len)
    end

    -- Free buffer if requested
    if free_buffer then
        M.free_rustbuffer(buffer)
    end

    return str
end

--[[
  Convert RustBuffer to Lua byte table, parsing UniFFI serialization.

  @param buffer (RustBuffer) - The buffer to convert
  @param free_buffer (boolean, optional) - Whether to free the buffer (default true)
  @return table - Array of byte values
]]
function M.rustbuffer_to_bytes(buffer, free_buffer)
    if free_buffer == nil then free_buffer = true end

    -- Handle empty buffer
    if buffer.len < 4 then
        if free_buffer then
            M.free_rustbuffer(buffer)
        end
        return {}
    end

    -- Read 4-byte big-endian length from prefix
    local data_len = bit.bor(
        bit.lshift(buffer.data[0], 24),
        bit.lshift(buffer.data[1], 16),
        bit.lshift(buffer.data[2], 8),
        buffer.data[3]
    )

    -- Validate length
    if data_len < 0 or data_len + 4 > tonumber(buffer.len) then
        if free_buffer then
            M.free_rustbuffer(buffer)
        end
        error(string.format("Invalid data length in RustBuffer: %d (buffer len: %d)",
            data_len, tonumber(buffer.len)))
    end

    -- Extract bytes
    local bytes = {}
    for i = 0, data_len - 1 do
        bytes[i + 1] = buffer.data[4 + i]
    end

    -- Free buffer if requested
    if free_buffer then
        M.free_rustbuffer(buffer)
    end

    return bytes
end

--[[
  Free a RustBuffer.

  @param buffer (RustBuffer) - The buffer to free
]]
function M.free_rustbuffer(buffer)
    if M.lib and buffer.data ~= nil then
        local status = M.new_status()
        M.lib.ffi_ant_ffi_rustbuffer_free(buffer, status)
        -- Ignore errors during free
    end
end

--[[
  Create an empty RustBuffer (zero-length data).

  @return RustBuffer - Empty buffer with UniFFI serialization
]]
function M.empty_rustbuffer()
    return M.string_to_rustbuffer("")
end

--[[
  Convert a raw bytes string (no UniFFI prefix) to RustBuffer.
  Used for passing binary data that already has the correct format.

  @param data (string) - Raw bytes to wrap
  @return RustBuffer - Buffer containing the raw data with length prefix
]]
function M.raw_to_rustbuffer(data)
    -- This is the same as string_to_rustbuffer for binary data
    return M.string_to_rustbuffer(data)
end

--[[
  Convert a Lua string to RustBuffer WITHOUT adding UniFFI length prefix.
  Used for passing data that already contains the correct serialization.

  @param str (string) - Raw bytes to wrap directly
  @return RustBuffer - Buffer containing the raw bytes
]]
function M.raw_string_to_rustbuffer(str)
    assert(M.lib, "helpers not initialized - call helpers.init(lib) first")

    local len = #str

    -- Create ForeignBytes pointing to our data
    local buf = ffi.new("uint8_t[?]", len)
    if len > 0 then
        ffi.copy(buf, str, len)
    end

    local fb = ffi.new("ForeignBytes")
    fb.len = len
    fb.data = buf

    -- Convert to RustBuffer
    local status = M.new_status()
    local result = M.lib.ffi_ant_ffi_rustbuffer_from_bytes(fb, status)

    -- Check for errors
    local errors = require("ant_ffi.errors")
    errors.check_status(status, "raw_string_to_rustbuffer")

    return result
end

--[[
  Serialize a PaymentOption::WalletPayment enum to RustBuffer.
  UniFFI enum format: i32 BE variant index (1-based) + variant fields.

  @param wallet - Wallet object with :_clone() method
  @return RustBuffer - Serialized PaymentOption enum
]]
function M.lower_payment_option(wallet)
    assert(M.lib, "helpers not initialized - call helpers.init(lib) first")

    -- Get a cloned wallet handle
    local wallet_handle = wallet:_clone()

    -- Total size: 4 bytes (variant) + 8 bytes (pointer)
    local total_len = 12
    local buf = ffi.new("uint8_t[?]", total_len)

    -- Write 4-byte big-endian variant index (1 = WalletPayment)
    buf[0] = 0
    buf[1] = 0
    buf[2] = 0
    buf[3] = 1

    -- Write 8-byte pointer (big-endian, MSB first - matches C# WriteU64)
    local ptr_val = ffi.cast("uint64_t", ffi.cast("uintptr_t", wallet_handle))
    -- Convert to number for bit operations (LuaJIT handles 64-bit via split)
    local lo = tonumber(ffi.cast("uint32_t", ptr_val))
    local hi = tonumber(ffi.cast("uint32_t", ffi.cast("uint64_t", ptr_val) / 0x100000000ULL))
    -- Write big-endian: high bytes first
    buf[4] = bit.band(bit.rshift(hi, 24), 0xFF)
    buf[5] = bit.band(bit.rshift(hi, 16), 0xFF)
    buf[6] = bit.band(bit.rshift(hi, 8), 0xFF)
    buf[7] = bit.band(hi, 0xFF)
    buf[8] = bit.band(bit.rshift(lo, 24), 0xFF)
    buf[9] = bit.band(bit.rshift(lo, 16), 0xFF)
    buf[10] = bit.band(bit.rshift(lo, 8), 0xFF)
    buf[11] = bit.band(lo, 0xFF)

    -- Create ForeignBytes pointing to our buffer
    local fb = ffi.new("ForeignBytes")
    fb.len = total_len
    fb.data = buf

    -- Convert to RustBuffer
    local status = M.new_status()
    local result = M.lib.ffi_ant_ffi_rustbuffer_from_bytes(fb, status)

    -- Check for errors
    local errors = require("ant_ffi.errors")
    errors.check_status(status, "lower_payment_option")

    return result
end

--[[
  Convert RustBuffer to Lua string WITHOUT parsing UniFFI serialization.
  Returns the raw buffer contents as-is.

  @param buffer (RustBuffer) - The buffer to convert
  @param free_buffer (boolean, optional) - Whether to free the buffer (default true)
  @return string - Raw buffer contents
]]
function M.rustbuffer_to_raw_string(buffer, free_buffer)
    if free_buffer == nil then free_buffer = true end

    -- Handle empty buffer
    if buffer.len == 0 then
        if free_buffer then
            M.free_rustbuffer(buffer)
        end
        return ""
    end

    -- Extract raw bytes
    local str = ffi.string(buffer.data, buffer.len)

    -- Free buffer if requested
    if free_buffer then
        M.free_rustbuffer(buffer)
    end

    return str
end

return M
