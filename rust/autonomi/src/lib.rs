use autonomi::client::payment::PaymentOption as AutonomiPaymentOption;
use autonomi::data::DataAddress;
use bytes::Bytes;
use self_encryption::{DataMap, EncryptedChunk};
use std::sync::Arc;

uniffi::setup_scaffolding!();

/// Represents encrypted data with a datamap chunk and content chunks
#[derive(uniffi::Record)]
pub struct EncryptedData {
    /// The serialized datamap chunk that contains metadata about the encrypted data
    pub datamap_chunk: Vec<u8>,
    /// The encrypted content chunks
    pub content_chunks: Vec<Vec<u8>>,
}

/// Result of uploading data to the network
#[derive(uniffi::Record)]
pub struct UploadResult {
    /// The price paid for the upload in tokens
    pub price: String,
    /// The hex-encoded data address where the data was stored
    pub address: String,
}

/// Error type for encryption/decryption operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum EncryptionError {
    #[error("Encryption failed: {reason}")]
    EncryptionFailed { reason: String },
}

/// Error type for Autonomi Client operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum ClientError {
    #[error("Network error: {reason}")]
    NetworkError { reason: String },
    #[error("Client initialization failed: {reason}")]
    InitializationFailed { reason: String },
    #[error("Invalid data address: {reason}")]
    InvalidAddress { reason: String },
}

/// Error type for Wallet operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum WalletError {
    #[error("Wallet creation failed: {reason}")]
    CreationFailed { reason: String },
    #[error("Balance check failed: {reason}")]
    BalanceCheckFailed { reason: String },
}

/// Error type for Network operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum NetworkError {
    #[error("Network creation failed: {reason}")]
    CreationFailed { reason: String },
}

/// Network configuration for connecting to Autonomi
#[derive(uniffi::Object)]
pub struct Network {
    inner: autonomi::Network,
}

#[uniffi::export]
impl Network {
    /// Create a new network configuration
    ///
    /// # Arguments
    /// * `is_local` - If true, connects to local testnet. If false, connects to production network.
    #[uniffi::constructor]
    pub fn new(is_local: bool) -> Result<Arc<Self>, NetworkError> {
        let network = autonomi::Network::new(is_local)
            .map_err(|e| NetworkError::CreationFailed {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(Self { inner: network }))
    }
}

/// Wallet for paying for operations on the Autonomi network
#[derive(uniffi::Object)]
pub struct Wallet {
    inner: autonomi::Wallet,
}

#[uniffi::export(async_runtime = "tokio")]
impl Wallet {
    /// Create a new wallet from a private key
    ///
    /// # Arguments
    /// * `network` - The network configuration
    /// * `private_key` - Hex-encoded private key (with or without 0x prefix)
    #[uniffi::constructor]
    pub fn new_from_private_key(
        network: Arc<Network>,
        private_key: String,
    ) -> Result<Arc<Self>, WalletError> {
        let wallet = autonomi::Wallet::new_from_private_key(network.inner.clone(), &private_key)
            .map_err(|e| WalletError::CreationFailed {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(Self { inner: wallet }))
    }

    /// Get the wallet's address
    pub fn address(&self) -> String {
        self.inner.address().to_string()
    }

    /// Get the wallet's token balance
    pub async fn balance_of_tokens(&self) -> Result<String, WalletError> {
        let balance = self
            .inner
            .balance_of_tokens()
            .await
            .map_err(|e| WalletError::BalanceCheckFailed {
                reason: e.to_string(),
            })?;

        Ok(balance.to_string())
    }
}

/// Payment option for paid operations
#[derive(uniffi::Enum)]
pub enum PaymentOption {
    /// Pay using a wallet
    WalletPayment { wallet_ref: Arc<Wallet> },
}

/// Autonomi network client
#[derive(uniffi::Object)]
pub struct Client {
    inner: Arc<autonomi::Client>,
}

#[uniffi::export(async_runtime = "tokio")]
impl Client {
    /// Initialize a new Autonomi client connected to the production network
    #[uniffi::constructor]
    pub async fn init() -> Result<Arc<Self>, ClientError> {
        let client = autonomi::Client::init()
            .await
            .map_err(|e| ClientError::InitializationFailed {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(Self {
            inner: Arc::new(client),
        }))
    }

    /// Initialize a new Autonomi client connected to a local testnet
    #[uniffi::constructor]
    pub async fn init_local() -> Result<Arc<Self>, ClientError> {
        let client = autonomi::Client::init_local()
            .await
            .map_err(|e| ClientError::InitializationFailed {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(Self {
            inner: Arc::new(client),
        }))
    }

    /// Upload data to the network as public data
    ///
    /// Returns the upload result containing price and data address
    pub async fn data_put_public(
        &self,
        data: Vec<u8>,
        payment: PaymentOption,
    ) -> Result<UploadResult, ClientError> {
        let bytes = Bytes::from(data);

        // Convert our PaymentOption to Autonomi's PaymentOption
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        // Upload the data
        let (price, address) = self
            .inner
            .data_put_public(bytes, autonomi_payment)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(UploadResult {
            price: price.to_string(),
            address: address.to_hex(),
        })
    }

    /// Fetch public data from the network using a hex-encoded data address
    pub async fn data_get_public(&self, address_hex: String) -> Result<Vec<u8>, ClientError> {
        // Parse the hex string into a DataAddress
        let data_address = DataAddress::from_hex(&address_hex).map_err(|e| {
            ClientError::InvalidAddress {
                reason: e.to_string(),
            }
        })?;

        // Fetch the data from the network
        let bytes = self
            .inner
            .data_get_public(&data_address)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(bytes.to_vec())
    }
}

/// Encrypts data using self-encryption algorithm
///
/// Takes raw bytes and returns encrypted chunks along with a datamap chunk
/// that can be used to decrypt the data later
#[uniffi::export]
pub fn encrypt(data: Vec<u8>) -> Result<EncryptedData, EncryptionError> {
    // Convert Vec<u8> to Bytes for the autonomi API
    let bytes_data = Bytes::from(data);

    // Use autonomi's self_encryption wrapper
    let (datamap_chunk, content_chunks) =
        autonomi::self_encryption::encrypt(bytes_data).map_err(|e| {
            EncryptionError::EncryptionFailed {
                reason: e.to_string(),
            }
        })?;

    // Convert datamap chunk to bytes
    let datamap_bytes = datamap_chunk.value().to_vec();

    // Convert content chunks to Vec<Vec<u8>>
    let chunks_bytes: Vec<Vec<u8>> = content_chunks
        .into_iter()
        .map(|chunk| chunk.value().to_vec())
        .collect();

    Ok(EncryptedData {
        datamap_chunk: datamap_bytes,
        content_chunks: chunks_bytes,
    })
}

/// Decrypts data that was previously encrypted with the encrypt function
///
/// Takes the datamap chunk and content chunks returned from encrypt
/// and reconstructs the original data
#[uniffi::export]
pub fn decrypt(encrypted_data: EncryptedData) -> Result<Vec<u8>, EncryptionError> {
    // Deserialize the datamap from bytes
    let datamap: DataMap = rmp_serde::from_slice(&encrypted_data.datamap_chunk).map_err(|e| {
        EncryptionError::EncryptionFailed {
            reason: format!("Failed to deserialize datamap: {}", e),
        }
    })?;

    // Convert Vec<Vec<u8>> back to Vec<EncryptedChunk>
    let encrypted_chunks: Vec<EncryptedChunk> = encrypted_data
        .content_chunks
        .into_iter()
        .map(|chunk_bytes| EncryptedChunk {
            content: Bytes::from(chunk_bytes),
        })
        .collect();

    // Decrypt using self_encryption
    let decrypted_bytes = self_encryption::decrypt(&datamap, &encrypted_chunks).map_err(|e| {
        EncryptionError::EncryptionFailed {
            reason: format!("Failed to decrypt data: {}", e),
        }
    })?;

    Ok(decrypted_bytes.to_vec())
}
