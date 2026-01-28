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

-- export for other resources
_G.GetCore = GetCore

print('[cz-core] core API module loaded')
