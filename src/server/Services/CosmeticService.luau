--!nonstrict
-- Grants cosmetics and mirrors the equipped loadout onto the character as
-- attributes. Every client renders cosmetics from those attributes (see
-- client CosmeticRenderer), so nothing visual is created on the server.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local ProfileSchema = require(Shared.Logic.ProfileSchema)
local Signal = require(Shared.Util.Signal)
local Remotes = require(Shared.Net.Remotes)

local CosmeticService = {}
CosmeticService.ItemGranted = Signal.new() -- (player, itemId, source)

local PlayerData: any
local notify: RemoteEvent

-- Equipped attribute names on the character, e.g. "Cos_Trail", "Cos_Acc_Head".
function CosmeticService.attributeFor(slot: string): string
	return "Cos_" .. slot
end

function CosmeticService.ApplyToCharacter(player: Player)
	local character = player.Character
	local profile = PlayerData.Get(player)
	if not character or not profile then
		return
	end
	local loadout = profile.equipped
	for _, slot in ProfileSchema.EQUIP_SLOTS do
		character:SetAttribute(CosmeticService.attributeFor(slot), loadout[slot])
	end
	for _, slot in ProfileSchema.ACCESSORY_SLOTS do
		character:SetAttribute(CosmeticService.attributeFor("Acc_" .. slot), loadout.Accessories[slot])
	end
	character:SetAttribute("Level", profile.level)
	character:SetAttribute("OwnerUserId", player.UserId)
end

function CosmeticService.Owns(player: Player, itemId: string): boolean
	local profile = PlayerData.Get(player)
	return profile ~= nil and profile.owned[itemId] ~= nil
end

-- Grants an unlockable item (achievement, collection, level...). Idempotent.
function CosmeticService.Grant(player: Player, itemId: string, source: string): boolean
	local item = CosmeticCatalog.get(itemId)
	if not item then
		warn("[Cosmetic] unknown item " .. itemId)
		return false
	end
	local profile = PlayerData.Get(player)
	if not profile or profile.owned[itemId] then
		return false
	end
	local granted = false
	PlayerData.Update(player, { "owned" }, function(p)
		if not p.owned[itemId] then
			p.owned[itemId] = os.time()
			granted = true
		end
	end)
	if granted then
		notify:FireClient(player, { kind = "Unlock", itemId = itemId, source = source })
		CosmeticService.ItemGranted:Fire(player, itemId, source)
	end
	return granted
end

function CosmeticService.Init(services)
	PlayerData = services.PlayerDataService
	notify = Remotes.event("Notify")
end

function CosmeticService.Start()
	local function hook(player: Player)
		player.CharacterAdded:Connect(function()
			CosmeticService.ApplyToCharacter(player)
		end)
		if player.Character then
			CosmeticService.ApplyToCharacter(player)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
	PlayerData.ProfileLoaded:Connect(function(player)
		CosmeticService.ApplyToCharacter(player)
	end)
end

return CosmeticService
