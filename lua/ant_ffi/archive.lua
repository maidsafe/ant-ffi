--[[
  Archive types for ant_ffi

  This module provides archive types for file collections:
  - Metadata: File metadata (size, timestamps)
  - ArchiveAddress: Address for public archives
  - PrivateArchiveDataMap: Data map for private archives
  - PublicArchive: Collection of public files
  - PrivateArchive: Collection of private (encrypted) files
]]

local ffi = require("ffi")

local M = {}

M._lib = nil
M._helpers = nil
M._errors = nil

function M._init(lib, helpers, errors)
    M._lib = lib
    M._helpers = helpers
    M._errors = errors
end

-- =============================================================================
-- Metadata
-- =============================================================================

local Metadata = {}
Metadata.__index = Metadata

function Metadata._wrap(handle)
    local self = setmetatable({}, Metadata)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_metadata(h, status)
        end
    end)
    return self
end

function Metadata.new(size)
    assert(M._lib, "archive not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_metadata_new(size, status)
    M._errors.check_status(status, "Metadata.new")
    return Metadata._wrap(handle)
end

function Metadata.with_timestamps(size, created, modified)
    assert(M._lib, "archive not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_metadata_with_timestamps(size, created, modified, status)
    M._errors.check_status(status, "Metadata.with_timestamps")
    return Metadata._wrap(handle)
end

function Metadata:_clone()
    assert(not self._disposed, "Metadata has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_metadata(self._handle, status)
    M._errors.check_status(status, "Metadata.clone")
    return cloned
end

function Metadata:size()
    assert(not self._disposed, "Metadata has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_metadata_size(self:_clone(), status)
    M._errors.check_status(status, "Metadata.size")
    return tonumber(result)
end

function Metadata:created()
    assert(not self._disposed, "Metadata has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_metadata_created(self:_clone(), status)
    M._errors.check_status(status, "Metadata.created")
    return tonumber(result)
end

function Metadata:modified()
    assert(not self._disposed, "Metadata has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_metadata_modified(self:_clone(), status)
    M._errors.check_status(status, "Metadata.modified")
    return tonumber(result)
end

function Metadata:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_metadata(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.Metadata = Metadata

-- =============================================================================
-- ArchiveAddress
-- =============================================================================

local ArchiveAddress = {}
ArchiveAddress.__index = ArchiveAddress

function ArchiveAddress._wrap(handle)
    local self = setmetatable({}, ArchiveAddress)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_archiveaddress(h, status)
        end
    end)
    return self
end

function ArchiveAddress.from_hex(hex)
    assert(M._lib, "archive not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_archiveaddress_from_hex(buf, status)
    M._errors.check_status(status, "ArchiveAddress.from_hex")
    return ArchiveAddress._wrap(handle)
end

function ArchiveAddress:_clone()
    assert(not self._disposed, "ArchiveAddress has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_archiveaddress(self._handle, status)
    M._errors.check_status(status, "ArchiveAddress.clone")
    return cloned
end

function ArchiveAddress:to_hex()
    assert(not self._disposed, "ArchiveAddress has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_archiveaddress_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "ArchiveAddress.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function ArchiveAddress:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_archiveaddress(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.ArchiveAddress = ArchiveAddress

-- =============================================================================
-- PrivateArchiveDataMap
-- =============================================================================

local PrivateArchiveDataMap = {}
PrivateArchiveDataMap.__index = PrivateArchiveDataMap

function PrivateArchiveDataMap._wrap(handle)
    local self = setmetatable({}, PrivateArchiveDataMap)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_privatearchivedatamap(h, status)
        end
    end)
    return self
end

function PrivateArchiveDataMap.from_hex(hex)
    assert(M._lib, "archive not initialized")
    local buf = M._helpers.raw_string_to_rustbuffer(hex)
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_privatearchivedatamap_from_hex(buf, status)
    M._errors.check_status(status, "PrivateArchiveDataMap.from_hex")
    return PrivateArchiveDataMap._wrap(handle)
end

function PrivateArchiveDataMap:_clone()
    assert(not self._disposed, "PrivateArchiveDataMap has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_privatearchivedatamap(self._handle, status)
    M._errors.check_status(status, "PrivateArchiveDataMap.clone")
    return cloned
end

function PrivateArchiveDataMap:to_hex()
    assert(not self._disposed, "PrivateArchiveDataMap has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_privatearchivedatamap_to_hex(result, self:_clone(), status)
    M._errors.check_status(status, "PrivateArchiveDataMap.to_hex")
    return M._helpers.rustbuffer_to_raw_string(result[0])
end

function PrivateArchiveDataMap:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_privatearchivedatamap(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.PrivateArchiveDataMap = PrivateArchiveDataMap

-- =============================================================================
-- PublicArchive
-- =============================================================================

local PublicArchive = {}
PublicArchive.__index = PublicArchive

function PublicArchive._wrap(handle)
    local self = setmetatable({}, PublicArchive)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_publicarchive(h, status)
        end
    end)
    return self
end

function PublicArchive.new()
    assert(M._lib, "archive not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_publicarchive_new(status)
    M._errors.check_status(status, "PublicArchive.new")
    return PublicArchive._wrap(handle)
end

function PublicArchive:_clone()
    assert(not self._disposed, "PublicArchive has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_publicarchive(self._handle, status)
    M._errors.check_status(status, "PublicArchive.clone")
    return cloned
end

function PublicArchive:add_file(path, address, metadata)
    assert(not self._disposed, "PublicArchive has been disposed")
    local path_buf = M._helpers.string_to_rustbuffer(path)
    local status = M._errors.new_status()
    local new_handle = M._lib.uniffi_ant_ffi_fn_method_publicarchive_add_file(
        self:_clone(), path_buf, address:_clone(), metadata:_clone(), status)
    M._errors.check_status(status, "PublicArchive.add_file")
    return PublicArchive._wrap(new_handle)
end

function PublicArchive:rename_file(old_path, new_path)
    assert(not self._disposed, "PublicArchive has been disposed")
    local old_buf = M._helpers.string_to_rustbuffer(old_path)
    local new_buf = M._helpers.string_to_rustbuffer(new_path)
    local status = M._errors.new_status()
    local new_handle = M._lib.uniffi_ant_ffi_fn_method_publicarchive_rename_file(
        self:_clone(), old_buf, new_buf, status)
    M._errors.check_status(status, "PublicArchive.rename_file")
    return PublicArchive._wrap(new_handle)
end

function PublicArchive:files()
    assert(not self._disposed, "PublicArchive has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_publicarchive_files(result, self:_clone(), status)
    M._errors.check_status(status, "PublicArchive.files")
    return M._helpers.rustbuffer_to_string(result[0])
end

function PublicArchive:file_count()
    assert(not self._disposed, "PublicArchive has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_publicarchive_file_count(self:_clone(), status)
    M._errors.check_status(status, "PublicArchive.file_count")
    return tonumber(result)
end

function PublicArchive:addresses()
    assert(not self._disposed, "PublicArchive has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_publicarchive_addresses(result, self:_clone(), status)
    M._errors.check_status(status, "PublicArchive.addresses")
    return M._helpers.rustbuffer_to_string(result[0])
end

function PublicArchive:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_publicarchive(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.PublicArchive = PublicArchive

-- =============================================================================
-- PrivateArchive
-- =============================================================================

local PrivateArchive = {}
PrivateArchive.__index = PrivateArchive

function PrivateArchive._wrap(handle)
    local self = setmetatable({}, PrivateArchive)
    self._disposed = false
    self._handle = ffi.gc(handle, function(h)
        if h ~= nil then
            local status = ffi.new("RustCallStatus")
            M._lib.uniffi_ant_ffi_fn_free_privatearchive(h, status)
        end
    end)
    return self
end

function PrivateArchive.new()
    assert(M._lib, "archive not initialized")
    local status = M._errors.new_status()
    local handle = M._lib.uniffi_ant_ffi_fn_constructor_privatearchive_new(status)
    M._errors.check_status(status, "PrivateArchive.new")
    return PrivateArchive._wrap(handle)
end

function PrivateArchive:_clone()
    assert(not self._disposed, "PrivateArchive has been disposed")
    local status = M._errors.new_status()
    local cloned = M._lib.uniffi_ant_ffi_fn_clone_privatearchive(self._handle, status)
    M._errors.check_status(status, "PrivateArchive.clone")
    return cloned
end

function PrivateArchive:add_file(path, data_map, metadata)
    assert(not self._disposed, "PrivateArchive has been disposed")
    local path_buf = M._helpers.string_to_rustbuffer(path)
    local status = M._errors.new_status()
    local new_handle = M._lib.uniffi_ant_ffi_fn_method_privatearchive_add_file(
        self:_clone(), path_buf, data_map:_clone(), metadata:_clone(), status)
    M._errors.check_status(status, "PrivateArchive.add_file")
    return PrivateArchive._wrap(new_handle)
end

function PrivateArchive:rename_file(old_path, new_path)
    assert(not self._disposed, "PrivateArchive has been disposed")
    local old_buf = M._helpers.string_to_rustbuffer(old_path)
    local new_buf = M._helpers.string_to_rustbuffer(new_path)
    local status = M._errors.new_status()
    local new_handle = M._lib.uniffi_ant_ffi_fn_method_privatearchive_rename_file(
        self:_clone(), old_buf, new_buf, status)
    M._errors.check_status(status, "PrivateArchive.rename_file")
    return PrivateArchive._wrap(new_handle)
end

function PrivateArchive:files()
    assert(not self._disposed, "PrivateArchive has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_privatearchive_files(result, self:_clone(), status)
    M._errors.check_status(status, "PrivateArchive.files")
    return M._helpers.rustbuffer_to_string(result[0])
end

function PrivateArchive:file_count()
    assert(not self._disposed, "PrivateArchive has been disposed")
    local status = M._errors.new_status()
    local result = M._lib.uniffi_ant_ffi_fn_method_privatearchive_file_count(self:_clone(), status)
    M._errors.check_status(status, "PrivateArchive.file_count")
    return tonumber(result)
end

function PrivateArchive:data_maps()
    assert(not self._disposed, "PrivateArchive has been disposed")
    local status = M._errors.new_status()
    local result = ffi.new("RustBuffer[1]")
    M._lib.uniffi_ant_ffi_fn_method_privatearchive_data_maps(result, self:_clone(), status)
    M._errors.check_status(status, "PrivateArchive.data_maps")
    return M._helpers.rustbuffer_to_string(result[0])
end

function PrivateArchive:dispose()
    if not self._disposed and self._handle ~= nil then
        ffi.gc(self._handle, nil)
        local status = ffi.new("RustCallStatus")
        M._lib.uniffi_ant_ffi_fn_free_privatearchive(self._handle, status)
        self._handle = nil
        self._disposed = true
    end
end

M.PrivateArchive = PrivateArchive

return M
