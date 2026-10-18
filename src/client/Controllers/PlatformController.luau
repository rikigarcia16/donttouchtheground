--!nonstrict
-- Client side of platforms: deterministic motion (from PlatformMotion
-- attributes, synced to server time), carry velocity for characters, and
-- every visual state — fading, warning blinks, cracks, protection glow,
-- ice, Safe Color highlighting.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlatformMotion = require(Shared.Logic.PlatformMotion)

local PlatformController = {}

type Tracked = {
	part: BasePart,
	baseCF: CFrame,
	baseSize: Vector3,
	round: boolean,
	children: { { part: BasePart, rel: CFrame, size: Vector3 } },
	lastPos: Vector3,
	lastYaw: number,
	baseColor: Color3,
	baseTransparency: number,
	baseMaterial: Enum.Material,
	connections: { RBXScriptConnection },
}

local tracked: { [BasePart]: Tracked } = {}
local moving: { [BasePart]: Tracked } = {}
local warning: { [BasePart]: Tracked } = {}
local RoundState: Instance

local WARN_COLORS = {
	Red = { Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 200, 200) },
	Roulette = { Color3.fromRGB(255, 40, 160), Color3.fromRGB(255, 255, 255) },
	Explosive = { Color3.fromRGB(255, 30, 0), Color3.fromRGB(255, 255, 255) },
	Drop = { Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 240, 200) },
	Fade = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 120, 120) },
	Collapse = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(40, 0, 0) },
}

local function setVisualTransparency(t: Tracked, value: number, instant: boolean)
	local goal = { Transparency = value }
	if instant then
		t.part.Transparency = value
	else
		TweenService:Create(t.part, TweenInfo.new(0.25), goal):Play()
	end
	for _, child in t.children do
		local target = if value >= 0.99 then 1 else child.part:GetAttribute("BaseT") or 0
		if instant then
			child.part.Transparency = target
		else
			TweenService:Create(child.part, TweenInfo.new(0.25), { Transparency = target }):Play()
		end
	end
	for _, gui in t.part:GetChildren() do
		if gui:IsA("SurfaceGui") then
			gui.Enabled = value < 0.9
		end
	end
end

local function refreshState(t: Tracked)
	local part = t.part
	local state = part:GetAttribute("State")
	if state == "Gone" then
		setVisualTransparency(t, 1, false)
	else
		setVisualTransparency(t, t.baseTransparency, false)
		part.Color = t.baseColor
	end
	if part:GetAttribute("Iced") then
		part.Material = Enum.Material.Ice
		part.Color = t.baseColor:Lerp(Color3.fromRGB(200, 240, 255), 0.55)
	elseif part.Material ~= t.baseMaterial then
		part.Material = t.baseMaterial
		part.Color = t.baseColor
	end
	if part:GetAttribute("WarnUntil") then
		warning[part] = t
	end
	if part:GetAttribute("Cracking") then
		part.Color = t.baseColor:Lerp(Color3.fromRGB(70, 40, 20), 0.5)
	elseif not moving[part] then
		part.CFrame = t.baseCF
	end
end

local function track(part: BasePart)
	if tracked[part] or not part:GetAttribute("PType") then
		return
	end
	local t: Tracked = {
		part = part,
		baseCF = part.CFrame,
		baseSize = part.Size,
		round = part:GetAttribute("Round") == true,
		children = {},
		lastPos = part.Position,
		lastYaw = 0,
		baseColor = (part:GetAttribute("BaseColor") :: Color3?) or part.Color,
		baseTransparency = (part:GetAttribute("BaseTransparency") :: number?) or part.Transparency,
		baseMaterial = part.Material,
		connections = {},
	}
	for _, child in part:GetChildren() do
		if child:IsA("BasePart") then
			child:SetAttribute("BaseT", child.Transparency)
			table.insert(t.children, { part = child, rel = part.CFrame:ToObjectSpace(child.CFrame), size = child.Size })
		end
	end
	tracked[part] = t
	if PlatformMotion.hasMotion(part) then
		moving[part] = t
	end
	local function onChange()
		if PlatformMotion.hasMotion(part) then
			moving[part] = t
		end
		refreshState(t)
	end
	for _, attribute in { "State", "WarnUntil", "Cracking", "Iced", "M_Kind", "E_Kind", "S_Scale" } do
		table.insert(t.connections, part:GetAttributeChangedSignal(attribute):Connect(onChange))
	end
	table.insert(
		t.connections,
		part.AncestryChanged:Connect(function()
			if not part:IsDescendantOf(workspace) then
				for _, c in t.connections do
					c:Disconnect()
				end
				tracked[part] = nil
				moving[part] = nil
				warning[part] = nil
			end
		end)
	)
	refreshState(t)
end

local function applyMotion(t: Tracked, now: number, dt: number)
	local part = t.part
	local offset, yaw, scale = PlatformMotion.compute(part, now)
	local rotation = t.baseCF - t.baseCF.Position
	local position = t.baseCF.Position + offset
	local cf = CFrame.new(position) * CFrame.Angles(0, yaw, 0) * rotation
	part.CFrame = cf
	if scale ~= 1 then
		part.Size = if t.round
			then Vector3.new(t.baseSize.X, t.baseSize.Y * scale, t.baseSize.Z * scale)
			else Vector3.new(t.baseSize.X * scale, t.baseSize.Y, t.baseSize.Z * scale)
	elseif part.Size ~= t.baseSize then
		part.Size = t.baseSize
	end
	for _, child in t.children do
		child.part.CFrame = cf * child.rel
		if scale ~= 1 then
			child.part.Size = if t.round
				then Vector3.new(child.size.X, child.size.Y * scale, child.size.Z * scale)
				else Vector3.new(child.size.X * scale, child.size.Y, child.size.Z * scale)
		elseif child.part.Size ~= child.size then
			child.part.Size = child.size
		end
	end
	-- Velocity lets characters ride the platform (anchored part conveyor trick).
	if dt > 0 then
		part.AssemblyLinearVelocity = (position - t.lastPos) / dt
		part.AssemblyAngularVelocity = Vector3.new(0, (yaw - t.lastYaw) / dt, 0)
	end
	t.lastPos = position
	t.lastYaw = yaw
	if not PlatformMotion.hasMotion(part) and offset.Magnitude < 1e-3 then
		moving[t.part] = nil
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end
end

local function safeColorTint(now: number)
	local safe = RoundState:GetAttribute("SafeColor")
	if not safe then
		return
	end
	local pulse = (math.sin(now * 10) + 1) / 2
	for part, t in tracked do
		if part:GetAttribute("State") ~= "Gone" then
			if part:GetAttribute("ColorGroup") == safe then
				part.Color = t.baseColor:Lerp(Color3.new(1, 1, 1), 0.25 * pulse)
			else
				part.Color = t.baseColor:Lerp(Color3.fromRGB(60, 0, 0), 0.4 + 0.3 * pulse)
			end
		end
	end
end

function PlatformController.Start()
	RoundState = ReplicatedStorage:WaitForChild("RoundState")
	local function watchMap(map: Instance)
		local folder = map:WaitForChild("Platforms", 10)
		if not folder then
			return
		end
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				track(child)
			end
		end
		folder.ChildAdded:Connect(function(child)
			if child:IsA("BasePart") then
				task.defer(track, child)
			end
		end)
	end
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Map" then
			watchMap(child)
		end
	end)
	local existing = workspace:FindFirstChild("Map")
	if existing then
		task.spawn(watchMap, existing)
	end

	local lastSafe = nil
	RunService.PreSimulation:Connect(function(dt)
		local now = workspace:GetServerTimeNow()
		for _, t in moving do
			applyMotion(t, now, dt)
		end
		for part, t in warning do
			local untilTime = part:GetAttribute("WarnUntil")
			if not untilTime or now >= untilTime or part:GetAttribute("State") == "Gone" then
				warning[part] = nil
				if part:GetAttribute("State") ~= "Gone" then
					part.Color = t.baseColor
				end
			else
				local colors = WARN_COLORS[part:GetAttribute("WarnStyle") or "Red"] or WARN_COLORS.Red
				local remaining = untilTime - now
				local speed = if remaining < 0.6 then 22 else 10
				part.Color = if math.sin(now * speed) > 0 then colors[1] else colors[2]
			end
		end
		for part, t in tracked do
			if part:GetAttribute("PType") == "Fake" and part:GetAttribute("State") ~= "Gone" then
				part.Transparency = t.baseTransparency + math.sin(now * 3 + part.Position.X) * 0.08
			elseif part:GetAttribute("Cracking") and part:GetAttribute("State") ~= "Gone" then
				local rotation = t.baseCF - t.baseCF.Position
				if not moving[part] then
					part.CFrame = CFrame.new(
						t.baseCF.Position + Vector3.new((math.random() - 0.5) * 0.12, 0, (math.random() - 0.5) * 0.12)
					) * rotation
				end
			elseif part:GetAttribute("ProtectedUntil") then
				local rim = part:FindFirstChild("Rim")
				if rim and rim:IsA("BasePart") then
					rim.Transparency = 0.2 + (math.sin(now * 4) + 1) * 0.2
				end
			end
		end
		local safe = RoundState:GetAttribute("SafeColor")
		if safe then
			safeColorTint(now)
		elseif lastSafe then
			for _, t in tracked do
				refreshState(t)
			end
		end
		lastSafe = safe
	end)
end

return PlatformController
