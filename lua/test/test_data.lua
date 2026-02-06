--[[
  Tests for data types (Chunk, ChunkAddress, DataAddress, DataMapChunk)

  Run with: luajit test/test_data.lua
]]

-- Add paths for running from lua directory: luajit test/test_data.lua
package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

local function test_chunk_creation()
    local ant = require("ant_ffi")

    local data = "Hello, this is chunk data!"
    local chunk = ant.Chunk.new(data)

    assert(chunk, "Should create chunk")

    local value = chunk:value()
    assert(value == data, "Chunk value should match original data")

    local size = chunk:size()
    assert(size > 0, "Chunk should have size > 0")
    print(string.format("Chunk size: %d bytes", size))

    local is_too_big = chunk:is_too_big()
    assert(not is_too_big, "Small chunk should not be too big")

    chunk:dispose()
    print("PASS: chunk_creation")
end

local function test_chunk_address()
    local ant = require("ant_ffi")

    local data = "Content-addressable data"
    local chunk = ant.Chunk.new(data)

    local address = chunk:address()
    assert(address, "Should get address from chunk")

    local hex = address:to_hex()
    assert(type(hex) == "string", "Address hex should be string")
    assert(#hex == 64, "Address should be 32 bytes (64 hex chars)")
    print("Chunk address: " .. hex)

    -- Same data should produce same address
    local chunk2 = ant.Chunk.new(data)
    local address2 = chunk2:address()
    assert(address:to_hex() == address2:to_hex(), "Same data should produce same address")

    chunk:dispose()
    chunk2:dispose()
    address:dispose()
    address2:dispose()
    print("PASS: chunk_address")
end

local function test_chunk_address_from_content()
    local ant = require("ant_ffi")

    local data = "Test content for address"
    local address = ant.ChunkAddress.from_content(data)

    assert(address, "Should create address from content")

    local hex = address:to_hex()
    assert(#hex == 64, "Address should be 64 hex chars")

    -- Verify it matches chunk-derived address
    local chunk = ant.Chunk.new(data)
    local chunk_address = chunk:address()
    assert(address:to_hex() == chunk_address:to_hex(),
        "Address from content should match chunk address")

    address:dispose()
    chunk:dispose()
    chunk_address:dispose()
    print("PASS: chunk_address_from_content")
end

local function test_chunk_address_hex_roundtrip()
    local ant = require("ant_ffi")

    local data = "Data for hex test"
    local address1 = ant.ChunkAddress.from_content(data)
    local hex = address1:to_hex()

    local address2 = ant.ChunkAddress.from_hex(hex)
    assert(address1:to_hex() == address2:to_hex(), "Address should round-trip through hex")

    address1:dispose()
    address2:dispose()
    print("PASS: chunk_address_hex_roundtrip")
end

local function test_data_address()
    local ant = require("ant_ffi")

    -- Create from hex (simulating an address received from network)
    local hex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    local address = ant.DataAddress.from_hex(hex)

    assert(address, "Should create DataAddress from hex")
    assert(address:to_hex() == hex, "DataAddress should round-trip through hex")

    address:dispose()
    print("PASS: data_address")
end

local function test_chunk_constants()
    local ant = require("ant_ffi")

    local max_size = ant.chunk_max_size()
    local max_raw_size = ant.chunk_max_raw_size()

    assert(max_size > 0, "Max chunk size should be > 0")
    assert(max_raw_size > 0, "Max raw chunk size should be > 0")

    print(string.format("Chunk max size: %d bytes", max_size))
    print(string.format("Chunk max raw size: %d bytes", max_raw_size))

    print("PASS: chunk_constants")
end

-- Run tests
print("\n=== Data Type Tests ===\n")

local tests = {
    test_chunk_creation,
    test_chunk_address,
    test_chunk_address_from_content,
    test_chunk_address_hex_roundtrip,
    test_data_address,
    test_chunk_constants,
}

for _, test in ipairs(tests) do
    local ok, err = pcall(test)
    if not ok then
        print("FAIL: " .. tostring(err))
    end
end

print("\n=== Tests Complete ===\n")
