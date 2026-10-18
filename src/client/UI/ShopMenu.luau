--!nonstrict
-- The cosmetic shop and collection menu. Modes: FEATURED (daily rotation,
-- discounted), SHOP (permanent catalogue), COLLECTION (everything, owned and
-- locked, with completion %), SETS (themed collections + rewards) and
-- PRESETS. Filters by category/rarity, sorting, favourites, a 3D preview
-- and try-on on the real avatar. Every purchase/equip is server-validated.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local RarityConfig = require(Shared.Config.RarityConfig)
local CollectionConfig = require(Shared.Config.CollectionConfig)
local AchievementConfig = require(Shared.Config.AchievementConfig)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local ShopRules = require(Shared.Logic.ShopRules)
local ProgressLogic = require(Shared.Logic.ProgressLogic)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Net.Remotes)
local FxKit = require(Shared.Visual.FxKit)
local Visuals = require(Shared.Visual.CosmeticVisuals)
local TitleStyles = require(Shared.Visual.TitleStyles)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local ShopMenu = {}

local player = Players.LocalPlayer

local RARITY_FILTERS = { "All", "Common", "Rare", "Epic", "Legendary", "Mythic" }
local SORTS = { "Default", "Price ↑", "Price ↓", "Rarity" }

local function unlockText(item): string
	local unlock = item.unlock
	if unlock.kind == "Achievement" then
		local achievement = AchievementConfig.ById[unlock.id]
		return "🏅 Achievement: " .. (if achievement then achievement.name else unlock.id)
	elseif unlock.kind == "Collection" then
		local collection = CollectionConfig.ById[unlock.id]
		return "🧩 Complete the " .. (if collection then collection.name else unlock.id)
	elseif unlock.kind == "Level" then
		return "⬆️ Reach level " .. tostring(unlock.level)
	elseif unlock.kind == "Default" then
		return "Starter item"
	end
	return ""
end

local function priceText(price: number?, currency: string): string
	if not price then
		return ""
	end
	return (if currency == "Coins" then "🪙 " else "🏆 ") .. Format.commas(price)
end

function ShopMenu.build(UI, controllers)
	local State = controllers.ClientState
	local Renderer = controllers.CosmeticRenderer
	local Emotes = controllers.EmoteController
	local Camera = controllers.CameraController
	local Audio = controllers.AudioController
	local layer = UI.Layers().menu

	local root = new(
		"Frame",
		{ Name = "ShopMenu", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = layer }
	)
	local dimmer = Widgets.dimmer(root, 1)
	local panel, content = Widgets.panel({
		Name = "Window",
		Title = "COSMETICS",
		Accent = C.Pink,
		TitleWidth = 300,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(1200, 620),
		ZIndex = 2,
		Parent = root,
	})
	local scale = new("UIScale", { Parent = panel })

	local mode = "Shop"
	local category = "All"
	local rarityIndex = 1
	local sortIndex = 1
	local onlyFavorites = false
	local selected = nil
	local fittingRoom = false

	-- ===== Header: mode tabs + wallet + close
	local tabs = new("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(310, -26),
		Size = UDim2.fromOffset(700, 44),
		ZIndex = 5,
		Parent = panel,
	})
	Widgets.list(tabs, Enum.FillDirection.Horizontal, 8)
	local tabButtons = {}
	local MODES = {
		{ "Featured", "⭐ FEATURED" },
		{ "Shop", "🛒 SHOP" },
		{ "Inventory", "🎒 COLLECTION" },
		{ "Sets", "🧩 SETS" },
		{ "Presets", "💾 PRESETS" },
	}
	local refresh: () -> () = function() end
	for i, m in MODES do
		tabButtons[m[1]] = Widgets.button({
			Name = m[1],
			Text = m[2],
			Style = "Ghost",
			Size = UDim2.fromOffset(132, 42),
			LayoutOrder = i,
			MaxTextSize = 18,
			ZIndex = 5,
			OnClick = function()
				mode = m[1]
				refresh()
			end,
			Parent = tabs,
		})
	end
	local walletText = label({
		Name = "Wallet",
		Text = "",
		Font = F.Display,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -70, 0, -22),
		Size = UDim2.fromOffset(260, 34),
		AlignX = Enum.TextXAlignment.Right,
		Color = C.Wins,
		Stroke = 2,
		ZIndex = 5,
		Parent = panel,
	})
	Widgets.button({
		Name = "Close",
		Text = "✕",
		Style = "Danger",
		Size = UDim2.fromOffset(48, 48),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 14, 0, -24),
		ZIndex = 6,
		OnClick = function()
			UI.Close("Shop")
			UI.Close("Inventory")
		end,
		Parent = panel,
	})

	-- ===== Left: categories
	local categoryColumn = Widgets.scroll({
		Name = "Categories",
		Position = UDim2.fromOffset(14, 14),
		Size = UDim2.new(0, 168, 1, -28),
		Parent = content,
	})
	Widgets.list(categoryColumn, Enum.FillDirection.Vertical, 6)
	local categoryButtons = {}
	local allCategories = { { id = "All", name = "All", icon = "✨" } }
	for _, info in CosmeticCatalog.Categories do
		table.insert(allCategories, info)
	end
	for i, info in allCategories do
		categoryButtons[info.id] = Widgets.button({
			Name = info.id,
			Text = info.icon .. " " .. info.name,
			Style = "Ghost",
			Size = UDim2.new(1, -10, 0, 40),
			LayoutOrder = i,
			MaxTextSize = 18,
			OnClick = function()
				category = info.id
				refresh()
			end,
			Parent = categoryColumn,
		})
	end

	-- ===== Centre: filters + grid
	local centre = new("Frame", {
		Name = "Centre",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(196, 14),
		Size = UDim2.new(1, -196 - 360, 1, -28),
		Parent = content,
	})
	local filters =
		new("Frame", { Name = "Filters", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = centre })
	Widgets.list(filters, Enum.FillDirection.Horizontal, 8)
	local rarityButton = Widgets.button({
		Name = "Rarity",
		Text = "RARITY: ALL",
		Style = "Ghost",
		Size = UDim2.fromOffset(170, 38),
		LayoutOrder = 1,
		MaxTextSize = 16,
		OnClick = function()
			rarityIndex = rarityIndex % #RARITY_FILTERS + 1
			refresh()
		end,
		Parent = filters,
	})
	local sortButton = Widgets.button({
		Name = "Sort",
		Text = "SORT: DEFAULT",
		Style = "Ghost",
		Size = UDim2.fromOffset(170, 38),
		LayoutOrder = 2,
		MaxTextSize = 16,
		OnClick = function()
			sortIndex = sortIndex % #SORTS + 1
			refresh()
		end,
		Parent = filters,
	})
	local favButton = Widgets.button({
		Name = "Favorites",
		Text = "♡ FAVOURITES",
		Style = "Ghost",
		Size = UDim2.fromOffset(160, 38),
		LayoutOrder = 3,
		MaxTextSize = 16,
		OnClick = function()
			onlyFavorites = not onlyFavorites
			refresh()
		end,
		Parent = filters,
	})
	local headerInfo = label({
		Name = "Info",
		Text = "",
		Font = F.Heavy,
		Size = UDim2.new(1, -520, 0, 38),
		LayoutOrder = 4,
		Color = C.Muted,
		MaxTextSize = 16,
		Parent = filters,
	})

	local grid = Widgets.scroll({
		Name = "Grid",
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		Parent = centre,
	})
	Widgets.padding(grid, 6)
	local gridLayout = new("UIGridLayout", {
		CellSize = UDim2.fromOffset(146, 178),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	-- ===== Right: detail panel
	local detail = new("Frame", {
		Name = "Detail",
		BackgroundColor3 = C.InkSoft,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.new(0, 340, 1, -28),
		Parent = content,
	})
	Widgets.corner(detail, 8)
	Widgets.stroke(detail, C.Shadow, 3)
	local viewport = new("ViewportFrame", {
		Name = "Preview",
		BackgroundColor3 = C.Ink,
		Size = UDim2.new(1, -20, 0, 210),
		Position = UDim2.fromOffset(10, 10),
		Ambient = Color3.fromRGB(200, 200, 220),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-1, -1, -1),
		Parent = detail,
	})
	Widgets.corner(viewport, 6)
	local previewIcon = label({
		Name = "Icon",
		Text = "",
		Font = F.Heavy,
		Size = UDim2.fromScale(0.6, 0.6),
		Position = UDim2.fromScale(0.2, 0.2),
		AlignX = Enum.TextXAlignment.Center,
		Parent = viewport,
	})
	local viewportGradient = Widgets.gradient(viewport, { C.InkLight, C.Ink }, 90)
	local worldModel = new("WorldModel", { Parent = viewport })
	local viewportCamera = new("Camera", { FieldOfView = 40, Parent = viewport }) :: Camera
	viewport.CurrentCamera = viewportCamera
	local detailName = label({
		Name = "Name",
		Text = "Select an item",
		Font = F.Display,
		Size = UDim2.new(1, -20, 0, 34),
		Position = UDim2.fromOffset(10, 228),
		Stroke = 2,
		Parent = detail,
	})
	local rarityTag = new("Frame", {
		Name = "Rarity",
		BackgroundColor3 = C.Muted,
		Size = UDim2.fromOffset(130, 26),
		Position = UDim2.fromOffset(10, 266),
		Rotation = Theme.Slant,
		Parent = detail,
	})
	Widgets.stroke(rarityTag, C.Shadow, 2)
	local rarityText = label({
		Text = "",
		Font = F.Display,
		Size = UDim2.new(1, -8, 1, -4),
		Position = UDim2.fromOffset(4, 2),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 1.5,
		Parent = rarityTag,
	})
	local categoryText = label({
		Text = "",
		Font = F.Heavy,
		Size = UDim2.new(1, -160, 0, 22),
		Position = UDim2.fromOffset(150, 268),
		Color = C.Muted,
		MaxTextSize = 16,
		Parent = detail,
	})
	local description = label({
		Name = "Description",
		Text = "",
		Font = F.Body,
		Size = UDim2.new(1, -20, 0, 54),
		Position = UDim2.fromOffset(10, 298),
		AlignY = Enum.TextYAlignment.Top,
		MaxTextSize = 16,
		Parent = detail,
	})
	local statusText = label({
		Name = "Status",
		Text = "",
		Font = F.Heavy,
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.fromOffset(10, 354),
		Color = C.Yellow,
		AlignY = Enum.TextYAlignment.Top,
		MaxTextSize = 15,
		Rich = true,
		Parent = detail,
	})
	local actionButton = Widgets.button({
		Name = "Action",
		Text = "BUY",
		Style = "Gold",
		Size = UDim2.new(1, -20, 0, 52),
		Position = UDim2.new(0, 10, 1, -120),
		Parent = detail,
	})
	local tryButton = Widgets.button({
		Name = "TryOn",
		Text = "👁 TRY ON",
		Style = "Primary",
		Size = UDim2.new(0.5, -15, 0, 46),
		Position = UDim2.new(0, 10, 1, -60),
		MaxTextSize = 20,
		Parent = detail,
	})
	local favDetail = Widgets.button({
		Name = "Fav",
		Text = "♡",
		Style = "Ghost",
		Size = UDim2.new(0.5, -15, 0, 46),
		Position = UDim2.new(0.5, 5, 1, -60),
		MaxTextSize = 24,
		Parent = detail,
	})

	-- ===== Preview model (clone of the avatar in the viewport)
	local previewModel: Model? = nil
	local previewKit = nil
	local previewAngle = 0
	local podiumModel: Model? = nil

	local function clearPreview()
		if previewKit then
			previewKit:Destroy()
			previewKit = nil
		end
		if podiumModel then
			podiumModel:Destroy()
			podiumModel = nil
		end
	end

	local function ensureAvatar(): Model?
		if previewModel and previewModel.Parent then
			return previewModel
		end
		local character = player.Character
		if not character then
			return nil
		end
		local archivable = character.Archivable
		character.Archivable = true
		local clone = character:Clone()
		character.Archivable = archivable
		if not clone then
			return nil
		end
		for _, d in clone:GetDescendants() do
			if
				d:IsA("Script")
				or d:IsA("LocalScript")
				or d:IsA("Sound")
				or d.Name == "DTTG_Cosmetics"
				or d:IsA("BillboardGui")
			then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		local humanoid = clone:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		clone:PivotTo(CFrame.new(0, 0, 0))
		clone.Parent = worldModel
		previewModel = clone
		return clone
	end

	local function showPreview(item)
		clearPreview()
		previewIcon.Text = item.icon
		local rarity = RarityConfig.get(item.rarity)
		viewportGradient.Color = ColorSequence.new(rarity.gradient[1]:Lerp(C.Ink, 0.5), C.Ink)
		local avatar = ensureAvatar()
		if avatar then
			avatar.Parent = if item.category == "Accessory" or item.category == "Podium" then worldModel else nil
		end
		if item.category == "Accessory" and avatar then
			previewIcon.Text = ""
			previewKit = FxKit.new(avatar, FxKit.DEFAULT_QUALITY)
			local builder = Visuals.Accessory[item.id]
			if builder then
				pcall(builder, previewKit)
			end
			-- Anchor everything (no physics in the viewport) at its welded place.
			for _, d in previewKit.folder:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
		elseif item.category == "Podium" then
			previewIcon.Text = ""
			local builder = Visuals.Podium[item.id]
			if builder then
				local ok, model, height = pcall(builder, CFrame.new(0, -7, 0), worldModel)
				if ok then
					podiumModel = model
					if avatar then
						avatar:PivotTo(CFrame.new(0, -7 + height + 3, 0))
					end
				end
			end
		end
	end

	RunService.RenderStepped:Connect(function(dt)
		if not root.Visible then
			return
		end
		previewAngle += dt * 0.6
		local focus = if selected and selected.category == "Podium"
			then Vector3.new(0, -3, 0)
			else Vector3.new(0, 1.5, 0)
		local distance = if selected and selected.category == "Podium" then 26 else 9
		viewportCamera.CFrame = CFrame.lookAt(
			focus + Vector3.new(math.sin(previewAngle) * distance, 2, math.cos(previewAngle) * distance),
			focus
		)
		if previewIcon.Text ~= "" then
			previewIcon.Rotation = math.sin(os.clock() * 2) * 6
		end
	end)

	-- ===== Data helpers
	local function profile()
		return State.Get()
	end

	local function filteredItems()
		local p = profile()
		local list = {}
		local rarityFilter = RARITY_FILTERS[rarityIndex]
		for _, item in CosmeticCatalog.Items do
			local include = true
			if mode == "Featured" then
				include = State.featuredSet[item.id] == true
			elseif mode == "Shop" then
				include = CosmeticCatalog.isPurchasable(item)
			end
			if include and category ~= "All" and item.category ~= category then
				include = false
			end
			if include and rarityFilter ~= "All" and item.rarity ~= rarityFilter then
				include = false
			end
			if include and onlyFavorites and not (p and p.favorites[item.id]) then
				include = false
			end
			if include then
				table.insert(list, item)
			end
		end
		local sortMode = SORTS[sortIndex]
		table.sort(list, function(a, b)
			if mode == "Featured" then
				return (table.find(State.featured, a.id) or 0) < (table.find(State.featured, b.id) or 0)
			end
			if sortMode == "Price ↑" or sortMode == "Price ↓" then
				local pa = a.price or math.huge
				local pb = b.price or math.huge
				if a.currency ~= b.currency then
					return a.currency == "Wins"
				end
				if pa ~= pb then
					return if sortMode == "Price ↑" then pa < pb else pa > pb
				end
			elseif sortMode == "Rarity" then
				local ra, rb = RarityConfig.get(a.rarity).order, RarityConfig.get(b.rarity).order
				if ra ~= rb then
					return ra > rb
				end
			end
			return a.order < b.order
		end)
		return list
	end

	local selectDetail: (any) -> ()

	local function card(item, index: number)
		local p = profile()
		local rarity = RarityConfig.get(item.rarity)
		local owned = p and p.owned[item.id] ~= nil
		local equipSlot = CosmeticCatalog.equipSlot(item)
		local equipped = p and owned and item.category ~= "Emote" and ShopRules.isEquipped(p.equipped, item, equipSlot)
		local button = new("TextButton", {
			Name = item.id,
			AutoButtonColor = false,
			Text = "",
			Selectable = true,
			BackgroundColor3 = C.Ink,
			LayoutOrder = index,
			Parent = grid,
		})
		Widgets.corner(button, 8)
		Widgets.gradient(button, { rarity.gradient[1]:Lerp(C.Ink, 0.35), C.Ink }, 90)
		Widgets.rarityFrame(button, rarity, 1)
		local iconLabel = label({
			Text = item.icon,
			Font = F.Heavy,
			Size = UDim2.new(1, -30, 0, 80),
			Position = UDim2.fromOffset(15, 10),
			AlignX = Enum.TextXAlignment.Center,
			ZIndex = 2,
			Parent = button,
		})
		label({
			Text = item.name,
			Font = F.Heavy,
			Size = UDim2.new(1, -12, 0, 36),
			Position = UDim2.fromOffset(6, 94),
			AlignX = Enum.TextXAlignment.Center,
			MaxTextSize = 16,
			ZIndex = 2,
			Parent = button,
		})
		local footer = new("Frame", {
			BackgroundColor3 = rarity.color,
			Size = UDim2.new(1, 0, 0, 34),
			Position = UDim2.new(0, 0, 1, -34),
			ZIndex = 2,
			Parent = button,
		})
		Widgets.corner(footer, 8)
		local footerText
		if equipped then
			footerText = "✔ EQUIPPED"
		elseif owned then
			footerText = "OWNED"
		elseif CosmeticCatalog.isPurchasable(item) then
			footerText = priceText(ShopRules.priceFor(item, State.featuredSet, State.discountPercent), item.currency)
		else
			footerText = "🔒 LOCKED"
		end
		label({
			Text = footerText,
			Font = F.Display,
			Size = UDim2.new(1, -10, 1, -6),
			Position = UDim2.fromOffset(5, 3),
			AlignX = Enum.TextXAlignment.Center,
			Stroke = 1.5,
			ZIndex = 3,
			Parent = footer,
		})
		label({
			Text = rarity.glyph,
			Font = F.Heavy,
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.fromOffset(6, 6),
			Color = rarity.accent,
			ZIndex = 3,
			Parent = button,
		})
		if p and p.favorites[item.id] then
			label({
				Text = "♥",
				Font = F.Heavy,
				Size = UDim2.fromOffset(22, 22),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -6, 0, 6),
				Color = C.Pink,
				ZIndex = 3,
				Parent = button,
			})
		end
		if State.featuredSet[item.id] and CosmeticCatalog.isPurchasable(item) and not owned then
			local badge = new("Frame", {
				BackgroundColor3 = C.Pink,
				Size = UDim2.fromOffset(64, 22),
				Position = UDim2.new(1, -60, 0, 26),
				Rotation = 12,
				ZIndex = 4,
				Parent = button,
			})
			Widgets.stroke(badge, C.Shadow, 2)
			label({
				Text = "-" .. State.discountPercent .. "%",
				Font = F.Display,
				Size = UDim2.fromScale(1, 1),
				AlignX = Enum.TextXAlignment.Center,
				ZIndex = 5,
				Parent = badge,
			})
		end
		if not owned and not CosmeticCatalog.isPurchasable(item) then
			iconLabel.TextTransparency = 0.55
		end
		local cardScale = new("UIScale", { Parent = button })
		button.MouseEnter:Connect(function()
			Widgets.tween(cardScale, Theme.Motion.Fast, { Scale = 1.05 })
		end)
		button.MouseLeave:Connect(function()
			Widgets.tween(cardScale, Theme.Motion.Fast, { Scale = 1 })
		end)
		button.SelectionGained:Connect(function()
			Widgets.tween(cardScale, Theme.Motion.Fast, { Scale = 1.06 })
		end)
		button.SelectionLost:Connect(function()
			Widgets.tween(cardScale, Theme.Motion.Fast, { Scale = 1 })
		end)
		button.Activated:Connect(function()
			if Audio then
				Audio.Play("UiClick")
			end
			selectDetail(item)
		end)
		return button
	end

	-- ===== Celebration overlay (scales with rarity)
	local function celebrate(item)
		local rarity = RarityConfig.get(item.rarity)
		Audio.Play(rarity.purchaseSound)
		local overlay = UI.Layers().overlay
		local splash = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(420, 300),
			ZIndex = 50,
			Parent = overlay,
		})
		local burst = new("Frame", {
			BackgroundColor3 = rarity.color,
			BackgroundTransparency = 0.2,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(40, 40),
			Rotation = 45,
			ZIndex = 50,
			Parent = splash,
		})
		Widgets.stroke(burst, C.Shadow, 4)
		Widgets.tween(burst, Theme.Motion.Pop, { Size = UDim2.fromOffset(260, 260) })
		local icon = label({
			Text = item.icon,
			Font = F.Heavy,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(160, 160),
			AlignX = Enum.TextXAlignment.Center,
			ZIndex = 52,
			Parent = splash,
		})
		local iconScale = new("UIScale", { Scale = 0.2, Parent = icon })
		Widgets.tween(iconScale, Theme.Motion.Pop, { Scale = 1 })
		label({
			Text = string.upper(rarity.displayName) .. "!",
			Font = F.Display,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, -40),
			Size = UDim2.fromOffset(420, 50),
			AlignX = Enum.TextXAlignment.Center,
			Color = rarity.accent,
			Stroke = 3,
			ZIndex = 52,
			Parent = splash,
		})
		-- Confetti glyphs: more and fancier for higher rarities.
		local amount = ({ 8, 14, 22, 32, 46 })[rarity.order]
		for i = 1, amount do
			local glyph = label({
				Text = ({ "★", "✦", "◆", "●", "✺" })[math.random(1, math.min(5, rarity.order + 1))],
				Font = F.Heavy,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.45),
				Size = UDim2.fromOffset(26, 26),
				AlignX = Enum.TextXAlignment.Center,
				Color = rarity.gradient[(i % #rarity.gradient) + 1],
				ZIndex = 51,
				Parent = splash,
			})
			local angle = math.random() * math.pi * 2
			local distance = 120 + math.random() * (80 + rarity.order * 40)
			Widgets.tween(glyph, TweenInfo.new(0.9, Enum.EasingStyle.Quint), {
				Position = UDim2.new(0.5, math.cos(angle) * distance, 0.45, math.sin(angle) * distance),
				Rotation = math.random(-200, 200),
				TextTransparency = 1,
			})
		end
		if rarity.order >= 4 then
			local flash = new("Frame", {
				BackgroundColor3 = rarity.accent,
				BackgroundTransparency = 0.3,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 49,
				Parent = overlay,
			})
			Widgets.tween(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 })
			game:GetService("Debris"):AddItem(flash, 0.9)
		end
		-- And a burst in the world around the player.
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			if rarity.order >= 5 then
				Visuals.Bursts.Jump.jump_cosmic(root.Position)
			elseif rarity.order >= 3 then
				Visuals.Bursts.Land.land_star(root.Position)
			else
				Visuals.Bursts.Land.land_confetti(root.Position)
			end
		end
		task.delay(1.6, function()
			Widgets.tween(burst, Theme.Motion.Fast, { BackgroundTransparency = 1 })
			Widgets.tween(icon, Theme.Motion.Fast, { TextTransparency = 1 })
			task.wait(0.25)
			splash:Destroy()
		end)
	end

	-- ===== Detail panel logic
	selectDetail = function(item)
		selected = item
		local p = profile()
		if not item or not p then
			return
		end
		local rarity = RarityConfig.get(item.rarity)
		detailName.Text = item.name
		rarityTag.BackgroundColor3 = rarity.color
		rarityText.Text = string.upper(rarity.displayName)
		local categoryInfo = nil
		for _, info in CosmeticCatalog.Categories do
			if info.id == item.category then
				categoryInfo = info
			end
		end
		categoryText.Text = (if categoryInfo then categoryInfo.icon .. " " .. categoryInfo.name else item.category)
			.. (if item.slot then " · " .. item.slot else "")
		local lines = { item.description }
		description.Text = table.concat(lines, "\n")
		local owned = p.owned[item.id] ~= nil
		local equipSlot = CosmeticCatalog.equipSlot(item)
		local status = {}
		if item.collection then
			local collection = CollectionConfig.ById[item.collection]
			table.insert(status, "🧩 Part of the " .. (if collection then collection.name else item.collection))
		end
		local api = Widgets.api(actionButton)
		local actionHandler = nil
		if item.category == "Emote" then
			if owned then
				api.SetText("▶ PLAY EMOTE")
				api.SetStyle("Primary")
				api.SetEnabled(true)
				actionHandler = function()
					Emotes.Request(item.id)
					UI.Close()
				end
			end
		elseif owned then
			local equipped = ShopRules.isEquipped(p.equipped, item, equipSlot)
			if equipped then
				api.SetText("✔ EQUIPPED (tap to remove)")
				api.SetStyle("Green")
				api.SetEnabled(true)
				actionHandler = function()
					api.SetEnabled(false)
					local result = Remotes.func("Unequip"):InvokeServer(item.id)
					api.SetEnabled(true)
					if result and result.ok then
						Audio.Play("Equip")
					end
				end
			else
				api.SetText("EQUIP")
				api.SetStyle("Primary")
				api.SetEnabled(true)
				local replaces = ShopRules.wouldReplace(p.equipped, item, equipSlot)
				if replaces then
					local other = CosmeticCatalog.get(replaces)
					table.insert(
						status,
						"⚠ Replaces <b>" .. (if other then other.name else replaces) .. "</b> (same slot)"
					)
				end
				actionHandler = function()
					api.SetEnabled(false)
					local result = Remotes.func("Equip"):InvokeServer(item.id)
					api.SetEnabled(true)
					if result and result.ok then
						Audio.Play("Equip")
						Renderer.ClearPreview()
					end
				end
			end
		end
		if not owned then
			if CosmeticCatalog.isPurchasable(item) then
				local allowed, reason, price = ShopRules.canPurchase(p, item, State.featuredSet, State.discountPercent)
				local text = "BUY  " .. priceText(price or item.price, item.currency)
				api.SetText(text)
				api.SetStyle("Gold")
				api.SetEnabled(allowed)
				if not allowed and reason and string.find(reason, "NotEnough") then
					local balance = if item.currency == "Coins" then p.coins else p.wins
					table.insert(
						status,
						string.format("Need %s more %s", Format.commas((price or 0) - balance), item.currency)
					)
				end
				if State.featuredSet[item.id] then
					table.insert(status, "⭐ Featured today: -" .. State.discountPercent .. "%")
				end
				actionHandler = function()
					api.SetEnabled(false)
					api.SetText("...")
					local result = Remotes.func("Purchase"):InvokeServer(item.id)
					if result and result.ok then
						celebrate(item)
					else
						Audio.Play("UiError")
						if UI.Toast then
							UI.Toast({
								title = "PURCHASE FAILED",
								text = tostring(result and result.reason or "Try again"),
								icon = "⚠️",
								color = C.Red,
							})
						end
					end
					task.delay(0.2, function()
						selectDetail(item)
					end)
				end
			else
				api.SetText("🔒 " .. unlockText(item))
				api.SetStyle("Ghost")
				api.SetEnabled(false)
			end
		end
		statusText.Text = table.concat(status, "\n")
		actionButton:SetAttribute("Handler", nil)
		ShopMenu._handler = actionHandler
		Widgets.api(favDetail).SetText(if p.favorites[item.id] then "♥ FAVOURITE" else "♡ FAVOURITE")
		showPreview(item)
	end

	actionButton.Activated:Connect(function()
		if ShopMenu._handler and actionButton:GetAttribute("Enabled") then
			Audio.Play("UiClick")
			ShopMenu._handler()
		end
	end)

	favDetail.Activated:Connect(function()
		if not selected then
			return
		end
		Remotes.func("ToggleFavorite"):InvokeServer(selected.id, nil)
	end)

	-- Try on: real avatar preview in the world (particles included).
	tryButton.Activated:Connect(function()
		local item = selected
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not item or not character or not root then
			return
		end
		Audio.Play("UiClick")
		if item.category == "Trail" or item.category == "Aura" or item.category == "Accessory" then
			Renderer.Preview(item.category, item)
			UI.Close()
			Camera.FocusSelf(true)
			task.delay(6, function()
				Camera.FocusSelf(false)
				Renderer.ClearPreview()
			end)
		elseif item.category == "JumpEffect" or item.category == "LandingEffect" or item.category == "DeathEffect" then
			Renderer.PlayBurst(item.category, item.id, root.Position, character)
		elseif item.category == "Emote" then
			Emotes.Play(character, item.id, nil)
			UI.Close()
			task.delay(4, function()
				if not character:GetAttribute("Emote") then
					Emotes.Stop(character)
				end
			end)
		elseif item.category == "WinAnimation" then
			UI.Close()
			Emotes.Play(character, item.id, nil)
			local effect = Visuals.WinAnimation[item.id]
			if effect then
				pcall(effect, root.CFrame * CFrame.new(0, -3, 0), character)
			end
			task.delay(4, function()
				if not character:GetAttribute("Emote") then
					Emotes.Stop(character)
				end
			end)
		elseif item.category == "Title" then
			local style, name = TitleStyles.get(item.id)
			if style and UI.Toast then
				UI.Toast({
					title = "NAMEPLATE PREVIEW",
					text = string.upper(name or ""),
					icon = item.icon,
					color = style.colors[1],
				})
			end
		end
	end)

	-- ===== Sets (collections) and presets views
	local function renderSets()
		local p = profile()
		if not p then
			return
		end
		gridLayout.CellSize = UDim2.new(1, -12, 0, 120)
		for i, collection in CollectionConfig.List do
			local members = ProgressLogic.collectionMembers(CosmeticCatalog.Items :: any, collection.id)
			local owned, total = ProgressLogic.collectionProgress(p, members)
			local row = new("Frame", { Name = collection.id, BackgroundColor3 = C.Ink, LayoutOrder = i, Parent = grid })
			Widgets.corner(row, 8)
			Widgets.stroke(row, collection.colors[1], 3)
			Widgets.gradient(row, { collection.colors[1]:Lerp(C.Ink, 0.6), C.Ink }, 0)
			label({
				Text = collection.icon,
				Font = F.Heavy,
				Size = UDim2.fromOffset(70, 70),
				Position = UDim2.fromOffset(10, 12),
				AlignX = Enum.TextXAlignment.Center,
				Parent = row,
			})
			label({
				Text = string.upper(collection.name),
				Font = F.Display,
				Size = UDim2.new(1, -330, 0, 30),
				Position = UDim2.fromOffset(90, 8),
				Stroke = 2,
				Parent = row,
			})
			local icons = {}
			for _, id in members do
				local item = CosmeticCatalog.get(id)
				if item then
					table.insert(icons, (if p.owned[id] then "" else "·") .. item.icon)
				end
			end
			label({
				Text = table.concat(icons, " "),
				Font = F.Heavy,
				Size = UDim2.new(1, -330, 0, 26),
				Position = UDim2.fromOffset(90, 40),
				MaxTextSize = 18,
				Parent = row,
			})
			local _, setBar = Widgets.bar({
				Size = UDim2.new(1, -330, 0, 14),
				Position = UDim2.fromOffset(90, 76),
				Colors = collection.colors,
				Parent = row,
			})
			setBar(owned / math.max(1, total))
			label({
				Text = string.format("%d / %d", owned, total),
				Font = F.Heavy,
				Size = UDim2.fromOffset(80, 20),
				Position = UDim2.new(1, -320, 0, 96),
				Color = C.Muted,
				Parent = row,
			})
			local reward = CosmeticCatalog.get(collection.reward)
			local claimed = p.claimedCollections[collection.id] ~= nil
			local complete = owned >= total
			Widgets.button({
				Name = "Claim",
				Text = if claimed
					then "✔ CLAIMED"
					elseif complete then "CLAIM " .. (if reward then reward.icon else "")
					else "🎁 " .. (if reward then reward.name else "Reward"),
				Style = if complete and not claimed then "Gold" else "Ghost",
				Size = UDim2.fromOffset(220, 56),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				MaxTextSize = 18,
				OnClick = function()
					if complete and not claimed then
						local result = Remotes.func("ClaimCollection"):InvokeServer(collection.id)
						if result and result.ok and reward then
							celebrate(reward)
						end
					elseif reward then
						selectDetail(reward)
					end
				end,
				Parent = row,
			})
		end
	end

	local function renderPresets()
		local p = profile()
		if not p then
			return
		end
		gridLayout.CellSize = UDim2.new(1, -12, 0, 110)
		for slot = 1, EconomyConfig.Presets.Slots do
			local preset = p.presets[slot]
			local row =
				new("Frame", { Name = "Preset" .. slot, BackgroundColor3 = C.Ink, LayoutOrder = slot, Parent = grid })
			Widgets.corner(row, 8)
			Widgets.stroke(row, C.Cyan, 3)
			label({
				Text = if preset and not preset.empty then preset.name else ("Preset " .. slot .. " (empty)"),
				Font = F.Display,
				Size = UDim2.new(1, -380, 0, 32),
				Position = UDim2.fromOffset(16, 10),
				Stroke = 2,
				Parent = row,
			})
			local summary = {}
			if preset and not preset.empty then
				for _, key in
					{ "Trail", "Aura", "JumpEffect", "LandingEffect", "DeathEffect", "WinAnimation", "Title", "Podium" }
				do
					local item = CosmeticCatalog.get(preset.loadout[key] or "")
					if item then
						table.insert(summary, item.icon)
					end
				end
				for _, id in preset.loadout.Accessories or {} do
					local item = CosmeticCatalog.get(id)
					if item then
						table.insert(summary, item.icon)
					end
				end
			end
			label({
				Text = if #summary > 0 then table.concat(summary, " ") else "Save your current outfit here",
				Font = F.Heavy,
				Size = UDim2.new(1, -380, 0, 36),
				Position = UDim2.fromOffset(16, 50),
				Color = C.Muted,
				MaxTextSize = 22,
				Parent = row,
			})
			Widgets.button({
				Name = "Save",
				Text = "💾 SAVE",
				Style = "Primary",
				Size = UDim2.fromOffset(160, 50),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -190, 0.5, 0),
				MaxTextSize = 20,
				OnClick = function()
					Remotes.func("SavePreset"):InvokeServer(slot, "Preset " .. slot)
				end,
				Parent = row,
			})
			local load = Widgets.button({
				Name = "Load",
				Text = "▶ WEAR",
				Style = "Green",
				Size = UDim2.fromOffset(160, 50),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				MaxTextSize = 20,
				OnClick = function()
					local result = Remotes.func("LoadPreset"):InvokeServer(slot)
					if result and result.ok then
						Audio.Play("Equip")
					end
				end,
				Parent = row,
			})
			Widgets.api(load).SetEnabled(preset ~= nil and not preset.empty)
		end
	end

	-- ===== Refresh
	refresh = function()
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for id, button in tabButtons do
			Widgets.api(button).SetStyle(if id == mode then "Accent" else "Ghost")
		end
		for id, button in categoryButtons do
			Widgets.api(button).SetStyle(if id == category then "Primary" else "Ghost")
		end
		local p = profile()
		if p then
			walletText.Text = string.format("🏆 %s   🪙 %s", Format.commas(p.wins), Format.commas(p.coins))
		end
		Widgets.api(rarityButton).SetText("RARITY: " .. string.upper(RARITY_FILTERS[rarityIndex]))
		Widgets.api(sortButton).SetText("SORT: " .. string.upper(SORTS[sortIndex]))
		Widgets.api(favButton).SetText(if onlyFavorites then "♥ FAVOURITES" else "♡ FAVOURITES")
		local listMode = mode == "Sets" or mode == "Presets"
		filters.Visible = not listMode
		categoryColumn.Visible = not listMode
		centre.Position = if listMode then UDim2.fromOffset(14, 14) else UDim2.fromOffset(196, 14)
		centre.Size = if listMode then UDim2.new(1, -28 - 360, 1, -28) else UDim2.new(1, -196 - 360, 1, -28)
		grid.Position = if listMode then UDim2.new() else UDim2.fromOffset(0, 50)
		grid.Size = if listMode then UDim2.fromScale(1, 1) else UDim2.new(1, 0, 1, -50)
		if mode == "Sets" then
			renderSets()
			return
		elseif mode == "Presets" then
			renderPresets()
			return
		end
		gridLayout.CellSize = UDim2.fromOffset(146, 178)
		local items = filteredItems()
		for i, item in items do
			card(item, i)
		end
		if mode == "Featured" then
			local seconds = math.max(0, State.featuredEndsAt - os.clock())
			headerInfo.Text = string.format("New featured items in %dh %02dm", seconds // 3600, (seconds % 3600) // 60)
		elseif mode == "Inventory" and p then
			local completion = ProgressLogic.collectionCompletion(p, CosmeticCatalog.Items :: any)
			headerInfo.Text = string.format("Collection %s complete", Format.percent(completion))
		else
			headerInfo.Text = string.format("%d items", #items)
		end
		if selected then
			selectDetail(selected)
		elseif items[1] then
			selectDetail(items[1])
		end
	end

	State.Changed:Connect(function()
		if root.Visible then
			refresh()
		end
	end)

	local function open(startMode: string, options)
		mode = startMode
		fittingRoom = options ~= nil and options.fittingRoom == true
		root.Visible = true
		scale.Scale = 0.85
		Widgets.tween(scale, Theme.Motion.Pop, { Scale = 1 })
		refresh()
		if fittingRoom then
			Camera.FocusSelf(true)
		end
	end
	local function close()
		root.Visible = false
		if fittingRoom then
			fittingRoom = false
			Camera.FocusSelf(false)
		end
		clearPreview()
		if previewModel then
			previewModel:Destroy()
			previewModel = nil
		end
	end
	dimmer.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			UI.Close()
		end
	end)
	UI.Register("Shop", {
		open = function(options)
			open(if #State.featured > 0 then "Featured" else "Shop", options)
		end,
		close = close,
		first = function()
			return tabButtons.Featured
		end,
	})
	UI.Register("Inventory", {
		open = function(options)
			open("Inventory", options)
		end,
		close = close,
		first = function()
			return tabButtons.Inventory
		end,
	})
end

return ShopMenu
