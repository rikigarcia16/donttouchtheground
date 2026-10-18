--!nonstrict
-- Original accessory models built from parts and welded to R15 avatar
-- attachments (with R6 fallbacks). They never replace the avatar, never
-- collide and are massless. Sizes scale with the avatar's head.

local RGB = Color3.fromRGB
local N = Enum.Material.Neon
local M = Enum.Material.Metal
local S = Enum.Material.SmoothPlastic
local G = Enum.Material.Glass
local CYL = CFrame.Angles(0, 0, math.rad(90))

local X = {}

local function headScale(kit): number
	local head = kit:BodyPart("Head")
	return if head then math.clamp(head.Size.Y / 1.2, 0.6, 2) else 1
end

local function attach(kit, attachmentName: string, fallbackPart: string, fallback: CFrame)
	return kit:AvatarAttachment(attachmentName, fallbackPart, fallback)
end

local function rig(kit, attachmentName, fallbackPart, fallback, pieces)
	local part, frame = attach(kit, attachmentName, fallbackPart, fallback)
	return kit:Rig(part, frame, pieces)
end

local function v(x, y, z, s)
	return Vector3.new(x, y, z) * s
end

local function at(x, y, z, s, rot)
	return CFrame.new(x * s, y * s, z * s) * (rot or CFrame.new())
end

-- Points on a circle (crowns, rims).
local function circle(count, radius, y, s, make)
	local pieces = {}
	for i = 0, count - 1 do
		local a = i / count * math.pi * 2
		table.insert(
			pieces,
			make(i, CFrame.new(math.cos(a) * radius * s, y * s, math.sin(a) * radius * s) * CFrame.Angles(0, -a, 0))
		)
	end
	return pieces
end

local function concat(...)
	local out = {}
	for _, list in { ... } do
		for _, item in list do
			table.insert(out, item)
		end
	end
	return out
end

-- ====================================================================== HEAD
X.acc_party_hat = function(kit)
	local s = headScale(kit)
	local pieces = {}
	for i = 0, 4 do
		local w = (1 - i / 5) * 1.1
		table.insert(pieces, {
			size = v(0.4, w, w, s),
			offset = at(0, 0.18 + i * 0.32, 0, s, CYL),
			shape = Enum.PartType.Cylinder,
			color = if i % 2 == 0 then RGB(255, 90, 170) else RGB(90, 220, 255),
			material = S,
		})
	end
	table.insert(pieces, {
		size = v(0.4, 0.4, 0.4, s),
		offset = at(0, 1.85, 0, s),
		shape = Enum.PartType.Ball,
		color = RGB(255, 230, 90),
		material = N,
	})
	rig(kit, "HatAttachment", "Head", CFrame.new(0, 0.6, 0), pieces)
end

X.acc_top_hat = function(kit)
	local s = headScale(kit)
	rig(kit, "HatAttachment", "Head", CFrame.new(0, 0.6, 0), {
		{
			size = v(0.12, 1.9, 1.9, s),
			offset = at(0, 0.05, 0, s, CYL),
			shape = Enum.PartType.Cylinder,
			color = RGB(25, 25, 32),
			material = S,
		},
		{
			size = v(1.3, 1.25, 1.25, s),
			offset = at(0, 0.75, 0, s, CYL),
			shape = Enum.PartType.Cylinder,
			color = RGB(25, 25, 32),
			material = S,
		},
		{
			size = v(0.22, 1.28, 1.28, s),
			offset = at(0, 0.3, 0, s, CYL),
			shape = Enum.PartType.Cylinder,
			color = RGB(255, 205, 70),
			material = M,
		},
	})
end

X.acc_viking_helmet = function(kit)
	local s = headScale(kit)
	local pieces = {
		{
			size = v(1.45, 1.45, 1.45, s),
			offset = at(0, -0.15, 0, s),
			shape = Enum.PartType.Ball,
			color = RGB(160, 165, 175),
			material = M,
		},
		{
			size = v(0.18, 1.5, 1.5, s),
			offset = at(0, -0.3, 0, s, CYL),
			shape = Enum.PartType.Cylinder,
			color = RGB(120, 90, 50),
			material = Enum.Material.Wood,
		},
		{ size = v(0.2, 0.9, 0.12, s), offset = at(0, -0.55, -0.72, s), color = RGB(150, 155, 165), material = M },
	}
	for side = -1, 1, 2 do
		for seg = 0, 3 do
			local angle = math.rad(25 + seg * 18)
			table.insert(pieces, {
				size = v(0.28 - seg * 0.05, 0.42, 0.28 - seg * 0.05, s),
				offset = at(side * (0.75 + seg * 0.18), 0.05 + seg * 0.3, 0, s, CFrame.Angles(0, 0, -side * angle)),
				color = RGB(245, 235, 205),
				material = S,
			})
		end
	end
	rig(kit, "HatAttachment", "Head", CFrame.new(0, 0.6, 0), pieces)
end

X.acc_halo = function(kit)
	local s = headScale(kit)
	local parts = rig(
		kit,
		"HatAttachment",
		"Head",
		CFrame.new(0, 0.6, 0),
		circle(12, 0.6, 0.75, s, function(_, cf)
			return { size = v(0.34, 0.12, 0.12, s), offset = cf, color = RGB(255, 245, 190), material = N }
		end)
	)
	if parts[1] then
		kit:Light(parts[1], RGB(255, 240, 170), 6, 0.8)
		local welds = {}
		for _, part in parts do
			local weld = part:FindFirstChildOfClass("Weld")
			if weld then
				table.insert(welds, { weld = weld, base = weld.C0 })
			end
		end
		kit:OnUpdate(function(_dt, k)
			local bob = CFrame.new(0, math.sin(k.time * 2) * 0.08 * s, 0) * CFrame.Angles(0, k.time * 0.6, 0)
			for _, w in welds do
				w.weld.C0 = bob * w.base
			end
		end)
	end
end

X.acc_ice_crown = function(kit)
	local s = headScale(kit)
	local spikes = circle(7, 0.55, 0.1, s, function(i, cf)
		local h = if i % 2 == 0 then 0.75 else 0.5
		return {
			class = "WedgePart",
			size = v(0.2, h, 0.3, s),
			offset = cf * CFrame.new(0, h * s / 2, 0),
			color = if i % 2 == 0 then RGB(210, 250, 255) else RGB(120, 200, 255),
			material = G,
			transparency = 0.1,
		}
	end)
	local band = circle(10, 0.6, -0.05, s, function(_, cf)
		return { size = v(0.4, 0.15, 0.1, s), offset = cf, color = RGB(170, 230, 255), material = N }
	end)
	local parts = rig(kit, "HatAttachment", "Head", CFrame.new(0, 0.6, 0), concat(spikes, band))
	if parts[1] then
		kit:Emitter(parts[1], {
			texture = "Sparkle",
			color = { RGB(230, 250, 255) },
			size = { 0.2, 0 },
			rate = 4,
			lifetime = { 0.5, 0.8 },
			speed = { 0.3, 0.6 },
			spread = { 180, 180 },
			lightEmission = 1,
		})
	end
end

X.acc_astro_helmet = function(kit)
	local s = headScale(kit)
	local parts = rig(kit, "HatAttachment", "Head", CFrame.new(0, 0.6, 0), {
		{
			size = v(1.9, 1.9, 1.9, s),
			offset = at(0, -0.6, 0, s),
			shape = Enum.PartType.Ball,
			color = RGB(200, 230, 255),
			material = G,
			transparency = 0.6,
		},
		{
			size = v(0.3, 1.9, 1.9, s),
			offset = at(0, -1.4, 0, s, CYL),
			shape = Enum.PartType.Cylinder,
			color = RGB(240, 240, 250),
			material = S,
		},
		{ size = v(0.08, 0.9, 0.08, s), offset = at(0.45, 0.65, 0, s), color = RGB(200, 200, 210), material = M },
		{
			name = "AntennaLight",
			size = v(0.22, 0.22, 0.22, s),
			offset = at(0.45, 1.15, 0, s),
			shape = Enum.PartType.Ball,
			color = RGB(255, 60, 90),
			material = N,
		},
	})
	local lightPart = parts[4]
	if lightPart then
		kit:OnUpdate(function(_dt, k)
			lightPart.Transparency = if math.floor(k.time * 2) % 2 == 0 then 0 else 0.7
		end)
	end
end

X.acc_gold_crown = function(kit)
	local s = headScale(kit)
	local points = circle(6, 0.55, 0.32, s, function(i, cf)
		return {
			class = "WedgePart",
			size = v(0.12, 0.5, 0.4, s),
			offset = cf * CFrame.new(0, 0.12 * s, 0),
			color = RGB(255, 210, 60),
			material = M,
			reflectance = 0.2,
		}
	end)
	local band = circle(12, 0.6, 0, s, function(_, cf)
		return {
			size = v(0.34, 0.35, 0.12, s),
			offset = cf,
			color = RGB(255, 205, 50),
			material = M,
			reflectance = 0.25,
		}
	end)
	local gems = circle(6, 0.63, 0, s, function(i, cf)
		return {
			size = v(0.16, 0.16, 0.16, s),
			offset = cf,
			shape = Enum.PartType.Ball,
			color = if i % 2 == 0 then RGB(230, 30, 60) else RGB(60, 120, 255),
			material = G,
		}
	end)
	local parts = rig(kit, "HatAttachment", "Head", CFrame.new(0, 0.6, 0), concat(band, points, gems))
	if parts[1] then
		kit:Emitter(parts[1], {
			texture = "Sparkle",
			color = { RGB(255, 245, 190) },
			size = { 0.25, 0 },
			rate = 5,
			lifetime = { 0.4, 0.7 },
			speed = { 0.2, 0.5 },
			spread = { 180, 180 },
			lightEmission = 1,
		})
	end
end

X.acc_flame_crown = function(kit)
	local s = headScale(kit)
	local parts = rig(
		kit,
		"HatAttachment",
		"Head",
		CFrame.new(0, 0.6, 0),
		circle(8, 0.55, 0.05, s, function(i, cf)
			return {
				size = v(0.22, if i % 2 == 0 then 0.55 else 0.35, 0.22, s),
				offset = cf * CFrame.new(0, 0.15 * s, 0),
				color = if i % 2 == 0 then RGB(255, 200, 40) else RGB(255, 90, 0),
				material = N,
			}
		end)
	)
	for i, part in parts do
		if i % 2 == 1 then
			kit:Emitter(part, {
				texture = "Fire",
				color = { RGB(255, 220, 90), RGB(255, 60, 0) },
				size = { 0.5, 0.1 },
				transparency = { 0.2, 1 },
				rate = 8,
				lifetime = { 0.3, 0.5 },
				speed = { 1, 2 },
				spread = { 10, 10 },
				lightEmission = 1,
			})
		end
	end
	if parts[1] then
		kit:Light(parts[1], RGB(255, 140, 40), 7, 1.2)
	end
end

-- ====================================================================== FACE
X.acc_shades = function(kit)
	local s = headScale(kit)
	rig(kit, "FaceFrontAttachment", "Head", CFrame.new(0, 0, -0.6), {
		{
			size = v(0.5, 0.28, 0.08, s),
			offset = at(-0.27, 0.12, -0.04, s),
			color = RGB(20, 20, 30),
			material = G,
			reflectance = 0.4,
		},
		{
			size = v(0.5, 0.28, 0.08, s),
			offset = at(0.27, 0.12, -0.04, s),
			color = RGB(20, 20, 30),
			material = G,
			reflectance = 0.4,
		},
		{ size = v(1.15, 0.07, 0.07, s), offset = at(0, 0.24, -0.04, s), color = RGB(255, 120, 60), material = M },
	})
end

X.acc_star_glasses = function(kit)
	local s = headScale(kit)
	local pieces = {}
	for side = -1, 1, 2 do
		for i = 0, 2 do
			table.insert(pieces, {
				size = v(0.5, 0.12, 0.06, s),
				offset = at(side * 0.28, 0.14, -0.05, s, CFrame.Angles(0, 0, i * math.pi / 3)),
				color = RGB(255, 220, 60),
				material = N,
			})
		end
	end
	table.insert(
		pieces,
		{ size = v(0.3, 0.06, 0.06, s), offset = at(0, 0.14, -0.05, s), color = RGB(255, 90, 170), material = N }
	)
	rig(kit, "FaceFrontAttachment", "Head", CFrame.new(0, 0, -0.6), pieces)
end

X.acc_ninja_mask = function(kit)
	local s = headScale(kit)
	local parts = rig(kit, "FaceFrontAttachment", "Head", CFrame.new(0, 0, -0.6), {
		{
			size = v(1.3, 0.5, 0.1, s),
			offset = at(0, -0.22, 0.02, s),
			color = RGB(35, 35, 55),
			material = Enum.Material.Fabric,
		},
		{
			size = v(1.32, 0.16, 0.12, s),
			offset = at(0, 0.35, 0.02, s),
			color = RGB(220, 40, 60),
			material = Enum.Material.Fabric,
		},
		{
			name = "Tie",
			size = v(0.12, 0.12, 0.9, s),
			offset = at(0.2, 0.35, 1.5, s, CFrame.Angles(0.3, 0, 0)),
			color = RGB(220, 40, 60),
			material = Enum.Material.Fabric,
		},
		{
			name = "Tie",
			size = v(0.12, 0.12, 0.8, s),
			offset = at(-0.2, 0.3, 1.45, s, CFrame.Angles(0.45, 0, 0)),
			color = RGB(220, 40, 60),
			material = Enum.Material.Fabric,
		},
	})
	local ties = { parts[3], parts[4] }
	local bases = {}
	for i, tie in ties do
		local weld = tie and tie:FindFirstChildOfClass("Weld")
		if weld then
			bases[i] = { weld = weld, base = weld.C0 }
		end
	end
	kit:OnUpdate(function(_dt, k)
		for i, b in bases do
			local flutter = math.sin(k.time * 8 + i) * (0.1 + math.min(k.speed, 20) / 60)
			b.weld.C0 = b.base * CFrame.Angles(flutter, 0, 0)
		end
	end)
end

X.acc_hero_mask = function(kit)
	local s = headScale(kit)
	rig(kit, "FaceFrontAttachment", "Head", CFrame.new(0, 0, -0.6), {
		{ size = v(1.25, 0.32, 0.08, s), offset = at(0, 0.14, -0.02, s), color = RGB(220, 30, 40), material = S },
		{
			class = "WedgePart",
			size = v(0.08, 0.25, 0.3, s),
			offset = at(-0.7, 0.2, 0, s, CFrame.Angles(0, math.rad(90), 0)),
			color = RGB(220, 30, 40),
			material = S,
		},
		{
			class = "WedgePart",
			size = v(0.08, 0.25, 0.3, s),
			offset = at(0.7, 0.2, 0, s, CFrame.Angles(0, math.rad(-90), 0)),
			color = RGB(220, 30, 40),
			material = S,
		},
		{ size = v(0.28, 0.12, 0.1, s), offset = at(-0.27, 0.14, -0.04, s), color = RGB(255, 255, 255), material = N },
		{ size = v(0.28, 0.12, 0.1, s), offset = at(0.27, 0.14, -0.04, s), color = RGB(255, 255, 255), material = N },
	})
end

X.acc_cyber_visor = function(kit)
	local s = headScale(kit)
	local parts = rig(kit, "FaceFrontAttachment", "Head", CFrame.new(0, 0, -0.6), {
		{
			size = v(1.3, 0.34, 0.12, s),
			offset = at(0, 0.14, -0.04, s),
			color = RGB(0, 230, 220),
			material = G,
			transparency = 0.25,
		},
		{ size = v(1.36, 0.06, 0.14, s), offset = at(0, 0.32, -0.04, s), color = RGB(40, 50, 70), material = M },
		{
			name = "Scanner",
			size = v(0.12, 0.3, 0.14, s),
			offset = at(0, 0.14, -0.06, s),
			color = RGB(255, 0, 200),
			material = N,
		},
	})
	local scanner = parts[3]
	local weld = scanner and scanner:FindFirstChildOfClass("Weld")
	if weld then
		local base = weld.C0
		kit:OnUpdate(function(_dt, k)
			weld.C0 = base * CFrame.new(math.sin(k.time * 3) * 0.55 * s, 0, 0)
		end)
	end
end

-- ====================================================================== BACK
local function wings(kit, s, props)
	local body, frame = attach(kit, "BodyBackAttachment", "Torso", CFrame.new(0, 0, 0.5))
	if not body then
		return
	end
	local sides = {}
	for side = -1, 1, 2 do
		local pivot = kit:Part({ name = "WingPivot", size = Vector3.new(0.1, 0.1, 0.1), transparency = 1 })
		local weld = kit:Weld(pivot, body, frame * CFrame.new(side * 0.2 * s, 0.3 * s, 0.1 * s))
		for i, feather in props.feathers do
			local part = kit:Part({
				class = feather.class,
				size = feather.size * s,
				color = feather.color,
				material = feather.material,
				transparency = feather.transparency,
			})
			local offset = CFrame.new(side * feather.x * s, feather.y * s, 0)
				* CFrame.Angles(0, 0, side * (feather.angle or 0))
			if side < 0 and feather.class == "WedgePart" then
				offset *= CFrame.Angles(0, math.pi, 0)
			end
			kit:Weld(part, pivot, offset)
			if props.emitter and i == 1 then
				kit:Emitter(part, props.emitter)
			end
		end
		table.insert(sides, { weld = weld, base = weld.C0, side = side })
	end
	local speed, amplitude = props.flapSpeed or 2, props.flapAmplitude or 0.25
	kit:OnUpdate(function(_dt, k)
		local flap = math.sin(k.time * speed) * amplitude + (if k.grounded then 0 else 0.15)
		for _, w in sides do
			w.weld.C0 = w.base * CFrame.Angles(0, w.side * (flap + 0.25), 0)
		end
	end)
end

X.acc_angel_wings = function(kit)
	local s = headScale(kit)
	local feathers = {}
	for i = 0, 4 do
		table.insert(feathers, {
			size = Vector3.new(0.9 + i * 0.3, 0.35, 0.12),
			x = 0.6 + i * 0.32,
			y = 0.4 - i * 0.28,
			angle = math.rad(10 + i * 9),
			color = RGB(255, 255, 255):Lerp(RGB(255, 235, 170), i / 5),
			material = S,
		})
	end
	wings(kit, s, {
		feathers = feathers,
		flapSpeed = 1.8,
		flapAmplitude = 0.2,
		emitter = {
			texture = "Sparkle",
			color = { RGB(255, 250, 220) },
			size = { 0.25, 0 },
			rate = 4,
			lifetime = { 0.6, 1 },
			speed = { 0.3, 0.6 },
			spread = { 180, 180 },
			lightEmission = 1,
		},
	})
end

X.acc_butterfly_wings = function(kit)
	local s = headScale(kit)
	wings(kit, s, {
		feathers = {
			{
				shape = nil,
				size = Vector3.new(1.6, 1.4, 0.08),
				x = 0.95,
				y = 0.45,
				angle = math.rad(-10),
				color = RGB(255, 90, 220),
				material = N,
				transparency = 0.2,
			},
			{
				size = Vector3.new(1.1, 1, 0.08),
				x = 0.8,
				y = -0.6,
				angle = math.rad(20),
				color = RGB(90, 220, 255),
				material = N,
				transparency = 0.2,
			},
			{ size = Vector3.new(0.5, 0.5, 0.1), x = 1, y = 0.45, angle = 0, color = RGB(255, 255, 255), material = N },
		},
		flapSpeed = 5,
		flapAmplitude = 0.45,
	})
end

X.acc_dragon_wings = function(kit)
	local s = headScale(kit)
	local feathers = {}
	for i = 0, 3 do
		table.insert(feathers, {
			class = "WedgePart",
			size = Vector3.new(0.1, 1.7 - i * 0.2, 1.1 + i * 0.1),
			x = 0.7 + i * 0.55,
			y = 0.3 - i * 0.2,
			angle = math.rad(20 + i * 12),
			color = RGB(170, 20, 20):Lerp(RGB(90, 0, 0), i / 4),
			material = Enum.Material.Slate,
		})
		table.insert(feathers, {
			size = Vector3.new(0.18, 0.18, 1.4),
			x = 0.7 + i * 0.55,
			y = 1 - i * 0.2,
			angle = math.rad(20 + i * 12),
			color = RGB(255, 170, 30),
			material = N,
		})
	end
	wings(kit, s, {
		feathers = feathers,
		flapSpeed = 1.4,
		flapAmplitude = 0.3,
		emitter = {
			texture = "Fire",
			color = { RGB(255, 200, 60), RGB(255, 40, 0) },
			size = { 0.5, 0.1 },
			rate = 10,
			lifetime = { 0.3, 0.6 },
			speed = { 0.5, 1.2 },
			lightEmission = 1,
		},
	})
end

X.acc_void_wings = function(kit)
	local s = headScale(kit)
	local feathers = {}
	for i = 0, 5 do
		table.insert(feathers, {
			size = Vector3.new(0.8 + i * 0.28, 0.3, 0.1),
			x = 0.55 + i * 0.3,
			y = 0.5 - i * 0.26,
			angle = math.rad(8 + i * 10),
			color = RGB(15, 0, 35):Lerp(RGB(140, 70, 255), i / 6),
			material = N,
			transparency = 0.1,
		})
	end
	wings(kit, s, {
		feathers = feathers,
		flapSpeed = 1.2,
		flapAmplitude = 0.22,
		emitter = {
			texture = "Sparkle",
			color = { RGB(180, 120, 255), RGB(255, 255, 255) },
			size = { 0.3, 0 },
			rate = 8,
			lifetime = { 0.8, 1.2 },
			speed = { 0.2, 0.6 },
			spread = { 180, 180 },
			lightEmission = 1,
		},
	})
end

X.acc_backpack = function(kit)
	local s = headScale(kit)
	rig(kit, "BodyBackAttachment", "Torso", CFrame.new(0, 0, 0.5), {
		{
			size = v(1.4, 1.5, 0.7, s),
			offset = at(0, 0, 0.35, s),
			color = RGB(200, 120, 60),
			material = Enum.Material.Fabric,
		},
		{
			size = v(1.2, 0.5, 0.25, s),
			offset = at(0, -0.35, 0.78, s),
			color = RGB(150, 85, 40),
			material = Enum.Material.Fabric,
		},
		{
			size = v(1.7, 0.45, 0.45, s),
			offset = at(0, 0.95, 0.35, s, CYL),
			shape = Enum.PartType.Cylinder,
			color = RGB(90, 140, 90),
			material = Enum.Material.Fabric,
		},
		{ size = v(0.15, 0.15, 0.15, s), offset = at(0.4, 0.2, 0.72, s), color = RGB(255, 210, 80), material = M },
	})
end

X.acc_jetpack = function(kit)
	local s = headScale(kit)
	local parts = rig(kit, "BodyBackAttachment", "Torso", CFrame.new(0, 0, 0.5), {
		{
			size = v(1.6, 0.6, 0.6, s),
			offset = at(-0.45, 0, 0.45, s, CFrame.Angles(0, 0, math.rad(90))),
			shape = Enum.PartType.Cylinder,
			color = RGB(210, 215, 230),
			material = M,
		},
		{
			size = v(1.6, 0.6, 0.6, s),
			offset = at(0.45, 0, 0.45, s, CFrame.Angles(0, 0, math.rad(90))),
			shape = Enum.PartType.Cylinder,
			color = RGB(210, 215, 230),
			material = M,
		},
		{
			name = "NozzleL",
			size = v(0.3, 0.45, 0.45, s),
			offset = at(-0.45, -0.9, 0.45, s, CFrame.Angles(0, 0, math.rad(90))),
			shape = Enum.PartType.Cylinder,
			color = RGB(60, 60, 70),
			material = M,
		},
		{
			name = "NozzleR",
			size = v(0.3, 0.45, 0.45, s),
			offset = at(0.45, -0.9, 0.45, s, CFrame.Angles(0, 0, math.rad(90))),
			shape = Enum.PartType.Cylinder,
			color = RGB(60, 60, 70),
			material = M,
		},
		{ size = v(0.5, 0.9, 0.3, s), offset = at(0, 0.1, 0.4, s), color = RGB(255, 120, 30), material = N },
	})
	for i = 3, 4 do
		local nozzle = parts[i]
		if nozzle then
			local a = Instance.new("Attachment")
			a.CFrame = CFrame.new(-0.2 * s, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
			a.Parent = nozzle
			kit.maid:Add(a)
			local flame = kit:Emitter(a, {
				texture = "Fire",
				color = { RGB(255, 230, 120), RGB(255, 80, 0) },
				size = { 0.45, 0.1 },
				transparency = { 0.1, 1 },
				rate = 18,
				lifetime = { 0.15, 0.3 },
				speed = { 4, 6 },
				spread = { 5, 5 },
				direction = Enum.NormalId.Bottom,
				lightEmission = 1,
			})
			kit:OnUpdate(function(_dt, k)
				-- Bigger flames while airborne.
				flame.Rate = (if k.grounded then 6 else 26) * k.q.particles
			end)
		end
	end
end

X.acc_royal_cape = function(kit)
	local s = headScale(kit)
	local body, frame = attach(kit, "BodyBackAttachment", "Torso", CFrame.new(0, 0, 0.5))
	if not body then
		return
	end
	local pivot = kit:Part({ name = "CapePivot", size = Vector3.new(0.1, 0.1, 0.1), transparency = 1 })
	local weld = kit:Weld(pivot, body, frame * CFrame.new(0, 0.8 * s, 0.1 * s))
	local pieces = {
		{
			size = v(1.9, 2.9, 0.08, s),
			offset = at(0, -1.45, 0.05, s),
			color = RGB(160, 15, 45),
			material = Enum.Material.Fabric,
		},
		{ size = v(1.95, 0.18, 0.12, s), offset = at(0, -2.9, 0.05, s), color = RGB(255, 210, 80), material = M },
		{ size = v(0.12, 2.9, 0.12, s), offset = at(-0.95, -1.45, 0.05, s), color = RGB(255, 210, 80), material = M },
		{ size = v(0.12, 2.9, 0.12, s), offset = at(0.95, -1.45, 0.05, s), color = RGB(255, 210, 80), material = M },
		{
			size = v(2.1, 0.35, 0.3, s),
			offset = at(0, 0, 0, s),
			color = RGB(245, 245, 245),
			material = Enum.Material.Fabric,
		},
	}
	for _, piece in pieces do
		local part = kit:Part({ size = piece.size, color = piece.color, material = piece.material })
		kit:Weld(part, pivot, piece.offset)
	end
	local base = weld.C0
	kit:OnUpdate(function(_dt, k)
		local sway = math.min(k.speed, 26) / 26 * 0.6 + math.sin(k.time * 2) * 0.04
		weld.C0 = base * CFrame.Angles(sway, 0, 0)
	end)
end

-- ================================================================= SHOULDERS
local function pauldrons(kit, pieceFn)
	local s = headScale(kit)
	for _, side in { "Left", "Right" } do
		local sign = if side == "Left" then -1 else 1
		rig(kit, side .. "ShoulderAttachment", "Torso", CFrame.new(sign * 1, 1, 0), pieceFn(s, sign))
	end
end

X.acc_gold_pads = function(kit)
	pauldrons(kit, function(s, sign)
		return {
			{
				size = v(1.05, 0.9, 1.05, s),
				offset = at(sign * 0.1, 0.05, 0, s),
				shape = Enum.PartType.Ball,
				color = RGB(255, 210, 70),
				material = M,
				reflectance = 0.2,
			},
			{
				size = v(0.15, 1.1, 1.1, s),
				offset = at(sign * 0.1, -0.15, 0, s, CYL),
				shape = Enum.PartType.Cylinder,
				color = RGB(190, 130, 30),
				material = M,
			},
		}
	end)
end

X.acc_spike_pads = function(kit)
	pauldrons(kit, function(s, sign)
		local pieces =
			{ { size = v(1, 0.5, 1, s), offset = at(sign * 0.05, 0, 0, s), color = RGB(70, 70, 80), material = M } }
		for i = -1, 1 do
			table.insert(pieces, {
				class = "WedgePart",
				size = v(0.18, 0.55, 0.3, s),
				offset = at(sign * 0.1, 0.5, i * 0.32, s),
				color = RGB(220, 220, 235),
				material = M,
				reflectance = 0.3,
			})
		end
		return pieces
	end)
end

X.acc_crystal_pads = function(kit)
	pauldrons(kit, function(s, sign)
		return {
			{
				size = v(0.9, 0.35, 0.9, s),
				offset = at(sign * 0.05, 0, 0, s),
				color = RGB(80, 90, 140),
				material = Enum.Material.Slate,
			},
			{
				class = "WedgePart",
				size = v(0.3, 0.9, 0.45, s),
				offset = at(sign * 0.1, 0.55, 0, s, CFrame.Angles(0, 0, -sign * 0.3)),
				color = RGB(170, 250, 255),
				material = G,
				transparency = 0.1,
			},
			{
				class = "WedgePart",
				size = v(0.25, 0.6, 0.35, s),
				offset = at(sign * 0.35, 0.4, 0.25, s, CFrame.Angles(0.3, 0, -sign * 0.5)),
				color = RGB(210, 140, 255),
				material = G,
				transparency = 0.1,
			},
		}
	end)
end

-- ====================================================================== FEET
local function feet(kit, pieceFn, emitterProps)
	local s = headScale(kit)
	for _, side in { "Left", "Right" } do
		local parts = rig(kit, side .. "FootAttachment", side .. "Foot", CFrame.new(0, -0.3, 0), pieceFn(s))
		if emitterProps and parts[1] then
			kit:Emitter(parts[1], emitterProps)
		end
	end
end

X.acc_cloud_feet = function(kit)
	feet(kit, function(s)
		return {
			{
				size = v(0.9, 0.6, 0.9, s),
				offset = at(0, 0, 0, s),
				shape = Enum.PartType.Ball,
				color = RGB(255, 255, 255),
				material = S,
				transparency = 0.1,
			},
			{
				size = v(0.6, 0.45, 0.6, s),
				offset = at(0.35, 0.05, 0.25, s),
				shape = Enum.PartType.Ball,
				color = RGB(235, 245, 255),
				material = S,
				transparency = 0.1,
			},
			{
				size = v(0.6, 0.45, 0.6, s),
				offset = at(-0.3, 0.05, -0.25, s),
				shape = Enum.PartType.Ball,
				color = RGB(235, 245, 255),
				material = S,
				transparency = 0.1,
			},
		}
	end, {
		texture = "Smoke",
		color = { RGB(255, 255, 255) },
		size = { 0.5, 1 },
		transparency = { 0.6, 1 },
		rate = 4,
		lifetime = { 0.5, 0.8 },
		speed = { 0.2, 0.5 },
		lightEmission = 0.3,
		movingOnly = true,
	})
end

X.acc_neon_sneakers = function(kit)
	feet(kit, function(s)
		return {
			{ size = v(0.75, 0.12, 1.15, s), offset = at(0, 0, -0.05, s), color = RGB(0, 255, 230), material = N },
			{ size = v(0.78, 0.08, 0.2, s), offset = at(0, 0.25, -0.3, s), color = RGB(255, 0, 200), material = N },
		}
	end)
end

X.acc_flame_feet = function(kit)
	feet(kit, function(s)
		return {
			{
				size = v(0.6, 0.15, 0.9, s),
				offset = at(0, 0, 0, s),
				color = RGB(255, 140, 20),
				material = N,
				transparency = 0.3,
			},
		}
	end, {
		texture = "Fire",
		color = { RGB(255, 220, 90), RGB(255, 60, 0) },
		size = { 0.8, 0.1 },
		transparency = { 0.2, 1 },
		rate = 14,
		lifetime = { 0.25, 0.45 },
		speed = { 1, 2 },
		spread = { 15, 15 },
		lightEmission = 1,
	})
end

-- ===================================================================== FLOAT
-- Companions float beside the player with a little lag and bob.
local function companion(kit, offset: Vector3, build: () -> { BasePart }, extra: ((BasePart, any) -> ())?)
	local parts = build()
	local main = parts[1]
	if not main then
		return
	end
	for _, part in parts do
		part.Anchored = true
	end
	-- Builders place extra pieces relative to the origin; the first part is the anchor.
	local relative = { CFrame.new() }
	for i = 2, #parts do
		relative[i] = parts[i].CFrame
	end
	local current: CFrame? = nil
	kit:OnUpdate(function(dt, k)
		local root = k.root
		if not root then
			return
		end
		local target = root.CFrame
			* CFrame.new(offset + Vector3.new(0, math.sin(k.time * 2.2) * 0.25, 0))
			* CFrame.Angles(0, k.time * 0.8, 0)
		current = if current then current:Lerp(target, math.clamp(dt * 8, 0, 1)) else target
		for i, part in parts do
			part.CFrame = (current :: CFrame) * relative[i]
		end
		if extra then
			extra(main, k)
		end
	end)
end

X.acc_star_pet = function(kit)
	companion(kit, Vector3.new(2.2, 1.6, 0.5), function()
		local list = {}
		for i = 0, 2 do
			table.insert(
				list,
				kit:Part({ size = Vector3.new(0.9, 0.18, 0.18), color = RGB(255, 235, 90), material = N })
			)
			list[#list].CFrame = CFrame.Angles(0, 0, i * math.pi / 3)
		end
		kit:Light(list[1], RGB(255, 230, 120), 6, 1)
		return list
	end)
end

X.acc_frost_orb = function(kit)
	companion(kit, Vector3.new(-2.2, 1.4, 0.4), function()
		local orb = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(0.9, 0.9, 0.9),
			color = RGB(190, 240, 255),
			material = G,
			transparency = 0.2,
		})
		local core = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(0.45, 0.45, 0.45),
			color = RGB(120, 200, 255),
			material = N,
		})
		kit:Emitter(orb, {
			texture = "Smoke",
			color = { RGB(230, 250, 255) },
			size = { 0.4, 0.8 },
			transparency = { 0.6, 1 },
			rate = 5,
			lifetime = { 0.6, 1 },
			speed = { 0.1, 0.3 },
			lightEmission = 0.4,
		})
		return { orb, core }
	end)
end

X.acc_lava_buddy = function(kit)
	companion(kit, Vector3.new(2.3, 1.2, 0.6), function()
		local body = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(1.1, 1, 1.1),
			color = RGB(255, 120, 20),
			material = N,
		})
		local eyeL = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(0.18, 0.25, 0.18),
			color = RGB(30, 10, 0),
			material = S,
		})
		local eyeR = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(0.18, 0.25, 0.18),
			color = RGB(30, 10, 0),
			material = S,
		})
		eyeL.CFrame = CFrame.new(-0.2, 0.12, -0.48)
		eyeR.CFrame = CFrame.new(0.2, 0.12, -0.48)
		kit:Emitter(body, {
			texture = "Fire",
			color = { RGB(255, 200, 60), RGB(255, 60, 0) },
			size = { 0.6, 0.1 },
			transparency = { 0.3, 1 },
			rate = 8,
			lifetime = { 0.3, 0.5 },
			speed = { 0.5, 1 },
			lightEmission = 1,
		})
		kit:Light(body, RGB(255, 120, 30), 6, 1)
		return { body, eyeL, eyeR }
	end, function(main, k)
		-- Squash and stretch like a jelly.
		local squash = 1 + math.sin(k.time * 6) * 0.06
		main.Size = Vector3.new(1.1 / squash, 1 * squash, 1.1 / squash)
	end)
end

X.acc_mini_planet = function(kit)
	companion(kit, Vector3.new(-2.4, 1.8, 0.5), function()
		local planet = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(1, 1, 1),
			color = RGB(255, 170, 90),
			material = S,
		})
		local ring = kit:Part({
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(0.05, 1.8, 1.8),
			color = RGB(170, 140, 255),
			material = N,
			transparency = 0.3,
		})
		ring.CFrame = CFrame.Angles(0.4, 0, math.rad(90))
		local moon = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(0.3, 0.3, 0.3),
			color = RGB(220, 220, 240),
			material = S,
		})
		moon.CFrame = CFrame.new(1.2, 0.3, 0)
		return { planet, ring, moon }
	end)
end

X.acc_drone = function(kit)
	companion(kit, Vector3.new(0, 3.2, 1.2), function()
		local body = kit:Part({ size = Vector3.new(1, 0.35, 1), color = RGB(60, 70, 90), material = M })
		local eye = kit:Part({
			shape = Enum.PartType.Ball,
			size = Vector3.new(0.35, 0.35, 0.35),
			color = RGB(0, 255, 220),
			material = N,
		})
		eye.CFrame = CFrame.new(0, -0.15, -0.45)
		local list = { body, eye }
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2 + math.pi / 4
			local rotor = kit:Part({
				shape = Enum.PartType.Cylinder,
				size = Vector3.new(0.05, 0.6, 0.6),
				color = RGB(0, 255, 220),
				material = N,
				transparency = 0.4,
			})
			rotor.CFrame = CFrame.new(math.cos(a) * 0.7, 0.2, math.sin(a) * 0.7) * CFrame.Angles(0, 0, math.rad(90))
			table.insert(list, rotor)
		end
		local beamA0 = Instance.new("Attachment")
		beamA0.Parent = eye
		kit.maid:Add(beamA0)
		return list
	end)
end

return X
