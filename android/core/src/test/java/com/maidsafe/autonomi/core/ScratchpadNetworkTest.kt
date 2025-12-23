/**
 * Network integration tests for Autonomi Scratchpad functionality.
 *
 * These tests verify that scratchpads can be created, retrieved, decrypted, and updated on a live
 * Autonomi network.
 *
 * Note: These tests require a local Autonomi testnet to be running. Set the environment variable
 * AUTONOMI_NETWORK_TESTS=true to enable these tests.
 */
package com.maidsafe.autonomi.core

import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Test
import uniffi.ant_ffi.*

class ScratchpadNetworkTest {

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
  fun testScratchpadCreateAndDecrypt(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      val ownerKey = SecretKey.random()
      val contentType = 1uL // Application-defined type
      val secretData = "My encrypted scratchpad data".toByteArray()

      val result = client.scratchpadCreate(ownerKey, contentType, secretData, payment)
      println("Scratchpad created at: ${result.address.toHex()}, cost: ${result.cost}")

      delay(5000)

      val scratchpad = client.scratchpadGet(result.address)
      val decrypted = scratchpad.decryptData(ownerKey)

      assertArrayEquals("Decrypted data should match original", secretData, decrypted)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }

  @Test
  fun testScratchpadUpdate(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      val ownerKey = SecretKey.random()
      val contentType = 1uL
      val data1 = "Version 1".toByteArray()

      client.scratchpadCreate(ownerKey, contentType, data1, payment)
      delay(5000)

      // Update (free operation)
      val data2 = "Version 2".toByteArray()
      client.scratchpadUpdate(ownerKey, contentType, data2)
      delay(5000)

      val scratchpad = client.scratchpadGetFromPublicKey(ownerKey.publicKey())
      val decrypted = scratchpad.decryptData(ownerKey)

      assertArrayEquals("Should get updated data", data2, decrypted)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }
}
