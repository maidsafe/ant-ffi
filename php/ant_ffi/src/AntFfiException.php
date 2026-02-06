<?php

declare(strict_types=1);

namespace AntFfi;

use Exception;

/**
 * Exception thrown when an FFI operation fails.
 */
class AntFfiException extends Exception
{
    private int $ffiCode;

    public function __construct(string $message, int $ffiCode = 0)
    {
        parent::__construct($message);
        $this->ffiCode = $ffiCode;
    }

    /**
     * Get the FFI error code.
     */
    public function getFfiCode(): int
    {
        return $this->ffiCode;
    }
}
