-- client-side core API shim

local function waitForReady(cb)
    if type(cb) ~= 'function' then return end
    if CZCore then cb(CZCore); return end
    AddEventHandler('cz-core:ready', function(core)
        cb(core)
    end)
end

local function withCore(cb)
    if type(cb) ~= 'function' then return end
    if type(CZCore) == 'table' then
        pcall(cb, CZCore)
        return
    end
    AddEventHandler('cz-core:ready', function(core) pcall(cb, core) end)
    TriggerEvent('cz-core:request_api')
end

local function GetCore()
    local rpc = CZ_RPC_CLIENT or {}
    return { RPC = { client = rpc }, waitForReady = waitForReady }
end

-- expose global for convenience
CZCore = CZCore or GetCore()

-- attach helper for consumers
CZCore.withCore = CZCore.withCore or withCore

-- announce to local consumers
TriggerEvent('cz-core:ready', GetCore())

-- respond to explicit API requests
AddEventHandler('cz-core:request_api', function()
    TriggerEvent('cz-core:ready', GetCore())
end)

print('Client Core API module loaded')
