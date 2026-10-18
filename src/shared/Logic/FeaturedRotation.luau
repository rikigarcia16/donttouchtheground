--!strict
-- Deterministic featured shop: every server shows the same picks for a period.
-- Rotation only changes what is highlighted (and discounted); every shop item
-- stays purchasable from the permanent catalogue at all times.

local Prng = require(script.Parent.Parent.Util.Prng)

local FeaturedRotation = {}

export type Item = {
	id: string,
	category: string,
	rarity: string,
	unlock: { kind: string },
	price: number?,
	currency: string,
}

function FeaturedRotation.periodIndex(unixTime: number, rotationHours: number): number
	return math.floor(unixTime / (rotationHours * 3600))
end

function FeaturedRotation.secondsUntilNext(unixTime: number, rotationHours: number): number
	local period = rotationHours * 3600
	return period - (unixTime % period)
end

function FeaturedRotation.pick(items: { Item }, period: number, slotCount: number, maxPerCategory: number): { string }
	local pool = {}
	for _, item in items do
		if item.unlock.kind == "Shop" and item.price ~= nil and item.currency == "Wins" then
			table.insert(pool, item)
		end
	end
	table.sort(pool, function(a, b)
		return a.id < b.id
	end)

	local rng = Prng.new(period * 7919 + 17)
	local shuffled = rng:Shuffle(pool)
	local picks = {}
	local perCategory: { [string]: number } = {}
	local hasHighRarity = false

	for _, item in shuffled do
		if #picks >= slotCount then
			break
		end
		local count = perCategory[item.category] or 0
		if count < maxPerCategory then
			perCategory[item.category] = count + 1
			table.insert(picks, item.id)
			if item.rarity == "Legendary" or item.rarity == "Mythic" then
				hasHighRarity = true
			end
		end
	end

	-- Guarantee one headline item (Legendary/Mythic) in the first slot.
	if not hasHighRarity then
		for _, item in shuffled do
			if (item.rarity == "Legendary" or item.rarity == "Mythic") and not table.find(picks, item.id) then
				picks[1] = item.id
				break
			end
		end
	else
		for i, id in picks do
			for _, item in pool do
				if item.id == id and (item.rarity == "Legendary" or item.rarity == "Mythic") then
					picks[i], picks[1] = picks[1], picks[i]
					return picks
				end
			end
		end
	end
	return picks
end

return FeaturedRotation
