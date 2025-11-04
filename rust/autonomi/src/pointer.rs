use autonomi::pointer::{
    Pointer as AutonomiPointer, PointerAddress as AutonomiPointerAddress,
    PointerTarget as AutonomiPointerTarget,
};
use std::sync::Arc;

use crate::data::ChunkAddress;
use crate::keys::{PublicKey, SecretKey};

/// Error type for pointer operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum PointerError {
    #[error("Invalid pointer: {reason}")]
    InvalidPointer { reason: String },
    #[error("Parsing failed: {reason}")]
    ParsingFailed { reason: String },
}

/// Address of a pointer on the network, derived from the owner's public key
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct PointerAddress {
    pub(crate) inner: AutonomiPointerAddress,
}

#[uniffi::export]
impl PointerAddress {
    /// Create a new PointerAddress from a public key (owner)
    #[uniffi::constructor]
    pub fn new(public_key: Arc<PublicKey>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiPointerAddress::new(public_key.inner),
        })
    }

    /// Create a PointerAddress from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, PointerError> {
        let inner =
            AutonomiPointerAddress::from_hex(&hex).map_err(|e| PointerError::ParsingFailed {
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

/// A mutable pointer to data on the network
/// Stored at the owner's public key address and can only be updated by the owner
#[derive(uniffi::Object, Clone, Debug)]
pub struct NetworkPointer {
    pub(crate) inner: AutonomiPointer,
}

#[uniffi::export]
impl NetworkPointer {
    /// Create a new pointer signed with the provided secret key
    /// There can only be one pointer per key on the network
    #[uniffi::constructor]
    pub fn new(key: Arc<SecretKey>, counter: u64, target: Arc<PointerTarget>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiPointer::new(&key.inner, counter, target.inner.clone()),
        })
    }

    /// Get the network address where this pointer is stored
    pub fn address(&self) -> Arc<PointerAddress> {
        Arc::new(PointerAddress {
            inner: self.inner.address(),
        })
    }

    /// Get the target that this pointer points to
    pub fn target(&self) -> Arc<PointerTarget> {
        Arc::new(PointerTarget {
            inner: self.inner.target().clone(),
        })
    }

    /// Get the counter value (version) of this pointer
    pub fn counter(&self) -> u64 {
        self.inner.counter()
    }
}

/// The target that a pointer can point to on the network
#[derive(uniffi::Object, Clone, Debug)]
pub struct PointerTarget {
    pub(crate) inner: AutonomiPointerTarget,
}

#[uniffi::export]
impl PointerTarget {
    /// Create a pointer target pointing to a chunk
    #[uniffi::constructor]
    pub fn chunk(addr: Arc<ChunkAddress>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiPointerTarget::ChunkAddress(addr.inner),
        })
    }

    /// Create a pointer target pointing to another pointer
    #[uniffi::constructor]
    pub fn pointer(addr: Arc<PointerAddress>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiPointerTarget::PointerAddress(addr.inner),
        })
    }

    /// Serialize to hex string
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}
