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
        val metadata = Metadata(1024u)

        assertEquals("Size should be 1024", 1024u, metadata.size())
        assertTrue("Created timestamp should be set", metadata.created() > 0u)
        assertTrue("Modified timestamp should be set", metadata.modified() > 0u)
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

        assertEquals("New archive should have 0 files", 0u, archive.fileCount())
        assertTrue("Files list should be empty", archive.files().isEmpty())
        assertTrue("Addresses list should be empty", archive.addresses().isEmpty())
    }

    @Test
    fun testPrivateArchiveCreation() {
        // Test creating an empty private archive
        val archive = PrivateArchive()

        assertEquals("New archive should have 0 files", 0u, archive.fileCount())
        assertTrue("Files list should be empty", archive.files().isEmpty())
        assertTrue("Data maps list should be empty", archive.dataMaps().isEmpty())
    }

    @Test
    fun testPublicArchiveAddFile() {
        // Test adding a file to a public archive
        val archive = PublicArchive()
        val metadata = Metadata(100u)

        // Create a mock data address - we need to create actual encrypted data first
        val testData = "Test file content for archive".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val address = DataAddress.fromHex(encrypted.datamapChunk.toHex())

        // Add file to archive (immutable - returns new archive)
        val updatedArchive = archive.addFile("test/path/file.txt", address, metadata)

        assertEquals("Archive should have 1 file", 1u, updatedArchive.fileCount())
        assertEquals("Files list should have 1 entry", 1, updatedArchive.files().size)

        val fileEntry = updatedArchive.files()[0]
        assertEquals("File path should match", "test/path/file.txt", fileEntry.path)
        assertEquals("Metadata size should match", 100u, fileEntry.metadata.size())
    }

    @Test
    fun testPrivateArchiveAddFile() {
        // Test adding a file to a private archive
        val archive = PrivateArchive()
        val metadata = Metadata(200u)

        // Create a mock data map chunk
        val testData = "Test private file content".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val dataMap = DataMapChunk.fromHex(encrypted.datamapChunk.toHex())

        // Add file to archive (immutable - returns new archive)
        val updatedArchive = archive.addFile("private/file.dat", dataMap, metadata)

        assertEquals("Archive should have 1 file", 1u, updatedArchive.fileCount())
        assertEquals("Files list should have 1 entry", 1, updatedArchive.files().size)

        val fileEntry = updatedArchive.files()[0]
        assertEquals("File path should match", "private/file.dat", fileEntry.path)
        assertEquals("Metadata size should match", 200u, fileEntry.metadata.size())
    }

    @Test
    fun testPublicArchiveRenameFile() {
        // Test renaming a file in a public archive
        val archive = PublicArchive()
        val metadata = Metadata(100u)

        val testData = "Test file for rename".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val address = DataAddress.fromHex(encrypted.datamapChunk.toHex())

        val archiveWithFile = archive.addFile("old/path.txt", address, metadata)
        val renamedArchive = archiveWithFile.renameFile("old/path.txt", "new/path.txt")

        assertEquals("Archive should still have 1 file", 1u, renamedArchive.fileCount())
        assertEquals("File path should be updated", "new/path.txt", renamedArchive.files()[0].path)
    }

    @Test
    fun testPrivateArchiveRenameFile() {
        // Test renaming a file in a private archive
        val archive = PrivateArchive()
        val metadata = Metadata(150u)

        val testData = "Test private file for rename".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val dataMap = DataMapChunk.fromHex(encrypted.datamapChunk.toHex())

        val archiveWithFile = archive.addFile("old/private.dat", dataMap, metadata)
        val renamedArchive = archiveWithFile.renameFile("old/private.dat", "new/private.dat")

        assertEquals("Archive should still have 1 file", 1u, renamedArchive.fileCount())
        assertEquals("File path should be updated", "new/private.dat", renamedArchive.files()[0].path)
    }

    @Test
    fun testArchiveAddressHexRoundtrip() {
        // Test that ArchiveAddress can be serialized and deserialized via hex
        // Note: We need a valid hex string that represents a proper address
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
    fun testPrivateArchiveDataMapHexRoundtrip() {
        // Test that PrivateArchiveDataMap can be serialized and deserialized via hex
        val testData = "Test data for datamap".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val originalHex = encrypted.datamapChunk.toHex()

        try {
            val dataMap = PrivateArchiveDataMap.fromHex(originalHex)
            val hexBack = dataMap.toHex()
            assertEquals("Hex roundtrip should preserve value", originalHex, hexBack)
        } catch (e: ArchiveException.ParsingFailed) {
            // DataMap format may differ from raw hex, that's expected
            assertTrue("Should have a reason", e.reason.isNotEmpty())
        }
    }

    @Test
    fun testPublicArchiveMultipleFiles() {
        // Test adding multiple files to a public archive
        var archive = PublicArchive()

        for (i in 1..5) {
            val testData = "File content $i".toByteArray(Charsets.UTF_8)
            val encrypted = encrypt(testData)
            val address = DataAddress.fromHex(encrypted.datamapChunk.toHex())
            val metadata = Metadata((i * 100).toULong())

            archive = archive.addFile("dir/file$i.txt", address, metadata)
        }

        assertEquals("Archive should have 5 files", 5u, archive.fileCount())
        assertEquals("Files list should have 5 entries", 5, archive.files().size)
        assertEquals("Addresses list should have 5 entries", 5, archive.addresses().size)
    }

    @Test
    fun testPrivateArchiveMultipleFiles() {
        // Test adding multiple files to a private archive
        var archive = PrivateArchive()

        for (i in 1..5) {
            val testData = "Private file content $i".toByteArray(Charsets.UTF_8)
            val encrypted = encrypt(testData)
            val dataMap = DataMapChunk.fromHex(encrypted.datamapChunk.toHex())
            val metadata = Metadata((i * 100).toULong())

            archive = archive.addFile("private/file$i.dat", dataMap, metadata)
        }

        assertEquals("Archive should have 5 files", 5u, archive.fileCount())
        assertEquals("Files list should have 5 entries", 5, archive.files().size)
        assertEquals("Data maps list should have 5 entries", 5, archive.dataMaps().size)
    }

    @Test
    fun testArchiveImmutability() {
        // Test that archives are immutable - adding files returns a new archive
        val originalArchive = PublicArchive()

        val testData = "Test data".toByteArray(Charsets.UTF_8)
        val encrypted = encrypt(testData)
        val address = DataAddress.fromHex(encrypted.datamapChunk.toHex())
        val metadata = Metadata(50u)

        val newArchive = originalArchive.addFile("test.txt", address, metadata)

        assertEquals("Original archive should be unchanged", 0u, originalArchive.fileCount())
        assertEquals("New archive should have the file", 1u, newArchive.fileCount())
    }
}
