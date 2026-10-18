--!strict
-- Every gameplay tunable lives here. Services read from this table; nothing is
-- hard-coded in the service logic.

local GameConfig = {
	Round = {
		IntermissionTime = 15,
		MapVoteOptions = 3,
		PreparationTime = 5,
		RoundTime = 180, -- active round length before sudden death
		SuddenDeathTime = 45, -- hard cap: lava reaches the top of every map by then
		ResultsTime = 9,
		MinPlayersCompetitive = 2,
		-- A Win is only granted when this many *active* (non-AFK) players
		-- took part and the round lasted at least MinRoundTimeForWin.
		MinActiveForWin = 2,
		MinRoundTimeForWin = 25,
		-- Players eliminated within this window of each other count as simultaneous.
		SimultaneousWindow = 0.05,
		SpawnProtectionTime = 6, -- start pads stay safe this long, never permanently
		TickRate = 1 / 20, -- server hazard/elimination loop frequency
	},

	Afk = {
		-- Lobby: a player who has not moved for this long sits out the next round.
		LobbyIdleSeconds = 150,
		-- Round: a participant must travel this far (studs, horizontal+vertical)
		-- to count as active for rewards.
		MinRoundTravel = 40,
		SampleInterval = 1,
	},

	Lava = {
		StartOffset = -6, -- relative to map origin
		-- Piecewise rise rate (studs/second) by elapsed round time.
		Phases = {
			{ from = 0, rate = 0, label = "Stable" },
			{ from = 20, rate = 0.12, label = "Rising" },
			{ from = 60, rate = 0.24, label = "Faster" },
			{ from = 120, rate = 0.42, label = "Rapid" },
		},
		SuddenDeathRate = 1.6,
		WarningLead = 4, -- seconds before a phase change to warn players
		KillMargin = 0.6, -- root part this far above the surface still dies (feet in lava)
		Size = Vector3.new(1400, 6, 1400),
	},

	Character = {
		WalkSpeed = 16,
		JumpPower = 50,
		RespawnToLobbyDelay = 0.35,
	},

	World = {
		LobbyOrigin = CFrame.new(0, 400, 0),
		MapOrigin = CFrame.new(0, 0, 0),
		ResultsStageOrigin = CFrame.new(0, 900, 0),
		DefaultGravity = 196.2,
		KillFloorOffset = -60, -- below map origin, safety net if lava is bypassed
	},

	Data = {
		DataStoreName = "DTTG_PlayerData_v1",
		LeaderboardStoreName = "DTTG_TotalWins_v1",
		AutosaveInterval = 60,
		SessionLockTimeout = 150, -- a lock older than this is considered stale
		LoadRetries = 6,
		LoadRetryDelay = 4,
		SaveRetries = 4,
		LeaderboardRefresh = 120,
	},

	Quality = {
		-- Multipliers applied by the client effects layer per quality level.
		Low = { particles = 0.25, glyphs = 0, debris = 0.3, lights = false, maxEffectDistance = 90 },
		Medium = { particles = 0.6, glyphs = 0.5, debris = 0.6, lights = true, maxEffectDistance = 160 },
		High = { particles = 1, glyphs = 1, debris = 1, lights = true, maxEffectDistance = 260 },
	},

	-- Test-only commands (see AdminService). Enabled automatically in Studio.
	AdminUserIds = {} :: { number },
}

return GameConfig
