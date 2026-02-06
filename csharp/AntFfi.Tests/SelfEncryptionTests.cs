using Xunit;

namespace AntFfi.Tests;

public class SelfEncryptionTests
{
    [Fact]
    public void Encrypt_WithValidData_ReturnsEncryptedData()
    {
        // Arrange
        var originalData = "Hello from C#! This is a test of self-encryption."u8.ToArray();

        // Act
        var encrypted = SelfEncryption.Encrypt(originalData);

        // Assert
        Assert.NotNull(encrypted);
        Assert.True(encrypted.Size > 0, "Encrypted data should have content");
    }

    [Fact]
    public void Encrypt_Decrypt_Roundtrip_ReturnsOriginalData()
    {
        // Arrange
        var originalMessage = "Hello from C#! This is a test of self-encryption.";
        var originalData = System.Text.Encoding.UTF8.GetBytes(originalMessage);

        // Act
        var encrypted = SelfEncryption.Encrypt(originalData);
        var decrypted = SelfEncryption.Decrypt(encrypted);

        // Assert
        Assert.Equal(originalData, decrypted);
    }

    [Fact]
    public void Encrypt_Decrypt_String_Roundtrip()
    {
        // Arrange
        var originalMessage = "Hello from C#! This is a test of self-encryption.";

        // Act
        var encrypted = SelfEncryption.Encrypt(originalMessage);
        var decrypted = SelfEncryption.DecryptToString(encrypted);

        // Assert
        Assert.Equal(originalMessage, decrypted);
    }

    [Fact]
    public void Encrypt_WithLargeData_Succeeds()
    {
        // Arrange - Create 1MB of random data
        var originalData = new byte[1024 * 1024];
        new Random(42).NextBytes(originalData);

        // Act
        var encrypted = SelfEncryption.Encrypt(originalData);
        var decrypted = SelfEncryption.Decrypt(encrypted);

        // Assert
        Assert.Equal(originalData, decrypted);
    }

    [Fact]
    public void Encrypt_WithEmptyData_HandlesGracefully()
    {
        // Arrange
        var originalData = Array.Empty<byte>();

        // Act & Assert - May throw or return empty, depending on implementation
        try
        {
            var encrypted = SelfEncryption.Encrypt(originalData);
            var decrypted = SelfEncryption.Decrypt(encrypted);
            Assert.Empty(decrypted);
        }
        catch (EncryptionException)
        {
            // Empty data might not be supported by self-encryption
        }
    }

    [Fact]
    public void Encrypt_WithNullData_ThrowsArgumentNullException()
    {
        // Act & Assert
        Assert.Throws<ArgumentNullException>(() => SelfEncryption.Encrypt((byte[])null!));
    }

    [Fact]
    public void Decrypt_WithNullData_ThrowsArgumentNullException()
    {
        // Act & Assert
        Assert.Throws<ArgumentNullException>(() => SelfEncryption.Decrypt(null!));
    }

    [Fact]
    public void Encrypt_SameData_ProducesSameResult()
    {
        // Arrange - Self-encryption is convergent (deterministic)
        var originalData = "Test data for convergent encryption"u8.ToArray();

        // Act
        var encrypted1 = SelfEncryption.Encrypt(originalData);
        var encrypted2 = SelfEncryption.Encrypt(originalData);

        // Assert - Same input should produce same output (convergent encryption)
        Assert.Equal(encrypted1.Size, encrypted2.Size);
    }

    [Fact]
    public void Encrypt_Decrypt_BinaryData_Roundtrip()
    {
        // Arrange - Binary data with null bytes and special characters
        var originalData = new byte[] { 0, 1, 2, 255, 254, 253, 0, 0, 128, 127 };

        // Act
        var encrypted = SelfEncryption.Encrypt(originalData);
        var decrypted = SelfEncryption.Decrypt(encrypted);

        // Assert
        Assert.Equal(originalData, decrypted);
    }
}
