--!nonstrict
-- Nameplate styles. Rarer titles get animated gradients, glow strokes and
-- orbiting sparkle glyphs; common ones stay clean and readable.

local Catalog = require(script.Parent.Parent.Config.CosmeticCatalog)
local RarityConfig = require(script.Parent.Parent.Config.RarityConfig)

local TitleStyles = {}

export type Style = {
	font: Enum.Font,
	colors: { Color3 },
	stroke: Color3,
	strokeThickness: number,
	animate: number, -- gradient rotation speed (deg/s), 0 = static
	shine: boolean,
	sparkles: string?,
	pulse: boolean,
}

local FONT_BY_RARITY = {
	Common = Enum.Font.GothamBold,
	Rare = Enum.Font.GothamBlack,
	Epic = Enum.Font.FredokaOne,
	Legendary = Enum.Font.LuckiestGuy,
	Mythic = Enum.Font.LuckiestGuy,
}

function TitleStyles.get(id: string?): (Style?, string?)
	local item = if id then Catalog.get(id) else nil
	if not item then
		return nil, nil
	end
	local rarity = RarityConfig.get(item.rarity)
	local order = rarity.order
	local style: Style = {
		font = FONT_BY_RARITY[item.rarity] or Enum.Font.GothamBold,
		colors = item.iconColors,
		stroke = item.iconColors[2]:Lerp(Color3.new(0, 0, 0), 0.6),
		strokeThickness = if order >= 4 then 2.5 else 1.5,
		animate = if order >= 5 then 90 elseif order >= 4 then 0 else 0,
		shine = order >= 3,
		sparkles = if order >= 5 then "✦" elseif order >= 4 then "★" else nil,
		pulse = order >= 4,
	}
	return style, item.name
end

return TitleStyles
