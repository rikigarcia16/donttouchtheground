--!nonstrict
-- The only code allowed to change Wins, Coins and XP. Every grant is logged
-- with a reason; spending is atomic inside a single profile update.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local EconomyConfig = require(Shared.Config.EconomyConfig)
local LevelCurve = require(Shared.Logic.LevelCurve)
local Signal = require(Shared.Util.Signal)

local CurrencyService = {}
CurrencyService.LevelUp = Signal.new() -- (player, newLevel, oldLevel)

local PlayerData: any

export type Grant = { wins: number?, coins: number?, xp: number?, victories: number? }

local MAX_SINGLE_GRANT = { wins = 5, coins = 20000, xp = 20000, victories = 1 }

function CurrencyService.Grant(player: Player, grant: Grant, reason: string): boolean
	local wins = math.clamp(math.floor(grant.wins or 0), 0, MAX_SINGLE_GRANT.wins)
	local coins = math.clamp(math.floor(grant.coins or 0), 0, MAX_SINGLE_GRANT.coins)
	local xp = math.clamp(math.floor(grant.xp or 0), 0, MAX_SINGLE_GRANT.xp)
	local victories = math.clamp(math.floor(grant.victories or 0), 0, MAX_SINGLE_GRANT.victories)
	if wins + coins + xp + victories == 0 then
		return true
	end
	local oldLevel, newLevel = 1, 1
	local ok = PlayerData.Update(
		player,
		{ "wins", "totalWins", "coins", "totalCoins", "xp", "level" },
		function(profile)
			profile.wins += wins
			profile.totalWins += victories
			profile.coins += coins
			profile.totalCoins += coins
			profile.xp += xp
			oldLevel = profile.level
			newLevel = LevelCurve.fromTotalXp(profile.xp, EconomyConfig.Level)
			profile.level = newLevel
		end
	)
	if ok and newLevel > oldLevel then
		CurrencyService.LevelUp:Fire(player, newLevel, oldLevel)
	end
	if ok then
		print(string.format("[Currency] %s +%dW +%dC +%dXP (%s)", player.Name, wins, coins, xp, reason))
	end
	return ok
end

-- Validates and deducts inside one update. `onSuccess` runs in the same
-- mutation so the deduction and the delivery can never be split.
function CurrencyService.SpendAtomic(
	player: Player,
	currency: "Wins" | "Coins",
	amount: number,
	keys: { string },
	onSuccess: (profile: any) -> ()
): boolean
	if amount <= 0 or amount ~= math.floor(amount) then
		return false
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return false
	end
	local field = if currency == "Coins" then "coins" else "wins"
	if profile[field] < amount then
		return false
	end
	local allKeys = table.clone(keys)
	table.insert(allKeys, field)
	local spent = false
	PlayerData.Update(player, allKeys, function(p)
		if p[field] >= amount then
			p[field] -= amount
			spent = true
			onSuccess(p)
		end
	end)
	return spent
end

function CurrencyService.Init(services)
	PlayerData = services.PlayerDataService
end

return CurrencyService
