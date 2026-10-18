--!nonstrict
-- Effect quality: Auto picks Low on small/touch devices with low graphics
-- settings, Medium on mobile, High elsewhere. Scales every ambient emitter,
-- the glyph/debris pools and burst counts.

local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local FxKit = require(Shared.Visual.FxKit)
local Bursts = require(Shared.Visual.Bursts)
local Signal = require(Shared.Util.Signal)

local QualityController = {}
QualityController.Changed = Signal.new()
QualityController.level = "High"

local function autoLevel(): string
	local ok, savedLevel = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	local graphics = if ok then savedLevel else 0
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return if graphics > 0 and graphics <= 3 then "Low" else "Medium"
	end
	if graphics > 0 and graphics <= 2 then
		return "Low"
	elseif graphics > 0 and graphics <= 5 then
		return "Medium"
	end
	return "High"
end

function QualityController.Get()
	return GameConfig.Quality[QualityController.level]
end

local function scaleEmitters(root: Instance)
	local q = QualityController.Get()
	for _, d in root:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			local base = d:GetAttribute("BaseRate")
			if type(base) == "number" then
				d.Rate = base * q.particles
			end
		end
	end
end

function QualityController.Set(setting: string)
	QualityController.level = if setting == "Auto" then autoLevel() else setting
	local q = QualityController.Get()
	FxKit.SetGlyphCap(math.floor(160 * q.glyphs))
	FxKit.SetDebrisCap(math.floor(140 * q.debris))
	Bursts.quality = q
	scaleEmitters(workspace)
	QualityController.Changed:Fire(QualityController.level)
end

function QualityController.Start()
	QualityController.Set("Auto")
	-- New maps / lobby content get scaled as they stream in.
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("ParticleEmitter") then
			task.defer(function()
				local base = d:GetAttribute("BaseRate")
				if type(base) == "number" then
					d.Rate = base * QualityController.Get().particles
				end
			end)
		end
	end)
end

return QualityController
