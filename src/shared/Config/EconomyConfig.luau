--!strict
-- Rewards, XP and level curve. Tuned so a free player earns an Epic within a
-- few sessions, a Legendary within a couple of weeks and Mythics long-term.

local EconomyConfig = {
	Rewards = {
		Win = { wins = 1, coins = 100, xp = 120 },
		Second = { coins = 50, xp = 70 },
		Third = { coins = 30, xp = 50 },
		Participation = { coins = 5, xp = 25 },
		Survive60 = { coins = 15, xp = 20 },
		SurvivePerExtra30 = { coins = 5, xp = 10 }, -- every 30s survived after the first 60
		FirstWinOfDay = { wins = 1 },
		Draw = { coins = 50, xp = 70 }, -- last players eliminated in the same instant
		Training = { xp = 15 }, -- single player: never Wins or Coins
	},

	-- XP needed to go from level L to L+1.
	Level = {
		Base = 100,
		Growth = 1.12,
		Cap = 200,
	},

	FeaturedShop = {
		SlotCount = 6,
		DiscountPercent = 15, -- featured items cost less; never removes items from the catalogue
		RotationHours = 24,
		-- Mix guarantees variety: at most this many from the same category.
		MaxPerCategory = 2,
	},

	Presets = { Slots = 3 },
}

return EconomyConfig
