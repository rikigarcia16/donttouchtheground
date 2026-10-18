--!nonstrict
-- Builds the lobby, rescues players who fall off it, tracks lobby idling
-- (AFK players sit out rounds) and keeps the leaderboard boards, podium
-- statues and featured pedestals up to date.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local RarityConfig = require(Shared.Config.RarityConfig)
local Format = require(Shared.Util.Format)
local LobbyBuilder = require(script.Parent.Parent.Maps.Lobby)

local LobbyService = {}

local Leaderboard: any
local Shop: any
local lobbyModel: Model
local refs: { [string]: any }
local idle: { [Player]: { position: Vector3?, lastMove: number } } = {}
local statues: { [number]: Model } = {}
local statueCache: { [number]: Model } = {}

local LOBBY_Y = GameConfig.World.LobbyOrigin.Position.Y

function LobbyService.SpawnCFrame(): CFrame
	local offset = Vector3.new(math.random(-5, 5), 4, math.random(-5, 5))
	return refs.spawn.CFrame + offset
end

function LobbyService.IsAFK(player: Player): boolean
	return player:GetAttribute("AFK") == true
end

function LobbyService.ResetIdle(player: Player)
	idle[player] = { position = nil, lastMove = os.clock() }
	player:SetAttribute("AFK", false)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function renderLeaderboard(entries)
	local body: Frame = refs.leaderboardBody
	for _, child in body:GetChildren() do
		child:Destroy()
	end
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body
	for rank = 1, math.min(10, #entries) do
		local entry = entries[rank]
		local row = Instance.new("TextLabel")
		row.Name = "Row" .. rank
		row.LayoutOrder = rank
		row.Size = UDim2.new(1, 0, 0.095, 0)
		row.BackgroundColor3 = if rank == 1
			then Color3.fromRGB(255, 200, 50)
			elseif rank == 2 then Color3.fromRGB(200, 210, 225)
			elseif rank == 3 then Color3.fromRGB(220, 140, 80)
			else Color3.fromRGB(45, 40, 80)
		row.BackgroundTransparency = if rank <= 3 then 0.1 else 0.3
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBlack
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if rank <= 3 then Color3.fromRGB(30, 20, 10) else Color3.fromRGB(255, 255, 255)
		row.Text = string.format("  #%d  %s  —  %s 🏆", rank, entry.name, Format.commas(entry.wins))
		row.Parent = body
	end
	if #entries == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.fromScale(1, 0.2)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.GothamBold
		empty.TextScaled = true
		empty.TextColor3 = Color3.fromRGB(220, 220, 255)
		empty.Text = "Win a round to claim the top spot!"
		empty.Parent = body
	end
end

local function placeStatue(rank: number, userId: number?)
	local existing = statues[rank]
	if existing then
		existing.Parent = nil
		statues[rank] = nil
	end
	if not userId then
		return
	end
	local model = statueCache[userId]
	if not model then
		local ok, result = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)
		if not ok or not result then
			return
		end
		model = result
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false
			elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
				descendant:Destroy()
			end
		end
		statueCache[userId] = model
	end
	model.Name = "Champion" .. rank
	model:SetAttribute("StatueRank", rank)
	local extents = model:GetExtentsSize()
	model:PivotTo(refs.podiums[rank] * CFrame.new(0, extents.Y / 2, 0))
	model.Parent = lobbyModel
	statues[rank] = model
end

local function refreshBoards(entries)
	renderLeaderboard(entries)
	for rank = 1, 3 do
		local entry = entries[rank]
		task.spawn(placeStatue, rank, if entry then entry.userId else nil)
	end
end

local function refreshGlobal()
	local body: Frame = refs.globalBody
	local label = body:FindFirstChild("Value") :: TextLabel?
	if not label then
		local newLabel = Instance.new("TextLabel")
		newLabel.Name = "Value"
		newLabel.BackgroundTransparency = 1
		newLabel.Size = UDim2.fromScale(1, 1)
		newLabel.Font = Enum.Font.LuckiestGuy
		newLabel.TextScaled = true
		newLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
		newLabel.Parent = body
		label = newLabel
	end
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Leaderboard")
	local value = if folder then folder:GetAttribute("GlobalWins") or 0 else 0;
	(label :: TextLabel).Text = Format.commas(value :: number) .. " 🏆"
end

local function refreshFeatured()
	local picks = Shop.FeaturedNow()
	for i, slot in refs.featured do
		local item = CosmeticCatalog.get(picks[i] or "")
		if item then
			local rarity = RarityConfig.get(item.rarity)
			slot.label.Text = item.icon .. " " .. item.name
			slot.label.TextColor3 = rarity.accent
			slot.holo.Color = rarity.color
		end
	end
end

function LobbyService.Init(services)
	Leaderboard = services.LeaderboardService
	Shop = services.ShopService
	lobbyModel, refs = LobbyBuilder(GameConfig.World.LobbyOrigin, workspace)
end

function LobbyService.Start()
	Players.PlayerAdded:Connect(LobbyService.ResetIdle)
	for _, player in Players:GetPlayers() do
		LobbyService.ResetIdle(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		idle[player] = nil
	end)

	Leaderboard.Updated:Connect(function(entries)
		refreshBoards(entries)
		refreshGlobal()
	end)
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Leaderboard")
	if folder then
		local ok, entries = pcall(HttpService.JSONDecode, HttpService, folder:GetAttribute("Json") or "[]")
		if ok then
			refreshBoards(entries)
		end
	end
	refreshGlobal()

	task.spawn(function()
		while true do
			refreshFeatured()
			task.wait(300)
		end
	end)

	-- Fall rescue + idle tracking (0.5s cadence, cheap).
	task.spawn(function()
		local idleLimit = GameConfig.Afk.LobbyIdleSeconds
		while true do
			task.wait(0.5)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				local state = idle[player]
				if root and state then
					local inRound = player:GetAttribute("InRound") == true
					if not inRound and root.Position.Y < LOBBY_Y - 60 and root.Position.Y > LOBBY_Y - 400 then
						root.AssemblyLinearVelocity = Vector3.zero
						local character = player.Character :: Model
						character:PivotTo(LobbyService.SpawnCFrame())
					end
					local position = root.Position
					if state.position == nil or (position - state.position).Magnitude > 1.5 or inRound then
						state.position = position
						state.lastMove = now
						if player:GetAttribute("AFK") then
							player:SetAttribute("AFK", false)
						end
					elseif now - state.lastMove > idleLimit and not player:GetAttribute("AFK") then
						player:SetAttribute("AFK", true)
					end
				end
			end
		end
	end)
end

return LobbyService
