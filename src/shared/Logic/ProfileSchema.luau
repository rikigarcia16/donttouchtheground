--!strict
-- Versioned player profile. `load` turns anything read from the DataStore
-- (missing, old, partially corrupt) into a valid current-version profile.

local ProfileSchema = {}

ProfileSchema.VERSION = 2

ProfileSchema.EQUIP_SLOTS = {
	"Trail",
	"Aura",
	"JumpEffect",
	"LandingEffect",
	"DeathEffect",
	"WinAnimation",
	"Title",
	"Podium",
}

ProfileSchema.ACCESSORY_SLOTS = { "Head", "Face", "Back", "Shoulders", "Feet", "Float" }

local QUALITY_LEVELS = { Auto = true, Low = true, Medium = true, High = true }

function ProfileSchema.emptyLoadout(): { [string]: any }
	return { Accessories = {} }
end

function ProfileSchema.default(now: number): { [string]: any }
	return {
		version = ProfileSchema.VERSION,
		wins = 0, -- spendable
		totalWins = 0, -- lifetime, never decreases
		coins = 0,
		totalCoins = 0,
		xp = 0,
		level = 1,
		owned = {},
		favorites = {},
		equipped = ProfileSchema.emptyLoadout(),
		presets = {},
		achievements = {},
		quests = { day = -1, list = {}, totalCompleted = 0 },
		stats = {
			roundsPlayed = 0,
			roundsCompetitive = 0,
			timeSurvived = 0,
			bestSurvival = 0,
			survive60 = 0,
			podiums = 0,
			eventsSurvived = 0,
			finalCollapseSurvived = 0,
			winsWithoutJump = 0,
			mapsWon = {},
			purchases = 0,
		},
		daily = { lastWinDay = -1 },
		claimedCollections = {},
		processedRounds = {}, -- round ids already rewarded (anti-duplication), trimmed
		settings = {
			quality = "Auto",
			music = 0.5,
			sfx = 0.8,
			showOthersEffects = true,
			reduceFlashing = false,
		},
		meta = { created = now, lastSeen = now, saves = 0 },
	}
end

local function sanitizeCount(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return math.max(0, math.floor(value))
end

local function sanitizeFraction(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value then
		return fallback
	end
	return math.clamp(value, 0, 1)
end

local function sanitizeIdMap(value: any, validIds: { [string]: any }?): { [string]: any }
	local out = {}
	if type(value) ~= "table" then
		return out
	end
	for key, entry in value do
		if type(key) == "string" and (validIds == nil or validIds[key] ~= nil) then
			out[key] = if type(entry) == "number" or entry == true then entry else true
		end
	end
	return out
end

local function sanitizeLoadout(value: any, validIds: { [string]: any }?): { [string]: any }
	local loadout = ProfileSchema.emptyLoadout()
	if type(value) ~= "table" then
		return loadout
	end
	for _, slot in ProfileSchema.EQUIP_SLOTS do
		local id = value[slot]
		if type(id) == "string" and (validIds == nil or validIds[id] ~= nil) then
			loadout[slot] = id
		end
	end
	if type(value.Accessories) == "table" then
		for _, slot in ProfileSchema.ACCESSORY_SLOTS do
			local id = value.Accessories[slot]
			if type(id) == "string" and (validIds == nil or validIds[id] ~= nil) then
				loadout.Accessories[slot] = id
			end
		end
	end
	return loadout
end

-- Migrations run in order; each receives data at version N-1 and returns N.
local MIGRATIONS: { [number]: (data: { [string]: any }) -> { [string]: any } } = {
	-- v1 stored a single `wins` counter for both spendable and lifetime wins.
	[2] = function(data)
		if data.totalWins == nil and type(data.wins) == "number" then
			data.totalWins = data.wins
		end
		if type(data.equipped) == "table" and type(data.equipped.Accessory) == "string" then
			data.equipped.Accessories = { Head = data.equipped.Accessory }
			data.equipped.Accessory = nil
		end
		return data
	end,
}

-- validIds: catalogue ids, used to drop items that no longer exist.
function ProfileSchema.load(raw: any, now: number, validIds: { [string]: any }?): ({ [string]: any }, { string })
	local notes = {}
	local base = ProfileSchema.default(now)
	if type(raw) ~= "table" then
		return base, notes
	end

	local data = table.clone(raw)
	local version = if type(data.version) == "number" then data.version else 1
	if version > ProfileSchema.VERSION then
		-- Written by a newer server build. Keep it, but never downgrade the field.
		table.insert(notes, "newer-version")
	end
	while version < ProfileSchema.VERSION do
		version += 1
		local migrate = MIGRATIONS[version]
		if migrate then
			data = migrate(data)
			table.insert(notes, "migrated-to-" .. version)
		end
	end

	local profile = base
	profile.version = math.max(ProfileSchema.VERSION, if type(raw.version) == "number" then raw.version else 0)
	profile.wins = sanitizeCount(data.wins, 0)
	profile.totalWins = math.max(sanitizeCount(data.totalWins, 0), 0)
	profile.coins = sanitizeCount(data.coins, 0)
	profile.totalCoins = math.max(sanitizeCount(data.totalCoins, 0), profile.coins)
	profile.xp = sanitizeCount(data.xp, 0)
	profile.level = math.max(1, sanitizeCount(data.level, 1))
	profile.owned = sanitizeIdMap(data.owned, validIds)
	profile.favorites = sanitizeIdMap(data.favorites, validIds)
	profile.equipped = sanitizeLoadout(data.equipped, validIds)

	if type(data.presets) == "table" then
		for i = 1, 10 do
			local preset = data.presets[i]
			if type(preset) == "table" then
				profile.presets[i] = {
					name = if type(preset.name) == "string" then string.sub(preset.name, 1, 20) else ("Preset " .. i),
					loadout = sanitizeLoadout(preset.loadout, validIds),
					empty = preset.empty == true,
				}
			else
				break
			end
		end
	end

	profile.achievements = sanitizeIdMap(data.achievements, nil)
	profile.claimedCollections = sanitizeIdMap(data.claimedCollections, nil)

	if type(data.quests) == "table" then
		profile.quests.day = if type(data.quests.day) == "number" then data.quests.day else -1
		profile.quests.totalCompleted = sanitizeCount(data.quests.totalCompleted, 0)
		if type(data.quests.list) == "table" then
			for _, quest in data.quests.list do
				if type(quest) == "table" and type(quest.id) == "string" then
					table.insert(profile.quests.list, {
						id = quest.id,
						progress = sanitizeCount(quest.progress, 0),
						claimed = quest.claimed == true,
					})
				end
			end
		end
	end

	if type(data.stats) == "table" then
		for key, default in profile.stats do
			if type(default) == "number" then
				profile.stats[key] = sanitizeCount(data.stats[key], default)
			end
		end
		if type(data.stats.mapsWon) == "table" then
			for mapId, count in data.stats.mapsWon do
				if type(mapId) == "string" then
					profile.stats.mapsWon[mapId] = sanitizeCount(count, 0)
				end
			end
		end
	end

	if type(data.daily) == "table" and type(data.daily.lastWinDay) == "number" then
		profile.daily.lastWinDay = data.daily.lastWinDay
	end

	if type(data.processedRounds) == "table" then
		for _, roundId in data.processedRounds do
			if type(roundId) == "string" then
				table.insert(profile.processedRounds, roundId)
			end
		end
	end

	if type(data.settings) == "table" then
		local s = data.settings
		profile.settings.quality = if type(s.quality) == "string" and QUALITY_LEVELS[s.quality]
			then s.quality
			else "Auto"
		profile.settings.music = sanitizeFraction(s.music, 0.5)
		profile.settings.sfx = sanitizeFraction(s.sfx, 0.8)
		profile.settings.showOthersEffects = s.showOthersEffects ~= false
		profile.settings.reduceFlashing = s.reduceFlashing == true
	end

	if type(data.meta) == "table" then
		profile.meta.created = if type(data.meta.created) == "number" then data.meta.created else now
		profile.meta.saves = sanitizeCount(data.meta.saves, 0)
	end
	profile.meta.lastSeen = now

	-- An equipped item must be owned.
	for _, slot in ProfileSchema.EQUIP_SLOTS do
		local id = profile.equipped[slot]
		if id and not profile.owned[id] then
			profile.equipped[slot] = nil
			table.insert(notes, "unequipped-unowned-" .. id)
		end
	end
	for slot, id in profile.equipped.Accessories do
		if not profile.owned[id] then
			profile.equipped.Accessories[slot] = nil
		end
	end

	return profile, notes
end

ProfileSchema.MAX_PROCESSED_ROUNDS = 30

function ProfileSchema.markRoundProcessed(profile: { [string]: any }, roundId: string): boolean
	if table.find(profile.processedRounds, roundId) then
		return false
	end
	table.insert(profile.processedRounds, roundId)
	while #profile.processedRounds > ProfileSchema.MAX_PROCESSED_ROUNDS do
		table.remove(profile.processedRounds, 1)
	end
	return true
end

return ProfileSchema
