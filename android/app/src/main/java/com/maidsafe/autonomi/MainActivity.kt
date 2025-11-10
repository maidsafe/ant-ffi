package com.maidsafe.autonomi

import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
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

enum class UploadType {
  TEXT,
  FILE
}

data class UploadedItem(val address: String, val type: UploadType, val name: String)

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
  val snackbarHostState = remember { SnackbarHostState() }

  var uploadMode by remember { mutableStateOf(UploadType.TEXT) }
  var noteText by remember { mutableStateOf("My first note on Autonomi!") }
  var client by remember { mutableStateOf<Client?>(null) }
  var wallet by remember { mutableStateOf<Wallet?>(null) }
  var connectionStatus by remember { mutableStateOf("Not connected") }
  var peerAddress by remember {
    mutableStateOf(
        "/ip4/10.0.2.2/udp/51736/quic-v1/p2p/12D3KooWQBwxJpTAPNbkZXCJHfpFQSx8GGACTYf68kJgU6NvigKa")
  }
  var uploadedItems by remember { mutableStateOf<List<UploadedItem>>(emptyList()) }
  var isLoading by remember { mutableStateOf(false) }
  var selectedFileUri by remember { mutableStateOf<Uri?>(null) }
  var selectedFileName by remember { mutableStateOf<String?>(null) }
  var downloadAddress by remember { mutableStateOf("") }
  var downloadType by remember { mutableStateOf(UploadType.TEXT) }
  var downloadedFileName by remember { mutableStateOf("downloaded_file") }
  var downloadedText by remember { mutableStateOf("") }

  val filePickerLauncher =
      rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        selectedFileUri = uri
        selectedFileName =
            uri?.let {
              context.contentResolver.query(it, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                cursor.moveToFirst()
                cursor.getString(nameIndex)
              }
            }
      }

  Scaffold(snackbarHost = { SnackbarHost(snackbarHostState) }) { padding ->
    Column(
        modifier =
            Modifier.fillMaxSize()
                .padding(padding)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
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
                                          listOf(peerAddress),
                                          network,
                                          context.cacheDir.absolutePath)
                                  val elapsed = System.currentTimeMillis() - startTime
                                  connectionStatus = "Connected (${elapsed}ms)"

                                  wallet =
                                      Wallet.newFromPrivateKey(
                                          network,
                                          "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
                                  val balance = wallet!!.balanceOfTokens()

                                  snackbarHostState.showSnackbar("Ready! Balance: $balance tokens")
                                } catch (e: Exception) {
                                  connectionStatus = "Failed"
                                  client = null
                                  wallet = null
                                  snackbarHostState.showSnackbar("Error: ${e.message}")
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

          HorizontalDivider()

          // Upload Mode Toggle
          Text(text = "Upload Data", style = MaterialTheme.typography.titleMedium)

          Row(
              modifier = Modifier.fillMaxWidth(),
              horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = uploadMode == UploadType.TEXT,
                    onClick = {
                      uploadMode = UploadType.TEXT
                      selectedFileUri = null
                      selectedFileName = null
                    },
                    label = { Text("Text") },
                    modifier = Modifier.weight(1f))
                FilterChip(
                    selected = uploadMode == UploadType.FILE,
                    onClick = {
                      uploadMode = UploadType.FILE
                      noteText = "My first note on Autonomi!"
                    },
                    label = { Text("File") },
                    modifier = Modifier.weight(1f))
              }

          // Upload Section - Text Mode
          if (uploadMode == UploadType.TEXT) {
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
                    try {
                      val result =
                          client!!.dataPutPublic(
                              noteText.toByteArray(), PaymentOption.WalletPayment(wallet!!))
                      uploadedItems =
                          uploadedItems + UploadedItem(result.address, UploadType.TEXT, "Note")
                      snackbarHostState.showSnackbar("Uploaded text! Cost: ${result.price} tokens")
                    } catch (e: Exception) {
                      snackbarHostState.showSnackbar("Upload failed: ${e.message}")
                    } finally {
                      isLoading = false
                    }
                  }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = client != null && wallet != null && noteText.isNotEmpty() && !isLoading) {
                  Text(if (isLoading) "Uploading..." else "Upload Text to Network")
                }
          }

          // Upload Section - File Mode
          if (uploadMode == UploadType.FILE) {
            Card(modifier = Modifier.fillMaxWidth()) {
              Column(
                  modifier = Modifier.padding(12.dp),
                  verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically) {
                          Text(
                              text = selectedFileName ?: "No file selected",
                              style = MaterialTheme.typography.bodyMedium,
                              modifier = Modifier.weight(1f))
                          Button(
                              onClick = { filePickerLauncher.launch("*/*") },
                              enabled = client != null && !isLoading) {
                                Text("Select File")
                              }
                        }

                    Button(
                        onClick = {
                          scope.launch {
                            isLoading = true
                            try {
                              selectedFileUri?.let { uri ->
                                val fileBytes =
                                    context.contentResolver.openInputStream(uri)?.use {
                                      it.readBytes()
                                    }
                                if (fileBytes != null) {
                                  val result =
                                      client!!.dataPutPublic(
                                          fileBytes, PaymentOption.WalletPayment(wallet!!))
                                  uploadedItems =
                                      uploadedItems +
                                          UploadedItem(
                                              result.address,
                                              UploadType.FILE,
                                              selectedFileName ?: "file")
                                  snackbarHostState.showSnackbar(
                                      "Uploaded ${selectedFileName} (${fileBytes.size} bytes)! Cost: ${result.price} tokens")
                                  selectedFileUri = null
                                  selectedFileName = null
                                } else {
                                  snackbarHostState.showSnackbar("Failed to read file")
                                }
                              }
                            } catch (e: Exception) {
                              snackbarHostState.showSnackbar("Upload failed: ${e.message}")
                            } finally {
                              isLoading = false
                            }
                          }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        enabled =
                            client != null &&
                                wallet != null &&
                                selectedFileUri != null &&
                                !isLoading) {
                          Text(if (isLoading) "Uploading..." else "Upload File to Network")
                        }
                  }
            }
          }

          // Uploaded Items List
          if (uploadedItems.isNotEmpty()) {
            HorizontalDivider()
            Text(text = "Uploaded Data", style = MaterialTheme.typography.titleMedium)
            Card(modifier = Modifier.fillMaxWidth()) {
              Column(
                  modifier = Modifier.padding(12.dp),
                  verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    uploadedItems.forEach { item ->
                      Column(modifier = Modifier.fillMaxWidth()) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically) {
                              Text(
                                  text = item.name,
                                  style = MaterialTheme.typography.bodyMedium,
                                  fontFamily = FontFamily.Monospace,
                                  modifier = Modifier.weight(1f))
                              Button(
                                  onClick = {
                                    scope.launch {
                                      isLoading = true
                                      try {
                                        val dataBytes = client!!.dataGetPublic(item.address)

                                        if (item.type == UploadType.FILE) {
                                          // Save file to Downloads
                                          val contentValues =
                                              ContentValues().apply {
                                                put(MediaStore.MediaColumns.DISPLAY_NAME, item.name)
                                                put(
                                                    MediaStore.MediaColumns.MIME_TYPE,
                                                    "application/octet-stream")
                                                if (Build.VERSION.SDK_INT >=
                                                    Build.VERSION_CODES.Q) {
                                                  put(
                                                      MediaStore.MediaColumns.RELATIVE_PATH,
                                                      Environment.DIRECTORY_DOWNLOADS)
                                                }
                                              }

                                          val uri =
                                              context.contentResolver.insert(
                                                  MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                                                  contentValues)

                                          uri?.let {
                                            context.contentResolver.openOutputStream(it)?.use {
                                                outputStream ->
                                              outputStream.write(dataBytes)
                                            }
                                            snackbarHostState.showSnackbar(
                                                "Downloaded ${item.name} (${dataBytes.size} bytes) to Downloads")
                                          }
                                              ?: run {
                                                snackbarHostState.showSnackbar(
                                                    "Failed to save file")
                                              }
                                        } else {
                                          // Show text content in status
                                          val text = String(dataBytes)
                                          snackbarHostState.showSnackbar("Text: $text")
                                        }
                                      } catch (e: Exception) {
                                        snackbarHostState.showSnackbar(
                                            "Download failed: ${e.message}")
                                      } finally {
                                        isLoading = false
                                      }
                                    }
                                  },
                                  modifier = Modifier.padding(start = 8.dp),
                                  enabled = !isLoading) {
                                    Text(if (item.type == UploadType.FILE) "Download" else "View")
                                  }
                            }
                        SelectionContainer {
                          Text(
                              text = item.address,
                              style = MaterialTheme.typography.bodySmall,
                              fontFamily = FontFamily.Monospace,
                              color = MaterialTheme.colorScheme.onSurfaceVariant,
                              modifier = Modifier.padding(top = 4.dp))
                        }
                      }
                      HorizontalDivider()
                    }
                  }
            }
          }

          HorizontalDivider()

          // Manual Download Section
          Text(text = "Download by Address", style = MaterialTheme.typography.titleMedium)

          OutlinedTextField(
              value = downloadAddress,
              onValueChange = { downloadAddress = it },
              modifier = Modifier.fillMaxWidth(),
              label = { Text("Data address (hex)") },
              enabled = client != null,
              singleLine = true)

          Row(
              modifier = Modifier.fillMaxWidth(),
              horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = downloadType == UploadType.TEXT,
                    onClick = { downloadType = UploadType.TEXT },
                    label = { Text("Text") },
                    modifier = Modifier.weight(1f))
                FilterChip(
                    selected = downloadType == UploadType.FILE,
                    onClick = { downloadType = UploadType.FILE },
                    label = { Text("File") },
                    modifier = Modifier.weight(1f))
              }

          if (downloadType == UploadType.FILE) {
            OutlinedTextField(
                value = downloadedFileName,
                onValueChange = { downloadedFileName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Save as filename") },
                enabled = client != null,
                singleLine = true)
          }

          Button(
              onClick = {
                scope.launch {
                  isLoading = true
                  downloadedText = ""
                  try {
                    val dataBytes = client!!.dataGetPublic(downloadAddress)

                    if (downloadType == UploadType.FILE) {
                      // Save file to Downloads
                      val contentValues =
                          ContentValues().apply {
                            put(MediaStore.MediaColumns.DISPLAY_NAME, downloadedFileName)
                            put(MediaStore.MediaColumns.MIME_TYPE, "application/octet-stream")
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                              put(
                                  MediaStore.MediaColumns.RELATIVE_PATH,
                                  Environment.DIRECTORY_DOWNLOADS)
                            }
                          }

                      val uri =
                          context.contentResolver.insert(
                              MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)

                      uri?.let {
                        context.contentResolver.openOutputStream(it)?.use { outputStream ->
                          outputStream.write(dataBytes)
                        }
                        snackbarHostState.showSnackbar(
                            "Downloaded ${downloadedFileName} (${dataBytes.size} bytes) to Downloads")
                      } ?: run { snackbarHostState.showSnackbar("Failed to save file") }
                    } else {
                      // Show text content
                      downloadedText = String(dataBytes)
                      snackbarHostState.showSnackbar("Downloaded ${dataBytes.size} bytes")
                    }
                  } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Download failed: ${e.message}")
                  } finally {
                    isLoading = false
                  }
                }
              },
              modifier = Modifier.fillMaxWidth(),
              enabled = client != null && downloadAddress.isNotEmpty() && !isLoading) {
                Text(if (isLoading) "Downloading..." else "Download from Network")
              }

          // Downloaded Text Display
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
}

@Preview(showBackground = true)
@Composable
fun NetworkStorageDemoPreview() {
  AutonomiTheme { NetworkStorageDemo() }
}
