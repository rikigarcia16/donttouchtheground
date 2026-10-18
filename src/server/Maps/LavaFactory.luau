--!nonstrict
-- LAVA FACTORY: four scaffold towers with switchback ramps, catwalk bridges
-- with conveyor belts, a central piston press, spinning gears and an
-- orbiting crane hook. Lots of mechanical motion, all deterministic.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local Decor = require(script.Parent.Decor)

local RGB = Color3.fromRGB
local METAL = RGB(95, 100, 115)
local HAZARD = RGB(255, 200, 30)

return function(ctx)
	local O: CFrame = ctx.origin
	local P = ctx.platforms
	local decor: Instance = ctx.decor
	local structures = ctx.structures
	local rng = ctx.rng

	local palette = {
		{ name = "ORANGE", color = RGB(255, 140, 30) },
		{ name = "STEEL", color = RGB(150, 160, 180) },
		{ name = "TEAL", color = RGB(40, 200, 190) },
		{ name = "PURPLE", color = RGB(150, 90, 230) },
	}
	P.palette = { palette[1].color, palette[2].color, palette[3].color, palette[4].color }

	local spawns = {}
	local TOWER = 32
	local FLOOR = 14
	local levels = { 10, 20, 30, 40, 50, 60, 70 }

	for tx = -1, 1, 2 do
		for tz = -1, 1, 2 do
			local towerCF = O * CFrame.new(tx * TOWER, 0, tz * TOWER)
			local group = ((tx + 1) + (tz + 1) / 2) % 4 + 1
			for k, y in levels do
				local kind = if y == 20
					then "Checkpoint"
					elseif y == 10 then "Fragile"
					elseif k == 5 and tx == tz then "Disappearing"
					else "Normal"
				P:Create(
					kind :: any,
					towerCF * CFrame.new(0, y, 0),
					Vector3.new(FLOOR, 1.4, FLOOR),
					{ colorGroup = group, material = if kind == "Normal" then Enum.Material.DiamondPlate else nil }
				)
				if y == 20 then
					for s = -1, 1 do
						table.insert(spawns, towerCF * CFrame.new(s * 4, y + 4, 0))
					end
				end
				-- Switchback ramp to the next floor, outside the footprint.
				if k < #levels then
					local rise = levels[k + 1] - y
					local side = if k % 2 == 1 then 1 else -1
					local rampCF = towerCF * CFrame.new(side * (FLOOR / 2 + 2.5), y + 0.7 + rise / 2, 0)
					if side < 0 then
						rampCF *= CFrame.Angles(0, math.pi, 0)
					end
					local ramp = Build.part({
						name = "Ramp",
						class = "WedgePart",
						size = Vector3.new(5, rise, FLOOR),
						cframe = rampCF,
						color = METAL,
						material = Enum.Material.DiamondPlate,
						collide = true,
					})
					ramp.Parent = decor
					table.insert(structures, ramp)
					Build.neon(
						Vector3.new(0.3, 0.3, FLOOR),
						rampCF * CFrame.new(side * 2.5, -rise / 2 + 0.2, 0),
						HAZARD,
						decor
					)
				end
			end
			-- Scaffold posts.
			for px = -1, 1, 2 do
				for pz = -1, 1, 2 do
					Build.cylinder(
						80,
						1.2,
						towerCF * CFrame.new(px * (FLOOR / 2 - 0.5), 34, pz * (FLOOR / 2 - 0.5)),
						METAL,
						Enum.Material.Metal,
						decor
					)
				end
			end
			-- Smokestack with smoke.
			local stackCF = towerCF * CFrame.new(tx * 9, 40, tz * 9)
			Build.cylinder(60, 5, stackCF, RGB(120, 70, 60), Enum.Material.Brick, decor)
			Build.cylinder(1, 5.6, stackCF * CFrame.new(0, 28, 0), HAZARD, Enum.Material.Neon, decor)
			Decor.ambientEmitter(stackCF * CFrame.new(0, 31, 0), Vector3.new(3, 1, 3), {
				texture = Decor.TEXTURES.Smoke,
				color = ColorSequence.new(RGB(90, 80, 80), RGB(40, 35, 35)),
				rate = 4,
				lifetime = NumberRange.new(4, 6),
				speed = NumberRange.new(3, 5),
				size = NumberSequence.new(3, 9),
				transparency = NumberSequence.new(0.4, 1),
				acceleration = Vector3.new(2, 1, 0),
				lightEmission = 0,
			}, decor)
		end
	end

	-- Catwalk bridges between neighbouring towers at y=30 and y=50 with
	-- conveyor segments, fragile grates and a fake panel.
	local bridgeKinds = { "Normal", "Conveyor", "Fragile", "Normal", "Fake" }
	for _, y in { 30, 50 } do
		for side = 0, 3 do
			local a = side * math.pi / 2
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local perp = Vector3.new(-dir.Z, 0, dir.X)
			local start = dir * TOWER - perp * (TOWER - FLOOR / 2)
			local segments = 5
			local span = (TOWER * 2 - FLOOR) / segments
			for s = 0, segments - 1 do
				local center = start + perp * (span * (s + 0.5))
				local kind = bridgeKinds[(s + side + (if y == 50 then 2 else 0)) % #bridgeKinds + 1]
				local cf = O * CFrame.lookAt(center + Vector3.new(0, y, 0), center + perp + Vector3.new(0, y, 0))
				if kind == "Conveyor" then
					local belt = P:Create(
						"Normal",
						cf,
						Vector3.new(4, 1, span - 0.4),
						{ color = RGB(40, 40, 45), material = Enum.Material.Fabric, symbol = "»", noRim = false }
					)
					belt:SetAttribute("Conveyor", perp * (if side % 2 == 0 then 8 else -8))
				else
					P:Create(kind :: any, cf, Vector3.new(4, 1, span - 0.4), { colorGroup = side % 4 + 1 })
				end
			end
		end
	end

	-- Spokes from every bridge to the central press.
	for side = 0, 3 do
		local a = side * math.pi / 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		for s = 0, 2 do
			local r = 9 + s * 7
			local cf = O * CFrame.lookAt(dir * r + Vector3.new(0, 30, 0), dir * (r + 1) + Vector3.new(0, 30, 0))
			P:Create(
				if s == 1 then "Fragile" else "Normal",
				cf,
				Vector3.new(4, 1, 6.6),
				{ colorGroup = (side + s) % 4 + 1 }
			)
		end
	end

	-- Central press: elevator piston, spinning gears, an orbiting crane hook.
	P:Create(
		"Normal",
		O * CFrame.new(0, 30, 0),
		Vector3.new(12, 2, 12),
		{ color = RGB(80, 80, 90), material = Enum.Material.Metal, name = "PressBase" }
	)
	P:Create("Bounce", O * CFrame.new(0, 31.5, 5.5), Vector3.new(4, 1, 4), { round = true })
	P:Create("Bounce", O * CFrame.new(0, 31.5, -5.5), Vector3.new(4, 1, 4), { round = true })
	P:Create("Moving", O * CFrame.new(0, 52, 0), Vector3.new(8, 1.5, 8), {
		motion = { kind = "Slide", vec = Vector3.new(0, 12, 0), period = 9, phase = 0, start = 0, finish = math.huge },
		name = "Piston",
	})
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + math.pi / 6
		local high = i % 2 == 1
		P:Create(
			"Rotating",
			O * CFrame.new(math.cos(a) * 13, if high then 57 else 45, math.sin(a) * 13),
			Vector3.new(9, 1.4, 9),
			{
				round = true,
				color = RGB(200, 160, 60),
				material = Enum.Material.Metal,
				motion = {
					kind = "Spin",
					vec = Vector3.new(if high then 1 else -1, 0, 0),
					period = 6,
					phase = 0,
					start = 0,
					finish = math.huge,
				},
				name = "Gear",
			}
		)
	end
	P:Create("Moving", O * CFrame.new(0, 60, 0), Vector3.new(6, 1.2, 6), {
		motion = { kind = "Orbit", vec = Vector3.new(26, 1, 0), period = 18, phase = 0, start = 0, finish = math.huge },
		name = "CraneHook",
		color = HAZARD,
	})
	P:Create(
		"Normal",
		O * CFrame.new(9.5, 68.5, 0),
		Vector3.new(7, 1.4, 7),
		{ color = RGB(255, 120, 20), symbol = "★", name = "Summit" }
	)

	-- ===== Decoration: pipes, glowing molten pipes, crucibles and sparks.
	for i = 1, 10 do
		local y = 6 + rng:NextNumber() * 60
		local a = rng:NextNumber() * math.pi
		local glowing = i % 3 == 0
		Build.part({
			name = "Pipe",
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(110, 2.4, 2.4),
			cframe = O * CFrame.new(0, y, (rng:NextNumber() - 0.5) * 20) * CFrame.Angles(0, a, 0),
			color = if glowing then RGB(255, 110, 20) else RGB(130, 135, 150),
			material = if glowing then Enum.Material.Neon else Enum.Material.Metal,
			castShadow = false,
			parent = decor,
		})
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local cf = O * CFrame.new(math.cos(a) * 62, 4, math.sin(a) * 62)
		Build.cylinder(10, 12, cf, RGB(60, 60, 70), Enum.Material.Metal, decor)
		Build.cylinder(0.5, 10, cf * CFrame.new(0, 5.2, 0), RGB(255, 90, 0), Enum.Material.Neon, decor)
		Decor.ambientEmitter(cf * CFrame.new(0, 6, 0), Vector3.new(8, 1, 8), {
			texture = Decor.TEXTURES.Spark,
			color = ColorSequence.new(RGB(255, 220, 120), RGB(255, 80, 0)),
			rate = 6,
			lifetime = NumberRange.new(0.8, 1.6),
			speed = NumberRange.new(8, 14),
			size = NumberSequence.new(0.4, 0),
			acceleration = Vector3.new(0, -30, 0),
			lightEmission = 1,
		}, decor)
	end
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2
		Build.ring(
			10,
			1.2,
			1.2,
			14,
			O * CFrame.new(math.cos(a) * 80, 40, math.sin(a) * 80) * CFrame.Angles(0, -a, math.pi / 2),
			RGB(200, 160, 60),
			Enum.Material.Metal,
			decor
		)
		Decor.sign(
			O * CFrame.new(math.cos(a) * 70, 58, math.sin(a) * 70) * CFrame.Angles(0, -a + math.pi / 2, 0),
			Vector3.new(20, 6, 1),
			"⚠ HOT FLOOR ⚠",
			HAZARD,
			RGB(30, 30, 30),
			decor
		)
	end

	return {
		spawns = spawns,
		palette = palette,
		center = O.Position,
		radius = 50,
		topY = 70,
	}
end
