--!nonstrict
-- Every trail is a function(kit) composing FxKit building blocks. They are
-- intentionally built from different techniques (ribbons, particles, glyphs,
-- part debris, bolts, afterimages, ground tiles) so no two look alike.

local FxKit = require(script.Parent.FxKit)

local RGB = Color3.fromRGB

local T = {}

T.trail_white = function(kit)
	kit:Ribbon("HumanoidRootPart", 0.9, nil, {
		color = { RGB(255, 255, 255) },
		transparency = { 0.25, 1 },
		lifetime = 0.45,
		width = { 1, 0.1 },
		lightEmission = 0.4,
	})
end

T.trail_blue_energy = function(kit)
	kit:Ribbon("HumanoidRootPart", 0.25, nil, {
		offset = Vector3.new(0, 0.9, 0),
		color = { RGB(120, 230, 255), RGB(20, 110, 255) },
		transparency = { 0, 1 },
		lifetime = 0.5,
		lightEmission = 1,
	})
	kit:Ribbon("HumanoidRootPart", 0.25, nil, {
		offset = Vector3.new(0, -1.6, 0),
		color = { RGB(120, 230, 255), RGB(20, 110, 255) },
		transparency = { 0, 1 },
		lifetime = 0.5,
		lightEmission = 1,
	})
	local a = kit:Attachment("HumanoidRootPart")
	if a then
		kit:Emitter(a, {
			texture = "Sparkle",
			color = { RGB(150, 240, 255), RGB(40, 120, 255) },
			size = { 0.35, 0 },
			rate = 14,
			lifetime = { 0.4, 0.8 },
			speed = { 0.5, 1.5 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
		kit:Light(a, RGB(60, 170, 255), 8, 0.8)
	end
end

T.trail_bubble = function(kit)
	kit:DebrisStream({
		shape = "Ball",
		material = Enum.Material.Glass,
		transparency = 0.45,
		colors = { RGB(190, 245, 255), RGB(160, 200, 255), RGB(220, 200, 255) },
		size = Vector3.new(0.7, 0.7, 0.7),
		rate = 9,
		lifetime = 1.5,
		velocity = Vector3.new(0, 3, 0),
		jitter = 1.2,
		from = "HumanoidRootPart",
		offset = Vector3.new(0, -1.5, 0),
		movingOnly = true,
	})
	local a = kit:Attachment("HumanoidRootPart", CFrame.new(0, -2, 0))
	if a then
		kit:Emitter(a, {
			texture = "Sparkle",
			color = { RGB(220, 250, 255) },
			size = { 0.2, 0 },
			rate = 6,
			lifetime = { 0.3, 0.5 },
			speed = { 2, 3 },
			spread = { 180, 180 },
			movingOnly = true,
		})
	end
end

T.trail_fire = function(kit)
	local feet = kit:Attachment("HumanoidRootPart", CFrame.new(0, -2.4, 0))
	if feet then
		kit:Emitter(feet, {
			texture = "Fire",
			color = { RGB(255, 220, 90), RGB(255, 110, 20), RGB(200, 30, 0) },
			size = { 1.6, 0.4 },
			transparency = { 0.1, 1 },
			rate = 32,
			lifetime = { 0.4, 0.8 },
			speed = { 2, 4 },
			acceleration = Vector3.new(0, 6, 0),
			lightEmission = 1,
			movingOnly = true,
		})
		kit:Emitter(feet, {
			texture = "Spark",
			color = { RGB(255, 200, 80) },
			size = { 0.3, 0 },
			rate = 10,
			lifetime = { 0.5, 0.9 },
			speed = { 4, 7 },
			spread = { 30, 30 },
			acceleration = Vector3.new(0, -10, 0),
			lightEmission = 1,
			movingOnly = true,
		})
		kit:Light(feet, RGB(255, 130, 40), 10, 1.4)
	end
	kit:Ribbon("HumanoidRootPart", 0.6, nil, {
		offset = Vector3.new(0, -1.6, 0),
		color = { RGB(255, 180, 60), RGB(255, 40, 0) },
		transparency = { 0.3, 1 },
		lifetime = 0.3,
		lightEmission = 1,
	})
end

T.trail_ice = function(kit)
	kit:Ribbon("HumanoidRootPart", 1, nil, {
		color = { RGB(255, 255, 255), RGB(140, 220, 255) },
		transparency = { 0.35, 1 },
		lifetime = 0.6,
		width = { 1, 0.3 },
		lightEmission = 0.3,
	})
	kit:GlyphStream({
		chars = { "❄", "❅", "❆" },
		colors = { RGB(230, 250, 255), RGB(160, 220, 255) },
		rate = 5,
		lifetime = 1.6,
		size = 0.9,
		velocity = Vector3.new(0, -0.6, 0),
		spin = 120,
		movingOnly = true,
	})
	kit:DebrisStream({
		shape = "Wedge",
		material = Enum.Material.Ice,
		colors = { RGB(200, 245, 255), RGB(150, 210, 255) },
		size = Vector3.new(0.25, 0.5, 0.35),
		rate = 7,
		lifetime = 0.9,
		velocity = Vector3.new(0, 2, 0),
		gravity = 30,
		jitter = 4,
		offset = Vector3.new(0, -2, 0),
		movingOnly = true,
	})
end

T.trail_toxic = function(kit)
	local a = kit:Attachment("HumanoidRootPart", CFrame.new(0, -1.5, 0))
	if a then
		kit:Emitter(a, {
			texture = "Smoke",
			color = { RGB(170, 255, 80), RGB(60, 160, 30) },
			size = { 1.5, 3.5 },
			transparency = { 0.4, 1 },
			rate = 12,
			lifetime = { 1, 1.6 },
			speed = { 0.5, 1 },
			spread = { 180, 180 },
			acceleration = Vector3.new(0, 1, 0),
			lightEmission = 0.4,
			movingOnly = true,
		})
		kit:Light(a, RGB(120, 255, 60), 8, 0.7)
	end
	kit:DebrisStream({
		shape = "Ball",
		colors = { RGB(160, 255, 70), RGB(90, 220, 40) },
		size = Vector3.new(0.35, 0.35, 0.35),
		rate = 8,
		lifetime = 1,
		velocity = Vector3.new(0, 2.5, 0),
		jitter = 1.5,
		offset = Vector3.new(0, -2, 0),
		movingOnly = true,
	})
end

T.trail_rainbow = function(kit)
	local trail = kit:Ribbon("HumanoidRootPart", 1.1, nil, {
		color = FxKit.rainbow(7),
		transparency = { 0.15, 1 },
		lifetime = 0.7,
		width = { 1, 0.6 },
		lightEmission = 0.8,
	})
	local a = kit:Attachment("HumanoidRootPart")
	local sparkles = if a
		then kit:Emitter(a, {
			texture = "Sparkle",
			color = FxKit.rainbow(6),
			size = { 0.4, 0 },
			rate = 10,
			lifetime = { 0.5, 1 },
			speed = { 0.5, 1 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
		else nil
	kit:OnUpdate(function(_dt, k)
		local offset = (k.time * 0.35) % 1
		local keypoints = {}
		for i = 0, 6 do
			table.insert(keypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV((offset + i / 7) % 1, 0.8, 1)))
		end
		local sequence = ColorSequence.new(keypoints)
		if trail then
			trail.Color = sequence
		end
		if sparkles then
			sparkles.Color = sequence
		end
	end)
end

T.trail_heart = function(kit)
	kit:GlyphStream({
		chars = { "♥", "❤", "♡" },
		colors = { RGB(255, 90, 160), RGB(255, 40, 90), RGB(255, 170, 210) },
		rate = 6,
		lifetime = 1.4,
		size = 1,
		velocity = Vector3.new(0, 2.5, 0),
		jitter = 1.5,
		movingOnly = true,
	})
	kit:Ribbon("HumanoidRootPart", 0.3, nil, {
		offset = Vector3.new(0, -0.5, 0),
		color = { RGB(255, 150, 200), RGB(255, 60, 120) },
		transparency = { 0.4, 1 },
		lifetime = 0.4,
		lightEmission = 0.6,
	})
end

T.trail_pixel = function(kit)
	-- Axis-aligned cubes (no spin): reads as chunky 8-bit pixels.
	local palette = { RGB(0, 255, 170), RGB(255, 0, 200), RGB(255, 230, 0), RGB(0, 170, 255) }
	local accumulator = 0
	kit:OnUpdate(function(dt, k)
		if k.speed < 2 or not k.visible or not k.root then
			return
		end
		accumulator += dt * 14 * k.q.debris
		while accumulator >= 1 do
			accumulator -= 1
			local grid = 0.6
			local p = k.root.CFrame.Position
				+ Vector3.new((math.random() - 0.5) * 3, (math.random() - 0.5) * 4, (math.random() - 0.5) * 3)
			p = Vector3.new(math.floor(p.X / grid) * grid, math.floor(p.Y / grid) * grid, math.floor(p.Z / grid) * grid)
			FxKit.SpawnDebris({
				size = Vector3.new(0.55, 0.55, 0.55),
				color = palette[math.random(1, #palette)],
				position = p,
				velocity = Vector3.new(0, -0.5, 0),
				lifetime = 0.9,
				cframe = CFrame.new(p),
			})
		end
	end)
	kit:Ribbon("HumanoidRootPart", 0.15, nil, {
		offset = Vector3.new(0, -1.9, 0),
		color = { RGB(0, 255, 170), RGB(255, 0, 200) },
		transparency = { 0, 1 },
		lifetime = 0.35,
		lightEmission = 1,
	})
end

T.trail_lightning = function(kit)
	local last: Vector3? = nil
	local cooldown = 0
	kit:OnUpdate(function(dt, k)
		cooldown -= dt
		if not k.root or not k.visible then
			return
		end
		local feet = k.root.CFrame.Position - Vector3.new(0, 2.5, 0)
		if last and k.speed > 3 and cooldown <= 0 then
			cooldown = 0.07
			FxKit.SpawnBolt(
				last,
				feet,
				if math.random() < 0.5 then RGB(255, 255, 150) else RGB(140, 180, 255),
				0.22,
				1.2,
				4
			)
		end
		if cooldown <= 0 or not last then
			last = feet
		end
	end)
	local a = kit:Attachment("HumanoidRootPart")
	if a then
		kit:Emitter(a, {
			texture = "Spark",
			color = { RGB(255, 255, 180), RGB(120, 160, 255) },
			size = { 0.3, 0 },
			rate = 12,
			lifetime = { 0.2, 0.4 },
			speed = { 6, 10 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
		local light = kit:Light(a, RGB(170, 200, 255), 10, 1)
		if light then
			kit:OnUpdate(function(_dt, k)
				light.Brightness = if k.speed > 2 and math.random() < 0.3 then 2.5 else 0.6
			end)
		end
	end
end

T.trail_sakura = function(kit)
	kit:GlyphStream({
		chars = { "🌸", "✿", "❀" },
		colors = { RGB(255, 190, 220), RGB(255, 140, 190), RGB(255, 230, 240) },
		rate = 7,
		lifetime = 2,
		size = 0.8,
		velocity = Vector3.new(0.5, -0.8, 0.3),
		jitter = 2,
		spin = 200,
		movingOnly = true,
	})
	kit:Ribbon("HumanoidRootPart", 0.8, nil, {
		color = { RGB(255, 210, 230), RGB(255, 150, 200) },
		transparency = { 0.55, 1 },
		lifetime = 0.6,
		width = { 1, 0.3 },
		lightEmission = 0.3,
	})
end

T.trail_golden_dust = function(kit)
	local a = kit:Attachment("HumanoidRootPart")
	if a then
		-- Long-lived, heavily dragged sparkles that hang in the air.
		kit:Emitter(a, {
			texture = "Sparkle",
			color = { RGB(255, 245, 170), RGB(255, 190, 40) },
			size = { 0.45, 0.1 },
			transparency = { 0, 1 },
			rate = 40,
			lifetime = { 1.6, 2.4 },
			speed = { 1, 3 },
			spread = { 180, 180 },
			drag = 4,
			acceleration = Vector3.new(0, -0.6, 0),
			lightEmission = 1,
			movingOnly = true,
		})
		kit:Light(a, RGB(255, 210, 90), 9, 1)
	end
	kit:GlyphStream({
		chars = { "✦", "✧" },
		colors = { RGB(255, 230, 120), RGB(255, 255, 220) },
		rate = 3,
		lifetime = 0.8,
		size = 0.7,
		velocity = Vector3.new(0, 0.3, 0),
		movingOnly = true,
	})
	kit:Ribbon("HumanoidRootPart", 0.2, nil, {
		offset = Vector3.new(0, -1, 0),
		color = { RGB(255, 230, 120), RGB(200, 140, 20) },
		transparency = { 0.2, 1 },
		lifetime = 0.5,
		lightEmission = 1,
	})
end

T.trail_shadow = function(kit)
	local a = kit:Attachment("HumanoidRootPart", CFrame.new(0, -0.5, 0))
	if a then
		kit:Emitter(a, {
			texture = "Smoke",
			color = { RGB(40, 25, 60), RGB(5, 0, 10) },
			size = { 2, 4 },
			transparency = { 0.25, 1 },
			rate = 18,
			lifetime = { 0.8, 1.3 },
			speed = { 0.2, 0.8 },
			spread = { 180, 180 },
			lightEmission = 0,
			lightInfluence = 0,
			movingOnly = true,
		})
		kit:Emitter(a, {
			texture = "Sparkle",
			color = { RGB(170, 90, 255) },
			size = { 0.25, 0 },
			rate = 6,
			lifetime = { 0.5, 0.9 },
			speed = { 1, 2 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
	end
	kit:Ribbon("HumanoidRootPart", 1.2, nil, {
		color = { RGB(30, 15, 45), RGB(0, 0, 0) },
		transparency = { 0.2, 1 },
		lifetime = 0.6,
		width = { 1, 0.5 },
		lightEmission = 0,
		lightInfluence = 1,
	})
end

T.trail_lava_sparks = function(kit)
	local feet = kit:Attachment("HumanoidRootPart", CFrame.new(0, -2.2, 0))
	if feet then
		kit:Emitter(feet, {
			texture = "Spark",
			color = { RGB(255, 230, 120), RGB(255, 90, 0) },
			size = { 0.45, 0 },
			rate = 26,
			lifetime = { 0.6, 1.1 },
			speed = { 6, 11 },
			spread = { 40, 40 },
			acceleration = Vector3.new(0, -25, 0),
			lightEmission = 1,
			movingOnly = true,
		})
		kit:Light(feet, RGB(255, 100, 20), 10, 1.6)
	end
	kit:DebrisStream({
		shape = "Ball",
		colors = { RGB(255, 150, 30), RGB(255, 80, 0), RGB(200, 30, 0) },
		size = Vector3.new(0.4, 0.4, 0.4),
		rate = 9,
		lifetime = 0.9,
		velocity = Vector3.new(0, 9, 0),
		gravity = 45,
		jitter = 5,
		offset = Vector3.new(0, -2, 0),
		movingOnly = true,
	})
	kit:Ribbon("HumanoidRootPart", 0.3, nil, {
		offset = Vector3.new(0, -2, 0),
		color = { RGB(255, 120, 20), RGB(120, 20, 0) },
		transparency = { 0.2, 1 },
		lifetime = 0.35,
		lightEmission = 1,
	})
end

T.trail_neon_grid = function(kit)
	-- Lights up ground tiles snapped to a 4-stud grid wherever you step.
	local lastCell = ""
	local flip = false
	kit:OnUpdate(function(_dt, k)
		if not k.root or not k.grounded or not k.visible then
			return
		end
		local feet = k.root.CFrame.Position - Vector3.new(0, 2.9, 0)
		local gx, gz = math.floor(feet.X / 4), math.floor(feet.Z / 4)
		local cell = gx .. ":" .. gz
		if cell ~= lastCell then
			lastCell = cell
			flip = not flip
			local center = Vector3.new(gx * 4 + 2, feet.Y + 0.05, gz * 4 + 2)
			local color = if flip then RGB(255, 0, 220) else RGB(0, 240, 255)
			for side = 0, 3 do
				local a = side * math.pi / 2
				local from = center
					+ Vector3.new(math.cos(a) * 1.9 - math.sin(a) * 1.9, 0, math.sin(a) * 1.9 + math.cos(a) * 1.9)
				local b = a + math.pi / 2
				local to = center
					+ Vector3.new(math.cos(b) * 1.9 - math.sin(b) * 1.9, 0, math.sin(b) * 1.9 + math.cos(b) * 1.9)
				FxKit.SpawnSegment(from, to, 0.15, color, 1.2)
			end
			FxKit.SpawnDebris({
				size = Vector3.new(3.6, 0.05, 3.6),
				color = color,
				position = center,
				velocity = Vector3.zero,
				lifetime = 0.6,
				cframe = CFrame.new(center),
				transparency = 0.7,
			})
		end
	end)
	kit:Ribbon("HumanoidRootPart", 0.12, nil, {
		offset = Vector3.new(0, 1, 0),
		color = { RGB(0, 240, 255), RGB(255, 0, 220) },
		transparency = { 0, 1 },
		lifetime = 0.4,
		lightEmission = 1,
	})
end

T.trail_galaxy = function(kit)
	kit:Ribbon("HumanoidRootPart", 1.3, nil, {
		color = { RGB(200, 120, 255), RGB(60, 40, 200), RGB(10, 10, 60) },
		transparency = { 0.2, 1 },
		lifetime = 0.8,
		width = { 1, 0.6 },
		lightEmission = 0.9,
	})
	local a = kit:Attachment("HumanoidRootPart")
	if a then
		kit:Emitter(a, {
			texture = "Smoke",
			color = { RGB(160, 80, 255), RGB(40, 60, 200) },
			size = { 1.5, 3 },
			transparency = { 0.5, 1 },
			rate = 8,
			lifetime = { 1, 1.5 },
			speed = { 0.2, 0.5 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
	end
	kit:GlyphStream({
		chars = { "✦", "★", "·" },
		colors = { RGB(255, 255, 255), RGB(255, 240, 160), RGB(180, 200, 255) },
		rate = 9,
		lifetime = 1.4,
		size = 0.6,
		velocity = Vector3.new(0, 0.2, 0),
		jitter = 0.5,
		movingOnly = true,
	})
end

T.trail_crystal = function(kit)
	local prism = { RGB(160, 255, 255), RGB(220, 140, 255), RGB(255, 170, 220), RGB(150, 190, 255) }
	kit:DebrisStream({
		shape = "Wedge",
		material = Enum.Material.Glass,
		transparency = 0.15,
		colors = prism,
		size = Vector3.new(0.35, 0.9, 0.5),
		rate = 10,
		lifetime = 1.2,
		velocity = Vector3.new(0, 3, 0),
		gravity = 12,
		jitter = 4,
		movingOnly = true,
	})
	kit:Ribbon("HumanoidRootPart", 0.9, nil, {
		color = { RGB(170, 255, 255), RGB(230, 160, 255), RGB(255, 190, 230) },
		transparency = { 0.35, 1 },
		lifetime = 0.55,
		lightEmission = 0.9,
	})
	local a = kit:Attachment("HumanoidRootPart")
	if a then
		kit:Emitter(a, {
			texture = "Sparkle",
			color = prism,
			size = { 0.3, 0 },
			rate = 8,
			lifetime = { 0.3, 0.6 },
			speed = { 1, 2 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
	end
end

T.trail_cosmic_stars = function(kit)
	local cooldown = 0
	kit:OnUpdate(function(dt, k)
		cooldown -= dt
		if not k.root or k.speed < 2 or cooldown > 0 or not k.visible then
			return
		end
		cooldown = 0.12 / math.max(0.25, k.q.debris)
		-- Shooting star: a streak plus a star glyph at its head.
		local head = k.root.CFrame.Position
			+ Vector3.new((math.random() - 0.5) * 5, math.random() * 3, (math.random() - 0.5) * 5)
		local velocity = k.velocity or Vector3.zero
		local back = if velocity.Magnitude > 0.1 then -velocity.Unit else Vector3.new(0, 0, 1)
		local tailDir = (back + Vector3.new(0, 0.4, 0)).Unit
		local color = Color3.fromHSV(math.random(), 0.45, 1)
		FxKit.SpawnSegment(head, head + tailDir * 2.5, 0.12, color, 0.45)
		FxKit.SpawnGlyph({
			char = "★",
			color = color,
			position = head,
			velocity = Vector3.new(0, -0.5, 0),
			lifetime = 0.7,
			size = 0.9,
		})
	end)
	kit:Ribbon("HumanoidRootPart", 0.4, nil, {
		color = { RGB(255, 245, 170), RGB(150, 110, 255) },
		transparency = { 0.1, 1 },
		lifetime = 0.6,
		lightEmission = 1,
	})
end

T.trail_phantom = function(kit)
	-- Ghostly afterimages of the main body parts.
	local parts = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"LeftUpperArm",
		"RightUpperArm",
		"LeftUpperLeg",
		"RightUpperLeg",
		"Torso",
	}
	local cooldown = 0
	local hue = 0
	kit:OnUpdate(function(dt, k)
		cooldown -= dt
		hue = (hue + dt * 0.2) % 1
		if k.speed < 3 or cooldown > 0 or not k.visible or not k.character then
			return
		end
		cooldown = 0.14 / math.max(0.3, k.q.debris)
		local color = Color3.fromHSV(0.5 + hue * 0.3, 0.6, 1)
		for _, name in parts do
			local body = k.character:FindFirstChild(name)
			if body and body:IsA("BasePart") then
				FxKit.SpawnDebris({
					size = body.Size,
					color = color,
					position = body.CFrame.Position,
					velocity = Vector3.zero,
					lifetime = 0.45,
					cframe = body.CFrame,
					transparency = 0.55,
				})
			end
		end
	end)
	local a = kit:Attachment("HumanoidRootPart")
	if a then
		kit:Emitter(a, {
			texture = "Smoke",
			color = { RGB(170, 230, 255), RGB(120, 80, 255) },
			size = { 1, 2 },
			transparency = { 0.6, 1 },
			rate = 6,
			lifetime = { 0.8, 1.2 },
			speed = { 0.3, 0.6 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
	end
end

T.trail_dragon_fire = function(kit)
	-- Twin ribbons spiralling around the body + roaring fire + scales + embers.
	local root = kit:BodyPart("HumanoidRootPart")
	if not root then
		return
	end
	local spirals = {}
	for i = 0, 1 do
		local a0 = Instance.new("Attachment")
		a0.Parent = root
		kit.maid:Add(a0)
		local a1 = Instance.new("Attachment")
		a1.Parent = root
		kit.maid:Add(a1)
		local trail = kit:Trail(a0, a1, {
			color = { RGB(255, 240, 120), RGB(255, 120, 0), RGB(200, 0, 0) },
			transparency = { 0, 1 },
			lifetime = 0.7,
			width = { 1, 0 },
			lightEmission = 1,
		})
		table.insert(spirals, { a0 = a0, a1 = a1, phase = i * math.pi, trail = trail })
	end
	kit:OnUpdate(function(_dt, k)
		for _, s in spirals do
			local angle = k.time * 9 + s.phase
			local p =
				Vector3.new(math.cos(angle) * 1.6, math.sin(k.time * 3 + s.phase) * 1.2 - 0.5, math.sin(angle) * 1.6)
			s.a0.Position = p + Vector3.new(0, 0.35, 0)
			s.a1.Position = p - Vector3.new(0, 0.35, 0)
		end
	end)
	local feet = kit:Attachment("HumanoidRootPart", CFrame.new(0, -2.3, 0))
	if feet then
		kit:Emitter(feet, {
			texture = "Fire",
			color = { RGB(255, 240, 140), RGB(255, 120, 10), RGB(160, 0, 0) },
			size = { 2.4, 0.6 },
			transparency = { 0, 1 },
			rate = 45,
			lifetime = { 0.5, 0.9 },
			speed = { 3, 6 },
			acceleration = Vector3.new(0, 8, 0),
			lightEmission = 1,
			movingOnly = true,
		})
		kit:Emitter(feet, {
			texture = "Spark",
			color = { RGB(255, 220, 100) },
			size = { 0.35, 0 },
			rate = 18,
			lifetime = { 0.6, 1.2 },
			speed = { 6, 12 },
			spread = { 50, 50 },
			acceleration = Vector3.new(0, -14, 0),
			lightEmission = 1,
			movingOnly = true,
		})
		local light = kit:Light(feet, RGB(255, 120, 30), 14, 2)
		if light then
			kit:OnUpdate(function(_dt, k)
				light.Brightness = 1.6 + math.sin(k.time * 11) * 0.5
			end)
		end
	end
	kit:DebrisStream({
		shape = "Wedge",
		material = Enum.Material.Neon,
		colors = { RGB(200, 20, 20), RGB(255, 170, 30), RGB(120, 0, 0) },
		size = Vector3.new(0.2, 0.5, 0.5),
		rate = 7,
		lifetime = 1,
		velocity = Vector3.new(0, 4, 0),
		gravity = 18,
		jitter = 5,
		movingOnly = true,
	})
	kit:GlyphStream({
		chars = { "🔥" },
		colors = { RGB(255, 255, 255) },
		rate = 3,
		lifetime = 1,
		size = 1,
		velocity = Vector3.new(0, 3, 0),
		movingOnly = true,
	})
end

T.trail_aurora = function(kit)
	local trail = kit:Ribbon("HumanoidRootPart", 1.6, nil, {
		offset = Vector3.new(0, 1, 0),
		color = { RGB(60, 255, 170), RGB(60, 200, 255), RGB(140, 80, 255) },
		transparency = { 0.3, 1 },
		lifetime = 1,
		width = { 1, 0.8 },
		lightEmission = 1,
	})
	kit:OnUpdate(function(_dt, k)
		if trail then
			local shift = math.sin(k.time * 0.8) * 0.5 + 0.5
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0.42 + shift * 0.1, 0.8, 1)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.55, 0.7, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(0.72 - shift * 0.05, 0.7, 1)),
			})
		end
	end)
	local a = kit:Attachment("HumanoidRootPart", CFrame.new(0, 1.5, 0))
	if a then
		kit:Emitter(a, {
			texture = "Sparkle",
			color = { RGB(120, 255, 200), RGB(160, 120, 255) },
			size = { 0.3, 0 },
			rate = 8,
			lifetime = { 0.8, 1.2 },
			speed = { 0.2, 0.5 },
			spread = { 180, 180 },
			lightEmission = 1,
			movingOnly = true,
		})
	end
end

return T
