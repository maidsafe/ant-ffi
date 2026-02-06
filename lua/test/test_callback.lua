--[[
  Simple test to check if FFI callbacks work
]]

package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

io.stdout:setvbuf("no")  -- Disable buffering

local ffi = require("ffi")

-- Load the ffi_defs
require("ant_ffi.ffi_defs")

-- Try to load the library
local native = require("ant_ffi.native")
local lib = native.lib

print("Library loaded successfully")

-- Test 1: Simple callback creation
print("\nTest 1: Creating a simple callback...")

local test_value = ffi.new("int8_t[1]")
test_value[0] = -1

local function my_callback(data, result)
    print(string.format("  Callback called with data=%d, result=%d", tonumber(data), tonumber(result)))
    test_value[0] = result
end

local cb = ffi.cast("UniffiRustFutureContinuationCallback", my_callback)
print("  Callback created: " .. tostring(cb))

-- Test 2: Call the callback manually
print("\nTest 2: Calling callback manually...")
io.flush()
cb(123, 0)
print(string.format("  test_value after manual call: %d", test_value[0]))
io.flush()

-- Test 3: Try to initialize client (this is what causes the segfault)
print("\nTest 3: Calling client init...")
io.flush()

local status = ffi.new("RustCallStatus")
print("  Calling uniffi_ant_ffi_fn_constructor_client_init_local...")
io.flush()
local future_handle = lib.uniffi_ant_ffi_fn_constructor_client_init_local()
print(string.format("  Got future handle: %d", tonumber(future_handle)))
io.flush()

-- Test 4: Try to poll with our callback
print("\nTest 4: Polling the future...")
io.flush()
test_value[0] = 1  -- Reset to pending

print("  About to call poll_pointer...")
io.flush()
lib.ffi_ant_ffi_rust_future_poll_pointer(future_handle, cb, 0)
print(string.format("  Poll returned, test_value = %d", test_value[0]))
io.flush()

-- Keep polling until ready
local poll_count = 0
while test_value[0] ~= 0 and poll_count < 1000 do
    poll_count = poll_count + 1
    lib.ffi_ant_ffi_rust_future_poll_pointer(future_handle, cb, 0)
end
print(string.format("  Polled %d times, final test_value = %d", poll_count, test_value[0]))

-- Clean up
print("\nTest 5: Completing and freeing...")
io.flush()
if test_value[0] == 0 then
    local result = lib.ffi_ant_ffi_rust_future_complete_pointer(future_handle, status)
    print(string.format("  Complete returned, status.code = %d", status.code))
    io.flush()
    if status.code == 0 then
        print("  Success! Got client handle: " .. tostring(result))
        io.flush()
        lib.uniffi_ant_ffi_fn_free_client(result, status)
        print("  Client freed")
        io.flush()
    else
        print("  Error occurred! Checking error buffer...")
        io.flush()
        if status.error_buf.len > 0 then
            print(string.format("  Error buffer len: %d", status.error_buf.len))
            -- Try to read error message
            if status.error_buf.data ~= nil then
                local err_data = ffi.string(status.error_buf.data, status.error_buf.len)
                print("  Error data (raw): " .. err_data:sub(1, math.min(100, #err_data)))
            end
            io.flush()
            -- Free error buffer
            local free_status = ffi.new("RustCallStatus")
            lib.ffi_ant_ffi_rustbuffer_free(status.error_buf, free_status)
        end
    end
end

lib.ffi_ant_ffi_rust_future_free_pointer(future_handle)
print("  Future freed")
io.flush()

-- Don't free the callback yet - wait for any pending callbacks
print("  Waiting briefly before freeing callback...")
io.flush()

cb:free()
print("  Callback freed")
io.flush()

print("\n=== Callback Test Complete ===")
io.flush()
