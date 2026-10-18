--!nonstrict
-- The cosmetic effects engine. A kit is bound to one character (or a world
-- position for bursts) and offers building blocks — trails, emitters,
-- welded parts, glyph particles, part debris, orbiting objects, per-frame
-- updaters — that every cosmetic definition composes into its own look.
-- Everything is client-side, quality-scaled and cleaned by a Maid.

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Maid = require(script.Parent.Parent.Util.Maid)

local FxKit = {}
FxKit.__index = FxKit

FxKit.TEXTURES = {
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Spark = "rbxasset://textures/particles/fire_sparks_main.dds",
}

export type Quality = { particles: number, glyphs: number, debris: number, lights: boolean, maxEffectDistance: number }

FxKit.DEFAULT_QUALITY = { particles = 1, glyphs = 1, debris = 1, lights = true, maxEffectDistance = 260 } :: Quality

-- ===================================================================== helpers
function FxKit.seq(...: number): NumberSequence
	local values = { ... }
	if #values == 1 then
		return NumberSequence.new(values[1])
	end
	local keypoints = {}
	for i, value in values do
		table.insert(keypoints, NumberSequenceKeypoint.new((i - 1) / (#values - 1), value))
	end
	return NumberSequence.new(keypoints)
end

function FxKit.colors(list: { Color3 }): ColorSequence
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local keypoints = {}
	for i, color in list do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / (#list - 1), color))
	end
	return ColorSequence.new(keypoints)
end

function FxKit.rainbow(count: number?, s: number?, v: number?): ColorSequence
	local n = count or 7
	local list = {}
	for i = 0, n - 1 do
		table.insert(list, Color3.fromHSV(i / n, s or 0.8, v or 1))
	end
	return FxKit.colors(list)
end

local function applyEmitterProps(emitter: ParticleEmitter, props, quality: Quality)
	emitter.Texture = FxKit.TEXTURES[props.texture or "Sparkle"] or props.texture
	emitter.Color = if typeof(props.color) == "ColorSequence"
		then props.color
		else FxKit.colors(props.color or { Color3.new(1, 1, 1) })
	emitter.Size = if typeof(props.size) == "NumberSequence"
		then props.size
		else FxKit.seq(table.unpack(props.size or { 0.5, 0 }))
	emitter.Transparency = if typeof(props.transparency) == "NumberSequence"
		then props.transparency
		else FxKit.seq(table.unpack(props.transparency or { 0, 1 }))
	emitter.Lifetime =
		NumberRange.new(props.lifetime and props.lifetime[1] or 0.6, props.lifetime and props.lifetime[2] or 1)
	emitter.Speed = NumberRange.new(props.speed and props.speed[1] or 1, props.speed and props.speed[2] or 2)
	local spread = props.spread or { 20, 20 }
	emitter.SpreadAngle = Vector2.new(spread[1], spread[2])
	emitter.Acceleration = props.acceleration or Vector3.zero
	emitter.Drag = props.drag or 0
	emitter.LightEmission = props.lightEmission or 0.5
	emitter.LightInfluence = props.lightInfluence or 0
	emitter.Rotation =
		NumberRange.new(props.rotation and props.rotation[1] or 0, props.rotation and props.rotation[2] or 360)
	emitter.RotSpeed =
		NumberRange.new(props.rotSpeed and props.rotSpeed[1] or -60, props.rotSpeed and props.rotSpeed[2] or 60)
	emitter.ZOffset = props.zOffset or 0
	emitter.LockedToPart = props.locked == true
	emitter.EmissionDirection = props.direction or Enum.NormalId.Top
	if props.shape then
		emitter.Shape = props.shape
		emitter.ShapeStyle = props.shapeStyle or Enum.ParticleEmitterShapeStyle.Volume
		emitter.ShapeInOut = props.shapeInOut or Enum.ParticleEmitterShapeInOut.Outward
	end
	if props.squash then
		emitter.Squash = FxKit.seq(table.unpack(props.squash))
	end
	local rate = (props.rate or 10) * quality.particles
	emitter:SetAttribute("BaseRate", props.rate or 10)
	emitter.Rate = rate
end

-- ===================================================================== kit
function FxKit.new(character: Model?, quality: Quality?)
	local self = setmetatable({}, FxKit)
	self.character = character
	self.root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	self.humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	self.q = quality or FxKit.DEFAULT_QUALITY
	self.maid = Maid.new()
	self.updaters = {}
	self.movingOnly = {} -- emitters/trails that only run while moving
	self.time = 0
	self.speed = 0
	self.velocity = Vector3.zero
	self.verticalSpeed = 0
	self.grounded = true
	self.visible = true
	if character then
		local folder = Instance.new("Model")
		folder.Name = "DTTG_Cosmetics"
		folder.Parent = character
		self.folder = folder
		self.maid:Add(folder)
	end
	return self
end

export type Kit = typeof(FxKit.new(nil, nil))

function FxKit.BodyPart(self: Kit, name: string): BasePart?
	local character = self.character
	if not character then
		return nil
	end
	local aliases = {
		Torso = { "UpperTorso", "Torso" },
		Waist = { "LowerTorso", "Torso" },
		LeftFoot = { "LeftFoot", "Left Leg" },
		RightFoot = { "RightFoot", "Right Leg" },
		LeftHand = { "LeftHand", "Left Arm" },
		RightHand = { "RightHand", "Right Arm" },
	}
	for _, candidate in aliases[name] or { name } do
		local part = character:FindFirstChild(candidate)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return self.root
end

-- Finds an avatar attachment (HatAttachment, BodyBackAttachment...) and
-- returns its part and local CFrame, falling back to a sensible offset.
function FxKit.AvatarAttachment(
	self: Kit,
	attachmentName: string,
	fallbackPart: string,
	fallbackOffset: CFrame
): (BasePart?, CFrame)
	local character = self.character
	if character then
		for _, descendant in character:GetDescendants() do
			if
				descendant:IsA("Attachment")
				and descendant.Name == attachmentName
				and descendant.Parent
				and descendant.Parent:IsA("BasePart")
			then
				local parent = descendant.Parent
				if parent.Parent == character then
					return parent :: BasePart, descendant.CFrame
				end
			end
		end
	end
	return self:BodyPart(fallbackPart), fallbackOffset
end

function FxKit.Attachment(self: Kit, partName: string, offset: CFrame?): Attachment?
	local part = self:BodyPart(partName)
	if not part then
		return nil
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "DTTG_FX"
	attachment.CFrame = offset or CFrame.new()
	attachment.Parent = part
	self.maid:Add(attachment)
	return attachment
end

function FxKit.Trail(self: Kit, a0: Attachment, a1: Attachment, props): Trail
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = if typeof(props.color) == "ColorSequence"
		then props.color
		else FxKit.colors(props.color or { Color3.new(1, 1, 1) })
	trail.Transparency = if typeof(props.transparency) == "NumberSequence"
		then props.transparency
		else FxKit.seq(table.unpack(props.transparency or { 0.2, 1 }))
	trail.Lifetime = props.lifetime or 0.5
	trail.MinLength = props.minLength or 0.1
	trail.WidthScale = if props.width then FxKit.seq(table.unpack(props.width)) else FxKit.seq(1, 0.2)
	trail.LightEmission = props.lightEmission or 0.6
	trail.LightInfluence = props.lightInfluence or 0
	trail.FaceCamera = props.faceCamera ~= false
	if props.texture then
		trail.Texture = FxKit.TEXTURES[props.texture] or props.texture
		trail.TextureMode = props.textureMode or Enum.TextureMode.Stretch
		trail.TextureLength = props.textureLength or 1
	end
	trail.Parent = a0.Parent
	self.maid:Add(trail)
	if props.movingOnly ~= false then
		table.insert(self.movingOnly, trail)
	end
	return trail
end

-- Convenience: two attachments around a body part plus a trail between them.
function FxKit.Ribbon(
	self: Kit,
	partName: string,
	halfWidth: number,
	axis: Vector3?,
	props
): (Trail?, Attachment?, Attachment?)
	local direction = axis or Vector3.new(0, 1, 0)
	local center = props.offset or Vector3.zero
	local a0 = self:Attachment(partName, CFrame.new(center + direction * halfWidth))
	local a1 = self:Attachment(partName, CFrame.new(center - direction * halfWidth))
	if not a0 or not a1 then
		return nil, nil, nil
	end
	return self:Trail(a0, a1, props), a0, a1
end

function FxKit.Emitter(self: Kit, parent: Instance, props): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	applyEmitterProps(emitter, props, self.q)
	emitter.Parent = parent
	self.maid:Add(emitter)
	if props.movingOnly then
		table.insert(self.movingOnly, emitter)
	end
	return emitter
end

function FxKit.Light(self: Kit, parent: Instance, color: Color3, range: number, brightness: number): PointLight?
	if not self.q.lights then
		return nil
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = parent
	self.maid:Add(light)
	return light
end

-- A cosmetic part: never collides, never queried, never touches, massless.
function FxKit.Part(self: Kit, props): BasePart
	local part = Instance.new((props.class or "Part") :: any) :: BasePart
	part.Name = props.name or "Cosmetic"
	if props.shape and part:IsA("Part") then
		(part :: Part).Shape = props.shape
	end
	part.Size = props.size or Vector3.new(1, 1, 1)
	part.Color = props.color or Color3.new(1, 1, 1)
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.Reflectance = props.reflectance or 0
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.Anchored = props.anchored == true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent or self.folder or workspace
	self.maid:Add(part)
	return part
end

-- Welds a cosmetic part to a body part at `offset` (relative to that part).
function FxKit.Weld(_self: Kit, part: BasePart, bodyPart: BasePart, offset: CFrame): Weld
	local weld = Instance.new("Weld")
	weld.Part0 = bodyPart
	weld.Part1 = part
	weld.C0 = offset
	weld.C1 = CFrame.new()
	weld.Parent = part
	part.CFrame = bodyPart.CFrame * offset
	return weld
end

-- Builds a set of parts described in a local frame and welds them all to a
-- body part. `pieces` = { { size, offset (CFrame), color, material, shape, transparency, class } }.
function FxKit.Rig(self: Kit, bodyPart: BasePart?, frame: CFrame, pieces): { BasePart }
	local parts = {}
	if not bodyPart then
		return parts
	end
	for _, piece in pieces do
		local part = self:Part({
			name = piece.name,
			size = piece.size,
			color = piece.color,
			material = piece.material,
			shape = piece.shape,
			transparency = piece.transparency,
			class = piece.class,
			reflectance = piece.reflectance,
		})
		self:Weld(part, bodyPart, frame * (piece.offset or CFrame.new()))
		table.insert(parts, part)
	end
	return parts
end

function FxKit.OnUpdate(self: Kit, fn: (dt: number, kit: any) -> ())
	table.insert(self.updaters, fn)
end

-- Called every frame by the renderer.
function FxKit.Update(self: Kit, dt: number)
	self.time += dt
	local root = self.root
	if root then
		local velocity = root.AssemblyLinearVelocity
		self.velocity = velocity
		self.speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
		self.verticalSpeed = velocity.Y
		self.grounded = self.humanoid ~= nil and self.humanoid.FloorMaterial ~= Enum.Material.Air
	end
	local moving = self.speed > 2 or math.abs(self.verticalSpeed or 0) > 4
	for _, item in self.movingOnly do
		if item.Parent then
			local enabled = moving and self.visible
			if item.Enabled ~= enabled then
				item.Enabled = enabled
			end
		end
	end
	for _, fn in self.updaters do
		local ok, err = pcall(fn, dt, self)
		if not ok then
			warn("[FxKit] updater error: " .. tostring(err))
			table.clear(self.updaters)
			break
		end
	end
end

function FxKit.SetVisible(self: Kit, visible: boolean)
	if self.visible == visible then
		return
	end
	self.visible = visible
	if self.folder then
		for _, d in self.folder:GetDescendants() do
			if d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
				d.Enabled = visible
			end
		end
	end
end

function FxKit.Destroy(self: Kit)
	table.clear(self.updaters)
	self.maid:Clean()
end

-- ===================================================== world-space glyph pool
-- Billboard text particles (♥ ★ ✿ ❄ ...). One shared pool for the whole
-- client, capped by quality so they can never pile up.
local glyphPool: { any } = {}
local activeGlyphs: { any } = {}
local glyphCap = 160
local glyphHost: Instance? = nil

local function host(): Instance
	if not glyphHost or not glyphHost.Parent then
		local terrain = workspace:FindFirstChildOfClass("Terrain")
		glyphHost = terrain or workspace
	end
	return glyphHost :: Instance
end

function FxKit.SetGlyphCap(cap: number)
	glyphCap = cap
end

function FxKit.SpawnGlyph(spec: {
	char: string,
	color: Color3,
	position: Vector3,
	velocity: Vector3,
	lifetime: number,
	size: number,
	spin: number?,
	fade: boolean?,
	font: Enum.Font?,
})
	if #activeGlyphs >= glyphCap then
		return
	end
	local glyph = table.remove(glyphPool)
	if not glyph then
		local attachment = Instance.new("Attachment")
		attachment.Name = "Glyph"
		local gui = Instance.new("BillboardGui")
		gui.LightInfluence = 0
		gui.AlwaysOnTop = false
		gui.Adornee = attachment
		gui.ResetOnSpawn = false
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.Parent = gui
		gui.Parent = attachment
		glyph = { attachment = attachment, gui = gui, label = label }
	end
	glyph.attachment.Parent = host()
	glyph.attachment.WorldPosition = spec.position
	glyph.gui.Size = UDim2.fromScale(spec.size, spec.size)
	glyph.gui.Enabled = true
	glyph.label.Text = spec.char
	glyph.label.TextColor3 = spec.color
	glyph.label.Font = spec.font or Enum.Font.GothamBlack
	glyph.label.TextTransparency = 0
	glyph.label.Rotation = 0
	glyph.position = spec.position
	glyph.velocity = spec.velocity
	glyph.life = spec.lifetime
	glyph.age = 0
	glyph.spin = spec.spin or 0
	glyph.fade = spec.fade ~= false
	table.insert(activeGlyphs, glyph)
end

-- ===================================================== world-space debris pool
local debrisPool: { [string]: { BasePart } } = {}
local activeDebris: { any } = {}
local debrisCap = 140
local debrisFolder: Folder? = nil

function FxKit.SetDebrisCap(cap: number)
	debrisCap = cap
end

local function debrisParent(): Folder
	if not debrisFolder or not debrisFolder.Parent then
		local folder = Instance.new("Folder")
		folder.Name = "DTTG_Debris"
		folder.Parent = workspace
		debrisFolder = folder
	end
	return debrisFolder :: Folder
end

function FxKit.SpawnDebris(spec: {
	shape: string?,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	position: Vector3,
	velocity: Vector3,
	lifetime: number,
	spin: Vector3?,
	gravity: number?,
	transparency: number?,
	cframe: CFrame?,
	grow: Vector3?,
})
	if #activeDebris >= debrisCap then
		return
	end
	local shape = spec.shape or "Block"
	local pool = debrisPool[shape]
	if not pool then
		pool = {}
		debrisPool[shape] = pool
	end
	local part = table.remove(pool)
	if not part then
		local created = Instance.new(if shape == "Wedge" then "WedgePart" else "Part") :: BasePart
		if shape == "Ball" and created:IsA("Part") then
			(created :: Part).Shape = Enum.PartType.Ball
		end
		created.Anchored = true
		created.CanCollide = false
		created.CanQuery = false
		created.CanTouch = false
		created.CastShadow = false
		created.Name = "Debris"
		part = created
	end
	local p = part :: BasePart
	p.Size = spec.size
	p.Color = spec.color
	p.Material = spec.material or Enum.Material.Neon
	p.Transparency = spec.transparency or 0
	p.CFrame = spec.cframe
		or (CFrame.new(spec.position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6))
	p.Parent = debrisParent()
	table.insert(activeDebris, {
		part = p,
		shape = shape,
		position = spec.position,
		velocity = spec.velocity,
		spin = spec.spin or (if spec.cframe
			then Vector3.zero
			else Vector3.new(math.random() * 6 - 3, math.random() * 6 - 3, math.random() * 6 - 3)),
		size = spec.size,
		grow = spec.grow,
		gravity = spec.gravity or 0,
		life = spec.lifetime,
		age = 0,
		baseTransparency = spec.transparency or 0,
		rotation = p.CFrame - p.CFrame.Position,
	})
end

-- A short-lived straight neon segment (lightning, streaks, grid lines).
function FxKit.SpawnSegment(
	from: Vector3,
	to: Vector3,
	thickness: number,
	color: Color3,
	lifetime: number,
	transparency: number?
)
	local length = (to - from).Magnitude
	if length < 0.05 then
		return
	end
	local mid = (from + to) / 2
	FxKit.SpawnDebris({
		size = Vector3.new(thickness, thickness, length),
		color = color,
		position = mid,
		velocity = Vector3.zero,
		lifetime = lifetime,
		cframe = CFrame.lookAt(mid, to),
		transparency = transparency,
	})
end

-- A jagged bolt from `from` to `to` made of segments.
function FxKit.SpawnBolt(
	from: Vector3,
	to: Vector3,
	color: Color3,
	lifetime: number,
	jitter: number?,
	segments: number?
)
	local count = segments or 5
	local previous = from
	for i = 1, count do
		local t = i / count
		local point = from:Lerp(to, t)
		if i < count then
			local j = jitter or 1
			point += Vector3.new((math.random() - 0.5) * j, (math.random() - 0.5) * j, (math.random() - 0.5) * j)
		end
		FxKit.SpawnSegment(previous, point, 0.18, color, lifetime)
		previous = point
	end
end

-- Steps the shared glyph and debris pools. Called once per frame.
function FxKit.StepPools(dt: number)
	for i = #activeGlyphs, 1, -1 do
		local glyph = activeGlyphs[i]
		glyph.age += dt
		if glyph.age >= glyph.life then
			glyph.gui.Enabled = false
			glyph.attachment.Parent = nil
			table.remove(activeGlyphs, i)
			table.insert(glyphPool, glyph)
		else
			glyph.position += glyph.velocity * dt
			glyph.attachment.WorldPosition = glyph.position
			if glyph.spin ~= 0 then
				glyph.label.Rotation += glyph.spin * dt
			end
			if glyph.fade then
				glyph.label.TextTransparency = math.clamp((glyph.age / glyph.life - 0.6) / 0.4, 0, 1)
			end
		end
	end
	for i = #activeDebris, 1, -1 do
		local d = activeDebris[i]
		d.age += dt
		if d.age >= d.life then
			d.part.Parent = nil
			table.remove(activeDebris, i)
			table.insert(debrisPool[d.shape], d.part)
		else
			d.velocity += Vector3.new(0, -d.gravity * dt, 0)
			d.position += d.velocity * dt
			d.rotation = d.rotation * CFrame.Angles(d.spin.X * dt, d.spin.Y * dt, d.spin.Z * dt)
			d.part.CFrame = CFrame.new(d.position) * d.rotation
			if d.grow then
				d.part.Size = d.size + d.grow * (d.age / d.life)
			end
			local fadeStart = 0.65
			local t = d.age / d.life
			if t > fadeStart then
				d.part.Transparency = d.baseTransparency + (1 - d.baseTransparency) * (t - fadeStart) / (1 - fadeStart)
			end
		end
	end
end

-- Streams: emit glyph/debris particles around a body part while moving.
function FxKit.GlyphStream(self: Kit, props)
	if self.q.glyphs <= 0 then
		return
	end
	local accumulator = 0
	local rate = (props.rate or 6) * self.q.glyphs
	self:OnUpdate(function(dt, kit)
		local moving = kit.speed > 2 or not props.movingOnly
		if not moving or not kit.visible then
			return
		end
		accumulator += dt * rate
		local part = kit:BodyPart(props.from or "HumanoidRootPart")
		while accumulator >= 1 and part do
			accumulator -= 1
			local spread = props.spread or 1.5
			local origin = part.CFrame.Position
				+ (props.offset or Vector3.zero)
				+ Vector3.new(
					(math.random() - 0.5) * spread * 2,
					(math.random() - 0.5) * spread,
					(math.random() - 0.5) * spread * 2
				)
			local colors = props.colors
			FxKit.SpawnGlyph({
				char = props.chars[math.random(1, #props.chars)],
				color = colors[math.random(1, #colors)],
				position = origin,
				velocity = (props.velocity or Vector3.new(0, 2, 0)) + Vector3.new(
					(math.random() - 0.5) * (props.jitter or 1),
					0,
					(math.random() - 0.5) * (props.jitter or 1)
				),
				lifetime = (props.lifetime or 1.2) * (0.8 + math.random() * 0.4),
				size = (props.size or 1) * (0.7 + math.random() * 0.6),
				spin = props.spin and (math.random() - 0.5) * props.spin or 0,
			})
		end
	end)
end

function FxKit.DebrisStream(self: Kit, props)
	local accumulator = 0
	local rate = (props.rate or 6) * self.q.debris
	if rate <= 0 then
		return
	end
	self:OnUpdate(function(dt, kit)
		local moving = kit.speed > 2 or not props.movingOnly
		if not moving or not kit.visible then
			return
		end
		accumulator += dt * rate
		local part = kit:BodyPart(props.from or "HumanoidRootPart")
		while accumulator >= 1 and part do
			accumulator -= 1
			local spread = props.spread or 1
			local colors = props.colors
			local size = props.size or Vector3.new(0.4, 0.4, 0.4)
			local scale = 0.7 + math.random() * 0.6
			FxKit.SpawnDebris({
				shape = props.shape,
				size = size * scale,
				color = colors[math.random(1, #colors)],
				material = props.material,
				transparency = props.transparency,
				position = part.CFrame.Position + (props.offset or Vector3.zero) + Vector3.new(
					(math.random() - 0.5) * spread * 2,
					(math.random() - 0.5) * spread,
					(math.random() - 0.5) * spread * 2
				),
				velocity = (props.velocity or Vector3.new(0, 1, 0)) + Vector3.new(
					(math.random() - 0.5) * (props.jitter or 2),
					(math.random() - 0.5) * (props.jitter or 2),
					(math.random() - 0.5) * (props.jitter or 2)
				),
				lifetime = (props.lifetime or 1) * (0.8 + math.random() * 0.4),
				gravity = props.gravity,
			})
		end
	end)
end

-- Objects orbiting the root part. `build(i)` returns a part to orbit.
function FxKit.Orbit(self: Kit, props)
	local count = props.count or 3
	local items = {}
	for i = 1, count do
		local part = props.build(i)
		part.Anchored = true
		table.insert(items, part)
	end
	self:OnUpdate(function(_dt, kit)
		local root = kit.root
		if not root then
			return
		end
		local t = kit.time * (props.speed or 1)
		local center = root.CFrame * CFrame.new(0, props.height or 0, 0)
		local tilt = props.tilt or CFrame.new()
		for i, part in items do
			local angle = t + (i - 1) / count * math.pi * 2
			local bob = if props.bob then math.sin(kit.time * 2 + i) * props.bob else 0
			local local_cf = tilt * CFrame.new(math.cos(angle) * props.radius, bob, math.sin(angle) * props.radius)
			local spinCF = if props.selfSpin
				then CFrame.Angles(kit.time * props.selfSpin, kit.time * props.selfSpin * 0.7, 0)
				else CFrame.new()
			part.CFrame = CFrame.new((center * local_cf).Position) * spinCF
		end
	end)
	return items
end

-- Flat neon ring of beams around a body part that can spin. Returns the hub attachment.
function FxKit.BeamRing(self: Kit, partName: string, props)
	local part = self:BodyPart(partName)
	if not part then
		return nil
	end
	local hub = Instance.new("Attachment")
	hub.Name = "DTTG_RingHub"
	hub.CFrame = props.offset or CFrame.new()
	hub.Parent = part
	self.maid:Add(hub)
	local segments = props.segments or 6
	local points = {}
	for i = 0, segments - 1 do
		local a = i / segments * math.pi * 2
		local attachment = Instance.new("Attachment")
		attachment.Position = Vector3.new(math.cos(a) * props.radius, 0, math.sin(a) * props.radius)
		attachment.Parent = part
		self.maid:Add(attachment)
		table.insert(points, { attachment = attachment, angle = a })
	end
	local beams = {}
	for i = 1, segments do
		local beam = Instance.new("Beam")
		beam.Attachment0 = points[i].attachment
		beam.Attachment1 = points[i % segments + 1].attachment
		beam.Color = if typeof(props.color) == "ColorSequence" then props.color else FxKit.colors(props.color)
		beam.Transparency = FxKit.seq(props.transparency or 0.2)
		beam.Width0 = props.width or 0.3
		beam.Width1 = props.width or 0.3
		beam.LightEmission = props.lightEmission or 1
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Segments = 4
		beam.Parent = part
		self.maid:Add(beam)
		table.insert(beams, beam)
	end
	local spin = props.spin or 0
	local wobble = props.wobble or 0
	self:OnUpdate(function(_dt, kit)
		local base = props.offset or CFrame.new()
		local yaw = kit.time * spin
		local tiltAngle = if wobble > 0 then math.sin(kit.time * 1.3) * wobble else 0
		for _, point in points do
			local a = point.angle + yaw
			local pos = Vector3.new(math.cos(a) * props.radius, 0, math.sin(a) * props.radius)
			point.attachment.Position = (base * CFrame.Angles(tiltAngle, 0, tiltAngle * 0.6) * CFrame.new(pos)).Position
		end
	end)
	return beams
end

-- Invisible welded part used as an emitter host (emitter shapes use the
-- host size: a flat disc at the feet, a box around the torso...).
function FxKit.Host(self: Kit, partName: string, size: Vector3, offset: CFrame?): BasePart?
	local body = self:BodyPart(partName)
	if not body then
		return nil
	end
	local host = self:Part({ name = "FxHost", size = size, transparency = 1 })
	self:Weld(host, body, offset or CFrame.new())
	return host
end

-- Billboard glyph stuck to a part (orbiting runes, floating icons).
function FxKit.Glyph(self: Kit, parent: Instance, char: string, color: Color3, size: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(size, size)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.MaxDistance = 120
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = char
	label.TextColor3 = color
	label.Parent = gui
	gui.Parent = parent
	self.maid:Add(gui)
	return label
end

-- Tweens helper (no-op safe when TweenService is mocked in tests).
function FxKit.tween(
	instance: Instance,
	seconds: number,
	goal: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
): Tween
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

FxKit.RunService = RunService

return FxKit
