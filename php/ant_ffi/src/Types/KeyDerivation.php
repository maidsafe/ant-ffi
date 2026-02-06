<?php

declare(strict_types=1);

namespace AntFfi\Types;

use AntFfi\AntFfiException;
use AntFfi\FFILoader;
use AntFfi\NativeHandle;
use AntFfi\RustBuffer;
use FFI;
use FFI\CData;

/**
 * Index for deriving child keys from a master key.
 *
 * DerivationIndex is a 32-byte value used in hierarchical key derivation.
 */
final class DerivationIndex extends NativeHandle
{
    /**
     * Generate a random derivation index.
     */
    public static function random(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_derivationindex_random(
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create a derivation index from 32 bytes.
     *
     * @param string $bytes Exactly 32 bytes
     * @throws AntFfiException if bytes is not exactly 32 bytes
     */
    public static function fromBytes(string $bytes): self
    {
        if (strlen($bytes) !== 32) {
            throw new AntFfiException('DerivationIndex must be exactly 32 bytes, got ' . strlen($bytes));
        }

        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $buffer = RustBuffer::fromStringWithPrefix($bytes);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_derivationindex_from_bytes(
            $buffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Convert to bytes (32 bytes).
     */
    public function toBytes(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_derivationindex_to_bytes(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_derivationindex($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_derivationindex($this->handle, FFI::addr($status));
    }
}

/**
 * BLS Signature (96 bytes).
 */
final class Signature extends NativeHandle
{
    /**
     * Create a signature from raw bytes (96 bytes for BLS signatures).
     *
     * @param string $bytes Exactly 96 bytes
     * @throws AntFfiException if bytes is not exactly 96 bytes
     */
    public static function fromBytes(string $bytes): self
    {
        if (strlen($bytes) !== 96) {
            throw new AntFfiException('Signature must be exactly 96 bytes, got ' . strlen($bytes));
        }

        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $buffer = RustBuffer::fromStringWithPrefix($bytes);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_signature_from_bytes(
            $buffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Convert to bytes (96 bytes).
     */
    public function toBytes(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_signature_to_bytes(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Returns true if the signature contains an odd number of ones (parity bit).
     */
    public function parity(): bool
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $result = $ffi->uniffi_ant_ffi_fn_method_signature_parity(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return $result !== 0;
    }

    /**
     * Convert to hex string.
     */
    public function toHex(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_signature_to_hex(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_signature($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_signature($this->handle, FFI::addr($status));
    }
}

/**
 * Master secret key for hierarchical key derivation.
 * Can be used to derive multiple child keys.
 */
final class MainSecretKey extends NativeHandle
{
    /**
     * Create a MainSecretKey from a SecretKey.
     */
    public static function fromSecretKey(SecretKey $secretKey): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_mainsecretkey_new(
            $secretKey->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Generate a random MainSecretKey.
     */
    public static function random(): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_mainsecretkey_random(
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the corresponding MainPubkey.
     */
    public function publicKey(): MainPubkey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_mainsecretkey_public_key(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new MainPubkey($handle);
    }

    /**
     * Sign a message with this secret key.
     */
    public function sign(string $message): Signature
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $msgBuffer = RustBuffer::fromStringWithPrefix($message);
        $handle = $ffi->uniffi_ant_ffi_fn_method_mainsecretkey_sign(
            $this->cloneForCall(),
            $msgBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new Signature($handle);
    }

    /**
     * Derive a DerivedSecretKey from this master key using the given index.
     */
    public function deriveKey(DerivationIndex $index): DerivedSecretKey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_mainsecretkey_derive_key(
            $this->cloneForCall(),
            $index->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new DerivedSecretKey($handle);
    }

    /**
     * Generate a new random DerivedSecretKey from this master key.
     */
    public function randomDerivedKey(): DerivedSecretKey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_mainsecretkey_random_derived_key(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new DerivedSecretKey($handle);
    }

    /**
     * Get the raw bytes of the secret key.
     */
    public function toBytes(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_mainsecretkey_to_bytes(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_mainsecretkey($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_mainsecretkey($this->handle, FFI::addr($status));
    }
}

/**
 * Master public key for hierarchical key derivation.
 */
final class MainPubkey extends NativeHandle
{
    /**
     * @internal Create from a raw handle.
     */
    public function __construct(CData $handle)
    {
        parent::__construct($handle);
    }

    /**
     * Create a MainPubkey from a PublicKey.
     */
    public static function fromPublicKey(PublicKey $publicKey): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_mainpubkey_new(
            $publicKey->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create from a hex string.
     */
    public static function fromHex(string $hex): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $hexBuffer = RustBuffer::fromString($hex);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_mainpubkey_from_hex(
            $hexBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Verify that a signature is valid for the given message.
     */
    public function verify(Signature $signature, string $message): bool
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $msgBuffer = RustBuffer::fromStringWithPrefix($message);
        $result = $ffi->uniffi_ant_ffi_fn_method_mainpubkey_verify(
            $this->cloneForCall(),
            $signature->cloneForCall(),
            $msgBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return $result !== 0;
    }

    /**
     * Derive a DerivedPubkey from this master public key using the given index.
     */
    public function deriveKey(DerivationIndex $index): DerivedPubkey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_mainpubkey_derive_key(
            $this->cloneForCall(),
            $index->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new DerivedPubkey($handle);
    }

    /**
     * Get the bytes representation.
     */
    public function toBytes(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_mainpubkey_to_bytes(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Convert to hex string.
     */
    public function toHex(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_mainpubkey_to_hex(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_mainpubkey($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_mainpubkey($this->handle, FFI::addr($status));
    }
}

/**
 * Derived secret key from hierarchical key derivation.
 */
final class DerivedSecretKey extends NativeHandle
{
    /**
     * @internal Create from a raw handle.
     */
    public function __construct(CData $handle)
    {
        parent::__construct($handle);
    }

    /**
     * Create a DerivedSecretKey from a SecretKey.
     */
    public static function fromSecretKey(SecretKey $secretKey): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_derivedsecretkey_new(
            $secretKey->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Get the corresponding DerivedPubkey.
     */
    public function publicKey(): DerivedPubkey
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_method_derivedsecretkey_public_key(
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new DerivedPubkey($handle);
    }

    /**
     * Sign a message with this derived secret key.
     */
    public function sign(string $message): Signature
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $msgBuffer = RustBuffer::fromStringWithPrefix($message);
        $handle = $ffi->uniffi_ant_ffi_fn_method_derivedsecretkey_sign(
            $this->cloneForCall(),
            $msgBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new Signature($handle);
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_derivedsecretkey($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_derivedsecretkey($this->handle, FFI::addr($status));
    }
}

/**
 * Derived public key from hierarchical key derivation.
 */
final class DerivedPubkey extends NativeHandle
{
    /**
     * @internal Create from a raw handle.
     */
    public function __construct(CData $handle)
    {
        parent::__construct($handle);
    }

    /**
     * Create a DerivedPubkey from a PublicKey.
     */
    public static function fromPublicKey(PublicKey $publicKey): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $handle = $ffi->uniffi_ant_ffi_fn_constructor_derivedpubkey_new(
            $publicKey->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Create from a hex string.
     */
    public static function fromHex(string $hex): self
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $hexBuffer = RustBuffer::fromString($hex);
        $handle = $ffi->uniffi_ant_ffi_fn_constructor_derivedpubkey_from_hex(
            $hexBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return new self($handle);
    }

    /**
     * Verify that a signature is valid for the given message.
     */
    public function verify(Signature $signature, string $message): bool
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');

        $msgBuffer = RustBuffer::fromStringWithPrefix($message);
        $result = $ffi->uniffi_ant_ffi_fn_method_derivedpubkey_verify(
            $this->cloneForCall(),
            $signature->cloneForCall(),
            $msgBuffer,
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        return $result !== 0;
    }

    /**
     * Get the bytes representation.
     */
    public function toBytes(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_derivedpubkey_to_bytes(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    /**
     * Convert to hex string.
     */
    public function toHex(): string
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $resultBuffer = $ffi->new('RustBuffer');

        $ffi->uniffi_ant_ffi_fn_method_derivedpubkey_to_hex(
            FFI::addr($resultBuffer),
            $this->cloneForCall(),
            FFI::addr($status)
        );

        RustBuffer::checkStatus($status);

        $result = RustBuffer::toString($resultBuffer);
        RustBuffer::free($resultBuffer);

        return $result;
    }

    protected function freeHandle(): void
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        $ffi->uniffi_ant_ffi_fn_free_derivedpubkey($this->handle, FFI::addr($status));
    }

    protected function cloneHandle(): CData
    {
        $ffi = FFILoader::get();
        $status = $ffi->new('RustCallStatus');
        return $ffi->uniffi_ant_ffi_fn_clone_derivedpubkey($this->handle, FFI::addr($status));
    }
}
