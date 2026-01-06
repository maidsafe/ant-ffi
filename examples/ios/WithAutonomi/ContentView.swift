import SwiftUI
  import Autonomi
internal import UniFFI

  struct ContentView: View {
      @State private var status = "Ready"

      var body: some View {
          VStack(spacing: 20) {
              Text(status)
                  .padding()

              Button("Test Encryption") {
                  testEncryption()
              }

              Button("Test Client Init") {
                  testClientInit()
              }
          }
          .padding()
      }

      func testEncryption() {
          do {
              let data: [UInt8] = Array("Hello, Autonomi!".utf8)
              let encrypted = try encrypt(data)
              let decrypted = try decrypt(encrypted)
              let message = String(bytes: decrypted, encoding: .utf8)!
              status = "Encryption works! Decrypted: \(message)"
          } catch {
              status = "Error: \(error)"
          }
      }

      func testClientInit() {
          Task {
              do {
                  status = "Connecting..."
                  let client = try await Client.initLocal()
                  status = "Client initialized! (local testnet)"
              } catch {
                  status = "Error: \(error)"
              }
          }
      }
  }

  #Preview {
      ContentView()
  }
