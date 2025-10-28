use autonomi::scratchpad::{
    Scratchpad as AutonomiScratchpad, ScratchpadAddress as AutonomiScratchpadAddress,
};
use bytes::Bytes;
use std::sync::Arc;

use crate::keys::{PublicKey, SecretKey};

/// Error type for scratchpad operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum ScratchpadError {
    #[error("Invalid scratchpad: {reason}")]
    InvalidScratchpad { reason: String },
    #[error("Parsing failed: {reason}")]
    ParsingFailed { reason: String },
    #[error("Decryption failed: {reason}")]
    DecryptionFailed { reason: String },
}

/// Address of a scratchpad on the network, derived from the owner's public key
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct ScratchpadAddress {
    pub(crate) inner: AutonomiScratchpadAddress,
}

#[uniffi::export]
impl ScratchpadAddress {
    /// Create a new ScratchpadAddress from a public key (owner)
    #[uniffi::constructor]
    pub fn new(public_key: Arc<PublicKey>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiScratchpadAddress::new(public_key.inner),
        })
    }

    /// Create a ScratchpadAddress from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, ScratchpadError> {
        let inner = AutonomiScratchpadAddress::from_hex(&hex)
            .map_err(|e| ScratchpadError::ParsingFailed {
                reason: format!("Failed to parse hex: {}", e),
            })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the owner's public key
    pub fn owner(&self) -> Arc<PublicKey> {
        Arc::new(PublicKey {
            inner: *self.inner.owner(),
        })
    }

    /// Serialize to hex string
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}

/// Scratchpad - encrypted mutable data with versioning
/// Stored at the owner's public key address, only updatable by the owner
#[derive(uniffi::Object, Clone, Debug)]
pub struct Scratchpad {
    pub(crate) inner: AutonomiScratchpad,
}

#[uniffi::export]
impl Scratchpad {
    /// Create a new scratchpad with encrypted data
    /// The data is encrypted with the owner's key before storage
    #[uniffi::constructor]
    pub fn new(
        owner: Arc<SecretKey>,
        data_encoding: u64,
        unencrypted_data: Vec<u8>,
        counter: u64,
    ) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiScratchpad::new(
                &owner.inner,
                data_encoding,
                &Bytes::from(unencrypted_data),
                counter,
            ),
        })
    }

    /// Get the network address where this scratchpad is stored
    pub fn address(&self) -> Arc<ScratchpadAddress> {
        Arc::new(ScratchpadAddress {
            inner: *self.inner.address(),
        })
    }

    /// Get the data encoding type
    pub fn data_encoding(&self) -> u64 {
        self.inner.data_encoding()
    }

    /// Get the counter (version) of this scratchpad
    /// Higher counter means more recent version
    pub fn counter(&self) -> u64 {
        self.inner.counter()
    }

    /// Decrypt the data using the owner's secret key
    pub fn decrypt_data(&self, sk: Arc<SecretKey>) -> Result<Vec<u8>, ScratchpadError> {
        let data = self
            .inner
            .decrypt_data(&sk.inner)
            .map_err(|e| ScratchpadError::DecryptionFailed {
                reason: format!("Failed to decrypt: {}", e),
            })?;
        Ok(data.to_vec())
    }

    /// Get the owner's public key
    pub fn owner(&self) -> Arc<PublicKey> {
        Arc::new(PublicKey {
            inner: *self.inner.owner(),
        })
    }

    /// Get the scratchpad hash as hex string
    pub fn scratchpad_hash(&self) -> String {
        hex::encode(self.inner.scratchpad_hash().0)
    }

    /// Get the encrypted data hash as hex string
    pub fn encrypted_data_hash(&self) -> String {
        hex::encode(self.inner.encrypted_data_hash())
    }

    /// Get the encrypted data
    pub fn encrypted_data(&self) -> Vec<u8> {
        self.inner.encrypted_data().to_vec()
    }
}
