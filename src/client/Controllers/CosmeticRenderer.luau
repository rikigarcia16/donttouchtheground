--!nonstrict
-- Renders every player's cosmetics from the replicated character attributes
-- (Cos_Trail, Cos_Aura, Cos_Acc_<slot>, Cos_Title...). Handles nameplates,
-- jump/landing/elimination bursts, try-on previews, results-stage clones,
-- distance culling and the "show others' effects" setting.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local ProfileSchema = require(Shared.Logic.ProfileSchema)
local Remotes = require(Shared.Net.Remotes)
local FxKit = require(Shared.Visual.FxKit)
local Visuals = require(Shared.Visual.CosmeticVisuals)
local TitleStyles = require(Shared.Visual.TitleStyles)

local CosmeticRenderer = {}
CosmeticRenderer.showOthers = true

local Quality: any
local Movement: any
local localPlayer = Players.LocalPlayer

type Entry = {
	character: Model,
	kits: { [string]: any },
	current: { [string]: string? },
	nameplate: BillboardGui?,
	isLocal: boolean,
	connections: { RBXScriptConnection },
	overrides: { [string]: string? }?,
	static: boolean,
}

local entries: { [Model]: Entry } = {}
local previewOverrides: { [string]: string? } = {}

local BURST_CATEGORY = { Jump = "JumpEffect", Land = "LandingEffect", Death = "DeathEffect" }

local LAYERS = { "Trail", "Aura" }
for _, slot in ProfileSchema.ACCESSORY_SLOTS do
	table.insert(LAYERS, "Acc_" .. slot)
end

local function layerCategory(layer: string): string
	return if string.sub(layer, 1, 4) == "Acc_" then "Accessory" else layer
end

local function wanted(entry: Entry, layer: string): string?
	if entry.overrides and entry.overrides[layer] ~= nil then
		local value = entry.overrides[layer]
		return if value == "" then nil else value
	end
	return entry.character:GetAttribute("Cos_" .. layer) :: string?
end

local function rebuildLayer(entry: Entry, layer: string)
	local id = wanted(entry, layer)
	if entry.current[layer] == id and (id == nil or entry.kits[layer]) then
		return
	end
	local old = entry.kits[layer]
	if old then
		old:Destroy()
		entry.kits[layer] = nil
	end
	entry.current[layer] = id
	if not id then
		return
	end
	local builder = Visuals[layerCategory(layer)][id]
	if not builder then
		return
	end
	local kit = FxKit.new(entry.character, Quality.Get())
	local ok, err = pcall(builder, kit)
	if not ok then
		warn("[CosmeticRenderer] " .. id .. " failed: " .. tostring(err))
		kit:Destroy()
		return
	end
	entry.kits[layer] = kit
end

-- ===== Nameplates
local function buildNameplate(entry: Entry)
	local character = entry.character
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	if entry.nameplate then
		entry.nameplate:Destroy()
	end
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "DTTG_Nameplate"
	gui.Size = UDim2.fromOffset(220, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Adornee = head
	gui.ResetOnSpawn = false

	local style, titleName = TitleStyles.get(character:GetAttribute("Cos_Title"))
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.42)
	title.Font = if style then style.font else Enum.Font.GothamBold
	title.TextScaled = true
	title.Text = if titleName then string.upper(titleName) else ""
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = gui
	if style then
		local gradient = Instance.new("UIGradient")
		gradient.Color = FxKit.colors(style.colors)
		gradient.Rotation = 90
		gradient.Parent = title
		local stroke = Instance.new("UIStroke")
		stroke.Color = style.stroke
		stroke.Thickness = style.strokeThickness
		stroke.Parent = title
		if style.animate > 0 or style.pulse or style.sparkles then
			table.insert(
				entry.connections,
				RunService.RenderStepped:Connect(function()
					local t = os.clock()
					if style.animate > 0 then
						gradient.Rotation = (t * style.animate) % 360
					end
					if style.pulse then
						stroke.Transparency = 0.2 + (math.sin(t * 4) + 1) * 0.2
					end
				end)
			)
		end
		if style.sparkles then
			title.Text = style.sparkles .. " " .. title.Text .. " " .. style.sparkles
		end
	end

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromScale(0, 0.42)
	name.Size = UDim2.fromScale(1, 0.4)
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	local level = character:GetAttribute("Level") or 1
	name.Text = string.format("%s  ·  Lv %d", if player then player.DisplayName else character.Name, level)
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.4
	name.Parent = gui
	gui.Parent = character
	entry.nameplate = gui
end

local function refreshAll(entry: Entry)
	for _, layer in LAYERS do
		rebuildLayer(entry, layer)
	end
end

function CosmeticRenderer.Attach(character: Model, options: { static: boolean?, overrides: { [string]: string? }? }?)
	if entries[character] then
		return entries[character]
	end
	local opts = options or {}
	local entry: Entry = {
		character = character,
		kits = {},
		current = {},
		nameplate = nil,
		isLocal = character == localPlayer.Character,
		connections = {},
		overrides = opts.overrides,
		static = opts.static == true,
	}
	entries[character] = entry
	if entry.isLocal then
		entry.overrides = previewOverrides
	end
	-- Wait for the rig so attachments exist.
	task.spawn(function()
		character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Head", 10)
		if not entries[character] then
			return
		end
		refreshAll(entry)
		if not entry.static then
			buildNameplate(entry)
		end
	end)
	for _, layer in LAYERS do
		table.insert(
			entry.connections,
			character:GetAttributeChangedSignal("Cos_" .. layer):Connect(function()
				rebuildLayer(entry, layer)
			end)
		)
	end
	table.insert(
		entry.connections,
		character:GetAttributeChangedSignal("Cos_Title"):Connect(function()
			buildNameplate(entry)
		end)
	)
	table.insert(
		entry.connections,
		character:GetAttributeChangedSignal("Level"):Connect(function()
			buildNameplate(entry)
		end)
	)
	table.insert(
		entry.connections,
		character.AncestryChanged:Connect(function()
			if not character:IsDescendantOf(workspace) then
				CosmeticRenderer.Detach(character)
			end
		end)
	)
	return entry
end

function CosmeticRenderer.Detach(character: Model)
	local entry = entries[character]
	if not entry then
		return
	end
	entries[character] = nil
	for _, c in entry.connections do
		c:Disconnect()
	end
	for _, kit in entry.kits do
		kit:Destroy()
	end
	if entry.nameplate then
		entry.nameplate:Destroy()
	end
end

-- ===== Try-on preview on the local character
function CosmeticRenderer.Preview(category: string, item)
	local layer = if category == "Accessory" then "Acc_" .. item.slot else category
	previewOverrides[layer] = item.id
	local entry = localPlayer.Character and entries[localPlayer.Character]
	if entry then
		rebuildLayer(entry, layer)
	end
end

function CosmeticRenderer.ClearPreview()
	local layers = {}
	for layer in previewOverrides do
		table.insert(layers, layer)
	end
	table.clear(previewOverrides)
	local entry = localPlayer.Character and entries[localPlayer.Character]
	if entry then
		for _, layer in layers do
			rebuildLayer(entry, layer)
		end
	end
end

function CosmeticRenderer.HasPreview(): boolean
	return next(previewOverrides) ~= nil
end

-- Renders a loadout on an arbitrary model (results stage clone).
function CosmeticRenderer.RenderLoadout(model: Model, loadout: { [string]: any })
	local overrides = {}
	overrides.Trail = loadout.Trail or ""
	overrides.Aura = loadout.Aura or ""
	for _, slot in ProfileSchema.ACCESSORY_SLOTS do
		overrides["Acc_" .. slot] = (loadout.Accessories and loadout.Accessories[slot]) or ""
	end
	CosmeticRenderer.Attach(model, { static = true, overrides = overrides })
end

-- ===== Bursts
local function playBurst(category: string, effectId: string?, position: Vector3, character: Model?)
	local map = Visuals[category]
	local fn = effectId and map[effectId]
	if not fn and category == "DeathEffect" then
		fn = map.default
	end
	if fn then
		local ok, err = pcall(fn, position, character)
		if not ok then
			warn("[CosmeticRenderer] burst " .. tostring(effectId) .. ": " .. tostring(err))
		end
	end
end

function CosmeticRenderer.PlayBurst(category: string, effectId: string?, position: Vector3, character: Model?)
	playBurst(category, effectId, position, character)
end

function CosmeticRenderer.Init(controllers)
	Quality = controllers.QualityController
	Movement = controllers.MovementController
end

function CosmeticRenderer.Start()
	local function hookPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			CosmeticRenderer.Attach(character)
		end)
		if player.Character then
			CosmeticRenderer.Attach(player.Character)
		end
	end
	Players.PlayerAdded:Connect(hookPlayer)
	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end

	Remotes.event("FX").OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" or typeof(payload.position) ~= "Vector3" then
			return
		end
		local camera = workspace.CurrentCamera
		if camera and (camera.CFrame.Position - payload.position).Magnitude > Quality.Get().maxEffectDistance then
			return
		end
		local category = BURST_CATEGORY[payload.kind]
		if not category then
			return
		end
		local other = Players:GetPlayerByUserId(payload.userId or 0)
		local hidden = other ~= localPlayer and not CosmeticRenderer.showOthers
		if hidden and category ~= "DeathEffect" then
			return
		end
		local character = if category == "DeathEffect" then nil else (other and other.Character)
		playBurst(category, payload.effectId, payload.position, character)
	end)

	-- Own jump/landing effects play instantly (no server round-trip).
	Movement.Jumped:Connect(function(character)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			playBurst("JumpEffect", character:GetAttribute("Cos_JumpEffect"), root.Position, character)
		end
	end)
	Movement.Landed:Connect(function(character)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			playBurst("LandingEffect", character:GetAttribute("Cos_LandingEffect"), root.Position, character)
		end
	end)

	Quality.Changed:Connect(function()
		for _, entry in entries do
			for layer, kit in entry.kits do
				kit:Destroy()
				entry.kits[layer] = nil
				entry.current[layer] = nil
			end
			refreshAll(entry)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		local cameraPos = if camera then camera.CFrame.Position else Vector3.zero
		local maxDistance = Quality.Get().maxEffectDistance
		for character, entry in entries do
			local root = character:FindFirstChild("HumanoidRootPart")
			local visible = true
			if root then
				visible = (root.Position - cameraPos).Magnitude <= maxDistance
			end
			if not entry.isLocal and not entry.static and not CosmeticRenderer.showOthers then
				visible = false
			end
			for _, kit in entry.kits do
				kit:SetVisible(visible)
				if visible then
					kit:Update(dt)
				end
			end
		end
		FxKit.StepPools(dt)
	end)
end

return CosmeticRenderer
