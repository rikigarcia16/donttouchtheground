--!nonstrict
-- Results-scene content: podium models and victory animation effects.
-- Podiums are static models built at a stage CFrame; victory effects are
-- timelines of Bursts played around the winner while their pose animates.

local Bursts = require(script.Parent.Bursts)
local FxKit = require(script.Parent.FxKit)

local RGB = Color3.fromRGB
local CYL = CFrame.Angles(0, 0, math.rad(90))

local W = {}

local function piece(parent: Instance, props)
	local part = Instance.new((props.class or "Part") :: any) :: BasePart
	if props.shape and part:IsA("Part") then
		(part :: Part).Shape = props.shape
	end
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color or Color3.new(1, 1, 1)
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.Reflectance = props.reflectance or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = parent
	return part
end

local function cylinder(parent, height, diameter, cf, color, material, transparency)
	return piece(parent, {
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(height, diameter, diameter),
		cframe = cf * CYL,
		color = color,
		material = material,
		transparency = transparency,
	})
end

local function ringOf(_parent, count, radius, cf, make)
	for i = 0, count - 1 do
		local a = i / count * math.pi * 2
		make(i, cf * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius) * CFrame.Angles(0, -a, 0))
	end
end

-- ===================================================================== PODIUMS
-- Each builder returns (model, standHeight). The winner stands at
-- stage * CFrame.new(0, standHeight, 0).
W.Podiums = {}

W.Podiums.podium_basic = function(stage: CFrame, parent: Instance)
	local m = Instance.new("Model")
	m.Name = "Podium"
	piece(m, { size = Vector3.new(8, 3, 8), cframe = stage * CFrame.new(0, 1.5, 0), color = RGB(70, 150, 255) })
	piece(m, {
		size = Vector3.new(8.4, 0.4, 8.4),
		cframe = stage * CFrame.new(0, 3.1, 0),
		color = RGB(255, 255, 255),
		material = Enum.Material.Neon,
	})
	m.Parent = parent
	return m, 3.3
end

W.Podiums.podium_gold = function(stage, parent)
	local m = Instance.new("Model")
	for i = 0, 2 do
		cylinder(
			m,
			1.4,
			11 - i * 2.6,
			stage * CFrame.new(0, 0.7 + i * 1.4, 0),
			RGB(255, 210, 70):Lerp(RGB(200, 140, 30), i / 3),
			Enum.Material.Metal
		)
	end
	ringOf(m, 14, 5.8, stage * CFrame.new(0, 0.9, 0), function(_, cf)
		piece(m, {
			class = "WedgePart",
			size = Vector3.new(0.3, 0.9, 0.9),
			cframe = cf,
			color = RGB(90, 200, 90),
			material = Enum.Material.SmoothPlastic,
		})
	end)
	m.Parent = parent
	return m, 4.2
end

W.Podiums.podium_cloud = function(stage, parent)
	local m = Instance.new("Model")
	for _, p in
		{ { 0, 1.5, 0, 7 }, { 2.6, 1.2, 1, 5 }, { -2.8, 1.2, -0.8, 5 }, { 1, 1.2, -2.6, 4.5 }, { -1, 1.3, 2.6, 4.5 } }
	do
		piece(m, {
			shape = Enum.PartType.Ball,
			size = Vector3.new(p[4], p[4] * 0.6, p[4]),
			cframe = stage * CFrame.new(p[1], p[2], p[3]),
			color = RGB(255, 255, 255),
		})
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		piece(m, {
			size = Vector3.new(0.4, 18, 0.4),
			cframe = stage
				* CFrame.new(math.cos(a) * 3, 10, math.sin(a) * 3)
				* CFrame.Angles(math.cos(a) * 0.25, 0, math.sin(a) * 0.25),
			color = RGB(255, 245, 200),
			material = Enum.Material.Neon,
			transparency = 0.6,
		})
	end
	m.Parent = parent
	return m, 2.6
end

W.Podiums.podium_hologram = function(stage, parent)
	local m = Instance.new("Model")
	cylinder(m, 0.6, 9, stage * CFrame.new(0, 0.3, 0), RGB(30, 40, 60), Enum.Material.Metal)
	for i = 1, 3 do
		cylinder(
			m,
			0.12,
			9 - i,
			stage * CFrame.new(0, 0.6 + i * 1.6, 0),
			RGB(0, 255, 230),
			Enum.Material.Neon,
			0.5 + i * 0.1
		).Name =
			"HoloRing"
	end
	cylinder(m, 6, 8, stage * CFrame.new(0, 3.6, 0), RGB(0, 200, 255), Enum.Material.ForceField, 0.6)
	m.Parent = parent
	return m, 0.6
end

W.Podiums.podium_crystal = function(stage, parent)
	local m = Instance.new("Model")
	cylinder(m, 2.5, 10, stage * CFrame.new(0, 1.25, 0), RGB(120, 110, 160), Enum.Material.Slate)
	ringOf(m, 7, 4, stage * CFrame.new(0, 2.5, 0), function(i, cf)
		piece(m, {
			size = Vector3.new(1, 3 + (i % 3), 1),
			cframe = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0.2, 0.7, 0.15),
			color = if i % 2 == 0 then RGB(170, 250, 255) else RGB(210, 140, 255),
			material = Enum.Material.Glass,
			transparency = 0.1,
		})
	end)
	for d = 1, 3 do
		cylinder(m, 1.5, 10 - d * 2.5, stage * CFrame.new(0, -0.5 - d * 1.4, 0), RGB(90, 80, 130), Enum.Material.Slate)
	end
	m.Parent = parent
	return m, 2.5
end

W.Podiums.podium_meteor = function(stage, parent)
	local m = Instance.new("Model")
	piece(m, {
		shape = Enum.PartType.Ball,
		size = Vector3.new(9, 6, 9),
		cframe = stage * CFrame.new(0, 0, 0),
		color = RGB(110, 80, 70),
		material = Enum.Material.Basalt,
	})
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		piece(m, {
			size = Vector3.new(0.4, 0.3, 3),
			cframe = stage * CFrame.new(math.cos(a) * 3.2, -0.5, math.sin(a) * 3.2) * CFrame.Angles(0, -a, 0.4),
			color = RGB(255, 120, 30),
			material = Enum.Material.Neon,
		})
	end
	local top = piece(m, {
		size = Vector3.new(6, 0.4, 6),
		cframe = stage * CFrame.new(0, 2.8, 0),
		color = RGB(90, 70, 60),
		material = Enum.Material.Basalt,
	})
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = FxKit.TEXTURES.Fire
	fire.Color = FxKit.colors({ RGB(255, 200, 60), RGB(255, 60, 0) })
	fire.Size = FxKit.seq(2, 0.3)
	fire.Transparency = FxKit.seq(0.3, 1)
	fire.Rate = 20
	fire.Lifetime = NumberRange.new(0.4, 0.8)
	fire.Speed = NumberRange.new(-3, -1)
	fire.LightEmission = 1
	fire.Parent = top
	m.Parent = parent
	return m, 3
end

W.Podiums.podium_lava_throne = function(stage, parent)
	local m = Instance.new("Model")
	cylinder(m, 0.4, 12, stage * CFrame.new(0, 0.2, 0), RGB(255, 90, 0), Enum.Material.Neon)
	piece(m, {
		size = Vector3.new(7, 2, 7),
		cframe = stage * CFrame.new(0, 1.4, 0),
		color = RGB(35, 25, 35),
		material = Enum.Material.Basalt,
	})
	piece(m, {
		size = Vector3.new(6, 9, 1.2),
		cframe = stage * CFrame.new(0, 6, 3),
		color = RGB(30, 20, 30),
		material = Enum.Material.Basalt,
	})
	for side = -1, 1, 2 do
		piece(m, {
			size = Vector3.new(1.2, 3, 5),
			cframe = stage * CFrame.new(side * 3, 3.5, 0.5),
			color = RGB(30, 20, 30),
			material = Enum.Material.Basalt,
		})
		piece(m, {
			class = "WedgePart",
			size = Vector3.new(0.8, 3, 1.2),
			cframe = stage * CFrame.new(side * 2.4, 12, 3),
			color = RGB(255, 100, 10),
			material = Enum.Material.Neon,
		})
	end
	m.Parent = parent
	return m, 2.4
end

W.Podiums.podium_galaxy = function(stage, parent)
	local m = Instance.new("Model")
	cylinder(m, 1, 9, stage * CFrame.new(0, 0.5, 0), RGB(25, 15, 50), Enum.Material.SmoothPlastic)
	local portal = cylinder(
		m,
		0.3,
		14,
		stage * CFrame.new(0, 8, 5) * CFrame.Angles(math.rad(90), 0, 0),
		RGB(140, 70, 255),
		Enum.Material.ForceField,
		0.1
	)
	portal.Name = "Portal"
	ringOf(m, 18, 7.2, stage * CFrame.new(0, 8, 5) * CFrame.Angles(math.rad(90), 0, 0), function(i, cf)
		piece(m, {
			size = Vector3.new(2.6, 0.5, 0.5),
			cframe = cf,
			color = Color3.fromHSV(0.7 + (i % 6) / 30, 0.7, 1),
			material = Enum.Material.Neon,
		})
	end)
	m.Parent = parent
	return m, 1
end

W.Podiums.podium_summit = function(stage, parent)
	local m = Instance.new("Model")
	for i = 0, 3 do
		cylinder(
			m,
			2,
			12 - i * 3,
			stage * CFrame.new(0, 1 + i * 1.6, 0),
			RGB(130, 140, 160):Lerp(RGB(240, 250, 255), i / 3),
			if i == 3 then Enum.Material.Snow else Enum.Material.Rock
		)
	end
	piece(m, {
		size = Vector3.new(0.2, 4, 0.2),
		cframe = stage * CFrame.new(1.2, 8.5, 0),
		color = RGB(200, 200, 210),
		material = Enum.Material.Metal,
	})
	piece(m, {
		size = Vector3.new(1.6, 1, 0.1),
		cframe = stage * CFrame.new(2, 10, 0),
		color = RGB(255, 60, 60),
		material = Enum.Material.Fabric,
	})
	m.Parent = parent
	return m, 6.8
end

W.Podiums.podium_rainbow_arch = function(stage, parent)
	local m = Instance.new("Model")
	piece(m, { size = Vector3.new(8, 2, 8), cframe = stage * CFrame.new(0, 1, 0), color = RGB(255, 255, 255) })
	for band = 0, 6 do
		local r = 9 - band * 0.8
		for s = 0, 15 do
			local a = s / 15 * math.pi
			piece(m, {
				size = Vector3.new(0.8, 2, 0.8),
				cframe = stage * CFrame.new(math.cos(a) * r, 2 + math.sin(a) * r, 2) * CFrame.Angles(0, 0, a),
				color = Color3.fromHSV(band / 7, 0.8, 1),
				material = Enum.Material.Neon,
			})
		end
	end
	m.Parent = parent
	return m, 2
end

W.Podiums.podium_void_rift = function(stage, parent)
	local m = Instance.new("Model")
	cylinder(m, 0.6, 10, stage * CFrame.new(0, 0.3, 0), RGB(10, 0, 20), Enum.Material.SmoothPlastic)
	for i = 0, 4 do
		local h = 10 + i * 2
		piece(m, {
			size = Vector3.new(0.5, h, 0.3),
			cframe = stage * CFrame.new(-4 + i * 2, h / 2, 4) * CFrame.Angles(0, 0, (i - 2) * 0.12),
			color = RGB(150, 70, 255),
			material = Enum.Material.Neon,
			transparency = 0.15,
		})
	end
	cylinder(
		m,
		0.2,
		9,
		stage * CFrame.new(0, 7, 5) * CFrame.Angles(math.rad(90), 0, 0),
		RGB(0, 0, 0),
		Enum.Material.SmoothPlastic
	)
	m.Parent = parent
	return m, 0.6
end

W.Podiums.podium_glacier = function(stage, parent)
	local m = Instance.new("Model")
	piece(m, {
		size = Vector3.new(9, 3, 9),
		cframe = stage * CFrame.new(0, 1.5, 0),
		color = RGB(200, 240, 255),
		material = Enum.Material.Glacier,
	})
	piece(m, {
		size = Vector3.new(6, 8, 1.2),
		cframe = stage * CFrame.new(0, 7, 3.2),
		color = RGB(170, 230, 255),
		material = Enum.Material.Ice,
		transparency = 0.1,
	})
	ringOf(m, 5, 2.4, stage * CFrame.new(0, 11, 3.2), function(i, cf)
		piece(m, {
			class = "WedgePart",
			size = Vector3.new(0.5, 2 + (i % 2), 0.8),
			cframe = cf,
			color = RGB(220, 250, 255),
			material = Enum.Material.Glass,
			transparency = 0.1,
		})
	end)
	m.Parent = parent
	return m, 3
end

-- ============================================================ VICTORY EFFECTS
-- function(standCF: CFrame, character: Model?) — schedules the celebration.
W.Effects = {}

local function above(cf: CFrame, y: number): Vector3
	return (cf * CFrame.new(0, y, 0)).Position
end

local function fireworks(center: Vector3, count: number, spread: number)
	for i = 1, count do
		task.delay(i * 0.35, function()
			local pos = center
				+ Vector3.new((math.random() - 0.5) * spread, 10 + math.random() * 8, (math.random() - 0.5) * spread)
			local hue = math.random()
			Bursts.sphere(
				pos,
				{ color = Color3.fromHSV(hue, 0.7, 1), from = 0.5, to = 6, duration = 0.4, transparency = 0.5 }
			)
			Bursts.debris(pos, {
				shape = "Ball",
				colors = { Color3.fromHSV(hue, 0.8, 1), Color3.fromHSV((hue + 0.1) % 1, 0.6, 1) },
				count = 16,
				speed = 12,
				up = 4,
				lifetime = 1.2,
				size = Vector3.new(0.3, 0.3, 0.3),
				gravity = 10,
			})
			Bursts.flash(pos, Color3.fromHSV(hue, 0.6, 1), 30, 3, 0.5)
		end)
	end
end

W.Effects.win_victory_dance = function(cf)
	Bursts.Land.land_confetti(above(cf, 3))
	task.delay(1, function()
		Bursts.Land.land_confetti(above(cf, 3))
	end)
end

W.Effects.win_backflip = function(cf)
	task.delay(0.9, function()
		Bursts.emit(above(cf, 0.3), {
			texture = "Smoke",
			color = { RGB(230, 230, 240) },
			size = { 1.5, 3 },
			transparency = { 0.3, 1 },
			lifetime = { 0.5, 0.8 },
			speed = { 4, 6 },
			spread = 90,
			lightEmission = 0.1,
			drag = 4,
		}, 14)
		Bursts.shockwave(above(cf, 0.1), { color = RGB(140, 220, 255), from = 1, to = 9, duration = 0.4 })
	end)
end

W.Effects.win_crown = function(cf, character)
	-- A crown drops from the sky onto the winner's head.
	local head = character and character:FindFirstChild("Head")
	local target = if head then head.CFrame.Position + Vector3.new(0, 1, 0) else above(cf, 6)
	local crown = Instance.new("Model")
	crown.Name = "VictoryCrown"
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		piece(crown, {
			class = "WedgePart",
			size = Vector3.new(0.2, 0.7, 0.5),
			cframe = CFrame.new(target + Vector3.new(math.cos(a) * 0.7, 20, math.sin(a) * 0.7))
				* CFrame.Angles(0, -a, 0),
			color = RGB(255, 210, 60),
			material = Enum.Material.Metal,
		})
	end
	crown.Parent = workspace
	game:GetService("Debris"):AddItem(crown, 9)
	for _, part in crown:GetChildren() do
		FxKit.tween(part, 1.2, { CFrame = part.CFrame - Vector3.new(0, 20, 0) }, Enum.EasingStyle.Bounce)
	end
	task.delay(1.2, function()
		Bursts.glyphs(target, {
			chars = { "✦", "★" },
			colors = { RGB(255, 230, 120) },
			count = 10,
			speed = 5,
			up = 3,
			lifetime = 0.8,
			size = 1,
		})
		Bursts.flash(target, RGB(255, 220, 120), 16, 3, 0.6)
	end)
end

W.Effects.win_fireworks = function(cf)
	fireworks(cf.Position, 8, 20)
end

W.Effects.win_superhero = function(cf)
	task.delay(0.4, function()
		Bursts.Land.land_meteor(above(cf, 3))
		Bursts.ring(above(cf, 0.2), { color = RGB(255, 255, 255), from = 2, to = 12, duration = 0.5 })
	end)
end

W.Effects.win_glitch = function(cf)
	for i = 0, 6 do
		task.delay(i * 0.25, function()
			Bursts.debris(above(cf, 3), {
				colors = { RGB(0, 255, 180), RGB(255, 0, 200) },
				count = 8,
				speed = 5,
				up = 3,
				lifetime = 0.5,
				size = Vector3.new(0.6, 0.6, 0.6),
				aligned = true,
				gravity = 0,
			})
		end)
	end
	Bursts.text(above(cf, 8), "SYSTEM OVERRIDE", RGB(0, 255, 180), 2, RGB(255, 0, 200))
end

W.Effects.win_lightning = function(cf)
	for i = 0, 3 do
		task.delay(0.5 + i * 0.3, function()
			local target = above(cf, 3)
			Bursts.bolt(
				target + Vector3.new((math.random() - 0.5) * 6, 35, (math.random() - 0.5) * 6),
				target,
				RGB(255, 255, 170),
				3
			)
			Bursts.flash(target, RGB(190, 210, 255), 30, 6, 0.3)
		end)
	end
end

W.Effects.win_magic_portal = function(cf)
	Bursts.Jump.jump_magic_portal(above(cf, 3))
	task.delay(0.4, function()
		Bursts.ring(
			above(cf, 0.3),
			{ color = RGB(200, 120, 255), from = 4, to = 4.5, duration = 1.2, segments = 16, rise = 6 }
		)
	end)
end

W.Effects.win_golden_throne = function(cf)
	Bursts.emit(above(cf, 2), {
		texture = "Sparkle",
		color = { RGB(255, 240, 170), RGB(255, 190, 40) },
		size = { 0.6, 0 },
		lifetime = { 1, 2 },
		speed = { 2, 5 },
		spread = 60,
		drag = 1,
	}, 50)
	Bursts.flash(above(cf, 4), RGB(255, 210, 100), 24, 3, 2)
end

W.Effects.win_cosmic = function(cf)
	Bursts.Jump.jump_cosmic(above(cf, 3))
	fireworks(cf.Position, 4, 14)
	task.delay(1, function()
		Bursts.Death.death_stardust(above(cf, 4))
	end)
end

W.Effects.win_dragon = function(cf)
	-- A fire "dragon" (chain of flaming orbs) circles the winner.
	local segments = {}
	for i = 1, 10 do
		local orb = piece(workspace, {
			shape = Enum.PartType.Ball,
			size = Vector3.new(2.2 - i * 0.15, 2.2 - i * 0.15, 2.2 - i * 0.15),
			cframe = cf,
			color = RGB(255, 140 - i * 8, 20),
			material = Enum.Material.Neon,
		})
		game:GetService("Debris"):AddItem(orb, 6)
		table.insert(segments, orb)
	end
	local start = os.clock()
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local t = os.clock() - start
		if t > 5 then
			connection:Disconnect()
			return
		end
		for i, orb in segments do
			local a = t * 2.4 - i * 0.28
			orb.CFrame = cf * CFrame.new(math.cos(a) * 7, 4 + math.sin(a * 2) * 2, math.sin(a) * 7)
		end
	end)
	task.delay(2.5, function()
		Bursts.Jump.jump_fire_ring(above(cf, 3))
		Bursts.flash(above(cf, 4), RGB(255, 120, 30), 30, 5, 1)
	end)
end

return W
