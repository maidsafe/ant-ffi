//! Vault module - Encrypted user data storage on the Autonomi network
//!
//! Vaults provide secure, encrypted storage for user data. They are identified by a
//! VaultSecretKey and can store arbitrary data or structured UserData (file archive references).
//!
//! ## Current Implementation
//! - ✅ VaultSecretKey: Secret key for vault encryption/decryption
//! - ✅ UserData: Container for user's file archive references
//! - ✅ Client methods: vault_cost, vault_put, vault_get, vault_get_user_data, vault_put_user_data
//!
//! ## Missing APIs (available in Python bindings - Future Work)
//! - ❌ UserData mutation methods:
//!   - `add_file_archive(addr, name)` - Add public archive reference
//!   - `add_private_file_archive(data_map, name)` - Add private archive reference
//!   - `remove_file_archive(addr)` - Remove archive reference

use autonomi::client::vault::{
    UserData as AutonomiUserData, VaultSecretKey as AutonomiVaultSecretKey,
};
use std::sync::Arc;

/// Error type for vault operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum VaultError {
    #[error("Invalid vault key: {reason}")]
    InvalidKey { reason: String },
    #[error("Parsing failed: {reason}")]
    ParsingFailed { reason: String },
}

/// A secret key used to encrypt and decrypt vault data.
///
/// Vaults are encrypted storage containers identified by this key.
/// Keep this key safe - losing it means losing access to the vault data.
#[derive(uniffi::Object, Clone, Debug)]
pub struct VaultSecretKey {
    pub(crate) inner: AutonomiVaultSecretKey,
}

#[uniffi::export]
impl VaultSecretKey {
    /// Creates a new random vault secret key
    #[uniffi::constructor]
    pub fn random() -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiVaultSecretKey::random(),
        })
    }

    /// Create a VaultSecretKey from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, VaultError> {
        let inner =
            AutonomiVaultSecretKey::from_hex(&hex).map_err(|e| VaultError::ParsingFailed {
                reason: format!("Failed to parse hex: {}", e),
            })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the hex string representation of the vault secret key
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}

/// UserData stored in Vaults containing references to user's file archives.
///
/// This allows users to keep track of only the key to their User Data Vault
/// while having the rest kept on the Network encrypted in a Vault for them.
/// Using User Data Vault is optional - one can decide to keep all their data locally instead.
#[derive(uniffi::Object, Clone, Debug)]
pub struct UserData {
    pub(crate) inner: AutonomiUserData,
}

/// A file archive entry with address and name
#[derive(uniffi::Record, Clone, Debug)]
pub struct FileArchiveEntry {
    /// The hex-encoded address of the archive
    pub address: String,
    /// The user-defined name for this archive
    pub name: String,
}

/// A private file archive entry with data map and name
#[derive(uniffi::Record, Clone, Debug)]
pub struct PrivateFileArchiveEntry {
    /// The hex-encoded data map for the private archive
    pub data_map: String,
    /// The user-defined name for this archive
    pub name: String,
}

#[uniffi::export]
impl UserData {
    /// Creates a new empty UserData instance
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiUserData::new(),
        })
    }

    /// Returns a list of public file archives as (address, name) pairs
    pub fn file_archives(&self) -> Vec<FileArchiveEntry> {
        self.inner
            .file_archives
            .iter()
            .map(|(addr, name)| FileArchiveEntry {
                address: addr.to_hex(),
                name: name.clone(),
            })
            .collect()
    }

    /// Returns a list of private file archives as (data_map, name) pairs
    pub fn private_file_archives(&self) -> Vec<PrivateFileArchiveEntry> {
        self.inner
            .private_file_archives
            .iter()
            .map(|(data_map, name)| PrivateFileArchiveEntry {
                data_map: data_map.to_hex(),
                name: name.clone(),
            })
            .collect()
    }
}

/// Result of fetching vault data
#[derive(uniffi::Record)]
pub struct VaultGetResult {
    /// The decrypted vault data
    pub data: Vec<u8>,
    /// The content type identifier (app-specific)
    pub content_type: u64,
}
