/**
 * JVM Unit tests for Autonomi key derivation functionality. These tests run on the host JVM
 * without requiring an Android emulator.
 */
package com.maidsafe.autonomi.core

import org.junit.Assert.*
import org.junit.Test
import uniffi.ant_ffi.*

class KeyDerivationTest {

    @Test
    fun testDerivationIndexRandom() {
        // Generate two random derivation indices - they should be different
        val index1 = DerivationIndex.random()
        val index2 = DerivationIndex.random()

        val bytes1 = index1.toBytes()
        val bytes2 = index2.toBytes()

        assertEquals("DerivationIndex should be 32 bytes", 32, bytes1.size)
        assertEquals("DerivationIndex should be 32 bytes", 32, bytes2.size)
        assertFalse("Random indices should be different", bytes1.contentEquals(bytes2))
    }

    @Test
    fun testDerivationIndexFromBytes() {
        // Create an index from specific bytes
        val bytes = ByteArray(32) { it.toByte() }
        val index = DerivationIndex.fromBytes(bytes.toList())

        val resultBytes = index.toBytes()
        assertArrayEquals("Bytes should round-trip correctly", bytes, resultBytes.toByteArray())
    }

    @Test
    fun testDerivationIndexInvalidLength() {
        // Try to create index with wrong size - should fail
        val tooShort = ByteArray(16) { it.toByte() }
        val tooLong = ByteArray(64) { it.toByte() }

        try {
            DerivationIndex.fromBytes(tooShort.toList())
            fail("Should throw for wrong length")
        } catch (e: KeyException.InvalidKey) {
            assertTrue("Error should mention 32 bytes", e.reason.contains("32"))
        }

        try {
            DerivationIndex.fromBytes(tooLong.toList())
            fail("Should throw for wrong length")
        } catch (e: KeyException.InvalidKey) {
            assertTrue("Error should mention 32 bytes", e.reason.contains("32"))
        }
    }

    @Test
    fun testMainSecretKeyRandom() {
        // Generate a random main secret key
        val mainSk = MainSecretKey.random()
        val mainPk = mainSk.publicKey()

        assertNotNull("Public key should not be null", mainPk)

        val bytes = mainSk.toBytes()
        assertTrue("Secret key bytes should not be empty", bytes.isNotEmpty())
    }

    @Test
    fun testMainSecretKeyFromSecretKey() {
        // Create MainSecretKey from a regular SecretKey
        val sk = SecretKey.random()
        val mainSk = MainSecretKey(sk)

        assertNotNull("MainSecretKey should be created", mainSk)
        val mainPk = mainSk.publicKey()
        assertNotNull("Public key should not be null", mainPk)
    }

    @Test
    fun testKeyDerivation() {
        // Test deriving keys from a master key
        val mainSk = MainSecretKey.random()
        val mainPk = mainSk.publicKey()

        val index = DerivationIndex.random()

        // Derive from secret key
        val derivedSk = mainSk.deriveKey(index)
        val derivedPkFromSk = derivedSk.publicKey()

        // Derive from public key
        val derivedPkFromPk = mainPk.deriveKey(index)

        // Both derived public keys should match
        assertEquals(
            "Derived pubkeys should match",
            derivedPkFromSk.toHex(),
            derivedPkFromPk.toHex()
        )
    }

    @Test
    fun testDerivedKeysUniqueness() {
        // Keys derived with different indices should be unique
        val mainSk = MainSecretKey.random()
        val mainPk = mainSk.publicKey()

        val derivedPubkeys = mutableSetOf<String>()

        // Generate multiple derived keys with different indices
        for (i in 1..10) {
            val index = DerivationIndex.random()
            val derivedPk = mainPk.deriveKey(index)
            val hex = derivedPk.toHex()

            assertTrue("Derived keys should be unique", derivedPubkeys.add(hex))
        }

        assertEquals("Should have 10 unique derived keys", 10, derivedPubkeys.size)
    }

    @Test
    fun testRandomDerivedKey() {
        // Test generating a random derived key
        val mainSk = MainSecretKey.random()
        val derivedSk1 = mainSk.randomDerivedKey()
        val derivedSk2 = mainSk.randomDerivedKey()

        assertNotEquals(
            "Random derived keys should be different",
            derivedSk1.publicKey().toHex(),
            derivedSk2.publicKey().toHex()
        )
    }

    @Test
    fun testSignatureCreation() {
        // Test signing with main key
        val mainSk = MainSecretKey.random()
        val msg = "Test message".toByteArray(Charsets.UTF_8)

        val signature = mainSk.sign(msg.toList())

        assertNotNull("Signature should not be null", signature)
        val sigBytes = signature.toBytes()
        assertEquals("BLS signature should be 96 bytes", 96, sigBytes.size)
    }

    @Test
    fun testSignatureVerification() {
        // Test signature verification
        val mainSk = MainSecretKey.random()
        val mainPk = mainSk.publicKey()
        val msg = "Test message".toByteArray(Charsets.UTF_8)

        val signature = mainSk.sign(msg.toList())

        // Verify with correct key and message
        assertTrue(
            "Valid signature should verify",
            mainPk.verify(signature, msg.toList())
        )
    }

    @Test
    fun testSignatureVerificationFails() {
        // Test that verification fails for wrong key or message
        val mainSk1 = MainSecretKey.random()
        val mainSk2 = MainSecretKey.random()
        val msg1 = "Test message 1".toByteArray(Charsets.UTF_8)
        val msg2 = "Test message 2".toByteArray(Charsets.UTF_8)

        val signature = mainSk1.sign(msg1.toList())

        // Wrong key should fail
        assertFalse(
            "Wrong key should fail verification",
            mainSk2.publicKey().verify(signature, msg1.toList())
        )

        // Wrong message should fail
        assertFalse(
            "Wrong message should fail verification",
            mainSk1.publicKey().verify(signature, msg2.toList())
        )
    }

    @Test
    fun testDerivedKeySignature() {
        // Test signing with derived key
        val mainSk = MainSecretKey.random()
        val derivedSk = mainSk.randomDerivedKey()
        val derivedPk = derivedSk.publicKey()

        val msg = "Derived key message".toByteArray(Charsets.UTF_8)
        val signature = derivedSk.sign(msg.toList())

        // Verify with derived pubkey
        assertTrue(
            "Derived signature should verify with derived pubkey",
            derivedPk.verify(signature, msg.toList())
        )

        // Main pubkey should NOT verify derived signature
        assertFalse(
            "Main pubkey should not verify derived signature",
            mainSk.publicKey().verify(signature, msg.toList())
        )
    }

    @Test
    fun testMainPubkeyHexRoundtrip() {
        // Test hex serialization roundtrip
        val mainSk = MainSecretKey.random()
        val mainPk = mainSk.publicKey()

        val hex = mainPk.toHex()
        val restored = MainPubkey.fromHex(hex)

        assertEquals("Hex roundtrip should preserve key", mainPk.toHex(), restored.toHex())
    }

    @Test
    fun testDerivedPubkeyHexRoundtrip() {
        // Test derived pubkey hex serialization
        val mainSk = MainSecretKey.random()
        val derivedSk = mainSk.randomDerivedKey()
        val derivedPk = derivedSk.publicKey()

        val hex = derivedPk.toHex()
        val restored = DerivedPubkey.fromHex(hex)

        assertEquals("Hex roundtrip should preserve key", derivedPk.toHex(), restored.toHex())
    }

    @Test
    fun testSignatureHexRoundtrip() {
        // Test signature hex serialization
        val mainSk = MainSecretKey.random()
        val msg = "Test".toByteArray(Charsets.UTF_8)
        val signature = mainSk.sign(msg.toList())

        val hex = signature.toHex()
        val bytes = signature.toBytes()

        assertEquals("Hex should be twice the byte length", bytes.size * 2, hex.length)
    }

    @Test
    fun testSignatureFromBytes() {
        // Test creating signature from bytes
        val mainSk = MainSecretKey.random()
        val msg = "Test".toByteArray(Charsets.UTF_8)
        val signature = mainSk.sign(msg.toList())

        val bytes = signature.toBytes()
        val restored = Signature.fromBytes(bytes)

        // Restored signature should also verify
        assertTrue(
            "Restored signature should verify",
            mainSk.publicKey().verify(restored, msg.toList())
        )
    }

    @Test
    fun testSignatureInvalidBytes() {
        // Test that invalid bytes fail
        val invalidBytes = ByteArray(50) { it.toByte() } // Wrong size

        try {
            Signature.fromBytes(invalidBytes.toList())
            fail("Should throw for invalid signature bytes")
        } catch (e: KeyException.InvalidKey) {
            assertTrue("Error should mention 96 bytes", e.reason.contains("96"))
        }
    }

    @Test
    fun testSignatureParity() {
        // Test signature parity function
        val mainSk = MainSecretKey.random()
        val msg = "Test".toByteArray(Charsets.UTF_8)
        val signature = mainSk.sign(msg.toList())

        // Just verify it returns a boolean
        val parity = signature.parity()
        assertTrue("Parity should be true or false", parity == true || parity == false)
    }
}
