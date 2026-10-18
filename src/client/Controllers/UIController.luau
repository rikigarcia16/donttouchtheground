--!nonstrict
-- Owns the ScreenGuis, responsive scaling, the menu stack and input routing
-- (keyboard shortcuts, gamepad buttons, touch). Screens live in Client/UI.

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)

local UIFolder = script.Parent.Parent:WaitForChild("UI")
local Theme = require(UIFolder.Theme)
local Widgets = require(UIFolder.Widgets)

local UIController = {}
UIController.MenuChanged = Signal.new() -- (name?)
UIController.current = nil :: string?

local menus: { [string]: any } = {}
local controllers: any
local screen: ScreenGui
local menuLayer: Frame
local hudLayer: Frame
local overlayLayer: Frame
local uiScale: UIScale

local function computeScale(): number
	local camera = workspace.CurrentCamera
	local viewport = if camera then camera.ViewportSize else Theme.DesignSize
	local base = math.min(viewport.X / Theme.DesignSize.X, viewport.Y / Theme.DesignSize.Y)
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		base *= 1.2
	end
	return math.clamp(base, 0.5, 1.35)
end

function UIController.IsTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function UIController.Register(name: string, menu)
	menus[name] = menu
end

function UIController.Open(name: string, ...)
	local menu = menus[name]
	if not menu then
		return
	end
	if UIController.current and UIController.current ~= name then
		UIController.Close(UIController.current)
	end
	UIController.current = name
	menu.open(...)
	if controllers.AudioController then
		controllers.AudioController.Play("UiOpen")
	end
	if UserInputService.GamepadEnabled and menu.first then
		local first = menu.first()
		if first then
			GuiService.SelectedObject = first
		end
	end
	UIController.MenuChanged:Fire(name)
end

function UIController.Close(name: string?)
	local target = name or UIController.current
	if not target then
		return
	end
	local menu = menus[target]
	if menu then
		menu.close()
	end
	if UIController.current == target then
		UIController.current = nil
		GuiService.SelectedObject = nil
		UIController.MenuChanged:Fire(nil)
	end
end

function UIController.Toggle(name: string, ...)
	if UIController.current == name then
		UIController.Close(name)
	else
		UIController.Open(name, ...)
	end
end

function UIController.Layers()
	return { root = screen, hud = hudLayer, menu = menuLayer, overlay = overlayLayer }
end

function UIController.Init(all)
	controllers = all
	Widgets.Audio = all.AudioController
end

function UIController.Start()
	local player = Players.LocalPlayer
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	end)

	screen = Instance.new("ScreenGui")
	screen.Name = "DTTG_UI"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.IgnoreGuiInset = false
	screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	screen.Parent = player:WaitForChild("PlayerGui")

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = screen
	uiScale = Instance.new("UIScale")
	uiScale.Parent = root

	-- Layers are sized in design units: Size = 1/scale so children laid out
	-- in offsets keep proportions on every screen.
	local function layer(name: string, z: number): Frame
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.ZIndex = z
		frame.Parent = root
		return frame
	end
	hudLayer = layer("HUD", 1)
	menuLayer = layer("Menus", 20)
	overlayLayer = layer("Overlay", 40)

	local function rescale()
		local s = computeScale()
		uiScale.Scale = s
		for _, frame in { hudLayer, menuLayer, overlayLayer } do
			frame.Size = UDim2.fromScale(1 / s, 1 / s)
		end
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	UserInputService.LastInputTypeChanged:Connect(rescale)

	-- Load and build every screen module.
	for _, name in
		{ "HUD", "Notifications", "RoundUI", "ShopMenu", "EmoteMenu", "QuestMenu", "SettingsMenu", "ResultsScreen" }
	do
		local module = UIFolder:FindFirstChild(name)
		if module then
			local ok, err = pcall(function()
				require(module).build(UIController, controllers)
			end)
			if not ok then
				warn("[UI] " .. name .. " failed to build: " .. tostring(err))
			end
		end
	end

	-- Shortcuts. Keyboard: B shop, I inventory, G emotes, J quests, Esc close.
	-- Gamepad: Y shop, X emotes, DPad Up quests, DPad Down inventory, B close.
	local function bind(actionName: string, menuName: string?, ...: Enum.KeyCode)
		ContextActionService:BindAction(actionName, function(_, state)
			if state ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
			if UserInputService:GetFocusedTextBox() then
				return Enum.ContextActionResult.Pass
			end
			if menuName then
				UIController.Toggle(menuName)
			elseif UIController.current then
				UIController.Close()
			else
				return Enum.ContextActionResult.Pass
			end
			return Enum.ContextActionResult.Sink
		end, false, ...)
	end
	bind("DTTG_Shop", "Shop", Enum.KeyCode.B, Enum.KeyCode.ButtonY)
	bind("DTTG_Inventory", "Inventory", Enum.KeyCode.I, Enum.KeyCode.DPadDown)
	bind("DTTG_Emotes", "Emotes", Enum.KeyCode.G, Enum.KeyCode.ButtonX)
	bind("DTTG_Quests", "Quests", Enum.KeyCode.J, Enum.KeyCode.DPadUp)
	bind("DTTG_Close", nil, Enum.KeyCode.ButtonB)

	-- Lobby proximity prompts open the matching menus.
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
		local kind = prompt:GetAttribute("Kind")
		if kind == "Shop" then
			UIController.Open("Shop")
		elseif kind == "Preview" then
			UIController.Open("Inventory", { fittingRoom = true })
		elseif kind == "Emotes" then
			UIController.Open("Emotes")
		elseif kind == "Portal" then
			UIController.Open("Portal")
		end
	end)
end

return UIController
