-- Core API helpers (GetCore, readiness, RPC wrapper)

local CzCoreRPC = {}

local core_ready = false
AddEventHandler('cz-core:ready', function()
    core_ready = true
end)

local versioner_impl = nil

-- Internal registration helper for the versioner module
_G.__cz_core_register_versioner = function(t)
    versioner_impl = t
    _G.__cz_core_register_versioner = nil
end

local function waitForReady(cb)
    if type(cb) ~= 'function' then return end
    if core_ready then
        cb(GetCore())
        return
    end
    AddEventHandler('cz-core:ready', function()
        cb(GetCore())
    end)
end

local function withCore(cb)
    if type(cb) ~= 'function' then return end
    if type(CZCore) == 'table' then
        pcall(cb, CZCore)
        return
    end
    waitForReady(function(core) pcall(cb, core) end)
end

local function versioner_checkFile(resName, repoOrUrl, cb)
    if versioner_impl and versioner_impl.checkFile then
        return versioner_impl.checkFile(resName, repoOrUrl, cb)
    end
    if cb then cb(false, nil, 'versioner not loaded') end
    return false, 'versioner not loaded'
end

function CzCoreRPC.call(name, sourceOrNil, ...)
    if CZ_RPC and CZ_RPC.call then
        return CZ_RPC.call(name, sourceOrNil, ...)
    elseif CZ_RPC and CZ_RPC.triggerClient then
        return false, 'direct server call not supported on this build'
    end
    return false, 'CZ_RPC not available'
end

function GetCore()
    return { RPC = { raw = CZ_RPC, call = CzCoreRPC.call }, Versioner = { checkFile = versioner_checkFile }, waitForReady = waitForReady }
end

if CZLog and CZLog.info then CZLog.info('Core API module loaded') else print('Core API module loaded') end

-- expose as a safe global for consumers that prefer direct access
-- expose both a non-_G global and an _G entry for backward compatibility
CZCore = CZCore or GetCore()
_G.CZCore = _G.CZCore or CZCore

-- attach helper onto global for consumers
CZCore.withCore = CZCore.withCore or withCore

-- ensure we broadcast readiness and refresh the global when core reloads
TriggerEvent('cz-core:ready', CZCore)

-- Respond to explicit API requests from other resources.
-- Consumers can register a `cz-core:ready` handler then trigger `cz-core:request_api`.
AddEventHandler('cz-core:request_api', function()
    TriggerEvent('cz-core:ready', GetCore())
end)
