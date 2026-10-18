--!nonstrict
-- Relays cosmetic effects. A client reports its own jump/landing (rate
-- limited); the server attaches the *server-known* equipped effect and
-- forwards it to the other clients. Elimination effects come from the server.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)
local Remotes = require(Shared.Net.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)

local FXService = {}
FXService.Jumped = Signal.new() -- (player)

local PlayerData: any
local fx: RemoteEvent

local function othersOf(player: Player): { Player }
	local list = {}
	for _, other in Players:GetPlayers() do
		if other ~= player then
			table.insert(list, other)
		end
	end
	return list
end

function FXService.PlayDeath(player: Player, position: Vector3)
	local profile = PlayerData.Get(player)
	local effectId = if profile then profile.equipped.DeathEffect else nil
	fx:FireAllClients({ kind = "Death", userId = player.UserId, effectId = effectId, position = position })
end

function FXService.Init(services)
	PlayerData = services.PlayerDataService
	fx = Remotes.event("FX")
end

function FXService.Start()
	Guard.event(fx, { "string" }, 5, function(player, kind)
		if kind ~= "Jump" and kind ~= "Land" then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return
		end
		if kind == "Jump" then
			FXService.Jumped:Fire(player)
		end
		local profile = PlayerData.Get(player)
		if not profile then
			return
		end
		local effectId = if kind == "Jump" then profile.equipped.JumpEffect else profile.equipped.LandingEffect
		if not effectId then
			return
		end
		local payload = { kind = kind, userId = player.UserId, effectId = effectId, position = root.Position }
		for _, other in othersOf(player) do
			fx:FireClient(other, payload)
		end
	end)
end

return FXService
