--[[
  Comprehensive type tests for ant_ffi (matching C# DataTypeTests.cs)

  Run with: luajit test/test_all_types.lua
]]

-- Add paths for running from lua directory
package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

local ant = require("ant_ffi")

-- =============================================================================
-- Chunk Tests
-- =============================================================================

local function test_chunk_create()
    local data = "Test chunk data"
    local chunk = ant.Chunk.new(data)

    assert(chunk, "Should create chunk")
    assert(chunk:size() == #data, "Chunk size should match data length")

    chunk:dispose()
    print("PASS: Chunk_Create")
end

local function test_chunk_value()
    local data = "Test chunk data"
    local chunk = ant.Chunk.new(data)

    local retrieved = chunk:value()
    assert(retrieved == data, "Chunk value should match original")

    chunk:dispose()
    print("PASS: Chunk_Value")
end

local function test_chunk_address()
    local data = "Test chunk data for address"
    local chunk = ant.Chunk.new(data)

    local address = chunk:address()
    assert(address, "Should get address from chunk")

    local hex = address:to_hex()
    assert(type(hex) == "string", "Address hex should be string")
    assert(#hex == 64, "Address should be 64 hex chars")

    chunk:dispose()
    address:dispose()
    print("PASS: Chunk_Address")
end

local function test_chunk_address_roundtrip()
    local data = "Test chunk data"
    local chunk = ant.Chunk.new(data)
    local original = chunk:address()
    local hex = original:to_hex()

    local restored = ant.ChunkAddress.from_hex(hex)
    assert(original:to_hex() == restored:to_hex(), "Address should roundtrip through hex")

    chunk:dispose()
    original:dispose()
    restored:dispose()
    print("PASS: ChunkAddress_Roundtrip")
end

local function test_chunk_same_data_same_address()
    local data = "Deterministic chunk data"

    local chunk1 = ant.Chunk.new(data)
    local chunk2 = ant.Chunk.new(data)
    local addr1 = chunk1:address()
    local addr2 = chunk2:address()

    assert(addr1:to_hex() == addr2:to_hex(), "Same data should produce same address")

    chunk1:dispose()
    chunk2:dispose()
    addr1:dispose()
    addr2:dispose()
    print("PASS: Chunk_SameData_SameAddress")
end

local function test_chunk_constants()
    local maxSize = ant.chunk_max_size()
    local maxRawSize = ant.chunk_max_raw_size()

    assert(maxSize > 0, "Max size should be > 0")
    assert(maxRawSize > 0, "Max raw size should be > 0")
    assert(maxRawSize <= maxSize, "Raw size should be <= total max size")

    print("PASS: ChunkConstants")
end

-- =============================================================================
-- DataAddress Tests
-- =============================================================================

local function test_data_address_roundtrip()
    -- Create a valid hex address (64 chars = 32 bytes)
    local hex = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

    local address = ant.DataAddress.from_hex(hex)
    local restored_hex = address:to_hex()

    assert(hex == restored_hex, "DataAddress should roundtrip through hex")

    address:dispose()
    print("PASS: DataAddress_Roundtrip")
end

-- =============================================================================
-- Pointer Tests
-- =============================================================================

local function test_pointer_address_from_public_key()
    local secretKey = ant.SecretKey.random()
    local publicKey = secretKey:public_key()

    local address = ant.PointerAddress.new(publicKey)
    assert(address, "Should create pointer address")

    local hex = address:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Should have valid hex")

    secretKey:dispose()
    publicKey:dispose()
    address:dispose()
    print("PASS: PointerAddress_FromPublicKey")
end

local function test_pointer_address_roundtrip()
    local secretKey = ant.SecretKey.random()
    local publicKey = secretKey:public_key()
    local original = ant.PointerAddress.new(publicKey)
    local hex = original:to_hex()

    local restored = ant.PointerAddress.from_hex(hex)
    assert(original:to_hex() == restored:to_hex(), "PointerAddress should roundtrip")

    secretKey:dispose()
    publicKey:dispose()
    original:dispose()
    restored:dispose()
    print("PASS: PointerAddress_Roundtrip")
end

local function test_pointer_target_to_chunk()
    local data = "Test data"
    local chunk = ant.Chunk.new(data)
    local chunkAddress = chunk:address()

    local target = ant.PointerTarget.chunk(chunkAddress)
    assert(target, "Should create pointer target")

    local hex = target:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Target should have valid hex")

    chunk:dispose()
    chunkAddress:dispose()
    target:dispose()
    print("PASS: PointerTarget_ToChunk")
end

local function test_network_pointer_create()
    local secretKey = ant.SecretKey.random()
    local data = "Test data"
    local chunk = ant.Chunk.new(data)
    local chunkAddress = chunk:address()
    local target = ant.PointerTarget.chunk(chunkAddress)

    local pointer = ant.NetworkPointer.new(secretKey, 0, target)
    assert(pointer, "Should create network pointer")
    assert(pointer:counter() == 0, "Counter should be 0")

    secretKey:dispose()
    chunk:dispose()
    chunkAddress:dispose()
    target:dispose()
    pointer:dispose()
    print("PASS: NetworkPointer_Create")
end

local function test_network_pointer_address()
    local secretKey = ant.SecretKey.random()
    local data = "Test data"
    local chunk = ant.Chunk.new(data)
    local chunkAddress = chunk:address()
    local target = ant.PointerTarget.chunk(chunkAddress)
    local pointer = ant.NetworkPointer.new(secretKey, 1, target)

    local address = pointer:address()
    assert(address, "Should get address from pointer")

    local hex = address:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Address should have valid hex")

    secretKey:dispose()
    chunk:dispose()
    chunkAddress:dispose()
    target:dispose()
    pointer:dispose()
    address:dispose()
    print("PASS: NetworkPointer_Address")
end

-- =============================================================================
-- Scratchpad Tests
-- =============================================================================

local function test_scratchpad_address_from_public_key()
    local secretKey = ant.SecretKey.random()
    local publicKey = secretKey:public_key()

    local address = ant.ScratchpadAddress.new(publicKey)
    assert(address, "Should create scratchpad address")

    local hex = address:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Should have valid hex")

    secretKey:dispose()
    publicKey:dispose()
    address:dispose()
    print("PASS: ScratchpadAddress_FromPublicKey")
end

local function test_scratchpad_create()
    local secretKey = ant.SecretKey.random()
    local data = "Test scratchpad data"

    local scratchpad = ant.Scratchpad.new(secretKey, 0, data, 0)
    assert(scratchpad, "Should create scratchpad")
    assert(scratchpad:data_encoding() == 0, "Data encoding should be 0")
    assert(scratchpad:counter() == 0, "Counter should be 0")

    secretKey:dispose()
    scratchpad:dispose()
    print("PASS: Scratchpad_Create")
end

local function test_scratchpad_decrypt()
    local secretKey = ant.SecretKey.random()
    local originalData = "Test scratchpad data for decryption"

    local scratchpad = ant.Scratchpad.new(secretKey, 0, originalData, 0)
    local decrypted = scratchpad:decrypt_data(secretKey)

    assert(decrypted == originalData, "Decrypted data should match original")

    secretKey:dispose()
    scratchpad:dispose()
    print("PASS: Scratchpad_Decrypt")
end

-- =============================================================================
-- Register Tests
-- =============================================================================

local function test_register_address_from_public_key()
    local secretKey = ant.SecretKey.random()
    local publicKey = secretKey:public_key()

    local address = ant.RegisterAddress.new(publicKey)
    assert(address, "Should create register address")

    local hex = address:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Should have valid hex")

    secretKey:dispose()
    publicKey:dispose()
    address:dispose()
    print("PASS: RegisterAddress_FromPublicKey")
end

local function test_register_key_from_name()
    local secretKey = ant.SecretKey.random()

    local registerKey = ant.register_key_from_name(secretKey, "my-register")
    assert(registerKey, "Should create register key")

    local hex = registerKey:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Should have valid hex")

    secretKey:dispose()
    registerKey:dispose()
    print("PASS: RegisterHelpers_KeyFromName")
end

local function test_register_value_from_bytes()
    local data = "Test data to hash into 32 bytes"

    local value = ant.register_value_from_bytes(data)
    assert(#value == 32, "Value should be 32 bytes")

    print("PASS: RegisterHelpers_ValueFromBytes")
end

-- =============================================================================
-- GraphEntry Tests
-- =============================================================================

local function test_graph_entry_address_from_public_key()
    local secretKey = ant.SecretKey.random()
    local publicKey = secretKey:public_key()

    local address = ant.GraphEntryAddress.new(publicKey)
    assert(address, "Should create graph entry address")

    local hex = address:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Should have valid hex")

    secretKey:dispose()
    publicKey:dispose()
    address:dispose()
    print("PASS: GraphEntryAddress_FromPublicKey")
end

local function test_graph_entry_address_roundtrip()
    local secretKey = ant.SecretKey.random()
    local publicKey = secretKey:public_key()
    local original = ant.GraphEntryAddress.new(publicKey)
    local hex = original:to_hex()

    local restored = ant.GraphEntryAddress.from_hex(hex)
    assert(original:to_hex() == restored:to_hex(), "GraphEntryAddress should roundtrip")

    secretKey:dispose()
    publicKey:dispose()
    original:dispose()
    restored:dispose()
    print("PASS: GraphEntryAddress_Roundtrip")
end

-- =============================================================================
-- Vault Tests
-- =============================================================================

local function test_vault_secret_key_random()
    local key = ant.VaultSecretKey.random()
    assert(key, "Should create vault secret key")

    local hex = key:to_hex()
    assert(type(hex) == "string" and #hex > 0, "Should have valid hex")

    key:dispose()
    print("PASS: VaultSecretKey_Random")
end

local function test_vault_secret_key_roundtrip()
    local original = ant.VaultSecretKey.random()
    local hex = original:to_hex()

    local restored = ant.VaultSecretKey.from_hex(hex)
    assert(original:to_hex() == restored:to_hex(), "VaultSecretKey should roundtrip")

    original:dispose()
    restored:dispose()
    print("PASS: VaultSecretKey_Roundtrip")
end

local function test_user_data_create()
    local userData = ant.UserData.new()
    assert(userData, "Should create user data")

    userData:dispose()
    print("PASS: UserData_Create")
end

-- =============================================================================
-- Network Tests
-- =============================================================================

local function test_network_create_local()
    local network = ant.Network.new(true)
    assert(network, "Should create local network")

    network:dispose()
    print("PASS: Network_Create_Local")
end

-- =============================================================================
-- Run All Tests
-- =============================================================================

print("\n=== Comprehensive Type Tests ===\n")

local tests = {
    -- Chunk tests
    test_chunk_create,
    test_chunk_value,
    test_chunk_address,
    test_chunk_address_roundtrip,
    test_chunk_same_data_same_address,
    test_chunk_constants,

    -- DataAddress tests
    test_data_address_roundtrip,

    -- Pointer tests
    test_pointer_address_from_public_key,
    test_pointer_address_roundtrip,
    test_pointer_target_to_chunk,
    test_network_pointer_create,
    test_network_pointer_address,

    -- Scratchpad tests
    test_scratchpad_address_from_public_key,
    test_scratchpad_create,
    test_scratchpad_decrypt,

    -- Register tests
    test_register_address_from_public_key,
    test_register_key_from_name,
    test_register_value_from_bytes,

    -- GraphEntry tests
    test_graph_entry_address_from_public_key,
    test_graph_entry_address_roundtrip,

    -- Vault tests
    test_vault_secret_key_random,
    test_vault_secret_key_roundtrip,
    test_user_data_create,

    -- Network tests
    test_network_create_local,
}

local passed = 0
local failed = 0

for _, test in ipairs(tests) do
    local ok, err = pcall(test)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("FAIL: " .. tostring(err))
    end
end

print(string.format("\n=== Results: %d passed, %d failed ===\n", passed, failed))
