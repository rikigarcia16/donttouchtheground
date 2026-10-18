--!nonstrict
-- CANDY DISASTER: a giant layered cake in the centre circled by macaron
-- stairs, an outer spiral of lollipops (some spinning, some melting),
-- chocolate-bar bridges, glazed donuts and gumdrop bounce pads.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local Decor = require(script.Parent.Decor)

local RGB = Color3.fromRGB

local function candyCane(cf: CFrame, height: number, parent: Instance)
	local model = Build.model("CandyCane", parent)
	local stripes = math.floor(height / 2)
	for i = 0, stripes - 1 do
		Build.cylinder(
			2,
			2.4,
			cf * CFrame.new(0, i * 2 + 1, 0) * CFrame.Angles(0, 0, math.rad(8)),
			if i % 2 == 0 then RGB(255, 255, 255) else RGB(230, 30, 60),
			Enum.Material.SmoothPlastic,
			model
		)
	end
	Build.arc(
		3,
		2.4,
		2.4,
		0,
		math.pi,
		7,
		cf * CFrame.new(-3, height, 0),
		RGB(230, 30, 60),
		Enum.Material.SmoothPlastic,
		model
	)
	return model
end

return function(ctx)
	local O: CFrame = ctx.origin
	local P = ctx.platforms
	local decor: Instance = ctx.decor
	local rng = ctx.rng

	local palette = {
		{ name = "PINK", color = RGB(255, 120, 190) },
		{ name = "MINT", color = RGB(120, 240, 190) },
		{ name = "LEMON", color = RGB(255, 235, 110) },
		{ name = "GRAPE", color = RGB(170, 120, 255) },
	}
	P.palette = { palette[1].color, palette[2].color, palette[3].color, palette[4].color }
	local spawns = {}

	-- Cake tiers (y, diameter) with cream rims.
	local tiers = { { 14, 34 }, { 28, 24 }, { 42, 16 }, { 56, 10 } }
	for t, tier in tiers do
		local y, d = tier[1], tier[2]
		P:Create("Normal", O * CFrame.new(0, y, 0), Vector3.new(d, 2, d), {
			round = true,
			color = palette[(t - 1) % 4 + 1].color,
			colorGroup = (t - 1) % 4 + 1,
		})
		-- Sponge body under the frosting (decoration).
		Build.cylinder(10, d - 1, O * CFrame.new(0, y - 6, 0), RGB(250, 220, 170), Enum.Material.Sand, decor)
		Build.cylinder(
			1,
			d + 0.6,
			O * CFrame.new(0, y - 1.4, 0),
			RGB(255, 255, 255),
			Enum.Material.SmoothPlastic,
			decor
		)
		if t == 1 then
			-- Gumball start pads sitting on the bottom tier.
			for i = 0, 9 do
				local a = i / 10 * math.pi * 2
				local pad = O * CFrame.new(math.cos(a) * 11, y + 1.5, math.sin(a) * 11)
				P:Create("Checkpoint", pad, Vector3.new(5, 1, 5), { round = true, name = "StartPad" })
				table.insert(spawns, pad * CFrame.new(0, 4, 0))
			end
		end
		-- Macaron stairs up to the next tier.
		local nextTier = tiers[t + 1]
		if nextTier then
			local rise = nextTier[1] - y
			local steps = 4
			for s = 1, steps - 1 do
				local a = t * 1.7 + s * 0.55
				-- Outside the lower tier (no low ceilings), last step hugs the next tier.
				local r = if s < steps - 1 then d / 2 + 3 else nextTier[2] / 2 + 3
				P:Create(
					if s == 2 then "Fragile" else "Normal",
					O * CFrame.new(math.cos(a) * r, y + rise * s / steps, math.sin(a) * r),
					Vector3.new(5, 1.6, 5),
					{
						round = true,
						color = palette[(s + t) % 4 + 1].color,
						colorGroup = (s + t) % 4 + 1,
						name = "Macaron",
					}
				)
			end
		end
	end
	P:Create(
		"Normal",
		O * CFrame.new(0, 66, 0),
		Vector3.new(6, 1.4, 6),
		{ round = true, color = RGB(230, 20, 50), symbol = "🍒", name = "Cherry" }
	)
	Build.ball(5, O * CFrame.new(0, 69.5, 0), RGB(220, 10, 40), Enum.Material.SmoothPlastic, decor)

	-- Outer lollipop spiral.
	for i = 0, 19 do
		local a = i * math.rad(21)
		local r = 34 + math.sin(i * 0.7) * 3
		local y = 10 + i * 3.1
		local kind = if i % 7 == 3
			then "Rotating"
			elseif i % 5 == 2 then "Disappearing"
			elseif i % 9 == 8 then "Fake"
			else "Normal"
		local cf = O * CFrame.new(math.cos(a) * r, y, math.sin(a) * r)
		local options: { [string]: any } = { round = true, colorGroup = i % 4 + 1, name = "Lollipop" }
		if kind == "Rotating" then
			options.motion =
				{ kind = "Spin", vec = Vector3.new(1, 0, 0), period = 5, phase = 0, start = 0, finish = math.huge }
		end
		P:Create(kind :: any, cf, Vector3.new(8, 1.2, 8), options)
		Build.cylinder(
			y + 20,
			0.8,
			cf * CFrame.new(0, -(y + 20) / 2 - 0.6, 0),
			RGB(255, 255, 255),
			Enum.Material.SmoothPlastic,
			decor
		)
		-- Swirl on the candy (decorative ring).
		Build.ring(
			2.2,
			0.4,
			0.2,
			10,
			cf * CFrame.new(0, 0.7, 0),
			RGB(255, 255, 255),
			Enum.Material.SmoothPlastic,
			decor
		)
	end

	-- Chocolate bar bridges from the spiral to the tiers.
	for _, spec in { { from = 5, tier = 2 }, { from = 10, tier = 3 }, { from = 15, tier = 4 } } do
		local a = spec.from * math.rad(21)
		local y = tiers[spec.tier][1]
		local inner = tiers[spec.tier][2] / 2
		local count = math.ceil((34 - 4 - inner - 0.5) / 5.5)
		for b = 0, count - 1 do
			local r = inner + 3 + b * 5.5
			P:Create(
				if b % 2 == 1 then "Fragile" else "Normal",
				O * CFrame.new(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(0, -a, 0),
				Vector3.new(5, 1.2, 4),
				{
					color = RGB(110, 60, 35),
					material = Enum.Material.SmoothPlastic,
					name = "Chocolate",
					symbol = if b % 2 == 1 then "⚠" else "▦",
				}
			)
		end
	end

	-- Glazed donuts (slippery) and gumdrop bounce pads.
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + 0.4
		P:Create(
			"Slippery",
			O * CFrame.new(math.cos(a) * 22, 22 + i * 8, math.sin(a) * 22),
			Vector3.new(7, 1.6, 7),
			{ round = true, color = RGB(255, 170, 220), name = "Donut", symbol = "🍩" }
		)
		P:Create(
			"Bounce",
			O * CFrame.new(math.cos(a + 0.8) * 46, 12 + i * 4, math.sin(a + 0.8) * 46),
			Vector3.new(6, 1.4, 6),
			{ round = true, color = Build.hue(i / 4, 0.6, 1), name = "Gumdrop" }
		)
	end

	-- ===== Decoration
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + 0.2
		candyCane(O * CFrame.new(math.cos(a) * 62, -10, math.sin(a) * 62), 40 + (i % 3) * 10, decor)
	end
	for _ = 1, 40 do
		local a = rng:NextNumber() * math.pi * 2
		local r = 15 + rng:NextNumber() * 60
		Build.part({
			name = "Sprinkle",
			size = Vector3.new(0.6, 0.6, 2.4),
			cframe = O
				* CFrame.new(math.cos(a) * r, 5 + rng:NextNumber() * 70, math.sin(a) * r)
				* CFrame.Angles(rng:NextNumber() * 3, rng:NextNumber() * 3, 0),
			color = Build.hue(rng:NextNumber(), 0.7, 1),
			material = Enum.Material.SmoothPlastic,
			castShadow = false,
			parent = decor,
		})
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local cf = O * CFrame.new(math.cos(a) * 85, 10 + i * 6, math.sin(a) * 85)
		Build.ball(10, cf, Build.hue(i / 6, 0.5, 1), Enum.Material.SmoothPlastic, decor)
		Build.part({
			name = "Wrapper",
			class = "WedgePart",
			size = Vector3.new(1, 6, 6),
			cframe = cf * CFrame.new(7, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
			color = Build.hue(i / 6, 0.6, 0.9),
			parent = decor,
		})
		Build.part({
			name = "Wrapper",
			class = "WedgePart",
			size = Vector3.new(1, 6, 6),
			cframe = cf * CFrame.new(-7, 0, 0) * CFrame.Angles(0, math.rad(-90), 0),
			color = Build.hue(i / 6, 0.6, 0.9),
			parent = decor,
		})
	end
	Decor.ambientEmitter(O * CFrame.new(0, 35, 0), Vector3.new(90, 50, 90), {
		texture = Decor.TEXTURES.Sparkle,
		color = ColorSequence.new(RGB(255, 180, 230), RGB(255, 255, 180)),
		rate = 10,
		lifetime = NumberRange.new(3, 5),
		speed = NumberRange.new(0.5, 1),
		size = NumberSequence.new(0.8, 0),
	}, decor)

	return {
		spawns = spawns,
		palette = palette,
		center = O.Position,
		radius = 48,
		topY = 70,
	}
end
