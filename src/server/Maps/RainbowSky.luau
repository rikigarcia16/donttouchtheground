--!nonstrict
-- RAINBOW SKY: three interleaved rainbow spiral staircases climb around a
-- central rainbow pillar. Spawn hub in the middle, bridges out to the arms,
-- bounce pads as shortcuts and a crown ring at the top.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local Decor = require(script.Parent.Decor)

local RGB = Color3.fromRGB

return function(ctx)
	local O: CFrame = ctx.origin
	local P = ctx.platforms
	local decor: Instance = ctx.decor
	local rng = ctx.rng

	local palette = {
		{ name = "RED", color = RGB(255, 70, 90) },
		{ name = "YELLOW", color = RGB(255, 215, 50) },
		{ name = "GREEN", color = RGB(70, 230, 120) },
		{ name = "BLUE", color = RGB(60, 150, 255) },
	}
	P.palette = { palette[1].color, palette[2].color, palette[3].color, palette[4].color }

	local spawns = {}

	-- Spawn hub: ring of checkpoint pads around a decorative core.
	local HUB_Y = 20
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local cf = O * CFrame.new(math.cos(a) * 13, HUB_Y, math.sin(a) * 13)
		P:Create("Checkpoint", cf, Vector3.new(7, 1.4, 7), { round = true })
		table.insert(spawns, cf * CFrame.new(0, 4, 0))
	end

	-- Three spiral arms.
	local ARMS, STEPS = 3, 21
	local typeCycle = {
		"Normal",
		"Normal",
		"Fragile",
		"Normal",
		"Disappearing",
		"Normal",
		"Slippery",
		"Normal",
		"Moving",
		"Normal",
		"Rotating",
		"Normal",
		"Fake",
		"Normal",
		"Disappearing",
		"Fragile",
		"Normal",
		"Normal",
		"Rotating",
		"Normal",
		"Normal",
	}
	for arm = 0, ARMS - 1 do
		for i = 0, STEPS - 1 do
			local angle = arm * (math.pi * 2 / ARMS) + math.rad(i * 18)
			local radius = 31 - i * 0.4
			local y = 8 + i * 3.6
			local cf = O
				* CFrame.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
				* CFrame.Angles(0, -angle, 0)
			local kind = typeCycle[(i + arm * 4) % #typeCycle + 1]
			local options: { [string]: any } = { colorGroup = (i + arm) % 4 + 1 }
			if kind == "Moving" then
				-- Slides radially, never further than the next step.
				options.motion = {
					kind = "Slide",
					vec = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 3,
					period = 5,
					phase = arm,
					start = 0,
					finish = math.huge,
				}
			elseif kind == "Rotating" then
				options.round = true
				options.motion = {
					kind = "Spin",
					vec = Vector3.new(if i % 2 == 0 then 1 else -1, 0, 0),
					period = 7,
					phase = 0,
					start = 0,
					finish = math.huge,
				}
			end
			local size = if kind == "Rotating" then Vector3.new(8, 1.2, 8) else Vector3.new(7, 1.2, 7)
			P:Create(kind :: any, cf, size, options)
		end
	end

	-- Bridges from the hub to each arm's 4th step (y ~ 18.8).
	for arm = 0, ARMS - 1 do
		local angle = arm * (math.pi * 2 / ARMS) + math.rad(3 * 18)
		for s = 0, 1 do
			local r = 19 + s * 4.5
			local cf = O
				* CFrame.new(math.cos(angle) * r, HUB_Y - 0.4 - s * 0.5, math.sin(angle) * r)
				* CFrame.Angles(0, -angle, 0)
			P:Create("Normal", cf, Vector3.new(4, 1, 4), { colorGroup = arm % 4 + 1 })
		end
	end

	-- Bounce pads tucked inside the spiral: each launches you (~23 studs) up to
	-- the arm step directly outward of it.
	for arm = 0, ARMS - 1 do
		for _, spec in { { step = 8, y = 21.8, r = 19.5 }, { step = 15, y = 40, r = 17.5 } } do
			local angle = arm * (math.pi * 2 / ARMS) + math.rad(spec.step * 18)
			local cf = O * CFrame.new(math.cos(angle) * spec.r, spec.y, math.sin(angle) * spec.r)
			P:Create("Bounce", cf, Vector3.new(6, 1, 6), { round = true })
		end
	end

	-- Crown ring at the top and the summit disc.
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2 + math.rad(15)
		local cf = O * CFrame.new(math.cos(a) * 14, 80, math.sin(a) * 14)
		P:Create(if i % 3 == 0 then "Fragile" else "Normal", cf, Vector3.new(6.5, 1.2, 6.5), { colorGroup = i % 4 + 1 })
	end
	P:Create(
		"Normal",
		O * CFrame.new(0, 84, 0),
		Vector3.new(8, 1.4, 8),
		{ round = true, color = RGB(255, 255, 255), symbol = "★" }
	)

	-- ===== Decoration
	local pillar = Build.model("RainbowPillar", decor)
	for band = 0, 13 do
		Build.cylinder(
			7,
			5,
			O * CFrame.new(0, -20 + band * 7 + 3.5, 0),
			Build.hue(band / 7, 0.75, 1),
			Enum.Material.SmoothPlastic,
			pillar
		)
		if band % 2 == 0 then
			Build.cylinder(
				0.6,
				6.2,
				O * CFrame.new(0, -20 + band * 7, 0),
				RGB(255, 255, 255),
				Enum.Material.Neon,
				pillar
			)
		end
	end
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2 + 0.6
		Decor.rainbowArc(
			O * CFrame.new(math.cos(a) * 75, -10, math.sin(a) * 75) * CFrame.Angles(0, -a + math.pi / 2, 0),
			42,
			decor
		)
	end
	for _ = 1, 26 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 50 + rng:NextNumber() * 90
		Decor.cloud(
			O * CFrame.new(math.cos(a) * r, -2 + rng:NextNumber() * 70, math.sin(a) * r),
			1 + rng:NextNumber() * 1.6,
			nil,
			decor
		)
	end
	for _ = 1, 18 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 40 + rng:NextNumber() * 50
		Decor.star(
			O * CFrame.new(math.cos(a) * r, 20 + rng:NextNumber() * 70, math.sin(a) * r),
			3 + rng:NextNumber() * 3,
			Build.hue(rng:NextNumber(), 0.5, 1),
			decor
		)
	end
	Decor.ambientEmitter(O * CFrame.new(0, 40, 0), Vector3.new(80, 60, 80), {
		texture = Decor.TEXTURES.Sparkle,
		color = ColorSequence.new(RGB(255, 200, 255), RGB(150, 220, 255)),
		rate = 12,
		lifetime = NumberRange.new(3, 5),
		speed = NumberRange.new(0.5, 1.5),
		size = NumberSequence.new(0.6, 0),
	}, decor)

	return {
		spawns = spawns,
		palette = palette,
		center = O.Position,
		radius = 50,
		topY = 84,
	}
end
