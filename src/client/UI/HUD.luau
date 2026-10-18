--!nonstrict
-- Always-on HUD. Top-left: Wins, Coins, level and XP. Top-centre: round
-- state, timer, players alive, next event. Top-right: active quest and
-- collection progress. Left: Shop / Inventory / Emotes / Quests / Settings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EconomyConfig = require(Shared.Config.EconomyConfig)
local EventConfig = require(Shared.Config.EventConfig)
local MapConfig = require(Shared.Config.MapConfig)
local QuestConfig = require(Shared.Config.QuestConfig)
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local LevelCurve = require(Shared.Logic.LevelCurve)
local ProgressLogic = require(Shared.Logic.ProgressLogic)
local Format = require(Shared.Util.Format)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local HUD = {}

local STATE_TEXT = {
	Lobby = "WAITING FOR PLAYERS",
	Intermission = "INTERMISSION",
	MapSelect = "MAP SELECTED",
	Preparation = "GET READY",
	Active = "SURVIVE!",
	SuddenDeath = "SUDDEN DEATH",
	Results = "RESULTS",
}

local function currencyChip(parent, order: number, icon: string, color: Color3)
	local chip = new("Frame", {
		Name = "Chip",
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(150, 40),
		LayoutOrder = order,
		Parent = parent,
	})
	Widgets.corner(chip, 6)
	Widgets.stroke(chip, C.Shadow, 3)
	local badge = new("Frame", {
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.fromOffset(-8, -3),
		Rotation = Theme.Slant,
		Parent = chip,
	})
	Widgets.stroke(badge, C.Shadow, 3)
	label({
		Text = icon,
		Font = F.Heavy,
		Size = UDim2.fromScale(0.8, 0.8),
		Position = UDim2.fromScale(0.1, 0.1),
		AlignX = Enum.TextXAlignment.Center,
		Parent = badge,
	})
	local value = label({
		Name = "Value",
		Text = "0",
		Font = F.Display,
		Size = UDim2.new(1, -52, 1, -6),
		Position = UDim2.fromOffset(46, 3),
		Color = color,
		Stroke = 2,
		Parent = chip,
	})
	return chip, value
end

function HUD.build(UI, controllers)
	local layers = UI.Layers()
	local hud = layers.hud
	local State = controllers.ClientState
	local roundState = ReplicatedStorage:WaitForChild("RoundState")

	-- ===== Wallet (top-left)
	local wallet = new("Frame", {
		Name = "Wallet",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 18),
		Size = UDim2.fromOffset(330, 150),
		Parent = hud,
	})
	Widgets.list(wallet, Enum.FillDirection.Vertical, 10)
	local _, winsValue = currencyChip(wallet, 1, "🏆", C.Wins)
	local _, coinsValue = currencyChip(wallet, 2, "🪙", C.Coins)
	local levelRow = new("Frame", {
		Name = "Level",
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(250, 40),
		LayoutOrder = 3,
		Parent = wallet,
	})
	Widgets.corner(levelRow, 6)
	Widgets.stroke(levelRow, C.Shadow, 3)
	local levelBadge = new("Frame", {
		BackgroundColor3 = C.Cyan,
		Size = UDim2.fromOffset(58, 46),
		Position = UDim2.fromOffset(-8, -3),
		Rotation = Theme.Slant,
		Parent = levelRow,
	})
	Widgets.stroke(levelBadge, C.Shadow, 3)
	local levelText = label({
		Text = "Lv 1",
		Font = F.Display,
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 2,
		Parent = levelBadge,
	})
	local _, setXp = Widgets.bar({
		Size = UDim2.new(1, -78, 0, 12),
		Position = UDim2.fromOffset(62, 8),
		Colors = { C.Cyan, C.Purple },
		Parent = levelRow,
	})
	local xpText = label({
		Text = "0 / 100 XP",
		Font = F.Bold,
		Size = UDim2.new(1, -78, 0, 14),
		Position = UDim2.fromOffset(62, 22),
		Color = C.Muted,
		Parent = levelRow,
	})

	local lastWins, lastCoins = -1, -1
	local function pop(target: GuiObject)
		local scale = target:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = target })
		scale.Scale = 1.35
		Widgets.tween(scale, Theme.Motion.Pop, { Scale = 1 })
	end
	local function refreshWallet()
		local profile = State.Get()
		if not profile then
			return
		end
		winsValue.Text = Format.compact(profile.wins)
		coinsValue.Text = Format.compact(profile.coins)
		if lastWins >= 0 and profile.wins ~= lastWins then
			pop(winsValue)
		end
		if lastCoins >= 0 and profile.coins ~= lastCoins then
			pop(coinsValue)
		end
		lastWins, lastCoins = profile.wins, profile.coins
		local level, into, need = LevelCurve.fromTotalXp(profile.xp, EconomyConfig.Level)
		levelText.Text = "Lv " .. level
		setXp(if need > 0 then into / need else 1)
		xpText.Text = if need > 0
			then string.format("%s / %s XP", Format.commas(into), Format.commas(need))
			else "MAX LEVEL"
	end

	-- ===== Round panel (top-centre)
	local roundPanel = new("Frame", {
		Name = "RoundPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(420, 96),
		BackgroundTransparency = 1,
		Parent = hud,
	})
	local banner = new(
		"Frame",
		{ Name = "Banner", BackgroundColor3 = C.Ink, Size = UDim2.new(1, 0, 0, 62), Rotation = 0, Parent = roundPanel }
	)
	Widgets.corner(banner, 6)
	Widgets.stroke(banner, C.Shadow, 3)
	Widgets.gradient(banner, { C.InkLight, C.Ink }, 90)
	local accent = new("Frame", {
		Name = "Accent",
		BackgroundColor3 = C.Pink,
		Size = UDim2.new(0, 120, 1, 8),
		Position = UDim2.fromOffset(-10, -4),
		Rotation = Theme.Slant,
		Parent = banner,
	})
	Widgets.stroke(accent, C.Shadow, 3)
	local timer = label({
		Name = "Timer",
		Text = "--",
		Font = F.Display,
		Size = UDim2.new(1, -16, 1, -12),
		Position = UDim2.fromOffset(8, 6),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 2,
		Parent = accent,
	})
	local stateText = label({
		Name = "State",
		Text = "WAITING",
		Font = F.Display,
		Size = UDim2.new(1, -140, 0, 30),
		Position = UDim2.fromOffset(124, 4),
		Stroke = 2,
		Parent = banner,
	})
	local subText = label({
		Name = "Sub",
		Text = "",
		Font = F.Heavy,
		Size = UDim2.new(1, -140, 0, 20),
		Position = UDim2.fromOffset(124, 36),
		Color = C.Muted,
		Parent = banner,
	})
	local aliveChip = new("Frame", {
		Name = "Alive",
		BackgroundColor3 = C.Green,
		Size = UDim2.fromOffset(110, 30),
		Position = UDim2.new(0, 10, 0, 64),
		Rotation = Theme.Slant,
		Parent = roundPanel,
	})
	Widgets.stroke(aliveChip, C.Shadow, 3)
	local aliveText = label({
		Text = "👤 0",
		Font = F.Display,
		Size = UDim2.new(1, -10, 1, -6),
		Position = UDim2.fromOffset(5, 3),
		AlignX = Enum.TextXAlignment.Center,
		Color = C.Ink,
		Parent = aliveChip,
	})
	local nextChip = new("Frame", {
		Name = "NextEvent",
		BackgroundColor3 = C.Yellow,
		Size = UDim2.fromOffset(270, 30),
		Position = UDim2.new(0, 132, 0, 64),
		Rotation = Theme.Slant,
		Visible = false,
		Parent = roundPanel,
	})
	Widgets.stroke(nextChip, C.Shadow, 3)
	local nextText = label({
		Text = "",
		Font = F.Heavy,
		Size = UDim2.new(1, -12, 1, -6),
		Position = UDim2.fromOffset(6, 3),
		AlignX = Enum.TextXAlignment.Center,
		Color = C.Ink,
		Parent = nextChip,
	})

	-- ===== Quest + collection (top-right)
	local questPanel = new("TextButton", {
		Name = "QuestTracker",
		AutoButtonColor = false,
		Text = "",
		Selectable = true,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 18),
		Size = UDim2.fromOffset(300, 72),
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.1,
		Parent = hud,
	})
	Widgets.corner(questPanel, 6)
	Widgets.stroke(questPanel, C.Shadow, 3)
	local questTag = new("Frame", {
		BackgroundColor3 = C.Purple,
		Size = UDim2.fromOffset(92, 26),
		Position = UDim2.fromOffset(-8, -10),
		Rotation = Theme.Slant,
		Parent = questPanel,
	})
	Widgets.stroke(questTag, C.Shadow, 2)
	label({
		Text = "QUEST",
		Font = F.Display,
		Size = UDim2.new(1, -8, 1, -4),
		Position = UDim2.fromOffset(4, 2),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 1.5,
		Parent = questTag,
	})
	local questText = label({
		Text = "Loading quests...",
		Font = F.Heavy,
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(10, 18),
		MaxTextSize = 18,
		Parent = questPanel,
	})
	local _, setQuest = Widgets.bar({
		Size = UDim2.new(1, -20, 0, 12),
		Position = UDim2.fromOffset(10, 48),
		Colors = { C.Purple, C.Pink },
		Parent = questPanel,
	})
	questPanel.Activated:Connect(function()
		UI.Open("Quests")
	end)
	local collectionButton = Widgets.button({
		Name = "CollectionButton",
		Style = "Accent",
		Text = "COLLECTION 0%",
		Size = UDim2.fromOffset(220, 40),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 100),
		MaxTextSize = 20,
		OnClick = function()
			UI.Open("Inventory")
		end,
		Parent = hud,
	})

	local function refreshQuest()
		local profile = State.Get()
		if not profile then
			return
		end
		local best, bestFraction = nil, -1
		for _, quest in profile.quests.list do
			local template = QuestConfig.ById[quest.id]
			if template and not quest.claimed then
				local fraction = quest.progress / template.target
				if fraction >= 1 then
					best, bestFraction = quest, 2
					break
				elseif fraction > bestFraction then
					best, bestFraction = quest, fraction
				end
			end
		end
		if best then
			local template = QuestConfig.ById[best.id]
			if bestFraction >= 2 then
				questText.Text = "✅ Claim: " .. template.description
				setQuest(1)
			else
				questText.Text = string.format("%s (%d/%d)", template.description, best.progress, template.target)
				setQuest(best.progress / template.target)
			end
		else
			questText.Text = "All daily quests done! 🎉"
			setQuest(1)
		end
		local completion = ProgressLogic.collectionCompletion(profile, CosmeticCatalog.Items :: any)
		Widgets.api(collectionButton).SetText("COLLECTION " .. Format.percent(completion))
	end

	-- ===== Side menu (left-centre)
	local side = new("Frame", {
		Name = "SideMenu",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 22, 0.5, 20),
		Size = UDim2.fromOffset(84, 420),
		Parent = hud,
	})
	Widgets.list(side, Enum.FillDirection.Vertical, 10)
	local buttons = {
		{ "Shop", "🛒", "SHOP", "Accent" },
		{ "Inventory", "🎒", "ITEMS", "Primary" },
		{ "Emotes", "🕺", "EMOTES", "Ghost" },
		{ "Quests", "📜", "QUESTS", "Ghost" },
		{ "Settings", "⚙️", "SETTINGS", "Ghost" },
	}
	local questBadge: GuiObject? = nil
	for i, spec in buttons do
		local b = Widgets.iconButton({
			Name = spec[1],
			Icon = spec[2],
			Caption = spec[3],
			Style = spec[4],
			LayoutOrder = i,
			Badge = spec[1] == "Quests",
			OnClick = function()
				UI.Toggle(spec[1])
			end,
			Parent = side,
		})
		if spec[1] == "Quests" then
			questBadge = b:FindFirstChild("Badge")
		end
	end
	local function refreshBadge()
		local profile = State.Get()
		if not profile or not questBadge then
			return
		end
		local claimable = false
		for _, quest in profile.quests.list do
			local template = QuestConfig.ById[quest.id]
			if template and not quest.claimed and quest.progress >= template.target then
				claimable = true
			end
		end
		questBadge.Visible = claimable
	end

	State.Changed:Connect(function()
		refreshWallet()
		refreshQuest()
		refreshBadge()
	end)
	refreshWallet()
	refreshQuest()

	-- Hide side menu while a full menu is open (avoids overlap on phones).
	UI.MenuChanged:Connect(function(name)
		side.Visible = name == nil
		questPanel.Visible = name == nil
		collectionButton.Visible = name == nil
	end)

	-- Round panel refresh (every frame for smooth timers).
	RunService.RenderStepped:Connect(function()
		local state = roundState:GetAttribute("State") or "Lobby"
		local ends = roundState:GetAttribute("PhaseEndsAt")
		local now = workspace:GetServerTimeNow()
		local remaining = if ends then math.max(0, ends - now) else nil
		timer.Text = if remaining then Format.clock(remaining) else "--"
		stateText.Text = STATE_TEXT[state] or state
		if
			roundState:GetAttribute("Training")
			and (state == "Active" or state == "Preparation" or state == "SuddenDeath")
		then
			stateText.Text = "TRAINING"
		end
		accent.BackgroundColor3 = if state == "SuddenDeath" then C.Red elseif state == "Active" then C.Pink else C.Purple
		local mapDef = MapConfig.ById[roundState:GetAttribute("MapId") or ""]
		if state == "Intermission" then
			subText.Text = "Vote for the next map at the portal (or press 🗳️)"
		elseif mapDef and state ~= "Lobby" then
			subText.Text = mapDef.icon .. " " .. mapDef.name
		else
			subText.Text = "Invite friends — 2+ players for ranked Wins"
		end
		local alive = roundState:GetAttribute("Alive") or 0
		local total = roundState:GetAttribute("Participants") or 0
		aliveChip.Visible = state == "Active" or state == "SuddenDeath" or state == "Preparation"
		aliveText.Text = string.format("👤 %d/%d", alive, total)
		local nextAt = roundState:GetAttribute("NextEventAt")
		local activeEvents = roundState:GetAttribute("ActiveEvents") or ""
		if (state == "Active") and (nextAt or activeEvents ~= "") then
			nextChip.Visible = true
			if activeEvents ~= "" then
				local names = {}
				for _, id in string.split(activeEvents, ",") do
					local def = EventConfig.ById[id]
					if def then
						table.insert(names, def.icon .. " " .. string.upper(def.name))
					end
				end
				nextText.Text = table.concat(names, "  ")
			else
				nextText.Text = string.format("NEXT EVENT IN %ds", math.max(0, math.ceil(nextAt - now)))
			end
		elseif state == "SuddenDeath" then
			nextChip.Visible = true
			nextText.Text = "🔥 LAVA RISING FAST 🔥"
		else
			nextChip.Visible = false
		end
	end)
end

return HUD
