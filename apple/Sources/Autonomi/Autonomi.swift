import Foundation
import UniFFI

// Re-export main types from UniFFI for easier access
public typealias Client = UniFFI.Client
public typealias Wallet = UniFFI.Wallet
public typealias Network = UniFFI.Network
public typealias PaymentOption = UniFFI.PaymentOption
public typealias EncryptedData = UniFFI.EncryptedData
public typealias UploadResult = UniFFI.UploadResult

// Re-export error types
public typealias ClientError = UniFFI.ClientError
public typealias WalletError = UniFFI.WalletError
public typealias NetworkError = UniFFI.NetworkError
public typealias EncryptionError = UniFFI.EncryptionError

// Re-export encryption functions with convenient [UInt8] interface
public func encrypt(_ data: [UInt8]) throws -> EncryptedData {
    return try UniFFI.encrypt(data: Data(data))
}

public func decrypt(_ encryptedData: EncryptedData) throws -> [UInt8] {
    let data = try UniFFI.decrypt(encryptedData: encryptedData)
    return Array(data)
}
