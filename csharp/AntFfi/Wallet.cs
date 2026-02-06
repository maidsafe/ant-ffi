using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a wallet operation fails.
/// </summary>
public class WalletException : AntFfiException
{
    public WalletException(string message) : base(message) { }
    public WalletException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// EVM wallet for managing tokens and payments on the Autonomi network.
/// </summary>
public sealed class Wallet : NativeHandle
{
    internal Wallet(IntPtr handle) : base(handle) { }

    /// <summary>
    /// Creates a wallet from a private key.
    /// </summary>
    /// <param name="network">The network configuration.</param>
    /// <param name="privateKey">The EVM private key (hex string with or without 0x prefix).</param>
    /// <returns>A new Wallet instance.</returns>
    public static Wallet FromPrivateKey(Network network, string privateKey)
    {
        ArgumentNullException.ThrowIfNull(network);
        ArgumentNullException.ThrowIfNull(privateKey);
        network.ThrowIfDisposed();

        var privateKeyBuffer = UniFFIHelpers.StringToRustBuffer(privateKey);
        var status = RustCallStatus.Create();
        var handle = NativeMethods.WalletFromPrivateKey(network.CloneHandle(), privateKeyBuffer, ref status);
        if (status.IsError)
            throw new WalletException("Failed to create wallet from private key", status);
        return new Wallet(handle);
    }

    /// <summary>
    /// Gets the wallet's EVM address as a hex string.
    /// </summary>
    public string Address()
    {
        ThrowIfDisposed();
        var status = RustCallStatus.Create();
        NativeMethods.WalletAddress(out var buffer, CloneHandle(), ref status);
        UniFFIHelpers.CheckStatus(ref status, "Wallet.Address");
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <summary>
    /// Gets the balance of tokens in the wallet.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>The token balance as a string.</returns>
    public async Task<string> BalanceOfTokensAsync(CancellationToken cancellationToken = default)
    {
        ThrowIfDisposed();
        var futureHandle = NativeMethods.WalletBalanceOfTokens(CloneHandle());
        var buffer = await AsyncFutureHelper.PollRustBufferAsync(futureHandle, cancellationToken);
        return UniFFIHelpers.StringFromRustBuffer(buffer);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeWallet(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneWallet(Handle, ref status);
    }
}
