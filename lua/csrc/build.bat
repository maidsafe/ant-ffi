@echo off
REM Build script for async_helper.dll on Windows
REM
REM Option 1: Using MSVC (Visual Studio)
REM   Open "Developer Command Prompt for VS" and run this script
REM
REM Option 2: Using MinGW/GCC
REM   Ensure gcc is in PATH and run this script

echo Building async_helper.dll...

REM Try MinGW first (more likely to be available)
where gcc >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using MinGW/GCC...
    gcc -shared -O2 -o async_helper.dll async_helper.c
    if %ERRORLEVEL% EQU 0 (
        echo Success! async_helper.dll created.
        copy async_helper.dll ..\ant_ffi\
        echo Copied to ..\ant_ffi\
    ) else (
        echo GCC build failed.
    )
    goto :end
)

REM Try MSVC
where cl >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using MSVC...
    cl /LD /O2 async_helper.c /Fe:async_helper.dll
    if %ERRORLEVEL% EQU 0 (
        echo Success! async_helper.dll created.
        copy async_helper.dll ..\ant_ffi\
        echo Copied to ..\ant_ffi\
    ) else (
        echo MSVC build failed.
    )
    goto :end
)

echo ERROR: No C compiler found.
echo Please install MinGW (gcc) or Visual Studio (cl).

:end
