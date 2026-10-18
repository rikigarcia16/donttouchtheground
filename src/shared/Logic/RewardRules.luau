--!strict
-- Turns round standings into rewards. Pure: the RewardService feeds it facts
-- gathered on the server and applies the result exactly once per round.

local RewardRules = {}

export type Line = { label: string, wins: number, coins: number, xp: number }
export type Reward = { wins: number, coins: number, xp: number, lines: { Line }, countedWin: boolean }

export type Input = {
	standings: {
		{
			id: number,
			placement: number,
			survived: number,
			isWinner: boolean,
			isDraw: boolean,
			left: boolean,
			active: boolean,
		}
	},
	participantCount: number,
	activeCount: number,
	duration: number,
	firstWinToday: { [number]: boolean },
}

export type Config = {
	rewards: any,
	minActiveForWin: number,
	minRoundTimeForWin: number,
}

local function add(reward: Reward, label: string, values: { wins: number?, coins: number?, xp: number? })
	local line = { label = label, wins = values.wins or 0, coins = values.coins or 0, xp = values.xp or 0 }
	reward.wins += line.wins
	reward.coins += line.coins
	reward.xp += line.xp
	table.insert(reward.lines, line)
end

function RewardRules.isWinEligible(input: Input, config: Config): boolean
	return input.participantCount >= 2
		and input.activeCount >= config.minActiveForWin
		and input.duration >= config.minRoundTimeForWin
end

function RewardRules.compute(input: Input, config: Config): { [number]: Reward }
	local R = config.rewards
	local results: { [number]: Reward } = {}
	local training = input.participantCount <= 1
	local winEligible = RewardRules.isWinEligible(input, config)

	for _, standing in input.standings do
		local reward: Reward = { wins = 0, coins = 0, xp = 0, lines = {}, countedWin = false }
		results[standing.id] = reward

		if standing.left then
			continue
		end
		if not standing.active then
			add(reward, "Inactive — no rewards", {})
			continue
		end
		if training then
			add(reward, "Training run", { xp = R.Training.xp })
			continue
		end

		add(reward, "Participation", { coins = R.Participation.coins, xp = R.Participation.xp })

		if standing.isWinner then
			if winEligible then
				add(reward, "Victory!", { wins = R.Win.wins, coins = R.Win.coins, xp = R.Win.xp })
				reward.countedWin = true
				if input.firstWinToday[standing.id] then
					add(reward, "First win of the day", { wins = R.FirstWinOfDay.wins })
				end
			else
				add(reward, "Victory (not ranked: too few active players)", { xp = R.Second.xp })
			end
		elseif standing.isDraw then
			if winEligible then
				add(reward, "Draw — last ones standing", { coins = R.Draw.coins, xp = R.Draw.xp })
			end
		elseif standing.placement == 2 then
			add(reward, "2nd place", { coins = R.Second.coins, xp = R.Second.xp })
		elseif standing.placement == 3 then
			add(reward, "3rd place", { coins = R.Third.coins, xp = R.Third.xp })
		end

		if standing.survived >= 60 then
			add(reward, "Survived 60s", { coins = R.Survive60.coins, xp = R.Survive60.xp })
			local extra = math.floor((standing.survived - 60) / 30)
			if extra > 0 then
				add(reward, string.format("Endurance x%d", extra), {
					coins = extra * R.SurvivePerExtra30.coins,
					xp = extra * R.SurvivePerExtra30.xp,
				})
			end
		end
	end

	return results
end

return RewardRules
