--[[
  Test the updated client module with async_helper
]]

package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

io.stdout:setvbuf("no")

print("=== Testing Updated Client Module ===\n")

local ant = require("ant_ffi")
local client_mod = require("ant_ffi.client")

-- Test 1: Check async availability
print("Test 1: Check async availability...")
local available, err = client_mod.is_async_available()
print(string.format("  Async available: %s", tostring(available)))
if not available then
    print("  Error: " .. (err or "unknown"))
    print("\nSKIP: async_helper not available")
    os.exit(0)
end
print("  PASS")

-- Test 2: Initialize client
print("\nTest 2: Initialize client (local network)...")
local ok, client = pcall(ant.Client.init_local)
if ok then
    print("  SUCCESS! Client initialized")

    -- Test 3: Dispose client
    print("\nTest 3: Dispose client...")
    client:dispose()
    print("  Client disposed")
    print("  PASS")
else
    print("  ERROR: " .. tostring(client))
end

print("\n=== Test Complete ===")
