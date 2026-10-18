--!nonstrict
-- Runs random events chosen by the DifficultyDirector. Each event lives in
-- Server/Events/<id>.luau with Start/Step/Stop; everything it creates or
-- changes is registered on a Maid so cleanup is guaranteed when it ends,
-- when the round ends early, or if the event errors.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local EventConfig = require(Shared.Config.EventConfig)
local GameConfig = require(Shared.Config.GameConfig)
local DifficultyDirector = require(Shared.Logic.DifficultyDirector)
local Prng = require(Shared.Util.Prng)
local Maid = require(Shared.Util.Maid)
local Signal = require(Shared.Util.Signal)
local Remotes = require(Shared.Net.Remotes)
local RoundState = require(script.Parent.Parent.Util.RoundState)

local EventService = {}
EventService.EventEnded = Signal.new() -- (def, survivors)

type Running = {
	def: EventConfig.EventDef,
	module: any,
	ctx: any,
	phase: "Warning" | "Active",
	startsAt: number,
	endsAt: number,
}

local Hazard: any
local roundEvent: RemoteEvent
local eventsFolder: Instance
local running: { Running } = {}
local recent: { string } = {}
local lastRunAt: { [string]: number } = {}
local nextEventAt = math.huge
local map: any = nil
local rng = Prng.new(1)
local aliveProvider: () -> { Player } = function()
	return {}
end
local roundStartServer = 0
local active = false

local function now(): number
	return workspace:GetServerTimeNow()
end

local function activeDefs(): { any }
	local list = {}
	for _, run in running do
		table.insert(list, run.def)
	end
	return list
end

local function safeCall(run: Running, method: string, ...: any)
	local fn = run.module[method]
	if fn then
		local ok, err = pcall(fn, run.ctx, ...)
		if not ok then
			warn(string.format("[Events] %s.%s failed: %s", run.def.id, method, tostring(err)))
		end
		return ok
	end
	return true
end

local function makeContext(def: EventConfig.EventDef, startsAt: number, endsAt: number)
	local maid = Maid.new()
	local ctx = {
		def = def,
		hazard = Hazard,
		map = map,
		rng = Prng.new(math.floor(now() * 1000) % 2147483646 + 1),
		maid = maid,
		startTime = startsAt,
		endTime = endsAt,
		roundState = RoundState,
		now = now,
		alive = aliveProvider,
		elapsed = function()
			return now() - roundStartServer
		end,
		broadcast = function(payload: { [string]: any })
			payload.type = payload.type or "EventFX"
			payload.eventId = def.id
			roundEvent:FireAllClients(payload)
		end,
	}
	-- Platforms an event may use: available and comfortably above the lava.
	function ctx.available(filter: ((any) -> boolean)?)
		local lavaY = Hazard.LavaY()
		return Hazard.Available(function(entry)
			return entry.basePos.Y - entry.size.Y / 2 > lavaY + 2 and (filter == nil or filter(entry))
		end)
	end
	-- Lock a platform for this event; released automatically on cleanup.
	function ctx.lock(entry): boolean
		if Hazard.Lock(entry, def.id) then
			maid:Add(function()
				Hazard.Unlock(entry, def.id)
			end)
			return true
		end
		return false
	end
	-- Delayed callback that is cancelled if the event is cleaned up first.
	function ctx.after(seconds: number, fn: () -> ())
		local thread = task.delay(seconds, function()
			local ok, err = pcall(fn)
			if not ok then
				warn("[Events] " .. def.id .. " delayed task failed: " .. tostring(err))
			end
		end)
		maid:Add(thread)
	end
	return ctx
end

local function finish(run: Running, survivors: { Player })
	safeCall(run, "Stop")
	run.ctx.maid:Clean()
	local index = table.find(running, run)
	if index then
		table.remove(running, index)
	end
	roundEvent:FireAllClients({ type = "EventEnded", eventId = run.def.id })
	EventService.EventEnded:Fire(run.def, survivors)
	EventService.PublishState()
end

function EventService.PublishState()
	local names = {}
	for _, run in running do
		if run.phase == "Active" then
			table.insert(names, run.def.id)
		end
	end
	RoundState:SetAttribute("ActiveEvents", table.concat(names, ","))
	RoundState:SetAttribute("NextEventAt", if nextEventAt < math.huge then nextEventAt else nil)
end

local function launch(def: EventConfig.EventDef, warnTime: number, duration: number)
	local module = eventsFolder:FindFirstChild(def.id)
	if not module then
		warn("[Events] missing module for " .. def.id)
		return
	end
	local t = now()
	local startsAt = t + warnTime
	local endsAt = startsAt + duration
	local run: Running = {
		def = def,
		module = require(module) :: any,
		ctx = makeContext(def, startsAt, endsAt),
		phase = "Warning",
		startsAt = startsAt,
		endsAt = endsAt,
	}
	table.insert(running, run)
	table.insert(recent, def.id)
	lastRunAt[def.id] = t - roundStartServer
	roundEvent:FireAllClients({
		type = "EventWarning",
		eventId = def.id,
		startsAt = startsAt,
		endsAt = endsAt,
	})
end

function EventService.Begin(loadedMap, roundStartServerTime: number, alive: () -> { Player })
	EventService.StopAll()
	map = loadedMap
	roundStartServer = roundStartServerTime
	aliveProvider = alive
	recent = {}
	lastRunAt = {}
	rng = Prng.new(math.floor(roundStartServerTime * 1000) % 2147483646 + 1)
	nextEventAt = roundStartServerTime + EventConfig.Director.FirstEventAt
	active = true
	EventService.PublishState()
end

function EventService.StartScheduled(id: string, duration: number?)
	local def = EventConfig.ById[id]
	if def then
		launch(def, def.warnTime, duration or def.duration)
	end
end

function EventService.IsRunning(id: string): boolean
	for _, run in running do
		if run.def.id == id then
			return true
		end
	end
	return false
end

function EventService.Step(dt: number, elapsed: number, suddenDeath: boolean)
	if not active then
		return
	end
	local t = now()
	for _, run in table.clone(running) do
		if run.phase == "Warning" and t >= run.startsAt then
			run.phase = "Active"
			if not safeCall(run, "Start") then
				finish(run, {})
			else
				roundEvent:FireAllClients({ type = "EventStarted", eventId = run.def.id, endsAt = run.endsAt })
				EventService.PublishState()
			end
		elseif run.phase == "Active" then
			if t >= run.endsAt then
				finish(run, aliveProvider())
			else
				safeCall(run, "Step", dt)
			end
		end
	end

	if not suddenDeath and t >= nextEventAt then
		local def = DifficultyDirector.choose(EventConfig.List :: any, EventConfig.Director.DifficultyRamp :: any, {
			elapsed = elapsed,
			active = activeDefs(),
			recent = recent,
			lastRunAt = lastRunAt,
			mapWeights = if map then map.def.eventWeights else nil,
			historyNoRepeat = EventConfig.Director.HistoryNoRepeat,
			suddenDeath = suddenDeath,
		}, rng)
		if def then
			launch(def :: any, def.warnTime, def.duration)
		end
		nextEventAt = t + DifficultyDirector.nextGap(EventConfig.Director.DifficultyRamp :: any, elapsed, rng)
		EventService.PublishState()
	elseif suddenDeath and nextEventAt < math.huge then
		nextEventAt = math.huge
		EventService.PublishState()
	end
end

-- Ends every event immediately (round over). Survivor credit is not given.
function EventService.StopAll()
	for _, run in table.clone(running) do
		safeCall(run, "Stop")
		run.ctx.maid:Clean()
		roundEvent:FireAllClients({ type = "EventEnded", eventId = run.def.id })
	end
	running = {}
	active = false
	nextEventAt = math.huge
	workspace.Gravity = GameConfig.World.DefaultGravity
	for _, attribute in { "Wind", "Darkness", "DoubleJump", "SafeColor", "ActiveEvents", "NextEventAt" } do
		RoundState:SetAttribute(attribute, nil)
	end
end

function EventService.Init(services)
	Hazard = services.HazardService
	roundEvent = Remotes.event("RoundEvent")
	eventsFolder = script.Parent.Parent:WaitForChild("Events")
end

return EventService
