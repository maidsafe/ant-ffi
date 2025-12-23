//! Archive module - File collections with metadata for the Autonomi network
//!
//! ## Current Implementation
//! - ✅ Metadata: File metadata (size, creation time, modification time)
//! - ✅ PublicArchive: Collection of public files with metadata
//! - ✅ PrivateArchive: Collection of private files with encryption
//! - ✅ ArchiveAddress: Address for public archives on the network
//! - ✅ PrivateArchiveDataMap: Datamap for private archives
//! - ✅ Client methods: archive_cost, archive_get, archive_put, archive_put_public, archive_get_public

use autonomi::files::archive_private::PrivateArchiveDataMap as AutonomiPrivateArchiveDataMap;
use autonomi::files::archive_public::ArchiveAddress as AutonomiArchiveAddress;
use autonomi::files::{
    Metadata as AutonomiMetadata, PrivateArchive as AutonomiPrivateArchive,
    PublicArchive as AutonomiPublicArchive,
};
use std::sync::Arc;

use crate::data::{DataAddress, DataMapChunk};

/// Error type for archive operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum ArchiveError {
    #[error("Invalid archive: {reason}")]
    InvalidArchive { reason: String },
    #[error("Parsing failed: {reason}")]
    ParsingFailed { reason: String },
    #[error("File not found: {path}")]
    FileNotFound { path: String },
}

/// Metadata for files in an archive, containing creation time, modification time, and size.
#[derive(uniffi::Object, Clone, Debug)]
pub struct Metadata {
    pub(crate) inner: AutonomiMetadata,
}

#[uniffi::export]
impl Metadata {
    /// Create new metadata with the given file size.
    /// Creation and modification times are set to the current time.
    #[uniffi::constructor]
    pub fn new(size: u64) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiMetadata::new_with_size(size),
        })
    }

    /// Create metadata with specific timestamps
    #[uniffi::constructor]
    pub fn with_timestamps(size: u64, created: u64, modified: u64) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiMetadata {
                size,
                created,
                modified,
                extra: None,
            },
        })
    }

    /// Get the file size in bytes
    pub fn size(&self) -> u64 {
        self.inner.size
    }

    /// Get the creation time as Unix timestamp in seconds
    pub fn created(&self) -> u64 {
        self.inner.created
    }

    /// Get the modification time as Unix timestamp in seconds
    pub fn modified(&self) -> u64 {
        self.inner.modified
    }
}

/// Address of a public archive on the network
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct ArchiveAddress {
    pub(crate) inner: AutonomiArchiveAddress,
}

#[uniffi::export]
impl ArchiveAddress {
    /// Create an ArchiveAddress from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, ArchiveError> {
        let inner =
            AutonomiArchiveAddress::from_hex(&hex).map_err(|e| ArchiveError::ParsingFailed {
                reason: format!("Failed to parse hex: {}", e),
            })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the hex string representation of this archive address
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}

/// Datamap for a private archive, used to retrieve the archive from the network
#[derive(uniffi::Object, Clone, Debug)]
pub struct PrivateArchiveDataMap {
    pub(crate) inner: AutonomiPrivateArchiveDataMap,
}

#[uniffi::export]
impl PrivateArchiveDataMap {
    /// Create a PrivateArchiveDataMap from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, ArchiveError> {
        let inner = AutonomiPrivateArchiveDataMap::from_hex(&hex).map_err(|e| {
            ArchiveError::ParsingFailed {
                reason: format!("Failed to parse hex: {}", e),
            }
        })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the hex string representation of this private archive datamap
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }
}

/// A file entry in a public archive
#[derive(uniffi::Record)]
pub struct PublicArchiveFileEntry {
    /// The path of the file in the archive
    pub path: String,
    /// The data address where the file content is stored
    pub address: Arc<DataAddress>,
    /// Metadata about the file
    pub metadata: Arc<Metadata>,
}

/// A file entry in a private archive
#[derive(uniffi::Record)]
pub struct PrivateArchiveFileEntry {
    /// The path of the file in the archive
    pub path: String,
    /// The data map chunk to retrieve the file content
    pub data_map: Arc<DataMapChunk>,
    /// Metadata about the file
    pub metadata: Arc<Metadata>,
}

/// A public archive containing files that can be accessed by anyone on the network.
#[derive(uniffi::Object, Clone, Debug)]
pub struct PublicArchive {
    pub(crate) inner: AutonomiPublicArchive,
}

#[uniffi::export]
impl PublicArchive {
    /// Create a new empty public archive
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiPublicArchive::new(),
        })
    }

    /// Add a file to the archive
    pub fn add_file(
        &self,
        path: String,
        address: Arc<DataAddress>,
        metadata: Arc<Metadata>,
    ) -> Arc<Self> {
        let mut archive = self.inner.clone();
        archive.add_file(
            std::path::PathBuf::from(path),
            address.inner,
            metadata.inner.clone(),
        );
        Arc::new(Self { inner: archive })
    }

    /// Rename a file in the archive
    pub fn rename_file(
        &self,
        old_path: String,
        new_path: String,
    ) -> Result<Arc<Self>, ArchiveError> {
        let mut archive = self.inner.clone();
        archive
            .rename_file(
                &std::path::PathBuf::from(&old_path),
                &std::path::PathBuf::from(&new_path),
            )
            .map_err(|e| ArchiveError::InvalidArchive {
                reason: format!("Failed to rename file: {}", e),
            })?;
        Ok(Arc::new(Self { inner: archive }))
    }

    /// List all files in the archive
    pub fn files(&self) -> Vec<PublicArchiveFileEntry> {
        self.inner
            .map()
            .iter()
            .map(|(path, (addr, meta))| PublicArchiveFileEntry {
                path: path.to_string_lossy().to_string(),
                address: Arc::new(DataAddress { inner: *addr }),
                metadata: Arc::new(Metadata {
                    inner: meta.clone(),
                }),
            })
            .collect()
    }

    /// Get the number of files in the archive
    pub fn file_count(&self) -> u64 {
        self.inner.map().len() as u64
    }

    /// Get all data addresses in the archive
    pub fn addresses(&self) -> Vec<String> {
        self.inner
            .addresses()
            .into_iter()
            .map(|a| a.to_hex())
            .collect()
    }
}

/// A private archive containing files with encrypted access.
#[derive(uniffi::Object, Clone, Debug)]
pub struct PrivateArchive {
    pub(crate) inner: AutonomiPrivateArchive,
}

#[uniffi::export]
impl PrivateArchive {
    /// Create a new empty private archive
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiPrivateArchive::new(),
        })
    }

    /// Add a file to the archive
    pub fn add_file(
        &self,
        path: String,
        data_map: Arc<DataMapChunk>,
        metadata: Arc<Metadata>,
    ) -> Arc<Self> {
        let mut archive = self.inner.clone();
        archive.add_file(
            std::path::PathBuf::from(path),
            data_map.inner.clone(),
            metadata.inner.clone(),
        );
        Arc::new(Self { inner: archive })
    }

    /// Rename a file in the archive
    pub fn rename_file(
        &self,
        old_path: String,
        new_path: String,
    ) -> Result<Arc<Self>, ArchiveError> {
        let mut archive = self.inner.clone();
        archive
            .rename_file(
                &std::path::PathBuf::from(&old_path),
                &std::path::PathBuf::from(&new_path),
            )
            .map_err(|e| ArchiveError::InvalidArchive {
                reason: format!("Failed to rename file: {}", e),
            })?;
        Ok(Arc::new(Self { inner: archive }))
    }

    /// List all files in the archive
    pub fn files(&self) -> Vec<PrivateArchiveFileEntry> {
        self.inner
            .map()
            .iter()
            .map(|(path, (data_map, meta))| PrivateArchiveFileEntry {
                path: path.to_string_lossy().to_string(),
                data_map: Arc::new(DataMapChunk {
                    inner: data_map.clone(),
                }),
                metadata: Arc::new(Metadata {
                    inner: meta.clone(),
                }),
            })
            .collect()
    }

    /// Get the number of files in the archive
    pub fn file_count(&self) -> u64 {
        self.inner.map().len() as u64
    }

    /// Get all data maps in the archive
    pub fn data_maps(&self) -> Vec<Arc<DataMapChunk>> {
        self.inner
            .data_maps()
            .into_iter()
            .map(|dm| Arc::new(DataMapChunk { inner: dm }))
            .collect()
    }
}
