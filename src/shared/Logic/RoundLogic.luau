--!strict
-- Server-authoritative bookkeeping for one round, independent of Roblox so the
-- placement/draw/early-exit rules can be unit tested.

local RoundLogic = {}
RoundLogic.__index = RoundLogic

export type EliminationCause = "Lava" | "Fall" | "Left" | "Reset" | "Hazard" | "Collapse"

export type Record = {
	id: number,
	name: string,
	alive: boolean,
	eliminatedAt: number?,
	cause: EliminationCause?,
	heightAtElimination: number?,
	joinOrder: number,
	travelled: number,
	eliminationBatch: number?,
}

export type Standing = {
	id: number,
	placement: number,
	survived: number,
	isWinner: boolean,
	isDraw: boolean,
	left: boolean,
	active: boolean,
}

export type Options = { simultaneousWindow: number, minTravelForActive: number }

export type RoundLogic = typeof(setmetatable(
	{} :: {
		records: { [number]: Record },
		order: { number },
		startTime: number,
		endTime: number?,
		options: Options,
		batch: number,
		lastBatchTime: number,
	},
	RoundLogic
))

function RoundLogic.new(startTime: number, options: Options): RoundLogic
	return setmetatable({
		records = {},
		order = {},
		startTime = startTime,
		endTime = nil,
		options = options,
		batch = 0,
		lastBatchTime = -math.huge,
	}, RoundLogic)
end

function RoundLogic.AddParticipant(self: RoundLogic, id: number, name: string)
	if self.records[id] then
		return
	end
	table.insert(self.order, id)
	self.records[id] = {
		id = id,
		name = name,
		alive = true,
		joinOrder = #self.order,
		travelled = 0,
	}
end

function RoundLogic.IsAlive(self: RoundLogic, id: number): boolean
	local record = self.records[id]
	return record ~= nil and record.alive
end

function RoundLogic.AddTravel(self: RoundLogic, id: number, distance: number)
	local record = self.records[id]
	if record and record.alive then
		record.travelled += distance
	end
end

function RoundLogic.AliveIds(self: RoundLogic): { number }
	local alive = {}
	for _, id in self.order do
		if self.records[id].alive then
			table.insert(alive, id)
		end
	end
	return alive
end

function RoundLogic.AliveCount(self: RoundLogic): number
	return #self:AliveIds()
end

function RoundLogic.ParticipantCount(self: RoundLogic): number
	return #self.order
end

-- Returns false when the player was not alive (prevents double elimination).
function RoundLogic.Eliminate(
	self: RoundLogic,
	id: number,
	now: number,
	cause: EliminationCause,
	height: number?
): boolean
	local record = self.records[id]
	if not record or not record.alive then
		return false
	end
	if now - self.lastBatchTime > self.options.simultaneousWindow then
		self.batch += 1
		self.lastBatchTime = now
	end
	record.alive = false
	record.eliminatedAt = now
	record.cause = cause
	record.heightAtElimination = height
	record.eliminationBatch = self.batch
	return true
end

function RoundLogic.ActiveCount(self: RoundLogic): number
	local count = 0
	for _, id in self.order do
		local record = self.records[id]
		if record.travelled >= self.options.minTravelForActive then
			count += 1
		end
	end
	return count
end

-- Competitive round ends at <= 1 alive; training (1 participant) ends at 0.
function RoundLogic.ShouldEnd(self: RoundLogic): boolean
	local alive = self:AliveCount()
	if #self.order <= 1 then
		return alive == 0
	end
	return alive <= 1
end

function RoundLogic.Finish(self: RoundLogic, now: number)
	if not self.endTime then
		self.endTime = now
	end
end

-- Placement 1 = best. Survivors (alive at the end) share the top; the rest are
-- ranked by elimination time (later = better). Players eliminated in the same
-- batch share a placement. If nobody is alive, the last batch is a draw.
function RoundLogic.Standings(self: RoundLogic): { Standing }
	local endTime = self.endTime or self.startTime
	local entries = {}
	for _, id in self.order do
		table.insert(entries, self.records[id])
	end

	table.sort(entries, function(a: Record, b: Record)
		if a.alive ~= b.alive then
			return a.alive
		end
		local at = a.eliminatedAt or endTime
		local bt = b.eliminatedAt or endTime
		if at ~= bt then
			return at > bt
		end
		return a.joinOrder < b.joinOrder
	end)

	local survivors = 0
	for _, entry in entries do
		if entry.alive then
			survivors += 1
		end
	end

	local standings: { Standing } = {}
	local placement = 0
	local previousKey: any = nil
	for index, entry in entries do
		local key = if entry.alive then "alive" else entry.eliminationBatch
		if key ~= previousKey then
			placement = index
			previousKey = key
		end
		local left = entry.cause == "Left"
		local survived = (entry.eliminatedAt or endTime) - self.startTime
		table.insert(standings, {
			id = entry.id,
			placement = placement,
			survived = math.max(0, survived),
			isWinner = false,
			isDraw = false,
			left = left,
			active = entry.travelled >= self.options.minTravelForActive,
		})
	end

	if survivors == 1 then
		standings[1].isWinner = true
	elseif survivors == 0 and #standings > 0 then
		-- Everybody fell: the final batch shares a draw unless it has a single member.
		local topBatch = {}
		for _, standing in standings do
			if standing.placement == 1 and not standing.left then
				table.insert(topBatch, standing)
			end
		end
		if #topBatch == 1 then
			topBatch[1].isWinner = true
		else
			for _, standing in topBatch do
				standing.isDraw = true
			end
		end
	end
	if survivors > 1 then
		-- Time ran out with several players alive (e.g. sudden death cap): they share a draw.
		for _, standing in standings do
			if standing.placement == 1 then
				standing.isDraw = true
			end
		end
	end
	return standings
end

return RoundLogic
