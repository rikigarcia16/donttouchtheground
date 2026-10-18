--!nonstrict
-- Evaluates achievements, level rewards and collection completion after any
-- profile change. Rewards are cosmetics (never gameplay advantages) and coins.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AchievementConfig = require(Shared.Config.AchievementConfig)
local CollectionConfig = require(Shared.Config.CollectionConfig)
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local ProgressLogic = require(Shared.Logic.ProgressLogic)
local Remotes = require(Shared.Net.Remotes)

local AchievementService = {}

local PlayerData: any
local Currency: any
local Cosmetics: any
local notify: RemoteEvent
local checking: { [Player]: boolean } = {}
local pendingRecheck: { [Player]: boolean } = {}

local function check(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end

	for _, achievement in ProgressLogic.newAchievements(profile, AchievementConfig.List :: any) do
		PlayerData.Update(player, { "achievements" }, function(p)
			p.achievements[achievement.id] = os.time()
		end)
		notify:FireClient(player, { kind = "Achievement", achievementId = achievement.id })
		for _, reward in achievement.rewards do
			Cosmetics.Grant(player, reward, "Achievement")
		end
		if achievement.coins then
			Currency.Grant(player, { coins = achievement.coins }, "achievement:" .. achievement.id)
		end
	end

	for _, itemId in ProgressLogic.pendingLevelRewards(profile, CosmeticCatalog.Items :: any, profile.level) do
		Cosmetics.Grant(player, itemId, "Level")
	end

	-- Tell the player once when a collection becomes claimable.
	for _, collection in CollectionConfig.List do
		if not profile.claimedCollections[collection.id] then
			local members = ProgressLogic.collectionMembers(CosmeticCatalog.Items :: any, collection.id)
			local owned, total = ProgressLogic.collectionProgress(profile, members)
			if owned == total and total > 0 then
				local flag = "CollectionReady_" .. collection.id
				if not player:GetAttribute(flag) then
					player:SetAttribute(flag, true)
					notify:FireClient(player, { kind = "CollectionReady", collectionId = collection.id })
				end
			end
		end
	end
end

-- Coalesces bursts of profile changes into one evaluation.
function AchievementService.Check(player: Player)
	if checking[player] then
		pendingRecheck[player] = true
		return
	end
	checking[player] = true
	task.defer(function()
		repeat
			pendingRecheck[player] = nil
			local ok, err = pcall(function()
				check(player)
			end)
			if not ok then
				warn("[Achievements] " .. tostring(err))
			end
		until not pendingRecheck[player] or not player.Parent
		checking[player] = nil
	end)
end

function AchievementService.Init(services)
	PlayerData = services.PlayerDataService
	Currency = services.CurrencyService
	Cosmetics = services.CosmeticService
	notify = Remotes.event("Notify")
end

function AchievementService.Start()
	PlayerData.ProfileLoaded:Connect(AchievementService.Check)
	PlayerData.ProfileChanged:Connect(function(player, _profile, keys)
		if keys == nil then
			AchievementService.Check(player)
			return
		end
		for _, key in keys do
			if key == "totalWins" or key == "stats" or key == "owned" or key == "level" or key == "quests" then
				AchievementService.Check(player)
				return
			end
		end
	end)
	Currency.LevelUp:Connect(function(player, newLevel)
		notify:FireClient(player, { kind = "LevelUp", level = newLevel })
	end)
end

return AchievementService
