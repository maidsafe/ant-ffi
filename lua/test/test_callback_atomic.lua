--[[
  Test using atomic/volatile memory for callback result
  The callback writes directly to a memory location without invoking Lua
]]

package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

io.stdout:setvbuf("no")  -- Disable buffering

local ffi = require("ffi")

-- Load the ffi_defs
require("ant_ffi.ffi_defs")

-- Load the library
local native = require("ant_ffi.native")
local lib = native.lib

print("Library loaded successfully")

-- Create a volatile memory location for the callback result
-- Using a C array so it has stable memory address
local callback_result = ffi.new("volatile int8_t[1]")
callback_result[0] = -1  -- Initial value

-- Store the address of the result
local result_ptr = ffi.cast("volatile int8_t*", callback_result)
print(string.format("Result pointer: %s", tostring(result_ptr)))

-- Create callback that writes directly to the memory location
-- This callback does minimal work - just stores the result
local function minimal_callback(callback_data, poll_result)
    -- Print callback invocation for debugging
    print(string.format("    CALLBACK: data=%s, result=%d", tostring(callback_data), poll_result))
    io.flush()
    -- Write result directly - this is the minimal operation
    callback_result[0] = poll_result
end

print("\nCreating callback...")
io.flush()
local cb = ffi.cast("UniffiRustFutureContinuationCallback", minimal_callback)
print("Callback created")
io.flush()

-- Get a future
print("\nCalling client init...")
io.flush()
local future_handle = lib.uniffi_ant_ffi_fn_constructor_client_init_local()
print(string.format("Future handle type: %s", type(future_handle)))
print(string.format("Future handle ctype: %s", tostring(ffi.typeof(future_handle))))
print(string.format("Future handle value: %s", tostring(future_handle)))
print(string.format("Future handle as number: %d", tonumber(future_handle) or -1))
io.flush()

-- Poll loop with careful timing
print("\nPolling (with careful timing)...")
io.flush()
local max_polls = 100
local polls = 0

callback_result[0] = 1  -- Start as pending (WAKE)

while callback_result[0] ~= 0 and polls < max_polls do
    polls = polls + 1
    callback_result[0] = 1  -- Reset before poll

    print(string.format("  Poll %d...", polls))
    io.flush()

    -- Call poll - pass future_handle as callback_data (like C# does)
    lib.ffi_ant_ffi_rust_future_poll_pointer(future_handle, cb, future_handle)

    -- Check result IMMEDIATELY
    local result = callback_result[0]
    print(string.format("  Poll %d result: %d", polls, result))
    io.flush()

    if result == 0 then
        -- Future is ready, break immediately
        break
    end

    -- Sleep between polls if not ready
    if result ~= 0 then
        local sleep_start = os.clock()
        while os.clock() - sleep_start < 0.1 do end
    end
end

print(string.format("\nPolling done after %d polls, result = %d", polls, callback_result[0]))
io.flush()

-- DO NOT free the callback yet - it may be called during future operations
print("\nCompleting future (callback still active)...")
io.flush()

local client_handle = nil

if callback_result[0] == 0 then
    local status = ffi.new("RustCallStatus")

    print("Calling ffi_ant_ffi_rust_future_complete_pointer...")
    io.flush()
    local result = lib.ffi_ant_ffi_rust_future_complete_pointer(future_handle, status)
    print(string.format("Complete returned, result = %s", tostring(result)))
    print(string.format("status.code = %d", status.code))
    io.flush()

    if status.code == 0 and result ~= nil then
        print("SUCCESS! Client initialized.")
        client_handle = result
        io.flush()
    else
        print("Error or NULL result")
        io.flush()
        if status.error_buf.len > 0 then
            print(string.format("Error buffer len: %d", tonumber(status.error_buf.len)))
        end
    end
else
    print("Future not ready!")
end

-- Free the future BEFORE freeing the callback
print("\nFreeing future...")
io.flush()
lib.ffi_ant_ffi_rust_future_free_pointer(future_handle)
print("Future freed")
io.flush()

-- Now free the callback
print("\nFreeing callback...")
io.flush()
cb:free()
cb = nil
print("Callback freed")
io.flush()

-- Free client if we got one
if client_handle ~= nil then
    print("\nFreeing client...")
    local free_status = ffi.new("RustCallStatus")
    lib.uniffi_ant_ffi_fn_free_client(client_handle, free_status)
    print("Client freed")
    io.flush()
end

print("\n=== Test Complete ===")
