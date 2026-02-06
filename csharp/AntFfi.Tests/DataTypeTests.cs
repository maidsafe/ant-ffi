using Xunit;

namespace AntFfi.Tests;

public class ChunkTests
{
    [Fact]
    public void Chunk_Create_WithValidData_Succeeds()
    {
        // Arrange
        var data = new byte[100];
        new Random(42).NextBytes(data);

        // Act
        using var chunk = Chunk.Create(data);

        // Assert
        Assert.NotNull(chunk);
        Assert.Equal((ulong)data.Length, chunk.Size());
    }

    [Fact]
    public void Chunk_Value_ReturnsOriginalData()
    {
        // Arrange
        var data = "Test chunk data"u8.ToArray();

        // Act
        using var chunk = Chunk.Create(data);
        var retrieved = chunk.Value();

        // Assert
        Assert.Equal(data, retrieved);
    }

    [Fact]
    public void Chunk_Address_ReturnsValidAddress()
    {
        // Arrange
        var data = "Test chunk data for address"u8.ToArray();
        using var chunk = Chunk.Create(data);

        // Act
        using var address = chunk.Address();

        // Assert
        Assert.NotNull(address);
        var hex = address.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void ChunkAddress_FromHex_ToHex_Roundtrip()
    {
        // Arrange
        var data = "Test chunk data"u8.ToArray();
        using var chunk = Chunk.Create(data);
        using var original = chunk.Address();
        var hex = original.ToHex();

        // Act
        using var restored = ChunkAddress.FromHex(hex);
        var restoredHex = restored.ToHex();

        // Assert
        Assert.Equal(hex, restoredHex);
    }

    [Fact]
    public void Chunk_SameData_ProducesSameAddress()
    {
        // Arrange - Content-addressed storage means same content = same address
        var data = "Deterministic chunk data"u8.ToArray();

        // Act
        using var chunk1 = Chunk.Create(data);
        using var chunk2 = Chunk.Create(data);
        using var addr1 = chunk1.Address();
        using var addr2 = chunk2.Address();

        // Assert
        Assert.Equal(addr1.ToHex(), addr2.ToHex());
    }

    [Fact]
    public void ChunkConstants_MaxSize_ReturnsValidValue()
    {
        // Act
        var maxSize = ChunkConstants.MaxSize;
        var maxRawSize = ChunkConstants.MaxRawSize;

        // Assert
        Assert.True(maxSize > 0);
        Assert.True(maxRawSize > 0);
        Assert.True(maxRawSize <= maxSize); // Raw size should be <= total max size
    }
}

public class DataAddressTests
{
    [Fact]
    public void DataAddress_FromHex_ToHex_Roundtrip()
    {
        // Arrange - Need to create a valid address first
        var bytes = new byte[32];
        new Random(42).NextBytes(bytes);

        // Act
        using var address = DataAddress.FromBytes(bytes);
        var hex = address.ToHex();
        using var restored = DataAddress.FromHex(hex);
        var restoredHex = restored.ToHex();

        // Assert
        Assert.Equal(hex, restoredHex);
    }
}

public class PointerTests
{
    [Fact]
    public void PointerAddress_FromPublicKey_Succeeds()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        using var publicKey = secretKey.PublicKey();

        // Act
        using var address = PointerAddress.FromPublicKey(publicKey);

        // Assert
        Assert.NotNull(address);
        var hex = address.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void PointerAddress_FromHex_ToHex_Roundtrip()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        using var publicKey = secretKey.PublicKey();
        using var original = PointerAddress.FromPublicKey(publicKey);
        var hex = original.ToHex();

        // Act
        using var restored = PointerAddress.FromHex(hex);
        var restoredHex = restored.ToHex();

        // Assert
        Assert.Equal(hex, restoredHex);
    }

    [Fact]
    public void PointerTarget_ToChunk_Succeeds()
    {
        // Arrange
        var data = "Test data"u8.ToArray();
        using var chunk = Chunk.Create(data);
        using var chunkAddress = chunk.Address();

        // Act
        using var target = PointerTarget.ToChunk(chunkAddress);

        // Assert
        Assert.NotNull(target);
        var hex = target.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void NetworkPointer_Create_Succeeds()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        var data = "Test data"u8.ToArray();
        using var chunk = Chunk.Create(data);
        using var chunkAddress = chunk.Address();
        using var target = PointerTarget.ToChunk(chunkAddress);

        // Act
        using var pointer = NetworkPointer.Create(secretKey, 0, target);

        // Assert
        Assert.NotNull(pointer);
        Assert.Equal(0UL, pointer.Counter);
    }

    [Fact]
    public void NetworkPointer_Address_ReturnsValidAddress()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        var data = "Test data"u8.ToArray();
        using var chunk = Chunk.Create(data);
        using var chunkAddress = chunk.Address();
        using var target = PointerTarget.ToChunk(chunkAddress);
        using var pointer = NetworkPointer.Create(secretKey, 1, target);

        // Act
        using var address = pointer.Address();

        // Assert
        Assert.NotNull(address);
        var hex = address.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }
}

public class ScratchpadTests
{
    [Fact]
    public void ScratchpadAddress_FromPublicKey_Succeeds()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        using var publicKey = secretKey.PublicKey();

        // Act
        using var address = ScratchpadAddress.FromPublicKey(publicKey);

        // Assert
        Assert.NotNull(address);
        var hex = address.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void Scratchpad_Create_Succeeds()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        var data = "Test scratchpad data"u8.ToArray();

        // Act
        using var scratchpad = Scratchpad.Create(secretKey, 0, data, 0);

        // Assert
        Assert.NotNull(scratchpad);
        Assert.Equal(0UL, scratchpad.DataEncoding);
        Assert.Equal(0UL, scratchpad.Counter);
    }

    [Fact]
    public void Scratchpad_DecryptData_ReturnsOriginalData()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        var originalData = "Test scratchpad data for decryption"u8.ToArray();

        // Act
        using var scratchpad = Scratchpad.Create(secretKey, 0, originalData, 0);
        var decrypted = scratchpad.DecryptData(secretKey);

        // Assert
        Assert.Equal(originalData, decrypted);
    }
}

public class RegisterTests
{
    [Fact]
    public void RegisterAddress_FromPublicKey_Succeeds()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        using var publicKey = secretKey.PublicKey();

        // Act
        using var address = RegisterAddress.FromPublicKey(publicKey);

        // Assert
        Assert.NotNull(address);
        var hex = address.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void RegisterHelpers_KeyFromName_ReturnsValidKey()
    {
        // Arrange
        using var secretKey = SecretKey.Random();

        // Act
        using var registerKey = RegisterHelpers.KeyFromName(secretKey, "my-register");

        // Assert
        Assert.NotNull(registerKey);
        var hex = registerKey.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void RegisterHelpers_ValueFromBytes_Returns32Bytes()
    {
        // Arrange
        var data = "Test data to hash into 32 bytes"u8.ToArray();

        // Act
        var value = RegisterHelpers.ValueFromBytes(data);

        // Assert
        Assert.Equal(32, value.Length);
    }
}

public class GraphEntryTests
{
    [Fact]
    public void GraphEntryAddress_FromPublicKey_Succeeds()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        using var publicKey = secretKey.PublicKey();

        // Act
        using var address = GraphEntryAddress.FromPublicKey(publicKey);

        // Assert
        Assert.NotNull(address);
        var hex = address.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void GraphEntryAddress_FromHex_ToHex_Roundtrip()
    {
        // Arrange
        using var secretKey = SecretKey.Random();
        using var publicKey = secretKey.PublicKey();
        using var original = GraphEntryAddress.FromPublicKey(publicKey);
        var hex = original.ToHex();

        // Act
        using var restored = GraphEntryAddress.FromHex(hex);
        var restoredHex = restored.ToHex();

        // Assert
        Assert.Equal(hex, restoredHex);
    }
}

public class VaultTests
{
    [Fact]
    public void VaultSecretKey_Random_CreatesValidKey()
    {
        // Act
        using var key = VaultSecretKey.Random();

        // Assert
        Assert.NotNull(key);
        var hex = key.ToHex();
        Assert.False(string.IsNullOrEmpty(hex));
    }

    [Fact]
    public void VaultSecretKey_FromHex_ToHex_Roundtrip()
    {
        // Arrange
        using var original = VaultSecretKey.Random();
        var hex = original.ToHex();

        // Act
        using var restored = VaultSecretKey.FromHex(hex);
        var restoredHex = restored.ToHex();

        // Assert
        Assert.Equal(hex, restoredHex);
    }

    [Fact]
    public void UserData_Create_Succeeds()
    {
        // Act
        using var userData = UserData.Create();

        // Assert
        Assert.NotNull(userData);
    }
}

public class NetworkTests
{
    [Fact]
    public void Network_Create_Local_Succeeds()
    {
        // Act
        using var network = Network.Create(isLocal: true);

        // Assert
        Assert.NotNull(network);
    }

}
