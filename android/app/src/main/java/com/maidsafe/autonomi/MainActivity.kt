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
import com.maidsafe.core.SafeCalculator

class MainActivity : ComponentActivity() {
  private val calculator = SafeCalculator()

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    setContent {
      AutonomiTheme {
        // A surface container using the 'background' color from the theme
        Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
          Greeting("🦀says 1 + 1 = ${calculator.add(1,1)}")
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
