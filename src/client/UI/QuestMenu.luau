--!nonstrict
-- Daily quests (claimable), achievements with progress, and the level
-- reward track. Everything shown here is read from the synced profile.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local QuestConfig = require(Shared.Config.QuestConfig)
local AchievementConfig = require(Shared.Config.AchievementConfig)
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local ProgressLogic = require(Shared.Logic.ProgressLogic)
local LevelCurve = require(Shared.Logic.LevelCurve)
local Format = require(Shared.Util.Format)
local Remotes = require(Shared.Net.Remotes)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local QuestMenu = {}

function QuestMenu.build(UI, controllers)
	local State = controllers.ClientState
	local Audio = controllers.AudioController
	local layer = UI.Layers().menu
	local root = new("Frame", {
		Name = "QuestMenu",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = layer,
	})
	local dimmer = Widgets.dimmer(root, 1)
	local panel, content = Widgets.panel({
		Name = "Window",
		Title = "QUESTS",
		Accent = C.Purple,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(900, 580),
		ZIndex = 2,
		Parent = root,
	})
	local scale = new("UIScale", { Parent = panel })
	local tab = "Daily"
	local tabsFrame = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(280, -26),
		Size = UDim2.fromOffset(520, 44),
		ZIndex = 5,
		Parent = panel,
	})
	Widgets.list(tabsFrame, Enum.FillDirection.Horizontal, 8)
	local tabButtons = {}
	local refresh: () -> () = function() end
	for i, spec in { { "Daily", "📜 DAILY" }, { "Achievements", "🏅 ACHIEVEMENTS" }, { "Levels", "⬆️ LEVELS" } } do
		tabButtons[spec[1]] = Widgets.button({
			Name = spec[1],
			Text = spec[2],
			Style = "Ghost",
			Size = UDim2.fromOffset(165, 42),
			LayoutOrder = i,
			MaxTextSize = 18,
			ZIndex = 5,
			OnClick = function()
				tab = spec[1]
				refresh()
			end,
			Parent = tabsFrame,
		})
	end
	Widgets.button({
		Name = "Close",
		Text = "✕",
		Style = "Danger",
		Size = UDim2.fromOffset(48, 48),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 14, 0, -24),
		ZIndex = 6,
		OnClick = function()
			UI.Close("Quests")
		end,
		Parent = panel,
	})
	local list =
		Widgets.scroll({ Position = UDim2.fromOffset(16, 16), Size = UDim2.new(1, -32, 1, -32), Parent = content })
	Widgets.list(list, Enum.FillDirection.Vertical, 10)
	Widgets.padding(list, 4)

	local function row(order: number, height: number, accent: Color3)
		local frame = new(
			"Frame",
			{ BackgroundColor3 = C.Ink, Size = UDim2.new(1, -12, 0, height), LayoutOrder = order, Parent = list }
		)
		Widgets.corner(frame, 8)
		Widgets.stroke(frame, accent, 3)
		return frame
	end

	local function renderDaily(profile)
		local now = os.time()
		local secondsLeft = 86400 - (now % 86400)
		label({
			Text = string.format(
				"New quests in %dh %02dm  ·  Completed overall: %d",
				secondsLeft // 3600,
				(secondsLeft % 3600) // 60,
				profile.quests.totalCompleted
			),
			Font = F.Heavy,
			Size = UDim2.new(1, -12, 0, 26),
			Color = C.Muted,
			LayoutOrder = 0,
			Parent = list,
		})
		for i, quest in profile.quests.list do
			local template = QuestConfig.ById[quest.id]
			if template then
				local tierColor = if template.tier == "Easy"
					then C.Green
					elseif template.tier == "Medium" then C.Cyan
					else C.Pink
				local frame = row(i, 96, tierColor)
				local tag = new("Frame", {
					BackgroundColor3 = tierColor,
					Size = UDim2.fromOffset(110, 30),
					Position = UDim2.fromOffset(-8, -10),
					Rotation = Theme.Slant,
					Parent = frame,
				})
				Widgets.stroke(tag, C.Shadow, 2)
				label({
					Text = string.upper(template.tier),
					Font = F.Display,
					Size = UDim2.new(1, -8, 1, -4),
					Position = UDim2.fromOffset(4, 2),
					AlignX = Enum.TextXAlignment.Center,
					Color = C.Ink,
					Parent = tag,
				})
				label({
					Text = template.description,
					Font = F.Display,
					Size = UDim2.new(1, -300, 0, 32),
					Position = UDim2.fromOffset(16, 22),
					Stroke = 2,
					Parent = frame,
				})
				local _, setBar = Widgets.bar({
					Size = UDim2.new(1, -300, 0, 14),
					Position = UDim2.fromOffset(16, 62),
					Colors = { tierColor, C.Purple },
					Parent = frame,
				})
				setBar(quest.progress / template.target)
				label({
					Text = string.format("%s / %s", Format.commas(quest.progress), Format.commas(template.target)),
					Font = F.Heavy,
					Size = UDim2.fromOffset(120, 18),
					Position = UDim2.new(1, -280, 0, 60),
					Color = C.Muted,
					Parent = frame,
				})
				local done = quest.progress >= template.target
				local button = Widgets.button({
					Name = "Claim",
					Text = if quest.claimed
						then "✔ CLAIMED"
						elseif done then string.format("CLAIM 🪙%d", template.coins)
						else string.format("🪙 %d  ·  ✨ %d XP", template.coins, template.xp),
					Style = if done and not quest.claimed then "Gold" else "Ghost",
					Size = UDim2.fromOffset(240, 54),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0),
					MaxTextSize = 18,
					OnClick = function()
						if done and not quest.claimed then
							local result = Remotes.func("ClaimQuest"):InvokeServer(quest.id)
							if result and result.ok then
								Audio.Play("Coin")
								if UI.Toast then
									UI.Toast({
										title = "QUEST CLAIMED",
										text = string.format("+%d Coins  +%d XP", result.coins, result.xp),
										icon = "🪙",
										color = C.Coins,
									})
								end
							end
						end
					end,
					Parent = frame,
				})
				Widgets.api(button).SetEnabled(done and not quest.claimed or quest.claimed)
			end
		end
		label({
			Text = string.format(
				"Finish all three for a bonus of 🪙 %d + %d XP",
				QuestConfig.AllCompleteBonus.coins,
				QuestConfig.AllCompleteBonus.xp
			),
			Font = F.Heavy,
			Size = UDim2.new(1, -12, 0, 26),
			Color = C.Yellow,
			LayoutOrder = 99,
			Parent = list,
		})
	end

	local function renderAchievements(profile)
		for i, achievement in AchievementConfig.List do
			local unlocked = profile.achievements[achievement.id] ~= nil
			local value = ProgressLogic.readStat(profile, achievement.stat)
			local frame = row(i, 78, if unlocked then C.Yellow else C.InkLight)
			label({
				Text = achievement.icon,
				Font = F.Heavy,
				Size = UDim2.fromOffset(56, 56),
				Position = UDim2.fromOffset(10, 11),
				AlignX = Enum.TextXAlignment.Center,
				Parent = frame,
			})
			label({
				Text = achievement.name,
				Font = F.Display,
				Size = UDim2.new(1, -380, 0, 28),
				Position = UDim2.fromOffset(76, 8),
				Color = if unlocked then C.Yellow else C.Paper,
				Stroke = 2,
				Parent = frame,
			})
			label({
				Text = achievement.description,
				Font = F.Bold,
				Size = UDim2.new(1, -380, 0, 20),
				Position = UDim2.fromOffset(76, 40),
				Color = C.Muted,
				MaxTextSize = 16,
				Parent = frame,
			})
			local rewards = {}
			for _, id in achievement.rewards do
				local item = CosmeticCatalog.get(id)
				if item then
					table.insert(rewards, item.icon .. " " .. item.name)
				end
			end
			if achievement.coins then
				table.insert(rewards, "🪙 " .. Format.commas(achievement.coins))
			end
			label({
				Text = table.concat(rewards, "  ·  "),
				Font = F.Heavy,
				Size = UDim2.fromOffset(280, 24),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 8),
				AlignX = Enum.TextXAlignment.Right,
				MaxTextSize = 15,
				Parent = frame,
			})
			if unlocked then
				label({
					Text = "✔ UNLOCKED",
					Font = F.Display,
					Size = UDim2.fromOffset(200, 26),
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -14, 0, 40),
					AlignX = Enum.TextXAlignment.Right,
					Color = C.Green,
					Stroke = 1.5,
					Parent = frame,
				})
			else
				local _, setBar = Widgets.bar({
					Size = UDim2.fromOffset(200, 12),
					Position = UDim2.new(1, -214, 0, 48),
					Colors = { C.Yellow, C.Orange },
					Parent = frame,
				})
				setBar(value / achievement.target)
			end
		end
	end

	local function renderLevels(profile)
		local level, into, need = LevelCurve.fromTotalXp(profile.xp, EconomyConfig.Level)
		label({
			Text = string.format(
				"Level %d  ·  %s / %s XP to next level. XP comes from playing, surviving and placing.",
				level,
				Format.commas(into),
				Format.commas(need)
			),
			Font = F.Heavy,
			Size = UDim2.new(1, -12, 0, 26),
			Color = C.Muted,
			LayoutOrder = 0,
			Parent = list,
		})
		local rewards = {}
		for _, item in CosmeticCatalog.Items do
			if item.unlock.kind == "Level" then
				table.insert(rewards, item)
			end
		end
		table.sort(rewards, function(a, b)
			return a.unlock.level < b.unlock.level
		end)
		for i, item in rewards do
			local reached = level >= item.unlock.level
			local frame = row(i, 70, if reached then C.Cyan else C.InkLight)
			label({
				Text = "LV " .. item.unlock.level,
				Font = F.Display,
				Size = UDim2.fromOffset(90, 40),
				Position = UDim2.fromOffset(12, 15),
				Color = if reached then C.Cyan else C.Muted,
				Stroke = 2,
				Parent = frame,
			})
			label({
				Text = item.icon .. "  " .. item.name,
				Font = F.Display,
				Size = UDim2.new(1, -330, 0, 32),
				Position = UDim2.fromOffset(110, 8),
				Stroke = 2,
				Parent = frame,
			})
			label({
				Text = item.description,
				Font = F.Bold,
				Size = UDim2.new(1, -330, 0, 20),
				Position = UDim2.fromOffset(110, 42),
				Color = C.Muted,
				MaxTextSize = 15,
				Parent = frame,
			})
			label({
				Text = if profile.owned[item.id] then "✔ OWNED" elseif reached then "UNLOCKING..." else "🔒",
				Font = F.Display,
				Size = UDim2.fromOffset(180, 30),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				AlignX = Enum.TextXAlignment.Right,
				Color = if profile.owned[item.id] then C.Green else C.Muted,
				Parent = frame,
			})
		end
	end

	refresh = function()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for id, button in tabButtons do
			Widgets.api(button).SetStyle(if id == tab then "Accent" else "Ghost")
		end
		local profile = State.Get()
		if not profile then
			return
		end
		if tab == "Daily" then
			renderDaily(profile)
		elseif tab == "Achievements" then
			renderAchievements(profile)
		else
			renderLevels(profile)
		end
	end

	State.Changed:Connect(function()
		if root.Visible then
			refresh()
		end
	end)
	dimmer.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			UI.Close("Quests")
		end
	end)
	UI.Register("Quests", {
		open = function()
			root.Visible = true
			scale.Scale = 0.85
			Widgets.tween(scale, Theme.Motion.Pop, { Scale = 1 })
			refresh()
		end,
		close = function()
			root.Visible = false
		end,
		first = function()
			return tabButtons.Daily
		end,
	})
end

return QuestMenu
