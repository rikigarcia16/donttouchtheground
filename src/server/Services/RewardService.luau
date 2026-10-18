--!nonstrict
-- Applies round rewards exactly once per player per round (round id stored
-- in the profile), updates stats, quests and the global victories counter.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local RewardRules = require(Shared.Logic.RewardRules)
local ProfileSchema = require(Shared.Logic.ProfileSchema)
local QuestLogic = require(Shared.Logic.QuestLogic)

local RewardService = {}

local PlayerData: any
local Currency: any
local Quests: any
local Leaderboard: any

export type RoundInfo = {
	roundId: string,
	mapId: string,
	noJumpViable: boolean,
	duration: number,
	participantCount: number,
	activeCount: number,
	players: { [number]: Player },
	eventsSurvived: { [number]: number },
	jumps: { [number]: number },
	finalCollapseSurvivors: { [number]: boolean },
}

function RewardService.GrantRound(standings: { any }, info: RoundInfo): { [number]: RewardRules.Reward }
	local today = QuestLogic.dayIndex(os.time())
	local firstWinToday = {}
	for _, standing in standings do
		local player = info.players[standing.id]
		local profile = player and PlayerData.Get(player)
		if profile then
			firstWinToday[standing.id] = profile.daily.lastWinDay ~= today
		end
	end

	local rewards = RewardRules.compute({
		standings = standings,
		participantCount = info.participantCount,
		activeCount = info.activeCount,
		duration = info.duration,
		firstWinToday = firstWinToday,
	}, {
		rewards = EconomyConfig.Rewards,
		minActiveForWin = GameConfig.Round.MinActiveForWin,
		minRoundTimeForWin = GameConfig.Round.MinRoundTimeForWin,
	})

	local competitive = info.participantCount >= 2
	local anyWin = false

	for _, standing in standings do
		local player = info.players[standing.id]
		local reward = rewards[standing.id]
		if not player or not player.Parent or not reward or standing.left then
			continue
		end
		local fresh = false
		PlayerData.Update(player, { "stats", "daily" }, function(p)
			fresh = ProfileSchema.markRoundProcessed(p, info.roundId)
			if not fresh then
				return
			end
			local stats = p.stats
			stats.roundsPlayed += 1
			if competitive and standing.active then
				stats.roundsCompetitive += 1
				stats.timeSurvived += math.floor(standing.survived)
				stats.bestSurvival = math.max(stats.bestSurvival, math.floor(standing.survived))
				if standing.survived >= 60 then
					stats.survive60 += 1
				end
				if standing.placement <= 3 then
					stats.podiums += 1
				end
				stats.eventsSurvived += info.eventsSurvived[standing.id] or 0
				if info.finalCollapseSurvivors[standing.id] then
					stats.finalCollapseSurvived += 1
				end
				if reward.countedWin then
					stats.mapsWon[info.mapId] = (stats.mapsWon[info.mapId] or 0) + 1
					p.daily.lastWinDay = today
					if info.noJumpViable and (info.jumps[standing.id] or 0) == 0 then
						stats.winsWithoutJump += 1
					end
				end
			end
		end)
		if not fresh then
			warn("[Rewards] duplicate grant blocked for " .. player.Name .. " round " .. info.roundId)
			rewards[standing.id] = { wins = 0, coins = 0, xp = 0, lines = {}, countedWin = false }
			continue
		end

		Currency.Grant(player, {
			wins = reward.wins,
			coins = reward.coins,
			xp = reward.xp,
			victories = if reward.countedWin then 1 else 0,
		}, "round:" .. info.roundId)

		if reward.countedWin then
			anyWin = true
		end

		if competitive and standing.active then
			Quests.AddProgress(player, "RoundPlayed", 1)
			Quests.AddProgress(player, "SurviveSeconds", standing.survived)
			if standing.survived >= 60 then
				Quests.AddProgress(player, "Survive60", 1)
			end
			if standing.placement <= 3 then
				Quests.AddProgress(player, "Top3", 1)
			end
			if reward.countedWin then
				Quests.AddProgress(player, "Win", 1)
			end
			local events = info.eventsSurvived[standing.id] or 0
			if events > 0 then
				Quests.AddProgress(player, "EventSurvived", events)
			end
		end
	end

	if anyWin then
		Leaderboard.CountGlobalWin()
	end
	return rewards
end

function RewardService.Init(services)
	PlayerData = services.PlayerDataService
	Currency = services.CurrencyService
	Quests = services.QuestService
	Leaderboard = services.LeaderboardService
end

return RewardService
