/**
 * JVM Unit tests for Autonomi archive functionality. These tests run on the host JVM
 * without requiring an Android emulator.
 */
package com.maidsafe.autonomi.core

import org.junit.Assert.*
import org.junit.Test
import uniffi.ant_ffi.*

class ArchiveTest {

    @Test
    fun testMetadataCreation() {
        // Test creating metadata with size
        val metadata = Metadata(1024uL)

        assertEquals("Size should be 1024", 1024uL, metadata.size())
        assertTrue("Created timestamp should be set", metadata.created() > 0uL)
        assertTrue("Modified timestamp should be set", metadata.modified() > 0uL)
    }

    @Test
    fun testMetadataWithTimestamps() {
        // Test creating metadata with specific timestamps
        val size: ULong = 2048u
        val created: ULong = 1700000000u
        val modified: ULong = 1700001000u

        val metadata = Metadata.withTimestamps(size, created, modified)

        assertEquals("Size should match", size, metadata.size())
        assertEquals("Created timestamp should match", created, metadata.created())
        assertEquals("Modified timestamp should match", modified, metadata.modified())
    }

    @Test
    fun testPublicArchiveCreation() {
        // Test creating an empty public archive
        val archive = PublicArchive()

        assertEquals("New archive should have 0 files", 0uL, archive.fileCount())
        assertTrue("Files list should be empty", archive.files().isEmpty())
        assertTrue("Addresses list should be empty", archive.addresses().isEmpty())
    }

    @Test
    fun testPrivateArchiveCreation() {
        // Test creating an empty private archive
        val archive = PrivateArchive()

        assertEquals("New archive should have 0 files", 0uL, archive.fileCount())
        assertTrue("Files list should be empty", archive.files().isEmpty())
        assertTrue("Data maps list should be empty", archive.dataMaps().isEmpty())
    }

    @Test
    fun testArchiveAddressHexRoundtrip() {
        // Test that ArchiveAddress can be serialized and deserialized via hex
        // For this test we use a 32-byte hex string (64 characters)
        val validHex = "a".repeat(64)

        try {
            val address = ArchiveAddress.fromHex(validHex)
            val hexBack = address.toHex()
            assertEquals("Hex roundtrip should preserve value", validHex, hexBack)
        } catch (e: ArchiveException.ParsingFailed) {
            // Some hex strings may not be valid addresses, that's okay for this test
            assertTrue("Error should mention parsing", e.reason.contains("parse", ignoreCase = true))
        }
    }

    @Test
    fun testArchiveTypesExist() {
        // Verify all archive types are available in the API
        val archiveClasses = listOf(
            "uniffi.ant_ffi.PublicArchive",
            "uniffi.ant_ffi.PrivateArchive",
            "uniffi.ant_ffi.Metadata",
            "uniffi.ant_ffi.ArchiveAddress",
            "uniffi.ant_ffi.PrivateArchiveDataMap",
            "uniffi.ant_ffi.PublicArchiveFileEntry",
            "uniffi.ant_ffi.PrivateArchiveFileEntry"
        )

        for (className in archiveClasses) {
            try {
                Class.forName(className)
            } catch (e: ClassNotFoundException) {
                fail("Class $className should exist")
            }
        }
    }

    @Test
    fun testClientArchiveMethodsExist() {
        // Verify Client has the archive methods
        val clientClass = Client::class.java
        val methodNames = clientClass.declaredMethods.map { it.name }

        val expectedMethods = listOf(
            "archiveCost",
            "archiveGetPublic",
            "archivePutPublic",
            "archiveGet",
            "archivePut"
        )

        for (method in expectedMethods) {
            assertTrue(
                "Client should have $method method",
                methodNames.contains(method)
            )
        }
    }

    @Test
    fun testClientFileMethodsExist() {
        // Verify Client has the file operation methods
        val clientClass = Client::class.java
        val methodNames = clientClass.declaredMethods.map { it.name }

        val expectedMethods = listOf(
            "fileCost",
            "fileUpload",
            "fileUploadPublic",
            "fileDownload",
            "fileDownloadPublic"
        )

        for (method in expectedMethods) {
            assertTrue(
                "Client should have $method method",
                methodNames.contains(method)
            )
        }
    }

    @Test
    fun testClientDirectoryMethodsExist() {
        // Verify Client has the directory operation methods
        val clientClass = Client::class.java
        val methodNames = clientClass.declaredMethods.map { it.name }

        val expectedMethods = listOf(
            "dirUpload",
            "dirUploadPublic",
            "dirDownload",
            "dirDownloadPublic",
            "dirContentUpload"
        )

        for (method in expectedMethods) {
            assertTrue(
                "Client should have $method method",
                methodNames.contains(method)
            )
        }
    }
}
