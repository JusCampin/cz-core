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
        if CZLog and CZLog.warn then CZLog.warn(('Client-side rate limit reached for RPC %s (count=%d)'):format(tostring(name), rd.count)) else print(('Client-side rate limit reached for RPC %s (count=%d)'):format(tostring(name), rd.count)) end
        if cb then cb(false, 'rate_limited') end
        return
    end

    -- sanitize inputs
    if type(name) ~= 'string' then if cb then cb(false, 'invalid_name') end return end
    if args ~= nil and type(args) ~= 'table' then if cb then cb(false, 'invalid_args') end return end

    local maxArgs = (Config and Config.RPC and Config.RPC.maxArgs) or 20
    if args and #args > maxArgs then if cb then cb(false, 'too_many_args') end return end

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
    if type(name) ~= 'string' then
        TriggerServerEvent('cz:rpc:clientResponse', requestId, false, 'invalid_name')
        return
    end
    if args ~= nil and type(args) ~= 'table' then
        TriggerServerEvent('cz:rpc:clientResponse', requestId, false, 'invalid_args')
        return
    end
    if Config and Config.RPC and next(Config.RPC.allowedClientRPCs) then
        local allowed = false
        for _,v in ipairs(Config.RPC.allowedClientRPCs) do if v == name then allowed = true break end end
        if not allowed then
            if CZLog and CZLog.warn then CZLog.warn(('Blocked client RPC request for %s (not allowed)'):format(tostring(name))) else print(('Blocked client RPC request for %s (not allowed)'):format(tostring(name))) end
            TriggerServerEvent('cz:rpc:clientResponse', requestId, false, 'not allowed')
            return
        end
    end
    local handler = callbacks[name]
    if not handler then
        if CZLog and CZLog.warn then CZLog.warn(('Client RPC not found: %s'):format(tostring(name))) else print(('Client RPC not found: %s'):format(tostring(name))) end
        TriggerServerEvent('cz:rpc:clientResponse', requestId, false, 'rpc not found')
        return
    end
    -- audit and run
    local argCount = (args and #args) or 0
    if argCount > ((Config and Config.RPC and Config.RPC.maxArgs) or 20) then
        if CZLog and CZLog.warn then CZLog.warn(('Client RPC call rejected (too many args): %s (args=%d)'):format(tostring(name), argCount)) else print(('Client RPC call rejected (too many args): %s (args=%d)'):format(tostring(name), argCount)) end
        TriggerServerEvent('cz:rpc:clientResponse', requestId, false, 'too_many_args')
        return
    end
    if CZLog and CZLog.info then CZLog.info(('Client RPC call: %s (args=%d)'):format(tostring(name), argCount)) else print(('Client RPC call: %s (args=%d)'):format(tostring(name), argCount)) end

    local ok,res = pcall(handler, table.unpack(args or {}))
    if ok then
        TriggerServerEvent('cz:rpc:clientResponse', requestId, true, res)
    else
        TriggerServerEvent('cz:rpc:clientResponse', requestId, false, tostring(res))
    end
end)

if CZLog and CZLog.info then CZLog.info('Client RPC module loaded') else print('Client RPC module loaded') end
