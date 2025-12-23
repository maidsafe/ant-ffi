/**
 * Network integration tests for Autonomi Pointer functionality.
 *
 * These tests verify that pointers can be created, retrieved, updated, and checked for existence on
 * a live Autonomi network.
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

class PointerNetworkTest {

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
  fun testPointerCreateAndGet(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      // Upload data to point to
      val data = "Pointer target data".toByteArray()
      val dataResult = client.dataPutPublic(data, payment)
      delay(5000)

      // Create pointer
      val pointerKey = SecretKey.random()
      val target = PointerTarget.chunk(ChunkAddress.fromHex(dataResult.address))
      val result = client.pointerCreate(pointerKey, target, payment)
      println("Pointer created at: ${result.address.toHex()}, cost: ${result.cost}")

      delay(5000)

      val pointer = client.pointerGet(result.address)
      assertNotNull("Should retrieve pointer", pointer)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }

  @Test
  fun testPointerUpdate(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      // Create initial data and pointer
      val data1 = "First target".toByteArray()
      val result1 = client.dataPutPublic(data1, payment)
      delay(3000)

      val pointerKey = SecretKey.random()
      val target1 = PointerTarget.chunk(ChunkAddress.fromHex(result1.address))
      val ptrResult = client.pointerCreate(pointerKey, target1, payment)
      delay(5000)

      // Update to new target (free operation)
      val data2 = "Second target".toByteArray()
      val result2 = client.dataPutPublic(data2, payment)
      delay(3000)

      val target2 = PointerTarget.chunk(ChunkAddress.fromHex(result2.address))
      client.pointerUpdate(pointerKey, target2)
      delay(5000)

      val pointer = client.pointerGet(ptrResult.address)
      assertNotNull("Should retrieve updated pointer", pointer)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }

  @Test
  fun testPointerExistenceCheck(): Unit = runBlocking {
    try {
      val (client, _, payment) = setupClientAndWallet()

      val data = "Test data".toByteArray()
      val dataResult = client.dataPutPublic(data, payment)
      delay(5000)

      val pointerKey = SecretKey.random()
      val target = PointerTarget.chunk(ChunkAddress.fromHex(dataResult.address))
      val result = client.pointerCreate(pointerKey, target, payment)
      delay(5000)

      val exists = client.pointerCheckExistence(result.address)
      assertTrue("Pointer should exist", exists)
    } catch (e: ClientException.InitializationFailed) {
      System.err.println("Network not available: ${e.reason}")
    }
  }
}
