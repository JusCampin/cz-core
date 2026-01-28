Config = {}

Config.RPC = {
    -- timeout for RPC requests in milliseconds
    timeout = 10000,
    -- maximum number of pending requests per side
    maxPending = 100,
    -- allowlists (optional) - if non-empty, only listed names are callable
    -- default allowed RPCs — populate with safe, minimal entries
    allowedServerRPCs = {
        'getPlayerIdentifiers',
    },
    allowedClientRPCs = {

    },
    -- if true, automatically add registered server RPCs to the server allowlist
    autoAllow = false,
    -- simple rate limit settings per player (calls per interval)
    rateLimit = {
        interval = 1000, -- ms
        maxCalls = 10,
    },
}

-- Versioner / GitHub settings (server-only)
Config.Versioner = {
    -- GitHub personal access token (server-only). Prefer setting this as a server convar
    -- named `cz_core_github_token` or fill it in here on the server (do NOT commit secrets).
    github_token = nil,
    -- cache TTL for remote version responses (seconds)
    cache_ttl = 300,
    -- retry configuration for HTTP requests
    retry = {
        attempts = 2,
        backoff = 2000, -- ms base backoff
    },
}
