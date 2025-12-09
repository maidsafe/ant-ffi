/**
 * Network integration tests for Autonomi file and archive functionality.
 *
 * These tests verify that private data, files, and archives can be uploaded and downloaded
 * on a live Autonomi network.
 *
 * Note: These tests require a local Autonomi testnet to be running.
 * Set the environment variable AUTONOMI_NETWORK_TESTS=true to enable these tests.
 */
package com.maidsafe.autonomi.core

import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Test
import uniffi.ant_ffi.*
import java.io.File

class FileNetworkTest {

    // Testnet private key with funds (default Anvil deployer key)
    private val testnetPrivateKey =
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

    @Before
    fun checkNetworkTestsEnabled() {
        val enabled = System.getenv("AUTONOMI_NETWORK_TESTS")?.toBoolean() ?: false
        assumeTrue("Network tests disabled. Set AUTONOMI_NETWORK_TESTS=true to enable.", enabled)
    }

    private suspend fun setupClientAndWallet(): Triple<Client, Wallet, PaymentOption> {
        val client = Client.initLocal()
        val network = Network(true)
        val wallet = Wallet.newFromPrivateKey(network, testnetPrivateKey)
        return Triple(client, wallet, PaymentOption.WalletPayment(wallet))
    }

    @Test
    fun testPrivateDataRoundtrip(): Unit = runBlocking {
        try {
            val (client, _, payment) = setupClientAndWallet()

            val secretData = "My secret information".toByteArray()
            val result = client.dataPut(secretData, payment)
            println("Private data uploaded, cost: ${result.cost}")

            delay(5000)

            val retrieved = client.dataGet(result.dataMap)
            assertArrayEquals("Private data should match", secretData, retrieved)

        } catch (e: ClientException.InitializationFailed) {
            System.err.println("Network not available: ${e.reason}")
        }
    }

    @Test
    fun testFileUploadDownloadPublic(): Unit = runBlocking {
        try {
            val (client, _, payment) = setupClientAndWallet()

            val tempDir = System.getProperty("java.io.tmpdir")

            val uploadFile = File(tempDir, "upload_test_${System.currentTimeMillis()}.txt")
            uploadFile.writeText("Hello from Autonomi!")

            val result = client.fileUploadPublic(uploadFile.absolutePath, payment)
            println("File uploaded to: ${result.address.toHex()}, cost: ${result.cost}")

            delay(5000)

            val downloadFile = File(tempDir, "download_test_${System.currentTimeMillis()}.txt")
            client.fileDownloadPublic(result.address, downloadFile.absolutePath)

            assertEquals("Downloaded content should match", "Hello from Autonomi!", downloadFile.readText())

            uploadFile.delete()
            downloadFile.delete()

        } catch (e: ClientException.InitializationFailed) {
            System.err.println("Network not available: ${e.reason}")
        }
    }

    @Test
    fun testFileUploadDownloadPrivate(): Unit = runBlocking {
        try {
            val (client, _, payment) = setupClientAndWallet()

            val tempDir = System.getProperty("java.io.tmpdir")

            val uploadFile = File(tempDir, "private_upload_${System.currentTimeMillis()}.txt")
            uploadFile.writeText("Secret file content")

            val result = client.fileUpload(uploadFile.absolutePath, payment)
            println("Private file uploaded, cost: ${result.cost}")

            delay(5000)

            val downloadFile = File(tempDir, "private_download_${System.currentTimeMillis()}.txt")
            client.fileDownload(result.dataMap, downloadFile.absolutePath)

            assertEquals("Downloaded content should match", "Secret file content", downloadFile.readText())

            uploadFile.delete()
            downloadFile.delete()

        } catch (e: ClientException.InitializationFailed) {
            System.err.println("Network not available: ${e.reason}")
        }
    }

    @Test
    fun testPublicArchiveRoundtrip(): Unit = runBlocking {
        try {
            val (client, _, payment) = setupClientAndWallet()

            // Upload data for archive
            val data = "Archive content".toByteArray()
            val dataResult = client.dataPutPublic(data, payment)
            delay(5000)

            // Create archive
            val archive = PublicArchive()
            val metadata = Metadata(data.size.toULong())
            archive.addFile("test.txt", DataAddress.fromHex(dataResult.address), metadata)

            val result = client.archivePutPublic(archive, payment)
            println("Archive uploaded to: ${result.address.toHex()}, cost: ${result.cost}")

            delay(5000)

            val retrieved = client.archiveGetPublic(result.address)
            assertEquals("Archive should have 1 file", 1uL, retrieved.fileCount())

        } catch (e: ClientException.InitializationFailed) {
            System.err.println("Network not available: ${e.reason}")
        }
    }
}
