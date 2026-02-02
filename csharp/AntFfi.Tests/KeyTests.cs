using Xunit;

namespace AntFfi.Tests;

public class KeyTests
{
    [Fact]
    public void SecretKey_Random_CreatesValidKey()
    {
        // Act
        using var secretKey = SecretKey.Random();

        // Assert
        Assert.NotNull(secretKey);
        var hex = secretKey.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void SecretKey_FromHex_ToHex_Roundtrip()
    {
        // Arrange
        using var original = SecretKey.Random();
        var hex = original.ToHex();

        // Act
        using var restored = SecretKey.FromHex(hex);
        var restoredHex = restored.ToHex();

        // Assert
        Assert.Equal(hex, restoredHex);
    }

    [Fact]
    public void SecretKey_PublicKey_ReturnsValidPublicKey()
    {
        // Arrange
        using var secretKey = SecretKey.Random();

        // Act
        using var publicKey = secretKey.PublicKey();

        // Assert
        Assert.NotNull(publicKey);
        var hex = publicKey.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void PublicKey_FromHex_ToHex_Roundtrip()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        using var original = secretKey.PublicKey();
        var hex = original.ToHex();

        // Act
        using var restored = PublicKey.FromHex(hex);
        var restoredHex = restored.ToHex();

        // Assert
        Assert.Equal(hex, restoredHex);
    }

    [Fact]
    public void SecretKey_FromHex_WithInvalidHex_ThrowsException()
    {
        // Act & Assert
        Assert.Throws<KeyException>(() => SecretKey.FromHex("not_a_valid_hex"));
    }

    [Fact]
    public void SecretKey_DisposedTwice_DoesNotThrow()
    {
        // Arrange
        var secretKey = SecretKey.Random();

        // Act
        secretKey.Dispose();
        secretKey.Dispose(); // Should not throw

        // Assert - No exception
    }

    [Fact]
    public void SecretKey_UseAfterDispose_ThrowsObjectDisposedException()
    {
        // Arrange
        var secretKey = SecretKey.Random();
        secretKey.Dispose();

        // Act & Assert
        Assert.Throws<ObjectDisposedException>(() => secretKey.ToHex());
    }

    [Fact]
    public void SecretKey_Random_CreatesUniqueKeys()
    {
        // Act
        using var key1 = SecretKey.Random();
        using var key2 = SecretKey.Random();

        // Assert
        Assert.NotEqual(key1.ToHex(), key2.ToHex());
    }

    // Helper to call ToHex in a separate stack frame
    [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.NoInlining)]
    private static string GetHexInSeparateFrame(SecretKey sk) => sk.ToHex();

    [Fact]
    public void PublicKey_FromSameSecretKey_IsDeterministic()
    {
        using var sk = SecretKey.Random();

        // Call ToHex in separate stack frames to rule out stack slot reuse
        var hexA = GetHexInSeparateFrame(sk);
        var hexB = GetHexInSeparateFrame(sk);

        Assert.True(hexA == hexB,
            $"Same key ToHex differs (separate frames):\nhexA: {hexA}\nhexB: {hexB}");
    }
}

public class DerivationIndexTests
{
    [Fact]
    public void DerivationIndex_Random_CreatesValidIndex()
    {
        // Act
        using var index = DerivationIndex.Random();

        // Assert
        Assert.NotNull(index);
        var bytes = index.ToBytes();
        Assert.NotEmpty(bytes);
    }

    [Fact]
    public void DerivationIndex_FromBytes_ToBytes_Roundtrip()
    {
        // Arrange
        using var original = DerivationIndex.Random();
        var bytes = original.ToBytes();

        // Act
        using var restored = DerivationIndex.FromBytes(bytes);
        var restoredBytes = restored.ToBytes();

        // Assert
        Assert.Equal(bytes, restoredBytes);
    }
}

public class MainSecretKeyTests
{
    [Fact]
    public void MainSecretKey_Random_CreatesValidKey()
    {
        // Act
        using var mainKey = MainSecretKey.Random();

        // Assert
        Assert.NotNull(mainKey);
        var bytes = mainKey.ToBytes();
        Assert.NotEmpty(bytes);
    }

    [Fact]
    public void MainSecretKey_PublicKey_ReturnsValidKey()
    {
        // Arrange
        using var mainKey = MainSecretKey.Random();

        // Act
        using var publicKey = mainKey.PublicKey();

        // Assert
        Assert.NotNull(publicKey);
        var hex = publicKey.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void MainSecretKey_DeriveKey_ReturnsValidDerivedKey()
    {
        // Arrange
        using var mainKey = MainSecretKey.Random();
        using var index = DerivationIndex.Random();

        // Act
        using var derived = mainKey.DeriveKey(index);

        // Assert
        Assert.NotNull(derived);
    }

    [Fact]
    public void MainSecretKey_Sign_CreatesValidSignature()
    {
        // Arrange
        using var mainKey = MainSecretKey.Random();
        var message = "Test message to sign"u8.ToArray();

        // Act
        using var signature = mainKey.Sign(message);

        // Assert
        Assert.NotNull(signature);
        var sigBytes = signature.ToBytes();
        Assert.NotEmpty(sigBytes);
    }

    [Fact]
    public void MainSecretKey_Sign_Verify_Roundtrip()
    {
        // Arrange
        using var mainKey = MainSecretKey.Random();
        using var publicKey = mainKey.PublicKey();
        var message = "Test message to sign and verify"u8.ToArray();

        // Act
        using var signature = mainKey.Sign(message);
        var isValid = publicKey.Verify(signature, message);

        // Assert
        Assert.True(isValid);
    }

    [Fact]
    public void MainPubkey_Verify_WithWrongMessage_ReturnsFalse()
    {
        // Arrange
        using var mainKey = MainSecretKey.Random();
        using var publicKey = mainKey.PublicKey();
        var originalMessage = "Original message"u8.ToArray();
        var wrongMessage = "Wrong message"u8.ToArray();

        // Act
        using var signature = mainKey.Sign(originalMessage);
        var isValid = publicKey.Verify(signature, wrongMessage);

        // Assert
        Assert.False(isValid);
    }
}
