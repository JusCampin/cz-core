-- Example usage for other resources: getting the core API and waiting for readiness
-- Put this snippet in any server-side file of a resource that depends on cz-core

local function onCoreReady(Core)
    -- Core is the table returned by exports['cz-core']:GetCore()
    -- Example: request a version check for this resource
    Core.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/JusCampin/cz-core')
end

local ok, Core = pcall(function() return exports['cz-core']:GetCore() end)
if ok and Core then
    if Core.waitForReady then
        Core.waitForReady(onCoreReady)
    else
        -- older core fallback: call immediately (or use the ready event)
        onCoreReady(Core)
    end
else
    -- fallback: wait for the event (robust for early startup ordering)
    AddEventHandler('cz-core:ready', function()
        local ok2, Core2 = pcall(function() return exports['cz-core']:GetCore() end)
        if ok2 and Core2 then
            onCoreReady(Core2)
        end
    end)
end
