--!nonstrict
-- Settings: effects quality, music/SFX volume, showing other players'
-- effects and reduced flashing/motion. Saved on the server profile.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local SettingsMenu = {}

local QUALITIES = { "Auto", "Low", "Medium", "High" }
local STEPS = { 0, 0.25, 0.5, 0.75, 1 }

function SettingsMenu.build(UI, controllers)
	local State = controllers.ClientState
	local Quality = controllers.QualityController
	local Audio = controllers.AudioController
	local Renderer = controllers.CosmeticRenderer
	local Camera = controllers.CameraController
	local layer = UI.Layers().menu
	local root = new("Frame", {
		Name = "SettingsMenu",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = layer,
	})
	local dimmer = Widgets.dimmer(root, 1)
	local panel, content = Widgets.panel({
		Name = "Window",
		Title = "SETTINGS",
		Accent = C.Cyan,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(640, 470),
		ZIndex = 2,
		Parent = root,
	})
	local scale = new("UIScale", { Parent = panel })
	Widgets.button({
		Name = "Close",
		Text = "✕",
		Style = "Danger",
		Size = UDim2.fromOffset(48, 48),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 14, 0, -24),
		ZIndex = 6,
		OnClick = function()
			UI.Close("Settings")
		end,
		Parent = panel,
	})
	local list = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(24, 20),
		Size = UDim2.new(1, -48, 1, -40),
		Parent = content,
	})
	Widgets.list(list, Enum.FillDirection.Vertical, 14)

	local settings = { quality = "Auto", music = 0.5, sfx = 0.8, showOthersEffects = true, reduceFlashing = false }
	local buttons: { [string]: any } = {}

	local function push()
		Remotes.event("SettingsUpdate"):FireServer(settings)
	end

	local function apply()
		Quality.Set(settings.quality)
		Audio.SetVolumes(settings.sfx, settings.music)
		Renderer.showOthers = settings.showOthersEffects
		Camera.reduceMotion = settings.reduceFlashing
		if UI.SetReduceFlashing then
			UI.SetReduceFlashing(settings.reduceFlashing)
		end
	end

	local function rowWith(order: number, title: string, makeButton)
		local row = new(
			"Frame",
			{ BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 56), LayoutOrder = order, Parent = list }
		)
		label({ Text = title, Font = F.Display, Size = UDim2.new(0.5, 0, 1, 0), Stroke = 2, Parent = row })
		local button = makeButton(row)
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, 0, 0.5, 0)
		return button
	end

	local function refreshButtons()
		Widgets.api(buttons.quality).SetText(
			string.upper(settings.quality)
				.. (if settings.quality == "Auto" then " (" .. string.upper(Quality.level) .. ")" else "")
		)
		Widgets.api(buttons.music).SetText(math.floor(settings.music * 100) .. "%")
		Widgets.api(buttons.sfx).SetText(math.floor(settings.sfx * 100) .. "%")
		Widgets.api(buttons.others).SetText(if settings.showOthersEffects then "SHOWN" else "HIDDEN")
		Widgets.api(buttons.others).SetStyle(if settings.showOthersEffects then "Green" else "Ghost")
		Widgets.api(buttons.flash).SetText(if settings.reduceFlashing then "ON" else "OFF")
		Widgets.api(buttons.flash).SetStyle(if settings.reduceFlashing then "Green" else "Ghost")
	end

	local function cycle(list_: { any }, current: any)
		local index = table.find(list_, current) or 0
		return list_[index % #list_ + 1]
	end

	buttons.quality = rowWith(1, "Effects quality", function(row)
		return Widgets.button({
			Style = "Primary",
			Size = UDim2.fromOffset(240, 48),
			MaxTextSize = 20,
			OnClick = function()
				settings.quality = cycle(QUALITIES, settings.quality)
				apply()
				refreshButtons()
				push()
			end,
			Parent = row,
		})
	end)
	buttons.music = rowWith(2, "Music volume", function(row)
		return Widgets.button({
			Style = "Primary",
			Size = UDim2.fromOffset(240, 48),
			OnClick = function()
				settings.music = cycle(STEPS, settings.music)
				apply()
				refreshButtons()
				push()
			end,
			Parent = row,
		})
	end)
	buttons.sfx = rowWith(3, "Sound effects", function(row)
		return Widgets.button({
			Style = "Primary",
			Size = UDim2.fromOffset(240, 48),
			OnClick = function()
				settings.sfx = cycle(STEPS, settings.sfx)
				apply()
				refreshButtons()
				push()
				Audio.Play("UiClick")
			end,
			Parent = row,
		})
	end)
	buttons.others = rowWith(4, "Other players' effects", function(row)
		return Widgets.button({
			Style = "Green",
			Size = UDim2.fromOffset(240, 48),
			OnClick = function()
				settings.showOthersEffects = not settings.showOthersEffects
				apply()
				refreshButtons()
				push()
			end,
			Parent = row,
		})
	end)
	buttons.flash = rowWith(5, "Reduce flashing & shake", function(row)
		return Widgets.button({
			Style = "Ghost",
			Size = UDim2.fromOffset(240, 48),
			OnClick = function()
				settings.reduceFlashing = not settings.reduceFlashing
				apply()
				refreshButtons()
				push()
			end,
			Parent = row,
		})
	end)
	label({
		Text = "Shortcuts: B Shop · I Items · G Emotes · J Quests  |  Gamepad: Y Shop · X Emotes · D-Pad Quests/Items · B Close",
		Font = F.Bold,
		Size = UDim2.new(1, 0, 0, 40),
		Color = C.Muted,
		LayoutOrder = 6,
		MaxTextSize = 15,
		Parent = list,
	})

	local loaded = false
	State.Changed:Connect(function(keys)
		local profile = State.Get()
		if profile and profile.settings and (not loaded or keys == nil) then
			loaded = true
			for key, value in profile.settings do
				settings[key] = value
			end
			apply()
			refreshButtons()
		end
	end)
	refreshButtons()

	dimmer.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			UI.Close("Settings")
		end
	end)
	UI.Register("Settings", {
		open = function()
			root.Visible = true
			scale.Scale = 0.85
			Widgets.tween(scale, Theme.Motion.Pop, { Scale = 1 })
			refreshButtons()
		end,
		close = function()
			root.Visible = false
		end,
		first = function()
			return buttons.quality
		end,
	})
end

return SettingsMenu
