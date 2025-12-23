@testable import Autonomi
import XCTest

final class EncryptionTests: XCTestCase {
    func testEncryptDecrypt() throws {
        // Test data
        let originalData: [UInt8] = Array("Hello, Autonomi Network!".utf8)

        // Encrypt the data
        let encrypted = try encrypt(originalData)

        // Verify we got encrypted data
        XCTAssertFalse(encrypted.datamapChunk.isEmpty, "Datamap chunk should not be empty")
        XCTAssertFalse(encrypted.contentChunks.isEmpty, "Content chunks should not be empty")

        // Decrypt the data
        let decrypted = try decrypt(encrypted)

        // Verify the decrypted data matches the original
        XCTAssertEqual(decrypted, originalData, "Decrypted data should match original")

        // Convert back to string and verify
        let decryptedString = String(bytes: decrypted, encoding: .utf8)
        XCTAssertEqual(decryptedString, "Hello, Autonomi Network!")
    }

    func testEncryptLargerData() throws {
        // Test with larger data (1KB)
        let largeData: [UInt8] = Array(repeating: 0x42, count: 1024)

        let encrypted = try encrypt(largeData)
        let decrypted = try decrypt(encrypted)

        XCTAssertEqual(decrypted, largeData)
    }
}
