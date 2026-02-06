--[[
  Integration tests for file operations and data_cost

  This test:
  1. Tests data_cost estimation
  2. Tests file_upload_public and file_download_public
  3. Tests file_upload (private) and file_download (private)

  Requirements:
  - Local Autonomi network running (antctl local status)
  - Local EVM testnet running (evm-testnet)

  Run with: luajit test/test_file_ops.lua
]]

package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

io.stdout:setvbuf("no")

print("=== File Operations Integration Test ===\n")

local ant = require("ant_ffi")
local client_mod = require("ant_ffi.client")
local ffi = require("ffi")

-- Helper to generate random data
local function random_data(size)
    local chars = {}
    for i = 1, size do
        chars[i] = string.char(math.random(0, 255))
    end
    return table.concat(chars)
end

-- Helper to write a temp file
local function write_temp_file(content)
    local filename = os.tmpname()
    local f = io.open(filename, "wb")
    if not f then
        error("Failed to create temp file: " .. filename)
    end
    f:write(content)
    f:close()
    return filename
end

-- Helper to read a file
local function read_file(filename)
    local f = io.open(filename, "rb")
    if not f then
        error("Failed to read file: " .. filename)
    end
    local content = f:read("*all")
    f:close()
    return content
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

-- Test 4: Data cost estimation
print("Test 4: Data cost estimation...")
math.randomseed(os.time())
local test_data = "Test data for cost estimation " .. os.date()

local cost_ok, cost = pcall(function()
    return client:data_cost(test_data)
end)

if not cost_ok then
    print("  ERROR: data_cost failed: " .. tostring(cost))
    wallet:dispose()
    client:dispose()
    os.exit(1)
end
print("  Data size: " .. #test_data .. " bytes")
print("  Estimated cost: " .. cost)
print("  PASS\n")

-- Test 5: File cost estimation
print("Test 5: File cost estimation...")

-- Create a test file for cost estimation
local cost_test_content = "Test content for file cost estimation " .. os.date()
local cost_test_file = write_temp_file(cost_test_content)
print("  Created test file: " .. cost_test_file)
print("  File size: " .. #cost_test_content .. " bytes")

local file_cost_ok, file_cost = pcall(function()
    return client:file_cost(cost_test_file)
end)

if not file_cost_ok then
    print("  ERROR: file_cost failed: " .. tostring(file_cost))
    os.remove(cost_test_file)
    wallet:dispose()
    client:dispose()
    os.exit(1)
end
print("  Estimated file cost: " .. file_cost)
os.remove(cost_test_file)
print("  PASS\n")

-- Test 6: File upload/download (public)
print("Test 6: File upload/download (public)...")

-- Create a test file
local file_content = "Hello from Lua FFI file upload test! " .. os.date() .. " " .. random_data(100)
local test_file = write_temp_file(file_content)
print("  Created test file: " .. test_file)
print("  File size: " .. #file_content .. " bytes")

-- Upload
local upload_public_ok, result_public = pcall(function()
    return client:file_upload_public(test_file, wallet)
end)

if not upload_public_ok then
    print("  ERROR: file_upload_public failed: " .. tostring(result_public))
    os.remove(test_file)
    wallet:dispose()
    client:dispose()
    os.exit(1)
end

local address, upload_cost = result_public, nil
if type(result_public) == "table" or (type(result_public) ~= "string" and result_public.to_hex) then
    -- result_public is the DataAddress
    address = result_public
end
print("  Upload successful!")
print("  Address: " .. address:to_hex())

-- Download
local download_file = os.tmpname()
local download_public_ok, download_err = pcall(function()
    return client:file_download_public(address, download_file)
end)

if not download_public_ok then
    print("  ERROR: file_download_public failed: " .. tostring(download_err))
    os.remove(test_file)
    wallet:dispose()
    client:dispose()
    os.exit(1)
end
print("  Download successful!")

-- Verify
local downloaded_content = read_file(download_file)
if downloaded_content == file_content then
    print("  File content matches! Round-trip successful!")
    print("  PASS\n")
else
    print("  ERROR: File content mismatch!")
    print("  Original size:   " .. #file_content .. " bytes")
    print("  Downloaded size: " .. #downloaded_content .. " bytes")
    os.remove(test_file)
    os.remove(download_file)
    wallet:dispose()
    client:dispose()
    os.exit(1)
end

-- Cleanup test files
os.remove(test_file)
os.remove(download_file)

-- Test 7: File upload/download (private) - requires larger file for self-encryption
print("Test 7: File upload/download (private)...")
print("  Note: Private files require self-encryption (>1MB recommended)")

-- Create a larger test file (needs to be at least 3 chunks for self-encryption)
local large_content = random_data(4 * 1024 * 1024)  -- 4MB
local large_test_file = write_temp_file(large_content)
print("  Created large test file: " .. large_test_file)
print("  File size: " .. #large_content .. " bytes")

-- Upload private
local upload_private_ok, result_private = pcall(function()
    return client:file_upload(large_test_file, wallet)
end)

if not upload_private_ok then
    print("  ERROR: file_upload (private) failed: " .. tostring(result_private))
    os.remove(large_test_file)
    wallet:dispose()
    client:dispose()
    os.exit(1)
end

local data_map = result_private
print("  Upload successful!")
print("  DataMap address: " .. data_map:address())

-- Download private
local download_private_file = os.tmpname()
local download_private_ok, download_private_err = pcall(function()
    return client:file_download(data_map, download_private_file)
end)

if not download_private_ok then
    print("  ERROR: file_download (private) failed: " .. tostring(download_private_err))
    os.remove(large_test_file)
    data_map:dispose()
    wallet:dispose()
    client:dispose()
    os.exit(1)
end
print("  Download successful!")

-- Verify
local downloaded_private_content = read_file(download_private_file)
if downloaded_private_content == large_content then
    print("  File content matches! Private round-trip successful!")
    print("  PASS\n")
else
    print("  ERROR: File content mismatch!")
    print("  Original size:   " .. #large_content .. " bytes")
    print("  Downloaded size: " .. #downloaded_private_content .. " bytes")
    os.remove(large_test_file)
    os.remove(download_private_file)
    data_map:dispose()
    wallet:dispose()
    client:dispose()
    os.exit(1)
end

-- Cleanup
os.remove(large_test_file)
os.remove(download_private_file)
data_map:dispose()

-- Final cleanup
print("Cleanup...")
wallet:dispose()
client:dispose()
print("  Resources disposed\n")

print("=== All File Operations Tests Passed! ===")
