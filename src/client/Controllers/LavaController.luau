--!nonstrict
-- Lava visuals: a glowing cracked-lava sea with an animated neon skin,
-- rolling swells, embers, smoke, under-lighting and a sizzle loop. Height
-- comes from the server (LavaY/LavaRate/LavaStamp) and is extrapolated so
-- movement is smooth between updates.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local FxKit = require(Shared.Visual.FxKit)
local Signal = require(Shared.Util.Signal)

local LavaController = {}
LavaController.ProximityChanged = Signal.new() -- (distance: number?)
LavaController.currentY = -math.huge

local SIZE = GameConfig.Lava.Size
local visuals: Model? = nil
local swells: { { part: BasePart, phase: number, offset: Vector3 } } = {}
local surface: BasePart? = nil
local skin: BasePart? = nil
local emberHost: BasePart? = nil
local sizzle: Sound? = nil
local smoothedY = 0

local function build(map: Instance)
	local color = (map:GetAttribute("LavaColor") :: Color3?) or Color3.fromRGB(255, 90, 20)
	local baseY = (map:GetAttribute("BaseY") :: number?) or 0
	local model = Instance.new("Model")
	model.Name = "LavaVisuals"

	local function part(name, size, cf, partColor, material, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		p.CFrame = cf
		p.Color = partColor
		p.Material = material
		p.Transparency = transparency or 0
		p.Parent = model
		return p
	end

	smoothedY = baseY + GameConfig.Lava.StartOffset
	surface = part(
		"LavaSurface",
		SIZE,
		CFrame.new(0, smoothedY - SIZE.Y / 2, 0),
		color:Lerp(Color3.fromRGB(120, 20, 0), 0.4),
		Enum.Material.CrackedLava
	)
	skin = part(
		"LavaSkin",
		Vector3.new(SIZE.X, 0.4, SIZE.Z),
		CFrame.new(0, smoothedY + 0.1, 0),
		color,
		Enum.Material.Neon,
		0.45
	)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Top
	light.Color = color
	light.Range = 40
	light.Brightness = 3
	light.Angle = 120
	light.Parent = skin

	swells = {}
	for x = -3, 3 do
		for z = -3, 3 do
			local offset = Vector3.new(x * 26, 0, z * 26)
			local swell = part(
				"Swell",
				Vector3.new(30, 3, 30),
				CFrame.new(offset + Vector3.new(0, smoothedY, 0)),
				color:Lerp(Color3.fromRGB(255, 220, 120), 0.25),
				Enum.Material.Neon,
				0.55
			)
			swell.Shape = Enum.PartType.Ball
			table.insert(swells, { part = swell, phase = (x * 1.7 + z * 1.3), offset = offset })
		end
	end

	emberHost =
		part("EmberHost", Vector3.new(140, 1, 140), CFrame.new(0, smoothedY, 0), color, Enum.Material.SmoothPlastic, 1)
	local embers = Instance.new("ParticleEmitter")
	embers.Texture = FxKit.TEXTURES.Spark
	embers.Color = FxKit.colors({ Color3.fromRGB(255, 220, 120), color })
	embers.Size = FxKit.seq(0.5, 0)
	embers.Lifetime = NumberRange.new(2, 4)
	embers.Speed = NumberRange.new(3, 7)
	embers.SpreadAngle = Vector2.new(20, 20)
	embers.Acceleration = Vector3.new(0, 1, 0)
	embers.LightEmission = 1
	embers.Shape = Enum.ParticleEmitterShape.Box
	embers:SetAttribute("BaseRate", 40)
	embers.Rate = 40
	embers.Parent = emberHost
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = FxKit.TEXTURES.Smoke
	smoke.Color = FxKit.colors({ Color3.fromRGB(120, 70, 50), Color3.fromRGB(40, 30, 30) })
	smoke.Size = FxKit.seq(6, 14)
	smoke.Transparency = FxKit.seq(0.75, 1)
	smoke.Lifetime = NumberRange.new(4, 6)
	smoke.Speed = NumberRange.new(2, 4)
	smoke.LightEmission = 0.2
	smoke.Shape = Enum.ParticleEmitterShape.Box
	smoke:SetAttribute("BaseRate", 6)
	smoke.Rate = 6
	smoke.Parent = emberHost

	local loop = Instance.new("Sound")
	loop.SoundId = "rbxasset://sounds/action_falling.mp3"
	loop.Looped = true
	loop.Volume = 0
	loop.PlaybackSpeed = 0.35
	loop.Parent = skin
	loop:Play()
	sizzle = loop

	model.Parent = workspace
	visuals = model
end

local function clear()
	if visuals then
		visuals:Destroy()
		visuals = nil
	end
	surface, skin, emberHost, sizzle = nil, nil, nil, nil
	swells = {}
	LavaController.currentY = -math.huge
	LavaController.ProximityChanged:Fire(nil)
end

function LavaController.TargetY(map: Instance): number?
	local y = map:GetAttribute("LavaY")
	if type(y) ~= "number" then
		return nil
	end
	local rate = (map:GetAttribute("LavaRate") :: number?) or 0
	local stamp = (map:GetAttribute("LavaStamp") :: number?) or workspace:GetServerTimeNow()
	return y + rate * math.clamp(workspace:GetServerTimeNow() - stamp, 0, 0.5)
end

function LavaController.Start()
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Map" then
			build(child)
		end
	end)
	workspace.ChildRemoved:Connect(function(child)
		if child.Name == "Map" then
			clear()
		end
	end)
	local existing = workspace:FindFirstChild("Map")
	if existing then
		build(existing)
	end

	local player = Players.LocalPlayer
	RunService.RenderStepped:Connect(function(dt)
		local map = workspace:FindFirstChild("Map")
		if not map or not surface or not skin then
			return
		end
		local target = LavaController.TargetY(map)
		if target then
			smoothedY += (target - smoothedY) * math.clamp(dt * 8, 0, 1)
		end
		LavaController.currentY = smoothedY
		local t = os.clock()
		local camera = workspace.CurrentCamera
		local follow = if camera
			then Vector3.new(camera.CFrame.Position.X, 0, camera.CFrame.Position.Z)
			else Vector3.zero
		surface.CFrame = CFrame.new(follow.X, smoothedY - SIZE.Y / 2 - 0.3, follow.Z)
		skin.CFrame = CFrame.new(follow.X, smoothedY + math.sin(t * 1.3) * 0.15, follow.Z)
		skin.Transparency = 0.4 + math.sin(t * 2.1) * 0.08
		-- Swells roll across the surface, snapped near the camera.
		local snap = Vector3.new(math.floor(follow.X / 26) * 26, 0, math.floor(follow.Z / 26) * 26)
		for _, s in swells do
			local h = math.sin(t * 1.1 + s.phase) * 0.9
			s.part.CFrame =
				CFrame.new(snap + s.offset + Vector3.new(math.sin(t * 0.4 + s.phase) * 3, smoothedY - 1.2 + h, 0))
		end
		if emberHost then
			emberHost.CFrame = CFrame.new(follow.X, smoothedY + 0.5, follow.Z)
		end

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and player:GetAttribute("InRound") then
			local distance = root.Position.Y - 3 - smoothedY
			LavaController.ProximityChanged:Fire(distance)
			if sizzle then
				sizzle.Volume = math.clamp(1 - distance / 30, 0, 1) * 0.6
			end
		else
			LavaController.ProximityChanged:Fire(nil)
			if sizzle then
				sizzle.Volume = 0
			end
		end
	end)
end

return LavaController
