-- Consumer helper: provides `withCore(cb)` and `Consumer.Log` wrapper
-- Usage:
-- local Consumer = require 'shared.consumer_helper' -- (or just include file)
-- Consumer.withCore(function(core) core.Versioner.checkFile(...) end)

local Consumer = {}

function Consumer.withCore(cb)
    if type(cb) ~= 'function' then return end
    -- prefer CZCore global
    if type(CZCore) == 'table' then
        pcall(cb, CZCore)
        return
    end
    -- otherwise wait for ready and request API
    AddEventHandler('cz-core:ready', function(core)
        pcall(cb, core)
    end)
    TriggerEvent('cz-core:request_api')
end

-- convenience: immediate core access (may be nil)
function Consumer.getCore()
    return (type(CZCore) == 'table') and CZCore or nil
end

-- Lightweight Log wrapper that prefers `CZLog` when available
Consumer.Log = {}
function Consumer.Log.info(msg)
    if CZLog and CZLog.info then CZLog.info(msg) else print(tostring(msg)) end
end
function Consumer.Log.warn(msg)
    if CZLog and CZLog.warn then CZLog.warn(msg) else print(tostring(msg)) end
end
function Consumer.Log.error(msg)
    if CZLog and CZLog.error then CZLog.error(msg) else print(tostring(msg)) end
end

return Consumer
