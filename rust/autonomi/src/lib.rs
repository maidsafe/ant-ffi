use autonomi::client::payment::PaymentOption as AutonomiPaymentOption;
use bytes::Bytes;
use std::sync::Arc;

mod data;
mod graph_entry;
mod keys;
mod pointer;
mod scratchpad;
mod self_encryption;

// Re-export data types
pub use data::{Chunk, ChunkAddress, DataAddress, DataError, DataMapChunk};
pub use graph_entry::{GraphDescendant, GraphEntry, GraphEntryAddress, GraphEntryError};
pub use keys::{KeyError, PublicKey, SecretKey};
pub use pointer::{NetworkPointer, PointerAddress, PointerError, PointerTarget};
pub use scratchpad::{Scratchpad, ScratchpadAddress, ScratchpadError};

uniffi::setup_scaffolding!();

/// Result of uploading data to the network
#[derive(uniffi::Record)]
pub struct UploadResult {
    /// The price paid for the upload in tokens
    pub price: String,
    /// The hex-encoded data address where the data was stored
    pub address: String,
}

/// Result of uploading a chunk to the network
#[derive(uniffi::Record)]
pub struct ChunkPutResult {
    /// The cost paid for the upload in tokens
    pub cost: String,
    /// The address where the chunk was stored
    pub address: Arc<ChunkAddress>,
}

/// Result of uploading private data to the network
#[derive(uniffi::Record)]
pub struct DataPutResult {
    /// The cost paid for the upload in tokens
    pub cost: String,
    /// The data map chunk containing metadata to retrieve the data
    pub data_map: Arc<DataMapChunk>,
}

/// Result of creating a pointer on the network
#[derive(uniffi::Record)]
pub struct PointerCreateResult {
    /// The cost paid for creating the pointer in tokens
    pub cost: String,
    /// The address where the pointer was stored
    pub address: Arc<PointerAddress>,
}

/// Result of creating a scratchpad on the network
#[derive(uniffi::Record)]
pub struct ScratchpadCreateResult {
    /// The cost paid for creating the scratchpad in tokens
    pub cost: String,
    /// The address where the scratchpad was stored
    pub address: Arc<ScratchpadAddress>,
}

/// Result of uploading a graph entry to the network
#[derive(uniffi::Record)]
pub struct GraphEntryPutResult {
    /// The cost paid for the upload in tokens
    pub cost: String,
    /// The address where the graph entry was stored
    pub address: Arc<GraphEntryAddress>,
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
        let network =
            autonomi::Network::new(is_local).map_err(|e| NetworkError::CreationFailed {
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
        let balance =
            self.inner
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
        let client =
            autonomi::Client::init()
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
        let client = autonomi::Client::init_local().await.map_err(|e| {
            ClientError::InitializationFailed {
                reason: e.to_string(),
            }
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
        let data_address =
            data::DataAddress::from_hex(address_hex).map_err(|e| ClientError::InvalidAddress {
                reason: e.to_string(),
            })?;

        // Fetch the data from the network
        let bytes = self
            .inner
            .data_get_public(&data_address.inner)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(bytes.to_vec())
    }

    /// Manually upload a chunk to the network.
    /// It is recommended to use `data_put` for larger data as it handles encryption and chunking.
    pub async fn chunk_put(
        &self,
        data: Vec<u8>,
        payment: PaymentOption,
    ) -> Result<ChunkPutResult, ClientError> {
        let chunk = autonomi::Chunk::new(Bytes::from(data));

        // Convert payment option
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        // Upload the chunk
        let (cost, addr) = self
            .inner
            .chunk_put(&chunk, autonomi_payment)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(ChunkPutResult {
            cost: cost.to_string(),
            address: Arc::new(ChunkAddress { inner: addr }),
        })
    }

    /// Get a chunk from the network by its address
    pub async fn chunk_get(&self, addr: Arc<ChunkAddress>) -> Result<Vec<u8>, ClientError> {
        let chunk =
            self.inner
                .chunk_get(&addr.inner)
                .await
                .map_err(|e| ClientError::NetworkError {
                    reason: e.to_string(),
                })?;

        Ok(chunk.value.to_vec())
    }

    /// Get the cost to store a chunk at a specific address
    pub async fn chunk_cost(&self, addr: Arc<ChunkAddress>) -> Result<String, ClientError> {
        let cost =
            self.inner
                .chunk_cost(&addr.inner)
                .await
                .map_err(|e| ClientError::NetworkError {
                    reason: e.to_string(),
                })?;

        Ok(cost.to_string())
    }

    /// Upload private data to the network with self-encryption.
    /// The data is encrypted and split into chunks automatically.
    /// The DataMapChunk contains the metadata needed to retrieve and decrypt the data.
    pub async fn data_put(
        &self,
        data: Vec<u8>,
        payment: PaymentOption,
    ) -> Result<DataPutResult, ClientError> {
        let bytes = Bytes::from(data);

        // Convert payment option
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        // Upload the data
        let (cost, data_map) = self
            .inner
            .data_put(bytes, autonomi_payment)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(DataPutResult {
            cost: cost.to_string(),
            data_map: Arc::new(DataMapChunk { inner: data_map }),
        })
    }

    /// Fetch private data from the network using a DataMapChunk.
    /// The data is automatically decrypted and reassembled from chunks.
    pub async fn data_get(&self, data_map: Arc<DataMapChunk>) -> Result<Vec<u8>, ClientError> {
        let bytes =
            self.inner
                .data_get(&data_map.inner)
                .await
                .map_err(|e| ClientError::NetworkError {
                    reason: e.to_string(),
                })?;

        Ok(bytes.to_vec())
    }

    /// Get the estimated cost of storing private data
    pub async fn data_cost(&self, data: Vec<u8>) -> Result<String, ClientError> {
        let bytes = Bytes::from(data);
        let cost = self
            .inner
            .data_cost(bytes)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(cost.to_string())
    }

    /// Get a pointer from the network by its address
    pub async fn pointer_get(
        &self,
        addr: Arc<PointerAddress>,
    ) -> Result<Arc<NetworkPointer>, ClientError> {
        let pointer =
            self.inner
                .pointer_get(&addr.inner)
                .await
                .map_err(|e| ClientError::NetworkError {
                    reason: e.to_string(),
                })?;

        Ok(Arc::new(NetworkPointer { inner: pointer }))
    }

    /// Store a pointer on the network
    /// Returns the address where the pointer was stored
    pub async fn pointer_put(
        &self,
        pointer: Arc<NetworkPointer>,
        payment: PaymentOption,
    ) -> Result<Arc<PointerAddress>, ClientError> {
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        let (_cost, addr) = self
            .inner
            .pointer_put(pointer.inner.clone(), autonomi_payment)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(PointerAddress { inner: addr }))
    }

    /// Create a new pointer on the network
    /// Make sure the owner key is not already used for another pointer
    pub async fn pointer_create(
        &self,
        owner: Arc<SecretKey>,
        target: Arc<PointerTarget>,
        payment: PaymentOption,
    ) -> Result<PointerCreateResult, ClientError> {
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        let (cost, addr) = self
            .inner
            .pointer_create(&owner.inner, target.inner.clone(), autonomi_payment)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(PointerCreateResult {
            cost: cost.to_string(),
            address: Arc::new(PointerAddress { inner: addr }),
        })
    }

    /// Update an existing pointer to point to a new target
    /// This operation is free as the pointer was already paid for
    /// Only the latest version is kept, previous versions are overwritten
    pub async fn pointer_update(
        &self,
        owner: Arc<SecretKey>,
        target: Arc<PointerTarget>,
    ) -> Result<(), ClientError> {
        self.inner
            .pointer_update(&owner.inner, target.inner.clone())
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(())
    }

    /// Update a pointer from a specific current pointer
    /// Returns the new updated pointer
    pub async fn pointer_update_from(
        &self,
        current: Arc<NetworkPointer>,
        owner: Arc<SecretKey>,
        target: Arc<PointerTarget>,
    ) -> Result<Arc<NetworkPointer>, ClientError> {
        let new_pointer = self
            .inner
            .pointer_update_from(&current.inner, &owner.inner, target.inner.clone())
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(NetworkPointer { inner: new_pointer }))
    }

    /// Get the cost of storing a pointer for a given public key
    pub async fn pointer_cost(&self, key: Arc<PublicKey>) -> Result<String, ClientError> {
        let cost =
            self.inner
                .pointer_cost(&key.inner)
                .await
                .map_err(|e| ClientError::NetworkError {
                    reason: e.to_string(),
                })?;

        Ok(cost.to_string())
    }

    /// Get a scratchpad from the network by its address
    pub async fn scratchpad_get(
        &self,
        addr: Arc<ScratchpadAddress>,
    ) -> Result<Arc<Scratchpad>, ClientError> {
        let scratchpad = self.inner.scratchpad_get(&addr.inner).await.map_err(|e| {
            ClientError::NetworkError {
                reason: e.to_string(),
            }
        })?;

        Ok(Arc::new(Scratchpad { inner: scratchpad }))
    }

    /// Get a scratchpad from the network using the owner's public key
    pub async fn scratchpad_get_from_public_key(
        &self,
        public_key: Arc<PublicKey>,
    ) -> Result<Arc<Scratchpad>, ClientError> {
        let scratchpad = self
            .inner
            .scratchpad_get_from_public_key(&public_key.inner)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(Scratchpad { inner: scratchpad }))
    }

    /// Store a scratchpad on the network
    pub async fn scratchpad_put(
        &self,
        scratchpad: Arc<Scratchpad>,
        payment: PaymentOption,
    ) -> Result<ScratchpadCreateResult, ClientError> {
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        let (cost, addr) = self
            .inner
            .scratchpad_put(scratchpad.inner.clone(), autonomi_payment)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(ScratchpadCreateResult {
            cost: cost.to_string(),
            address: Arc::new(ScratchpadAddress { inner: addr }),
        })
    }

    /// Create a new scratchpad on the network
    /// The data is encrypted with the owner's key
    /// Make sure the owner key is not already used for another scratchpad
    pub async fn scratchpad_create(
        &self,
        owner: Arc<SecretKey>,
        content_type: u64,
        initial_data: Vec<u8>,
        payment: PaymentOption,
    ) -> Result<ScratchpadCreateResult, ClientError> {
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        let (cost, addr) = self
            .inner
            .scratchpad_create(
                &owner.inner,
                content_type,
                &Bytes::from(initial_data),
                autonomi_payment,
            )
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(ScratchpadCreateResult {
            cost: cost.to_string(),
            address: Arc::new(ScratchpadAddress { inner: addr }),
        })
    }

    /// Update an existing scratchpad
    /// This operation is free as the scratchpad was already paid for
    /// Only the latest version is kept, previous versions are overwritten
    pub async fn scratchpad_update(
        &self,
        owner: Arc<SecretKey>,
        content_type: u64,
        data: Vec<u8>,
    ) -> Result<(), ClientError> {
        self.inner
            .scratchpad_update(&owner.inner, content_type, &Bytes::from(data))
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(())
    }

    /// Update a scratchpad from a specific current scratchpad
    /// Returns the new updated scratchpad
    pub async fn scratchpad_update_from(
        &self,
        current: Arc<Scratchpad>,
        owner: Arc<SecretKey>,
        content_type: u64,
        data: Vec<u8>,
    ) -> Result<Arc<Scratchpad>, ClientError> {
        let new_scratchpad = self
            .inner
            .scratchpad_update_from(
                &current.inner,
                &owner.inner,
                content_type,
                &Bytes::from(data),
            )
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(Arc::new(Scratchpad {
            inner: new_scratchpad,
        }))
    }

    /// Update an existing scratchpad without fetching it first
    /// This is useful when you already have the scratchpad
    pub async fn scratchpad_put_update(
        &self,
        scratchpad: Arc<Scratchpad>,
    ) -> Result<(), ClientError> {
        self.inner
            .scratchpad_put_update(scratchpad.inner.clone())
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(())
    }

    /// Get the cost of creating a scratchpad for a given public key
    pub async fn scratchpad_cost(&self, public_key: Arc<PublicKey>) -> Result<String, ClientError> {
        let cost = self
            .inner
            .scratchpad_cost(&public_key.inner)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(cost.to_string())
    }

    // ===== GraphEntry Methods =====

    /// Fetch a graph entry from the network
    pub async fn graph_entry_get(
        &self,
        addr: Arc<GraphEntryAddress>,
    ) -> Result<Arc<GraphEntry>, ClientError> {
        let entry = self.inner.graph_entry_get(&addr.inner).await.map_err(|e| {
            ClientError::NetworkError {
                reason: e.to_string(),
            }
        })?;

        Ok(Arc::new(GraphEntry { inner: entry }))
    }

    /// Check if a graph entry exists on the network
    pub async fn graph_entry_check_existence(
        &self,
        addr: Arc<GraphEntryAddress>,
    ) -> Result<bool, ClientError> {
        let exists = self
            .inner
            .graph_entry_check_existence(&addr.inner)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(exists)
    }

    /// Put a graph entry to the network
    pub async fn graph_entry_put(
        &self,
        entry: Arc<GraphEntry>,
        payment: PaymentOption,
    ) -> Result<GraphEntryPutResult, ClientError> {
        let autonomi_payment = match payment {
            PaymentOption::WalletPayment { wallet_ref } => {
                AutonomiPaymentOption::Wallet(wallet_ref.inner.clone())
            }
        };

        let (cost, addr) = self
            .inner
            .graph_entry_put(entry.inner.clone(), autonomi_payment)
            .await
            .map_err(|e| ClientError::NetworkError {
                reason: e.to_string(),
            })?;

        Ok(GraphEntryPutResult {
            cost: cost.to_string(),
            address: Arc::new(GraphEntryAddress { inner: addr }),
        })
    }

    /// Get the cost to create a graph entry for a given public key
    pub async fn graph_entry_cost(&self, key: Arc<PublicKey>) -> Result<String, ClientError> {
        let cost = self.inner.graph_entry_cost(&key.inner).await.map_err(|e| {
            ClientError::NetworkError {
                reason: e.to_string(),
            }
        })?;

        Ok(cost.to_string())
    }
}

/// Verify a pointer's signature
#[uniffi::export]
pub fn pointer_verify(pointer: Arc<NetworkPointer>) -> Result<(), ClientError> {
    autonomi::Client::pointer_verify(&pointer.inner).map_err(|e| ClientError::NetworkError {
        reason: e.to_string(),
    })
}

/// Verify a scratchpad's signature
#[uniffi::export]
pub fn scratchpad_verify(scratchpad: Arc<Scratchpad>) -> Result<(), ClientError> {
    autonomi::Client::scratchpad_verify(&scratchpad.inner).map_err(|e| ClientError::NetworkError {
        reason: e.to_string(),
    })
}
