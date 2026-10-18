--!nonstrict
-- Owns every player profile. Session-locked DataStore persistence with
-- retries, autosave, BindToClose, schema migration and a memory fallback when
-- DataStores are unavailable (Studio without API access).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local ProfileSchema = require(Shared.Logic.ProfileSchema)
local LevelCurve = require(Shared.Logic.LevelCurve)
local Signal = require(Shared.Util.Signal)
local Remotes = require(Shared.Net.Remotes)

type Profile = { [string]: any }

type Session = {
	player: Player,
	profile: Profile,
	dirty: boolean,
	loadedFromStore: boolean,
	saving: boolean,
	released: boolean,
	lastSave: number,
}

local PlayerDataService = {}
PlayerDataService.ProfileLoaded = Signal.new() -- (player, profile)
PlayerDataService.ProfileChanged = Signal.new() -- (player, profile, keys)

local DataCfg = GameConfig.Data
local sessions: { [Player]: Session } = {}
local loading: { [Player]: boolean } = {}
local store: DataStore? = nil
local memoryStore: { [string]: any } = {}
local useMemory = false
local jobId = if game.JobId ~= "" then game.JobId else ("studio-" .. HttpService:GenerateGUID(false))
local dataSync: RemoteEvent

local function keyFor(userId: number): string
	return "player_" .. userId
end

local function now(): number
	return os.time()
end

-- UpdateAsync with retry/backoff; `transform` may return nil to cancel.
local function updateWithRetry(key: string, transform: (any) -> any, retries: number): (boolean, any)
	if useMemory then
		local result = transform(memoryStore[key])
		if result ~= nil then
			memoryStore[key] = result
		end
		return true, result
	end
	local attempt = 0
	while true do
		attempt += 1
		local ok, result = pcall(function()
			return (store :: DataStore):UpdateAsync(key, transform)
		end)
		if ok then
			return true, result
		end
		warn(string.format("[PlayerData] UpdateAsync %s failed (attempt %d): %s", key, attempt, tostring(result)))
		if attempt >= retries then
			return false, result
		end
		task.wait(math.min(2 ^ attempt, 16))
	end
end

local function validIds(): { [string]: any }
	return CosmeticCatalog.ById :: any
end

local function applyDefaults(profile: Profile)
	for _, id in CosmeticCatalog.defaultOwned() do
		if not profile.owned[id] then
			profile.owned[id] = now()
		end
	end
	for slot, id in CosmeticCatalog.DefaultLoadout do
		if profile.equipped[slot] == nil and profile.owned[id] then
			profile.equipped[slot] = id
		end
	end
	local level = LevelCurve.fromTotalXp(profile.xp, EconomyConfig.Level)
	profile.level = level
end

local function setupLeaderstats(player: Player, profile: Profile)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local wins = leaderstats:FindFirstChild("Wins") or Instance.new("IntValue")
	wins.Name = "Wins";
	(wins :: IntValue).Value = profile.totalWins
	wins.Parent = leaderstats
	local level = leaderstats:FindFirstChild("Level") or Instance.new("IntValue")
	level.Name = "Level";
	(level :: IntValue).Value = profile.level
	level.Parent = leaderstats
	leaderstats.Parent = player
	player:SetAttribute("Level", profile.level)
	player:SetAttribute("TotalWins", profile.totalWins)
end

local function refreshLeaderstats(player: Player, profile: Profile)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local wins = leaderstats:FindFirstChild("Wins") :: IntValue?
		if wins then
			wins.Value = profile.totalWins
		end
		local level = leaderstats:FindFirstChild("Level") :: IntValue?
		if level then
			level.Value = profile.level
		end
	end
	player:SetAttribute("Level", profile.level)
	player:SetAttribute("TotalWins", profile.totalWins)
end

-- What the client receives: everything except bookkeeping.
function PlayerDataService.Snapshot(profile: Profile): Profile
	local copy = table.clone(profile)
	copy.processedRounds = nil
	copy.meta = nil
	return copy
end

local function loadProfile(player: Player)
	local key = keyFor(player.UserId)
	local raw: any = nil
	local lockedByOther = false

	for _ = 1, DataCfg.LoadRetries do
		lockedByOther = false
		local ok, result = updateWithRetry(key, function(old: any)
			raw = nil
			lockedByOther = false
			if type(old) == "table" then
				local lock = old.lock
				if
					type(lock) == "table"
					and lock.job ~= jobId
					and type(lock.t) == "number"
					and now() - lock.t < DataCfg.SessionLockTimeout
				then
					lockedByOther = true
					return nil -- cancel: another server still owns this profile
				end
				raw = old.data
			end
			return { lock = { job = jobId, t = now() }, data = raw }
		end, DataCfg.SaveRetries)

		if not player.Parent then
			return
		end
		if ok and not lockedByOther then
			local profile, notes = ProfileSchema.load(raw, now(), validIds())
			if #notes > 0 then
				print(string.format("[PlayerData] %s profile notes: %s", player.Name, table.concat(notes, ", ")))
			end
			applyDefaults(profile)
			local session: Session = {
				player = player,
				profile = profile,
				dirty = true,
				loadedFromStore = true,
				saving = false,
				released = false,
				lastSave = os.clock(),
			}
			sessions[player] = session
			setupLeaderstats(player, profile)
			player:SetAttribute("DataLoaded", true)
			PlayerDataService.ProfileLoaded:Fire(player, profile)
			PlayerDataService.Sync(player)
			return
		end
		if not ok then
			warn("[PlayerData] load failed for " .. player.Name .. ": " .. tostring(result))
		end
		task.wait(DataCfg.LoadRetryDelay)
	end

	if player.Parent then
		if lockedByOther then
			player:Kick("Your data is still being saved by another server. Please rejoin in a few seconds.")
		else
			player:Kick("We could not load your data (Roblox DataStores may be down). Please rejoin soon.")
		end
	end
end

local function saveSession(session: Session, release: boolean): boolean
	if not session.loadedFromStore or session.released then
		return false
	end
	if session.saving then
		if not release then
			return false
		end
		-- Let an in-flight autosave finish first, or it could re-lock after release.
		local deadline = os.clock() + 15
		while session.saving and os.clock() < deadline do
			task.wait(0.1)
		end
	end
	session.saving = true
	local player = session.player
	local profile = session.profile
	profile.meta.saves += 1
	profile.meta.lastSeen = now()
	local payload = profile
	local ownershipLost = false

	local ok = updateWithRetry(keyFor(player.UserId), function(old: any)
		ownershipLost = false
		if type(old) == "table" and type(old.lock) == "table" and old.lock.job ~= jobId then
			ownershipLost = true
			return nil
		end
		return {
			lock = if release then nil else { job = jobId, t = now() },
			data = payload,
		}
	end, DataCfg.SaveRetries)

	session.saving = false
	if ownershipLost then
		warn("[PlayerData] lost session lock for " .. player.Name .. "; not overwriting newer data")
		session.released = true
		return false
	end
	if ok then
		session.dirty = false
		session.lastSave = os.clock()
		if release then
			session.released = true
		end
	end
	return ok
end

function PlayerDataService.Get(player: Player): Profile?
	local session = sessions[player]
	return if session then session.profile else nil
end

function PlayerDataService.WaitFor(player: Player, timeout: number?): Profile?
	local deadline = os.clock() + (timeout or 30)
	while player.Parent and os.clock() < deadline do
		local profile = PlayerDataService.Get(player)
		if profile then
			return profile
		end
		task.wait(0.25)
	end
	return nil
end

function PlayerDataService.IsLoaded(player: Player): boolean
	return sessions[player] ~= nil
end

-- All profile mutations go through here so they are synced and saved.
function PlayerDataService.Update(player: Player, keys: { string }?, mutate: (Profile) -> ()): boolean
	local session = sessions[player]
	if not session or session.released then
		return false
	end
	mutate(session.profile)
	session.dirty = true
	refreshLeaderstats(player, session.profile)
	PlayerDataService.ProfileChanged:Fire(player, session.profile, keys)
	PlayerDataService.Sync(player, keys)
	return true
end

function PlayerDataService.Sync(player: Player, keys: { string }?)
	local session = sessions[player]
	if not session then
		return
	end
	if keys then
		local partial = {}
		for _, key in keys do
			partial[key] = session.profile[key]
		end
		dataSync:FireClient(player, partial, false)
	else
		dataSync:FireClient(player, PlayerDataService.Snapshot(session.profile), true)
	end
end

function PlayerDataService.SaveNow(player: Player): boolean
	local session = sessions[player]
	return if session then saveSession(session, false) else false
end

function PlayerDataService.IsMemoryMode(): boolean
	return useMemory
end

function PlayerDataService.Init()
	dataSync = Remotes.event("DataSync")
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DataCfg.DataStoreName)
	end)
	if ok then
		store = result
		-- In Studio without "Enable Studio Access to API Services" every call errors.
		if RunService:IsStudio() then
			local probeOk = pcall(function()
				(store :: DataStore):GetAsync("__probe")
			end)
			if not probeOk then
				useMemory = true
			end
		end
	else
		useMemory = true
	end
	if useMemory then
		warn("[PlayerData] DataStores unavailable: using in-memory profiles (nothing will persist)")
	end
end

function PlayerDataService.Start()
	local function onPlayerAdded(player: Player)
		if loading[player] or sessions[player] then
			return
		end
		loading[player] = true
		loadProfile(player)
		loading[player] = nil
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			saveSession(session, true)
			sessions[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			task.wait(DataCfg.AutosaveInterval)
			for _, session in sessions do
				if session.dirty or os.clock() - session.lastSave > DataCfg.SessionLockTimeout / 2 then
					-- Refreshing the lock timestamp keeps other servers out.
					task.spawn(saveSession, session, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for _, session in sessions do
			pending += 1
			task.spawn(function()
				saveSession(session, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return PlayerDataService
