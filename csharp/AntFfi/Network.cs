using AntFfi.Native;

namespace AntFfi;

/// <summary>
/// Exception thrown when a network operation fails.
/// </summary>
public class NetworkException : AntFfiException
{
    public NetworkException(string message) : base(message) { }
    public NetworkException(string message, RustCallStatus status) : base(message, status) { }
}

/// <summary>
/// Network configuration for connecting to the Autonomi network.
/// </summary>
public sealed class Network : NativeHandle
{
    /// <summary>
    /// Gets whether this network is configured for local testnet.
    /// </summary>
    public bool IsLocal { get; }

    internal Network(IntPtr handle, bool isLocal) : base(handle)
    {
        IsLocal = isLocal;
    }

    /// <summary>
    /// Creates a new network configuration.
    /// </summary>
    /// <param name="isLocal">If true, connects to local testnet. If false, connects to production network.</param>
    /// <returns>A new Network instance.</returns>
    public static Network Create(bool isLocal)
    {
        var status = RustCallStatus.Create();
        var handle = NativeMethods.NetworkNew(isLocal ? (sbyte)1 : (sbyte)0, ref status);
        if (status.IsError)
            throw new NetworkException("Failed to create network", status);
        return new Network(handle, isLocal);
    }

    /// <summary>
    /// Creates a custom network configuration with specific RPC URL and contract addresses.
    /// </summary>
    /// <param name="rpcUrl">RPC URL for the EVM network (e.g., "http://10.0.2.2:61611").</param>
    /// <param name="paymentTokenAddress">Payment token contract address (hex string).</param>
    /// <param name="dataPaymentsAddress">Data payments contract address (hex string).</param>
    /// <returns>A new Network instance.</returns>
    public static Network CreateCustom(string rpcUrl, string paymentTokenAddress, string dataPaymentsAddress)
    {
        var rpcUrlBuffer = UniFFIHelpers.StringToRustBuffer(rpcUrl);
        var paymentTokenBuffer = UniFFIHelpers.StringToRustBuffer(paymentTokenAddress);
        var dataPaymentsBuffer = UniFFIHelpers.StringToRustBuffer(dataPaymentsAddress);

        var status = RustCallStatus.Create();
        var handle = NativeMethods.NetworkCustom(rpcUrlBuffer, paymentTokenBuffer, dataPaymentsBuffer, ref status);
        if (status.IsError)
            throw new NetworkException("Failed to create custom network", status);
        return new Network(handle, true);
    }

    /// <inheritdoc/>
    protected override void FreeHandle()
    {
        var status = RustCallStatus.Create();
        NativeMethods.FreeNetwork(Handle, ref status);
    }

    /// <inheritdoc/>
    protected internal override IntPtr CloneHandle()
    {
        var status = RustCallStatus.Create();
        return NativeMethods.CloneNetwork(Handle, ref status);
    }
}
