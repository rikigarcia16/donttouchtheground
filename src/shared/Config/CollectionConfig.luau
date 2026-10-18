--!strict
-- Themed collections. Membership comes from each catalogue item's `collection`
-- field; this file only holds presentation and the completion reward (which
-- is itself a cosmetic, never a gameplay advantage).

export type Collection = {
	id: string,
	name: string,
	description: string,
	icon: string,
	colors: { Color3 },
	reward: string, -- cosmetic id granted on completion
}

local RGB = Color3.fromRGB

local list: { Collection } = {
	{
		id = "Fire",
		name = "Fire Collection",
		description = "Everything that burns bright.",
		icon = "🔥",
		colors = { RGB(255, 170, 30), RGB(200, 20, 0) },
		reward = "title_inferno_master",
	},
	{
		id = "Frozen",
		name = "Frozen Collection",
		description = "Ice, frost and crystal.",
		icon = "❄️",
		colors = { RGB(210, 250, 255), RGB(70, 150, 255) },
		reward = "podium_glacier",
	},
	{
		id = "Galaxy",
		name = "Galaxy Collection",
		description = "Stars, nebulae and planets.",
		icon = "🌌",
		colors = { RGB(170, 90, 255), RGB(30, 20, 110) },
		reward = "title_galaxy_master",
	},
	{
		id = "Cyber",
		name = "Cyber Collection",
		description = "Neon, pixels and holograms.",
		icon = "💾",
		colors = { RGB(0, 255, 220), RGB(255, 0, 200) },
		reward = "emote_glitch",
	},
	{
		id = "Rainbow",
		name = "Rainbow Collection",
		description = "Every colour at once.",
		icon = "🌈",
		colors = { RGB(255, 90, 90), RGB(90, 160, 255) },
		reward = "podium_rainbow_arch",
	},
	{
		id = "Royal",
		name = "Royal Collection",
		description = "Gold, crowns and capes.",
		icon = "👑",
		colors = { RGB(255, 220, 90), RGB(150, 30, 60) },
		reward = "title_royal_highness",
	},
	{
		id = "Void",
		name = "Void Collection",
		description = "Shadows from beyond the edge.",
		icon = "🕳️",
		colors = { RGB(130, 60, 255), RGB(5, 0, 20) },
		reward = "podium_void_rift",
	},
}

local byId: { [string]: Collection } = {}
for _, collection in list do
	byId[collection.id] = collection
end

return {
	List = list,
	ById = byId,
}
