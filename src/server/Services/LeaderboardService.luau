--!nonstrict
-- Global Total Wins leaderboard (OrderedDataStore) and a global victories
-- counter. Results are published on ReplicatedStorage.Leaderboard for the
-- lobby boards and podium statues.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Signal = require(Shared.Util.Signal)

local LeaderboardService = {}
LeaderboardService.Updated = Signal.new() -- (entries)

local PlayerData: any
local ordered: OrderedDataStore? = nil
local globalStore: DataStore? = nil
local pendingGlobalWins = 0
local lastPublished: { [number]: number } = {}
local entries: { { userId: number, name: string, wins: number } } = {}
local valueFolder: Folder

local function publish(globalWins: number?)
	valueFolder:SetAttribute("Json", HttpService:JSONEncode(entries))
	if globalWins then
		valueFolder:SetAttribute("GlobalWins", globalWins)
	end
	LeaderboardService.Updated:Fire(entries)
end

local function nameFor(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	return if ok then name else ("Player " .. userId)
end

local function refresh()
	if not ordered then
		-- Memory mode: rank the players in this server.
		local list = {}
		for _, player in Players:GetPlayers() do
			local profile = PlayerData.Get(player)
			if profile then
				table.insert(list, { userId = player.UserId, name = player.DisplayName, wins = profile.totalWins })
			end
		end
		table.sort(list, function(a, b)
			return a.wins > b.wins
		end)
		entries = list
		publish(nil)
		return
	end
	local ok, pages = pcall(function()
		return (ordered :: OrderedDataStore):GetSortedAsync(false, 10)
	end)
	if not ok then
		warn("[Leaderboard] fetch failed: " .. tostring(pages))
		return
	end
	local list = {}
	for _, row in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(string.match(row.key, "%d+"))
		if userId then
			table.insert(list, { userId = userId, name = nameFor(userId), wins = row.value })
		end
	end
	entries = list
	local globalWins = nil
	if globalStore then
		local gOk, value = pcall(function()
			return (globalStore :: DataStore):GetAsync("GlobalWins")
		end)
		if gOk and type(value) == "number" then
			globalWins = value
		end
	end
	publish(globalWins)
end

function LeaderboardService.Submit(player: Player, totalWins: number)
	if not ordered or lastPublished[player.UserId] == totalWins then
		return
	end
	lastPublished[player.UserId] = totalWins
	task.spawn(function()
		local ok, err = pcall(function()
			(ordered :: OrderedDataStore):SetAsync("u" .. player.UserId, totalWins)
		end)
		if not ok then
			warn("[Leaderboard] submit failed: " .. tostring(err))
			lastPublished[player.UserId] = nil
		end
	end)
end

function LeaderboardService.CountGlobalWin()
	pendingGlobalWins += 1
end

function LeaderboardService.Entries()
	return entries
end

function LeaderboardService.Init(services)
	PlayerData = services.PlayerDataService
	valueFolder = Instance.new("Folder")
	valueFolder.Name = "Leaderboard"
	valueFolder:SetAttribute("Json", "[]")
	valueFolder:SetAttribute("GlobalWins", 0)
	valueFolder.Parent = ReplicatedStorage
	if not PlayerData.IsMemoryMode() then
		pcall(function()
			ordered = DataStoreService:GetOrderedDataStore(GameConfig.Data.LeaderboardStoreName)
			globalStore = DataStoreService:GetDataStore(GameConfig.Data.LeaderboardStoreName .. "_global")
		end)
	end
end

function LeaderboardService.Start()
	PlayerData.ProfileChanged:Connect(function(player, profile, keys)
		if keys and table.find(keys, "totalWins") then
			LeaderboardService.Submit(player, profile.totalWins)
		end
	end)
	PlayerData.ProfileLoaded:Connect(function(player, profile)
		LeaderboardService.Submit(player, profile.totalWins)
	end)
	task.spawn(function()
		while true do
			if pendingGlobalWins > 0 and globalStore then
				local amount = pendingGlobalWins
				pendingGlobalWins = 0
				local ok = pcall(function()
					(globalStore :: DataStore):IncrementAsync("GlobalWins", amount)
				end)
				if not ok then
					pendingGlobalWins += amount
				end
			end
			refresh()
			task.wait(if ordered then GameConfig.Data.LeaderboardRefresh else 15)
		end
	end)
end

return LeaderboardService
