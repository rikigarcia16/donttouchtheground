--!strict
-- Small helpers for building geometry from code (maps, lobby, cosmetics).
-- Parts are anchored, non-colliding and non-queryable unless a builder opts in,
-- which keeps decorations cheap for physics and raycasts.

local Build = {}

export type PartProps = {
	name: string?,
	size: Vector3,
	cframe: CFrame,
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
	reflectance: number?,
	collide: boolean?,
	anchored: boolean?,
	shape: Enum.PartType?,
	castShadow: boolean?,
	parent: Instance?,
	class: string?, -- "Part" | "WedgePart" | "CornerWedgePart"
}

function Build.part(props: PartProps): BasePart
	local part = Instance.new((props.class or "Part") :: any) :: BasePart
	part.Name = props.name or "Part"
	if props.shape and part:IsA("Part") then
		(part :: Part).Shape = props.shape
	end
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color or Color3.new(1, 1, 1)
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.Reflectance = props.reflectance or 0
	part.Anchored = if props.anchored == nil then true else props.anchored
	local collide = props.collide == true
	part.CanCollide = collide
	part.CanQuery = collide
	part.CanTouch = false
	part.CastShadow = if props.castShadow == nil then true else props.castShadow
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props.parent then
		part.Parent = props.parent
	end
	return part
end

function Build.neon(size: Vector3, cframe: CFrame, color: Color3, parent: Instance?): BasePart
	return Build.part({
		name = "Neon",
		size = size,
		cframe = cframe,
		color = color,
		material = Enum.Material.Neon,
		castShadow = false,
		parent = parent,
	})
end

function Build.ball(
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	parent: Instance?
): BasePart
	return Build.part({
		name = "Ball",
		shape = Enum.PartType.Ball,
		size = Vector3.new(diameter, diameter, diameter),
		cframe = cframe,
		color = color,
		material = material,
		parent = parent,
	})
end

-- Upright cylinder (axis along Y) centred on `cframe`.
local CYLINDER_UPRIGHT = CFrame.Angles(0, 0, math.rad(90))
function Build.cylinder(
	height: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	parent: Instance?
): BasePart
	return Build.part({
		name = "Cylinder",
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(height, diameter, diameter),
		cframe = cframe * CYLINDER_UPRIGHT,
		color = color,
		material = material,
		parent = parent,
	})
end
Build.CYLINDER_UPRIGHT = CYLINDER_UPRIGHT

-- Ring made of segments (no meshes needed). Returns the model.
function Build.ring(
	radius: number,
	thickness: number,
	height: number,
	segments: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	parent: Instance?
): Model
	local model = Instance.new("Model")
	model.Name = "Ring"
	local segmentLength = 2 * math.pi * radius / segments * 1.08
	for i = 0, segments - 1 do
		local angle = i / segments * math.pi * 2
		local cf = cframe * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -radius)
		Build.part({
			name = "Segment",
			size = Vector3.new(segmentLength, height, thickness),
			cframe = cf,
			color = color,
			material = material or Enum.Material.Neon,
			castShadow = false,
			parent = model,
		})
	end
	if parent then
		model.Parent = parent
	end
	return model
end

-- Arc of segments in the XY plane of `cframe` (used for rainbows and arches).
function Build.arc(
	radius: number,
	thickness: number,
	depth: number,
	fromAngle: number,
	toAngle: number,
	segments: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	parent: Instance?
): Model
	local model = Instance.new("Model")
	model.Name = "Arc"
	local span = toAngle - fromAngle
	local segmentLength = radius * math.abs(span) / segments * 1.1
	for i = 0, segments - 1 do
		local angle = fromAngle + span * (i + 0.5) / segments
		local position = Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
		local cf = cframe * CFrame.new(position) * CFrame.Angles(0, 0, angle + math.pi / 2)
		Build.part({
			name = "ArcSegment",
			size = Vector3.new(segmentLength, thickness, depth),
			cframe = cf,
			color = color,
			material = material or Enum.Material.Neon,
			castShadow = false,
			parent = model,
		})
	end
	if parent then
		model.Parent = parent
	end
	return model
end

-- Text on a part face (signs, boards, platform symbols).
function Build.label(
	part: BasePart,
	face: Enum.NormalId,
	text: string,
	props: {
		color: Color3?,
		font: Enum.Font?,
		pixelsPerStud: number?,
		transparency: number?,
		stroke: Color3?,
		bold: boolean?,
	}?
): TextLabel
	local options: { [string]: any } = props or {}
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = options.pixelsPerStud or 20
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextScaled = true
	label.Font = options.font or Enum.Font.LuckiestGuy
	label.TextColor3 = options.color or Color3.new(1, 1, 1)
	label.TextTransparency = options.transparency or 0
	if options.stroke then
		label.TextStrokeColor3 = options.stroke
		label.TextStrokeTransparency = 0
	else
		label.TextStrokeTransparency = 1
	end
	label.Parent = gui
	gui.Parent = part
	return label
end

function Build.light(parent: Instance, color: Color3, range: number, brightness: number): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = parent
	return light
end

function Build.model(name: string, parent: Instance?): Model
	local model = Instance.new("Model")
	model.Name = name
	if parent then
		model.Parent = parent
	end
	return model
end

function Build.lerpColor(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, t)
end

-- Rainbow helper: hue 0..1 to a saturated colour.
function Build.hue(h: number, s: number?, v: number?): Color3
	return Color3.fromHSV(h % 1, s or 0.85, v or 1)
end

return Build
