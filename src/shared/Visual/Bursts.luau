--!nonstrict
-- One-shot world effects: jump effects, landing effects and elimination
-- effects. Purely visual: every part is anchored, non-colliding and
-- auto-destroyed. Counts scale with the viewer's quality level.

local Debris = game:GetService("Debris")

local FxKit = require(script.Parent.FxKit)

local RGB = Color3.fromRGB
local CYL = CFrame.Angles(0, 0, math.rad(90))

local B = {}
B.quality = FxKit.DEFAULT_QUALITY

local folder: Folder? = nil
local function fxFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "DTTG_Bursts"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local function count(n: number, kind: "particles" | "debris"): number
	return math.max(1, math.floor(n * (B.quality[kind] or 1) + 0.5))
end

function B.part(props): BasePart
	local part = Instance.new((props.class or "Part") :: any) :: BasePart
	if props.shape and part:IsA("Part") then
		(part :: Part).Shape = props.shape
	end
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color or Color3.new(1, 1, 1)
	part.Material = props.material or Enum.Material.Neon
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = fxFolder()
	Debris:AddItem(part, props.life or 2)
	return part
end

-- Flat expanding disc/ring on the ground.
function B.shockwave(position: Vector3, props)
	local from, to = props.from or 1, props.to or 10
	local part = B.part({
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(props.height or 0.2, from, from),
		cframe = CFrame.new(position) * CYL,
		color = props.color,
		material = props.material,
		transparency = props.transparency or 0.15,
		life = (props.duration or 0.5) + 0.1,
	})
	FxKit.tween(part, props.duration or 0.5, { Size = Vector3.new(props.height or 0.2, to, to), Transparency = 1 })
	return part
end

function B.sphere(position: Vector3, props)
	local from, to = props.from or 1, props.to or 6
	local part = B.part({
		shape = Enum.PartType.Ball,
		size = Vector3.new(from, from, from),
		cframe = CFrame.new(position),
		color = props.color,
		material = props.material,
		transparency = props.transparency or 0.2,
		life = (props.duration or 0.5) + 0.1,
	})
	FxKit.tween(part, props.duration or 0.5, { Size = Vector3.new(to, to, to), Transparency = 1 }, props.style)
	return part
end

-- Ring of segments flying outward (reads as a hollow ring, not a disc).
function B.ring(position: Vector3, props)
	local segments = props.segments or 14
	local radius0, radius1 = props.from or 1, props.to or 7
	for i = 0, segments - 1 do
		local a = i / segments * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local start = CFrame.lookAt(position + dir * radius0, position + dir * radius0 + Vector3.new(-dir.Z, 0, dir.X))
		local part = B.part({
			size = props.size or Vector3.new(0.25, 0.25, 1.2),
			cframe = start,
			color = if props.rainbow then Color3.fromHSV(i / segments, 0.8, 1) else props.color,
			life = (props.duration or 0.6) + 0.1,
		})
		FxKit.tween(
			part,
			props.duration or 0.6,
			{ CFrame = start + dir * (radius1 - radius0) + Vector3.new(0, props.rise or 0, 0), Transparency = 1 }
		)
	end
end

function B.emit(position: Vector3, props, amount: number)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = terrain or fxFolder()
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Texture = FxKit.TEXTURES[props.texture or "Sparkle"] or props.texture
	emitter.Color = if typeof(props.color) == "ColorSequence"
		then props.color
		else FxKit.colors(props.color or { Color3.new(1, 1, 1) })
	emitter.Size = FxKit.seq(table.unpack(props.size or { 0.6, 0 }))
	emitter.Transparency = FxKit.seq(table.unpack(props.transparency or { 0, 1 }))
	local life = props.lifetime or { 0.5, 1 }
	emitter.Lifetime = NumberRange.new(life[1], life[2])
	emitter.Speed = NumberRange.new(props.speed and props.speed[1] or 5, props.speed and props.speed[2] or 10)
	emitter.SpreadAngle = Vector2.new(props.spread or 180, props.spread or 180)
	emitter.Acceleration = props.acceleration or Vector3.zero
	emitter.Drag = props.drag or 0
	emitter.LightEmission = props.lightEmission or 1
	emitter.LightInfluence = 0
	emitter.RotSpeed = NumberRange.new(-120, 120)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Parent = attachment
	local amountToEmit = count(amount, "particles")
	pcall(function()
		emitter:Emit(amountToEmit)
	end)
	Debris:AddItem(attachment, life[2] + 0.3)
end

function B.glyphs(position: Vector3, props)
	if B.quality.glyphs <= 0 then
		return
	end
	local n = math.max(1, math.floor((props.count or 8) * B.quality.glyphs))
	for i = 1, n do
		local a = i / n * math.pi * 2 + math.random() * 0.4
		local speed = (props.speed or 6) * (0.7 + math.random() * 0.6)
		FxKit.SpawnGlyph({
			char = props.chars[math.random(1, #props.chars)],
			color = props.colors[math.random(1, #props.colors)],
			position = position + (props.offset or Vector3.zero),
			velocity = Vector3.new(
				math.cos(a) * speed,
				(props.up or 3) * (0.6 + math.random() * 0.8),
				math.sin(a) * speed
			),
			lifetime = (props.lifetime or 0.9) * (0.8 + math.random() * 0.4),
			size = (props.size or 1.2) * (0.7 + math.random() * 0.6),
			spin = props.spin or 180,
		})
	end
end

function B.debris(position: Vector3, props)
	local n = count(props.count or 10, "debris")
	for _ = 1, n do
		local a = math.random() * math.pi * 2
		local speed = (props.speed or 8) * (0.5 + math.random() * 0.8)
		local size = props.size or Vector3.new(0.4, 0.4, 0.4)
		FxKit.SpawnDebris({
			shape = props.shape,
			size = size * (0.7 + math.random() * 0.6),
			color = props.colors[math.random(1, #props.colors)],
			material = props.material,
			transparency = props.transparency,
			position = position + Vector3.new(
				(math.random() - 0.5) * (props.spread or 1),
				(math.random() - 0.5) * (props.spreadY or props.spread or 1),
				(math.random() - 0.5) * (props.spread or 1)
			),
			velocity = Vector3.new(math.cos(a) * speed, (props.up or 8) * (0.5 + math.random()), math.sin(a) * speed),
			lifetime = (props.lifetime or 1) * (0.8 + math.random() * 0.4),
			gravity = props.gravity or 40,
			cframe = if props.aligned then CFrame.new(position) else nil,
		})
	end
end

function B.flash(position: Vector3, color: Color3, range: number, brightness: number, duration: number)
	if not B.quality.lights then
		return
	end
	local holder = B.part({
		size = Vector3.new(0.2, 0.2, 0.2),
		cframe = CFrame.new(position),
		transparency = 1,
		life = duration + 0.1,
	})
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = holder
	FxKit.tween(light, duration, { Brightness = 0 })
end

function B.column(position: Vector3, props)
	local height = props.height or 30
	local part = B.part({
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(height, props.width or 2, props.width or 2),
		cframe = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CYL,
		color = props.color,
		transparency = props.transparency or 0.2,
		life = (props.duration or 0.6) + 0.1,
	})
	FxKit.tween(
		part,
		props.duration or 0.6,
		{ Size = Vector3.new(height, 0.05, 0.05), Transparency = 1 },
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)
	return part
end

function B.text(position: Vector3, text: string, color: Color3, duration: number, stroke: Color3?)
	local holder = B.part({
		size = Vector3.new(0.2, 0.2, 0.2),
		cframe = CFrame.new(position),
		transparency = 1,
		life = duration + 0.1,
	})
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(2, 1)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = stroke or Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = holder
	FxKit.tween(gui, duration * 0.3, { Size = UDim2.fromScale(9, 4.5) }, Enum.EasingStyle.Back)
	FxKit.tween(holder, duration, { CFrame = CFrame.new(position + Vector3.new(0, 4, 0)) })
	task.delay(duration * 0.6, function()
		if label.Parent then
			FxKit.tween(label, duration * 0.4, { TextTransparency = 1, TextStrokeTransparency = 1 })
		end
	end)
end

function B.bolt(from: Vector3, to: Vector3, color: Color3, branches: number?)
	FxKit.SpawnBolt(from, to, color, 0.3, 2.5, 8)
	for _ = 1, branches or 0 do
		local mid = from:Lerp(to, 0.3 + math.random() * 0.4)
		FxKit.SpawnBolt(
			mid,
			mid + Vector3.new((math.random() - 0.5) * 8, -math.random() * 6, (math.random() - 0.5) * 8),
			color,
			0.25,
			1.5,
			4
		)
	end
end

local function feetOf(position: Vector3): Vector3
	return position - Vector3.new(0, 2.8, 0)
end

-- ============================================================== JUMP EFFECTS
B.Jump = {}

B.Jump.jump_smoke_puff = function(p)
	local f = feetOf(p)
	B.emit(f, {
		texture = "Smoke",
		color = { RGB(240, 240, 250), RGB(170, 170, 190) },
		size = { 1.2, 2.6 },
		transparency = { 0.2, 1 },
		lifetime = { 0.5, 0.8 },
		speed = { 3, 6 },
		spread = 90,
		lightEmission = 0.1,
		drag = 4,
	}, 10)
end

B.Jump.jump_star_burst = function(p)
	B.glyphs(feetOf(p), {
		chars = { "★", "✦" },
		colors = { RGB(255, 240, 100), RGB(255, 190, 40) },
		count = 8,
		speed = 7,
		up = 4,
		lifetime = 0.6,
		size = 1,
	})
end

B.Jump.jump_frost_burst = function(p)
	local f = feetOf(p)
	B.shockwave(f, {
		color = RGB(200, 245, 255),
		from = 1,
		to = 9,
		duration = 0.45,
		material = Enum.Material.Ice,
		transparency = 0.3,
	})
	B.debris(f, {
		shape = "Wedge",
		material = Enum.Material.Ice,
		colors = { RGB(220, 250, 255), RGB(140, 210, 255) },
		count = 8,
		speed = 9,
		up = 6,
		lifetime = 0.7,
		size = Vector3.new(0.3, 0.6, 0.4),
	})
end

B.Jump.jump_fire_ring = function(p)
	local f = feetOf(p)
	B.ring(f, { color = RGB(255, 140, 20), from = 1, to = 8, duration = 0.5, segments = 16 })
	B.emit(f, {
		texture = "Fire",
		color = { RGB(255, 220, 90), RGB(255, 60, 0) },
		size = { 1.5, 0.2 },
		lifetime = { 0.3, 0.5 },
		speed = { 6, 9 },
		spread = 85,
	}, 18)
	B.flash(f, RGB(255, 140, 40), 14, 3, 0.4)
end

B.Jump.jump_pixel = function(p)
	B.debris(feetOf(p), {
		colors = { RGB(0, 255, 140), RGB(0, 160, 255), RGB(255, 255, 255) },
		count = 14,
		speed = 10,
		up = 7,
		lifetime = 0.7,
		size = Vector3.new(0.45, 0.45, 0.45),
		aligned = true,
		gravity = 25,
	})
end

B.Jump.jump_rainbow_wave = function(p)
	local f = feetOf(p)
	for i = 0, 2 do
		task.delay(i * 0.08, function()
			B.ring(
				f + Vector3.new(0, i * 0.2, 0),
				{ rainbow = true, from = 1, to = 6 + i * 2, duration = 0.55, segments = 18 }
			)
		end)
	end
end

B.Jump.jump_lightning = function(p)
	local f = feetOf(p)
	B.bolt(f + Vector3.new(math.random(-3, 3), 22, math.random(-3, 3)), f, RGB(255, 255, 160), 2)
	B.flash(f, RGB(180, 200, 255), 18, 5, 0.25)
	B.emit(f, {
		texture = "Spark",
		color = { RGB(255, 255, 200), RGB(130, 170, 255) },
		size = { 0.4, 0 },
		lifetime = { 0.2, 0.4 },
		speed = { 10, 16 },
		spread = 80,
	}, 16)
end

B.Jump.jump_crystals = function(p)
	local f = feetOf(p)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local base = f + Vector3.new(math.cos(a) * 1.6, 0, math.sin(a) * 1.6)
		local spike = B.part({
			class = "WedgePart",
			size = Vector3.new(0.4, 0.1, 0.6),
			cframe = CFrame.lookAt(base, base + Vector3.new(math.cos(a), 0, math.sin(a)))
				* CFrame.Angles(math.rad(-20), 0, 0),
			color = if i % 2 == 0 then RGB(170, 250, 255) else RGB(210, 130, 255),
			material = Enum.Material.Glass,
			transparency = 0.1,
			life = 0.9,
		})
		FxKit.tween(spike, 0.15, { Size = Vector3.new(0.4, 2.2, 0.6) }, Enum.EasingStyle.Back)
		task.delay(0.4, function()
			if spike.Parent then
				FxKit.tween(spike, 0.4, { Transparency = 1, Size = Vector3.new(0.4, 0.2, 0.6) })
			end
		end)
	end
end

B.Jump.jump_void_pulse = function(p)
	local f = feetOf(p)
	local orb = B.sphere(f + Vector3.new(0, 1, 0), {
		color = RGB(120, 50, 220),
		from = 6,
		to = 0.5,
		duration = 0.35,
		transparency = 0.3,
		style = Enum.EasingStyle.Quad,
	})
	orb.Material = Enum.Material.ForceField
	B.emit(f + Vector3.new(0, 1, 0), {
		color = { RGB(170, 90, 255), RGB(20, 0, 50) },
		size = { 0.5, 0 },
		lifetime = { 0.3, 0.4 },
		speed = { -12, -8 },
		spread = 180,
	}, 20)
end

B.Jump.jump_magic_portal = function(p)
	local f = feetOf(p) + Vector3.new(0, 0.1, 0)
	local disc = B.part({
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(0.1, 0.5, 0.5),
		cframe = CFrame.new(f) * CYL,
		color = RGB(170, 90, 255),
		material = Enum.Material.ForceField,
		life = 1,
	})
	FxKit.tween(disc, 0.2, { Size = Vector3.new(0.1, 6, 6) }, Enum.EasingStyle.Back)
	task.delay(0.5, function()
		if disc.Parent then
			FxKit.tween(disc, 0.4, { Size = Vector3.new(0.1, 0.2, 0.2), Transparency = 1 })
		end
	end)
	B.ring(f, { color = RGB(80, 230, 255), from = 3, to = 3.2, duration = 0.8, segments = 12, rise = 3 })
	B.glyphs(f, {
		chars = { "✧", "⟡", "✦" },
		colors = { RGB(210, 150, 255), RGB(110, 230, 255) },
		count = 6,
		speed = 2,
		up = 6,
		lifetime = 0.8,
		size = 0.9,
	})
end

B.Jump.jump_cosmic = function(p)
	local f = feetOf(p)
	B.sphere(f, { color = RGB(160, 80, 255), from = 1, to = 9, duration = 0.5, transparency = 0.4 })
	B.emit(f, {
		texture = "Smoke",
		color = { RGB(190, 110, 255), RGB(60, 70, 220) },
		size = { 2, 4 },
		lifetime = { 0.6, 0.9 },
		speed = { 4, 8 },
		spread = 90,
		lightEmission = 1,
		drag = 3,
	}, 10)
	B.glyphs(f, {
		chars = { "★", "✦", "✧" },
		colors = { RGB(255, 255, 255), RGB(255, 240, 150), RGB(190, 160, 255) },
		count = 10,
		speed = 9,
		up = 5,
		lifetime = 0.8,
		size = 1,
	})
	B.flash(f, RGB(180, 120, 255), 16, 3, 0.4)
end

B.Jump.jump_light_wings = function(p, character)
	local f = feetOf(p)
	B.emit(f, {
		color = { RGB(255, 255, 230), RGB(140, 220, 255) },
		size = { 0.5, 0 },
		lifetime = { 0.5, 0.8 },
		speed = { 4, 7 },
		spread = 70,
	}, 18)
	B.flash(p, RGB(220, 240, 255), 16, 3, 0.6)
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	if torso and torso:IsA("BasePart") then
		for side = -1, 1, 2 do
			for i = 0, 3 do
				local feather = Instance.new("Part")
				feather.Size = Vector3.new(1.4 + i * 0.4, 0.35, 0.1)
				feather.Color = RGB(255, 255, 240):Lerp(RGB(140, 220, 255), i / 4)
				feather.Material = Enum.Material.Neon
				feather.Transparency = 0.15
				feather.CanCollide = false
				feather.CanQuery = false
				feather.CanTouch = false
				feather.Massless = true
				feather.CastShadow = false
				local weld = Instance.new("Weld")
				weld.Part0 = torso
				weld.Part1 = feather
				weld.C0 = CFrame.new(side * (0.9 + i * 0.4), 0.6 - i * 0.3, 0.6)
					* CFrame.Angles(0, 0, side * math.rad(15 + i * 10))
				weld.Parent = feather
				feather.Parent = fxFolder()
				Debris:AddItem(feather, 1)
				FxKit.tween(feather, 0.9, { Transparency = 1 })
			end
		end
	end
end

B.Jump.jump_rank_ring = function(p)
	local f = feetOf(p)
	B.ring(f, { color = RGB(120, 220, 255), from = 1, to = 5, duration = 0.45, segments = 10 })
	B.ring(
		f + Vector3.new(0, 0.3, 0),
		{ color = RGB(255, 255, 255), from = 1, to = 3.5, duration = 0.45, segments = 8 }
	)
end

-- =========================================================== LANDING EFFECTS
B.Land = {}

B.Land.land_energy_wave = function(p)
	B.shockwave(feetOf(p), { color = RGB(140, 235, 255), from = 1, to = 10, duration = 0.4, height = 0.15 })
end

B.Land.land_confetti = function(p)
	B.debris(feetOf(p), {
		colors = { RGB(255, 90, 160), RGB(90, 220, 255), RGB(255, 230, 80), RGB(120, 255, 120) },
		count = 18,
		speed = 7,
		up = 10,
		lifetime = 1.1,
		size = Vector3.new(0.35, 0.05, 0.25),
		gravity = 18,
	})
end

B.Land.land_ink = function(p)
	local f = feetOf(p) + Vector3.new(0, 0.06, 0)
	for i = 0, 5 do
		local a = math.random() * math.pi * 2
		local r = if i == 0 then 0 else 1 + math.random() * 1.8
		local d = if i == 0 then 3.4 else 0.6 + math.random() * 1
		local blot = B.part({
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(0.06, 0.2, 0.2),
			cframe = CFrame.new(f + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) * CYL,
			color = RGB(50, 25, 130),
			material = Enum.Material.Glass,
			life = 1.8,
		})
		FxKit.tween(blot, 0.12, { Size = Vector3.new(0.06, d, d) }, Enum.EasingStyle.Back)
		task.delay(1.1, function()
			if blot.Parent then
				FxKit.tween(blot, 0.6, { Transparency = 1 })
			end
		end)
	end
end

B.Land.land_neon_pulse = function(p)
	local f = feetOf(p) + Vector3.new(0, 0.05, 0)
	for i = 0, 1 do
		task.delay(i * 0.12, function()
			local square = B.part({
				size = Vector3.new(1, 0.08, 1),
				cframe = CFrame.new(f),
				color = if i == 0 then RGB(255, 0, 230) else RGB(0, 255, 240),
				transparency = 0.3,
				life = 0.6,
			})
			FxKit.tween(square, 0.45, { Size = Vector3.new(9, 0.08, 9), Transparency = 1 })
		end)
	end
end

B.Land.land_glow_cracks = function(p)
	local f = feetOf(p) + Vector3.new(0, 0.05, 0)
	for i = 0, 6 do
		local a = i / 7 * math.pi * 2 + math.random() * 0.3
		local length = 1.5 + math.random() * 2
		local previous = f
		for s = 1, 3 do
			local nextPoint = f
				+ Vector3.new(
					math.cos(a + (math.random() - 0.5) * 0.6) * length * s / 3,
					0,
					math.sin(a + (math.random() - 0.5) * 0.6) * length * s / 3
				)
			FxKit.SpawnSegment(previous, nextPoint, 0.12, RGB(255, 190, 70), 0.9)
			previous = nextPoint
		end
	end
	B.flash(f, RGB(255, 160, 60), 10, 2, 0.5)
end

B.Land.land_rainbow_splash = function(p)
	B.debris(feetOf(p), {
		shape = "Ball",
		colors = { RGB(255, 80, 80), RGB(255, 200, 60), RGB(80, 230, 120), RGB(80, 150, 255), RGB(200, 90, 255) },
		count = 16,
		speed = 8,
		up = 7,
		lifetime = 0.8,
		size = Vector3.new(0.45, 0.45, 0.45),
		gravity = 35,
	})
end

B.Land.land_ice_shatter = function(p)
	local f = feetOf(p)
	B.debris(f, {
		shape = "Wedge",
		material = Enum.Material.Ice,
		colors = { RGB(230, 250, 255), RGB(130, 200, 255) },
		count = 14,
		speed = 10,
		up = 8,
		lifetime = 0.8,
		size = Vector3.new(0.4, 0.8, 0.5),
	})
	B.emit(f, {
		texture = "Smoke",
		color = { RGB(240, 250, 255) },
		size = { 1, 2 },
		transparency = { 0.4, 1 },
		lifetime = { 0.4, 0.6 },
		speed = { 3, 5 },
		spread = 90,
		lightEmission = 0.3,
		drag = 4,
	}, 8)
end

B.Land.land_flame_ring = function(p)
	local f = feetOf(p)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		B.emit(f + Vector3.new(math.cos(a) * 2.5, 0, math.sin(a) * 2.5), {
			texture = "Fire",
			color = { RGB(255, 220, 90), RGB(255, 60, 0) },
			size = { 1.4, 0.2 },
			lifetime = { 0.4, 0.7 },
			speed = { 3, 5 },
			spread = 10,
		}, 3)
	end
	B.flash(f, RGB(255, 140, 40), 14, 3, 0.5)
end

B.Land.land_meteor = function(p)
	local f = feetOf(p)
	B.shockwave(f, { color = RGB(255, 150, 60), from = 1, to = 11, duration = 0.5 })
	B.emit(f, {
		texture = "Smoke",
		color = { RGB(140, 110, 90), RGB(80, 60, 50) },
		size = { 1.6, 3.5 },
		transparency = { 0.3, 1 },
		lifetime = { 0.6, 1 },
		speed = { 4, 7 },
		spread = 85,
		lightEmission = 0,
		drag = 3,
	}, 12)
	B.debris(f, {
		colors = { RGB(120, 90, 70), RGB(255, 140, 40) },
		count = 10,
		speed = 9,
		up = 10,
		lifetime = 0.9,
		size = Vector3.new(0.4, 0.4, 0.4),
		material = Enum.Material.Slate,
	})
	B.flash(f, RGB(255, 150, 60), 16, 4, 0.4)
end

B.Land.land_star = function(p)
	local f = feetOf(p) + Vector3.new(0, 0.06, 0)
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2 - math.pi / 2
		FxKit.SpawnSegment(f, f + Vector3.new(math.cos(a) * 4, 0, math.sin(a) * 4), 0.35, RGB(255, 240, 150), 0.6, 0.1)
	end
	B.glyphs(f, {
		chars = { "✦", "✧", "★" },
		colors = { RGB(255, 245, 170), RGB(190, 150, 255) },
		count = 6,
		speed = 3,
		up = 3,
		lifetime = 0.8,
		size = 0.8,
	})
end

B.Land.land_royal_crest = function(p)
	local f = feetOf(p) + Vector3.new(0, 0.06, 0)
	local crest = B.part({
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(0.08, 0.5, 0.5),
		cframe = CFrame.new(f) * CYL,
		color = RGB(255, 215, 80),
		material = Enum.Material.Metal,
		life = 1.4,
	})
	FxKit.tween(crest, 0.18, { Size = Vector3.new(0.08, 5, 5) }, Enum.EasingStyle.Back)
	task.delay(0.8, function()
		if crest.Parent then
			FxKit.tween(crest, 0.5, { Transparency = 1 })
		end
	end)
	B.glyphs(f + Vector3.new(0, 0.5, 0), {
		chars = { "⚜" },
		colors = { RGB(255, 225, 100) },
		count = 1,
		speed = 0,
		up = 2,
		lifetime = 1,
		size = 3,
		spin = 0,
	})
	B.ring(f, { color = RGB(255, 225, 100), from = 2.5, to = 6, duration = 0.5, segments = 12 })
end

B.Land.land_black_hole = function(p)
	local f = feetOf(p) + Vector3.new(0, 0.8, 0)
	local hole = B.part({
		shape = Enum.PartType.Ball,
		size = Vector3.new(0.2, 0.2, 0.2),
		cframe = CFrame.new(f),
		color = RGB(0, 0, 0),
		material = Enum.Material.SmoothPlastic,
		life = 1.2,
	})
	FxKit.tween(hole, 0.25, { Size = Vector3.new(1.8, 1.8, 1.8) }, Enum.EasingStyle.Back)
	task.delay(0.7, function()
		if hole.Parent then
			FxKit.tween(hole, 0.3, { Size = Vector3.new(0.05, 0.05, 0.05) })
		end
	end)
	B.emit(f, {
		color = { RGB(180, 100, 255), RGB(60, 0, 120) },
		size = { 0.4, 0 },
		lifetime = { 0.5, 0.7 },
		speed = { -9, -6 },
		spread = 180,
	}, 26)
	B.ring(f, { color = RGB(150, 70, 255), from = 4, to = 0.5, duration = 0.6, segments = 12 })
end

-- ======================================================== ELIMINATION EFFECTS
B.Death = {}

B.Death.death_confetti = function(p)
	B.debris(p, {
		colors = { RGB(255, 90, 160), RGB(90, 220, 255), RGB(255, 230, 80), RGB(150, 255, 120) },
		count = 30,
		speed = 9,
		up = 14,
		lifetime = 1.6,
		size = Vector3.new(0.4, 0.05, 0.3),
		gravity = 16,
		spread = 2,
	})
	B.text(p + Vector3.new(0, 2, 0), "🎉", RGB(255, 255, 255), 1)
end

B.Death.death_color_smoke = function(p)
	B.emit(p, {
		texture = "Smoke",
		color = { RGB(255, 140, 220), RGB(140, 180, 255), RGB(190, 255, 200) },
		size = { 2, 5 },
		transparency = { 0.2, 1 },
		lifetime = { 1, 1.6 },
		speed = { 2, 5 },
		spread = 180,
		lightEmission = 0.4,
		drag = 2,
	}, 22)
end

B.Death.death_pixels = function(p)
	-- Body-shaped volume of cubes that drift up and fade.
	local n = math.floor(40 * B.quality.debris)
	for _ = 1, n do
		local offset = Vector3.new((math.random() - 0.5) * 2, (math.random() - 0.5) * 5, (math.random() - 0.5) * 1)
		local pos = p + offset
		FxKit.SpawnDebris({
			size = Vector3.new(0.45, 0.45, 0.45),
			color = if math.random() < 0.5 then RGB(0, 230, 255) else RGB(0, 120, 255),
			position = pos,
			velocity = Vector3.new(0, 2 + math.random() * 3, 0),
			lifetime = 1 + math.random() * 0.6,
			cframe = CFrame.new(pos),
			gravity = 0,
		})
	end
end

B.Death.death_ember = function(p)
	B.emit(p, {
		texture = "Spark",
		color = { RGB(255, 220, 100), RGB(255, 80, 0) },
		size = { 0.5, 0 },
		lifetime = { 1, 1.6 },
		speed = { 3, 8 },
		spread = 60,
		acceleration = Vector3.new(0, 6, 0),
	}, 40)
	B.flash(p, RGB(255, 120, 30), 14, 3, 0.8)
end

B.Death.death_rainbow = function(p)
	B.sphere(p, { color = RGB(255, 255, 255), from = 2, to = 8, duration = 0.35, transparency = 0.3 })
	B.ring(p, { rainbow = true, from = 1, to = 9, duration = 0.6, segments = 20 })
	B.debris(p, {
		shape = "Ball",
		colors = { RGB(255, 80, 80), RGB(255, 210, 60), RGB(80, 230, 120), RGB(80, 150, 255) },
		count = 16,
		speed = 9,
		up = 9,
		lifetime = 0.9,
		size = Vector3.new(0.5, 0.5, 0.5),
	})
end

B.Death.death_teleport = function(p)
	B.column(p - Vector3.new(0, 3, 0), { color = RGB(120, 255, 230), height = 40, width = 3, duration = 0.7 })
	B.emit(p, {
		color = { RGB(170, 255, 240), RGB(60, 140, 255) },
		size = { 0.5, 0 },
		lifetime = { 0.6, 1 },
		speed = { 6, 12 },
		spread = 15,
		acceleration = Vector3.new(0, 30, 0),
	}, 30)
	B.flash(p, RGB(120, 255, 230), 18, 4, 0.6)
end

B.Death.death_crystal = function(p)
	B.debris(p, {
		shape = "Wedge",
		material = Enum.Material.Glass,
		colors = { RGB(180, 250, 255), RGB(130, 170, 255), RGB(220, 160, 255) },
		count = 26,
		speed = 11,
		up = 10,
		lifetime = 1.2,
		size = Vector3.new(0.5, 1.1, 0.6),
		spread = 2,
		spreadY = 4,
	})
	B.flash(p, RGB(170, 230, 255), 14, 3, 0.4)
end

B.Death.death_retro = function(p)
	B.text(p + Vector3.new(0, 3, 0), "GAME OVER", RGB(255, 60, 60), 1.6, RGB(255, 230, 60))
	B.debris(p, {
		colors = { RGB(255, 60, 60), RGB(255, 230, 60) },
		count = 18,
		speed = 6,
		up = 6,
		lifetime = 0.9,
		size = Vector3.new(0.6, 0.6, 0.6),
		aligned = true,
		gravity = 20,
	})
end

B.Death.death_void = function(p)
	local orb = B.sphere(p, { color = RGB(60, 0, 120), from = 6, to = 0.2, duration = 0.45, transparency = 0.2 })
	orb.Material = Enum.Material.ForceField
	task.delay(0.45, function()
		B.sphere(p, { color = RGB(170, 90, 255), from = 0.5, to = 7, duration = 0.3, transparency = 0.3 })
	end)
	B.emit(p, {
		color = { RGB(170, 90, 255), RGB(10, 0, 30) },
		size = { 0.6, 0 },
		lifetime = { 0.4, 0.5 },
		speed = { -14, -9 },
		spread = 180,
	}, 30)
end

B.Death.death_stardust = function(p)
	B.emit(p, {
		texture = "Sparkle",
		color = { RGB(255, 245, 180), RGB(170, 130, 255) },
		size = { 0.7, 0 },
		lifetime = { 1.2, 2 },
		speed = { 1, 4 },
		spread = 180,
		drag = 1.5,
		acceleration = Vector3.new(0, 1.5, 0),
	}, 60)
	B.glyphs(p, {
		chars = { "✦", "✧", "★", "·" },
		colors = { RGB(255, 255, 255), RGB(255, 235, 150), RGB(190, 160, 255) },
		count = 14,
		speed = 3,
		up = 2,
		lifetime = 1.6,
		size = 0.9,
	})
end

B.Death.death_cosmic_ray = function(p)
	B.column(p - Vector3.new(0, 4, 0), { color = RGB(255, 255, 230), height = 80, width = 4, duration = 0.9 })
	task.delay(0.1, function()
		B.column(
			p - Vector3.new(0, 4, 0),
			{ color = RGB(120, 200, 255), height = 80, width = 7, duration = 0.7, transparency = 0.5 }
		)
	end)
	B.shockwave(p - Vector3.new(0, 2.8, 0), { color = RGB(200, 230, 255), from = 2, to = 14, duration = 0.6 })
	B.flash(p, RGB(220, 240, 255), 24, 6, 0.8)
end

-- Fallback when no elimination effect is equipped.
B.Death.default = function(p)
	B.emit(p, {
		texture = "Smoke",
		color = { RGB(255, 140, 60), RGB(80, 60, 60) },
		size = { 1.5, 3 },
		transparency = { 0.3, 1 },
		lifetime = { 0.6, 1 },
		speed = { 3, 6 },
		spread = 180,
		lightEmission = 0.3,
		drag = 2,
	}, 14)
	B.emit(p, {
		texture = "Spark",
		color = { RGB(255, 200, 80) },
		size = { 0.4, 0 },
		lifetime = { 0.4, 0.8 },
		speed = { 6, 10 },
		spread = 180,
	}, 12)
end

return B
