--!strict
-- Achievement, collection and level-reward evaluation over a profile.

local ProgressLogic = {}

export type Achievement = { id: string, stat: string, target: number, rewards: { string }, coins: number? }

function ProgressLogic.readStat(profile: { [string]: any }, stat: string): number
	if stat == "mapsWonDistinct" then
		local count = 0
		for _, wins in profile.stats.mapsWon do
			if wins > 0 then
				count += 1
			end
		end
		return count
	elseif stat == "ownedCount" then
		local count = 0
		for _ in profile.owned do
			count += 1
		end
		return count
	end
	local node: any = profile
	for part in string.gmatch(stat, "[^%.]+") do
		if type(node) ~= "table" then
			return 0
		end
		node = node[part]
	end
	return if type(node) == "number" then node else 0
end

function ProgressLogic.newAchievements(profile: { [string]: any }, achievements: { Achievement }): { Achievement }
	local unlocked = {}
	for _, achievement in achievements do
		if
			not profile.achievements[achievement.id]
			and ProgressLogic.readStat(profile, achievement.stat) >= achievement.target
		then
			table.insert(unlocked, achievement)
		end
	end
	return unlocked
end

export type CatalogItem = { id: string, collection: string?, unlock: { kind: string, id: string?, level: number? } }

-- Members are the items that belong to the collection and are not its reward.
function ProgressLogic.collectionMembers(items: { CatalogItem }, collectionId: string): { string }
	local members = {}
	for _, item in items do
		if item.collection == collectionId then
			table.insert(members, item.id)
		end
	end
	return members
end

function ProgressLogic.collectionProgress(profile: { [string]: any }, members: { string }): (number, number)
	local owned = 0
	for _, id in members do
		if profile.owned[id] then
			owned += 1
		end
	end
	return owned, #members
end

-- Level rewards whose level requirement is met but not yet owned.
function ProgressLogic.pendingLevelRewards(
	profile: { [string]: any },
	items: { CatalogItem },
	level: number
): { string }
	local pending = {}
	for _, item in items do
		if item.unlock.kind == "Level" and (item.unlock.level or math.huge) <= level and not profile.owned[item.id] then
			table.insert(pending, item.id)
		end
	end
	return pending
end

function ProgressLogic.collectionCompletion(profile: { [string]: any }, items: { CatalogItem }): number
	local total, owned = 0, 0
	for _, item in items do
		total += 1
		if profile.owned[item.id] then
			owned += 1
		end
	end
	return if total > 0 then owned / total else 0
end

return ProgressLogic
