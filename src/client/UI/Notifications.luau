--!nonstrict
-- Toast notifications (unlocks, achievements, quests, level-ups) that stack
-- on the right side, styled by rarity, with sound and a pop animation.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local RarityConfig = require(Shared.Config.RarityConfig)
local AchievementConfig = require(Shared.Config.AchievementConfig)
local QuestConfig = require(Shared.Config.QuestConfig)
local CollectionConfig = require(Shared.Config.CollectionConfig)
local Remotes = require(Shared.Net.Remotes)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local Notifications = {}

function Notifications.build(UI, controllers)
	local overlay = UI.Layers().overlay
	local Audio = controllers.AudioController
	local stack = new("Frame", {
		Name = "Toasts",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 160),
		Size = UDim2.fromOffset(340, 420),
		Parent = overlay,
	})
	Widgets.list(stack, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Right)
	local order = 0

	local function toast(props: {
		title: string,
		text: string,
		icon: string?,
		color: Color3?,
		sound: string?,
		duration: number?,
	})
		order += 1
		local holder = new("Frame", {
			Name = "Toast",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(330, 72),
			LayoutOrder = order,
			Parent = stack,
		})
		local card = new("Frame", {
			BackgroundColor3 = C.Ink,
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(360, 0),
			Parent = holder,
		})
		Widgets.corner(card, 6)
		Widgets.stroke(card, props.color or C.Cyan, 3)
		local tag = new("Frame", {
			BackgroundColor3 = props.color or C.Cyan,
			Size = UDim2.fromOffset(64, 80),
			Position = UDim2.fromOffset(-10, -4),
			Rotation = Theme.Slant,
			Parent = card,
		})
		Widgets.stroke(tag, C.Shadow, 3)
		label({
			Text = props.icon or "★",
			Font = F.Heavy,
			Size = UDim2.fromScale(0.8, 0.6),
			Position = UDim2.fromScale(0.1, 0.2),
			AlignX = Enum.TextXAlignment.Center,
			Parent = tag,
		})
		label({
			Text = props.title,
			Font = F.Display,
			Size = UDim2.new(1, -76, 0, 28),
			Position = UDim2.fromOffset(66, 6),
			Color = props.color or C.Cyan,
			Stroke = 2,
			Parent = card,
		})
		label({
			Text = props.text,
			Font = F.Heavy,
			Size = UDim2.new(1, -76, 0, 26),
			Position = UDim2.fromOffset(66, 38),
			MaxTextSize = 18,
			Parent = card,
		})
		Widgets.tween(card, Theme.Motion.Slide, { Position = UDim2.fromOffset(0, 0) })
		if props.sound and Audio then
			Audio.Play(props.sound)
		end
		task.delay(props.duration or 4, function()
			if card.Parent then
				Widgets.tween(card, Theme.Motion.Slide, { Position = UDim2.fromOffset(360, 0) })
				task.wait(0.4)
				holder:Destroy()
			end
		end)
	end
	UI.Toast = toast

	Remotes.event("Notify").OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if payload.kind == "Unlock" then
			local item = CosmeticCatalog.get(payload.itemId or "")
			if item then
				local rarity = RarityConfig.get(item.rarity)
				toast({
					title = "UNLOCKED!",
					text = item.name .. " · " .. rarity.displayName,
					icon = item.icon,
					color = rarity.color,
					sound = rarity.purchaseSound,
					duration = 5,
				})
			end
		elseif payload.kind == "Achievement" then
			local achievement = AchievementConfig.ById[payload.achievementId or ""]
			if achievement then
				toast({
					title = "ACHIEVEMENT",
					text = achievement.name,
					icon = achievement.icon,
					color = C.Yellow,
					sound = "Achievement",
					duration = 5,
				})
			end
		elseif payload.kind == "QuestComplete" then
			local quest = QuestConfig.ById[payload.questId or ""]
			if quest then
				toast({
					title = "QUEST COMPLETE",
					text = quest.description .. " — claim it!",
					icon = "📜",
					color = C.Purple,
					sound = "Achievement",
				})
			end
		elseif payload.kind == "LevelUp" then
			toast({
				title = "LEVEL UP!",
				text = "You reached level " .. tostring(payload.level),
				icon = "⬆️",
				color = C.Cyan,
				sound = "Achievement",
				duration = 5,
			})
		elseif payload.kind == "CollectionReady" then
			local collection = CollectionConfig.ById[payload.collectionId or ""]
			if collection then
				toast({
					title = "COLLECTION COMPLETE",
					text = collection.name .. " — claim your reward!",
					icon = collection.icon,
					color = C.Pink,
					sound = "Achievement",
					duration = 6,
				})
			end
		end
	end)
end

return Notifications
