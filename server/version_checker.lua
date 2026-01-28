local resourceName = GetCurrentResourceName()

local use_releases = true
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
                    -- strip leading bullets
                    local cleaned = s:gsub("^%-+%s*", ""):gsub("^%*+%s*", "")
                    table.insert(changelog, cleaned)
                end
            end
        end
    end
    return version, changelog, repo
end

local function fetch_latest_from_github(repo, use_releases, cb)
    local url
    if use_releases == false then
        url = ('https://api.github.com/repos/%s/tags'):format(repo)
    else
        url = ('https://api.github.com/repos/%s/releases/latest'):format(repo)
    end
    PerformHttpRequest(url, function(code, body, headers)
        if code ~= 200 then
            cb(false, nil, ('GitHub request failed: %s'):format(tostring(code)))
            return
        end
        local ok, data = pcall(json.decode, body)
        if not ok or not data then
            cb(false, nil, 'failed to parse GitHub response')
            return
        end
        if use_releases == false then
            if type(data) == 'table' and #data > 0 and data[1].name then
                cb(true, data[1].name)
                return
            elseif type(data) == 'table' and #data > 0 and data[1].tag_name then
                cb(true, data[1].tag_name)
                return
            end
            cb(false, nil, 'no tags found')
            return
        else
            local latest = data.tag_name or data.name
            if latest then
                cb(true, latest)
                return
            end
            cb(false, nil, 'no tag_name found in release')
            return
        end
    end, 'GET', '', build_headers())
end

-- Public: check a given repo against a provided current_version
function CheckVersion(repo, current_version, cb)
    if not repo or repo == '' then
        if cb then cb(false, nil, 'repo not provided') end
        return
    end
    local function normalize_repo_param(r)
        if type(r) ~= 'string' then return r end
        if r:match('^https?://') then
            local m = r:match('github%.com/([^/%s]+/[^/%s]+)')
            if m then return m end
        end
        return r
    end
    repo = normalize_repo_param(repo)
    fetch_latest_from_github(repo, use_releases, function(ok, latest, err)
        if not ok then
            if cb then cb(false, nil, err) end
            return
        end
        latest = tostring(latest):gsub('^v', '')
        local cmp = compare_versions(current_version or '', latest)
        if cb then cb(true, { newer = (cmp < 0), latest = latest }, nil) end
    end)
end

-- Starts checker for this resource once. Reads `version` file for current version and repo.
function StartVersionChecker()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        local version, changelog, repo = parse_version_file(resourceName)
        local current_version = version or '0.0.0'
        if not repo or repo == '' then
            print('[cz-core][version-checker] repo not found in version file. Add a line like "repo: owner/repo" to version')
            return
        end
        CheckVersion(repo, current_version, function(ok, res, err)
            if not ok then
                print(('[cz-core][version-checker] check failed: %s'):format(tostring(err)))
                return
            end
            if res.newer then
                print(('\n[cz-core] NEW VERSION AVAILABLE for %s!\n  current: %s\n  latest:  %s\n  see: https://github.com/%s/releases/latest\n'):format(resourceName, current_version, res.latest, repo))
            else
                print(('[cz-core] %s is up-to-date (%s)'):format(resourceName, current_version))
            end
        end)
    end)
end

-- Also register via CZ_RPC if present
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

-- Provide a callable API table to other resources
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

local CzCoreRPC = {}

-- readiness flag and helper
local core_ready = false
AddEventHandler('cz-core:ready', function()
    core_ready = true
end)

local function waitForReady(cb)
    if type(cb) ~= 'function' then return end
    if core_ready then
        cb(GetCore())
        return
    end
    AddEventHandler('cz-core:ready', function()
        cb(GetCore())
    end)
end

function GetCore()
    return { RPC = { raw = CZ_RPC, call = CzCoreRPC.call }, Versioner = { checkFile = checkFileWrapper }, waitForReady = waitForReady }
end

_G.GetCore = GetCore

function CzCoreRPC.call(name, sourceOrNil, ...)
    if CZ_RPC and CZ_RPC.call then
        return CZ_RPC.call(name, sourceOrNil, ...)
    elseif CZ_RPC and CZ_RPC.triggerClient then
        -- fallback: not ideal for server->server calls
        return false, 'direct server call not supported on this build'
    end
    return false, 'CZ_RPC not available'
end
