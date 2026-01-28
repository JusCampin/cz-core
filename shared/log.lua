-- Simple structured logger for CoreZ
CZLog = CZLog or {}

local function format_msg(level, msg)
    local colors = {
        info = '^2',
        warn = '^3',
        error = '^1',
        debug = '^5'
    }
    local color = colors[level] or '^7'
    local prefix = ('[%s] '):format(tostring(level):upper())
    return ("%s%s^0"):format(color, prefix .. tostring(msg))
end

function CZLog.info(msg)
    print(format_msg('info', msg))
end

function CZLog.warn(msg)
    print(format_msg('warn', msg))
end

function CZLog.error(msg)
    print(format_msg('error', msg))
end

function CZLog.debug(msg)
    print(format_msg('debug', msg))
end

return CZLog
