//! Data module - Chunk and data operations for the Autonomi network
//!
//! ## Current Implementation
//! - ✅ Chunk: Content-addressable data storage
//! - ✅ ChunkAddress: Addressing for chunks
//! - ✅ DataAddress: Public data addresses
//! - ✅ DataMapChunk: Private data encryption metadata
//! - ✅ Client methods: data_put, data_get, data_put_public, data_get_public
//! - ✅ Client methods: chunk_put, chunk_get, chunk_cost, data_cost
//!
//! ## Missing APIs (available in Python bindings)
//! - ❌ Data streaming: `data_stream(access)`, `data_stream_public(addr)` - Stream large data iteratively
//! - ❌ File operations: `file_cost(path)`, `file_download(data_map, path)`, `file_download_public(addr, path)`
//! - ❌ File operations: `file_content_upload(path, payment)`, `file_content_upload_public(path, payment)`
//! - ❌ Directory operations: `dir_download(data_map, path)`, `dir_download_public(addr, path)`
//! - ❌ Directory operations: `dir_content_upload(path, payment)`, `dir_content_upload_public(path, payment)`
//! - ❌ Directory operations: `dir_upload(path, payment)`, `dir_upload_public(path, payment)`
//! - ❌ Archive operations: `archive_cost(archive)`, `archive_get(data_map)`, `archive_get_public(addr)`
//! - ❌ Archive operations: `archive_put(archive, payment)`, `archive_put_public(archive, payment)`
//! - ❌ Archive types: `PrivateArchive`, `PublicArchive`, `ArchiveAddress`, `PrivateArchiveDataMap`, `Metadata`

use autonomi::data::{
    DataAddress as AutonomiDataAddress, private::DataMapChunk as AutonomiDataMapChunk,
};
use autonomi::{Chunk as AutonomiChunk, ChunkAddress as AutonomiChunkAddress, XorName};
use bytes::Bytes;
use std::sync::Arc;

/// Error type for data operations
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum DataError {
    #[error("Invalid data: {reason}")]
    InvalidData { reason: String },
    #[error("Parsing failed: {reason}")]
    ParsingFailed { reason: String },
}

/// A chunk of data stored on the network.
/// Chunks are content-addressable, meaning their address is derived from their content.
#[derive(uniffi::Object, Clone, Debug)]
pub struct Chunk {
    pub(crate) inner: AutonomiChunk,
}

#[uniffi::export]
impl Chunk {
    /// Creates a new chunk from raw data
    #[uniffi::constructor]
    pub fn new(value: Vec<u8>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiChunk::new(Bytes::from(value)),
        })
    }

    /// Returns the content of the chunk
    pub fn value(&self) -> Vec<u8> {
        self.inner.value().to_vec()
    }

    /// Returns the address of the chunk
    pub fn address(&self) -> Arc<ChunkAddress> {
        Arc::new(ChunkAddress {
            inner: *self.inner.address(),
        })
    }

    /// Returns the network address as a string
    pub fn network_address(&self) -> String {
        self.inner.network_address().to_string()
    }

    /// Returns the size of this chunk after serialization
    pub fn size(&self) -> u64 {
        self.inner.size() as u64
    }

    /// Returns true if the chunk is too big to store
    pub fn is_too_big(&self) -> bool {
        self.inner.is_too_big()
    }
}

/// The maximum size of an unencrypted/raw chunk (4MB)
#[uniffi::export]
pub fn chunk_max_raw_size() -> u64 {
    AutonomiChunk::MAX_RAW_SIZE as u64
}

/// The maximum size of an encrypted chunk (4MB + 32 bytes)
#[uniffi::export]
pub fn chunk_max_size() -> u64 {
    AutonomiChunk::MAX_SIZE as u64
}

/// An address of a chunk of data on the network.
/// Used to locate and retrieve data chunks.
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct ChunkAddress {
    pub(crate) inner: AutonomiChunkAddress,
}

#[uniffi::export]
impl ChunkAddress {
    /// Creates a new chunk address from raw bytes (32 bytes)
    #[uniffi::constructor]
    pub fn new(bytes: Vec<u8>) -> Result<Arc<Self>, DataError> {
        if bytes.len() != 32 {
            return Err(DataError::InvalidData {
                reason: format!("XorName must be exactly 32 bytes, got {}", bytes.len()),
            });
        }
        let mut array = [0u8; 32];
        array.copy_from_slice(&bytes);
        Ok(Arc::new(Self {
            inner: AutonomiChunkAddress::new(XorName(array)),
        }))
    }

    /// Generate a chunk address for the given content (content-addressable storage)
    #[uniffi::constructor]
    pub fn from_content(data: Vec<u8>) -> Arc<Self> {
        Arc::new(Self {
            inner: AutonomiChunkAddress::new(XorName::from_content(&data)),
        })
    }

    /// Create a ChunkAddress from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, DataError> {
        let inner = AutonomiChunkAddress::from_hex(&hex).map_err(|e| DataError::ParsingFailed {
            reason: format!("Failed to parse hex: {}", e),
        })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the hex string representation of the address
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }

    /// Returns the raw bytes of the address (32 bytes)
    pub fn to_bytes(&self) -> Vec<u8> {
        self.inner.xorname().0.to_vec()
    }
}

/// Address of public data on the network
#[derive(uniffi::Object, Clone, Copy, Debug)]
pub struct DataAddress {
    pub(crate) inner: AutonomiDataAddress,
}

#[uniffi::export]
impl DataAddress {
    /// Construct a new DataAddress from raw bytes (32 bytes)
    #[uniffi::constructor]
    pub fn new(bytes: Vec<u8>) -> Result<Arc<Self>, DataError> {
        if bytes.len() != 32 {
            return Err(DataError::InvalidData {
                reason: format!("XorName must be exactly 32 bytes, got {}", bytes.len()),
            });
        }
        let mut array = [0u8; 32];
        array.copy_from_slice(&bytes);
        Ok(Arc::new(Self {
            inner: AutonomiDataAddress::new(XorName(array)),
        }))
    }

    /// Create a DataAddress from a hex string
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, DataError> {
        let inner = AutonomiDataAddress::from_hex(&hex).map_err(|e| DataError::ParsingFailed {
            reason: format!("Failed to parse hex: {}", e),
        })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the hex string representation of the address
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }

    /// Returns the raw bytes of the address (32 bytes)
    pub fn to_bytes(&self) -> Vec<u8> {
        self.inner.xorname().0.to_vec()
    }
}

/// DataMapChunk contains the metadata needed to decrypt and retrieve private data.
/// It's returned when uploading private data and used when downloading it.
#[derive(uniffi::Object, Clone, Debug)]
pub struct DataMapChunk {
    pub(crate) inner: AutonomiDataMapChunk,
}

#[uniffi::export]
impl DataMapChunk {
    /// Creates a DataMapChunk from a hex string representation
    #[uniffi::constructor]
    pub fn from_hex(hex: String) -> Result<Arc<Self>, DataError> {
        let inner = AutonomiDataMapChunk::from_hex(&hex).map_err(|e| DataError::ParsingFailed {
            reason: format!("Failed to parse hex: {}", e),
        })?;
        Ok(Arc::new(Self { inner }))
    }

    /// Returns the hex string representation of this DataMapChunk
    pub fn to_hex(&self) -> String {
        self.inner.to_hex()
    }

    /// Returns the address of this DataMapChunk
    /// Note: This is not a network address, it's only used for referring to private data client-side
    pub fn address(&self) -> String {
        self.inner.address().to_string()
    }
}
