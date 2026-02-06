--[[
  Native library loading for ant_ffi

  This module handles loading the native ant_ffi library
  across different platforms (Windows, macOS, Linux).
]]

local ffi = require("ffi")

-- Load FFI definitions
require("ant_ffi.ffi_defs")

local M = {}

-- Determine library name based on platform
local function get_lib_name()
    if ffi.os == "Windows" then
        return "ant_ffi"  -- Windows uses ant_ffi.dll
    elseif ffi.os == "OSX" then
        return "libant_ffi"  -- macOS uses libant_ffi.dylib
    else
        return "libant_ffi"  -- Linux uses libant_ffi.so
    end
end

-- Get library extension based on platform
local function get_lib_ext()
    if ffi.os == "Windows" then
        return ".dll"
    elseif ffi.os == "OSX" then
        return ".dylib"
    else
        return ".so"
    end
end

-- Try to load the library from various paths
local function load_library()
    local lib_name = get_lib_name()
    local lib_ext = get_lib_ext()

    -- Try these paths in order
    local search_paths = {
        -- Direct name (system library path)
        lib_name,
        -- In ant_ffi subdirectory (recommended location)
        "./ant_ffi/" .. lib_name .. lib_ext,
        -- Current directory
        "./" .. lib_name .. lib_ext,
        -- Relative to rust build output
        "../rust/target/release/" .. lib_name .. lib_ext,
        "../../rust/target/release/" .. lib_name .. lib_ext,
        -- Common installation paths
        "/usr/local/lib/" .. lib_name .. lib_ext,
        "/usr/lib/" .. lib_name .. lib_ext,
    }

    -- On Windows, also try without explicit extension
    if ffi.os == "Windows" then
        table.insert(search_paths, 2, "./ant_ffi/" .. lib_name)
        table.insert(search_paths, 3, "./" .. lib_name)
        table.insert(search_paths, 4, "../rust/target/release/" .. lib_name)
    end

    local errors = {}
    for _, path in ipairs(search_paths) do
        local ok, lib = pcall(ffi.load, path)
        if ok then
            return lib
        else
            table.insert(errors, string.format("  %s: %s", path, lib))
        end
    end

    -- No library found - provide helpful error message
    error(string.format(
        "Could not load ant_ffi library. Tried the following paths:\n%s\n\n" ..
        "Make sure the native library is built and accessible.\n" ..
        "Build with: cd rust && cargo build --release",
        table.concat(errors, "\n")
    ))
end

-- Load the library once on module load
M.lib = load_library()

-- Export platform info
M.os = ffi.os
M.arch = ffi.arch

return M
