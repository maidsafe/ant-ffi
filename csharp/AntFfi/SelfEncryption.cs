using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Represents encrypted data returned from the self-encryption algorithm.
/// </summary>
/// <remarks>
/// This is an opaque blob containing the serialized EncryptedData record from Rust,
/// which includes the datamap chunk and content chunks needed for decryption.
/// </remarks>
public class EncryptedData
{
    /// <summary>
    /// The raw serialized encrypted data (UniFFI format).
    /// </summary>
    internal byte[] RawData { get; }

    internal EncryptedData(byte[] rawData)
    {
        RawData = rawData;
    }

    /// <summary>
    /// Gets the size of the encrypted data in bytes.
    /// </summary>
    public int Size => RawData.Length;
}

/// <summary>
/// Provides self-encryption and decryption functionality.
/// </summary>
/// <remarks>
/// Self-encryption is a content-based encryption scheme where the data is encrypted
/// using keys derived from its own content. This provides convergent encryption
/// where the same data always produces the same encrypted output.
/// </remarks>
public static class SelfEncryption
{
    /// <summary>
    /// Encrypts data using the self-encryption algorithm.
    /// </summary>
    /// <param name="data">The data to encrypt.</param>
    /// <returns>The encrypted data, which can be passed to <see cref="Decrypt"/> to recover the original data.</returns>
    /// <exception cref="EncryptionException">Thrown if encryption fails.</exception>
    /// <exception cref="ArgumentNullException">Thrown if data is null.</exception>
    public static EncryptedData Encrypt(byte[] data)
    {
        ArgumentNullException.ThrowIfNull(data);

        // Serialize data with UniFFI format (4-byte big-endian length prefix)
        var inputBuffer = UniFFIHelpers.ToRustBuffer(data);

        try
        {
            var status = RustCallStatus.Create();
            var resultBuffer = NativeMethods.Encrypt(inputBuffer, ref status);

            if (status.IsError)
            {
                throw new EncryptionException("Encryption failed", status);
            }

            // Get the raw bytes (don't deserialize - this is the serialized EncryptedData record)
            var encryptedBytes = UniFFIHelpers.FromRustBufferRaw(resultBuffer);
            return new EncryptedData(encryptedBytes);
        }
        catch (AntFfiException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new EncryptionException($"Encryption failed: {ex.Message}");
        }
    }

    /// <summary>
    /// Encrypts a string using the self-encryption algorithm.
    /// </summary>
    /// <param name="text">The text to encrypt (will be encoded as UTF-8).</param>
    /// <returns>The encrypted data.</returns>
    public static EncryptedData Encrypt(string text)
    {
        ArgumentNullException.ThrowIfNull(text);
        return Encrypt(System.Text.Encoding.UTF8.GetBytes(text));
    }

    /// <summary>
    /// Decrypts data that was previously encrypted with <see cref="Encrypt"/>.
    /// </summary>
    /// <param name="encryptedData">The encrypted data to decrypt.</param>
    /// <returns>The original decrypted data.</returns>
    /// <exception cref="DecryptionException">Thrown if decryption fails.</exception>
    /// <exception cref="ArgumentNullException">Thrown if encryptedData is null.</exception>
    public static byte[] Decrypt(EncryptedData encryptedData)
    {
        ArgumentNullException.ThrowIfNull(encryptedData);

        // Create a RustBuffer from the raw encrypted data
        var pinnedHandle = System.Runtime.InteropServices.GCHandle.Alloc(
            encryptedData.RawData,
            System.Runtime.InteropServices.GCHandleType.Pinned);

        try
        {
            var foreignBytes = new ForeignBytes
            {
                Len = encryptedData.RawData.Length,
                Data = pinnedHandle.AddrOfPinnedObject()
            };

            var status = RustCallStatus.Create();
            var inputBuffer = NativeMethods.RustBufferFromBytes(foreignBytes, ref status);

            if (status.IsError)
            {
                throw new DecryptionException("Failed to create input buffer", status);
            }

            status = RustCallStatus.Create();
            var resultBuffer = NativeMethods.Decrypt(inputBuffer, ref status);

            if (status.IsError)
            {
                throw new DecryptionException("Decryption failed", status);
            }

            // Deserialize the result (skip UniFFI length prefix)
            return UniFFIHelpers.FromRustBuffer(resultBuffer);
        }
        catch (AntFfiException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new DecryptionException($"Decryption failed: {ex.Message}");
        }
        finally
        {
            pinnedHandle.Free();
        }
    }

    /// <summary>
    /// Decrypts data and returns it as a UTF-8 string.
    /// </summary>
    /// <param name="encryptedData">The encrypted data to decrypt.</param>
    /// <returns>The decrypted data as a string.</returns>
    public static string DecryptToString(EncryptedData encryptedData)
    {
        var bytes = Decrypt(encryptedData);
        return System.Text.Encoding.UTF8.GetString(bytes);
    }
}
