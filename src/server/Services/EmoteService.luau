--!nonstrict
-- Validates emote requests (owned, character alive, grounded during rounds)
-- and publishes the active emote as character attributes. Every client then
-- animates it procedurally; emotes never touch the hitbox or movement.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local Remotes = require(Shared.Net.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)

local EmoteService = {}

local PlayerData: any

function EmoteService.Stop(player: Player)
	local character = player.Character
	if character then
		character:SetAttribute("Emote", nil)
		character:SetAttribute("EmoteStart", nil)
	end
end

function EmoteService.Init(services)
	PlayerData = services.PlayerDataService
end

function EmoteService.Start()
	Guard.event(Remotes.event("EmoteRequest"), { "string" }, 3, function(player, emoteId)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not humanoid or humanoid.Health <= 0 then
			return
		end
		if emoteId == "" then
			EmoteService.Stop(player)
			return
		end
		local item = CosmeticCatalog.get(emoteId)
		local profile = PlayerData.Get(player)
		if not item or item.category ~= "Emote" or not profile or not profile.owned[emoteId] then
			return
		end
		local state = game:GetService("ReplicatedStorage"):FindFirstChild("RoundState")
		local roundState = if state then state:GetAttribute("State") else "Lobby"
		if player:GetAttribute("InRound") then
			-- Only while standing still on solid ground, never in the preparation freeze.
			if roundState == "Preparation" or humanoid.FloorMaterial == Enum.Material.Air then
				return
			end
		end
		character:SetAttribute("Emote", emoteId)
		character:SetAttribute("EmoteStart", workspace:GetServerTimeNow())
	end)
end

return EmoteService
