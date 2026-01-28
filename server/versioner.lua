-- read GitHub token from server-only config or server convar to avoid committing secrets
local github_token = nil
do
    local cfg_token = (Config and Config.Versioner and Config.Versioner.github_token) or nil
    local convar_token = nil
    if type(GetConvar) == 'function' then
        convar_token = GetConvar('cz_core_github_token', '')
    end
    local chosen = cfg_token or (convar_token ~= '' and convar_token) or nil
    github_token = chosen and tostring(chosen) or nil
end

local function split_numbers(s)
    local t = {}
    for part in tostring(s):gmatch("([0-9]+)") do
        table.insert(t, tonumber(part))
    end
    return t
end

local function compare_versions(a, b)
    if not a or not b then return 0 end
    a = tostring(a):gsub("^v", "")
    b = tostring(b):gsub("^v", "")
    local ta = split_numbers(a)
    local tb = split_numbers(b)
    local n = math.max(#ta, #tb)
    for i = 1, n do
        local va = ta[i] or 0
        local vb = tb[i] or 0
        if va < vb then return -1 end
        if va > vb then return 1 end
    end
    return 0
end

local function build_headers()
    local headers = { ['User-Agent'] = 'CoreZ-Version-Checker', ['Accept'] = 'application/vnd.github.v3+json' }
    if github_token and github_token ~= '' then
        headers["Authorization"] = ('token %s'):format(github_token)
    end
    return headers
end

-- simple in-memory cache for remote version responses (keyed by url)
local version_cache = {}
local function log(level, msg)
    if not level or not msg then return end
    if CZLog and type(CZLog[level]) == 'function' then
        pcall(CZLog[level], ('%s'):format(tostring(msg)))
    else
        print(('[versioner] %s: %s'):format(tostring(level):upper(), tostring(msg)))
    end
end

local function cache_get(key)
    if not key then return nil end
    local entry = version_cache[key]
    if not entry then return nil end
    local now = os.time()
    local ttl = (Config and Config.Versioner and Config.Versioner.cache_ttl) or 300
    if now - (entry.ts or 0) > ttl then
        version_cache[key] = nil
        return nil
    end
    return entry.data
end
local function cache_set(key, data)
    if not key then return end
    version_cache[key] = { ts = os.time(), data = data }
end

-- HTTP GET with retries and exponential backoff
local function http_get_with_retries(url, cb)
    if not url then if cb then cb(nil, nil, 'empty url') end return end
    local cfg = (Config and Config.Versioner) or { retry = { attempts = 2, backoff = 2000 } }
    local attempts = (cfg.retry and cfg.retry.attempts) or 2
    local backoff = (cfg.retry and cfg.retry.backoff) or 2000

    local function attempt(i)
        PerformHttpRequest(url, function(code, body, headers)
            -- handle rate-limit / forbidden distinctly
            if code == 200 and body then
                if cb then cb(code, body, headers) end
                return
            end
            if code == 403 or code == 429 then
                log('warn', ('HTTP %s on %s'):format(tostring(code), url))
                if cb then cb(code, nil, headers) end
                return
            end
            if i < attempts then
                local delay = backoff * (2 ^ (i - 1))
                SetTimeout(delay, function()
                    attempt(i + 1)
                end)
                return
            end
            if cb then cb(code, nil, headers) end
        end, 'GET', '', build_headers())
    end

    attempt(1)
end

local function parse_version_file(res)
    local raw = LoadResourceFile(res, "version")
    if not raw then return nil end
    local lines = {}
    for line in raw:gmatch("([^\r\n]+)") do
        table.insert(lines, line)
    end
    local version = nil
    local changelog = {}
    local repo = nil
    for i, l in ipairs(lines) do
        local s = l:gsub("^%s+", ""):gsub("%s+$", "")
        if s ~= "" then
            local repo_match = s:match("^repo%s*:%s*(.+)$") or s:match("^repository%s*:%s*(.+)$")
            if repo_match then
                repo = repo_match
            else
                if not version then
                    version = s
                else
                    local cleaned = s:gsub("^%-+%s*", ""):gsub("^%*+%s*", "")
                    table.insert(changelog, cleaned)
                end
            end
        end
    end
    return version, changelog, repo
end

local function parse_version_content(raw)
    if not raw then return nil end
    local lines = {}
    for line in tostring(raw):gmatch("([^\r\n]+)") do
        table.insert(lines, line)
    end
    local version = nil
    local changelog = {}
    local repo = nil
    for i, l in ipairs(lines) do
        local s = l:gsub("^%s+", ""):gsub("%s+$", "")
        if s ~= "" then
            local repo_match = s:match("^repo%s*:%s*(.+)$") or s:match("^repository%s*:%s*(.+)$")
            if repo_match then
                repo = repo_match
            else
                if not version then
                    version = s
                else
                    local cleaned = s:gsub("^%-+%s*", ""):gsub("^%*+%s*", "")
                    table.insert(changelog, cleaned)
                end
            end
        end
    end
    return version, changelog, repo
end

local function fetch_remote_version(repoParam, cb)
    -- repoParam can be: owner/repo, a github.com URL, or a raw.githubusercontent.com URL
    if not repoParam or repoParam == '' then
        if cb then cb(false, nil, nil, 'empty repo param') end
        return
    end
    local function try_url(url)
        local cached = cache_get(url)
        if cached then
            cb(true, cached.version, cached.changelog, nil)
            return
        end
        http_get_with_retries(url, function(code, body, headers)
            if code == 200 and body then
                local ver, changelog, repo = parse_version_content(body)
                cache_set(url, { version = ver, changelog = changelog, raw = body })
                cb(true, ver, changelog, nil)
                return
            end
            cb(false, nil, nil, ('http %s'):format(tostring(code)))
        end)
    end

    -- direct raw URL
    if type(repoParam) == 'string' and repoParam:match('^https?://raw%.githubusercontent%.com/') then
        try_url(repoParam)
        return
    end

    -- github.com URL: extract owner/repo and optional branch from /blob/
    local owner_repo = repoParam:match('github%.com/([^/%s]+/[^/%s]+)') or repoParam:match('([^/%s]+/[^/%s]+)')
    if not owner_repo then
        if cb then cb(false, nil, nil, 'could not parse repo param') end
        return
    end
    local owner, repo = owner_repo:match('([^/]+)/([^/]+)')
    local branch = repoParam:match('github%.com/[^/]+/[^/]+/blob/([^/]+)/')

    local tried = {}
    if branch then table.insert(tried, branch) end
    table.insert(tried, 'main')
    table.insert(tried, 'master')

    local api_idx = 1
    local tried_idx = 1

    local function try_next_api()
        local b = tried[api_idx]
        if not b then
            cb(false, nil, nil, 'remote version file not found')
            return
        end
        local api_url = ('https://api.github.com/repos/%s/%s/contents/version?ref=%s'):format(owner, repo, b)
        local cached = cache_get(api_url)
        if cached then
            cb(true, cached.version, cached.changelog, nil)
            return
        end
        http_get_with_retries(api_url, function(code, body, headers)
            if code == 200 and body then
                local ok, data = pcall(json.decode, body)
                if ok and data and data.content then
                    local enc = data.encoding
                    local content = data.content
                    if enc == 'base64' then
                        local ok2, decoded = pcall(function() return decode_base64(content) end)
                        if ok2 and decoded then
                            local ver, changelog, repoLine = parse_version_content(decoded)
                            cache_set(api_url, { version = ver, changelog = changelog, raw = decoded })
                            cb(true, ver, changelog, nil)
                            return
                        end
                    end
                end
            end
            api_idx = api_idx + 1
            try_next_api()
        end)
    end

    local function try_next_raw()
        local b = tried[tried_idx]
        if not b then
            try_next_api()
            return
        end
        local url = ('https://raw.githubusercontent.com/%s/%s/%s/version'):format(owner, repo, b)
        local cached = cache_get(url)
        if cached then
            cb(true, cached.version, cached.changelog, nil)
            return
        end
        http_get_with_retries(url, function(code, body, headers)
            if code == 200 and body then
                local ver, changelog, repoLine = parse_version_content(body)
                cache_set(url, { version = ver, changelog = changelog, raw = body })
                cb(true, ver, changelog, nil)
                return
            end
            tried_idx = tried_idx + 1
            try_next_raw()
        end)
    end

    -- base64 decoder for GitHub Contents API
    local function decode_base64(data)
        local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if x == '=' then return '' end
            local r,f='', (b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i - f%2^(i-1) > 0 and '1' or '0') end
            return r
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if #x ~= 8 then return '' end
            local c=0
            for i=1,8 do c=c + (x:sub(i,i) == '1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end

    local api_idx = 1
    local function try_next_api()
        local b = tried[api_idx]
        if not b then
            cb(false, nil, nil, 'remote version file not found')
            return
        end
        local api_url = ('https://api.github.com/repos/%s/%s/contents/version?ref=%s'):format(owner, repo, b)
        local cached = cache_get(api_url)
        if cached then
            cb(true, cached.version, cached.changelog, nil)
            return
        end
        http_get_with_retries(api_url, function(code, body, headers)
            if code == 200 and body then
                local ok, data = pcall(json.decode, body)
                if ok and data and data.content then
                    local enc = data.encoding
                    local content = data.content
                    if enc == 'base64' then
                        local ok2, decoded = pcall(function() return decode_base64(content) end)
                        if ok2 and decoded then
                            local ver, changelog, repoLine = parse_version_content(decoded)
                            cache_set(api_url, { version = ver, changelog = changelog, raw = decoded })
                            cb(true, ver, changelog, nil)
                            return
                        end
                    end
                end
            end
            api_idx = api_idx + 1
            try_next_api()
        end)
    end

    try_next_raw()
end

function CheckVersion(repo, current_version, cb)
    if not repo or repo == '' then
        if cb then cb(false, nil, 'repo not provided') end
        return
    end
    -- Fetch remote version file and compare
    fetch_remote_version(repo, function(ok, remote_version, remote_changelog, err)
        if not ok then
            if cb then cb(false, nil, err) end
            return
        end
        remote_version = tostring(remote_version or ''):gsub('^v', '')
        local cmp = compare_versions(current_version or '', remote_version)
        if cb then cb(true, { newer = (cmp < 0), latest = remote_version, changelog = remote_changelog }, nil) end
    end)
end

local function checkFileWrapper(resName, repoOrUrl, cb)
    if type(resName) ~= 'string' then
        if cb then cb(false, nil, 'resource name must be a string') end
        return
    end
    -- parse resource version file early
    local version, changelog, repoFromFile = parse_version_file(resName)
    local current_version = version or '0.0.0'

    -- throttle checks per-resource to avoid spamming remote hosts
    local cooldown = (Config and Config.Versioner and Config.Versioner.check_cooldown) or 60
    _G.__cz_version_last = _G.__cz_version_last or {}
    local last = _G.__cz_version_last[resName]
    local now = os.time()
    if last and (now - last) < cooldown then
        log('info', ('Skipping version check for %s (cooldown %ds remaining)'):format(resName, cooldown - (now - last)))
        -- return cached info if available
        local urlKey = repoOrUrl or repoFromFile
        local cached = urlKey and cache_get(urlKey)
        if cached then
            if cb then
                local newer = (compare_versions(current_version, cached.version) < 0)
                cb(true, { newer = newer, latest = cached.version, changelog = cached.changelog }, nil)
            end
            return
        end
        if cb then cb(false, nil, 'throttled') end
        return
    end
    local repo = repoOrUrl or repoFromFile
    if not repo or repo == '' then
        if cb then cb(false, nil, 'repo not provided or not found in resource version file') end
        return
    end
    CheckVersion(repo, current_version, function(ok, res, err)
        if not cb then
            if not ok then
                log('error', ('check failed for %s: %s'):format(resName, tostring(err)))
                return
            end

            local latest = res.latest or ''
            local cmp = compare_versions(current_version or '', latest)
            local uptodate = (cmp == 0)
            local overdate = (cmp > 0)
            local outdated = (cmp < 0)

            local repoLink = repo or ''
            if repoLink:match('^[^/]+/[^/]+$') then
                repoLink = ('https://github.com/%s'):format(repoLink)
            end

            if uptodate then
                log('info', ('^2✅ Up to Date! ^5[%s] ^6(Current Version %s)^0'):format(resName, current_version))
            elseif overdate then
                log('warn', ('^3⚠️ Unsupported! ^5[%s] ^6(Version %s)^0'):format(resName, current_version))
                if latest ~= '' then
                    log('info', ('^4Latest Available ^2(%s) ^3<%s>^0'):format(latest, repoLink))
                end
            elseif outdated then
                log('error', ('^1❌ Outdated! ^5[%s] ^6(Version %s)^0'):format(resName, current_version))
                if latest ~= '' then
                    log('info', ('^4NEW VERSION ^2(%s) ^3<%s>^0'):format(latest, repoLink))
                end
                if res.changelog and #res.changelog > 0 then
                    log('info', '^4CHANGELOG:^0')
                    for _, line in ipairs(res.changelog) do
                        log('info', ('  - %s'):format(line))
                    end
                end
            else
                log('info', ('%s is up-to-date (%s)'):format(resName, current_version))
            end

            -- record last check time
            _G.__cz_version_last[resName] = os.time()
            return
        end
        cb(ok, res, err)
    end)
end

-- register RPC for remote checks
if CZ_RPC then
    CZ_RPC.register('cz-core:check_version', function(_, repo, current_version)
        local result = nil
        local done = false
        CheckVersion(repo, current_version, function(ok, res, err)
            result = { ok = ok, res = res, err = err }
            done = true
        end)
        local t0 = GetGameTimer()
        while not done and GetGameTimer() - t0 < 5000 do
            Citizen.Wait(50)
        end
        return result
    end)
end

-- expose the versioner implementation to core_api via registration helper
if type(_G.__cz_core_register_versioner) == 'function' then
    _G.__cz_core_register_versioner({ checkFile = checkFileWrapper, CheckVersion = CheckVersion })
end

if CZLog and CZLog.info then CZLog.info('Versioner module loaded') else print('Versioner module loaded') end
