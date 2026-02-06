--[[
  Thread-safe async helper for Lua FFI

  This module provides thread-safe callback handling for UniFFI async futures.
  It uses a small C library (async_helper.dll/so/dylib) that provides atomic
  operations for callback results, avoiding LuaJIT's callback thread-safety issues.

  Usage:
    local async = require("ant_ffi.async_helper")

    -- Allocate a slot for tracking the future
    local slot = async.alloc_slot()

    -- Get the C callback function pointer
    local callback = async.get_callback()

    -- Poll the future (pass slot as callback_data)
    lib.ffi_ant_ffi_rust_future_poll_pointer(future_handle, callback, slot)

    -- Check the result (thread-safe)
    local result = async.get_result(slot)  -- -1=pending, 0=ready, 1=wake

    -- Reset for next poll if needed
    async.reset_result(slot)

    -- Free the slot when done
    async.free_slot(slot)
]]

local ffi = require("ffi")

local M = {}

-- FFI declarations for the async helper library
ffi.cdef[[
    // Callback signature matching UniFFI
    typedef void (*UniffiAsyncCallback)(uint64_t callback_data, int8_t poll_result);

    // Async helper functions
    int32_t async_helper_alloc_slot(void);
    void async_helper_free_slot(int32_t slot);
    int8_t async_helper_get_result(int32_t slot);
    void async_helper_reset_result(int32_t slot);
    void* async_helper_get_callback(void);
]]

-- Load the async helper library
local function load_helper_lib()
    local lib_name
    if ffi.os == "Windows" then
        lib_name = "async_helper"
    elseif ffi.os == "OSX" then
        lib_name = "libasync_helper"
    else
        lib_name = "libasync_helper"
    end

    -- Try various paths
    local search_paths = {
        lib_name,                                    -- Current directory / system path
        "./" .. lib_name,                            -- Explicit current dir
        "./ant_ffi/" .. lib_name,                    -- Module directory
        "../ant_ffi/" .. lib_name,                   -- From test directory
    }

    -- Add extension-specific paths
    local ext = ffi.os == "Windows" and ".dll" or (ffi.os == "OSX" and ".dylib" or ".so")
    for i = 1, #search_paths do
        table.insert(search_paths, search_paths[i] .. ext)
    end

    for _, path in ipairs(search_paths) do
        local ok, lib = pcall(ffi.load, path)
        if ok then
            return lib
        end
    end

    return nil, "Could not load async_helper library. Please build it first:\n" ..
                "  cd lua/csrc && build.bat (Windows)\n" ..
                "  cd lua/csrc && ./build.sh (Linux/macOS)"
end

-- Try to load the library
local helper_lib, load_error = load_helper_lib()

-- Store the callback pointer (cast to the right type)
local callback_ptr = nil

--[[
  Check if the async helper is available.
  @return boolean, string - true if available, false with error message otherwise
]]
function M.is_available()
    if helper_lib then
        return true
    else
        return false, load_error
    end
end

--[[
  Allocate a slot for tracking a future's poll result.
  @return number - slot index (0-255), or -1 if no slots available
]]
function M.alloc_slot()
    if not helper_lib then
        error("async_helper library not loaded: " .. (load_error or "unknown error"))
    end
    return helper_lib.async_helper_alloc_slot()
end

--[[
  Free a previously allocated slot.
  @param slot (number) - the slot index to free
]]
function M.free_slot(slot)
    if helper_lib then
        helper_lib.async_helper_free_slot(slot)
    end
end

--[[
  Get the current poll result for a slot.
  @param slot (number) - the slot index
  @return number - -1 = not yet called, 0 = ready, 1 = wake/poll again
]]
function M.get_result(slot)
    if not helper_lib then
        return -1
    end
    return helper_lib.async_helper_get_result(slot)
end

--[[
  Reset the poll result for a slot (set to "pending").
  @param slot (number) - the slot index
]]
function M.reset_result(slot)
    if helper_lib then
        helper_lib.async_helper_reset_result(slot)
    end
end

--[[
  Get the thread-safe callback function pointer.
  This can be passed directly to UniFFI poll functions.
  @return cdata - callback function pointer
]]
function M.get_callback()
    if not helper_lib then
        error("async_helper library not loaded: " .. (load_error or "unknown error"))
    end

    if not callback_ptr then
        local raw_ptr = helper_lib.async_helper_get_callback()
        callback_ptr = ffi.cast("UniffiRustFutureContinuationCallback", raw_ptr)
    end

    return callback_ptr
end

--[[
  Poll a pointer-returning future until ready (blocking).
  @param lib - the native ant_ffi library
  @param future_handle (number) - the future handle from an async function
  @return cdata, RustCallStatus - the result pointer and status
]]
function M.poll_pointer_sync(lib, future_handle)
    if not helper_lib then
        error("async_helper library not loaded: " .. (load_error or "unknown error"))
    end

    local slot = M.alloc_slot()
    if slot < 0 then
        error("No async slots available")
    end

    local callback = M.get_callback()

    -- Poll until ready
    repeat
        M.reset_result(slot)
        lib.ffi_ant_ffi_rust_future_poll_pointer(future_handle, callback, slot)

        -- Wait for callback with a small sleep between checks
        local result = M.get_result(slot)
        while result == -1 do
            -- Small busy wait
            for i = 1, 1000 do end
            result = M.get_result(slot)
        end
    until result == 0  -- 0 = ready

    -- Complete the future
    local status = ffi.new("RustCallStatus")
    local ptr_result = lib.ffi_ant_ffi_rust_future_complete_pointer(future_handle, status)

    -- Free the future and slot
    lib.ffi_ant_ffi_rust_future_free_pointer(future_handle)
    M.free_slot(slot)

    return ptr_result, status
end

--[[
  Poll a RustBuffer-returning future until ready (blocking).
  @param lib - the native ant_ffi library
  @param future_handle (number) - the future handle from an async function
  @return RustBuffer, RustCallStatus - the result buffer and status
]]
function M.poll_rust_buffer_sync(lib, future_handle)
    if not helper_lib then
        error("async_helper library not loaded: " .. (load_error or "unknown error"))
    end

    local slot = M.alloc_slot()
    if slot < 0 then
        error("No async slots available")
    end

    local callback = M.get_callback()

    -- Poll until ready
    repeat
        M.reset_result(slot)
        lib.ffi_ant_ffi_rust_future_poll_rust_buffer(future_handle, callback, slot)

        -- Wait for callback
        local result = M.get_result(slot)
        while result == -1 do
            for i = 1, 1000 do end
            result = M.get_result(slot)
        end
    until result == 0

    -- Complete the future
    local status = ffi.new("RustCallStatus")
    local buffer_result = ffi.new("RustBuffer[1]")
    lib.ffi_ant_ffi_rust_future_complete_rust_buffer(buffer_result, future_handle, status)

    -- Free the future and slot
    lib.ffi_ant_ffi_rust_future_free_rust_buffer(future_handle)
    M.free_slot(slot)

    return buffer_result[0], status
end

--[[
  Poll a void-returning future until ready (blocking).
  @param lib - the native ant_ffi library
  @param future_handle (number) - the future handle from an async function
  @return RustCallStatus - the status
]]
function M.poll_void_sync(lib, future_handle)
    if not helper_lib then
        error("async_helper library not loaded: " .. (load_error or "unknown error"))
    end

    local slot = M.alloc_slot()
    if slot < 0 then
        error("No async slots available")
    end

    local callback = M.get_callback()

    -- Poll until ready
    repeat
        M.reset_result(slot)
        lib.ffi_ant_ffi_rust_future_poll_void(future_handle, callback, slot)

        -- Wait for callback
        local result = M.get_result(slot)
        while result == -1 do
            for i = 1, 1000 do end
            result = M.get_result(slot)
        end
    until result == 0

    -- Complete the future
    local status = ffi.new("RustCallStatus")
    lib.ffi_ant_ffi_rust_future_complete_void(future_handle, status)

    -- Free the future and slot
    lib.ffi_ant_ffi_rust_future_free_void(future_handle)
    M.free_slot(slot)

    return status
end

return M
