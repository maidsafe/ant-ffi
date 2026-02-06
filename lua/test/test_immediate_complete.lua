--[[
  Test calling complete immediately without polling
  to see what status code we get
]]

package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

io.stdout:setvbuf("no")

local ffi = require("ffi")
require("ant_ffi.ffi_defs")
local native = require("ant_ffi.native")
local lib = native.lib

print("Library loaded")

-- Create a future
print("\nCreating future...")
local future_handle = lib.uniffi_ant_ffi_fn_constructor_client_init_local()
print(string.format("Future handle: %s", tostring(future_handle)))

-- Try completing immediately WITHOUT polling
print("\nTrying to complete immediately (without polling)...")
local status = ffi.new("RustCallStatus")
local result = lib.ffi_ant_ffi_rust_future_complete_pointer(future_handle, status)
print(string.format("status.code = %d (0=success, 1=error, 2=panic, 3=cancelled)", status.code))
print(string.format("result = %s", tostring(result)))

-- Free the future
print("\nFreeing future...")
lib.ffi_ant_ffi_rust_future_free_pointer(future_handle)
print("Done")
