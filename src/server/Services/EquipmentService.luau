--!nonstrict
-- Equip / unequip with server-side ownership checks. One item per slot;
-- accessories are per accessory slot and report what they replaced.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local ShopRules = require(Shared.Logic.ShopRules)
local Remotes = require(Shared.Net.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)

local EquipmentService = {}

local PlayerData: any
local Cosmetics: any

function EquipmentService.Equip(player: Player, itemId: string): { [string]: any }
	local item = CosmeticCatalog.get(itemId)
	if not item then
		return { ok = false, reason = "UnknownItem" }
	end
	if item.category == "Emote" then
		return { ok = false, reason = "NotEquippable" }
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return { ok = false, reason = "NotLoaded" }
	end
	if not profile.owned[itemId] then
		return { ok = false, reason = "NotOwned" }
	end
	local replaced: string? = nil
	local applied = false
	PlayerData.Update(player, { "equipped" }, function(p)
		applied, replaced = ShopRules.applyEquip(p.equipped, item, CosmeticCatalog.equipSlot(item))
	end)
	if not applied then
		return { ok = false, reason = "NoSlot" }
	end
	Cosmetics.ApplyToCharacter(player)
	return { ok = true, replaced = replaced }
end

function EquipmentService.Unequip(player: Player, itemId: string): { [string]: any }
	local item = CosmeticCatalog.get(itemId)
	if not item then
		return { ok = false, reason = "UnknownItem" }
	end
	local removed = false
	PlayerData.Update(player, { "equipped" }, function(p)
		removed = ShopRules.applyUnequip(p.equipped, item, CosmeticCatalog.equipSlot(item))
	end)
	Cosmetics.ApplyToCharacter(player)
	return { ok = removed, reason = if removed then nil else "NotEquipped" }
end

function EquipmentService.Init(services)
	PlayerData = services.PlayerDataService
	Cosmetics = services.CosmeticService
end

function EquipmentService.Start()
	Guard.func(Remotes.func("Equip"), { "string" }, 4, function(player, itemId)
		return EquipmentService.Equip(player, itemId)
	end)
	Guard.func(Remotes.func("Unequip"), { "string" }, 4, function(player, itemId)
		return EquipmentService.Unequip(player, itemId)
	end)
end

return EquipmentService
