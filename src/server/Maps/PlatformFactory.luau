--!nonstrict
-- Creates interactive platforms with a consistent visual language so every
-- type is recognisable at a glance: colour + rim glow + symbol + material.
-- Behaviour is implemented by HazardService (server) and the client
-- PlatformController (motion, warnings) from the attributes set here.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)
local PlatformMotion = require(Shared.Logic.PlatformMotion)

local PlatformFactory = {}
PlatformFactory.__index = PlatformFactory

export type PlatformType =
	"Normal"
	| "Fragile"
	| "Disappearing"
	| "Moving"
	| "Rotating"
	| "Bounce"
	| "Slippery"
	| "Temporary"
	| "Fake"
	| "Checkpoint"

export type Options = {
	round: boolean?,
	color: Color3?,
	material: Enum.Material?,
	colorGroup: number?,
	motion: PlatformMotion.Channel?,
	name: string?,
	noRim: boolean?,
	symbol: string?,
	transparency: number?,
}

-- Visual language per type. `color` nil = use the map palette colour.
local STYLE: { [string]: { color: Color3?, rim: Color3?, material: Enum.Material?, symbol: string?, transparency: number? } } =
	{
		Normal = { rim = nil },
		Fragile = {
			color = Color3.fromRGB(230, 170, 90),
			rim = Color3.fromRGB(255, 210, 60),
			material = Enum.Material.Sandstone,
			symbol = "⚠",
		},
		Disappearing = {
			color = Color3.fromRGB(255, 120, 200),
			rim = Color3.fromRGB(255, 60, 160),
			material = Enum.Material.Glass,
			symbol = "⏱",
			transparency = 0.1,
		},
		Moving = { rim = Color3.fromRGB(60, 230, 255), material = Enum.Material.DiamondPlate, symbol = "⇄" },
		Rotating = { rim = Color3.fromRGB(190, 110, 255), material = Enum.Material.Metal, symbol = "⟳" },
		Bounce = {
			color = Color3.fromRGB(110, 255, 90),
			rim = Color3.fromRGB(200, 255, 80),
			material = Enum.Material.SmoothPlastic,
			symbol = "⇧",
		},
		Slippery = {
			color = Color3.fromRGB(190, 240, 255),
			rim = Color3.fromRGB(130, 220, 255),
			material = Enum.Material.Ice,
			symbol = "❄",
		},
		Temporary = {
			rim = Color3.fromRGB(255, 255, 255),
			material = Enum.Material.Neon,
			transparency = 0.25,
			symbol = "✦",
		},
		Fake = { material = Enum.Material.Glass, transparency = 0.22, symbol = "?" },
		Checkpoint = {
			color = Color3.fromRGB(70, 230, 140),
			rim = Color3.fromRGB(120, 255, 170),
			material = Enum.Material.SmoothPlastic,
			symbol = "✚",
		},
	}
PlatformFactory.STYLE = STYLE

function PlatformFactory.new(folder: Instance, palette: { Color3 })
	local self = setmetatable({
		folder = folder,
		palette = palette,
		count = 0,
		platforms = {} :: { BasePart },
	}, PlatformFactory)
	return self
end

export type Factory = typeof(PlatformFactory.new(Instance.new("Folder"), {}))

-- `cframe` is the upright centre of the platform; `size` is logical
-- (width X, thickness Y, depth Z). Round platforms use size.X as diameter.
function PlatformFactory.Create(
	self: Factory,
	kind: PlatformType,
	cframe: CFrame,
	size: Vector3,
	options: Options?
): BasePart
	local opts: Options = options or {}
	local style = STYLE[kind]
	assert(style, "Unknown platform type " .. kind)
	self.count += 1
	local colorGroup = opts.colorGroup or ((self.count - 1) % #self.palette) + 1
	local color = opts.color or style.color or self.palette[colorGroup]
	local round = opts.round == true
	local part: BasePart
	if round then
		part = Build.cylinder(size.Y, size.X, cframe, color, opts.material or style.material)
	else
		part = Build.part({ size = size, cframe = cframe, color = color, material = opts.material or style.material })
	end
	part.Name = opts.name or (kind .. "Platform")
	part.CanCollide = true
	part.CanQuery = true
	part.Transparency = opts.transparency or style.transparency or 0

	part:SetAttribute("PType", kind)
	part:SetAttribute("Round", round)
	part:SetAttribute("LSize", size)
	part:SetAttribute("BasePos", cframe.Position)
	local _, yaw, _ = cframe:ToOrientation()
	part:SetAttribute("BaseYaw", yaw)
	part:SetAttribute("ColorGroup", colorGroup)
	part:SetAttribute("BaseColor", color)
	part:SetAttribute("BaseTransparency", part.Transparency)

	-- Glowing rim slightly larger than the platform, welded visually by
	-- following the same motion on the client (child of the platform).
	if not opts.noRim then
		local rimColor = style.rim or color:Lerp(Color3.new(1, 1, 1), 0.45)
		local rimSize = if round
			then Vector3.new(0.35, size.X + 0.5, size.X + 0.5)
			else Vector3.new(size.X + 0.5, 0.35, size.Z + 0.5)
		local rimCFrame = if round
			then cframe * CFrame.new(0, -size.Y / 2 + 0.1, 0) * Build.CYLINDER_UPRIGHT
			else cframe * CFrame.new(0, -size.Y / 2 + 0.1, 0)
		local rim = Build.part({
			name = "Rim",
			shape = if round then Enum.PartType.Cylinder else nil,
			size = rimSize,
			cframe = rimCFrame,
			color = rimColor,
			material = Enum.Material.Neon,
			castShadow = false,
		})
		rim.Parent = part
	end

	local symbol = opts.symbol or style.symbol
	if symbol and math.min(size.X, size.Z) >= 4 then
		local face = if round then Enum.NormalId.Right else Enum.NormalId.Top
		local label = Build.label(part, face, symbol, {
			color = Color3.new(1, 1, 1),
			font = Enum.Font.GothamBlack,
			pixelsPerStud = 12,
			transparency = if kind == "Fake" then 0.75 else 0.35,
		})
		label.Size = UDim2.fromScale(0.5, 0.5)
		label.Position = UDim2.fromScale(0.25, 0.25)
	end

	if opts.motion then
		PlatformMotion.writeChannel(part, "M_", opts.motion)
	end

	part.Parent = self.folder
	table.insert(self.platforms, part)
	return part
end

return PlatformFactory
