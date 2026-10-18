--!strict
-- Deterministic PRNG (Park-Miller minimal standard). Every intermediate value
-- stays below 2^53 so results are exact in doubles and identical on every
-- server and in every test run (used for rotations, daily quests, tests).

local Prng = {}
Prng.__index = Prng

export type Prng = typeof(setmetatable({} :: { state: number }, Prng))

local MODULUS = 2147483647
local MULTIPLIER = 48271

function Prng.new(seed: number): Prng
	local state = math.floor(math.abs(seed)) % MODULUS
	if state == 0 then
		state = 1234567
	end
	local self = setmetatable({ state = state }, Prng)
	-- Discard the first outputs: they correlate strongly with small seeds.
	for _ = 1, 4 do
		self:NextNumber()
	end
	return self
end

function Prng.hashString(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % MODULUS
	end
	return h
end

-- Returns a float in [0, 1).
function Prng.NextNumber(self: Prng): number
	self.state = (self.state * MULTIPLIER) % MODULUS
	return (self.state - 1) / (MODULUS - 1)
end

-- Inclusive integer range.
function Prng.NextInteger(self: Prng, min: number, max: number): number
	return min + math.floor(self:NextNumber() * (max - min + 1))
end

function Prng.Shuffle<T>(self: Prng, list: { T }): { T }
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = self:NextInteger(1, i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

function Prng.Pick<T>(self: Prng, list: { T }): T
	return list[self:NextInteger(1, #list)]
end

-- Picks an index from a list of weights (all >= 0, at least one > 0).
function Prng.WeightedIndex(self: Prng, weights: { number }): number?
	local total = 0
	for _, w in weights do
		total += math.max(w, 0)
	end
	if total <= 0 then
		return nil
	end
	local roll = self:NextNumber() * total
	for i, w in weights do
		roll -= math.max(w, 0)
		if roll < 0 then
			return i
		end
	end
	return #weights
end

return Prng
