--!nonstrict
-- SKY ISLANDS: grassy floating islands at rising heights, joined by stone
-- ramps (a full no-jump route from spawn to summit), rope bridges made of
-- planks, stepping stones, drifting clouds and bounce mushrooms.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local Decor = require(script.Parent.Decor)

local RGB = Color3.fromRGB
local GRASS = RGB(100, 210, 80)
local DIRT = RGB(130, 90, 60)

return function(ctx)
	local O: CFrame = ctx.origin
	local P = ctx.platforms
	local decor: Instance = ctx.decor
	local structures = ctx.structures
	local rng = ctx.rng

	local palette = {
		{ name = "GREEN", color = GRASS },
		{ name = "SAND", color = RGB(240, 215, 140) },
		{ name = "SNOW", color = RGB(235, 245, 255) },
		{ name = "BLOSSOM", color = RGB(255, 170, 210) },
	}
	P.palette = { palette[1].color, palette[2].color, palette[3].color, palette[4].color }

	local islands = {
		{ x = 0, z = 0, y = 18, r = 20, group = 1 },
		{ x = 42, z = -8, y = 24, r = 13, group = 2 },
		{ x = 32, z = 36, y = 31, r = 12, group = 4 },
		{ x = -10, z = 46, y = 38, r = 12, group = 1 },
		{ x = -46, z = 14, y = 45, r = 12, group = 2 },
		{ x = -34, z = -34, y = 52, r = 11, group = 4 },
		{ x = 8, z = -44, y = 59, r = 10, group = 3 },
		{ x = 4, z = -6, y = 68, r = 8, group = 3 },
	}

	local spawns = {}
	for index, isl in islands do
		local cf = O * CFrame.new(isl.x, isl.y, isl.z)
		P:Create("Normal", cf, Vector3.new(isl.r * 2, 3, isl.r * 2), {
			round = true,
			color = palette[isl.group].color,
			material = if isl.group == 3
				then Enum.Material.Snow
				elseif isl.group == 2 then Enum.Material.Sand
				else Enum.Material.Grass,
			colorGroup = isl.group,
			name = "Island" .. index,
			noRim = true,
		})
		-- Rocky underside: stacked shrinking discs.
		for layer = 1, 4 do
			local d = isl.r * 2 * (1 - layer * 0.2)
			Build.cylinder(
				3,
				d,
				cf * CFrame.new(0, -1.5 - layer * 2.6, 0),
				DIRT:Lerp(RGB(90, 70, 60), layer / 5),
				Enum.Material.Slate,
				decor
			)
		end
		if index == 1 then
			for i = 0, 9 do
				local a = i / 10 * math.pi * 2
				local pad = O * CFrame.new(isl.x + math.cos(a) * 12, isl.y + 2, isl.z + math.sin(a) * 12)
				P:Create("Checkpoint", pad, Vector3.new(5, 1, 5), { round = true })
				table.insert(spawns, pad * CFrame.new(0, 4, 0))
			end
		end
		-- Trees and rocks keep to the rim so the middle stays playable.
		for t = 1, math.floor(isl.r / 5) do
			local a = rng:NextNumber() * math.pi * 2
			local rr = isl.r * 0.8
			local base = O * CFrame.new(isl.x + math.cos(a) * rr, isl.y + 1.5, isl.z + math.sin(a) * rr)
			if t % 2 == 0 then
				Decor.rock(base * CFrame.new(0, 1, 0), 3, RGB(140, 140, 150), decor)
			else
				Decor.tree(
					base,
					8 + rng:NextNumber() * 4,
					if isl.group == 4 then RGB(255, 160, 200) else RGB(60, 170, 70),
					decor
				)
			end
		end
		-- Waterfall off the edge.
		if index % 2 == 0 then
			local a = rng:NextNumber() * math.pi * 2
			local fall = Build.part({
				name = "Waterfall",
				size = Vector3.new(3, 60, 0.6),
				cframe = O
					* CFrame.new(isl.x + math.cos(a) * (isl.r + 0.4), isl.y - 30, isl.z + math.sin(a) * (isl.r + 0.4))
					* CFrame.Angles(0, -a + math.pi / 2, 0),
				color = RGB(120, 200, 255),
				material = Enum.Material.Neon,
				transparency = 0.35,
				castShadow = false,
				parent = decor,
			})
			fall:SetAttribute("Flow", true)
		end
	end

	-- Stone ramp between two islands: low end at `a`, high end at `b`.
	local function ramp(a, b)
		local pa = Vector3.new(a.x, 0, a.z)
		local pb = Vector3.new(b.x, 0, b.z)
		local dir = (pb - pa).Unit
		local lowPoint = pa + dir * (a.r - 1)
		local highPoint = pb - dir * (b.r - 1)
		local length = (highPoint - lowPoint).Magnitude
		local lowY, highY = a.y + 1.5, b.y + 1.5
		local mid = (lowPoint + highPoint) / 2 + Vector3.new(0, (lowY + highY) / 2, 0)
		local cf = O * CFrame.lookAt(mid, Vector3.new(lowPoint.X, mid.Y, lowPoint.Z))
		local part = Build.part({
			name = "StoneRamp",
			class = "WedgePart",
			size = Vector3.new(5, highY - lowY, length),
			cframe = cf,
			color = RGB(170, 160, 150),
			material = Enum.Material.Cobblestone,
			collide = true,
			parent = decor,
		})
		table.insert(structures, part)
		-- Rope rails.
		for side = -1, 1, 2 do
			local slope = math.atan2(highY - lowY, length)
			Build.part({
				name = "Rope",
				size = Vector3.new(0.25, 0.25, length / math.cos(slope)),
				cframe = cf * CFrame.new(side * 2.4, 2, 0) * CFrame.Angles(-slope, 0, 0),
				color = RGB(200, 160, 100),
				material = Enum.Material.Fabric,
				castShadow = false,
				parent = decor,
			})
		end
	end
	for i = 1, #islands - 2 do
		ramp(islands[i], islands[i + 1])
	end
	-- Last ramp from island 7 up to the summit island.
	ramp(islands[7], islands[8])

	-- Plank bridges (jump route) and stepping stones as shortcuts.
	local function planks(a, b, kindEvery: number)
		local pa = Vector3.new(a.x, a.y + 1, a.z)
		local pb = Vector3.new(b.x, b.y + 1, b.z)
		local dir = (pb - pa) * Vector3.new(1, 0, 1)
		local flatDir = dir.Unit
		local from = pa + flatDir * a.r
		local to = pb - flatDir * b.r
		local count = math.max(2, math.floor(((to - from) * Vector3.new(1, 0, 1)).Magnitude / 4.6))
		for i = 1, count do
			local t = i / (count + 1)
			local p = from:Lerp(to, t)
			local kind = if i % kindEvery == 0 then "Fragile" elseif i % 5 == 4 then "Disappearing" else "Normal"
			P:Create(
				kind :: any,
				O * CFrame.lookAt(p, p + flatDir),
				Vector3.new(4, 0.8, 3),
				{ color = RGB(170, 120, 70), material = Enum.Material.WoodPlanks, name = "Plank", colorGroup = 2 }
			)
		end
	end
	planks(islands[1], islands[3], 3)
	planks(islands[2], islands[4], 2)
	planks(islands[3], islands[5], 3)
	planks(islands[4], islands[6], 3)
	planks(islands[5], islands[7], 2)

	-- Bounce mushrooms and drifting cloud platforms.
	for i, spec in { { 20, 21, 20 }, { -25, 35, 30 }, { -20, 50, -10 } } do
		local cf = O * CFrame.new(spec[1], spec[2], spec[3])
		P:Create("Bounce", cf, Vector3.new(6, 1.2, 6), { round = true, color = RGB(230, 50, 60), name = "Mushroom" })
		Build.cylinder(6, 1.6, cf * CFrame.new(0, -3.6, 0), RGB(250, 240, 220), Enum.Material.SmoothPlastic, decor)
		local cloudCF = O * CFrame.new(spec[1] * 0.4, spec[2] + 12, spec[3] * 0.4)
		P:Create("Moving", cloudCF, Vector3.new(8, 1.4, 8), {
			color = RGB(255, 255, 255),
			material = Enum.Material.SmoothPlastic,
			name = "CloudPlatform",
			motion = {
				kind = "Slide",
				vec = Vector3.new(10, 0, 6) * (if i % 2 == 0 then 1 else -1),
				period = 10,
				phase = i,
				start = 0,
				finish = math.huge,
			},
		})
	end

	for _ = 1, 22 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 70 + rng:NextNumber() * 80
		Decor.cloud(
			O * CFrame.new(math.cos(a) * r, rng:NextNumber() * 80, math.sin(a) * r),
			1.2 + rng:NextNumber() * 2,
			nil,
			decor
		)
	end
	Decor.ambientEmitter(O * CFrame.new(0, 40, 0), Vector3.new(100, 60, 100), {
		texture = Decor.TEXTURES.Sparkle,
		color = ColorSequence.new(RGB(255, 255, 200), RGB(200, 255, 200)),
		rate = 6,
		lifetime = NumberRange.new(4, 6),
		speed = NumberRange.new(0.3, 0.8),
		size = NumberSequence.new(0.5, 0),
	}, decor)

	return {
		spawns = spawns,
		palette = palette,
		center = O.Position,
		radius = 55,
		topY = 70,
	}
end
