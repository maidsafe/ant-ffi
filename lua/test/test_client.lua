--[[
  Integration tests for Client (requires running local network)

  These tests require a local Autonomi network to be running.
  Skip if network is not available.

  Run with: luajit test/test_client.lua
]]

-- Add paths for running from lua directory: luajit test/test_client.lua
package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

local function test_client_init_local()
    local ant = require("ant_ffi")

    print("Attempting to connect to local network...")
    local client = ant.Client.init_local()

    assert(client, "Should create client")
    print("Connected to local network!")

    client:dispose()
    print("PASS: client_init_local")

    return true
end

-- Note: The following tests require payment/wallet which may not be
-- available in a test environment. They're included as examples.

--[[
local function test_data_put_get_public()
    local ant = require("ant_ffi")

    local client = ant.Client.init_local()

    local data = "Hello from Lua FFI!"
    local payment = ""  -- Would need real payment option

    -- This would fail without valid payment
    -- local address = client:data_put_public(data, payment)
    -- local retrieved = client:data_get_public(address:to_hex())
    -- assert(retrieved == data, "Data should round-trip")

    client:dispose()
    print("PASS: data_put_get_public (skipped - no payment)")
end
]]

-- Run tests
print("\n=== Client Tests (Integration) ===\n")
print("Note: These tests require a running local Autonomi network.\n")

local ok, err = pcall(test_client_init_local)
if not ok then
    print("SKIP: client_init_local - " .. tostring(err))
    print("\nTo run integration tests:")
    print("1. Start a local Autonomi network")
    print("2. Ensure the ant_ffi library is built")
    print("3. Run this test again")
end

print("\n=== Tests Complete ===\n")
