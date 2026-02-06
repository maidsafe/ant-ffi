--[[
  Error handling for ant_ffi

  This module provides utilities for checking RustCallStatus
  and extracting error messages from UniFFI error format.
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
  Error codes from UniFFI.
  0 = success
  1 = error
  2 = panic
]]
M.CODE_SUCCESS = 0
M.CODE_ERROR = 1
M.CODE_PANIC = 2

--[[
  Extract error message from a RustBuffer containing UniFFI error format.

  UniFFI error format:
  - 1 byte: variant index (error type)
  - 4 bytes: big-endian string length
  - N bytes: UTF-8 error message

  Falls back to raw bytes if parsing fails.

  @param error_buf (RustBuffer) - The error buffer from RustCallStatus
  @return string - The extracted error message
]]
local function extract_error_message(error_buf)
    if error_buf.len == 0 or error_buf.data == nil then
        return "Unknown error (empty error buffer)"
    end

    local data = error_buf.data
    local len = tonumber(error_buf.len)

    -- Try UniFFI format: variant_index (1 byte) + length prefix (4 bytes) + string
    if len > 5 then
        -- Skip variant index (1 byte), read 4-byte big-endian string length
        local str_len = bit.bor(
            bit.lshift(data[1], 24),
            bit.lshift(data[2], 16),
            bit.lshift(data[3], 8),
            data[4]
        )

        if str_len > 0 and str_len + 5 <= len then
            return ffi.string(data + 5, str_len)
        end
    end

    -- Try without variant index: just length prefix (4 bytes) + string
    if len > 4 then
        local str_len = bit.bor(
            bit.lshift(data[0], 24),
            bit.lshift(data[1], 16),
            bit.lshift(data[2], 8),
            data[3]
        )

        if str_len > 0 and str_len + 4 <= len then
            return ffi.string(data + 4, str_len)
        end
    end

    -- Fallback: try to read as raw UTF-8
    local raw = ffi.string(data, len)

    -- Filter to printable ASCII if it looks like garbage
    local printable = raw:gsub("[^%g%s]", "")
    if #printable > 0 then
        return printable
    end

    return string.format("Unknown error (raw bytes: %d)", len)
end

--[[
  Check a RustCallStatus and raise an error if it indicates failure.

  @param status (RustCallStatus) - The status to check
  @param operation (string) - Description of the operation for error message
  @raises error if status.code is non-zero
]]
function M.check_status(status, operation)
    if status.code == M.CODE_SUCCESS then
        return  -- All good
    end

    local msg = extract_error_message(status.error_buf)

    -- Free the error buffer
    if M.lib and status.error_buf.data ~= nil then
        local free_status = ffi.new("RustCallStatus")
        M.lib.ffi_ant_ffi_rustbuffer_free(status.error_buf, free_status)
    end

    -- Determine error type
    local error_type
    if status.code == M.CODE_ERROR then
        error_type = "error"
    elseif status.code == M.CODE_PANIC then
        error_type = "panic"
    else
        error_type = string.format("unknown (code %d)", status.code)
    end

    error(string.format("[ant_ffi %s] %s: %s", error_type, operation, msg), 2)
end

--[[
  Check status and return success boolean instead of raising error.

  @param status (RustCallStatus) - The status to check
  @return boolean, string|nil - (true, nil) on success, (false, error_message) on failure
]]
function M.check_status_safe(status)
    if status.code == M.CODE_SUCCESS then
        return true, nil
    end

    local msg = extract_error_message(status.error_buf)

    -- Free the error buffer
    if M.lib and status.error_buf.data ~= nil then
        local free_status = ffi.new("RustCallStatus")
        M.lib.ffi_ant_ffi_rustbuffer_free(status.error_buf, free_status)
    end

    return false, msg
end

--[[
  Create a new RustCallStatus initialized to success.

  @return RustCallStatus
]]
function M.new_status()
    return ffi.new("RustCallStatus")
end

return M
