--!nonstrict
-- Emote wheel: a radial menu of owned emotes (favourites first). Works with
-- mouse, touch and gamepad (Selectable buttons, X to open, B to close).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local RarityConfig = require(Shared.Config.RarityConfig)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local EmoteMenu = {}

function EmoteMenu.build(UI, controllers)
	local State = controllers.ClientState
	local Emotes = controllers.EmoteController
	local layer = UI.Layers().menu

	local root = new("Frame", {
		Name = "EmoteMenu",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = layer,
	})
	local dimmer = Widgets.dimmer(root, 1)
	dimmer.BackgroundTransparency = 0.6
	local wheel = new("Frame", {
		Name = "Wheel",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromOffset(560, 560),
		ZIndex = 2,
		Active = true,
		Parent = root,
	})
	local scale = new("UIScale", { Parent = wheel })
	local hub = new("Frame", {
		BackgroundColor3 = C.Ink,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(170, 170),
		Rotation = 45,
		ZIndex = 2,
		Parent = wheel,
	})
	Widgets.stroke(hub, C.Pink, 4)
	local hubText = label({
		Text = "EMOTES",
		Font = F.Display,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(150, 40),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 2,
		ZIndex = 4,
		Parent = wheel,
	})
	local stopButton = Widgets.button({
		Name = "Stop",
		Text = "■ STOP",
		Style = "Danger",
		Size = UDim2.fromOffset(120, 40),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 26),
		ZIndex = 5,
		MaxTextSize = 18,
		OnClick = function()
			Emotes.StopLocal()
			UI.Close("Emotes")
		end,
		Parent = wheel,
	})
	local buttons = {}

	local function rebuild()
		for _, b in buttons do
			b:Destroy()
		end
		buttons = {}
		local profile = State.Get()
		if not profile then
			return
		end
		local owned = {}
		for _, item in CosmeticCatalog.byCategory("Emote") do
			if profile.owned[item.id] then
				table.insert(owned, item)
			end
		end
		table.sort(owned, function(a, b)
			local fa, fb = profile.favorites[a.id] ~= nil, profile.favorites[b.id] ~= nil
			if fa ~= fb then
				return fa
			end
			return a.order < b.order
		end)
		local count = math.max(1, #owned)
		for i, item in owned do
			local ring = if i <= 10 then 0 else 1
			local indexInRing = if ring == 0 then i - 1 else i - 11
			local perRing = if ring == 0 then math.min(10, count) else math.max(1, count - 10)
			local angle = indexInRing / perRing * math.pi * 2 - math.pi / 2
			local radius = 165 + ring * 95
			local rarity = RarityConfig.get(item.rarity)
			local b = Widgets.button({
				Name = item.id,
				Style = "Ghost",
				Size = UDim2.fromOffset(92, 92),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, math.cos(angle) * radius, 0.5, math.sin(angle) * radius),
				ZIndex = 3,
				OnClick = function()
					Emotes.Request(item.id)
					UI.Close("Emotes")
				end,
				Parent = wheel,
			})
			local text = b:FindFirstChild("Text") :: TextLabel
			text.Text = item.icon
			text.Size = UDim2.new(1, -16, 0.6, 0)
			label({
				Text = item.name,
				Font = F.Heavy,
				Size = UDim2.new(1, -8, 0.3, 0),
				Position = UDim2.new(0, 4, 0.66, 0),
				AlignX = Enum.TextXAlignment.Center,
				Stroke = 1.5,
				MaxTextSize = 13,
				ZIndex = 5,
				Parent = b,
			})
			Widgets.stroke(b, rarity.color, 3)
			b.SelectionGained:Connect(function()
				hubText.Text = string.upper(item.name)
			end)
			b.MouseEnter:Connect(function()
				hubText.Text = string.upper(item.name)
			end)
			table.insert(buttons, b)
		end
		if #owned == 0 then
			hubText.Text = "NO EMOTES"
		end
	end

	dimmer.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			UI.Close("Emotes")
		end
	end)
	UI.Register("Emotes", {
		open = function()
			rebuild()
			hubText.Text = "EMOTES"
			root.Visible = true
			scale.Scale = 0.6
			Widgets.tween(scale, Theme.Motion.Pop, { Scale = 1 })
		end,
		close = function()
			root.Visible = false
		end,
		first = function()
			return buttons[1] or stopButton
		end,
	})
end

return EmoteMenu
