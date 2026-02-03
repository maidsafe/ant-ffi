--[[
  Tests for cryptographic key functionality

  Run with: luajit test/test_keys.lua
]]

-- Add paths for running from lua directory: luajit test/test_keys.lua
package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

local function test_secret_key_random()
    local ant = require("ant_ffi")

    local key = ant.SecretKey.random()
    assert(key, "Should create random key")

    local hex = key:to_hex()
    assert(type(hex) == "string", "to_hex should return string")
    assert(#hex > 0, "Hex should not be empty")
    print("Random key: " .. hex:sub(1, 32) .. "...")

    key:dispose()
    print("PASS: secret_key_random")
end

local function test_secret_key_from_hex()
    local ant = require("ant_ffi")

    -- Create a key, get its hex, then recreate from hex
    local key1 = ant.SecretKey.random()
    local hex = key1:to_hex()

    local key2 = ant.SecretKey.from_hex(hex)
    local hex2 = key2:to_hex()

    assert(hex == hex2, "Keys should match after round-trip")

    key1:dispose()
    key2:dispose()
    print("PASS: secret_key_from_hex")
end

local function test_public_key()
    local ant = require("ant_ffi")

    local secret = ant.SecretKey.random()
    local public = secret:public_key()

    assert(public, "Should get public key from secret key")

    local hex = public:to_hex()
    assert(type(hex) == "string", "to_hex should return string")
    assert(#hex > 0, "Public key hex should not be empty")
    print("Public key: " .. hex:sub(1, 32) .. "...")

    -- Same secret key should produce same public key
    local public2 = secret:public_key()
    assert(public:to_hex() == public2:to_hex(), "Same secret should produce same public")

    secret:dispose()
    public:dispose()
    public2:dispose()
    print("PASS: public_key")
end

local function test_public_key_from_hex()
    local ant = require("ant_ffi")

    local secret = ant.SecretKey.random()
    local public1 = secret:public_key()
    local hex = public1:to_hex()

    local public2 = ant.PublicKey.from_hex(hex)
    assert(public2:to_hex() == hex, "Public key should round-trip through hex")

    secret:dispose()
    public1:dispose()
    public2:dispose()
    print("PASS: public_key_from_hex")
end

local function test_multiple_keys()
    local ant = require("ant_ffi")

    -- Create multiple different keys
    local keys = {}
    for i = 1, 5 do
        keys[i] = ant.SecretKey.random()
    end

    -- All keys should be unique
    local hexes = {}
    for i, key in ipairs(keys) do
        hexes[i] = key:to_hex()
    end

    for i = 1, #hexes do
        for j = i + 1, #hexes do
            assert(hexes[i] ~= hexes[j], "Keys should be unique")
        end
    end

    -- Cleanup
    for _, key in ipairs(keys) do
        key:dispose()
    end

    print("PASS: multiple_keys")
end

local function test_key_garbage_collection()
    local ant = require("ant_ffi")

    -- Create keys and let them be GC'd
    for i = 1, 10 do
        local key = ant.SecretKey.random()
        local _ = key:to_hex()
        -- Key goes out of scope and should be collected
    end

    -- Force garbage collection
    collectgarbage("collect")
    collectgarbage("collect")

    -- If we got here without crash, GC cleanup works
    print("PASS: key_garbage_collection")
end

-- Run tests
print("\n=== Key Tests ===\n")

local tests = {
    test_secret_key_random,
    test_secret_key_from_hex,
    test_public_key,
    test_public_key_from_hex,
    test_multiple_keys,
    test_key_garbage_collection,
}

for _, test in ipairs(tests) do
    local ok, err = pcall(test)
    if not ok then
        print("FAIL: " .. tostring(err))
    end
end

print("\n=== Tests Complete ===\n")
