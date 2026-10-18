--!nonstrict
-- VOLCANO ESCAPE: a double helix of rocky ledges spirals up an erupting
-- volcano. Obsidian ledges crack, magma vents launch you upward and the
-- crater rim is the last refuge.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local Decor = require(script.Parent.Decor)

local RGB = Color3.fromRGB
local ROCK = RGB(85, 70, 70)
local OBSIDIAN = RGB(40, 30, 50)

local function coneRadius(y: number): number
	return math.max(6, 40 - (y + 10) * 0.375)
end

return function(ctx)
	local O: CFrame = ctx.origin
	local P = ctx.platforms
	local decor: Instance = ctx.decor
	local rng = ctx.rng

	local palette = {
		{ name = "EMBER", color = RGB(255, 120, 40) },
		{ name = "ASH", color = RGB(150, 140, 140) },
		{ name = "SULFUR", color = RGB(240, 220, 70) },
		{ name = "JADE", color = RGB(70, 200, 150) },
	}
	P.palette = { palette[1].color, palette[2].color, palette[3].color, palette[4].color }
	local spawns = {}

	-- The cone (decoration).
	local cone = Build.model("Volcano", decor)
	for layer = 0, 15 do
		local y = -12 + layer * 5.5
		Build.cylinder(
			5.6,
			coneRadius(y) * 2 - 4,
			O * CFrame.new(0, y, 0),
			ROCK:Lerp(RGB(60, 45, 45), layer / 16),
			Enum.Material.Basalt,
			cone
		)
	end
	Build.cylinder(1, 10, O * CFrame.new(0, 75.5, 0), RGB(255, 90, 0), Enum.Material.Neon, cone)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + 0.3
		-- Glowing lava streams down the slopes.
		Build.part({
			name = "LavaStream",
			size = Vector3.new(1.6, 0.4, 70),
			cframe = O
				* CFrame.new(math.cos(a) * 22, 38, math.sin(a) * 22)
				* CFrame.Angles(0, -a + math.pi / 2, 0)
				* CFrame.Angles(math.rad(-68), 0, 0),
			color = RGB(255, 100, 10),
			material = Enum.Material.Neon,
			castShadow = false,
			parent = cone,
		})
	end
	local eruption = Decor.ambientEmitter(O * CFrame.new(0, 78, 0), Vector3.new(8, 1, 8), {
		texture = Decor.TEXTURES.Fire,
		color = ColorSequence.new(RGB(255, 200, 60), RGB(255, 40, 0)),
		rate = 20,
		lifetime = NumberRange.new(1.5, 2.5),
		speed = NumberRange.new(14, 24),
		size = NumberSequence.new(5, 1),
		acceleration = Vector3.new(0, -8, 0),
		lightEmission = 1,
	}, decor)
	eruption:SetAttribute("Eruption", true)
	Decor.ambientEmitter(O * CFrame.new(0, 82, 0), Vector3.new(10, 1, 10), {
		texture = Decor.TEXTURES.Smoke,
		color = ColorSequence.new(RGB(80, 70, 70), RGB(30, 25, 25)),
		rate = 6,
		lifetime = NumberRange.new(5, 8),
		speed = NumberRange.new(6, 10),
		size = NumberSequence.new(8, 22),
		transparency = NumberSequence.new(0.3, 1),
		lightEmission = 0,
	}, decor)

	-- Outer floating rocks: spawn ring.
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local cf = O * CFrame.new(math.cos(a) * 46, 18, math.sin(a) * 46)
		P:Create("Checkpoint", cf, Vector3.new(8, 2, 8), { round = true })
		table.insert(spawns, cf * CFrame.new(0, 4, 0))
		Decor.rock(cf * CFrame.new(0, -3, 0), 7, ROCK, decor)
	end

	-- Double helix of ledges.
	-- The angular step grows as the cone narrows so ledges stay ~11 studs apart.
	local STEPS = 24
	for arm = 0, 1 do
		local angle = arm * math.pi
		for i = 0, STEPS - 1 do
			local y = 14 + i * 2.8
			local r = coneRadius(y) + 4.5
			if i > 0 then
				angle += 11 / r
			end
			local kind = if i % 6 == 4
				then "Fragile"
				elseif i % 11 == 7 then "Disappearing"
				elseif i % 13 == 9 then "Slippery"
				elseif (i + arm * 5) % 17 == 12 then "Fake"
				else "Normal"
			local cf = O * CFrame.new(math.cos(angle) * r, y, math.sin(angle) * r) * CFrame.Angles(0, -angle, 0)
			P:Create(kind :: any, cf, Vector3.new(7, 1.6, 7.5), {
				color = if kind == "Fragile" or kind == "Slippery" then OBSIDIAN else nil,
				material = if kind == "Normal" then Enum.Material.Basalt else Enum.Material.Glass,
				colorGroup = (i + arm * 2) % 4 + 1,
				name = "Ledge",
			})
		end
	end

	-- Bridges from the spawn ring to the bottom of each helix arm.
	for arm = 0, 1 do
		local angle = arm * math.pi
		P:Create(
			"Normal",
			O * CFrame.new(math.cos(angle) * 41, 16.6, math.sin(angle) * 41) * CFrame.Angles(0, -angle, 0),
			Vector3.new(5, 1.2, 4.5),
			{ color = ROCK, material = Enum.Material.Slate, name = "RockBridge" }
		)
	end
	-- Stepping rocks between neighbouring spawn rocks so the whole ring connects.
	for i = 0, 9 do
		for j = 1, 3 do
			local a = (i + j / 4) / 10 * math.pi * 2
			P:Create(
				if (i + j) % 4 == 0 then "Fragile" else "Normal",
				O * CFrame.new(math.cos(a) * 46, 17.6 + (j % 2) * 0.8, math.sin(a) * 46),
				Vector3.new(4, 1.2, 4),
				{ round = true, color = ROCK, material = Enum.Material.Slate, name = "SteppingRock" }
			)
		end
	end

	-- Magma vents: bounce pads that launch you up a few helix turns.
	for i = 0, 3 do
		local angle = i * math.pi / 2 + math.rad(50)
		local y = 20 + i * 12
		local r = coneRadius(y) + 11
		P:Create(
			"Bounce",
			O * CFrame.new(math.cos(angle) * r, y, math.sin(angle) * r),
			Vector3.new(5, 1, 5),
			{ round = true, color = RGB(255, 80, 0), material = Enum.Material.Neon, name = "MagmaVent", symbol = "⇧" }
		)
	end

	-- Spinning basalt discs drifting around the mid slopes (alternate route).
	for i = 0, 2 do
		local angle = i / 3 * math.pi * 2 + math.rad(100)
		local y = 34 + i * 12
		local r = coneRadius(y) + 13
		P:Create("Rotating", O * CFrame.new(math.cos(angle) * r, y, math.sin(angle) * r), Vector3.new(8, 1.4, 8), {
			round = true,
			color = ROCK,
			material = Enum.Material.Basalt,
			name = "SpinningRock",
			motion = {
				kind = "Spin",
				vec = Vector3.new(if i % 2 == 0 then 1 else -1, 0, 0),
				period = 8,
				phase = 0,
				start = 0,
				finish = math.huge,
			},
		})
	end

	-- Crater rim.
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		P:Create(
			if i % 2 == 0 then "Normal" else "Fragile",
			O * CFrame.new(math.cos(a) * 9.5, 81, math.sin(a) * 9.5) * CFrame.Angles(0, -a, 0),
			Vector3.new(5, 1.6, 6),
			{ color = OBSIDIAN, material = Enum.Material.Basalt, name = "CraterRim" }
		)
	end

	for _ = 1, 16 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 60 + rng:NextNumber() * 70
		Decor.rock(
			O * CFrame.new(math.cos(a) * r, rng:NextNumber() * 50, math.sin(a) * r),
			4 + rng:NextNumber() * 8,
			ROCK,
			decor
		)
	end
	Decor.ambientEmitter(O * CFrame.new(0, 10, 0), Vector3.new(120, 4, 120), {
		texture = Decor.TEXTURES.Spark,
		color = ColorSequence.new(RGB(255, 200, 80), RGB(255, 60, 0)),
		rate = 18,
		lifetime = NumberRange.new(3, 5),
		speed = NumberRange.new(2, 5),
		size = NumberSequence.new(0.5, 0),
		acceleration = Vector3.new(0, 2, 0),
		lightEmission = 1,
	}, decor)

	return {
		spawns = spawns,
		palette = palette,
		center = O.Position,
		radius = 50,
		topY = 82,
	}
end
