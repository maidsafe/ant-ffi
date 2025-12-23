//! Data streaming module - Memory-efficient streaming for large data
//!
//! ## Current Implementation
//! - ✅ DataStream: Wrapper for streaming large data in chunks
//! - ✅ Client methods: data_stream, data_stream_public

use autonomi::client::data::DataStream as AutonomiDataStream;
use std::sync::{Arc, Mutex};

use crate::ClientError;

/// A stream for reading large data in chunks without loading everything into memory.
///
/// Use `next_chunk()` to get the next chunk of data, or `collect_all()` to get all data at once.
#[derive(uniffi::Object)]
pub struct DataStream {
    inner: Mutex<AutonomiDataStream>,
}

impl DataStream {
    pub(crate) fn new(stream: AutonomiDataStream) -> Arc<Self> {
        Arc::new(Self {
            inner: Mutex::new(stream),
        })
    }
}

#[uniffi::export]
impl DataStream {
    /// Get the next chunk of data from the stream.
    /// Returns None when the stream is exhausted.
    pub fn next_chunk(&self) -> Result<Option<Vec<u8>>, ClientError> {
        let mut stream = self.inner.lock().map_err(|e| ClientError::NetworkError {
            reason: format!("Lock error: {}", e),
        })?;

        match stream.next() {
            Some(Ok(chunk)) => Ok(Some(chunk.to_vec())),
            Some(Err(e)) => Err(ClientError::NetworkError {
                reason: format!("Stream error: {}", e),
            }),
            None => Ok(None),
        }
    }

    /// Collect all remaining chunks into a single buffer.
    /// This loads all data into memory, so use with caution for large data.
    pub fn collect_all(&self) -> Result<Vec<u8>, ClientError> {
        let mut result = Vec::new();
        while let Some(chunk) = self.next_chunk()? {
            result.extend(chunk);
        }
        Ok(result)
    }

    /// Get the original data size in bytes.
    pub fn data_size(&self) -> Result<u64, ClientError> {
        let stream = self.inner.lock().map_err(|e| ClientError::NetworkError {
            reason: format!("Lock error: {}", e),
        })?;

        Ok(stream.data_size() as u64)
    }

    /// Decrypts and returns a specific byte range from the encrypted data.
    ///
    /// # Arguments
    /// * `start` - The starting byte position (inclusive)
    /// * `length` - The number of bytes to read
    ///
    /// Returns the decrypted bytes for the requested range.
    pub fn get_range(&self, start: u64, length: u64) -> Result<Vec<u8>, ClientError> {
        let stream = self.inner.lock().map_err(|e| ClientError::NetworkError {
            reason: format!("Lock error: {}", e),
        })?;

        stream
            .get_range(start as usize, length as usize)
            .map(|bytes| bytes.to_vec())
            .map_err(|e| ClientError::NetworkError {
                reason: format!("Read range error: {}", e),
            })
    }
}
