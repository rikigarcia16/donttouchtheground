--!strict
-- Rarity defines far more than a colour: price band, card frame style, sound,
-- purchase celebration and how much visual budget an item may use.

export type RarityId = "Common" | "Rare" | "Epic" | "Legendary" | "Mythic"

export type Rarity = {
	id: RarityId,
	order: number,
	displayName: string,
	minPrice: number,
	maxPrice: number,
	color: Color3,
	accent: Color3,
	gradient: { Color3 },
	frameStyle: "Plain" | "Stripe" | "Shine" | "Pulse" | "Prismatic",
	celebration: "Pop" | "Burst" | "Shower" | "Fanfare" | "Cosmic",
	purchaseSound: string,
	glyph: string,
}

local Rarities: { [string]: Rarity } = {
	Common = {
		id = "Common",
		order = 1,
		displayName = "Common",
		minPrice = 2,
		maxPrice = 5,
		color = Color3.fromRGB(176, 190, 205),
		accent = Color3.fromRGB(235, 242, 250),
		gradient = { Color3.fromRGB(120, 135, 150), Color3.fromRGB(190, 205, 220) },
		frameStyle = "Plain",
		celebration = "Pop",
		purchaseSound = "PurchaseCommon",
		glyph = "●",
	},
	Rare = {
		id = "Rare",
		order = 2,
		displayName = "Rare",
		minPrice = 6,
		maxPrice = 15,
		color = Color3.fromRGB(45, 150, 255),
		accent = Color3.fromRGB(150, 215, 255),
		gradient = { Color3.fromRGB(20, 85, 210), Color3.fromRGB(70, 190, 255) },
		frameStyle = "Stripe",
		celebration = "Burst",
		purchaseSound = "PurchaseRare",
		glyph = "◆",
	},
	Epic = {
		id = "Epic",
		order = 3,
		displayName = "Epic",
		minPrice = 16,
		maxPrice = 40,
		color = Color3.fromRGB(170, 70, 255),
		accent = Color3.fromRGB(225, 170, 255),
		gradient = { Color3.fromRGB(95, 25, 200), Color3.fromRGB(215, 90, 255) },
		frameStyle = "Shine",
		celebration = "Shower",
		purchaseSound = "PurchaseEpic",
		glyph = "✦",
	},
	Legendary = {
		id = "Legendary",
		order = 4,
		displayName = "Legendary",
		minPrice = 41,
		maxPrice = 100,
		color = Color3.fromRGB(255, 180, 30),
		accent = Color3.fromRGB(255, 235, 140),
		gradient = { Color3.fromRGB(255, 120, 0), Color3.fromRGB(255, 225, 60) },
		frameStyle = "Pulse",
		celebration = "Fanfare",
		purchaseSound = "PurchaseLegendary",
		glyph = "★",
	},
	Mythic = {
		id = "Mythic",
		order = 5,
		displayName = "Mythic",
		minPrice = 101,
		maxPrice = 250,
		color = Color3.fromRGB(255, 60, 140),
		accent = Color3.fromRGB(120, 255, 240),
		gradient = {
			Color3.fromRGB(255, 50, 120),
			Color3.fromRGB(255, 200, 60),
			Color3.fromRGB(60, 255, 200),
			Color3.fromRGB(110, 90, 255),
		},
		frameStyle = "Prismatic",
		celebration = "Cosmic",
		purchaseSound = "PurchaseMythic",
		glyph = "✺",
	},
}

local RarityConfig = {
	ById = Rarities,
	Order = { "Common", "Rare", "Epic", "Legendary", "Mythic" } :: { RarityId },
}

function RarityConfig.get(id: string): Rarity
	local rarity = Rarities[id]
	assert(rarity, "Unknown rarity " .. tostring(id))
	return rarity
end

return RarityConfig
