--!strict
-- Player level is derived from lifetime XP; independent from Wins.

local LevelCurve = {}

export type Config = { Base: number, Growth: number, Cap: number }

function LevelCurve.xpToNext(level: number, config: Config): number
	return math.floor(config.Base * config.Growth ^ (level - 1) + 0.5)
end

-- Returns level, xp into current level, xp needed for next level.
function LevelCurve.fromTotalXp(totalXp: number, config: Config): (number, number, number)
	local level = 1
	local remaining = math.max(0, math.floor(totalXp))
	while level < config.Cap do
		local need = LevelCurve.xpToNext(level, config)
		if remaining < need then
			return level, remaining, need
		end
		remaining -= need
		level += 1
	end
	return config.Cap, 0, 0
end

function LevelCurve.totalXpForLevel(level: number, config: Config): number
	local total = 0
	for l = 1, level - 1 do
		total += LevelCurve.xpToNext(l, config)
	end
	return total
end

return LevelCurve
