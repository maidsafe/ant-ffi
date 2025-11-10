package com.maidsafe.autonomi

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.maidsafe.autonomi.ui.theme.AutonomiTheme
import kotlinx.coroutines.launch
import uniffi.ant_ffi.*

class MainActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    setContent {
      AutonomiTheme {
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
          NetworkStorageDemo()
        }
      }
    }
  }
}

@Composable
fun NetworkStorageDemo() {
  val context = androidx.compose.ui.platform.LocalContext.current
  val scope = rememberCoroutineScope()

  var noteText by remember { mutableStateOf("My first note on Autonomi!") }
  var client by remember { mutableStateOf<Client?>(null) }
  var wallet by remember { mutableStateOf<Wallet?>(null) }
  var connectionStatus by remember { mutableStateOf("Not connected") }
  var peerAddress by remember {
    mutableStateOf(
        "/ip4/10.0.2.2/udp/51736/quic-v1/p2p/12D3KooWQBwxJpTAPNbkZXCJHfpFQSx8GGACTYf68kJgU6NvigKa")
  }
  var uploadedAddresses by remember { mutableStateOf<List<String>>(emptyList()) }
  var downloadAddress by remember { mutableStateOf("") }
  var downloadedText by remember { mutableStateOf("") }
  var statusMessage by remember { mutableStateOf("") }
  var isLoading by remember { mutableStateOf(false) }

  Column(
      modifier = Modifier.fillMaxSize().padding(16.dp).verticalScroll(rememberScrollState()),
      verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(
            text = "Autonomi Network Storage",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.primary)

        Text(
            text = "Store and retrieve data on the decentralized network",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant)

        HorizontalDivider()

        // Connection Status
        Card(modifier = Modifier.fillMaxWidth()) {
          Column(
              modifier = Modifier.padding(12.dp),
              verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(text = "Connection Settings", style = MaterialTheme.typography.titleMedium)

                OutlinedTextField(
                    value = peerAddress,
                    onValueChange = { peerAddress = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Peer multiaddress") },
                    enabled = client == null,
                    singleLine = true)

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically) {
                      Text(
                          text = connectionStatus,
                          style = MaterialTheme.typography.bodyMedium,
                          color =
                              if (client != null) MaterialTheme.colorScheme.primary
                              else MaterialTheme.colorScheme.onSurfaceVariant)

                      Button(
                          onClick = {
                            scope.launch {
                              isLoading = true
                              statusMessage = ""
                              connectionStatus = "Connecting..."
                              try {
                                val network =
                                    Network.custom(
                                        rpcUrl = "http://10.0.2.2:61611",
                                        paymentTokenAddress =
                                            "0x5FbDB2315678afecb367f032d93F642f64180aa3",
                                        dataPaymentsAddress =
                                            "0x8464135c8F25Da09e49BC8782676a84730C318bC")

                                val startTime = System.currentTimeMillis()
                                client =
                                    Client.initWithPeers(
                                        listOf(peerAddress), network, context.cacheDir.absolutePath)
                                val elapsed = System.currentTimeMillis() - startTime
                                connectionStatus = "Connected (${elapsed}ms)"

                                wallet =
                                    Wallet.newFromPrivateKey(
                                        network,
                                        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
                                val balance = wallet!!.balanceOfTokens()

                                statusMessage = "Ready! Balance: $balance tokens"
                              } catch (e: Exception) {
                                connectionStatus = "Failed"
                                client = null
                                wallet = null
                                statusMessage = "Error: ${e.message}"
                              } finally {
                                isLoading = false
                              }
                            }
                          },
                          enabled = !isLoading && client == null && peerAddress.isNotEmpty()) {
                            Text(if (isLoading) "Connecting..." else "Connect")
                          }
                    }
              }
        }

        // Status Messages
        if (statusMessage.isNotEmpty()) {
          Card(
              modifier = Modifier.fillMaxWidth(),
              colors =
                  CardDefaults.cardColors(
                      containerColor = MaterialTheme.colorScheme.secondaryContainer)) {
                Text(
                    text = statusMessage,
                    modifier = Modifier.padding(12.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSecondaryContainer)
              }
        }

        HorizontalDivider()

        // Upload Section
        Text(text = "Upload Note", style = MaterialTheme.typography.titleMedium)

        OutlinedTextField(
            value = noteText,
            onValueChange = { noteText = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Note content") },
            minLines = 4,
            enabled = client != null)

        Button(
            onClick = {
              scope.launch {
                isLoading = true
                statusMessage = ""
                try {
                  val result =
                      client!!.dataPutPublic(
                          noteText.toByteArray(), PaymentOption.WalletPayment(wallet!!))
                  uploadedAddresses = uploadedAddresses + result.address
                  statusMessage = "Uploaded! Cost: ${result.price} tokens"
                } catch (e: Exception) {
                  statusMessage = "Upload failed: ${e.message}"
                } finally {
                  isLoading = false
                }
              }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = client != null && wallet != null && noteText.isNotEmpty() && !isLoading) {
              Text(if (isLoading) "Uploading..." else "Upload to Network")
            }

        // Uploaded Addresses List
        if (uploadedAddresses.isNotEmpty()) {
          HorizontalDivider()
          Text(text = "Uploaded Notes", style = MaterialTheme.typography.titleMedium)
          Card(modifier = Modifier.fillMaxWidth()) {
            Column(
                modifier = Modifier.padding(12.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)) {
                  uploadedAddresses.forEach { address ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically) {
                          Text(
                              text = "${address.take(16)}...",
                              style = MaterialTheme.typography.bodySmall,
                              fontFamily = FontFamily.Monospace,
                              modifier = Modifier.weight(1f))
                          Button(
                              onClick = { downloadAddress = address },
                              modifier = Modifier.padding(start = 8.dp)) {
                                Text("Load")
                              }
                        }
                    HorizontalDivider()
                  }
                }
          }
        }

        HorizontalDivider()

        // Download Section
        Text(text = "Download Note", style = MaterialTheme.typography.titleMedium)

        OutlinedTextField(
            value = downloadAddress,
            onValueChange = { downloadAddress = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Data address (hex)") },
            enabled = client != null,
            singleLine = true)

        Button(
            onClick = {
              scope.launch {
                isLoading = true
                statusMessage = ""
                downloadedText = ""
                try {
                  val dataBytes = client!!.dataGetPublic(downloadAddress)
                  downloadedText = String(dataBytes)
                  statusMessage = "Downloaded ${dataBytes.size} bytes"
                } catch (e: Exception) {
                  statusMessage = "Download failed: ${e.message}"
                } finally {
                  isLoading = false
                }
              }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = client != null && downloadAddress.isNotEmpty() && !isLoading) {
              Text("Download from Network")
            }

        // Downloaded Text
        if (downloadedText.isNotEmpty()) {
          Card(
              modifier = Modifier.fillMaxWidth(),
              colors =
                  CardDefaults.cardColors(
                      containerColor = MaterialTheme.colorScheme.tertiaryContainer)) {
                Column(modifier = Modifier.padding(12.dp)) {
                  Text(
                      text = "Downloaded Content:",
                      style = MaterialTheme.typography.titleSmall,
                      color = MaterialTheme.colorScheme.onTertiaryContainer)
                  Text(
                      text = downloadedText,
                      modifier = Modifier.padding(top = 8.dp),
                      style = MaterialTheme.typography.bodyMedium,
                      color = MaterialTheme.colorScheme.onTertiaryContainer)
                }
              }
        }
      }
}

@Preview(showBackground = true)
@Composable
fun NetworkStorageDemoPreview() {
  AutonomiTheme { NetworkStorageDemo() }
}
