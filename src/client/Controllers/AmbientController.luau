--!nonstrict
-- Ambient animation for decoration flagged by attributes: dance floor tiles,
-- spinning holograms, portal swirl, bobbing lanterns, blinking antenna
-- lights, flowing waterfalls, volcano eruptions, the title sign gradient.
-- Also fills the lobby boards that are personal (Your Wins, Next Round).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MapConfig = require(Shared.Config.MapConfig)
local Format = require(Shared.Util.Format)

local AmbientController = {}

local ClientState: any
local tagged: { [string]: { BasePart } } =
	{ DanceTile = {}, Spin = {}, Swirl = {}, Bob = {}, Blink = {}, Flow = {}, Eruption = {} }
local baseCF: { [BasePart]: CFrame } = {}

local function consider(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	for attribute, list in tagged do
		if instance:GetAttribute(attribute) ~= nil then
			table.insert(list, instance)
			baseCF[instance] = instance.CFrame
		end
	end
end

local function label(body: Instance?, text: string, color: Color3?)
	if not body then
		return
	end
	local existing = body:FindFirstChild("Value") :: TextLabel?
	if not existing then
		local newLabel = Instance.new("TextLabel")
		newLabel.Name = "Value"
		newLabel.BackgroundTransparency = 1
		newLabel.Size = UDim2.fromScale(1, 1)
		newLabel.Font = Enum.Font.LuckiestGuy
		newLabel.TextScaled = true
		newLabel.TextColor3 = color or Color3.new(1, 1, 1)
		newLabel.Parent = body
		existing = newLabel
	end
	(existing :: TextLabel).Text = text
end

local function findBody(panelName: string): Instance?
	local lobby = workspace:FindFirstChild("Lobby")
	local panel = lobby and lobby:FindFirstChild(panelName, true)
	local board = panel and panel:FindFirstChild("Board")
	local root = board and board:FindFirstChild("Root")
	return root and root:FindFirstChild("Body")
end

function AmbientController.Init(controllers)
	ClientState = controllers.ClientState
end

function AmbientController.Start()
	for _, d in workspace:GetDescendants() do
		consider(d)
	end
	workspace.DescendantAdded:Connect(consider)
	workspace.DescendantRemoving:Connect(function(d)
		if baseCF[d] then
			baseCF[d] = nil
			for _, list in tagged do
				local i = table.find(list, d)
				if i then
					table.remove(list, i)
				end
			end
		end
	end)

	local roundState = ReplicatedStorage:WaitForChild("RoundState")
	local titleGradient: UIGradient? = nil
	task.spawn(function()
		local lobby = workspace:WaitForChild("Lobby", 30)
		local sign = lobby and lobby:FindFirstChild("TitleSign")
		titleGradient = sign and sign:FindFirstChildWhichIsA("UIGradient", true)
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for i, tile in tagged.DanceTile do
			tile.Color =
				Color3.fromHSV((t * 0.25 + i * 0.07) % 1, 0.75, if math.floor(t * 2 + i) % 3 == 0 then 1 else 0.6)
		end
		for _, part in tagged.Spin do
			local base = baseCF[part]
			if base then
				part.CFrame = base * CFrame.new(0, math.sin(t * 2) * 0.4, 0) * CFrame.Angles(0, t * 1.5, 0.3)
			end
		end
		for _, part in tagged.Swirl do
			local base = baseCF[part]
			if base then
				part.CFrame = base * CFrame.Angles(t * 1.2, 0, 0)
				part.Color = Color3.fromHSV(0.75 + math.sin(t) * 0.08, 0.7, 1)
			end
		end
		for _, part in tagged.Bob do
			local base = baseCF[part]
			if base then
				local phase = part:GetAttribute("Bob") or 0
				part.CFrame = base + Vector3.new(0, math.sin(t * 1.5 + phase) * 0.5, 0)
			end
		end
		for i, part in tagged.Blink do
			part.Transparency = if math.floor(t * 1.5 + i * 0.3) % 2 == 0 then 0 else 0.85
		end
		for _, part in tagged.Flow do
			part.Transparency = 0.3 + math.sin(t * 6) * 0.05
		end
		if titleGradient then
			titleGradient.Offset = Vector2.new(math.sin(t * 0.8) * 0.3, 0)
		end
	end)

	-- Volcano eruptions: periodic bursts on the crater emitter.
	task.spawn(function()
		while true do
			task.wait(6 + math.random() * 4)
			for _, part in tagged.Eruption do
				local emitter = part:FindFirstChildOfClass("ParticleEmitter")
				if emitter then
					pcall(function()
						emitter:Emit(40)
					end)
				end
			end
		end
	end)

	-- Personal and round boards in the lobby.
	task.spawn(function()
		while true do
			local profile = ClientState.Get()
			if profile then
				label(
					findBody("StatsPanel"),
					string.format(
						"%s 🏆  ·  %s available",
						Format.commas(profile.totalWins),
						Format.commas(profile.wins)
					),
					Color3.fromRGB(140, 230, 255)
				)
			end
			local state = roundState:GetAttribute("State")
			local ends = roundState:GetAttribute("PhaseEndsAt")
			local remaining = if ends then math.max(0, ends - workspace:GetServerTimeNow()) else 0
			local mapDef = MapConfig.ById[roundState:GetAttribute("MapId") or ""]
			local text
			if state == "Intermission" then
				text = "VOTE NOW · " .. Format.clock(remaining)
			elseif state == "Lobby" then
				text = "WAITING FOR PLAYERS"
			elseif state == "Results" then
				text = "RESULTS"
			else
				text = string.format(
					"%s · %d ALIVE",
					if mapDef then string.upper(mapDef.name) else "ROUND",
					roundState:GetAttribute("Alive") or 0
				)
			end
			label(findBody("PortalPanel"), text, Color3.fromRGB(255, 255, 255))
			task.wait(0.5)
		end
	end)
end

return AmbientController
