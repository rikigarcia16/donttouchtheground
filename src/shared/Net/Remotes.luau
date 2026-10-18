--!strict
-- Every remote in one place. The server creates them; clients wait for them.
-- Client -> server payloads are always validated by the receiving service.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

Remotes.Events = {
	"DataSync", -- S->C profile snapshot / partial update
	"RoundEvent", -- S->C round lifecycle messages
	"FX", -- C->S own jump/land; S->C cosmetic effects of others
	"EmoteRequest", -- C->S play/stop emote
	"MapVote", -- C->S vote for a map option
	"Knockback", -- S->C apply an impulse to own character
	"Notify", -- S->C toast (achievement, quest, unlock)
	"SettingsUpdate", -- C->S persisted settings
}

Remotes.Functions = {
	"GetBootstrap", -- C->S initial profile, featured shop, server time info
	"Purchase",
	"Equip",
	"Unequip",
	"ToggleFavorite",
	"SavePreset",
	"LoadPreset",
	"ClaimQuest",
	"ClaimCollection",
}

local FOLDER_NAME = "Remotes"

function Remotes.setupServer()
	assert(RunService:IsServer(), "setupServer is server-only")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, name in Remotes.Events do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	for _, name in Remotes.Functions do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteFunction")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

local function folder(): Instance
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		assert(existing, "Remotes.setupServer() must run first")
		return existing
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

function Remotes.event(name: string): RemoteEvent
	assert(table.find(Remotes.Events, name), "Unknown RemoteEvent " .. name)
	local remote = if RunService:IsServer() then folder():FindFirstChild(name) else folder():WaitForChild(name)
	return remote :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	assert(table.find(Remotes.Functions, name), "Unknown RemoteFunction " .. name)
	local remote = if RunService:IsServer() then folder():FindFirstChild(name) else folder():WaitForChild(name)
	return remote :: RemoteFunction
end

return Remotes
