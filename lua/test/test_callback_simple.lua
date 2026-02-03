--[[
  Simpler callback test - check if we can use atomic operations
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

-- Create a shared memory location for the callback result
-- Using volatile-style access
ffi.cdef[[
    typedef struct {
        volatile int8_t ready;
    } CallbackState;
]]

local state = ffi.new("CallbackState")
state.ready = -1

-- Create a callback that writes to the state
-- Note: This callback may be called from another thread
local function callback_fn(data, result)
    -- Minimal work in callback - just set the flag
    state.ready = result
end

print("\nCreating callback...")
io.flush()
local cb = ffi.cast("UniffiRustFutureContinuationCallback", callback_fn)
print("Callback created")
io.flush()

-- Get a future
print("\nCalling client init...")
io.flush()
local future_handle = lib.uniffi_ant_ffi_fn_constructor_client_init_local()
print(string.format("Future handle: %d", tonumber(future_handle)))
io.flush()

-- Poll loop
print("\nPolling...")
io.flush()
local max_polls = 10000
local polls = 0

state.ready = 1  -- Start as pending

while state.ready ~= 0 and polls < max_polls do
    polls = polls + 1
    state.ready = 1  -- Reset before each poll
    print(string.format("  Poll %d - calling poll_pointer...", polls))
    io.flush()
    lib.ffi_ant_ffi_rust_future_poll_pointer(future_handle, cb, polls)
    print(string.format("  Poll %d - returned, state.ready = %d", polls, state.ready))
    io.flush()

    -- Small busy-wait to let callback fire
    local wait_count = 0
    while state.ready ~= 0 and wait_count < 10000 do
        wait_count = wait_count + 1
    end

    if state.ready ~= 0 and polls < max_polls then
        -- Sleep a bit if not ready
        local sleep_start = os.clock()
        while os.clock() - sleep_start < 0.1 do end  -- 100ms sleep
    end
end

print(string.format("Polling done after %d polls, state.ready = %d", polls, state.ready))
io.flush()

-- Complete
print("\nCompleting...")
io.flush()

-- Check struct sizes
print(string.format("sizeof(RustCallStatus) = %d", ffi.sizeof("RustCallStatus")))
print(string.format("sizeof(RustBuffer) = %d", ffi.sizeof("RustBuffer")))
io.flush()

-- Try with array notation (like other sync functions use)
local status_arr = ffi.new("RustCallStatus[1]")
local status = status_arr[0]

print(string.format("Status before complete: code=%d, buf.cap=%d, buf.len=%d, buf.data=%s",
    status.code, tonumber(status.error_buf.capacity), tonumber(status.error_buf.len),
    tostring(status.error_buf.data)))
io.flush()

if state.ready == 0 then
    -- Add a small delay to allow any async operations to settle
    print("Future is ready! Waiting 500ms before completing...")
    io.flush()
    local start = os.clock()
    while os.clock() - start < 0.5 do end

    print("Calling ffi_ant_ffi_rust_future_complete_pointer...")
    io.flush()
    -- Pass pointer to first element of array
    local result = lib.ffi_ant_ffi_rust_future_complete_pointer(future_handle, status_arr)
    print(string.format("Complete returned, result = %s", tostring(result)))
    io.flush()
    -- Read status from array
    status = status_arr[0]
    print(string.format("status.code = %d", status.code))
    io.flush()

    if status.code == 0 then
        print("SUCCESS! Client initialized.")
        io.flush()
        -- Free the client
        local free_status = ffi.new("RustCallStatus")
        lib.uniffi_ant_ffi_fn_free_client(result, free_status)
        print("Client freed")
        io.flush()
    else
        print("Error code: " .. status.code)
        io.flush()
        -- Print full error buffer details
        print(string.format("Error buffer capacity: %d", tonumber(status.error_buf.capacity)))
        print(string.format("Error buffer len: %d", tonumber(status.error_buf.len)))
        print(string.format("Error buffer data: %s", tostring(status.error_buf.data)))
        io.flush()
        -- Try to extract error message
        if status.error_buf.len > 0 then
            print(string.format("Error buffer len: %d", tonumber(status.error_buf.len)))
            io.flush()
            if status.error_buf.data ~= nil then
                -- UniFFI error format: variant byte + 4-byte BE length + string
                local data = status.error_buf.data
                local len = tonumber(status.error_buf.len)

                -- Print raw bytes for debugging
                local raw = ""
                for i = 0, math.min(len - 1, 100) do
                    raw = raw .. string.format("%02x ", data[i])
                end
                print("Raw error bytes: " .. raw)
                io.flush()

                -- Try different parsing approaches
                if len > 5 then
                    -- Skip variant byte (1) + read BE length (4)
                    local str_len = bit.bor(
                        bit.lshift(data[1], 24),
                        bit.lshift(data[2], 16),
                        bit.lshift(data[3], 8),
                        data[4]
                    )
                    print(string.format("Parsed string length: %d", str_len))
                    if str_len > 0 and str_len + 5 <= len then
                        local msg = ffi.string(data + 5, str_len)
                        print("Error message: " .. msg)
                    end
                elseif len > 0 then
                    -- Try reading as raw string
                    local msg = ffi.string(data, len)
                    print("Raw error string: " .. msg)
                end
                io.flush()

                -- Free error buffer
                local free_status = ffi.new("RustCallStatus")
                lib.ffi_ant_ffi_rustbuffer_free(status.error_buf, free_status)
            end
        else
            print("No error buffer data")
            io.flush()
        end
    end
else
    print("Future not ready after max polls")
    io.flush()
end

-- Cancel/free the future
lib.ffi_ant_ffi_rust_future_free_pointer(future_handle)
print("Future freed")
io.flush()

-- Wait a bit before cleanup
print("Waiting before final cleanup...")
io.flush()
for i = 1, 1000000 do end  -- Busy wait

-- Free callback - this is where it might crash if callback is still in use
print("About to free callback...")
io.flush()
cb:free()
print("Callback freed")
io.flush()

print("\n=== Test Complete ===")
