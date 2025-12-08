/**
 * JVM Unit tests for Autonomi register functionality. These tests run on the host JVM
 * without requiring an Android emulator.
 */
package com.maidsafe.autonomi.core

import org.junit.Assert.*
import org.junit.Test
import uniffi.ant_ffi.*

class RegisterTest {

    @Test
    fun testRegisterAddressCreation() {
        // Create a register address from a public key
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        val addr = RegisterAddress(pk)
        assertNotNull("RegisterAddress should not be null", addr)

        // Verify hex serialization
        val hex = addr.toHex()
        assertTrue("Hex should not be empty", hex.isNotEmpty())
    }

    @Test
    fun testRegisterAddressHexRoundtrip() {
        // Create a register address and verify hex roundtrip
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        val addr = RegisterAddress(pk)
        val hex = addr.toHex()

        val restored = RegisterAddress.fromHex(hex)
        assertEquals("Hex roundtrip should preserve address", hex, restored.toHex())
    }

    @Test
    fun testRegisterAddressOwner() {
        // Verify the owner relationship
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        val addr = RegisterAddress(pk)
        val owner = addr.owner()

        assertEquals("Owner should match original public key", pk.toHex(), owner.toHex())
    }

    @Test
    fun testRegisterKeyFromName() {
        // Test deriving register keys from names
        val masterSk = SecretKey.random()

        val key1 = registerKeyFromName(masterSk, "register1")
        val key2 = registerKeyFromName(masterSk, "register2")
        val key1Again = registerKeyFromName(masterSk, "register1")

        // Same name should derive same key
        assertEquals(
            "Same name should derive same key",
            key1.publicKey().toHex(),
            key1Again.publicKey().toHex()
        )

        // Different names should derive different keys
        assertNotEquals(
            "Different names should derive different keys",
            key1.publicKey().toHex(),
            key2.publicKey().toHex()
        )
    }

    @Test
    fun testRegisterKeyFromNameDifferentOwners() {
        // Different owners with same name should get different keys
        val sk1 = SecretKey.random()
        val sk2 = SecretKey.random()

        val key1 = registerKeyFromName(sk1, "myregister")
        val key2 = registerKeyFromName(sk2, "myregister")

        assertNotEquals(
            "Different owners should get different keys",
            key1.publicKey().toHex(),
            key2.publicKey().toHex()
        )
    }

    @Test
    fun testRegisterKeyFromNameMultipleRegisters() {
        // Test creating multiple unique register keys from a single master key
        val masterSk = SecretKey.random()
        val keys = mutableSetOf<String>()

        for (i in 1..10) {
            val key = registerKeyFromName(masterSk, "register$i")
            val hex = key.publicKey().toHex()
            assertTrue("Register keys should be unique", keys.add(hex))
        }

        assertEquals("Should have 10 unique keys", 10, keys.size)
    }

    @Test
    fun testRegisterValueFromBytes() {
        // Test creating register value from exact 32 bytes
        val bytes = ByteArray(32) { it.toByte() }
        val value = registerValueFromBytes(bytes.toList())

        assertEquals("Value should be 32 bytes", 32, value.size)
        assertArrayEquals("Value should match input", bytes, value.toByteArray())
    }

    @Test
    fun testRegisterValueFromBytesPadding() {
        // Test that shorter values get padded
        val shortBytes = ByteArray(16) { it.toByte() }
        val value = registerValueFromBytes(shortBytes.toList())

        assertEquals("Value should be padded to 32 bytes", 32, value.size)

        // First 16 bytes should match input
        for (i in 0 until 16) {
            assertEquals("First bytes should match", shortBytes[i], value[i])
        }

        // Remaining bytes should be zero
        for (i in 16 until 32) {
            assertEquals("Padding should be zeros", 0.toByte(), value[i])
        }
    }

    @Test
    fun testRegisterValueFromBytesEmpty() {
        // Test with empty input
        val emptyBytes = ByteArray(0)
        val value = registerValueFromBytes(emptyBytes.toList())

        assertEquals("Empty input should produce 32 zero bytes", 32, value.size)
        assertTrue("All bytes should be zero", value.all { it == 0.toByte() })
    }

    @Test
    fun testRegisterValueFromBytesTooLong() {
        // Test that values over 32 bytes are rejected
        val tooLong = ByteArray(64) { it.toByte() }

        try {
            registerValueFromBytes(tooLong.toList())
            fail("Should throw for values over 32 bytes")
        } catch (e: RegisterException.InvalidRegister) {
            assertTrue("Error should mention size", e.reason.isNotEmpty())
        }
    }

    @Test
    fun testInvalidRegisterAddressHex() {
        // Test that invalid hex throws an error
        val invalidHex = "not-valid-hex"

        try {
            RegisterAddress.fromHex(invalidHex)
            fail("Should throw for invalid hex")
        } catch (e: RegisterException.ParsingFailed) {
            assertTrue("Error should mention parsing", e.reason.isNotEmpty())
        }
    }

    @Test
    fun testClientRegisterHistoryMethodExists() {
        // Verify Client has the register_history_collect method
        val clientClass = Client::class.java
        val methodNames = clientClass.declaredMethods.map { it.name }

        assertTrue(
            "Client should have registerHistoryCollect method",
            methodNames.contains("registerHistoryCollect")
        )
    }

    @Test
    fun testRegisterValueUseCases() {
        // Test common use cases for register values

        // Use case 1: Store a 32-byte hash
        val hash = ByteArray(32) { (it * 7).toByte() }
        val hashValue = registerValueFromBytes(hash.toList())
        assertEquals("Hash should be stored exactly", 32, hashValue.size)

        // Use case 2: Store a counter (8 bytes)
        val counter = ByteArray(8)
        // Write 12345678L in big-endian
        val num = 12345678L
        for (i in 0 until 8) {
            counter[7 - i] = ((num shr (i * 8)) and 0xFF).toByte()
        }
        val counterValue = registerValueFromBytes(counter.toList())
        assertEquals("Counter should be padded", 32, counterValue.size)

        // Use case 3: Store a string reference
        val stringRef = "Hello".toByteArray(Charsets.UTF_8)
        val stringValue = registerValueFromBytes(stringRef.toList())
        assertEquals("String should be padded", 32, stringValue.size)
    }

    @Test
    fun testRegisterKeyNamingPatterns() {
        // Test various naming patterns for register keys
        val masterSk = SecretKey.random()

        // App-specific registers
        val userSettings = registerKeyFromName(masterSk, "app.settings.user")
        val appConfig = registerKeyFromName(masterSk, "app.settings.config")

        // Versioned registers
        val v1 = registerKeyFromName(masterSk, "data/v1")
        val v2 = registerKeyFromName(masterSk, "data/v2")

        // All should be unique
        val keys = setOf(
            userSettings.publicKey().toHex(),
            appConfig.publicKey().toHex(),
            v1.publicKey().toHex(),
            v2.publicKey().toHex()
        )
        assertEquals("All named registers should be unique", 4, keys.size)
    }
}
