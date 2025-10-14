/**
 * FIXME: This file should move out of Android Tests ASAP. It only exists here because I haven't yet
 * figured out how to build and link the platform-native binaries via JNI just yet and this works.
 * See https://github.com/willir/cargo-ndk-android-gradle/issues/12.
 *
 * This solution is STUPIDLY INEFFICIENT and will probably contribute to global climate change since
 * an Android emulator uses like two whole CPU cores when idling.
 */
package com.maidsafe.autonomi.core

import org.junit.Assert.*
import org.junit.Test
import uniffi.ant_ffi.*

class AutonomiEncryptionTest {

  @Test
  fun testBasicEncryptionDecryption() {
    // Test data: simple string
    val originalData = "Hello, Autonomi!".toByteArray(Charsets.UTF_8)

    // Encrypt the data
    val encryptedData = encrypt(originalData)

    // Verify encrypted data structure
    assertNotNull("Datamap chunk should not be null", encryptedData.datamapChunk)
    assertNotNull("Content chunks should not be null", encryptedData.contentChunks)
    assertTrue("Datamap chunk should not be empty", encryptedData.datamapChunk.isNotEmpty())
    assertTrue("Content chunks should not be empty", encryptedData.contentChunks.isNotEmpty())

    // Decrypt the data
    val decryptedData = decrypt(encryptedData)

    // Verify decrypted data matches original
    assertArrayEquals("Decrypted data should match original", originalData, decryptedData)
    assertEquals(
        "Decrypted string should match original",
        "Hello, Autonomi!",
        decryptedData.toString(Charsets.UTF_8))
  }

  @Test
  fun testMinimumDataEncryption() {
    // Test with minimum valid data (3 bytes - the minimum required for self-encryption)
    val originalData = ByteArray(3) { it.toByte() } // [0, 1, 2]

    // Encrypt the data
    val encryptedData = encrypt(originalData)

    // Verify encrypted data structure
    assertNotNull("Datamap chunk should not be null", encryptedData.datamapChunk)
    assertNotNull("Content chunks should not be null", encryptedData.contentChunks)

    // Decrypt the data
    val decryptedData = decrypt(encryptedData)

    // Verify decrypted data matches original
    assertArrayEquals("Decrypted minimum data should match original", originalData, decryptedData)
    assertEquals("Decrypted data should have 3 bytes", 3, decryptedData.size)
  }

  @Test
  fun testLargeDataEncryption() {
    // Test with larger data (1KB of repeating pattern)
    val pattern = "Autonomi is a decentralized storage network. "
    val originalData =
        pattern.repeat(1024 / pattern.length).toByteArray(Charsets.UTF_8).copyOf(1024)

    // Encrypt the data
    val encryptedData = encrypt(originalData)

    // Verify encrypted data has chunks
    assertTrue("Large data should produce multiple chunks", encryptedData.contentChunks.size > 0)

    // Decrypt the data
    val decryptedData = decrypt(encryptedData)

    // Verify decrypted data matches original
    assertArrayEquals("Decrypted large data should match original", originalData, decryptedData)
  }

  @Test
  fun testBinaryDataEncryption() {
    // Test with binary data (not UTF-8 text)
    val originalData = ByteArray(256) { it.toByte() } // 0x00 to 0xFF

    // Encrypt the data
    val encryptedData = encrypt(originalData)

    // Decrypt the data
    val decryptedData = decrypt(encryptedData)

    // Verify decrypted data matches original
    assertArrayEquals("Decrypted binary data should match original", originalData, decryptedData)
  }

  @Test
  fun testTooSmallDataThrowsException() {
    // Test that data smaller than 3 bytes throws an exception
    val testCases =
        listOf(
            ByteArray(0), // Empty data
            ByteArray(1) { 0x42 }, // 1 byte
            ByteArray(2) { it.toByte() } // 2 bytes
            )

    for (tooSmallData in testCases) {
      try {
        encrypt(tooSmallData)
        fail("Expected EncryptionException for data size ${tooSmallData.size}")
      } catch (e: EncryptionException.EncryptionFailed) {
        // Verify the error message mentions the size requirement
        assertTrue(
            "Error message should mention minimum size requirement",
            e.reason.contains("Too small", ignoreCase = true) ||
                e.reason.contains("at least 3", ignoreCase = true))
      }
    }
  }
}
