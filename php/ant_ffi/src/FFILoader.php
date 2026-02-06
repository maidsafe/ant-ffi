<?php

declare(strict_types=1);

namespace AntFfi;

use FFI;

/**
 * Loads the ant_ffi native library.
 */
final class FFILoader
{
    private static ?FFI $ffi = null;

    /**
     * Get the FFI instance, loading it if necessary.
     */
    public static function get(): FFI
    {
        if (self::$ffi === null) {
            self::$ffi = self::load();
        }
        return self::$ffi;
    }

    /**
     * Load the native library.
     */
    private static function load(): FFI
    {
        $headerPath = __DIR__ . '/../ffi/ant_ffi.h';

        if (!file_exists($headerPath)) {
            throw new AntFfiException("FFI header not found at: $headerPath");
        }

        // Determine library name based on OS
        if (PHP_OS_FAMILY === 'Windows') {
            $libName = 'ant_ffi.dll';
        } elseif (PHP_OS_FAMILY === 'Darwin') {
            $libName = 'libant_ffi.dylib';
        } else {
            $libName = 'libant_ffi.so';
        }

        // Try to load from common locations
        $searchPaths = [
            __DIR__ . '/../ffi/',
            __DIR__ . '/../',
            __DIR__ . '/../../',
            __DIR__ . '/../../rust/target/release/',
            getenv('ANT_FFI_LIB_PATH') ?: '',
        ];

        foreach ($searchPaths as $path) {
            if (empty($path)) {
                continue;
            }
            $fullPath = rtrim($path, '/\\') . DIRECTORY_SEPARATOR . $libName;
            if (file_exists($fullPath)) {
                return FFI::cdef(
                    file_get_contents($headerPath),
                    $fullPath
                );
            }
        }

        // Fall back to system library path
        try {
            return FFI::cdef(
                file_get_contents($headerPath),
                $libName
            );
        } catch (\FFI\Exception $e) {
            throw new AntFfiException(
                "Failed to load native library '$libName'. " .
                "Set ANT_FFI_LIB_PATH environment variable or place the library in the package directory. " .
                "Original error: " . $e->getMessage()
            );
        }
    }
}
