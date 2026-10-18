--!nonstrict
-- Daily quests. Progress is fed by RewardService from server-observed round
-- facts only; claiming is validated here.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local QuestConfig = require(Shared.Config.QuestConfig)
local QuestLogic = require(Shared.Logic.QuestLogic)
local Remotes = require(Shared.Net.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)

local QuestService = {}

local PlayerData: any
local Currency: any
local notify: RemoteEvent

local function ensureDay(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local day = QuestLogic.dayIndex(os.time())
	if profile.quests.day ~= day or #profile.quests.list == 0 then
		PlayerData.Update(player, { "quests" }, function(p)
			QuestLogic.ensureDay(p.quests, QuestConfig.List :: any, QuestConfig.Tiers, player.UserId, day)
		end)
	end
end

function QuestService.AddProgress(player: Player, event: string, amount: number)
	ensureDay(player)
	local completed = {}
	PlayerData.Update(player, { "quests" }, function(p)
		completed = QuestLogic.addProgress(p.quests.list, QuestConfig.ById :: any, event, amount)
	end)
	for _, questId in completed do
		notify:FireClient(player, { kind = "QuestComplete", questId = questId })
	end
end

function QuestService.Claim(player: Player, questId: string): { [string]: any }
	ensureDay(player)
	local profile = PlayerData.Get(player)
	if not profile then
		return { ok = false, reason = "NotLoaded" }
	end
	local template = QuestConfig.ById[questId]
	local claimable = QuestLogic.canClaim(profile.quests.list, QuestConfig.ById :: any, questId)
	if not claimable or not template then
		return { ok = false, reason = "NotClaimable" }
	end
	local claimed, allDone = false, false
	PlayerData.Update(player, { "quests" }, function(p: any)
		local ok, quest = QuestLogic.canClaim(p.quests.list, QuestConfig.ById :: any, questId)
		if ok and quest then
			quest.claimed = true
			p.quests.totalCompleted += 1
			claimed = true
			allDone = QuestLogic.allClaimed(p.quests.list)
		end
	end)
	if not claimed then
		return { ok = false, reason = "NotClaimable" }
	end
	Currency.Grant(player, { coins = template.coins, xp = template.xp }, "quest:" .. questId)
	if allDone then
		Currency.Grant(player, QuestConfig.AllCompleteBonus, "quest:all")
	end
	return { ok = true, coins = template.coins, xp = template.xp, allDone = allDone }
end

function QuestService.Init(services)
	PlayerData = services.PlayerDataService
	Currency = services.CurrencyService
	notify = Remotes.event("Notify")
end

function QuestService.Start()
	PlayerData.ProfileLoaded:Connect(ensureDay)
	Guard.func(Remotes.func("ClaimQuest"), { "string" }, 2, function(player, questId)
		local ran, result = Guard.exclusive(player, function()
			return QuestService.Claim(player, questId)
		end)
		return if ran then result else { ok = false, reason = "Busy" }
	end)
	-- Roll quests over at UTC midnight for players who stay online.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in game:GetService("Players"):GetPlayers() do
				ensureDay(player)
			end
		end
	end)
end

return QuestService
