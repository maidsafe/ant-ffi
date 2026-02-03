--[[
  Test the async_helper library for thread-safe callbacks
]]

package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

io.stdout:setvbuf("no")

local ffi = require("ffi")

print("=== Async Helper Test ===\n")

-- Load FFI defs and native library
require("ant_ffi.ffi_defs")
local native = require("ant_ffi.native")
local lib = native.lib

-- Load async helper
local async_helper = require("ant_ffi.async_helper")

-- Check if async helper is available
local available, err = async_helper.is_available()
if not available then
    print("SKIP: async_helper not available: " .. err)
    os.exit(0)
end

print("async_helper loaded successfully!")

-- Test 1: Slot allocation
print("\nTest 1: Slot allocation...")
local slot1 = async_helper.alloc_slot()
print(string.format("  Allocated slot: %d", slot1))
assert(slot1 >= 0, "Failed to allocate slot")

local slot2 = async_helper.alloc_slot()
print(string.format("  Allocated slot: %d", slot2))
assert(slot2 >= 0 and slot2 ~= slot1, "Failed to allocate second slot")

async_helper.free_slot(slot1)
async_helper.free_slot(slot2)
print("  PASS: Slot allocation works")

-- Test 2: Get callback pointer
print("\nTest 2: Get callback pointer...")
local callback = async_helper.get_callback()
print(string.format("  Callback pointer: %s", tostring(callback)))
assert(callback ~= nil, "Failed to get callback")
print("  PASS: Got callback pointer")

-- Test 3: Result get/reset
print("\nTest 3: Result get/reset...")
local slot = async_helper.alloc_slot()
local result = async_helper.get_result(slot)
print(string.format("  Initial result: %d (should be -1)", result))
assert(result == -1, "Initial result should be -1")

async_helper.reset_result(slot)
result = async_helper.get_result(slot)
print(string.format("  After reset: %d (should be -1)", result))
assert(result == -1, "Reset result should be -1")

async_helper.free_slot(slot)
print("  PASS: Result get/reset works")

-- Test 4: Full client init test
print("\nTest 4: Client init with async_helper...")
io.flush()

-- Create the future
local future_handle = lib.uniffi_ant_ffi_fn_constructor_client_init_local()
print(string.format("  Future handle: %s", tostring(future_handle)))
io.flush()

-- Use the sync polling helper
local errors = require("ant_ffi.errors")
errors.init(lib)

print("  Polling future...")
io.flush()

local ptr_result, status = async_helper.poll_pointer_sync(lib, future_handle)

print(string.format("  Result: %s", tostring(ptr_result)))
print(string.format("  Status code: %d", status.code))
io.flush()

if status.code == 0 and ptr_result ~= nil then
    print("  SUCCESS! Client initialized!")

    -- Free the client
    local free_status = ffi.new("RustCallStatus")
    lib.uniffi_ant_ffi_fn_free_client(ptr_result, free_status)
    print("  Client freed")
else
    print("  Error: status code = " .. status.code)
    if status.error_buf.len > 0 then
        print(string.format("  Error buffer len: %d", tonumber(status.error_buf.len)))
    end
end

print("\n=== Async Helper Test Complete ===")
