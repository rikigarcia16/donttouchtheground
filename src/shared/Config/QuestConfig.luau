--!strict
-- Daily quests: one per tier is drawn each UTC day, deterministically per player.
-- Progress only comes from server-observed round facts (see QuestService).

export type QuestTemplate = {
	id: string,
	tier: "Easy" | "Medium" | "Hard",
	description: string,
	event: "RoundPlayed" | "SurviveSeconds" | "Survive60" | "Top3" | "Win" | "EventSurvived",
	target: number,
	coins: number,
	xp: number,
}

local list: { QuestTemplate } = {
	{
		id = "q_play_3",
		tier = "Easy",
		description = "Play 3 rounds",
		event = "RoundPlayed",
		target = 3,
		coins = 60,
		xp = 40,
	},
	{
		id = "q_survive_120",
		tier = "Easy",
		description = "Survive 120 seconds in total",
		event = "SurviveSeconds",
		target = 120,
		coins = 60,
		xp = 40,
	},
	{
		id = "q_events_3",
		tier = "Easy",
		description = "Survive 3 random events",
		event = "EventSurvived",
		target = 3,
		coins = 70,
		xp = 45,
	},
	{
		id = "q_top3_2",
		tier = "Medium",
		description = "Finish in the top 3 twice",
		event = "Top3",
		target = 2,
		coins = 100,
		xp = 70,
	},
	{
		id = "q_survive60_3",
		tier = "Medium",
		description = "Survive 60 seconds in 3 rounds",
		event = "Survive60",
		target = 3,
		coins = 100,
		xp = 70,
	},
	{
		id = "q_play_8",
		tier = "Medium",
		description = "Play 8 rounds",
		event = "RoundPlayed",
		target = 8,
		coins = 110,
		xp = 75,
	},
	{ id = "q_win_1", tier = "Hard", description = "Win a round", event = "Win", target = 1, coins = 150, xp = 120 },
	{
		id = "q_survive_600",
		tier = "Hard",
		description = "Survive 10 minutes in total",
		event = "SurviveSeconds",
		target = 600,
		coins = 150,
		xp = 110,
	},
	{
		id = "q_events_10",
		tier = "Hard",
		description = "Survive 10 random events",
		event = "EventSurvived",
		target = 10,
		coins = 160,
		xp = 120,
	},
}

local byId: { [string]: QuestTemplate } = {}
for _, quest in list do
	byId[quest.id] = quest
end

return {
	List = list,
	ById = byId,
	Tiers = { "Easy", "Medium", "Hard" },
	AllCompleteBonus = { coins = 100, xp = 100 },
}
