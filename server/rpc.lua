-- Simple secure-ish RPC system (server side)
-- Exposes `CZ_RPC` global table

CZ_RPC = CZ_RPC or {}

local callbacks = {}
local pending = {}
local timeout = (Config and Config.RPC and Config.RPC.timeout) or 10000
local rateData = {} -- per-player rate tracking
local activeRequests = {}
local rl_config = (Config and Config.RPC and Config.RPC.rateLimit) or { interval = 1000, maxCalls = 10 }

function CZ_RPC.register(name, fn)
    callbacks[name] = fn
    if Config and Config.RPC and Config.RPC.autoAllow then
        Config.RPC.allowedServerRPCs = Config.RPC.allowedServerRPCs or {}
        local found = false
        for _,v in ipairs(Config.RPC.allowedServerRPCs) do if v == name then found = true break end end
        if not found then
            table.insert(Config.RPC.allowedServerRPCs, name)
            print(('Auto-allowed server RPC: %s'):format(tostring(name)))
        end
    end
end

RegisterNetEvent('cz:rpc:request')
AddEventHandler('cz:rpc:request', function(name, requestId, args)
    local src = source
    if type(name) ~= 'string' then
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'invalid name')
        return
    end

    -- rate limiting per player
    local now = GetGameTimer()
    local rd = rateData[src]
    if not rd or (now - (rd.window or 0) >= rl_config.interval) then
        rd = { count = 1, window = now }
    else
        rd.count = rd.count + 1
    end
    rateData[src] = rd
    if rd.count > rl_config.maxCalls then
        print(('Rate-limited RPC from %s: %s (count=%d)'):format(tostring(src), tostring(name), rd.count))
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'rate_limited')
        return
    end

    if Config and Config.RPC and next(Config.RPC.allowedServerRPCs) then
        local allowed = false
        for _,v in ipairs(Config.RPC.allowedServerRPCs) do if v == name then allowed = true break end end
        if not allowed then
            print(('Blocked RPC from %s: %s (not allowed)'):format(tostring(src), tostring(name)))
            TriggerClientEvent('cz:rpc:response', src, requestId, false, 'not allowed')
            return
        end
    end

    local handler = callbacks[name]
    if not handler then
        print(('RPC not found: %s requested by %s'):format(tostring(name), tostring(src)))
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'rpc not found')
        return
    end

    -- audit: log call summary
    local argCount = (args and #args) or 0
    print(('RPC call: %s by %s (args=%d)'):format(tostring(name), tostring(src), argCount))

    -- concurrent active request limiting
    activeRequests[src] = (activeRequests[src] or 0) + 1
    if activeRequests[src] > ((Config and Config.RPC and Config.RPC.maxPending) or 100) then
        activeRequests[src] = activeRequests[src] - 1
        print(('Too many concurrent RPCs from %s'):format(tostring(src)))
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'too_many_concurrent')
        return
    end

    local ok, res = pcall(function()
        return handler(src, table.unpack(args or {}))
    end)
    activeRequests[src] = (activeRequests[src] or 1) - 1
    if not ok then
        TriggerClientEvent('cz:rpc:response', src, requestId, false, tostring(res))
    else
        TriggerClientEvent('cz:rpc:response', src, requestId, true, res)
    end
end)

-- Server -> Client RPC
function CZ_RPC.triggerClient(target, name, args, cb)
    local requestId = tostring(math.random(1, 1e9)) .. '-' .. tostring(GetGameTimer())
    if cb then
        pending[target..':'..requestId] = { cb = cb, ts = GetGameTimer() }
        SetTimeout(timeout, function()
            local key = target..':'..requestId
            if pending[key] then
                local p = pending[key]
                pending[key] = nil
                p.cb(false, 'timeout')
            end
        end)
    end
    TriggerClientEvent('cz:rpc:clientRequest', target, name, requestId, args or {})
end

RegisterNetEvent('cz:rpc:clientResponse')
AddEventHandler('cz:rpc:clientResponse', function(requestId, ok, res)
    local src = source
    local key = src..':'..tostring(requestId)
    local p = pending[key]
    if p then
        pending[key] = nil
        p.cb(ok, res)
    end
end)

-- convenience
function CZ_RPC.registerServer(name, fn) CZ_RPC.register(name, fn) end

print('Server RPC module loaded')

-- Allow other server resources to call registered server RPC handlers directly
function CZ_RPC.call(name, sourceOrNil, ...)
    local handler = callbacks[name]
    if not handler then
        return false, 'rpc not found'
    end
    local src = sourceOrNil or -1
    local args = { ... }
    local ok, res = pcall(function()
        return handler(src, table.unpack(args))
    end)
    if not ok then
        return false, tostring(res)
    end
    return true, res
end
