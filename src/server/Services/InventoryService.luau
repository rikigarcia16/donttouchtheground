--!nonstrict
-- Favourites, cosmetic presets and collection reward claims.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local CollectionConfig = require(Shared.Config.CollectionConfig)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local ProfileSchema = require(Shared.Logic.ProfileSchema)
local ProgressLogic = require(Shared.Logic.ProgressLogic)
local Remotes = require(Shared.Net.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)

local InventoryService = {}

local PlayerData: any
local Cosmetics: any

local function cloneLoadout(loadout: { [string]: any }): { [string]: any }
	local copy = table.clone(loadout)
	copy.Accessories = table.clone(loadout.Accessories or {})
	return copy
end

function InventoryService.ToggleFavorite(player: Player, itemId: string, value: boolean?): { [string]: any }
	if not CosmeticCatalog.get(itemId) then
		return { ok = false, reason = "UnknownItem" }
	end
	local result = false
	PlayerData.Update(player, { "favorites" }, function(p)
		local count = 0
		for _ in p.favorites do
			count += 1
		end
		local newValue = if value == nil then not p.favorites[itemId] else value
		if newValue and count >= 100 then
			return
		end
		p.favorites[itemId] = if newValue then true else nil
		result = newValue
	end)
	return { ok = true, favorite = result }
end

function InventoryService.SavePreset(player: Player, slot: number, name: string?): { [string]: any }
	slot = math.floor(slot)
	if slot < 1 or slot > EconomyConfig.Presets.Slots then
		return { ok = false, reason = "BadSlot" }
	end
	PlayerData.Update(player, { "presets" }, function(p)
		-- Fill earlier slots so the array never has holes (DataStore-safe).
		for i = 1, slot - 1 do
			if not p.presets[i] then
				p.presets[i] = { name = "Preset " .. i, loadout = ProfileSchema.emptyLoadout(), empty = true }
			end
		end
		local cleanName = if name and #name > 0 then string.sub(name, 1, 20) else ("Preset " .. slot)
		p.presets[slot] = { name = cleanName, loadout = cloneLoadout(p.equipped), empty = false }
	end)
	return { ok = true }
end

function InventoryService.LoadPreset(player: Player, slot: number): { [string]: any }
	local profile = PlayerData.Get(player)
	if not profile then
		return { ok = false, reason = "NotLoaded" }
	end
	local preset = profile.presets[math.floor(slot)]
	if not preset or preset.empty then
		return { ok = false, reason = "EmptyPreset" }
	end
	PlayerData.Update(player, { "equipped" }, function(p)
		local loadout = ProfileSchema.emptyLoadout()
		-- Only re-equip items still owned.
		for _, key in ProfileSchema.EQUIP_SLOTS do
			local id = preset.loadout[key]
			if id and p.owned[id] then
				loadout[key] = id
			end
		end
		for accessorySlot, id in preset.loadout.Accessories do
			if p.owned[id] then
				loadout.Accessories[accessorySlot] = id
			end
		end
		p.equipped = loadout
	end)
	Cosmetics.ApplyToCharacter(player)
	return { ok = true }
end

function InventoryService.ClaimCollection(player: Player, collectionId: string): { [string]: any }
	local collection = CollectionConfig.ById[collectionId]
	local profile = PlayerData.Get(player)
	if not collection or not profile then
		return { ok = false, reason = "Unknown" }
	end
	if profile.claimedCollections[collectionId] then
		return { ok = false, reason = "AlreadyClaimed" }
	end
	local members = ProgressLogic.collectionMembers(CosmeticCatalog.Items :: any, collectionId)
	local owned, total = ProgressLogic.collectionProgress(profile, members)
	if owned < total then
		return { ok = false, reason = "Incomplete" }
	end
	PlayerData.Update(player, { "claimedCollections" }, function(p)
		p.claimedCollections[collectionId] = os.time()
	end)
	Cosmetics.Grant(player, collection.reward, "Collection")
	return { ok = true, reward = collection.reward }
end

function InventoryService.Init(services)
	PlayerData = services.PlayerDataService
	Cosmetics = services.CosmeticService
end

function InventoryService.Start()
	Guard.func(Remotes.func("ToggleFavorite"), { "string", "boolean?" }, 6, function(player, itemId, value)
		return InventoryService.ToggleFavorite(player, itemId, value)
	end)
	Guard.func(Remotes.func("SavePreset"), { "number", "string?" }, 2, function(player, slot, name)
		return InventoryService.SavePreset(player, slot, name)
	end)
	Guard.func(Remotes.func("LoadPreset"), { "number" }, 2, function(player, slot)
		return InventoryService.LoadPreset(player, slot)
	end)
	Guard.func(Remotes.func("ClaimCollection"), { "string" }, 2, function(player, collectionId)
		local _, result = Guard.exclusive(player, function()
			return InventoryService.ClaimCollection(player, collectionId)
		end)
		return result or { ok = false, reason = "Busy" }
	end)
end

return InventoryService
