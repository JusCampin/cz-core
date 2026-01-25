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
