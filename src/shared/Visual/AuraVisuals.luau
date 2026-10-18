--!nonstrict
-- Auras surround the character without hiding the platforms: they stay
-- mostly around the torso/feet, use additive light and modest sizes.
-- Legendary/Mythic auras layer more techniques (orbits, rings, glyphs).

local FxKit = require(script.Parent.FxKit)

local RGB = Color3.fromRGB

local A = {}

local function feetDisc(kit, diameter)
	return kit:Host("HumanoidRootPart", Vector3.new(diameter, 0.2, diameter), CFrame.new(0, -2.6, 0))
end

local function torsoBox(kit, size)
	return kit:Host("HumanoidRootPart", size or Vector3.new(2.6, 3.4, 1.6), CFrame.new(0, 0.2, 0))
end

local function orbitBall(kit, size, color, material)
	return function()
		return kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(size, size, size),
			color = color,
			material = material or Enum.Material.Neon,
		})
	end
end

A.aura_flame = function(kit)
	local disc = feetDisc(kit, 5)
	if disc then
		kit:Emitter(disc, {
			texture = "Fire",
			shape = Enum.ParticleEmitterShape.Disc,
			shapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			color = { RGB(255, 220, 90), RGB(255, 100, 10), RGB(180, 20, 0) },
			size = { 1.2, 0.3 },
			transparency = { 0.2, 1 },
			rate = 30,
			lifetime = { 0.5, 0.9 },
			speed = { 1.5, 3 },
			spread = { 5, 5 },
			acceleration = Vector3.new(0, 5, 0),
			lightEmission = 1,
		})
		kit:Light(disc, RGB(255, 140, 40), 10, 1.2)
	end
end

A.aura_frozen = function(kit)
	local disc = feetDisc(kit, 5)
	if disc then
		kit:Emitter(disc, {
			texture = "Smoke",
			shape = Enum.ParticleEmitterShape.Disc,
			color = { RGB(230, 250, 255), RGB(170, 220, 255) },
			size = { 1.5, 2.5 },
			transparency = { 0.6, 1 },
			rate = 8,
			lifetime = { 1.2, 1.8 },
			speed = { 0.3, 0.6 },
			lightEmission = 0.4,
		})
		kit:Light(disc, RGB(150, 210, 255), 9, 0.8)
	end
	local flakes = kit:Orbit({
		count = 4,
		radius = 2.4,
		height = 0,
		speed = 1.2,
		bob = 0.6,
		build = orbitBall(kit, 0.25, RGB(240, 250, 255)),
	})
	for _, flake in flakes do
		kit:Glyph(flake, "❄", RGB(220, 245, 255), 1.1)
	end
end

A.aura_toxic = function(kit)
	local disc = feetDisc(kit, 4.5)
	if disc then
		kit:Emitter(disc, {
			texture = "Smoke",
			shape = Enum.ParticleEmitterShape.Disc,
			color = { RGB(170, 255, 70), RGB(70, 170, 30) },
			size = { 1, 2.4 },
			transparency = { 0.45, 1 },
			rate = 10,
			lifetime = { 1, 1.5 },
			speed = { 1, 2 },
			lightEmission = 0.5,
		})
	end
	kit:DebrisStream({
		shape = "Ball",
		colors = { RGB(160, 255, 60), RGB(110, 230, 40) },
		size = Vector3.new(0.3, 0.3, 0.3),
		rate = 6,
		lifetime = 1.2,
		velocity = Vector3.new(0, 2.5, 0),
		jitter = 0.8,
		spread = 1.8,
		offset = Vector3.new(0, -2.4, 0),
	})
end

A.aura_thunder = function(kit)
	local cooldown = 0
	local names = { "Head", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }
	kit:OnUpdate(function(dt, k)
		cooldown -= dt
		if cooldown > 0 or not k.visible or not k.character then
			return
		end
		cooldown = 0.18 / math.max(0.3, k.q.debris)
		local a = k:BodyPart(names[math.random(1, #names)])
		local b = k:BodyPart(names[math.random(1, #names)])
		if a and b and a ~= b then
			FxKit.SpawnBolt(
				a.CFrame.Position,
				b.CFrame.Position,
				if math.random() < 0.5 then RGB(255, 255, 160) else RGB(140, 180, 255),
				0.12,
				0.8,
				4
			)
		end
	end)
	local box = torsoBox(kit)
	if box then
		kit:Emitter(box, {
			texture = "Spark",
			shape = Enum.ParticleEmitterShape.Box,
			color = { RGB(255, 255, 200), RGB(130, 170, 255) },
			size = { 0.25, 0 },
			rate = 10,
			lifetime = { 0.15, 0.3 },
			speed = { 4, 8 },
			spread = { 180, 180 },
			lightEmission = 1,
		})
		local light = kit:Light(box, RGB(170, 200, 255), 9, 1)
		if light then
			kit:OnUpdate(function()
				light.Brightness = if math.random() < 0.15 then 3 else 0.6
			end)
		end
	end
end

A.aura_cyber = function(kit)
	kit:BeamRing("HumanoidRootPart", {
		radius = 2.2,
		segments = 6,
		color = { RGB(0, 255, 220) },
		width = 0.15,
		spin = 1.5,
		offset = CFrame.new(0, -1, 0),
	})
	local scan = kit:BeamRing(
		"HumanoidRootPart",
		{ radius = 1.9, segments = 6, color = { RGB(255, 0, 200) }, width = 0.1, spin = -2 }
	)
	local hub = kit:BodyPart("HumanoidRootPart")
	if scan and hub then
		-- The magenta ring scans up and down the body.
		kit:OnUpdate(function(_dt, k)
			local y = math.sin(k.time * 2) * 2.2
			for _, beam in scan do
				beam.Attachment0.Position = Vector3.new(beam.Attachment0.Position.X, y, beam.Attachment0.Position.Z)
				beam.Attachment1.Position = Vector3.new(beam.Attachment1.Position.X, y, beam.Attachment1.Position.Z)
			end
		end)
	end
	kit:GlyphStream({
		chars = { "0", "1" },
		colors = { RGB(0, 255, 200), RGB(120, 255, 240) },
		rate = 7,
		lifetime = 1.2,
		size = 0.6,
		velocity = Vector3.new(0, 2, 0),
		spread = 1.6,
		offset = Vector3.new(0, -1.5, 0),
	})
end

A.aura_shadow = function(kit)
	local box = torsoBox(kit)
	if box then
		kit:Emitter(box, {
			texture = "Smoke",
			shape = Enum.ParticleEmitterShape.Box,
			color = { RGB(45, 25, 70), RGB(5, 0, 15) },
			size = { 1.2, 2.6 },
			transparency = { 0.35, 1 },
			rate = 16,
			lifetime = { 0.9, 1.4 },
			speed = { 0.4, 1 },
			spread = { 180, 180 },
			acceleration = Vector3.new(0, 1.2, 0),
			lightEmission = 0,
		})
		kit:Emitter(box, {
			texture = "Sparkle",
			shape = Enum.ParticleEmitterShape.Box,
			color = { RGB(170, 90, 255) },
			size = { 0.2, 0 },
			rate = 5,
			lifetime = { 0.6, 1 },
			speed = { 0.5, 1 },
			lightEmission = 1,
		})
	end
end

A.aura_golden = function(kit)
	local disc = feetDisc(kit, 4.5)
	if disc then
		kit:Emitter(disc, {
			texture = "Sparkle",
			shape = Enum.ParticleEmitterShape.Disc,
			color = { RGB(255, 245, 180), RGB(255, 190, 40) },
			size = { 0.45, 0 },
			rate = 22,
			lifetime = { 1, 1.6 },
			speed = { 2, 3.5 },
			spread = { 5, 5 },
			lightEmission = 1,
		})
		kit:Light(disc, RGB(255, 210, 90), 11, 1.4)
	end
	kit:BeamRing("HumanoidRootPart", {
		radius = 2.6,
		segments = 12,
		color = { RGB(255, 225, 100) },
		width = 0.2,
		spin = 0.6,
		offset = CFrame.new(0, -2.5, 0),
	})
end

A.aura_rainbow = function(kit)
	local rings = {}
	for i = 0, 2 do
		local beams = kit:BeamRing("HumanoidRootPart", {
			radius = 2 + i * 0.35,
			segments = 10,
			color = { Color3.fromHSV(i / 3, 0.8, 1) },
			width = 0.18,
			spin = if i % 2 == 0 then 1.2 else -1.5,
			wobble = 0.5,
			offset = CFrame.new(0, -1 + i * 1, 0),
		})
		table.insert(rings, beams)
	end
	kit:OnUpdate(function(_dt, k)
		for i, beams in rings do
			local color = ColorSequence.new(Color3.fromHSV((k.time * 0.3 + i / 3) % 1, 0.8, 1))
			for _, beam in beams or {} do
				beam.Color = color
			end
		end
	end)
end

A.aura_crystal = function(kit)
	local crystals = kit:Orbit({
		count = 5,
		radius = 2.5,
		height = 0.5,
		speed = 0.9,
		bob = 0.4,
		selfSpin = 1.5,
		build = function(i)
			return kit:Part({
				class = "WedgePart",
				size = Vector3.new(0.35, 0.9, 0.5),
				color = if i % 2 == 0 then RGB(170, 255, 255) else RGB(220, 140, 255),
				material = Enum.Material.Glass,
				transparency = 0.1,
			})
		end,
	})
	for _, crystal in crystals do
		kit:Emitter(crystal, {
			texture = "Sparkle",
			color = { RGB(220, 255, 255) },
			size = { 0.2, 0 },
			rate = 3,
			lifetime = { 0.3, 0.6 },
			speed = { 0.2, 0.5 },
			lightEmission = 1,
		})
	end
end

A.aura_galaxy = function(kit)
	local box = torsoBox(kit, Vector3.new(3, 3.6, 2))
	if box then
		kit:Emitter(box, {
			texture = "Smoke",
			shape = Enum.ParticleEmitterShape.Box,
			color = { RGB(170, 90, 255), RGB(50, 70, 220) },
			size = { 1, 2 },
			transparency = { 0.55, 1 },
			rate = 9,
			lifetime = { 1.2, 1.8 },
			speed = { 0.1, 0.4 },
			lightEmission = 1,
		})
	end
	local planets = kit:Orbit({
		count = 2,
		radius = 2.6,
		height = 0.8,
		speed = 1.1,
		tilt = CFrame.Angles(0.35, 0, 0.2),
		build = function(i)
			return kit:Part({
				shape = Enum.PartType.Ball,
				size = Vector3.new(0.6, 0.6, 0.6),
				color = if i == 1 then RGB(255, 170, 90) else RGB(110, 200, 255),
				material = Enum.Material.Neon,
			})
		end,
	})
	if planets[1] then
		kit:Emitter(planets[1], {
			texture = "Sparkle",
			color = { RGB(255, 210, 160) },
			size = { 0.25, 0 },
			rate = 5,
			lifetime = { 0.4, 0.6 },
			speed = { 0, 0.2 },
			lightEmission = 1,
		})
	end
	kit:GlyphStream({
		chars = { "✦", "·", "✧" },
		colors = { RGB(255, 255, 255), RGB(200, 210, 255) },
		rate = 5,
		lifetime = 1.2,
		size = 0.5,
		velocity = Vector3.new(0, 0.3, 0),
		spread = 2,
	})
end

A.aura_angelic = function(kit)
	kit:BeamRing("Head", {
		radius = 0.85,
		segments = 10,
		color = { RGB(255, 250, 210) },
		width = 0.16,
		spin = 0.8,
		offset = CFrame.new(0, 1.3, 0),
	})
	local disc = feetDisc(kit, 4)
	if disc then
		-- Long, squashed sparkles read as soft light rays falling around you.
		kit:Emitter(disc, {
			texture = "Sparkle",
			shape = Enum.ParticleEmitterShape.Disc,
			color = { RGB(255, 255, 230), RGB(255, 225, 150) },
			size = { 0.6, 0.2 },
			squash = { 2, 2 },
			rate = 12,
			lifetime = { 1, 1.5 },
			speed = { 1.5, 2.5 },
			spread = { 0, 0 },
			lightEmission = 1,
		})
		kit:Light(disc, RGB(255, 240, 200), 12, 1.2)
	end
	kit:GlyphStream({
		chars = { "🪶" },
		colors = { RGB(255, 255, 255) },
		rate = 2,
		lifetime = 2.2,
		size = 0.8,
		velocity = Vector3.new(0.3, -0.6, 0.2),
		spin = 60,
		spread = 2,
		offset = Vector3.new(0, 2.5, 0),
	})
end

A.aura_demonic = function(kit)
	local disc = feetDisc(kit, 5)
	if disc then
		kit:Emitter(disc, {
			texture = "Fire",
			shape = Enum.ParticleEmitterShape.Disc,
			shapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			color = { RGB(255, 60, 60), RGB(150, 0, 20), RGB(40, 0, 10) },
			size = { 1.1, 0.2 },
			transparency = { 0.2, 1 },
			rate = 26,
			lifetime = { 0.5, 0.9 },
			speed = { 1, 2.5 },
			acceleration = Vector3.new(0, 4, 0),
			lightEmission = 0.8,
		})
		kit:Emitter(disc, {
			texture = "Spark",
			shape = Enum.ParticleEmitterShape.Disc,
			color = { RGB(255, 120, 80) },
			size = { 0.25, 0 },
			rate = 8,
			lifetime = { 1, 1.6 },
			speed = { 2, 4 },
			lightEmission = 1,
		})
		local light = kit:Light(disc, RGB(255, 40, 40), 10, 1)
		if light then
			kit:OnUpdate(function(_dt, k)
				light.Brightness = 0.9 + math.sin(k.time * 3) * 0.4
			end)
		end
	end
	kit:BeamRing("HumanoidRootPart", {
		radius = 2.3,
		segments = 8,
		color = { RGB(140, 0, 20) },
		width = 0.25,
		spin = -0.8,
		wobble = 0.2,
		offset = CFrame.new(0, -0.6, 0),
	})
end

A.aura_void = function(kit)
	local hole = kit:Orbit({
		count = 1,
		radius = 2.4,
		height = 1.2,
		speed = 0.7,
		bob = 0.3,
		build = function()
			return kit:Part({
				shape = Enum.PartType.Ball,
				size = Vector3.new(0.9, 0.9, 0.9),
				color = RGB(0, 0, 0),
				material = Enum.Material.SmoothPlastic,
			})
		end,
	})[1]
	if hole then
		kit:Emitter(hole, {
			texture = "Sparkle",
			shape = Enum.ParticleEmitterShape.Sphere,
			shapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
			color = { RGB(170, 90, 255), RGB(60, 0, 120) },
			size = { 0.4, 0 },
			rate = 25,
			lifetime = { 0.4, 0.6 },
			speed = { 3, 5 },
			lightEmission = 1,
		})
		local ring = Instance.new("Attachment")
		ring.Parent = hole
		kit.maid:Add(ring)
		kit:Light(hole, RGB(140, 60, 255), 8, 1.2)
	end
	local box = torsoBox(kit, Vector3.new(4, 4.5, 4))
	if box then
		kit:Emitter(box, {
			texture = "Smoke",
			shape = Enum.ParticleEmitterShape.Sphere,
			shapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
			color = { RGB(90, 40, 180), RGB(10, 0, 30) },
			size = { 1, 0.3 },
			transparency = { 0.5, 1 },
			rate = 10,
			lifetime = { 0.6, 0.9 },
			speed = { 2, 3 },
			lightEmission = 0.6,
		})
	end
	kit:BeamRing("HumanoidRootPart", {
		radius = 2.8,
		segments = 12,
		color = { RGB(150, 70, 255) },
		width = 0.12,
		spin = 2.4,
		wobble = 0.35,
		offset = CFrame.new(0, 0.5, 0),
	})
end

A.aura_solar = function(kit)
	local sun = kit:Orbit({
		count = 1,
		radius = 2.6,
		height = 1.6,
		speed = 0.6,
		bob = 0.25,
		build = orbitBall(kit, 1.3, RGB(255, 210, 60)),
	})[1]
	if sun then
		kit:Emitter(sun, {
			texture = "Fire",
			shape = Enum.ParticleEmitterShape.Sphere,
			color = { RGB(255, 240, 150), RGB(255, 120, 0) },
			size = { 1, 0.2 },
			transparency = { 0.2, 1 },
			rate = 30,
			lifetime = { 0.3, 0.6 },
			speed = { 0.5, 1.5 },
			lightEmission = 1,
		})
		kit:Light(sun, RGB(255, 190, 80), 14, 2)
	end
	kit:BeamRing("HumanoidRootPart", {
		radius = 2.3,
		segments = 12,
		color = { RGB(255, 200, 60), RGB(255, 120, 0) },
		width = 0.22,
		spin = 1,
		offset = CFrame.new(0, -2.4, 0),
	})
	local flares = kit:Orbit({
		count = 3,
		radius = 1.8,
		height = -0.5,
		speed = -2,
		build = orbitBall(kit, 0.25, RGB(255, 160, 40)),
	})
	for _, flare in flares do
		kit:Emitter(flare, {
			texture = "Spark",
			color = { RGB(255, 220, 120) },
			size = { 0.2, 0 },
			rate = 6,
			lifetime = { 0.2, 0.4 },
			speed = { 0, 0.3 },
			lightEmission = 1,
		})
	end
end

A.aura_ancient_king = function(kit)
	kit:BeamRing("Head", {
		radius = 0.95,
		segments = 8,
		color = { RGB(255, 225, 100) },
		width = 0.22,
		spin = 0.5,
		offset = CFrame.new(0, 1.4, 0),
	})
	local runes = kit:Orbit({
		count = 6,
		radius = 2.7,
		height = 0.4,
		speed = 0.55,
		bob = 0.25,
		build = orbitBall(kit, 0.12, RGB(255, 220, 90)),
	})
	local symbols = { "⚜", "♔", "✧", "♛", "⚜", "✦" }
	for i, rune in runes do
		kit:Glyph(rune, symbols[i], if i % 2 == 0 then RGB(255, 225, 110) else RGB(190, 130, 255), 1.3)
	end
	local disc = feetDisc(kit, 4.5)
	if disc then
		kit:Emitter(disc, {
			texture = "Sparkle",
			shape = Enum.ParticleEmitterShape.Disc,
			color = { RGB(255, 235, 140), RGB(170, 100, 255) },
			size = { 0.4, 0 },
			rate = 18,
			lifetime = { 1.2, 1.8 },
			speed = { 2, 3 },
			spread = { 3, 3 },
			lightEmission = 1,
		})
		kit:Light(disc, RGB(255, 210, 120), 12, 1.4)
	end
	kit:BeamRing("HumanoidRootPart", {
		radius = 2.9,
		segments = 12,
		color = { RGB(255, 210, 90), RGB(170, 90, 255) },
		width = 0.18,
		spin = -0.4,
		offset = CFrame.new(0, -2.5, 0),
	})
end

A.aura_veteran = function(kit)
	kit:BeamRing("HumanoidRootPart", {
		radius = 2.2,
		segments = 10,
		color = { RGB(120, 255, 170) },
		width = 0.15,
		spin = 0.5,
		offset = CFrame.new(0, -2.5, 0),
	})
	local disc = feetDisc(kit, 4)
	if disc then
		kit:Emitter(disc, {
			texture = "Sparkle",
			shape = Enum.ParticleEmitterShape.Disc,
			color = { RGB(170, 255, 200) },
			size = { 0.3, 0 },
			rate = 8,
			lifetime = { 0.8, 1.2 },
			speed = { 1, 2 },
			lightEmission = 1,
		})
		kit:Light(disc, RGB(120, 255, 170), 9, 0.9)
	end
end

A.aura_centennial = function(kit)
	local orbiters = kit:Orbit({
		count = 3,
		radius = 2.6,
		height = 1,
		speed = 0.8,
		bob = 0.3,
		build = orbitBall(kit, 0.15, RGB(255, 255, 255)),
	})
	for _, orbiter in orbiters do
		kit:Glyph(orbiter, "💯", RGB(255, 255, 255), 1.4)
	end
	for i = 0, 1 do
		kit:BeamRing("HumanoidRootPart", {
			radius = 2.2 + i * 0.4,
			segments = 12,
			color = FxKit.rainbow(5),
			width = 0.15,
			spin = if i == 0 then 1.4 else -1.1,
			wobble = 0.4,
			offset = CFrame.new(0, -0.5 + i, 0),
		})
	end
	local box = torsoBox(kit)
	if box then
		kit:Emitter(box, {
			texture = "Sparkle",
			shape = Enum.ParticleEmitterShape.Box,
			color = FxKit.rainbow(6),
			size = { 0.35, 0 },
			rate = 14,
			lifetime = { 0.6, 1 },
			speed = { 0.5, 1 },
			lightEmission = 1,
		})
	end
end

return A
