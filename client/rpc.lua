-- Simple client RPC system
-- Exposes `CZ_RPC_CLIENT` global

CZ_RPC_CLIENT = CZ_RPC_CLIENT or {}

local callbacks = {}
local pending = {}
local timeout = (Config and Config.RPC and Config.RPC.timeout) or 10000
local clientRate = {}
local client_rl = (Config and Config.RPC and Config.RPC.rateLimit) or { interval = 1000, maxCalls = 10 }

function CZ_RPC_CLIENT.register(name, fn)
    callbacks[name] = fn
end

function CZ_RPC_CLIENT.triggerServer(name, args, cb)
    -- client-side rate limiting to avoid spamming server
    local now = GetGameTimer()
    local rd = clientRate
    if not rd.window or (now - rd.window >= client_rl.interval) then
        rd.count = 1
        rd.window = now
    else
        rd.count = (rd.count or 0) + 1
    end
    if rd.count > client_rl.maxCalls then
        print(('[cz-core] client-side rate limit reached for RPC %s (count=%d)'):format(tostring(name), rd.count))
        if cb then cb(false, 'rate_limited') end
        return
    end

    local requestId = tostring(math.random(1, 1e9)) .. '-' .. tostring(GetGameTimer())
    if cb then
        pending[requestId] = { cb = cb, ts = GetGameTimer() }
        SetTimeout(timeout, function()
            if pending[requestId] then
                local p = pending[requestId]
                pending[requestId] = nil
                p.cb(false, 'timeout')
            end
        end)
    end
    TriggerServerEvent('cz:rpc:request', name, requestId, args or {})
end

RegisterNetEvent('cz:rpc:response')
AddEventHandler('cz:rpc:response', function(requestId, ok, res)
    local p = pending[requestId]
    if p then
        pending[requestId] = nil
        p.cb(ok, res)
    end
end)

RegisterNetEvent('cz:rpc:clientRequest')
AddEventHandler('cz:rpc:clientRequest', function(name, requestId, args)
    if Config and Config.RPC and next(Config.RPC.allowedClientRPCs) then
        local allowed = false
        for _,v in ipairs(Config.RPC.allowedClientRPCs) do if v == name then allowed = true break end end
        if not allowed then
            print(('[cz-core] blocked client RPC request for %s (not allowed)'):format(tostring(name)))
            TriggerServerEvent('cz:rpc:clientResponse', requestId, false, 'not allowed')
            return
        end
    end
    local handler = callbacks[name]
    if not handler then
        print(('[cz-core] client RPC not found: %s'):format(tostring(name)))
        TriggerServerEvent('cz:rpc:clientResponse', requestId, false, 'rpc not found')
        return
    end
    -- audit and run
    local argCount = (args and #args) or 0
    print(('[cz-core] client RPC call: %s (args=%d)'):format(tostring(name), argCount))

    local ok,res = pcall(handler, table.unpack(args or {}))
    if ok then
        TriggerServerEvent('cz:rpc:clientResponse', requestId, true, res)
    else
        TriggerServerEvent('cz:rpc:clientResponse', requestId, false, tostring(res))
    end
end)

print('[cz-core] client RPC module loaded')
