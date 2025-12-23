/**
 * Network integration tests for Autonomi Register functionality.
 *
 * These tests verify that registers can be created, read, updated, and their history collected on a
 * live Autonomi network.
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

class RegisterNetworkTest {

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
  fun testRegisterCreateAndRead(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      val ownerKey = SecretKey.random()
      val initialValue = registerValueFromBytes("Hello, World!".toByteArray())

      val result = client.registerCreate(ownerKey, initialValue, payment)
      println("Register created at: ${result.address.toHex()}, cost: ${result.cost}")

      // Wait for network replication
      delay(5000)

      val retrieved = client.registerGet(result.address)
      assertArrayEquals("Register value should match", initialValue, retrieved)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }

  @Test
  fun testRegisterUpdate(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      val ownerKey = SecretKey.random()
      val value1 = registerValueFromBytes("Version 1".toByteArray())

      val result = client.registerCreate(ownerKey, value1, payment)
      delay(5000)

      val value2 = registerValueFromBytes("Version 2".toByteArray())
      val updateCost = client.registerUpdate(ownerKey, value2, payment)
      println("Register updated, cost: $updateCost")

      delay(5000)

      val retrieved = client.registerGet(result.address)
      assertArrayEquals("Should get updated value", value2, retrieved)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }

  @Test
  fun testRegisterHistoryCollect(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      val ownerKey = SecretKey.random()
      val value1 = registerValueFromBytes("First entry".toByteArray())

      val result = client.registerCreate(ownerKey, value1, payment)
      delay(5000)

      val value2 = registerValueFromBytes("Second entry".toByteArray())
      client.registerUpdate(ownerKey, value2, payment)
      delay(5000)

      val history = client.registerHistoryCollect(result.address)
      assertEquals("Should have 2 history entries", 2, history.size)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }
}
