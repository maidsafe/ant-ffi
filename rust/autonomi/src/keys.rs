use blsttc::{PublicKey as AutonomiPublicKey, SecretKey as AutonomiSecretKey};
use std::sync::Arc;

/// Error type for key operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum KeyError {
    #[error("Invalid key: {reason}")]
    InvalidKey { reason: String },
    #[error("Parsing failed: {reason}")]
    ParsingFailed { reason: String },
}

/// BLS Secret Key for signing operations
#[derive(uniffi::Object, Clone, Debug)]
pub struct SecretKey {
    pub(crate) inner: AutonomiSecretKey,
}

#[uniffi::export]
impl SecretKey {
    /// Generate a random secret key
    #[uniffi::constructor]
    pub fn random() -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiSecretKey::random(),
        })
    }

    /// Create a SecretKey from hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, KeyError> {
        let inner = AutonomiSecretKey::from_hex(&hex).map_err(|e| KeyError::ParsingFailed {
            reason: format!("Failed to parse hex: {}", e),
        })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Serialize to hex string
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }

    /// Get the public key corresponding to this secret key
    pub fn public_key(&self) -> Arc<PublicKey> {
        Arc::new(PublicKey {
            inner: self.inner.public_key(),
        })
    }
}

/// BLS Public Key
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct PublicKey {
    pub(crate) inner: AutonomiPublicKey,
}

#[uniffi::export]
impl PublicKey {
    /// Create a PublicKey from hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, KeyError> {
        let inner = AutonomiPublicKey::from_hex(&hex).map_err(|e| KeyError::ParsingFailed {
            reason: format!("Failed to parse hex: {}", e),
        })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Serialize to hex string
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}
