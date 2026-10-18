--!nonstrict
-- Reusable decoration pieces for maps and the lobby. Everything here is
-- non-colliding, non-queryable and shadow-light to stay cheap on mobile.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)

local Decor = {}

local RGB = Color3.fromRGB

function Decor.cloud(cframe: CFrame, scale: number, color: Color3?, parent: Instance)
	local model = Build.model("Cloud", parent)
	local c = color or RGB(255, 255, 255)
	local puffs = {
		{ Vector3.new(0, 0, 0), 1 },
		{ Vector3.new(1.1, 0.15, 0.2), 0.8 },
		{ Vector3.new(-1.1, 0.1, -0.1), 0.75 },
		{ Vector3.new(0.4, 0.55, -0.3), 0.7 },
		{ Vector3.new(-0.5, 0.45, 0.4), 0.6 },
	}
	for _, puff in puffs do
		local ball = Build.ball(
			puff[2] * 6 * scale,
			cframe * CFrame.new(puff[1] * 4 * scale),
			c,
			Enum.Material.SmoothPlastic,
			model
		)
		ball.CastShadow = false
	end
	return model
end

function Decor.rainbowArc(cframe: CFrame, radius: number, parent: Instance)
	local model = Build.model("Rainbow", parent)
	for band = 0, 6 do
		Build.arc(
			radius - band * 1.6,
			1.6,
			1.2,
			0,
			math.pi,
			22,
			cframe,
			Build.hue(band / 7, 0.8, 1),
			Enum.Material.Neon,
			model
		)
	end
	return model
end

function Decor.star(cframe: CFrame, size: number, color: Color3, parent: Instance)
	local model = Build.model("Star", parent)
	for i = 0, 2 do
		Build.neon(
			Vector3.new(size, size * 0.18, size * 0.18),
			cframe * CFrame.Angles(0, 0, i * math.pi / 3),
			color,
			model
		)
	end
	return model
end

function Decor.tree(cframe: CFrame, height: number, leafColor: Color3, parent: Instance)
	local model = Build.model("Tree", parent)
	Build.cylinder(
		height,
		height * 0.16,
		cframe * CFrame.new(0, height / 2, 0),
		RGB(120, 80, 50),
		Enum.Material.Wood,
		model
	)
	Build.ball(height * 0.75, cframe * CFrame.new(0, height, 0), leafColor, Enum.Material.Grass, model)
	Build.ball(
		height * 0.5,
		cframe * CFrame.new(height * 0.25, height * 0.85, height * 0.1),
		leafColor:Lerp(RGB(255, 255, 160), 0.15),
		Enum.Material.Grass,
		model
	)
	return model
end

function Decor.rock(cframe: CFrame, size: number, color: Color3, parent: Instance)
	local part = Build.part({
		name = "Rock",
		size = Vector3.new(size, size * 0.7, size * 0.9),
		cframe = cframe * CFrame.Angles(0.3, 0.7, 0.2),
		color = color,
		material = Enum.Material.Slate,
		parent = parent,
	})
	return part
end

function Decor.crystal(cframe: CFrame, height: number, color: Color3, parent: Instance)
	local model = Build.model("Crystal", parent)
	local body = Build.part({
		name = "CrystalBody",
		size = Vector3.new(height * 0.3, height, height * 0.3),
		cframe = cframe * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, math.rad(45), math.rad(8)),
		color = color,
		material = Enum.Material.Glass,
		transparency = 0.2,
		parent = model,
	})
	body.CastShadow = false
	Build.neon(
		Vector3.new(height * 0.12, height * 0.9, height * 0.12),
		body.CFrame,
		color:Lerp(Color3.new(1, 1, 1), 0.4),
		model
	)
	return model
end

-- Lightweight ambient emitter (sparkles, embers, bubbles...). Rates are scaled
-- down on low quality by the client EffectsQuality controller via attribute.
function Decor.ambientEmitter(
	cframe: CFrame,
	size: Vector3,
	props: {
		texture: string,
		color: ColorSequence,
		rate: number,
		lifetime: NumberRange,
		speed: NumberRange,
		size: NumberSequence,
		transparency: NumberSequence?,
		acceleration: Vector3?,
		lightEmission: number?,
	},
	parent: Instance
)
	local anchor = Build.part({
		name = "AmbientFX",
		size = size,
		cframe = cframe,
		transparency = 1,
		castShadow = false,
		parent = parent,
	})
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = props.texture
	emitter.Color = props.color
	emitter.Rate = props.rate
	emitter.Lifetime = props.lifetime
	emitter.Speed = props.speed
	emitter.Size = props.size
	emitter.Transparency = props.transparency or NumberSequence.new(0.2, 1)
	emitter.Acceleration = props.acceleration or Vector3.zero
	emitter.LightEmission = props.lightEmission or 0.6
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter:SetAttribute("BaseRate", props.rate)
	emitter.Parent = anchor
	return anchor
end

Decor.TEXTURES = {
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Spark = "rbxasset://textures/particles/fire_sparks_main.dds",
}

-- Glowing sign with text (Neon City billboards, lobby signage).
function Decor.sign(
	cframe: CFrame,
	size: Vector3,
	text: string,
	background: Color3,
	textColor: Color3,
	parent: Instance
)
	local board = Build.part({
		name = "Sign",
		size = size,
		cframe = cframe,
		color = background,
		material = Enum.Material.Neon,
		castShadow = false,
		parent = parent,
	})
	local label = Build.label(
		board,
		Enum.NormalId.Front,
		text,
		{ color = textColor, pixelsPerStud = 16, stroke = background:Lerp(Color3.new(0, 0, 0), 0.6) }
	)
	Build.label(
		board,
		Enum.NormalId.Back,
		text,
		{ color = textColor, pixelsPerStud = 16, stroke = background:Lerp(Color3.new(0, 0, 0), 0.6) }
	)
	return board, label
end

return Decor
