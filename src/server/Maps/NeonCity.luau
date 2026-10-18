--!nonstrict
-- NEON CITY: a 5x5 block of skyscrapers. Rooftop heights follow a snake path
-- (+3 studs per building) so there is always a climb; billboards, flying
-- cars, spinning signs and a helipad bounce offer alternative routes.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local Decor = require(script.Parent.Decor)

local RGB = Color3.fromRGB

local SIGNS = { "DTTG", "LAVA COLA", "JUMP!", "NO FLOOR", "NEON", "SKY HIGH", "HOT!", "24/7" }

return function(ctx)
	local O: CFrame = ctx.origin
	local P = ctx.platforms
	local decor: Instance = ctx.decor
	local rng = ctx.rng

	local palette = {
		{ name = "PINK", color = RGB(255, 40, 200) },
		{ name = "CYAN", color = RGB(0, 230, 255) },
		{ name = "LIME", color = RGB(160, 255, 40) },
		{ name = "VIOLET", color = RGB(140, 70, 255) },
	}
	P.palette = { palette[1].color, palette[2].color, palette[3].color, palette[4].color }

	local GRID, SPACING, WIDTH = 5, 21, 16
	local spawns = {}
	local tops = {}

	-- Snake ordering: row 0 left->right, row 1 right->left, ...
	local order = 0
	for row = 0, GRID - 1 do
		for c = 0, GRID - 1 do
			local col = if row % 2 == 0 then c else GRID - 1 - c
			local x = (col - (GRID - 1) / 2) * SPACING
			local z = (row - (GRID - 1) / 2) * SPACING
			local top = 10 + order * 3
			local group = (row + col) % 4 + 1
			local kinds =
				{ "Normal", "Normal", "Fragile", "Normal", "Slippery", "Normal", "Fake", "Normal", "Disappearing" }
			local kind = if order >= 4 and order <= 7 then "Checkpoint" else kinds[(order * 7) % #kinds + 1]
			local roofCF = O * CFrame.new(x, top, z)
			P:Create(kind :: any, roofCF, Vector3.new(WIDTH, 1.6, WIDTH), {
				colorGroup = group,
				color = if kind == "Normal" then RGB(40, 40, 60) else nil,
				material = if kind == "Normal" then Enum.Material.Concrete else nil,
				name = "Rooftop" .. order,
			})
			-- Neon roof border in the building's colour so groups read clearly.
			Build.neon(
				Vector3.new(WIDTH + 0.6, 0.4, 0.6),
				roofCF * CFrame.new(0, 0.9, WIDTH / 2),
				palette[group].color,
				decor
			)
			Build.neon(
				Vector3.new(WIDTH + 0.6, 0.4, 0.6),
				roofCF * CFrame.new(0, 0.9, -WIDTH / 2),
				palette[group].color,
				decor
			)
			Build.neon(
				Vector3.new(0.6, 0.4, WIDTH + 0.6),
				roofCF * CFrame.new(WIDTH / 2, 0.9, 0),
				palette[group].color,
				decor
			)
			Build.neon(
				Vector3.new(0.6, 0.4, WIDTH + 0.6),
				roofCF * CFrame.new(-WIDTH / 2, 0.9, 0),
				palette[group].color,
				decor
			)

			-- Building body (decorative: non-colliding so a vanished roof means a fall).
			local bodyHeight = top + 40
			Build.part({
				name = "Building",
				size = Vector3.new(WIDTH - 1, bodyHeight, WIDTH - 1),
				cframe = O * CFrame.new(x, top - 1 - bodyHeight / 2, z),
				color = RGB(25, 22, 40),
				material = Enum.Material.Glass,
				reflectance = 0.15,
				castShadow = false,
				parent = decor,
			})
			for band = 1, math.floor(bodyHeight / 9) do
				local y = top - 1 - band * 9
				if y > -20 then
					Build.neon(
						Vector3.new(WIDTH - 0.6, 0.5, WIDTH - 0.6),
						O * CFrame.new(x, y, z),
						if band % 2 == 0 then palette[group].color else RGB(255, 230, 160),
						decor
					).Transparency =
						0.3
				end
			end
			if kind == "Checkpoint" then
				for s = -1, 1 do
					table.insert(spawns, roofCF * CFrame.new(s * 4, 4, 0))
				end
			end
			tops[order] = { x = x, z = z, top = top, row = row, col = col }
			order += 1
		end
	end

	-- Rooftop extras: AC units (small steps), water towers, antenna, signs.
	for index = 0, order - 1 do
		local t = tops[index]
		if index % 4 == 1 then
			P:Create(
				"Normal",
				O * CFrame.new(t.x + 4, t.top + 3, t.z + 4),
				Vector3.new(5, 1.2, 5),
				{ round = true, color = RGB(150, 120, 90), name = "WaterTower" }
			)
			Build.cylinder(
				3,
				4.5,
				O * CFrame.new(t.x + 4, t.top + 1, t.z + 4),
				RGB(120, 90, 70),
				Enum.Material.WoodPlanks,
				decor
			)
		elseif index % 4 == 3 then
			Build.cylinder(
				14,
				0.5,
				O * CFrame.new(t.x - 5, t.top + 7, t.z - 5),
				RGB(200, 200, 210),
				Enum.Material.Metal,
				decor
			)
			local blink = Build.ball(
				1.2,
				O * CFrame.new(t.x - 5, t.top + 14.5, t.z - 5),
				RGB(255, 30, 60),
				Enum.Material.Neon,
				decor
			)
			blink:SetAttribute("Blink", true)
		end
		if index % 3 == 0 then
			local sign = SIGNS[(index // 3) % #SIGNS + 1]
			local color = palette[(index % 4) + 1].color
			Decor.sign(
				O * CFrame.new(t.x, t.top + 6, t.z - WIDTH / 2 + 0.6),
				Vector3.new(12, 4, 0.6),
				sign,
				RGB(20, 10, 30):Lerp(color, 0.25),
				color,
				decor
			)
		end
	end

	-- Helipad bounce on the 12th building and a spinning sign platform.
	local heli = tops[12]
	P:Create(
		"Bounce",
		O * CFrame.new(heli.x, heli.top + 1.2, heli.z),
		Vector3.new(8, 0.8, 8),
		{ round = true, symbol = "H", name = "Helipad" }
	)
	for _, idx in { 6, 17 } do
		local t = tops[idx]
		P:Create("Rotating", O * CFrame.new(t.x, t.top + 9, t.z), Vector3.new(10, 1, 3), {
			color = palette[idx % 4 + 1].color,
			material = Enum.Material.Neon,
			name = "SpinningSign",
			motion = { kind = "Spin", vec = Vector3.new(1, 0, 0), period = 6, phase = 0, start = 0, finish = math.huge },
		})
		Build.cylinder(8, 0.6, O * CFrame.new(t.x, t.top + 4.5, t.z), RGB(160, 160, 170), Enum.Material.Metal, decor)
	end

	-- Flying cars crossing the streets between rows at mid heights.
	for lane = 0, 3 do
		local z = (lane - 1.5) * SPACING
		local y = 22 + lane * 13
		P:Create("Moving", O * CFrame.new(0, y, z), Vector3.new(7, 1.4, 4.5), {
			color = palette[lane % 4 + 1].color,
			material = Enum.Material.Metal,
			name = "FlyingCar",
			symbol = "🚗",
			motion = {
				kind = "Slide",
				vec = Vector3.new(SPACING * 2, 0, 0),
				period = 12 + lane * 2,
				phase = lane,
				start = 0,
				finish = math.huge,
			},
		})
	end

	-- Distant skyline.
	for _ = 1, 30 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 110 + rng:NextNumber() * 60
		local h = 40 + rng:NextNumber() * 90
		local w = 10 + rng:NextNumber() * 14
		local cf = O * CFrame.new(math.cos(a) * r, h / 2 - 30, math.sin(a) * r)
		Build.part({
			name = "Skyline",
			size = Vector3.new(w, h, w),
			cframe = cf,
			color = RGB(20, 15, 35),
			material = Enum.Material.SmoothPlastic,
			castShadow = false,
			parent = decor,
		})
		Build.neon(
			Vector3.new(w + 0.2, 0.6, w + 0.2),
			cf * CFrame.new(0, h / 2 - 2, 0),
			palette[rng:NextInteger(1, 4)].color,
			decor
		)
	end
	Decor.ambientEmitter(O * CFrame.new(0, 30, 0), Vector3.new(110, 40, 110), {
		texture = Decor.TEXTURES.Sparkle,
		color = ColorSequence.new(RGB(255, 60, 220), RGB(60, 230, 255)),
		rate = 10,
		lifetime = NumberRange.new(3, 5),
		speed = NumberRange.new(0.5, 1),
		size = NumberSequence.new(0.5, 0),
	}, decor)

	return {
		spawns = spawns,
		palette = palette,
		center = O.Position,
		radius = 58,
		topY = 10 + (order - 1) * 3,
	}
end
