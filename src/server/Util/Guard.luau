--!nonstrict
-- Wraps client -> server remotes: per-player rate limiting, argument type
-- checks and error isolation. Handlers never see malformed input.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local RateLimiter = require(Shared.Util.RateLimiter)

local Guard = {}

local limiters: { RateLimiter.RateLimiter } = {}

Players.PlayerRemoving:Connect(function(player)
	for _, limiter in limiters do
		limiter:Forget(player)
	end
end)

export type Check = "string" | "number" | "boolean" | "string?" | "number?" | "boolean?" | "any"

local function matches(value: any, check: Check): boolean
	if check == "any" then
		return true
	end
	local optional = string.sub(check, -1) == "?"
	local base = if optional then string.sub(check, 1, -2) else check
	if value == nil then
		return optional
	end
	if type(value) ~= base then
		return false
	end
	if base == "number" and (value ~= value or value == math.huge or value == -math.huge) then
		return false
	end
	if base == "string" and #value > 64 then
		return false
	end
	return true
end

local function validate(args: { any }, checks: { Check }): boolean
	for i, check in checks do
		if not matches(args[i], check) then
			return false
		end
	end
	return true
end

function Guard.func(remote: RemoteFunction, checks: { Check }, perSecond: number, handler: (Player, ...any) -> any)
	local limiter = RateLimiter.new(math.max(3, perSecond * 2), perSecond)
	table.insert(limiters, limiter)
	remote.OnServerInvoke = function(player: Player, ...)
		if not limiter:Check(player) then
			return { ok = false, reason = "RateLimited" }
		end
		local args = { ... }
		if not validate(args, checks) then
			return { ok = false, reason = "BadRequest" }
		end
		local ok, result = pcall(handler, player, table.unpack(args, 1, #checks))
		if not ok then
			warn("[Guard] " .. remote.Name .. " error: " .. tostring(result))
			return { ok = false, reason = "ServerError" }
		end
		return result
	end
end

function Guard.event(remote: RemoteEvent, checks: { Check }, perSecond: number, handler: (Player, ...any) -> ())
	local limiter = RateLimiter.new(math.max(3, perSecond * 2), perSecond)
	table.insert(limiters, limiter)
	remote.OnServerEvent:Connect(function(player: Player, ...)
		if not limiter:Check(player) then
			return
		end
		local args = { ... }
		if not validate(args, checks) then
			return
		end
		local ok, err = pcall(handler, player, table.unpack(args, 1, #checks))
		if not ok then
			warn("[Guard] " .. remote.Name .. " error: " .. tostring(err))
		end
	end)
end

-- Serialises handlers per player (no concurrent purchases from one player).
local busy: { [Player]: boolean } = {}
function Guard.exclusive<T>(player: Player, fn: () -> T): (boolean, T?)
	if busy[player] then
		return false, nil
	end
	busy[player] = true
	local ok, result = pcall(fn)
	busy[player] = nil
	if not ok then
		error(result, 0)
	end
	return true, result
end

return Guard
