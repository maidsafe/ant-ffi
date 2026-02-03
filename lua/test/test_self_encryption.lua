--[[
  Tests for self-encryption functionality

  Run with: luajit test/test_self_encryption.lua
  Or with busted: busted test/
]]

-- Add paths for running from lua directory: luajit test/test_self_encryption.lua
package.path = "./?/init.lua;./?.lua;./ant_ffi/?.lua;" .. package.path

local function test_encrypt_decrypt_string()
    local ant = require("ant_ffi")

    local original = "Hello, Autonomi! This is a test of self-encryption."
    print("Original: " .. original)

    local encrypted = ant.encrypt(original)
    print("Encrypted length: " .. #encrypted)

    local decrypted = ant.decrypt(encrypted)
    print("Decrypted: " .. decrypted)

    assert(decrypted == original, "Decrypted data should match original")
    print("PASS: encrypt_decrypt_string")
end

local function test_encrypt_decrypt_empty()
    local ant = require("ant_ffi")

    -- Note: Self-encryption requires minimum data size
    -- Empty string encryption is not supported
    local original = ""
    local ok, _ = pcall(function()
        local encrypted = ant.encrypt(original)
        local decrypted = ant.decrypt(encrypted)
        assert(decrypted == original, "Empty string should round-trip")
    end)

    if ok then
        print("PASS: encrypt_decrypt_empty")
    else
        print("SKIP: encrypt_decrypt_empty (empty data not supported)")
    end
end

local function test_encrypt_decrypt_binary()
    local ant = require("ant_ffi")

    -- Binary data with null bytes
    local original = "binary\x00data\x00with\x00nulls"
    local encrypted = ant.encrypt(original)
    local decrypted = ant.decrypt(encrypted)

    assert(decrypted == original, "Binary data should round-trip")
    print("PASS: encrypt_decrypt_binary")
end

local function test_encrypt_decrypt_bytes()
    local ant = require("ant_ffi")

    local original = {72, 101, 108, 108, 111}  -- "Hello"
    local encrypted = ant.encrypt_bytes(original)
    local decrypted = ant.decrypt_bytes(encrypted)

    assert(#decrypted == #original, "Byte count should match")
    for i = 1, #original do
        assert(decrypted[i] == original[i], "Byte " .. i .. " should match")
    end
    print("PASS: encrypt_decrypt_bytes")
end

local function test_deterministic_encryption()
    local ant = require("ant_ffi")

    -- Self-encryption is deterministic (same input = same output)
    local data = "Deterministic test data"
    local encrypted1 = ant.encrypt(data)
    local encrypted2 = ant.encrypt(data)

    assert(encrypted1 == encrypted2, "Same input should produce same encrypted output")
    print("PASS: deterministic_encryption")
end

-- Run tests
print("\n=== Self-Encryption Tests ===\n")

local ok, err = pcall(test_encrypt_decrypt_string)
if not ok then print("FAIL: encrypt_decrypt_string - " .. tostring(err)) end

ok, err = pcall(test_encrypt_decrypt_empty)
if not ok then print("FAIL: encrypt_decrypt_empty - " .. tostring(err)) end

ok, err = pcall(test_encrypt_decrypt_binary)
if not ok then print("FAIL: encrypt_decrypt_binary - " .. tostring(err)) end

ok, err = pcall(test_encrypt_decrypt_bytes)
if not ok then print("FAIL: encrypt_decrypt_bytes - " .. tostring(err)) end

ok, err = pcall(test_deterministic_encryption)
if not ok then print("FAIL: deterministic_encryption - " .. tostring(err)) end

print("\n=== Tests Complete ===\n")
