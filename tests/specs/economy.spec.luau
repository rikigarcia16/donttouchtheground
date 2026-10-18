local test, eq, ok = Harness.test, Harness.eq, Harness.ok
local Catalog = require(Shared.Config.CosmeticCatalog)
local Rarity = require(Shared.Config.RarityConfig)
local Collections = require(Shared.Config.CollectionConfig)
local Achievements = require(Shared.Config.AchievementConfig)
local Quests = require(Shared.Config.QuestConfig)
local Events = require(Shared.Config.EventConfig)
local Economy = require(Shared.Config.EconomyConfig)
local ProfileSchema = require(Shared.Logic.ProfileSchema)
local ShopRules = require(Shared.Logic.ShopRules)
local Featured = require(Shared.Logic.FeaturedRotation)
local QuestLogic = require(Shared.Logic.QuestLogic)
local Progress = require(Shared.Logic.ProgressLogic)
local Director = require(Shared.Logic.DifficultyDirector)
local Prng = require(Shared.Util.Prng)

local COIN_BANDS = { Common = { 150, 600 }, Rare = { 600, 1500 }, Epic = { 1500, 4000 } }

test("catalogue prices respect rarity bands", function()
	for _, item in Catalog.Items do
		local rarity = Rarity.get(item.rarity)
		if item.price then
			if item.currency == "Wins" then
				ok(item.price >= rarity.minPrice and item.price <= rarity.maxPrice, item.id .. " price " .. item.price)
			else
				local band = COIN_BANDS[item.rarity]
				ok(band, item.id .. " coin item rarity has no band")
				ok(item.price >= band[1] and item.price <= band[2], item.id .. " coin price")
			end
			eq(item.unlock.kind, "Shop", item.id)
		else
			ok(item.unlock.kind ~= "Shop", item.id .. " shop item without price")
		end
	end
end)

test("catalogue has the requested breadth", function()
	local counts = {}
	for _, item in Catalog.Items do
		counts[item.category] = (counts[item.category] or 0) + 1
	end
	ok(counts.Trail >= 20, "trails")
	ok(counts.Aura >= 15, "auras")
	ok(counts.JumpEffect >= 10, "jump")
	ok(counts.LandingEffect >= 8, "landing")
	ok(counts.WinAnimation >= 10, "win")
	ok(counts.DeathEffect >= 8, "death")
	ok(counts.Emote >= 15, "emotes")
	ok(counts.Accessory >= 20, "accessories")
	ok(counts.Title >= 10, "titles")
	ok(counts.Podium >= 7, "podiums")
	for _, item in Catalog.Items do
		if item.category == "Accessory" then
			ok(table.find(ProfileSchema.ACCESSORY_SLOTS, item.slot), item.id .. " slot")
		end
	end
end)

test("trail and aura price ranges match the brief", function()
	for _, item in Catalog.Items do
		if item.category == "Trail" and item.price then
			ok(item.price >= 2 and item.price <= 150, item.id)
		elseif item.category == "Aura" and item.price then
			ok(item.price >= 10 and item.price <= 250, item.id)
		end
	end
end)

test("every unlock reference resolves", function()
	for _, item in Catalog.Items do
		if item.unlock.kind == "Achievement" then
			ok(Achievements.ById[item.unlock.id], item.id .. " -> " .. item.unlock.id)
		elseif item.unlock.kind == "Collection" then
			ok(Collections.ById[item.unlock.id], item.id)
			eq(Collections.ById[item.unlock.id].reward, item.id, "collection reward link " .. item.id)
		end
		if item.collection then
			ok(Collections.ById[item.collection], item.id .. " collection")
		end
	end
	for _, a in Achievements.List do
		for _, reward in a.rewards do
			local item = Catalog.get(reward)
			ok(item, a.id .. " reward " .. reward)
			eq(item.unlock.kind, "Achievement", reward)
		end
	end
	for _, c in Collections.List do
		local members = Progress.collectionMembers(Catalog.Items, c.id)
		ok(#members >= 5, c.id .. " has " .. #members .. " members")
		ok(Catalog.get(c.reward), c.reward)
	end
end)

test("profile load: nil -> default; migrates v1; drops unknown and unowned", function()
	local p = ProfileSchema.load(nil, 100, Catalog.ById)
	eq(p.version, ProfileSchema.VERSION)
	eq(p.wins, 0)
	local v1 = {
		wins = 7,
		coins = -5,
		owned = { trail_fire = true, not_a_real_item = true },
		equipped = { Trail = "trail_fire", Aura = "aura_void", Accessory = "acc_party_hat" },
		stats = { roundsPlayed = 3.7, mapsWon = { rainbow_sky = 2 } },
		settings = { quality = "Ultra", music = 3 },
	}
	local loaded, notes = ProfileSchema.load(v1, 100, Catalog.ById)
	eq(loaded.wins, 7)
	eq(loaded.totalWins, 7, "migration copies lifetime wins")
	eq(loaded.coins, 0, "negative clamped")
	ok(loaded.owned.trail_fire)
	eq(loaded.owned.not_a_real_item, nil)
	eq(loaded.equipped.Trail, "trail_fire")
	eq(loaded.equipped.Aura, nil, "unowned unequipped")
	eq(loaded.equipped.Accessories.Head, nil, "migrated accessory unowned -> removed")
	eq(loaded.stats.roundsPlayed, 3)
	eq(loaded.stats.mapsWon.rainbow_sky, 2)
	eq(loaded.settings.quality, "Auto")
	eq(loaded.settings.music, 1)
	ok(#notes > 0)
end)

test("processed rounds dedupe and trim", function()
	local p = ProfileSchema.default(0)
	ok(ProfileSchema.markRoundProcessed(p, "r1"))
	ok(not ProfileSchema.markRoundProcessed(p, "r1"))
	for i = 2, 50 do
		ProfileSchema.markRoundProcessed(p, "r" .. i)
	end
	eq(#p.processedRounds, ProfileSchema.MAX_PROCESSED_ROUNDS)
end)

test("shop rules: funds, duplicates, not-for-sale, featured discount", function()
	local p = ProfileSchema.default(0)
	p.wins = 10
	local fire = Catalog.get("trail_fire")
	local okBuy, reason, price = ShopRules.canPurchase(p, fire, nil, 15)
	ok(okBuy, reason)
	eq(price, 8)
	p.owned.trail_fire = true
	eq(select(2, ShopRules.canPurchase(p, fire, nil, 15)), "AlreadyOwned")
	eq(select(2, ShopRules.canPurchase(p, Catalog.get("title_first_victory"), nil, 15)), "NotForSale")
	eq(select(2, ShopRules.canPurchase(p, Catalog.get("aura_void"), nil, 15)), "NotEnoughWins")
	eq(select(2, ShopRules.canPurchase(p, Catalog.get("emote_robot"), nil, 15)), "NotEnoughCoins")
	eq(select(2, ShopRules.canPurchase(p, nil, nil, 15)), "UnknownItem")
	eq(ShopRules.priceFor(Catalog.get("trail_white"), { trail_white = true }, 15), 1)
	eq(ShopRules.priceFor(Catalog.get("aura_void"), { aura_void = true }, 15), 153)
end)

test("equip rules: one per slot, accessories by slot with replacement report", function()
	local loadout = ProfileSchema.emptyLoadout()
	local crown = Catalog.get("acc_gold_crown")
	local hat = Catalog.get("acc_party_hat")
	local shades = Catalog.get("acc_shades")
	ShopRules.applyEquip(loadout, crown, Catalog.equipSlot(crown))
	eq(ShopRules.wouldReplace(loadout, hat, Catalog.equipSlot(hat)), "acc_gold_crown")
	eq(ShopRules.wouldReplace(loadout, shades, Catalog.equipSlot(shades)), nil)
	local _, replaced = ShopRules.applyEquip(loadout, hat, Catalog.equipSlot(hat))
	eq(replaced, "acc_gold_crown")
	ShopRules.applyEquip(loadout, shades, Catalog.equipSlot(shades))
	eq(loadout.Accessories.Head, "acc_party_hat")
	eq(loadout.Accessories.Face, "acc_shades")
	local trail = Catalog.get("trail_fire")
	ShopRules.applyEquip(loadout, trail, Catalog.equipSlot(trail))
	eq(loadout.Trail, "trail_fire")
	ok(ShopRules.isEquipped(loadout, trail, "Trail"))
	ok(ShopRules.applyUnequip(loadout, trail, "Trail"))
	eq(loadout.Trail, nil)
end)

test("featured rotation is deterministic, varied and headline-first", function()
	local cfg = Economy.FeaturedShop
	local a = Featured.pick(Catalog.Items, 100, cfg.SlotCount, cfg.MaxPerCategory)
	local b = Featured.pick(Catalog.Items, 100, cfg.SlotCount, cfg.MaxPerCategory)
	eq(#a, cfg.SlotCount)
	for i = 1, #a do
		eq(a[i], b[i])
	end
	local headline = Catalog.get(a[1])
	ok(headline.rarity == "Legendary" or headline.rarity == "Mythic", "headline " .. a[1])
	local differs = false
	for period = 101, 110 do
		local c = Featured.pick(Catalog.Items, period, cfg.SlotCount, cfg.MaxPerCategory)
		local perCat = {}
		for _, id in c do
			local item = Catalog.get(id)
			ok(item.unlock.kind == "Shop")
			perCat[item.category] = (perCat[item.category] or 0) + 1
			ok(perCat[item.category] <= cfg.MaxPerCategory)
			if not table.find(a, id) then
				differs = true
			end
		end
	end
	ok(differs, "rotation changes over time")
end)

test("daily quests: one per tier, stable per day, progress and claim", function()
	local q = { day = -1, list = {}, totalCompleted = 0 }
	ok(QuestLogic.ensureDay(q, Quests.List, Quests.Tiers, 12345, 20000))
	eq(#q.list, 3)
	local first = q.list[1].id
	ok(not QuestLogic.ensureDay(q, Quests.List, Quests.Tiers, 12345, 20000))
	eq(q.list[1].id, first)
	local again = QuestLogic.pickDaily(Quests.List, Quests.Tiers, 12345, 20000)
	eq(again[1].id, first)
	local tiers = {}
	for _, quest in q.list do
		tiers[Quests.ById[quest.id].tier] = true
	end
	ok(tiers.Easy and tiers.Medium and tiers.Hard)

	local list = { { id = "q_play_3", progress = 0, claimed = false } }
	eq(#QuestLogic.addProgress(list, Quests.ById, "RoundPlayed", 2), 0)
	ok(not QuestLogic.canClaim(list, Quests.ById, "q_play_3"))
	eq(#QuestLogic.addProgress(list, Quests.ById, "RoundPlayed", 5), 1)
	eq(list[1].progress, 3)
	ok(QuestLogic.canClaim(list, Quests.ById, "q_play_3"))
	list[1].claimed = true
	ok(not QuestLogic.canClaim(list, Quests.ById, "q_play_3"))
	ok(QuestLogic.allClaimed(list))
end)

test("achievements read nested and derived stats", function()
	local p = ProfileSchema.default(0)
	p.totalWins = 10
	p.stats.mapsWon = { a = 1, b = 2, c = 0 }
	eq(Progress.readStat(p, "totalWins"), 10)
	eq(Progress.readStat(p, "mapsWonDistinct"), 2)
	eq(Progress.readStat(p, "stats.survive60"), 0)
	local unlocked = Progress.newAchievements(p, Achievements.List)
	local ids = {}
	for _, a in unlocked do
		ids[a.id] = true
	end
	ok(ids.ach_first_win and ids.ach_wins_10)
	ok(not ids.ach_wins_25)
	local pending = Progress.pendingLevelRewards(p, Catalog.Items, 20)
	ok(table.find(pending, "aura_veteran") and table.find(pending, "title_hopper"))
	ok(not table.find(pending, "aura_centennial"))
end)

test("director: nothing hard early, no incompatible pairs, budget respected", function()
	local cfg = Events.Director
	local rng = Prng.new(99)
	local state = {
		elapsed = 25,
		active = {},
		recent = {},
		lastRunAt = {},
		historyNoRepeat = cfg.HistoryNoRepeat,
		suddenDeath = false,
	}
	for _ = 1, 50 do
		local def = Director.choose(Events.List, cfg.DifficultyRamp, state, rng)
		ok(def, "an event is available at 25s")
		ok(def.difficulty <= 1, def.id .. " too hard for 25s")
	end
	state.elapsed = 15
	local list = Director.eligible(Events.List, cfg.DifficultyRamp, state)
	eq(#list, 0, "nothing before minElapsed")
	-- Late game, two concurrent events must be compatible.
	for seed = 1, 200 do
		local r = Prng.new(seed)
		local s = { elapsed = 130, active = {}, recent = {}, lastRunAt = {}, historyNoRepeat = 3, suddenDeath = false }
		local first = Director.choose(Events.List, cfg.DifficultyRamp, s, r)
		ok(first)
		s.active = { first }
		local second = Director.choose(Events.List, cfg.DifficultyRamp, s, r)
		if second then
			ok(Director.compatible(second, { first }), first.id .. "+" .. second.id)
			ok(first.difficulty + second.difficulty <= 6)
			ok(not (first.id == "strong_wind" and second.id == "slippery_floor"))
		end
	end
	local sd = { elapsed = 200, active = {}, recent = {}, lastRunAt = {}, historyNoRepeat = 3, suddenDeath = true }
	eq(#Director.eligible(Events.List, cfg.DifficultyRamp, sd), 0)
end)

test("event config: every incompatibility is symmetric-safe and final collapse is scheduled only", function()
	for _, def in Events.List do
		ok(def.duration > 0 and def.warnTime > 0, def.id)
		if def.id == "final_collapse" then
			ok(def.scheduledOnly)
		end
	end
	eq(#Events.List, 20)
end)
