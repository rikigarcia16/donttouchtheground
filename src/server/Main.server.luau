--!nonstrict
-- Server bootstrap: create remotes, then Init every service (wiring only, no
-- yielding), then Start them (loops, connections). Order matters only for Start.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)

Remotes.setupServer()

local Services = script.Parent:WaitForChild("Services")

local ORDER = {
	"PlayerDataService",
	"CurrencyService",
	"CosmeticService",
	"InventoryService",
	"EquipmentService",
	"ShopService",
	"AchievementService",
	"QuestService",
	"LeaderboardService",
	"LobbyService",
	"MapService",
	"HazardService",
	"EventService",
	"RewardService",
	"EmoteService",
	"FXService",
	"RoundService",
	"AdminService",
}

local registry: { [string]: any } = {}
for _, name in ORDER do
	local module = Services:FindFirstChild(name)
	assert(module and module:IsA("ModuleScript"), "Missing service " .. name)
	registry[name] = require(module) :: any
end

for _, name in ORDER do
	local service = registry[name]
	if service.Init then
		service.Init(registry)
	end
end

for _, name in ORDER do
	local service = registry[name]
	if service.Start then
		local ok, err = pcall(service.Start)
		if not ok then
			warn(string.format("[Main] %s.Start failed: %s", name, tostring(err)))
		end
	end
end

print("[DTTG] server ready")
