<?php

declare(strict_types=1);

namespace AntFfi;

use FFI\CData;

/**
 * Base class for types that wrap a native handle.
 */
abstract class NativeHandle
{
    protected CData $handle;
    protected bool $disposed = false;

    protected function __construct(CData $handle)
    {
        $this->handle = $handle;
    }

    /**
     * Free the native handle.
     */
    abstract protected function freeHandle(): void;

    /**
     * Clone the native handle (for Arc reference counting).
     */
    abstract protected function cloneHandle(): CData;

    /**
     * Get the raw handle.
     *
     * @throws AntFfiException if the object has been disposed
     */
    public function getHandle(): CData
    {
        if ($this->disposed) {
            throw new AntFfiException('Object has been disposed');
        }
        return $this->handle;
    }

    /**
     * Clone handle for passing to FFI calls.
     * This is needed because UniFFI uses Arc<T> and consumes the reference.
     */
    public function cloneForCall(): CData
    {
        if ($this->disposed) {
            throw new AntFfiException('Object has been disposed');
        }
        return $this->cloneHandle();
    }

    /**
     * Dispose the object, freeing the native handle.
     */
    public function dispose(): void
    {
        if (!$this->disposed) {
            $this->freeHandle();
            $this->disposed = true;
        }
    }

    /**
     * Check if the object has been disposed.
     */
    public function isDisposed(): bool
    {
        return $this->disposed;
    }

    /**
     * Destructor - automatically dispose.
     */
    public function __destruct()
    {
        $this->dispose();
    }
}
