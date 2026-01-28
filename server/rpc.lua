-- Simple secure-ish RPC system (server side)
-- Exposes `CZ_RPC` global table

CZ_RPC = CZ_RPC or {}

local callbacks = {}
local callbacks_meta = {}
local pending = {}
local timeout = (Config and Config.RPC and Config.RPC.timeout) or 10000
local rateData = {} -- per-player rate tracking
local activeRequests = {}
local rl_config = (Config and Config.RPC and Config.RPC.rateLimit) or { interval = 1000, maxCalls = 10 }

function CZ_RPC.register(name, fn, opts)
    callbacks[name] = fn
    callbacks_meta[name] = opts or {}
    if Config and Config.RPC and Config.RPC.autoAllow then
        Config.RPC.allowedServerRPCs = Config.RPC.allowedServerRPCs or {}
        local found = false
        for _,v in ipairs(Config.RPC.allowedServerRPCs) do if v == name then found = true break end end
        if not found then
                table.insert(Config.RPC.allowedServerRPCs, name)
                if CZLog and CZLog.info then CZLog.info(('Auto-allowed server RPC: %s'):format(tostring(name))) else print(('Auto-allowed server RPC: %s'):format(tostring(name))) end
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
    if type(requestId) ~= 'string' and type(requestId) ~= 'number' then
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'invalid request id')
        return
    end
    if args ~= nil and type(args) ~= 'table' then
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'invalid args')
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
        if CZLog and CZLog.warn then CZLog.warn(('Rate-limited RPC from %s: %s (count=%d)'):format(tostring(src), tostring(name), rd.count)) else print(('Rate-limited RPC from %s: %s (count=%d)'):format(tostring(src), tostring(name), rd.count)) end
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'rate_limited')
        return
    end

    if Config and Config.RPC and next(Config.RPC.allowedServerRPCs) then
        local allowed = false
        for _,v in ipairs(Config.RPC.allowedServerRPCs) do if v == name then allowed = true break end end
        if not allowed then
            if CZLog and CZLog.warn then CZLog.warn(('Blocked RPC from %s: %s (not allowed)'):format(tostring(src), tostring(name))) else print(('Blocked RPC from %s: %s (not allowed)'):format(tostring(src), tostring(name))) end
            TriggerClientEvent('cz:rpc:response', src, requestId, false, 'not allowed')
            return
        end
    end

    -- permission check via registration metadata or Config hook
    local meta = callbacks_meta[name] or {}
    if meta and meta.requiredPermission then
        local okPerm = false
        if Config and Config.RPC and type(Config.RPC.checkServerPermission) == 'function' then
            okPerm = Config.RPC.checkServerPermission(src, meta.requiredPermission)
        elseif type(meta.requiredPermission) == 'string' and type(IsPlayerAceAllowed) == 'function' then
            okPerm = IsPlayerAceAllowed(src, meta.requiredPermission)
        end
        if not okPerm then
            if CZLog and CZLog.warn then CZLog.warn(('Blocked RPC by permission from %s: %s'):format(tostring(src), tostring(name))) else print(('Blocked RPC by permission from %s: %s'):format(tostring(src), tostring(name))) end
            TriggerClientEvent('cz:rpc:response', src, requestId, false, 'no_permission')
            return
        end
    end

    -- argument limits
    local maxArgs = (Config and Config.RPC and Config.RPC.maxArgs) or 20
    if args and #args > maxArgs then
        if CZLog and CZLog.warn then CZLog.warn(('RPC %s called by %s rejected: too many args (%d > %d)'):format(tostring(name), tostring(src), #args, maxArgs)) else print(('RPC %s called by %s rejected: too many args (%d > %d)'):format(tostring(name), tostring(src), #args, maxArgs)) end
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'too_many_args')
        return
    end

    local handler = callbacks[name]
    if not handler then
        if CZLog and CZLog.warn then CZLog.warn(('RPC not found: %s requested by %s'):format(tostring(name), tostring(src))) else print(('RPC not found: %s requested by %s'):format(tostring(name), tostring(src))) end
        TriggerClientEvent('cz:rpc:response', src, requestId, false, 'rpc not found')
        return
    end

    -- audit: log call summary
    local argCount = (args and #args) or 0
    if CZLog and CZLog.info then CZLog.info(('RPC call: %s by %s (args=%d)'):format(tostring(name), tostring(src), argCount)) else print(('RPC call: %s by %s (args=%d)'):format(tostring(name), tostring(src), argCount)) end

    -- concurrent active request limiting
    activeRequests[src] = (activeRequests[src] or 0) + 1
    if activeRequests[src] > ((Config and Config.RPC and Config.RPC.maxPending) or 100) then
        activeRequests[src] = activeRequests[src] - 1
        if CZLog and CZLog.warn then CZLog.warn(('Too many concurrent RPCs from %s'):format(tostring(src))) else print(('Too many concurrent RPCs from %s'):format(tostring(src))) end
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

if CZLog and CZLog.info then CZLog.info('Server RPC module loaded') else print('Server RPC module loaded') end

-- Allow other server resources to call registered server RPC handlers directly
function CZ_RPC.call(name, sourceOrNil, ...)
    local handler = callbacks[name]
    if not handler then
        return false, 'rpc not found'
    end
    local src = sourceOrNil or -1
    -- enforce permission checks for direct server calls as well
    local meta = callbacks_meta[name] or {}
    if meta and meta.requiredPermission and src ~= -1 then
        local okPerm = false
        if Config and Config.RPC and type(Config.RPC.checkServerPermission) == 'function' then
            okPerm = Config.RPC.checkServerPermission(src, meta.requiredPermission)
        elseif type(meta.requiredPermission) == 'string' and type(IsPlayerAceAllowed) == 'function' then
            okPerm = IsPlayerAceAllowed(src, meta.requiredPermission)
        end
        if not okPerm then
            return false, 'no_permission'
        end
    end
    local args = { ... }
    local ok, res = pcall(function()
        return handler(src, table.unpack(args))
    end)
    if not ok then
        return false, tostring(res)
    end
    return true, res
end
