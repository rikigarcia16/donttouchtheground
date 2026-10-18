--!nonstrict
-- The social lobby: a floating neon plaza with the shop pavilion, preview
-- pad, leaderboard podiums, global victories board, emote dance floor, map
-- portal and a friends' lounge island. Built once at server start.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local Decor = require(script.Parent.Decor)

local RGB = Color3.fromRGB
local FLOOR = RGB(235, 240, 255)
local PINK = RGB(255, 60, 170)
local CYAN = RGB(40, 220, 255)
local GOLD = RGB(255, 205, 60)
local PURPLE = RGB(140, 80, 255)

local function prompt(parent: BasePart, action: string, object: string, kind: string, distance: number?)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.MaxActivationDistance = distance or 12
	p.RequiresLineOfSight = false
	p.HoldDuration = 0
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p:SetAttribute("Kind", kind)
	p.Parent = parent
	return p
end

local function board(cf: CFrame, size: Vector3, title: string, accent: Color3, parent: Instance): (BasePart, Frame)
	local panel = Build.part({
		name = title .. "Board",
		size = size,
		cframe = cf,
		color = RGB(20, 18, 40),
		material = Enum.Material.SmoothPlastic,
		collide = true,
		parent = parent,
	})
	Build.neon(Vector3.new(size.X + 0.8, 0.6, size.Z + 0.4), cf * CFrame.new(0, size.Y / 2 + 0.3, 0), accent, parent)
	Build.neon(Vector3.new(size.X + 0.8, 0.6, size.Z + 0.4), cf * CFrame.new(0, -size.Y / 2 - 0.3, 0), accent, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Board"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui
	local header = Instance.new("TextLabel")
	header.Name = "Title"
	header.BackgroundColor3 = accent
	header.BorderSizePixel = 0
	header.Size = UDim2.fromScale(1, 0.16)
	header.Font = Enum.Font.LuckiestGuy
	header.TextScaled = true
	header.TextColor3 = RGB(255, 255, 255)
	header.Text = title
	header.Parent = root
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = RGB(0, 0, 0)
	stroke.Transparency = 0.4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = header
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromScale(0.04, 0.2)
	body.Size = UDim2.fromScale(0.92, 0.76)
	body.Parent = root
	gui.Parent = panel
	return panel, body
end

return function(origin: CFrame, parent: Instance)
	local lobby = Build.model("Lobby", parent)
	local O = origin
	local refs: { [string]: any } = {}

	-- ===== Main plaza
	local plaza = Build.cylinder(4, 150, O * CFrame.new(0, -2, 0), FLOOR, Enum.Material.SmoothPlastic, lobby)
	plaza.CanCollide = true
	plaza.CanQuery = true
	plaza.Name = "Plaza"
	for i, r in { 20, 45, 72 } do
		Build.ring(
			r,
			0.8,
			0.25,
			28 + i * 8,
			O * CFrame.new(0, 0.05, 0),
			if i % 2 == 0 then PINK else CYAN,
			Enum.Material.Neon,
			lobby
		)
	end
	-- Underside rock with hanging crystals.
	for layer = 1, 5 do
		Build.cylinder(
			5,
			150 - layer * 24,
			O * CFrame.new(0, -4 - layer * 4.5, 0),
			RGB(120, 110, 150):Lerp(RGB(60, 50, 90), layer / 5),
			Enum.Material.Slate,
			lobby
		)
	end
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		Decor.crystal(
			O * CFrame.new(math.cos(a) * 45, -22, math.sin(a) * 45) * CFrame.Angles(math.pi, 0, 0),
			10 + (i % 3) * 4,
			Build.hue(i / 12, 0.6, 1),
			lobby
		)
	end

	-- Spawn pad.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = O * CFrame.new(0, 0.5, 0)
	spawn.Color = CYAN
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.2
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = lobby
	refs.spawn = spawn

	-- ===== Title sign floating above the north edge.
	local titleCF = O * CFrame.new(0, 30, -62) * CFrame.Angles(math.rad(-12), 0, 0)
	local titlePanel = Build.part({
		name = "TitleSign",
		size = Vector3.new(70, 18, 1),
		cframe = titleCF,
		color = RGB(30, 20, 60),
		material = Enum.Material.SmoothPlastic,
		parent = lobby,
	})
	titlePanel.CFrame = titleCF * CFrame.Angles(0, math.pi, 0)
	local titleLabel = Build.label(
		titlePanel,
		Enum.NormalId.Front,
		"DON'T TOUCH THE GROUND",
		{ color = RGB(255, 255, 255), pixelsPerStud = 14, stroke = PINK }
	)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, RGB(255, 210, 60)),
		ColorSequenceKeypoint.new(0.5, RGB(255, 80, 160)),
		ColorSequenceKeypoint.new(1, RGB(80, 220, 255)),
	})
	gradient.Parent = titleLabel
	refs.titleGradient = gradient
	Build.neon(Vector3.new(72, 1, 1.2), titleCF * CFrame.new(0, 9.5, 0), PINK, lobby)
	Build.neon(Vector3.new(72, 1, 1.2), titleCF * CFrame.new(0, -9.5, 0), CYAN, lobby)
	for side = -1, 1, 2 do
		Build.cylinder(32, 2, O * CFrame.new(side * 34, 14, -60), RGB(60, 50, 100), Enum.Material.Metal, lobby)
		Build.ball(4, O * CFrame.new(side * 34, 31, -60), GOLD, Enum.Material.Neon, lobby)
	end

	-- ===== Shop pavilion (east)
	local shopCF = O * CFrame.new(46, 0, -8)
	local shopFloor =
		Build.cylinder(1, 26, shopCF * CFrame.new(0, 0.5, 0), RGB(60, 30, 90), Enum.Material.SmoothPlastic, lobby)
	shopFloor.CanCollide = true
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		Build.cylinder(
			14,
			1.4,
			shopCF * CFrame.new(math.cos(a) * 11, 7.5, math.sin(a) * 11),
			GOLD,
			Enum.Material.Metal,
			lobby
		)
	end
	Build.cylinder(1.5, 28, shopCF * CFrame.new(0, 15, 0), PINK, Enum.Material.SmoothPlastic, lobby)
	Build.cylinder(4, 20, shopCF * CFrame.new(0, 17.5, 0), RGB(255, 120, 200), Enum.Material.SmoothPlastic, lobby)
	Build.ring(14, 0.6, 0.6, 24, shopCF * CFrame.new(0, 15.9, 0), GOLD, Enum.Material.Neon, lobby)
	local shopSign = Decor.sign(
		shopCF * CFrame.new(0, 23, 0) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(16, 5, 1),
		"★ SHOP ★",
		PINK,
		RGB(255, 255, 255),
		lobby
	)
	shopSign.Name = "ShopSign"
	local counter = Build.part({
		name = "ShopCounter",
		size = Vector3.new(4, 3.5, 10),
		cframe = shopCF * CFrame.new(0, 2.75, 0),
		color = RGB(40, 25, 70),
		material = Enum.Material.SmoothPlastic,
		collide = true,
		parent = lobby,
	})
	Build.neon(Vector3.new(4.2, 0.4, 10.2), counter.CFrame * CFrame.new(0, 1.8, 0), CYAN, lobby)
	prompt(counter, "Open Shop", "Cosmetic Shop", "Shop", 14)
	-- Featured pedestals (labels filled in by LobbyService).
	refs.featured = {}
	for i = 1, 3 do
		local a = math.rad(-60 + (i - 1) * 60) + math.pi
		local pedCF = shopCF * CFrame.new(math.cos(a) * 7, 0, math.sin(a) * 7)
		Build.cylinder(3, 3, pedCF * CFrame.new(0, 2.5, 0), RGB(30, 20, 60), Enum.Material.SmoothPlastic, lobby).CanCollide =
			true
		local holo = Build.part({
			name = "FeaturedHolo",
			size = Vector3.new(2.5, 2.5, 2.5),
			cframe = pedCF * CFrame.new(0, 6, 0),
			color = GOLD,
			material = Enum.Material.ForceField,
			castShadow = false,
			parent = lobby,
		})
		holo:SetAttribute("Spin", true)
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(160, 70)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.MaxDistance = 60
		billboard.LightInfluence = 0
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = RGB(255, 255, 255)
		text.TextStrokeTransparency = 0.3
		text.Text = "FEATURED"
		text.Parent = billboard
		billboard.Parent = holo
		table.insert(refs.featured, { holo = holo, label = text })
	end

	-- ===== Preview pad (next to shop)
	local previewCF = O * CFrame.new(46, 0, 22)
	local previewPad =
		Build.cylinder(1, 14, previewCF * CFrame.new(0, 0.5, 0), RGB(30, 30, 60), Enum.Material.SmoothPlastic, lobby)
	previewPad.CanCollide = true
	previewPad.Name = "PreviewPad"
	Build.ring(7, 0.4, 0.3, 20, previewCF * CFrame.new(0, 1.1, 0), CYAN, Enum.Material.Neon, lobby)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + math.pi / 4
		Build.cylinder(
			10,
			0.8,
			previewCF * CFrame.new(math.cos(a) * 8, 5, math.sin(a) * 8),
			RGB(200, 200, 230),
			Enum.Material.Metal,
			lobby
		)
		Build.ball(
			1.6,
			previewCF * CFrame.new(math.cos(a) * 8, 10.5, math.sin(a) * 8),
			RGB(255, 255, 255),
			Enum.Material.Neon,
			lobby
		)
	end
	prompt(previewPad, "Preview Outfit", "Fitting Room", "Preview", 9)
	Decor.sign(
		previewCF * CFrame.new(9, 9, 0) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(10, 3, 0.6),
		"FITTING ROOM",
		CYAN,
		RGB(255, 255, 255),
		lobby
	)

	-- ===== Leaderboard plaza (west)
	local lbCF = O * CFrame.new(-48, 0, -6)
	local podiumHeights = { 9, 6, 4 }
	local podiumOffsets = { 0, -9, 9 }
	local podiumColors = { GOLD, RGB(210, 220, 235), RGB(220, 140, 80) }
	refs.podiums = {}
	for rank = 1, 3 do
		local h = podiumHeights[rank]
		local cf = lbCF * CFrame.new(6, h / 2, podiumOffsets[rank])
		local block = Build.part({
			name = "Podium" .. rank,
			size = Vector3.new(7, h, 7),
			cframe = cf,
			color = podiumColors[rank],
			material = Enum.Material.Metal,
			collide = true,
			parent = lobby,
		})
		Build.label(
			block,
			Enum.NormalId.Right,
			tostring(rank),
			{ color = RGB(255, 255, 255), stroke = RGB(0, 0, 0), pixelsPerStud = 10 }
		)
		refs.podiums[rank] = cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, math.rad(-90), 0)
	end
	local lbPanel, lbBody = board(
		lbCF * CFrame.new(-6, 12, 0) * CFrame.Angles(0, math.rad(-90), 0),
		Vector3.new(24, 20, 1),
		"TOP CHAMPIONS",
		GOLD,
		lobby
	)
	lbPanel.Name = "LeaderboardPanel"
	refs.leaderboardBody = lbBody
	local globalPanel, globalBody = board(
		lbCF * CFrame.new(-2, 7, 20) * CFrame.Angles(0, math.rad(-50), 0),
		Vector3.new(14, 8, 1),
		"GLOBAL VICTORIES",
		PINK,
		lobby
	)
	globalPanel.Name = "GlobalPanel"
	refs.globalBody = globalBody
	local statsPanel, statsBody = board(
		lbCF * CFrame.new(-2, 7, -20) * CFrame.Angles(0, math.rad(-130), 0),
		Vector3.new(14, 8, 1),
		"YOUR WINS",
		CYAN,
		lobby
	)
	statsPanel.Name = "StatsPanel"
	refs.statsBody = statsBody

	-- ===== Emote dance floor (south-west)
	local danceCF = O * CFrame.new(-30, 0, 40)
	local tiles = Build.model("DanceFloor", lobby)
	for x = -3, 3 do
		for z = -3, 3 do
			local tile = Build.part({
				name = "Tile",
				size = Vector3.new(3.8, 0.4, 3.8),
				cframe = danceCF * CFrame.new(x * 4, 0.2, z * 4),
				color = Build.hue((x + z) / 14, 0.7, 1),
				material = Enum.Material.Neon,
				castShadow = false,
				parent = tiles,
			})
			tile:SetAttribute("DanceTile", true)
		end
	end
	for side = -1, 1, 2 do
		local speaker = Build.part({
			name = "Speaker",
			size = Vector3.new(4, 9, 4),
			cframe = danceCF * CFrame.new(side * 17, 4.5, 0),
			color = RGB(25, 25, 30),
			material = Enum.Material.SmoothPlastic,
			collide = true,
			parent = lobby,
		})
		Build.cylinder(
			0.4,
			3,
			speaker.CFrame
				* CFrame.new(0, 1.5, -2.05)
				* CFrame.Angles(math.rad(90), 0, 0)
				* CFrame.Angles(0, 0, math.rad(-90)),
			PINK,
			Enum.Material.Neon,
			lobby
		)
	end
	local emoteBooth = Build.part({
		name = "EmoteBooth",
		size = Vector3.new(6, 4, 3),
		cframe = danceCF * CFrame.new(0, 2, -16),
		color = RGB(40, 20, 70),
		material = Enum.Material.SmoothPlastic,
		collide = true,
		parent = lobby,
	})
	prompt(emoteBooth, "Emotes", "Dance Floor", "Emotes", 14)
	Decor.sign(
		danceCF * CFrame.new(0, 10, -17),
		Vector3.new(16, 4, 0.6),
		"DANCE FLOOR",
		PURPLE,
		RGB(255, 255, 255),
		lobby
	)
	refs.danceFloor = tiles

	-- ===== Map portal (south)
	local portalCF = O * CFrame.new(18, 0, 55)
	local portal = Build.model("MapPortal", lobby)
	Build.ring(
		10,
		1.5,
		2,
		24,
		portalCF * CFrame.new(0, 12, 0) * CFrame.Angles(math.rad(90), 0, 0),
		PINK,
		Enum.Material.Neon,
		portal
	)
	local swirl = Build.cylinder(
		0.3,
		18,
		portalCF * CFrame.new(0, 12, 0) * CFrame.Angles(math.rad(90), 0, 0),
		PURPLE,
		Enum.Material.ForceField,
		portal
	)
	swirl.Name = "PortalSwirl"
	swirl.Transparency = 0.2
	swirl:SetAttribute("Swirl", true)
	local portalBase = Build.part({
		name = "PortalBase",
		size = Vector3.new(24, 2, 6),
		cframe = portalCF * CFrame.new(0, 1, 0),
		color = RGB(40, 30, 70),
		material = Enum.Material.SmoothPlastic,
		collide = true,
		parent = portal,
	})
	prompt(portalBase, "Vote / Spectate", "Map Portal", "Portal", 14)
	local portalPanel, portalBody =
		board(portalCF * CFrame.new(0, 27, 0), Vector3.new(20, 7, 1), "NEXT ROUND", CYAN, portal)
	portalPanel.Name = "PortalPanel"
	refs.portalBody = portalBody

	-- ===== Friends lounge island (north-east), joined by a bridge.
	local loungeCF = O * CFrame.new(70, 4, -62)
	local lounge = Build.cylinder(3, 36, loungeCF, RGB(200, 245, 220), Enum.Material.Grass, lobby)
	lounge.CanCollide = true
	lounge.CanQuery = true
	lounge.Name = "Lounge"
	for layer = 1, 3 do
		Build.cylinder(
			3,
			36 - layer * 9,
			loungeCF * CFrame.new(0, -2.5 - layer * 2.6, 0),
			RGB(120, 100, 140),
			Enum.Material.Slate,
			lobby
		)
	end
	local bridgeStart = O * CFrame.new(52, 0, -40)
	local bridgeEnd = loungeCF * CFrame.new(-10, 1.5, 12)
	local mid = (bridgeStart.Position + bridgeEnd.Position) / 2
	local bridgeLength = (bridgeEnd.Position - bridgeStart.Position).Magnitude
	local bridge = Build.part({
		name = "LoungeBridge",
		size = Vector3.new(6, 1, bridgeLength + 4),
		cframe = CFrame.lookAt(mid, bridgeEnd.Position),
		color = RGB(170, 120, 80),
		material = Enum.Material.WoodPlanks,
		collide = true,
		parent = lobby,
	})
	Build.neon(Vector3.new(0.3, 0.3, bridgeLength + 4), bridge.CFrame * CFrame.new(3, 1.5, 0), CYAN, lobby)
	Build.neon(Vector3.new(0.3, 0.3, bridgeLength + 4), bridge.CFrame * CFrame.new(-3, 1.5, 0), CYAN, lobby)
	-- Campfire with benches (Seats).
	local fireCF = loungeCF * CFrame.new(0, 1.5, 0)
	Build.cylinder(1, 5, fireCF * CFrame.new(0, 0.5, 0), RGB(90, 80, 80), Enum.Material.Slate, lobby)
	local fireAnchor = Build.part({
		name = "Campfire",
		size = Vector3.new(2, 1, 2),
		cframe = fireCF * CFrame.new(0, 1.5, 0),
		transparency = 1,
		parent = lobby,
	})
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Heat = 6
	fire.Color = RGB(255, 140, 40)
	fire.SecondaryColor = RGB(255, 60, 20)
	fire.Parent = fireAnchor
	Build.light(fireAnchor, RGB(255, 160, 80), 22, 2)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local seat = Instance.new("Seat")
		seat.Name = "Bench"
		seat.Anchored = true
		seat.Size = Vector3.new(5, 1, 2)
		seat.CFrame = CFrame.lookAt(
			(fireCF * CFrame.new(math.cos(a) * 8, 0.5, math.sin(a) * 8)).Position,
			fireCF.Position + Vector3.new(0, 0.5, 0)
		)
		seat.Color = RGB(150, 100, 70)
		seat.Material = Enum.Material.Wood
		seat.TopSurface = Enum.SurfaceType.Smooth
		seat.Parent = lobby
	end
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		local lanternCF = loungeCF * CFrame.new(math.cos(a) * 15, 6, math.sin(a) * 15)
		Build.cylinder(5, 0.4, lanternCF * CFrame.new(0, -2.5, 0), RGB(80, 60, 50), Enum.Material.Wood, lobby)
		local lantern = Build.ball(1.6, lanternCF, Build.hue(i / 8, 0.5, 1), Enum.Material.Neon, lobby)
		lantern:SetAttribute("Bob", i)
	end
	Decor.sign(
		loungeCF * CFrame.new(0, 12, -17),
		Vector3.new(14, 3.5, 0.6),
		"FRIENDS LOUNGE",
		RGB(80, 200, 140),
		RGB(255, 255, 255),
		lobby
	)

	-- ===== Ambient decoration: floating islets, rainbow, clouds, sparkles.
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2 + 0.2
		local cf = O * CFrame.new(math.cos(a) * 110, -10 + (i % 3) * 14, math.sin(a) * 110)
		Build.cylinder(3, 14 + (i % 3) * 4, cf, RGB(140, 230, 140), Enum.Material.Grass, lobby)
		Build.cylinder(5, 8, cf * CFrame.new(0, -4, 0), RGB(120, 100, 140), Enum.Material.Slate, lobby)
		Decor.crystal(cf * CFrame.new(0, 1.5, 0), 8, Build.hue(i / 8, 0.6, 1), lobby)
	end
	Decor.rainbowArc(O * CFrame.new(-10, -30, -150), 80, lobby)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		Decor.cloud(O * CFrame.new(math.cos(a) * 140, -40 + (i % 4) * 8, math.sin(a) * 140), 2 + (i % 3), nil, lobby)
	end
	Decor.ambientEmitter(O * CFrame.new(0, 12, 0), Vector3.new(130, 20, 130), {
		texture = Decor.TEXTURES.Sparkle,
		color = ColorSequence.new(RGB(255, 200, 255), RGB(150, 230, 255)),
		rate = 14,
		lifetime = NumberRange.new(3, 5),
		speed = NumberRange.new(0.3, 1),
		size = NumberSequence.new(0.6, 0),
	}, lobby)

	return lobby, refs
end
