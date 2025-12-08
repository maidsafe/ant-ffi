/**
 * JVM Unit tests for Autonomi pointer functionality. These tests run on the host JVM
 * without requiring an Android emulator.
 */
package com.maidsafe.autonomi.core

import org.junit.Assert.*
import org.junit.Test
import uniffi.ant_ffi.*

class PointerTest {

    @Test
    fun testPointerAddressCreation() {
        // Create a pointer address from a public key
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        val addr = PointerAddress(pk)
        assertNotNull("PointerAddress should not be null", addr)

        // Verify hex serialization
        val hex = addr.toHex()
        assertTrue("Hex should not be empty", hex.isNotEmpty())
    }

    @Test
    fun testPointerAddressHexRoundtrip() {
        // Create a pointer address and verify hex roundtrip
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        val addr = PointerAddress(pk)
        val hex = addr.toHex()

        val restored = PointerAddress.fromHex(hex)
        assertEquals("Hex roundtrip should preserve address", hex, restored.toHex())
    }

    @Test
    fun testPointerAddressOwner() {
        // Verify the owner relationship
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        val addr = PointerAddress(pk)
        val owner = addr.owner()

        assertEquals("Owner should match original public key", pk.toHex(), owner.toHex())
    }

    @Test
    fun testPointerTargetChunk() {
        // Create a pointer target pointing to a chunk
        val testData = "Test chunk data".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val chunkAddr = ChunkAddress.fromHex(encrypted.datamapChunk.toHex())

        val target = PointerTarget.chunk(chunkAddr)
        assertNotNull("PointerTarget should not be null", target)

        // Verify hex serialization
        val hex = target.toHex()
        assertTrue("Hex should not be empty", hex.isNotEmpty())
    }

    @Test
    fun testPointerTargetPointer() {
        // Create a pointer target pointing to another pointer
        val sk = SecretKey.random()
        val pk = sk.publicKey()
        val pointerAddr = PointerAddress(pk)

        val target = PointerTarget.pointer(pointerAddr)
        assertNotNull("PointerTarget should not be null", target)

        val hex = target.toHex()
        assertTrue("Hex should not be empty", hex.isNotEmpty())
    }

    @Test
    fun testPointerTargetGraphEntry() {
        // Create a pointer target pointing to a graph entry
        val sk = SecretKey.random()
        val pk = sk.publicKey()
        val graphAddr = GraphEntryAddress(pk)

        val target = PointerTarget.graphEntry(graphAddr)
        assertNotNull("PointerTarget should not be null", target)

        val hex = target.toHex()
        assertTrue("Hex should not be empty", hex.isNotEmpty())
    }

    @Test
    fun testPointerTargetScratchpad() {
        // Create a pointer target pointing to a scratchpad
        val sk = SecretKey.random()
        val pk = sk.publicKey()
        val scratchpadAddr = ScratchpadAddress(pk)

        val target = PointerTarget.scratchpad(scratchpadAddr)
        assertNotNull("PointerTarget should not be null", target)

        val hex = target.toHex()
        assertTrue("Hex should not be empty", hex.isNotEmpty())
    }

    @Test
    fun testAllPointerTargetTypesAvailable() {
        // Verify all target type constructors are available
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        // Create test data for chunk
        val testData = "Test".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val chunkAddr = ChunkAddress.fromHex(encrypted.datamapChunk.toHex())

        // All four target types should be creatable
        val targets = listOf(
            PointerTarget.chunk(chunkAddr),
            PointerTarget.pointer(PointerAddress(pk)),
            PointerTarget.graphEntry(GraphEntryAddress(pk)),
            PointerTarget.scratchpad(ScratchpadAddress(pk))
        )

        assertEquals("Should have 4 target types", 4, targets.size)
        targets.forEach { target ->
            assertNotNull("Target should not be null", target)
            assertTrue("Target hex should not be empty", target.toHex().isNotEmpty())
        }
    }

    @Test
    fun testPointerTargetHexRoundtrip() {
        // Test hex roundtrip for chunk target
        val testData = "Test chunk data".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val chunkAddr = ChunkAddress.fromHex(encrypted.datamapChunk.toHex())

        val target = PointerTarget.chunk(chunkAddr)
        val hex = target.toHex()

        val restored = PointerTarget.fromHex(hex)
        assertEquals("Hex roundtrip should preserve target", hex, restored.toHex())
    }

    @Test
    fun testNetworkPointerCreation() {
        // Create a NetworkPointer using new()
        val sk = SecretKey.random()
        val testData = "Test".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val chunkAddr = ChunkAddress.fromHex(encrypted.datamapChunk.toHex())
        val target = PointerTarget.chunk(chunkAddr)

        val pointer = NetworkPointer(sk, target)
        assertNotNull("NetworkPointer should not be null", pointer)

        // Check counter starts at 0
        assertEquals("Counter should start at 0", 0u, pointer.counter())

        // Check address
        val addr = pointer.address()
        assertNotNull("Address should not be null", addr)
    }

    @Test
    fun testNetworkPointerTarget() {
        // Verify we can get the target from a pointer
        val sk = SecretKey.random()
        val testData = "Test".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val chunkAddr = ChunkAddress.fromHex(encrypted.datamapChunk.toHex())
        val originalTarget = PointerTarget.chunk(chunkAddr)

        val pointer = NetworkPointer(sk, originalTarget)
        val retrievedTarget = pointer.target()

        assertEquals(
            "Retrieved target should match original",
            originalTarget.toHex(),
            retrievedTarget.toHex()
        )
    }

    @Test
    fun testNetworkPointerWithCounter() {
        // Create a pointer with a specific counter
        val sk = SecretKey.random()
        val testData = "Test".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val chunkAddr = ChunkAddress.fromHex(encrypted.datamapChunk.toHex())
        val target = PointerTarget.chunk(chunkAddr)

        val pointer = NetworkPointer.withCounter(sk, target, 42u)

        assertEquals("Counter should be 42", 42u, pointer.counter())
    }

    @Test
    fun testNetworkPointerOwner() {
        // Verify the owner public key is correctly derived
        val sk = SecretKey.random()
        val pk = sk.publicKey()
        val testData = "Test".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val chunkAddr = ChunkAddress.fromHex(encrypted.datamapChunk.toHex())
        val target = PointerTarget.chunk(chunkAddr)

        val pointer = NetworkPointer(sk, target)
        val owner = pointer.owner()

        assertEquals("Owner should match public key", pk.toHex(), owner.toHex())
    }

    @Test
    fun testClientExistenceCheckMethodsExist() {
        // Verify Client has existence check methods
        val clientClass = Client::class.java
        val methodNames = clientClass.declaredMethods.map { it.name }

        assertTrue(
            "Client should have pointerCheckExistence method",
            methodNames.contains("pointerCheckExistence")
        )
        assertTrue(
            "Client should have scratchpadCheckExistence method",
            methodNames.contains("scratchpadCheckExistence")
        )
    }

    @Test
    fun testInvalidPointerAddressHex() {
        // Test that invalid hex throws an error
        val invalidHex = "not-valid-hex"

        try {
            PointerAddress.fromHex(invalidHex)
            fail("Should throw for invalid hex")
        } catch (e: PointerException.ParsingFailed) {
            assertTrue("Error should mention parsing", e.reason.isNotEmpty())
        }
    }

    @Test
    fun testInvalidPointerTargetHex() {
        // Test that invalid hex throws an error
        val invalidHex = "not-valid-hex"

        try {
            PointerTarget.fromHex(invalidHex)
            fail("Should throw for invalid hex")
        } catch (e: PointerException.ParsingFailed) {
            assertTrue("Error should mention parsing", e.reason.isNotEmpty())
        }
    }
}
