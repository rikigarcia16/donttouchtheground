--!strict
-- Chooses which random event runs next. Intensity ramps with round time,
-- concurrent events are capped by a difficulty budget, and tags prevent
-- impossible combinations (e.g. wind on ice, darkness during meteors).

local DifficultyDirector = {}

export type EventDef = {
	id: string,
	difficulty: number,
	weight: number,
	minElapsed: number,
	cooldown: number,
	tags: { string },
	incompatible: { string },
	scheduledOnly: boolean?,
}

export type Ramp = { from: number, maxDifficulty: number, budget: number, maxConcurrent: number, gap: { number } }

export type Rng = {
	NextNumber: (any) -> number,
	NextInteger: (any, number, number) -> number,
	WeightedIndex: (any, { number }) -> number?,
}

function DifficultyDirector.rampAt(ramps: { Ramp }, elapsed: number): Ramp
	local current = ramps[1]
	for _, ramp in ramps do
		if elapsed >= ramp.from then
			current = ramp
		end
	end
	return current
end

local function intersects(a: { string }, b: { string }): boolean
	for _, x in a do
		if table.find(b, x) then
			return true
		end
	end
	return false
end

function DifficultyDirector.compatible(candidate: EventDef, active: { EventDef }): boolean
	for _, other in active do
		if other.id == candidate.id then
			return false
		end
		if intersects(candidate.tags, other.incompatible) or intersects(other.tags, candidate.incompatible) then
			return false
		end
	end
	return true
end

export type State = {
	elapsed: number,
	active: { EventDef },
	recent: { string }, -- most recent last
	lastRunAt: { [string]: number },
	mapWeights: { [string]: number }?,
	historyNoRepeat: number,
	suddenDeath: boolean,
}

function DifficultyDirector.eligible(defs: { EventDef }, ramps: { Ramp }, state: State): ({ EventDef }, { number })
	local ramp = DifficultyDirector.rampAt(ramps, state.elapsed)
	local list, weights = {}, {}
	if state.suddenDeath or #state.active >= ramp.maxConcurrent then
		return list, weights
	end
	local activeDifficulty = 0
	for _, def in state.active do
		activeDifficulty += def.difficulty
	end
	local recentStart = math.max(1, #state.recent - state.historyNoRepeat + 1)
	for _, def in defs do
		local ok = not def.scheduledOnly
			and def.weight > 0
			and state.elapsed >= def.minElapsed
			and def.difficulty <= ramp.maxDifficulty
			and activeDifficulty + def.difficulty <= ramp.budget
			and DifficultyDirector.compatible(def, state.active)
		if ok then
			for i = recentStart, #state.recent do
				if state.recent[i] == def.id then
					ok = false
				end
			end
		end
		if ok then
			local last = state.lastRunAt[def.id]
			if last and state.elapsed - last < def.cooldown then
				ok = false
			end
		end
		if ok then
			local multiplier = if state.mapWeights and state.mapWeights[def.id] then state.mapWeights[def.id] else 1
			table.insert(list, def)
			table.insert(weights, def.weight * multiplier)
		end
	end
	return list, weights
end

function DifficultyDirector.choose(defs: { EventDef }, ramps: { Ramp }, state: State, rng: Rng): EventDef?
	local list, weights = DifficultyDirector.eligible(defs, ramps, state)
	if #list == 0 then
		return nil
	end
	local index = rng:WeightedIndex(weights)
	return if index then list[index] else nil
end

function DifficultyDirector.nextGap(ramps: { Ramp }, elapsed: number, rng: Rng): number
	local ramp = DifficultyDirector.rampAt(ramps, elapsed)
	return rng:NextInteger(ramp.gap[1], ramp.gap[2])
end

return DifficultyDirector
