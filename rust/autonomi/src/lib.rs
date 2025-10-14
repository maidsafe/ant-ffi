use bytes::Bytes;
use self_encryption::{DataMap, EncryptedChunk};

uniffi::setup_scaffolding!();

/// Represents encrypted data with a datamap chunk and content chunks
#[derive(uniffi::Record)]
pub struct EncryptedData {
    /// The serialized datamap chunk that contains metadata about the encrypted data
    pub datamap_chunk: Vec<u8>,
    /// The encrypted content chunks
    pub content_chunks: Vec<Vec<u8>>,
}

/// Custom error type for UniFFI
#[derive(Debug, uniffi::Error, thiserror::Error)]
pub enum EncryptionError {
    #[error("Encryption failed: {reason}")]
    EncryptionFailed { reason: String },
}

/// Simple addition function for testing
#[uniffi::export]
pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

/// Encrypts data using self-encryption algorithm
///
/// Takes raw bytes and returns encrypted chunks along with a datamap chunk
/// that can be used to decrypt the data later
#[uniffi::export]
pub fn encrypt(data: Vec<u8>) -> Result<EncryptedData, EncryptionError> {
    // Convert Vec<u8> to Bytes for the autonomi API
    let bytes_data = Bytes::from(data);

    // Use autonomi's self_encryption wrapper
    let (datamap_chunk, content_chunks) =
        autonomi::self_encryption::encrypt(bytes_data).map_err(|e| {
            EncryptionError::EncryptionFailed {
                reason: e.to_string(),
            }
        })?;

    // Convert datamap chunk to bytes
    let datamap_bytes = datamap_chunk.value().to_vec();

    // Convert content chunks to Vec<Vec<u8>>
    let chunks_bytes: Vec<Vec<u8>> = content_chunks
        .into_iter()
        .map(|chunk| chunk.value().to_vec())
        .collect();

    Ok(EncryptedData {
        datamap_chunk: datamap_bytes,
        content_chunks: chunks_bytes,
    })
}

/// Decrypts data that was previously encrypted with the encrypt function
///
/// Takes the datamap chunk and content chunks returned from encrypt
/// and reconstructs the original data
#[uniffi::export]
pub fn decrypt(encrypted_data: EncryptedData) -> Result<Vec<u8>, EncryptionError> {
    // Deserialize the datamap from bytes
    let datamap: DataMap = rmp_serde::from_slice(&encrypted_data.datamap_chunk).map_err(|e| {
        EncryptionError::EncryptionFailed {
            reason: format!("Failed to deserialize datamap: {}", e),
        }
    })?;

    // Convert Vec<Vec<u8>> back to Vec<EncryptedChunk>
    let encrypted_chunks: Vec<EncryptedChunk> = encrypted_data
        .content_chunks
        .into_iter()
        .map(|chunk_bytes| EncryptedChunk {
            content: Bytes::from(chunk_bytes),
        })
        .collect();

    // Decrypt using self_encryption
    let decrypted_bytes = self_encryption::decrypt(&datamap, &encrypted_chunks).map_err(|e| {
        EncryptionError::EncryptionFailed {
            reason: format!("Failed to decrypt data: {}", e),
        }
    })?;

    Ok(decrypted_bytes.to_vec())
}
