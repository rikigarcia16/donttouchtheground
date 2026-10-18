--!nonstrict
-- The round state machine. Server-authoritative: participants, survivors,
-- timers, eliminations, the winner and rewards are decided here only.
-- Each round runs inside pcall with a full cleanup so an error can never
-- leave the server stuck in a round.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local MapConfig = require(Shared.Config.MapConfig)
local EventConfig = require(Shared.Config.EventConfig)
local LavaCurve = require(Shared.Logic.LavaCurve)
local RoundLogic = require(Shared.Logic.RoundLogic)
local Maid = require(Shared.Util.Maid)
local Remotes = require(Shared.Net.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)
local RoundState = require(script.Parent.Parent.Util.RoundState)

local RoundService = {}

local Cfg = GameConfig.Round
local PlayerData: any
local Lobby: any
local Maps: any
local Hazard: any
local Events: any
local Rewards: any
local FX: any
local Emotes: any
local roundEvent: RemoteEvent

local votes: { [Player]: string } = {}
local voteOptions: { string } = {}
local roundCounter = 0

-- Live round context (nil outside of a round).
type Live = {
	logic: RoundLogic.RoundLogic,
	players: { [number]: Player },
	maid: Maid.Maid,
	eventsSurvived: { [number]: number },
	jumps: { [number]: number },
	lastPositions: { [number]: Vector3 },
	map: any,
	startServer: number,
	suddenDeath: boolean,
	eventLog: { string },
}
local live: Live? = nil

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function setState(state: string, duration: number?)
	RoundState:SetAttribute("State", state)
	RoundState:SetAttribute("PhaseEndsAt", if duration then serverNow() + duration else nil)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

local function eligible(player: Player): boolean
	if not PlayerData.IsLoaded(player) or Lobby.IsAFK(player) then
		return false
	end
	local humanoid = humanoidOf(player)
	return humanoid ~= nil and humanoid.Health > 0 and rootOf(player) ~= nil
end

local function eligiblePlayers(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if eligible(player) then
			table.insert(list, player)
		end
	end
	return list
end

local function sendToLobby(player: Player)
	player:SetAttribute("InRound", false)
	if player.Parent then
		task.spawn(function()
			local ok, err = pcall(function()
				player:LoadCharacter()
			end)
			if not ok then
				warn("[Round] LoadCharacter failed for " .. player.Name .. ": " .. tostring(err))
			end
		end)
	end
end

local function aliveList(): { Player }
	local list = {}
	if live then
		for _, id in live.logic:AliveIds() do
			local player = live.players[id]
			if player and player.Parent then
				table.insert(list, player)
			end
		end
	end
	return list
end

local function publishCounts()
	if live then
		RoundState:SetAttribute("Alive", live.logic:AliveCount())
		RoundState:SetAttribute("Participants", live.logic:ParticipantCount())
	end
end

local function eliminate(player: Player, cause: RoundLogic.EliminationCause)
	local current = live
	if not current then
		return
	end
	local root = rootOf(player)
	local height = if root then root.Position.Y else nil
	if not current.logic:Eliminate(player.UserId, os.clock(), cause, height) then
		return
	end
	player:SetAttribute("InRound", false)
	publishCounts()
	roundEvent:FireAllClients({
		type = "Eliminated",
		userId = player.UserId,
		name = player.DisplayName,
		cause = cause,
		alive = current.logic:AliveCount(),
	})
	if cause ~= "Left" then
		FX.PlayDeath(player, if root then root.Position else current.map.center)
		task.delay(GameConfig.Character.RespawnToLobbyDelay, function()
			if player.Parent and not player:GetAttribute("InRound") then
				sendToLobby(player)
			end
		end)
	end
end

-- ===== Phases

local function runIntermission(): boolean
	voteOptions = Maps.PickOptions(Cfg.MapVoteOptions)
	votes = {}
	RoundState:SetAttribute("VoteOptions", table.concat(voteOptions, ","))
	RoundState:SetAttribute("VoteCounts", "{}")
	setState("Intermission", Cfg.IntermissionTime)
	local deadline = os.clock() + Cfg.IntermissionTime
	while os.clock() < deadline do
		task.wait(0.25)
		if #eligiblePlayers() == 0 then
			return false
		end
	end
	return true
end

local function tallyVotes(): string
	local counts: { [string]: number } = {}
	for player, mapId in votes do
		if player.Parent then
			counts[mapId] = (counts[mapId] or 0) + 1
		end
	end
	local best, bestCount = {}, -1
	for _, mapId in voteOptions do
		local count = counts[mapId] or 0
		if count > bestCount then
			best, bestCount = { mapId }, count
		elseif count == bestCount then
			table.insert(best, mapId)
		end
	end
	if #best == 0 then
		return MapConfig.List[math.random(1, #MapConfig.List)].id
	end
	return best[math.random(1, #best)]
end

local function freeze(player: Player, frozen: boolean)
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.WalkSpeed = if frozen then 0 else GameConfig.Character.WalkSpeed
		humanoid.UseJumpPower = true
		humanoid.JumpPower = if frozen then 0 else GameConfig.Character.JumpPower
	end
end

local function runRound(): ()
	-- Map selection
	local mapId = tallyVotes()
	RoundState:SetAttribute("MapId", mapId)
	setState("MapSelect", 3)
	roundEvent:FireAllClients({ type = "MapSelected", mapId = mapId })
	local map = Maps.Load(mapId)
	task.wait(3)

	local participants = eligiblePlayers()
	if #participants == 0 then
		Maps.Unload()
		return
	end

	roundCounter += 1
	local roundId = string.format(
		"%s-%d-%s",
		string.sub(game.JobId ~= "" and game.JobId or "studio", 1, 8),
		roundCounter,
		HttpService:GenerateGUID(false):sub(1, 6)
	)
	local logic = RoundLogic.new(os.clock(), {
		simultaneousWindow = Cfg.SimultaneousWindow,
		minTravelForActive = GameConfig.Afk.MinRoundTravel,
	})
	local current: Live = {
		logic = logic,
		players = {},
		maid = Maid.new(),
		eventsSurvived = {},
		jumps = {},
		lastPositions = {},
		map = map,
		startServer = 0,
		suddenDeath = false,
		eventLog = {},
	}
	live = current
	local training = #participants == 1
	RoundState:SetAttribute("Training", training)
	RoundState:SetAttribute("RoundId", roundId)
	RoundState:SetAttribute("SuddenDeath", false)

	-- Preparation: teleport, freeze, countdown.
	for index, player in participants do
		logic:AddParticipant(player.UserId, player.DisplayName)
		current.players[player.UserId] = player
		current.eventsSurvived[player.UserId] = 0
		current.jumps[player.UserId] = 0
		player:SetAttribute("InRound", true)
		Emotes.Stop(player)
		local spawnCF = map.spawns[(index - 1) % #map.spawns + 1]
		local lap = math.floor((index - 1) / #map.spawns)
		local character = player.Character
		if character then
			character:PivotTo(spawnCF * CFrame.new(lap * 1.5, lap * 2, 0))
			local root = rootOf(player)
			if root then
				root.AssemblyLinearVelocity = Vector3.zero
				current.lastPositions[player.UserId] = root.Position
			end
		end
		freeze(player, true)
		local humanoid = humanoidOf(player)
		if humanoid then
			current.maid:Add(humanoid.Died:Connect(function()
				eliminate(player, "Reset")
			end))
		end
		current.maid:Add(player.CharacterRemoving:Connect(function()
			eliminate(player, "Reset")
		end))
	end
	current.maid:Add(FX.Jumped:Connect(function(player)
		if current.jumps[player.UserId] then
			current.jumps[player.UserId] += 1
		end
	end))
	current.maid:Add(Events.EventEnded:Connect(function(def, survivors)
		table.insert(current.eventLog, def.id)
		for _, player in survivors do
			if current.eventsSurvived[player.UserId] then
				current.eventsSurvived[player.UserId] += 1
			end
		end
	end))
	publishCounts()

	setState("Preparation", Cfg.PreparationTime)
	roundEvent:FireAllClients({
		type = "Preparation",
		mapId = mapId,
		training = training,
		endsAt = serverNow() + Cfg.PreparationTime,
	})
	local prepEnd = os.clock() + Cfg.PreparationTime
	local lastCount = math.huge
	while os.clock() < prepEnd do
		local remaining = math.ceil(prepEnd - os.clock())
		if remaining <= 3 and remaining < lastCount then
			lastCount = remaining
			roundEvent:FireAllClients({ type = "Countdown", value = remaining })
		end
		task.wait(0.1)
	end

	-- Active round
	current.startServer = serverNow()
	logic.startTime = os.clock()
	for _, player in aliveList() do
		freeze(player, false)
	end
	Hazard.Begin(map, current.startServer)
	Events.Begin(map, current.startServer, aliveList)
	setState("Active", Cfg.RoundTime)
	RoundState:SetAttribute("RoundStart", current.startServer)
	roundEvent:FireAllClients({ type = "Go" })

	local warnedPhase = 1
	local lastTick = os.clock()
	local lastSample = os.clock()
	local lastPublish = 0
	local startClock = os.clock()

	while true do
		task.wait(Cfg.TickRate)
		local nowClock = os.clock()
		local dt = math.min(0.25, nowClock - lastTick)
		lastTick = nowClock
		local elapsed = nowClock - startClock
		local alive = aliveList()

		Hazard.Step(dt, elapsed, current.suddenDeath, alive)
		Events.Step(dt, elapsed, current.suddenDeath)

		-- Eliminations (lava, falling, missing character). Collected first and
		-- applied together so simultaneous deaths share a batch.
		local lavaY = Hazard.LavaY()
		local doomed: { Player } = {}
		local causes: { RoundLogic.EliminationCause } = {}
		for _, player in alive do
			local root = rootOf(player)
			local humanoid = humanoidOf(player)
			if not root or not humanoid or humanoid.Health <= 0 then
				table.insert(doomed, player)
				table.insert(causes, "Reset")
			else
				local feetY = root.Position.Y - (humanoid.HipHeight + root.Size.Y / 2)
				local flat = (root.Position - map.center) * Vector3.new(1, 0, 1)
				if feetY < lavaY - GameConfig.Lava.KillMargin then
					table.insert(doomed, player)
					table.insert(causes, "Lava")
				elseif
					root.Position.Y < map.baseY + GameConfig.World.KillFloorOffset
					or flat.Magnitude > map.radius + 160
				then
					table.insert(doomed, player)
					table.insert(causes, "Fall")
				end
			end
		end
		for i, player in doomed do
			eliminate(player, causes[i])
		end

		-- Travel sampling for AFK detection.
		if nowClock - lastSample >= GameConfig.Afk.SampleInterval then
			lastSample = nowClock
			for _, player in aliveList() do
				local root = rootOf(player)
				local last = current.lastPositions[player.UserId]
				if root then
					if last then
						logic:AddTravel(player.UserId, math.min(40, (root.Position - last).Magnitude))
					end
					current.lastPositions[player.UserId] = root.Position
				end
			end
		end

		-- Lava phase warnings.
		local untilNext, nextPhase = LavaCurve.nextChange(GameConfig.Lava.Phases, elapsed)
		local phaseIndex = LavaCurve.phaseIndexAt(GameConfig.Lava.Phases, elapsed)
		if untilNext and nextPhase and untilNext <= GameConfig.Lava.WarningLead and warnedPhase <= phaseIndex then
			warnedPhase = phaseIndex + 1
			roundEvent:FireAllClients({ type = "LavaWarning", label = nextPhase.label, inSeconds = untilNext })
		end
		if nowClock - lastPublish >= 0.1 then
			lastPublish = nowClock
			Hazard.PublishLava(elapsed, current.suddenDeath)
		end

		if logic:ShouldEnd() then
			break
		end
		if not current.suddenDeath and elapsed >= Cfg.RoundTime then
			current.suddenDeath = true
			RoundState:SetAttribute("SuddenDeath", true)
			setState("SuddenDeath", Cfg.SuddenDeathTime)
			roundEvent:FireAllClients({ type = "SuddenDeath", endsAt = serverNow() + Cfg.SuddenDeathTime })
			Events.StartScheduled("final_collapse", Cfg.SuddenDeathTime - EventConfig.ById.final_collapse.warnTime)
		elseif current.suddenDeath and elapsed >= Cfg.RoundTime + Cfg.SuddenDeathTime then
			break
		end
	end

	-- ===== End of round
	logic:Finish(os.clock())
	local collapseSurvivors: { [number]: boolean } = {}
	if current.suddenDeath and Events.IsRunning("final_collapse") then
		for _, player in aliveList() do
			collapseSurvivors[player.UserId] = true
		end
	end
	Events.StopAll()
	Hazard.Stop()
	current.maid:Clean()

	local standings = logic:Standings()
	local duration = (logic.endTime :: number) - logic.startTime
	local rewards = Rewards.GrantRound(standings, {
		roundId = roundId,
		mapId = mapId,
		noJumpViable = map.def.noJumpViable,
		duration = duration,
		participantCount = logic:ParticipantCount(),
		activeCount = logic:ActiveCount(),
		players = current.players,
		eventsSurvived = current.eventsSurvived,
		jumps = current.jumps,
		finalCollapseSurvivors = collapseSurvivors,
	})

	-- Results payload (winner cosmetics come from the server-side profile).
	local winnerId: number? = nil
	local isDraw = false
	local summary = {}
	for i, standing in standings do
		if standing.isWinner then
			winnerId = standing.id
		end
		if standing.isDraw then
			isDraw = true
		end
		if i <= 8 then
			table.insert(summary, {
				userId = standing.id,
				name = logic.records[standing.id].name,
				placement = standing.placement,
				survived = math.floor(standing.survived),
				isWinner = standing.isWinner,
				isDraw = standing.isDraw,
			})
		end
	end
	local winnerLoadout = nil
	if winnerId then
		local winner = current.players[winnerId]
		local profile = winner and PlayerData.Get(winner)
		if profile then
			winnerLoadout = profile.equipped
		end
	end
	setState("Results", Cfg.ResultsTime)
	roundEvent:FireAllClients({
		type = "Results",
		roundId = roundId,
		mapId = mapId,
		training = logic:ParticipantCount() <= 1,
		winnerId = winnerId,
		isDraw = isDraw,
		standings = summary,
		duration = math.floor(duration),
		events = current.eventLog,
		winnerLoadout = winnerLoadout,
	})
	for id, reward in rewards do
		local player = current.players[id]
		if player and player.Parent then
			roundEvent:FireClient(player, { type = "Rewards", reward = reward })
		end
	end

	-- Survivors stay frozen on the map while the results scene plays.
	for _, player in aliveList() do
		freeze(player, true)
	end
	task.wait(Cfg.ResultsTime)
	for _, player in aliveList() do
		sendToLobby(player)
	end
	live = nil
	task.wait(0.5)
	Maps.Unload()
end

local function cleanupAfterFailure()
	local current = live
	live = nil
	pcall(Events.StopAll)
	pcall(Hazard.Stop)
	if current then
		pcall(function()
			current.maid:Clean()
		end)
	end
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("InRound") then
			sendToLobby(player)
		end
	end
	pcall(Maps.Unload)
end

function RoundService.IsInRound(player: Player): boolean
	return live ~= nil and live.logic:IsAlive(player.UserId)
end

function RoundService.Init(services)
	PlayerData = services.PlayerDataService
	Lobby = services.LobbyService
	Maps = services.MapService
	Hazard = services.HazardService
	Events = services.EventService
	Rewards = services.RewardService
	FX = services.FXService
	Emotes = services.EmoteService
	roundEvent = Remotes.event("RoundEvent")
end

function RoundService.Start()
	Guard.event(Remotes.event("MapVote"), { "string" }, 2, function(player, mapId)
		if RoundState:GetAttribute("State") ~= "Intermission" or not table.find(voteOptions, mapId) then
			return
		end
		votes[player] = mapId
		local counts = {}
		for voter, choice in votes do
			if voter.Parent then
				counts[choice] = (counts[choice] or 0) + 1
			end
		end
		RoundState:SetAttribute("VoteCounts", HttpService:JSONEncode(counts))
	end)

	Players.PlayerRemoving:Connect(function(player)
		votes[player] = nil
		if live and live.logic:IsAlive(player.UserId) then
			eliminate(player, "Left")
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("InRound", false)
	end)

	task.spawn(function()
		while true do
			setState("Lobby", nil)
			RoundState:SetAttribute("Alive", 0)
			while #eligiblePlayers() == 0 do
				task.wait(1)
			end
			local ok, err = pcall(function()
				if runIntermission() then
					runRound()
				end
			end)
			if not ok then
				warn("[Round] round failed, recovering: " .. tostring(err))
				cleanupAfterFailure()
				task.wait(2)
			end
			if RunService:IsStudio() then
				task.wait(0.2)
			end
		end
	end)
end

return RoundService
