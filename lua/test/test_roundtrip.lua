--[[
  Round-trip integration test for Lua FFI bindings

  This test:
  1. Initializes a client connected to local network
  2. Creates a wallet from EVM private key
  3. Generates random test data
  4. Uploads data to the network
  5. Downloads data from the network
  6. Verifies the downloaded data matches the original

  Requirements:
  - Local Autonomi network running (antctl local status)
  - Local EVM testnet running (evm-testnet)
  - EVM_PRIVATE_KEY environment variable set

  Run with: luajit test/test_roundtrip.lua
]]

package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

io.stdout:setvbuf("no")

print("=== Round-Trip Integration Test ===\n")

local ant = require("ant_ffi")
local client_mod = require("ant_ffi.client")

-- Helper to generate random data
local function random_data(size)
    local chars = {}
    for i = 1, size do
        chars[i] = string.char(math.random(0, 255))
    end
    return table.concat(chars)
end

-- Default Anvil/Hardhat test private key #0 (pre-funded on local testnets)
local DEFAULT_TEST_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

-- Get EVM private key from environment or use default test key
local function get_evm_private_key()
    local key = os.getenv("EVM_PRIVATE_KEY")
    if key then
        print("  Using EVM_PRIVATE_KEY from environment")
        return key
    end

    key = os.getenv("SECRET_KEY")
    if key then
        print("  Using SECRET_KEY from environment")
        return key
    end

    -- Use default test key for local testing
    print("  Using default Anvil/Hardhat test key #0")
    return DEFAULT_TEST_KEY
end

-- Get private key (always available with default fallback)
local private_key = get_evm_private_key()

-- Test 1: Check async availability
print("Test 1: Check async availability...")
local available, err = client_mod.is_async_available()
if not available then
    print("  SKIP: async_helper not available - " .. (err or "unknown"))
    os.exit(0)
end
print("  Async available: true")
print("  PASS\n")

-- Test 2: Initialize client
print("Test 2: Initialize client (local network)...")
local ok, client = pcall(ant.Client.init_local)
if not ok then
    print("  ERROR: Failed to initialize client: " .. tostring(client))
    print("\n  Make sure local network is running:")
    print("    antctl local status")
    os.exit(1)
end
print("  Client connected to local network")
print("  PASS\n")

-- Test 3: Create network and wallet
print("Test 3: Create network and wallet...")
local network = ant.Network.new(true)  -- true = local network
print("  Network created (local mode)")

local wallet_ok, wallet = pcall(ant.Wallet.from_private_key, network, private_key)
if not wallet_ok then
    print("  ERROR: Failed to create wallet: " .. tostring(wallet))
    print("\n  Make sure EVM testnet is running and EVM_PRIVATE_KEY is set")
    client:dispose()
    os.exit(1)
end
print("  Wallet address: " .. wallet:address())
print("  PASS\n")

-- Test 4: Upload data
print("Test 4: Upload data to network...")
math.randomseed(os.time())
local test_data = "Hello from Lua FFI round-trip test! " .. os.date() .. " " .. random_data(100)
print("  Test data size: " .. #test_data .. " bytes")

local upload_ok, address = pcall(function()
    return client:data_put_public(test_data, wallet)
end)

if not upload_ok then
    print("  ERROR: Upload failed: " .. tostring(address))
    wallet:dispose()
    client:dispose()
    os.exit(1)
end
print("  Upload successful!")
print("  Address: " .. address:to_hex())
print("  PASS\n")

-- Test 5: Download data
print("Test 5: Download data from network...")
local download_ok, downloaded_data = pcall(function()
    return client:data_get_public(address:to_hex())
end)

if not download_ok then
    print("  ERROR: Download failed: " .. tostring(downloaded_data))
    wallet:dispose()
    client:dispose()
    os.exit(1)
end
print("  Download successful!")
print("  Downloaded size: " .. #downloaded_data .. " bytes")
print("  PASS\n")

-- Test 6: Verify data
print("Test 6: Verify data integrity...")
if downloaded_data == test_data then
    print("  Data matches! Round-trip successful!")
    print("  PASS\n")
else
    print("  ERROR: Data mismatch!")
    print("  Original:   " .. #test_data .. " bytes")
    print("  Downloaded: " .. #downloaded_data .. " bytes")
    wallet:dispose()
    client:dispose()
    os.exit(1)
end

-- Cleanup
print("Cleanup...")
wallet:dispose()
client:dispose()
print("  Resources disposed\n")

print("=== All Round-Trip Tests Passed! ===")
