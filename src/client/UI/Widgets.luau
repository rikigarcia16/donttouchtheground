--!nonstrict
-- UI building blocks. Every interactive widget is a real, Selectable button
-- with hover/press feedback, a click sound and gamepad support.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Theme)
local C = Theme.Colors
local F = Theme.Fonts

local Widgets = {}
Widgets.Audio = nil :: any -- injected by UIController

local function tween(instance: Instance, info: TweenInfo, goal)
	local t = TweenService:Create(instance, info, goal)
	t:Play()
	return t
end
Widgets.tween = tween

function Widgets.new(className: string, props: { [string]: any }?, children: { Instance }?): Instance
	local instance = Instance.new(className :: any)
	for key, value in (props or {}) :: { [string]: any } do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	for _, child in (children or {}) :: { Instance } do
		child.Parent = instance
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end
local new = Widgets.new

function Widgets.corner(parent: Instance, radius: number?)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

function Widgets.stroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?)
	return new("UIStroke", {
		Color = color or C.Shadow,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Widgets.textStroke(parent: Instance, color: Color3?, thickness: number?)
	return new("UIStroke", {
		Color = color or C.Shadow,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = parent,
	})
end

function Widgets.gradient(parent: Instance, colors: { Color3 }, rotation: number?)
	local keypoints = {}
	for i, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new(if #colors == 1 then 0 else (i - 1) / (#colors - 1), color))
	end
	if #keypoints == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, colors[1]))
	end
	return new("UIGradient", { Color = ColorSequence.new(keypoints), Rotation = rotation or 90, Parent = parent })
end

function Widgets.padding(parent: Instance, px: number)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

function Widgets.list(
	parent: Instance,
	direction: Enum.FillDirection?,
	padding: number?,
	align: Enum.HorizontalAlignment?,
	valign: Enum.VerticalAlignment?
)
	return new("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = valign or Enum.VerticalAlignment.Top,
		Parent = parent,
	})
end

function Widgets.label(props: { [string]: any }): TextLabel
	local label = new("TextLabel", {
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, 24),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Font = props.Font or F.Bold,
		Text = props.Text or "",
		TextColor3 = props.Color or C.Paper,
		TextScaled = props.Scaled ~= false,
		TextSize = props.TextSize or 18,
		TextWrapped = true,
		TextXAlignment = props.AlignX or Enum.TextXAlignment.Left,
		TextYAlignment = props.AlignY or Enum.TextYAlignment.Center,
		RichText = props.Rich == true,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}) :: TextLabel
	if props.Stroke then
		Widgets.textStroke(label, props.StrokeColor, props.Stroke)
	end
	if props.MaxTextSize then
		new(
			"UITextSizeConstraint",
			{ MaxTextSize = props.MaxTextSize, MinTextSize = props.MinTextSize or 8, Parent = label }
		)
	end
	return label
end

-- Dark panel with a slanted accent header ribbon (the game's signature look).
function Widgets.panel(props: { [string]: any }): (Frame, Frame)
	local panel = new("Frame", {
		Name = props.Name or "Panel",
		BackgroundColor3 = props.Color or C.Ink,
		BackgroundTransparency = props.Transparency or 0.06,
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Visible = props.Visible ~= false,
		ZIndex = props.ZIndex or 1,
		Active = true, -- swallow clicks so the dimmer behind does not close the menu
		Parent = props.Parent,
	}) :: Frame
	Widgets.corner(panel, 8)
	Widgets.stroke(panel, props.StrokeColor or C.Shadow, 3, 0.2)
	Widgets.gradient(panel, { (props.Color or C.Ink):Lerp(C.InkLight, 0.35), props.Color or C.Ink }, 90)
	local content = new(
		"Frame",
		{ Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = panel }
	) :: Frame
	if props.Title then
		local ribbon = new("Frame", {
			Name = "Ribbon",
			BackgroundColor3 = props.Accent or C.Pink,
			Size = UDim2.new(0, props.TitleWidth or 260, 0, 46),
			Position = UDim2.new(0, -10, 0, -22),
			Rotation = Theme.Slant,
			ZIndex = (props.ZIndex or 1) + 2,
			Parent = panel,
		})
		Widgets.stroke(ribbon, C.Shadow, 3)
		new("Frame", {
			Name = "Shine",
			BackgroundColor3 = C.Paper,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 6),
			ZIndex = (props.ZIndex or 1) + 3,
			Parent = ribbon,
		})
		Widgets.label({
			Text = props.Title,
			Font = F.Display,
			Size = UDim2.new(1, -20, 1, -8),
			Position = UDim2.new(0, 14, 0, 4),
			Stroke = 2,
			ZIndex = (props.ZIndex or 1) + 4,
			Parent = ribbon,
		})
		content.Position = UDim2.new(0, 0, 0, 30)
		content.Size = UDim2.new(1, 0, 1, -30)
	end
	return panel, content
end

-- Primary action button. `style` = "Primary" | "Accent" | "Ghost" | "Danger" | "Gold".
local STYLE_COLORS = {
	Primary = { C.Cyan, Color3.fromRGB(0, 140, 220) },
	Accent = { C.Pink, Color3.fromRGB(190, 20, 110) },
	Gold = { C.Yellow, Color3.fromRGB(230, 140, 0) },
	Green = { C.Green, Color3.fromRGB(20, 160, 80) },
	Danger = { C.Red, Color3.fromRGB(170, 20, 40) },
	Ghost = { C.InkLight, C.InkSoft },
}

function Widgets.button(props: { [string]: any }): TextButton
	local colors = STYLE_COLORS[props.Style or "Primary"] or STYLE_COLORS.Primary
	local button = new("TextButton", {
		Name = props.Name or "Button",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Size = props.Size or UDim2.new(0, 160, 0, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Text = "",
		Selectable = true,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}) :: TextButton
	Widgets.corner(button, 6)
	local stroke = Widgets.stroke(button, C.Shadow, 3)
	local gradient = Widgets.gradient(button, colors, 90)
	local scale = new("UIScale", { Parent = button }) :: UIScale
	local text = Widgets.label({
		Name = "Text",
		Text = props.Text or "",
		Font = props.Font or F.Display,
		Size = UDim2.new(1, -16, 1, -10),
		Position = UDim2.new(0, 8, 0, 5),
		AlignX = Enum.TextXAlignment.Center,
		Color = props.TextColor or C.Paper,
		Stroke = 2,
		MaxTextSize = props.MaxTextSize or 30,
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = button,
	})
	local selection = new("Frame", {
		Name = "SelectionOutline",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 8, 1, 8),
		Position = UDim2.new(0, -4, 0, -4),
		ZIndex = (props.ZIndex or 1) + 2,
		Visible = false,
		Parent = button,
	})
	Widgets.corner(selection, 8)
	Widgets.stroke(selection, C.Yellow, 3)
	button.SelectionImageObject = selection
	local enabled = true
	button.MouseEnter:Connect(function()
		if enabled then
			tween(scale, Theme.Motion.Fast, { Scale = 1.05 })
			if Widgets.Audio then
				Widgets.Audio.Play("UiHover")
			end
		end
	end)
	button.MouseLeave:Connect(function()
		tween(scale, Theme.Motion.Fast, { Scale = 1 })
	end)
	button.SelectionGained:Connect(function()
		tween(scale, Theme.Motion.Fast, { Scale = 1.06 })
		stroke.Color = C.Yellow
	end)
	button.SelectionLost:Connect(function()
		tween(scale, Theme.Motion.Fast, { Scale = 1 })
		stroke.Color = C.Shadow
	end)
	button.MouseButton1Down:Connect(function()
		tween(scale, Theme.Motion.Fast, { Scale = 0.94 })
	end)
	button.MouseButton1Up:Connect(function()
		tween(scale, Theme.Motion.Pop, { Scale = 1 })
	end)
	if props.OnClick then
		button.Activated:Connect(function()
			if not enabled then
				if Widgets.Audio then
					Widgets.Audio.Play("UiError")
				end
				return
			end
			if Widgets.Audio then
				Widgets.Audio.Play("UiClick")
			end
			props.OnClick()
		end)
	end
	-- Small API on the instance for state changes.
	button:SetAttribute("Enabled", true)
	local api = {}
	function api.SetText(value: string)
		text.Text = value
	end
	function api.SetStyle(style: string)
		local c = STYLE_COLORS[style] or STYLE_COLORS.Primary
		gradient.Color = ColorSequence.new(c[1], c[2])
	end
	function api.SetEnabled(value: boolean)
		enabled = value
		button:SetAttribute("Enabled", value)
		button.BackgroundTransparency = if value then 0 else 0.5
		text.TextTransparency = if value then 0 else 0.4
	end
	Widgets._api[button] = api
	button.Destroying:Connect(function()
		Widgets._api[button] = nil
	end)
	return button
end
Widgets._api = setmetatable({}, { __mode = "k" }) :: any

function Widgets.api(button: Instance)
	return Widgets._api[button]
end

-- Square icon button with a glyph and caption (HUD side menu).
function Widgets.iconButton(props: { [string]: any }): TextButton
	local button = Widgets.button({
		Name = props.Name,
		Style = props.Style or "Ghost",
		Size = props.Size or UDim2.fromOffset(74, 74),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		OnClick = props.OnClick,
		Parent = props.Parent,
	})
	local text = button:FindFirstChild("Text") :: TextLabel
	text.Text = props.Icon or "?"
	text.Font = Enum.Font.GothamBlack
	text.Size = UDim2.new(1, -10, 0.62, 0)
	text.Position = UDim2.new(0, 5, 0, 4)
	Widgets.label({
		Name = "Caption",
		Text = props.Caption or "",
		Font = F.Heavy,
		Size = UDim2.new(1, -6, 0.3, 0),
		Position = UDim2.new(0, 3, 0.66, 0),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 1.5,
		MaxTextSize = 14,
		ZIndex = 3,
		Parent = button,
	})
	if props.Badge then
		local badge = new("TextLabel", {
			Name = "Badge",
			BackgroundColor3 = C.Pink,
			Size = UDim2.fromOffset(24, 24),
			Position = UDim2.new(1, -16, 0, -8),
			Text = "!",
			Font = F.Heavy,
			TextScaled = true,
			TextColor3 = C.Paper,
			Visible = false,
			ZIndex = 5,
			Parent = button,
		})
		Widgets.corner(badge, 12)
		Widgets.stroke(badge, C.Shadow, 2)
	end
	return button
end

-- Horizontal progress bar. Returns frame and setter(fraction).
function Widgets.bar(props: { [string]: any }): (Frame, (number) -> ())
	local back = new("Frame", {
		Name = props.Name or "Bar",
		BackgroundColor3 = C.InkSoft,
		Size = props.Size or UDim2.new(1, 0, 0, 12),
		Position = props.Position or UDim2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	}) :: Frame
	Widgets.corner(back, 6)
	Widgets.stroke(back, C.Shadow, 2)
	local fill = new(
		"Frame",
		{ Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(0, 1), Parent = back }
	)
	Widgets.corner(fill, 6)
	Widgets.gradient(fill, props.Colors or { C.Cyan, C.Purple }, 0)
	local function set(fraction: number)
		tween(fill, Theme.Motion.Slide, { Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) })
	end
	return back, set
end

-- Rarity-specific animated frame decoration for cosmetic cards.
function Widgets.rarityFrame(card: GuiObject, rarity, zIndex: number?)
	local style = rarity.frameStyle
	local stroke = Widgets.stroke(card, rarity.color, if rarity.order >= 4 then 4 else 3)
	local g = new("UIGradient", { Parent = stroke }) :: UIGradient
	local keypoints = {}
	for i, color in rarity.gradient do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / math.max(1, #rarity.gradient - 1), color))
	end
	g.Color = ColorSequence.new(keypoints)
	local connection: RBXScriptConnection? = nil
	if style == "Stripe" then
		g.Rotation = 45
	elseif style == "Shine" or style == "Pulse" or style == "Prismatic" then
		-- Animated strokes for Epic+ (rotating sheen / pulsing glow).
		connection = RunService.RenderStepped:Connect(function()
			if not card.Parent then
				if connection then
					connection:Disconnect()
				end
				return
			end
			local t = os.clock()
			if style == "Prismatic" then
				g.Rotation = (t * 120) % 360
			elseif style == "Pulse" then
				stroke.Transparency = 0.15 + (math.sin(t * 3) + 1) * 0.15
				g.Rotation = (t * 40) % 360
			else
				g.Offset = Vector2.new(math.sin(t * 1.5) * 0.5, 0)
			end
		end)
	end
	if rarity.order >= 4 then
		-- Glow halo behind Legendary/Mythic cards.
		local glow = new("Frame", {
			Name = "Glow",
			BackgroundColor3 = rarity.color,
			BackgroundTransparency = 0.8,
			Size = UDim2.new(1, 14, 1, 14),
			Position = UDim2.new(0, -7, 0, -7),
			ZIndex = math.max(0, (zIndex or 1) - 1),
			Parent = card,
		})
		Widgets.corner(glow, 12)
	end
	return stroke
end

-- Modal dimmer behind menus.
function Widgets.dimmer(parent: Instance, zIndex: number): Frame
	return new("Frame", {
		Name = "Dimmer",
		BackgroundColor3 = C.Shadow,
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex,
		Active = true,
		Parent = parent,
	}) :: Frame
end

function Widgets.scroll(props: { [string]: any }): ScrollingFrame
	local frame = new("ScrollingFrame", {
		Name = props.Name or "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Cyan,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Selectable = false,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	}) :: ScrollingFrame
	return frame
end

return Widgets
