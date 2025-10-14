/**
 * Tests for the Autonomi Client functionality.
 *
 * These tests verify that the Client can be initialized and can upload/download data from the
 * network.
 *
 * Note: These tests require a local Autonomi testnet to be running.
 */
package com.maidsafe.autonomi.core

import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import uniffi.ant_ffi.*

class AutonomiClientTest {

  // Testnet private key with funds
  private val testnetPrivateKey =
      "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

  @Test
  fun testClientLocalInitialization() = runBlocking {
    // Test that we can initialize a local client
    try {
      val client = Client.initLocal()
      assertNotNull("Client should be initialized", client)
    } catch (e: ClientException.InitializationFailed) {
      // If local network is not running, this is expected
      System.err.println("Local network not available: ${e.reason}")
    }
  }

  @Test
  fun testWalletCreation() = runBlocking {
    try {
      val network = Network(true) // true for local testnet
      val wallet = Wallet.newFromPrivateKey(network, testnetPrivateKey)

      assertNotNull("Wallet should be created", wallet)
      assertNotNull("Wallet address should not be null", wallet.address())
      assertTrue("Wallet address should not be empty", wallet.address().isNotEmpty())

      // Try to get balance
      try {
        val balance = wallet.balanceOfTokens()
        assertNotNull("Balance should not be null", balance)
        System.out.println("Wallet balance: $balance")
      } catch (e: WalletException.BalanceCheckFailed) {
        // Balance check may fail if network is not available
        System.err.println("Balance check failed: ${e.reason}")
      }
    } catch (e: NetworkException.CreationFailed) {
      System.err.println("Network creation failed: ${e.reason}")
    } catch (e: WalletException.CreationFailed) {
      System.err.println("Wallet creation failed: ${e.reason}")
    }
  }

  @Test
  fun testUploadAndDownloadData() = runBlocking {
    val testData = "Hello, Autonomi!".toByteArray(Charsets.UTF_8)

    try {
      // Initialize network and wallet
      val network = Network(true)
      val wallet = Wallet.newFromPrivateKey(network, testnetPrivateKey)
      val payment = PaymentOption.WalletPayment(wallet)

      // Initialize client
      val client = Client.initLocal()

      // Upload data
      val uploadResult = client.dataPutPublic(testData, payment)
      assertNotNull("Upload result should not be null", uploadResult)
      assertNotNull("Price should not be null", uploadResult.price)
      assertNotNull("Address should not be null", uploadResult.address)
      assertTrue("Address should not be empty", uploadResult.address.isNotEmpty())

      System.out.println("Data uploaded for ${uploadResult.price} ANT")
      System.out.println("Data address: ${uploadResult.address}")

      // Wait for network to store the data
      delay(1000)

      // Download data
      val retrievedData = client.dataGetPublic(uploadResult.address)
      assertNotNull("Retrieved data should not be null", retrievedData)
      assertArrayEquals("Retrieved data should match original", testData, retrievedData)

      val retrievedString = String(retrievedData, Charsets.UTF_8)
      assertEquals("Retrieved string should match original", "Hello, Autonomi!", retrievedString)

      System.out.println("Successfully uploaded and retrieved data!")
    } catch (e: NetworkException.CreationFailed) {
      System.err.println("Network creation failed: ${e.reason}")
    } catch (e: WalletException.CreationFailed) {
      System.err.println("Wallet creation failed: ${e.reason}")
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Client initialization failed: ${e.reason}")
    } catch (e: ClientException.NetworkException) {
      System.err.println("Network error: ${e.reason}")
    }
  }

  @Test
  fun testInvalidDataAddress() = runBlocking {
    // Test that invalid hex addresses are rejected
    val invalidAddress = "not-a-valid-hex-address"

    try {
      val client = Client.initLocal()
      try {
        client.dataGetPublic(invalidAddress)
        fail("Expected InvalidAddress exception for invalid hex string")
      } catch (e: ClientException.InvalidAddress) {
        // This is expected
        assertTrue("Error message should mention invalid address", e.reason.isNotEmpty())
      }
    } catch (e: ClientException.InitializationFailed) {
      // Client initialization may fail - skip the rest of the test
      System.err.println("Client initialization failed: ${e.reason}")
    }
  }
}
