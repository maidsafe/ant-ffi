//! Registers module - Mutable versioned storage on the Autonomi network
//!
//! Registers provide mutable, versioned data storage where data can be updated while
//! maintaining a version history. Unlike pointers and scratchpads, registers can store
//! arbitrary-length data with full version tracking.
//!
//! ## Current Implementation
//! - ✅ RegisterAddress: Address derived from owner's public key
//! - ✅ Client methods: register_create, register_update, register_get, register_cost, register_history_collect
//! - ✅ Helper functions: register_key_from_name, register_value_from_bytes

use autonomi::register::RegisterAddress as AutonomiRegisterAddress;
use std::sync::Arc;

use crate::keys::{PublicKey, SecretKey};

/// Error type for register operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum RegisterError {
    #[error("Invalid register: {reason}")]
    InvalidRegister { reason: String },
    #[error("Parsing failed: {reason}")]
    ParsingFailed { reason: String },
}

/// Address of a register on the network, derived from the owner's public key.
///
/// Registers are mutable data structures that allow versioned updates.
/// They are stored at an address derived from the owner's public key.
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct RegisterAddress {
    pub(crate) inner: AutonomiRegisterAddress,
}

#[uniffi::export]
impl RegisterAddress {
    /// Create a new RegisterAddress from a public key (owner)
    #[uniffi::constructor]
    pub fn new(owner: Arc<PublicKey>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiRegisterAddress::new(owner.inner),
        })
    }

    /// Create a RegisterAddress from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, RegisterError> {
        let inner =
            AutonomiRegisterAddress::from_hex(&hex).map_err(|e| RegisterError::ParsingFailed {
                reason: format!("Failed to parse hex: {}", e),
            })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the owner's public key
    pub fn owner(&self) -> Arc<PublicKey> {
        Arc::new(PublicKey {
            inner: self.inner.owner(),
        })
    }

    /// Serialize to hex string
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}

/// Derive a register key from a secret key and a name.
/// This is useful for creating multiple registers from a single key.
#[uniffi::export]
pub fn register_key_from_name(owner: Arc<SecretKey>, name: String) -> Arc<SecretKey> {
    let key = autonomi::Client::register_key_from_name(&owner.inner, &name);
    Arc::new(SecretKey { inner: key })
}

/// Create a register value from bytes.
/// The input must be at most 32 bytes. If shorter, it will be padded with zeros.
#[uniffi::export]
pub fn register_value_from_bytes(bytes: Vec<u8>) -> Result<Vec<u8>, RegisterError> {
    let value = autonomi::Client::register_value_from_bytes(&bytes).map_err(|e| {
        RegisterError::InvalidRegister {
            reason: format!("Invalid register value: {}", e),
        }
    })?;
    Ok(value.to_vec())
}
