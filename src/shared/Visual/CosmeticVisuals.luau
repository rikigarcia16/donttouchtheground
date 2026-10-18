--!nonstrict
-- Index from catalogue category to its visual implementation table.

local TrailVisuals = require(script.Parent.TrailVisuals)
local AuraVisuals = require(script.Parent.AuraVisuals)
local AccessoryModels = require(script.Parent.AccessoryModels)
local Bursts = require(script.Parent.Bursts)
local EmoteLibrary = require(script.Parent.EmoteLibrary)
local WinScenes = require(script.Parent.WinScenes)
local TitleStyles = require(script.Parent.TitleStyles)

local CosmeticVisuals = {
	Trail = TrailVisuals,
	Aura = AuraVisuals,
	Accessory = AccessoryModels,
	JumpEffect = Bursts.Jump,
	LandingEffect = Bursts.Land,
	DeathEffect = Bursts.Death,
	WinAnimation = WinScenes.Effects,
	Podium = WinScenes.Podiums,
	Emote = EmoteLibrary.Animations,
}

-- True when the item has a working visual definition.
function CosmeticVisuals.has(item): boolean
	if item.category == "Title" then
		return TitleStyles.get(item.id) ~= nil
	end
	if item.category == "WinAnimation" then
		return WinScenes.Effects[item.id] ~= nil and EmoteLibrary.Animations[item.id] ~= nil
	end
	local map = CosmeticVisuals[item.category]
	return map ~= nil and map[item.id] ~= nil
end

CosmeticVisuals.Bursts = Bursts
CosmeticVisuals.EmoteLibrary = EmoteLibrary
CosmeticVisuals.WinScenes = WinScenes
CosmeticVisuals.TitleStyles = TitleStyles

return CosmeticVisuals
