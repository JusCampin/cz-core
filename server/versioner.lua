local github_token = nil

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
        PerformHttpRequest(url, function(code, body, headers)
            if code == 200 and body then
                local ver, changelog, repo = parse_version_content(body)
                cb(true, ver, changelog, nil)
                return
            end
            cb(false, nil, nil, ('http %s'):format(tostring(code)))
        end, 'GET', '', build_headers())
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

    local tried_idx = 1
    local try_next_api
    local function try_next_raw()
        local b = tried[tried_idx]
        if not b then
            try_next_api()
            return
        end
        local url = ('https://raw.githubusercontent.com/%s/%s/%s/version'):format(owner, repo, b)
        PerformHttpRequest(url, function(code, body, headers)
            if code == 200 and body then
                local ver, changelog, repoLine = parse_version_content(body)
                cb(true, ver, changelog, nil)
                return
            end
            tried_idx = tried_idx + 1
            try_next_raw()
        end, 'GET', '', build_headers())
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
        PerformHttpRequest(api_url, function(code, body, headers)
            if code == 200 and body then
                local ok, data = pcall(json.decode, body)
                if ok and data and data.content then
                    local enc = data.encoding
                    local content = data.content
                    if enc == 'base64' then
                        local ok2, decoded = pcall(function() return decode_base64(content) end)
                        if ok2 and decoded then
                            local ver, changelog, repoLine = parse_version_content(decoded)
                            cb(true, ver, changelog, nil)
                            return
                        end
                    end
                end
            end
            api_idx = api_idx + 1
            try_next_api()
        end, 'GET', '', build_headers())
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
    local version, changelog, repoFromFile = parse_version_file(resName)
    local current_version = version or '0.0.0'
    local repo = repoOrUrl or repoFromFile
    if not repo or repo == '' then
        if cb then cb(false, nil, 'repo not provided or not found in resource version file') end
        return
    end
    CheckVersion(repo, current_version, function(ok, res, err)
        if not cb then
            if not ok then
                print(('[cz-core][versioner] check failed for %s: %s'):format(resName, tostring(err)))
                return
            end
            if res.newer then
                print(('\n[cz-core] NEW VERSION AVAILABLE for %s!\n  current: %s\n  latest: %s\n  see: https://github.com/%s/releases/latest\n'):format(resName, current_version, res.latest, repo))
                if changelog and #changelog > 0 then
                    print('  changelog:')
                    for _,line in ipairs(changelog) do
                        print(('    - %s'):format(line))
                    end
                end
            else
                print(('[cz-core] %s is up-to-date (%s)'):format(resName, current_version))
            end
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

print('[cz-core] versioner module loaded')
