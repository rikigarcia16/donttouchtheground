--!nonstrict
-- Loads/unloads maps (procedural builders in Server/Maps) and applies each
-- map's lighting/atmosphere. Exposes the platform list to Hazard/Event services.

local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local MapConfig = require(Shared.Config.MapConfig)
local Prng = require(Shared.Util.Prng)
local PlatformFactory = require(script.Parent.Parent.Maps.PlatformFactory)

local MapService = {}

export type LoadedMap = {
	def: MapConfig.MapDef,
	model: Model,
	platformFolder: Folder,
	platforms: { BasePart },
	structures: { BasePart },
	spawns: { CFrame },
	palette: { { name: string, color: Color3 } },
	center: Vector3,
	radius: number,
	topY: number,
	baseY: number,
	factory: any,
}

local current: LoadedMap? = nil
local lastMapId: string? = nil

local atmosphere: Atmosphere
local bloom: BloomEffect
local color: ColorCorrectionEffect
local sunRays: SunRaysEffect

local LOBBY_LIGHTING = {
	clockTime = 14,
	brightness = 3,
	ambient = Color3.fromRGB(130, 130, 160),
	outdoorAmbient = Color3.fromRGB(170, 180, 220),
	fogColor = Color3.fromRGB(190, 220, 255),
	atmosphereDensity = 0.25,
	atmosphereColor = Color3.fromRGB(200, 225, 255),
	atmosphereDecay = Color3.fromRGB(255, 190, 220),
	atmosphereHaze = 1,
	bloomIntensity = 0.6,
	tint = Color3.fromRGB(255, 252, 255),
	saturation = 0.2,
	contrast = 0.06,
}

local function ensure<T>(className: string, name: string): T
	local existing = Lighting:FindFirstChild(name)
	if existing then
		return existing :: any
	end
	local instance = Instance.new(className :: any)
	instance.Name = name
	instance.Parent = Lighting
	return instance :: any
end

function MapService.ApplyLighting(preset)
	Lighting.ClockTime = preset.clockTime
	Lighting.Brightness = preset.brightness
	Lighting.Ambient = preset.ambient
	Lighting.OutdoorAmbient = preset.outdoorAmbient
	Lighting.FogColor = preset.fogColor
	Lighting.FogEnd = 100000
	atmosphere.Density = preset.atmosphereDensity
	atmosphere.Color = preset.atmosphereColor
	atmosphere.Decay = preset.atmosphereDecay
	atmosphere.Haze = preset.atmosphereHaze
	atmosphere.Glare = 0.2
	bloom.Intensity = preset.bloomIntensity
	bloom.Size = 28
	bloom.Threshold = 1.6
	color.TintColor = preset.tint
	color.Saturation = preset.saturation
	color.Contrast = preset.contrast
	color.Brightness = 0.02
end

function MapService.ApplyLobbyLighting()
	MapService.ApplyLighting(LOBBY_LIGHTING)
end

function MapService.PickOptions(count: number): { string }
	local pool = {}
	for _, def in MapConfig.List do
		if def.id ~= lastMapId then
			table.insert(pool, def.id)
		end
	end
	local rng = Prng.new(os.time() + math.random(1, 100000))
	local shuffled = rng:Shuffle(pool)
	local options = {}
	for i = 1, math.min(count, #shuffled) do
		table.insert(options, shuffled[i])
	end
	return options
end

function MapService.Unload()
	if current then
		current.model:Destroy()
		current = nil
	end
	MapService.ApplyLobbyLighting()
end

function MapService.Load(mapId: string): LoadedMap
	MapService.Unload()
	local def = MapConfig.ById[mapId]
	assert(def, "Unknown map " .. mapId)
	local builderModule = script.Parent.Parent.Maps:FindFirstChild(def.builder)
	assert(builderModule, "Missing builder " .. def.builder)
	local builder = require(builderModule) :: any

	local model = Instance.new("Model")
	model.Name = "Map"
	model:SetAttribute("MapId", def.id)
	model:SetAttribute("LavaColor", def.lavaColor)
	local platformFolder = Instance.new("Folder")
	platformFolder.Name = "Platforms"
	platformFolder.Parent = model
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = model

	local origin = GameConfig.World.MapOrigin
	local factory = PlatformFactory.new(platformFolder, { Color3.new(1, 1, 1) })
	local structures: { BasePart } = {}
	local result = builder({
		origin = origin,
		platforms = factory,
		decor = decor,
		structures = structures,
		rng = Prng.new(os.time()),
		def = def,
	})

	model:SetAttribute("BaseY", origin.Position.Y)
	model:SetAttribute("TopY", result.topY)
	model:SetAttribute("Radius", result.radius)
	local paletteNames = {}
	for i, entry in result.palette do
		model:SetAttribute("Palette" .. i, entry.color)
		paletteNames[i] = entry.name
	end
	model:SetAttribute("PaletteNames", table.concat(paletteNames, ","))
	model.Parent = workspace

	current = {
		def = def,
		model = model,
		platformFolder = platformFolder,
		platforms = factory.platforms,
		structures = structures,
		spawns = result.spawns,
		palette = result.palette,
		center = result.center,
		radius = result.radius,
		topY = result.topY,
		baseY = origin.Position.Y,
		factory = factory,
	}
	lastMapId = def.id
	MapService.ApplyLighting(def.lighting)
	return current :: LoadedMap
end

function MapService.Current(): LoadedMap?
	return current
end

function MapService.Init()
	atmosphere = ensure("Atmosphere", "DTTG_Atmosphere")
	bloom = ensure("BloomEffect", "DTTG_Bloom")
	color = ensure("ColorCorrectionEffect", "DTTG_Color")
	sunRays = ensure("SunRaysEffect", "DTTG_SunRays")
	sunRays.Intensity = 0.05
	sunRays.Spread = 0.6
	if not Lighting:FindFirstChildOfClass("Sky") then
		local sky = Instance.new("Sky")
		sky.Name = "DTTG_Sky"
		sky.CelestialBodiesShown = true
		sky.StarCount = 3000
		sky.Parent = Lighting
	end
	MapService.ApplyLobbyLighting()
end

return MapService
