--!strict
-- Daily quest selection and progress. Pure; QuestService applies results.

local Prng = require(script.Parent.Parent.Util.Prng)

local QuestLogic = {}

export type Template = { id: string, tier: string, event: string, target: number, coins: number, xp: number }
export type QuestState = { id: string, progress: number, claimed: boolean }

function QuestLogic.dayIndex(unixTime: number): number
	return math.floor(unixTime / 86400)
end

function QuestLogic.pickDaily(templates: { Template }, tiers: { string }, userId: number, day: number): { QuestState }
	local rng = Prng.new(userId % 1000003 * 31 + day * 7)
	local quests = {}
	for _, tier in tiers do
		local pool = {}
		for _, template in templates do
			if template.tier == tier then
				table.insert(pool, template)
			end
		end
		table.sort(pool, function(a, b)
			return a.id < b.id
		end)
		if #pool > 0 then
			table.insert(quests, { id = rng:Pick(pool).id, progress = 0, claimed = false })
		end
	end
	return quests
end

-- Refreshes the list if the day changed. Returns true when it was reset.
function QuestLogic.ensureDay(
	questData: { day: number, list: { QuestState }, totalCompleted: number },
	templates: { Template },
	tiers: { string },
	userId: number,
	day: number
): boolean
	local valid = questData.day == day and #questData.list > 0
	if valid then
		local byId = {}
		for _, template in templates do
			byId[template.id] = true
		end
		for _, quest in questData.list do
			if not byId[quest.id] then
				valid = false
			end
		end
	end
	if valid then
		return false
	end
	questData.day = day
	questData.list = QuestLogic.pickDaily(templates, tiers, userId, day)
	return true
end

-- Adds progress for an event; returns ids that just became complete.
function QuestLogic.addProgress(
	list: { QuestState },
	byId: { [string]: Template },
	event: string,
	amount: number
): { string }
	local completed = {}
	for _, quest in list do
		local template = byId[quest.id]
		if template and template.event == event and not quest.claimed and quest.progress < template.target then
			quest.progress = math.min(template.target, quest.progress + math.max(0, math.floor(amount)))
			if quest.progress >= template.target then
				table.insert(completed, quest.id)
			end
		end
	end
	return completed
end

function QuestLogic.canClaim(
	list: { QuestState },
	byId: { [string]: Template },
	questId: string
): (boolean, QuestState?)
	for _, quest in list do
		if quest.id == questId then
			local template = byId[quest.id]
			if template and not quest.claimed and quest.progress >= template.target then
				return true, quest
			end
			return false, quest
		end
	end
	return false, nil
end

function QuestLogic.allClaimed(list: { QuestState }): boolean
	if #list == 0 then
		return false
	end
	for _, quest in list do
		if not quest.claimed then
			return false
		end
	end
	return true
end

return QuestLogic
