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
    fun testPointerTargetTypesAvailable() {
        // Verify all target type constructors are available
        val sk = SecretKey.random()
        val pk = sk.publicKey()

        // These target types should be creatable (chunk needs a valid address, skip for now)
        val targets = listOf(
            PointerTarget.pointer(PointerAddress(pk)),
            PointerTarget.graphEntry(GraphEntryAddress(pk)),
            PointerTarget.scratchpad(ScratchpadAddress(pk))
        )

        assertEquals("Should have 3 target types", 3, targets.size)
        targets.forEach { target ->
            assertNotNull("Target should not be null", target)
            assertTrue("Target hex should not be empty", target.toHex().isNotEmpty())
        }
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
    fun testPointerTypesExist() {
        // Verify all pointer types are available in the API
        val pointerClasses = listOf(
            "uniffi.ant_ffi.PointerAddress",
            "uniffi.ant_ffi.PointerTarget",
            "uniffi.ant_ffi.NetworkPointer"
        )

        for (className in pointerClasses) {
            try {
                Class.forName(className)
            } catch (e: ClassNotFoundException) {
                fail("Class $className should exist")
            }
        }
    }

    @Test
    fun testClientPointerMethodsExist() {
        // Verify Client has the pointer methods
        val clientClass = Client::class.java
        val methodNames = clientClass.declaredMethods.map { it.name }

        val expectedMethods = listOf(
            "pointerGet",
            "pointerPut",
            "pointerCreate",
            "pointerUpdate",
            "pointerCost",
            "pointerCheckExistence"
        )

        for (method in expectedMethods) {
            assertTrue(
                "Client should have $method method",
                methodNames.contains(method)
            )
        }
    }
}
