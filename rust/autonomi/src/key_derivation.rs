//! Key derivation module - Hierarchical BLS key derivation for the Autonomi network
//!
//! ## Current Implementation
//! - ✅ DerivationIndex: Index for deriving child keys from master keys
//! - ✅ MainSecretKey: Master secret key for hierarchical derivation
//! - ✅ MainPubkey: Master public key
//! - ✅ DerivedSecretKey: Child secret key derived from master
//! - ✅ DerivedPubkey: Child public key derived from master
//! - ✅ Signature: BLS signature type

use autonomi::client::key_derivation::{
    DerivationIndex as AutonomiDerivationIndex, DerivedPubkey as AutonomiDerivedPubkey,
    DerivedSecretKey as AutonomiDerivedSecretKey, MainPubkey as AutonomiMainPubkey,
    MainSecretKey as AutonomiMainSecretKey,
};
use blsttc::Signature as AutonomiSignature;
use blsttc::rand as bls_rand;
use std::sync::Arc;

use crate::keys::{KeyError, PublicKey, SecretKey};

/// Index for deriving child keys from a master key
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct DerivationIndex {
    pub(crate) inner: AutonomiDerivationIndex,
}

#[uniffi::export]
impl DerivationIndex {
    /// Generate a random derivation index
    #[uniffi::constructor]
    pub fn random() -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiDerivationIndex::random(&mut bls_rand::thread_rng()),
        })
    }

    /// Create a derivation index from 32 bytes
    #[uniffi::constructor]
    pub fn from_bytes(bytes: Vec<u8>) -> Result<Arc<Self>, KeyError> {
        if bytes.len() != 32 {
            return Err(KeyError::InvalidKey {
                reason: format!(
                    "DerivationIndex must be exactly 32 bytes, got {}",
                    bytes.len()
                ),
            });
        }
        let mut array = [0u8; 32];
        array.copy_from_slice(&bytes);
        Ok(Arc::new(Self {
            inner: AutonomiDerivationIndex::from_bytes(array),
        }))
    }

    /// Returns the bytes representation of the derivation index
    pub fn to_bytes(&self) -> Vec<u8> {
        self.inner.into_bytes().to_vec()
    }
}

/// BLS Signature
#[derive(uniffi::Object, Clone, Debug)]
pub struct Signature {
    pub(crate) inner: AutonomiSignature,
}

#[uniffi::export]
impl Signature {
    /// Create a signature from raw bytes (96 bytes for BLS signatures)
    #[uniffi::constructor]
    pub fn from_bytes(bytes: Vec<u8>) -> Result<Arc<Self>, KeyError> {
        if bytes.len() != 96 {
            return Err(KeyError::InvalidKey {
                reason: format!("Signature must be exactly 96 bytes, got {}", bytes.len()),
            });
        }
        let mut array = [0u8; 96];
        array.copy_from_slice(&bytes);
        AutonomiSignature::from_bytes(array)
            .map(|inner| Arc::new(Self { inner }))
            .map_err(|e| KeyError::ParsingFailed {
                reason: format!("Invalid signature: {}", e),
            })
    }

    /// Returns the bytes representation of the signature
    pub fn to_bytes(&self) -> Vec<u8> {
        self.inner.to_bytes().to_vec()
    }

    /// Returns `true` if the signature contains an odd number of ones
    pub fn parity(&self) -> bool {
        self.inner.parity()
    }

    /// Returns the hex representation of the signature
    pub fn to_hex(&self) -> String {
        hex::encode(self.inner.to_bytes())
    }
}

/// Master secret key for hierarchical key derivation
/// Can be used to derive multiple child keys
#[derive(uniffi::Object, Clone, Debug)]
pub struct MainSecretKey {
    pub(crate) inner: AutonomiMainSecretKey,
}

#[uniffi::export]
impl MainSecretKey {
    /// Create a MainSecretKey from a SecretKey
    #[uniffi::constructor]
    pub fn new(secret_key: Arc<SecretKey>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiMainSecretKey::new(secret_key.inner.clone()),
        })
    }

    /// Generate a random MainSecretKey
    #[uniffi::constructor]
    pub fn random() -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiMainSecretKey::random(),
        })
    }

    /// Return the matching MainPubkey
    pub fn public_key(&self) -> Arc<MainPubkey> {
        Arc::new(MainPubkey {
            inner: self.inner.public_key(),
        })
    }

    /// Sign a message with this secret key
    pub fn sign(&self, msg: Vec<u8>) -> Arc<Signature> {
        Arc::new(Signature {
            inner: self.inner.sign(&msg),
        })
    }

    /// Derive a DerivedSecretKey from this master key using the given index
    pub fn derive_key(&self, index: Arc<DerivationIndex>) -> Arc<DerivedSecretKey> {
        Arc::new(DerivedSecretKey {
            inner: self.inner.derive_key(&index.inner),
        })
    }

    /// Generate a new random DerivedSecretKey from this master key
    pub fn random_derived_key(&self) -> Arc<DerivedSecretKey> {
        Arc::new(DerivedSecretKey {
            inner: self.inner.random_derived_key(&mut bls_rand::thread_rng()),
        })
    }

    /// Returns the raw bytes of the secret key
    pub fn to_bytes(&self) -> Vec<u8> {
        self.inner.to_bytes()
    }
}

/// Master public key for hierarchical key derivation
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct MainPubkey {
    pub(crate) inner: AutonomiMainPubkey,
}

#[uniffi::export]
impl MainPubkey {
    /// Create a MainPubkey from a PublicKey
    #[uniffi::constructor]
    pub fn new(public_key: Arc<PublicKey>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiMainPubkey::new(public_key.inner),
        })
    }

    /// Create a MainPubkey from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, KeyError> {
        AutonomiMainPubkey::from_hex(&hex)
            .map(|inner| Arc::new(Self { inner }))
            .map_err(|e| KeyError::ParsingFailed {
                reason: format!("Failed to parse hex: {}", e),
            })
    }

    /// Verify that a signature is valid for the given message
    pub fn verify(&self, signature: Arc<Signature>, msg: Vec<u8>) -> bool {
        self.inner.verify(&signature.inner, &msg)
    }

    /// Derive a DerivedPubkey from this master public key using the given index
    pub fn derive_key(&self, index: Arc<DerivationIndex>) -> Arc<DerivedPubkey> {
        Arc::new(DerivedPubkey {
            inner: self.inner.derive_key(&index.inner),
        })
    }

    /// Returns the bytes representation of the public key
    pub fn to_bytes(&self) -> Vec<u8> {
        self.inner.to_bytes().to_vec()
    }

    /// Returns the hex representation of the public key
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}

/// Derived secret key from hierarchical key derivation
#[derive(uniffi::Object, Clone, Debug)]
pub struct DerivedSecretKey {
    pub(crate) inner: AutonomiDerivedSecretKey,
}

#[uniffi::export]
impl DerivedSecretKey {
    /// Create a DerivedSecretKey from a SecretKey
    #[uniffi::constructor]
    pub fn new(secret_key: Arc<SecretKey>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiDerivedSecretKey::new(secret_key.inner.clone()),
        })
    }

    /// Get the corresponding DerivedPubkey
    pub fn public_key(&self) -> Arc<DerivedPubkey> {
        Arc::new(DerivedPubkey {
            inner: self.inner.public_key(),
        })
    }

    /// Sign a message with this derived secret key
    pub fn sign(&self, msg: Vec<u8>) -> Arc<Signature> {
        Arc::new(Signature {
            inner: self.inner.sign(&msg),
        })
    }
}

/// Derived public key from hierarchical key derivation
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct DerivedPubkey {
    pub(crate) inner: AutonomiDerivedPubkey,
}

#[uniffi::export]
impl DerivedPubkey {
    /// Create a DerivedPubkey from a PublicKey
    #[uniffi::constructor]
    pub fn new(public_key: Arc<PublicKey>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiDerivedPubkey::new(public_key.inner),
        })
    }

    /// Create a DerivedPubkey from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, KeyError> {
        AutonomiDerivedPubkey::from_hex(&hex)
            .map(|inner| Arc::new(Self { inner }))
            .map_err(|e| KeyError::ParsingFailed {
                reason: format!("Failed to parse hex: {}", e),
            })
    }

    /// Verify that a signature is valid for the given message
    pub fn verify(&self, signature: Arc<Signature>, msg: Vec<u8>) -> bool {
        self.inner.verify(&signature.inner, &msg)
    }

    /// Returns the bytes representation of the public key
    pub fn to_bytes(&self) -> Vec<u8> {
        self.inner.to_bytes().to_vec()
    }

    /// Returns the hex representation of the public key
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}
