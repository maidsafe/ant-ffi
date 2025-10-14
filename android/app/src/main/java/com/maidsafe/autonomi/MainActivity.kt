package com.maidsafe.autonomi

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.maidsafe.autonomi.ui.theme.AutonomiTheme
import uniffi.ant_ffi.*

class MainActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    // Demo encryption/decryption
    val originalText = "Hello, Autonomi!"
    val encrypted = encrypt(originalText.toByteArray())
    val decrypted = decrypt(encrypted)
    val result = String(decrypted)

    setContent {
      AutonomiTheme {
        // A surface container using the 'background' color from the theme
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
          Greeting("🦀 encrypted and decrypted: $result")
        }
      }
    }
  }
}

@Composable
fun Greeting(name: String, modifier: Modifier = Modifier) {
  Text(text = "Hello $name!", modifier = modifier)
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
  AutonomiTheme { Greeting("Android") }
}
