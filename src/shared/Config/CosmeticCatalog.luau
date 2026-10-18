--!strict
-- Single source of truth for every cosmetic. Ids are stable forever: they are
-- what the DataStore saves. To add a cosmetic: add an entry here and a visual
-- definition with the same id in Shared/Visual (the test suite enforces both).

-- "Trail" | "Aura" | "JumpEffect" | "LandingEffect" | "WinAnimation" |
-- "DeathEffect" | "Emote" | "Accessory" | "Title" | "Podium"
export type Category = string

-- kind: "Shop" | "Default" | "Achievement" (id) | "Collection" (id) | "Level" (level)
export type Unlock = { kind: string, id: string?, level: number? }

export type Item = {
	id: string,
	name: string,
	category: Category,
	rarity: string,
	price: number?,
	currency: string, -- "Wins" | "Coins"
	unlock: Unlock,
	description: string,
	icon: string,
	iconColors: { Color3 },
	collection: string?,
	slot: string?, -- accessory slot
	order: number,
}

local RGB = Color3.fromRGB

local CATEGORY_INFO: { { id: string, name: string, icon: string, equipSlot: string? } } = {
	{ id = "Trail", name = "Trails", icon = "💫", equipSlot = "Trail" },
	{ id = "Aura", name = "Auras", icon = "🌀", equipSlot = "Aura" },
	{ id = "JumpEffect", name = "Jump FX", icon = "⏫", equipSlot = "JumpEffect" },
	{ id = "LandingEffect", name = "Landing FX", icon = "💥", equipSlot = "LandingEffect" },
	{ id = "DeathEffect", name = "Elimination FX", icon = "✨", equipSlot = "DeathEffect" },
	{ id = "WinAnimation", name = "Victory", icon = "🏆", equipSlot = "WinAnimation" },
	{ id = "Emote", name = "Emotes", icon = "🕺", equipSlot = nil },
	{ id = "Accessory", name = "Accessories", icon = "👑", equipSlot = "Accessories" },
	{ id = "Title", name = "Titles", icon = "🏷️", equipSlot = "Title" },
	{ id = "Podium", name = "Podiums", icon = "🏛️", equipSlot = "Podium" },
}

local items: { Item } = {}
local byId: { [string]: Item } = {}

local function add(category: Category, def: { [string]: any })
	assert(byId[def.id] == nil, "Duplicate cosmetic id " .. def.id)
	local unlock: Unlock = def.unlock or (if def.price then { kind = "Shop" } else { kind = "Default" })
	local item: Item = {
		id = def.id,
		name = def.name,
		category = category,
		rarity = def.rarity,
		price = def.price,
		currency = def.currency or "Wins",
		unlock = unlock,
		description = def.desc,
		icon = def.icon,
		iconColors = def.colors or { RGB(255, 255, 255), RGB(200, 200, 200) },
		collection = def.collection,
		slot = def.slot,
		order = #items + 1,
	}
	table.insert(items, item)
	byId[item.id] = item
end

-- ===================================================================== TRAILS
local T = "Trail" :: Category
add(T, {
	id = "trail_white",
	name = "White Trail",
	rarity = "Common",
	price = 2,
	icon = "🤍",
	desc = "A clean ribbon of light that follows every step.",
	colors = { RGB(255, 255, 255), RGB(190, 210, 230) },
})
add(T, {
	id = "trail_blue_energy",
	name = "Blue Energy",
	rarity = "Common",
	price = 4,
	icon = "🔷",
	desc = "Crackling cyan energy with floating sparks.",
	colors = { RGB(40, 200, 255), RGB(20, 90, 255) },
})
add(T, {
	id = "trail_bubble",
	name = "Bubble Trail",
	rarity = "Common",
	price = 5,
	icon = "🫧",
	desc = "Glassy bubbles that drift upward and pop.",
	colors = { RGB(170, 240, 255), RGB(120, 160, 255) },
})
add(T, {
	id = "trail_fire",
	name = "Fire Trail",
	rarity = "Rare",
	price = 8,
	icon = "🔥",
	desc = "Real flames licking at your heels.",
	collection = "Fire",
	colors = { RGB(255, 140, 0), RGB(255, 40, 0) },
})
add(T, {
	id = "trail_ice",
	name = "Ice Trail",
	rarity = "Rare",
	price = 8,
	icon = "❄️",
	desc = "Frosty ribbon with snowflakes and ice chips.",
	collection = "Frozen",
	colors = { RGB(200, 245, 255), RGB(90, 180, 255) },
})
add(T, {
	id = "trail_toxic",
	name = "Toxic Smoke",
	rarity = "Rare",
	price = 10,
	icon = "☣️",
	desc = "Bubbling green smog. Totally harmless. Probably.",
	colors = { RGB(140, 255, 60), RGB(40, 140, 20) },
})
add(T, {
	id = "trail_rainbow",
	name = "Rainbow Trail",
	rarity = "Rare",
	price = 12,
	icon = "🌈",
	desc = "A shimmering band that cycles through every colour.",
	collection = "Rainbow",
	colors = { RGB(255, 80, 80), RGB(80, 160, 255) },
})
add(T, {
	id = "trail_heart",
	name = "Heart Trail",
	rarity = "Rare",
	price = 14,
	icon = "💖",
	desc = "Floating hearts for every friend you leave behind.",
	colors = { RGB(255, 110, 170), RGB(255, 40, 100) },
})
add(T, {
	id = "trail_pixel",
	name = "Pixel Trail",
	rarity = "Epic",
	price = 18,
	icon = "👾",
	desc = "Chunky 8-bit pixels tumble out of thin air.",
	collection = "Cyber",
	colors = { RGB(0, 255, 170), RGB(255, 0, 200) },
})
add(T, {
	id = "trail_lightning",
	name = "Lightning Trail",
	rarity = "Epic",
	price = 20,
	icon = "⚡",
	desc = "Jagged bolts arc between your footsteps.",
	colors = { RGB(255, 255, 120), RGB(120, 160, 255) },
})
add(T, {
	id = "trail_sakura",
	name = "Sakura Petals",
	rarity = "Epic",
	price = 22,
	icon = "🌸",
	desc = "Cherry blossom petals flutter in your wake.",
	colors = { RGB(255, 190, 220), RGB(255, 120, 170) },
})
add(T, {
	id = "trail_golden_dust",
	name = "Golden Dust",
	rarity = "Epic",
	price = 28,
	icon = "✨",
	desc = "Glittering gold that hangs in the air.",
	collection = "Royal",
	colors = { RGB(255, 230, 120), RGB(230, 160, 20) },
})
add(T, {
	id = "trail_shadow",
	name = "Shadow Trail",
	rarity = "Epic",
	price = 30,
	icon = "🌑",
	desc = "Inky wisps that swallow the light behind you.",
	collection = "Void",
	colors = { RGB(80, 60, 110), RGB(10, 0, 25) },
})
add(T, {
	id = "trail_lava_sparks",
	name = "Lava Sparks",
	rarity = "Epic",
	price = 35,
	icon = "🌋",
	desc = "Molten droplets and sparks. The floor IS lava.",
	collection = "Fire",
	colors = { RGB(255, 170, 40), RGB(200, 30, 0) },
})
add(T, {
	id = "trail_neon_grid",
	name = "Neon Grid",
	rarity = "Legendary",
	price = 45,
	icon = "🟪",
	desc = "Glowing grid tiles light up wherever you step.",
	collection = "Cyber",
	colors = { RGB(255, 0, 230), RGB(0, 240, 255) },
})
add(T, {
	id = "trail_galaxy",
	name = "Galaxy Trail",
	rarity = "Legendary",
	price = 55,
	icon = "🌌",
	desc = "A nebula ribbon sprinkled with twinkling stars.",
	collection = "Galaxy",
	colors = { RGB(140, 60, 255), RGB(30, 20, 120) },
})
add(T, {
	id = "trail_crystal",
	name = "Crystal Fragments",
	rarity = "Legendary",
	price = 60,
	icon = "💎",
	desc = "Prismatic crystal shards spin off your body.",
	colors = { RGB(160, 255, 255), RGB(220, 120, 255) },
})
add(T, {
	id = "trail_cosmic_stars",
	name = "Cosmic Stars",
	rarity = "Legendary",
	price = 75,
	icon = "🌠",
	desc = "Shooting stars that streak and fade in every colour.",
	collection = "Galaxy",
	colors = { RGB(255, 240, 150), RGB(120, 90, 255) },
})
add(T, {
	id = "trail_phantom",
	name = "Phantom Trail",
	rarity = "Legendary",
	price = 90,
	icon = "👻",
	desc = "Ghostly afterimages of yourself chase you around.",
	collection = "Void",
	colors = { RGB(150, 230, 255), RGB(110, 70, 255) },
})
add(T, {
	id = "trail_dragon_fire",
	name = "Legendary Dragon Fire",
	rarity = "Mythic",
	price = 150,
	icon = "🐉",
	desc = "Twin spiralling flames, roaring embers and dragon scales.",
	collection = "Fire",
	colors = { RGB(255, 210, 60), RGB(255, 30, 0) },
})
add(T, {
	id = "trail_aurora",
	name = "Aurora Trail",
	rarity = "Legendary",
	icon = "🌠",
	desc = "Northern lights for seasoned climbers. Reach level 40.",
	unlock = { kind = "Level", level = 40 },
	colors = { RGB(60, 255, 170), RGB(120, 80, 255) },
})

-- ====================================================================== AURAS
local A = "Aura" :: Category
add(A, {
	id = "aura_flame",
	name = "Flame Aura",
	rarity = "Rare",
	price = 10,
	icon = "🔥",
	desc = "A ring of dancing flames around your feet.",
	collection = "Fire",
	colors = { RGB(255, 150, 20), RGB(255, 50, 0) },
})
add(A, {
	id = "aura_frozen",
	name = "Frozen Aura",
	rarity = "Rare",
	price = 12,
	icon = "🧊",
	desc = "Frost mist and orbiting snowflakes.",
	collection = "Frozen",
	colors = { RGB(200, 250, 255), RGB(80, 170, 255) },
})
add(A, {
	id = "aura_toxic",
	name = "Toxic Aura",
	rarity = "Rare",
	price = 14,
	icon = "🧪",
	desc = "Bubbling green fumes rise around you.",
	colors = { RGB(160, 255, 60), RGB(50, 160, 30) },
})
add(A, {
	id = "aura_thunder",
	name = "Thunder Aura",
	rarity = "Epic",
	price = 25,
	icon = "🌩️",
	desc = "Static arcs snap across your body.",
	colors = { RGB(255, 255, 140), RGB(90, 140, 255) },
})
add(A, {
	id = "aura_cyber",
	name = "Cyber Aura",
	rarity = "Epic",
	price = 28,
	icon = "💠",
	desc = "Scanning hex rings and drifting binary code.",
	collection = "Cyber",
	colors = { RGB(0, 255, 220), RGB(255, 0, 200) },
})
add(A, {
	id = "aura_shadow",
	name = "Shadow Aura",
	rarity = "Epic",
	price = 30,
	icon = "🌚",
	desc = "Dark smoke curls around you like a cloak.",
	collection = "Void",
	colors = { RGB(90, 60, 130), RGB(15, 5, 30) },
})
add(A, {
	id = "aura_golden",
	name = "Golden Aura",
	rarity = "Epic",
	price = 35,
	icon = "🌟",
	desc = "A warm golden glow with rising sparkles.",
	collection = "Royal",
	colors = { RGB(255, 235, 120), RGB(255, 170, 20) },
})
add(A, {
	id = "aura_rainbow",
	name = "Rainbow Aura",
	rarity = "Epic",
	price = 38,
	icon = "🌈",
	desc = "Colour-cycling rings spin around you.",
	collection = "Rainbow",
	colors = { RGB(255, 90, 90), RGB(90, 200, 255) },
})
add(A, {
	id = "aura_crystal",
	name = "Crystal Aura",
	rarity = "Legendary",
	price = 50,
	icon = "🔮",
	desc = "Floating crystals orbit you in formation.",
	collection = "Frozen",
	colors = { RGB(170, 255, 255), RGB(200, 120, 255) },
})
add(A, {
	id = "aura_galaxy",
	name = "Galaxy Aura",
	rarity = "Legendary",
	price = 60,
	icon = "🌌",
	desc = "A swirling nebula with orbiting planets.",
	collection = "Galaxy",
	colors = { RGB(150, 70, 255), RGB(40, 30, 140) },
})
add(A, {
	id = "aura_angelic",
	name = "Angelic Aura",
	rarity = "Legendary",
	price = 70,
	icon = "😇",
	desc = "A halo, soft light rays and drifting feathers.",
	colors = { RGB(255, 255, 230), RGB(255, 220, 140) },
})
add(A, {
	id = "aura_demonic",
	name = "Infernal Aura",
	rarity = "Legendary",
	price = 70,
	icon = "😈",
	desc = "Crimson embers and a smouldering dark ring.",
	collection = "Fire",
	colors = { RGB(255, 40, 60), RGB(70, 0, 20) },
})
add(A, {
	id = "aura_void",
	name = "Void Aura",
	rarity = "Mythic",
	price = 180,
	icon = "🕳️",
	desc = "A miniature black hole devours the light around you.",
	collection = "Void",
	colors = { RGB(120, 60, 255), RGB(0, 0, 0) },
})
add(A, {
	id = "aura_solar",
	name = "Solar Aura",
	rarity = "Mythic",
	price = 200,
	icon = "☀️",
	desc = "Your own tiny sun, corona flares included.",
	colors = { RGB(255, 240, 120), RGB(255, 110, 0) },
})
add(A, {
	id = "aura_ancient_king",
	name = "Ancient King Aura",
	rarity = "Mythic",
	price = 250,
	icon = "🔱",
	desc = "Orbiting golden runes and a crown of light. Bow down.",
	collection = "Royal",
	colors = { RGB(255, 220, 90), RGB(150, 60, 255) },
})
add(A, {
	id = "aura_veteran",
	name = "Veteran Glow",
	rarity = "Epic",
	icon = "🎖️",
	desc = "A steady glow earned by reaching level 20.",
	unlock = { kind = "Level", level = 20 },
	colors = { RGB(120, 255, 160), RGB(30, 130, 90) },
})
add(A, {
	id = "aura_centennial",
	name = "Centennial Aura",
	rarity = "Mythic",
	icon = "💯",
	desc = "Reserved for level 100 legends.",
	unlock = { kind = "Level", level = 100 },
	colors = { RGB(255, 255, 255), RGB(255, 90, 200) },
})

-- =============================================================== JUMP EFFECTS
local J = "JumpEffect" :: Category
add(J, {
	id = "jump_smoke_puff",
	name = "Smoke Puff",
	rarity = "Common",
	price = 2,
	icon = "💨",
	desc = "A cartoon puff of smoke at take-off.",
	colors = { RGB(230, 230, 240), RGB(150, 150, 170) },
})
add(J, {
	id = "jump_star_burst",
	name = "Star Burst",
	rarity = "Common",
	price = 3,
	icon = "⭐",
	desc = "A pop of tiny stars.",
	colors = { RGB(255, 240, 100), RGB(255, 170, 0) },
})
add(J, {
	id = "jump_frost_burst",
	name = "Frost Burst",
	rarity = "Rare",
	price = 8,
	icon = "❄️",
	desc = "A ring of frost bursts beneath you.",
	collection = "Frozen",
	colors = { RGB(210, 250, 255), RGB(100, 190, 255) },
})
add(J, {
	id = "jump_fire_ring",
	name = "Fire Ring",
	rarity = "Rare",
	price = 9,
	icon = "⭕",
	desc = "A blazing ring expands from your feet.",
	collection = "Fire",
	colors = { RGB(255, 170, 0), RGB(255, 40, 0) },
})
add(J, {
	id = "jump_pixel",
	name = "Pixel Explosion",
	rarity = "Rare",
	price = 10,
	icon = "🟩",
	desc = "Retro pixels scatter in all directions.",
	collection = "Cyber",
	colors = { RGB(0, 255, 140), RGB(0, 160, 255) },
})
add(J, {
	id = "jump_rainbow_wave",
	name = "Rainbow Wave",
	rarity = "Epic",
	price = 18,
	icon = "🌈",
	desc = "Concentric rainbow rings ripple outward.",
	collection = "Rainbow",
	colors = { RGB(255, 100, 100), RGB(100, 255, 160) },
})
add(J, {
	id = "jump_lightning",
	name = "Lightning Bolt",
	rarity = "Epic",
	price = 20,
	icon = "⚡",
	desc = "A bolt strikes where you jumped.",
	colors = { RGB(255, 255, 150), RGB(110, 150, 255) },
})
add(J, {
	id = "jump_crystals",
	name = "Crystal Spikes",
	rarity = "Epic",
	price = 24,
	icon = "💎",
	desc = "Crystal spikes erupt from the ground.",
	colors = { RGB(160, 250, 255), RGB(210, 130, 255) },
})
add(J, {
	id = "jump_void_pulse",
	name = "Void Pulse",
	rarity = "Epic",
	price = 30,
	icon = "🟣",
	desc = "An imploding pulse of dark energy.",
	collection = "Void",
	colors = { RGB(140, 70, 255), RGB(20, 0, 50) },
})
add(J, {
	id = "jump_magic_portal",
	name = "Magic Portal",
	rarity = "Legendary",
	price = 45,
	icon = "🌀",
	desc = "A spinning rune portal launches you upward.",
	colors = { RGB(200, 120, 255), RGB(70, 220, 255) },
})
add(J, {
	id = "jump_cosmic",
	name = "Cosmic Jump",
	rarity = "Legendary",
	price = 60,
	icon = "🌌",
	desc = "A galactic explosion of stars and nebula.",
	collection = "Galaxy",
	colors = { RGB(170, 90, 255), RGB(255, 240, 150) },
})
add(J, {
	id = "jump_light_wings",
	name = "Wings of Light",
	rarity = "Mythic",
	price = 120,
	icon = "🪽",
	desc = "Radiant wings unfold for a moment on every jump.",
	colors = { RGB(255, 255, 230), RGB(130, 220, 255) },
})
add(J, {
	id = "jump_rank_ring",
	name = "Rank Ring",
	rarity = "Rare",
	icon = "🔰",
	desc = "A ring of honour, unlocked at level 10.",
	unlock = { kind = "Level", level = 10 },
	colors = { RGB(120, 220, 255), RGB(255, 255, 255) },
})

-- ============================================================ LANDING EFFECTS
local L = "LandingEffect" :: Category
add(L, {
	id = "land_energy_wave",
	name = "Energy Wave",
	rarity = "Common",
	price = 3,
	icon = "〰️",
	desc = "A clean shockwave ring on impact.",
	colors = { RGB(120, 230, 255), RGB(255, 255, 255) },
})
add(L, {
	id = "land_confetti",
	name = "Confetti Pop",
	rarity = "Common",
	price = 4,
	icon = "🎉",
	desc = "Party time, every single landing.",
	colors = { RGB(255, 90, 160), RGB(90, 220, 255) },
})
add(L, {
	id = "land_ink",
	name = "Ink Splash",
	rarity = "Rare",
	price = 7,
	icon = "🖋️",
	desc = "A splat of glossy cartoon ink.",
	colors = { RGB(70, 40, 160), RGB(20, 10, 60) },
})
add(L, {
	id = "land_neon_pulse",
	name = "Neon Pulse",
	rarity = "Rare",
	price = 9,
	icon = "🔲",
	desc = "A square neon pulse scans the floor.",
	collection = "Cyber",
	colors = { RGB(255, 0, 230), RGB(0, 255, 240) },
})
add(L, {
	id = "land_glow_cracks",
	name = "Glowing Cracks",
	rarity = "Rare",
	price = 10,
	icon = "🪨",
	desc = "The ground cracks with glowing light.",
	colors = { RGB(255, 200, 80), RGB(255, 90, 0) },
})
add(L, {
	id = "land_rainbow_splash",
	name = "Rainbow Splash",
	rarity = "Rare",
	price = 11,
	icon = "🎨",
	desc = "A splash of paint in every colour.",
	collection = "Rainbow",
	colors = { RGB(255, 80, 80), RGB(80, 120, 255) },
})
add(L, {
	id = "land_ice_shatter",
	name = "Ice Shatter",
	rarity = "Rare",
	price = 12,
	icon = "🧊",
	desc = "Shards of ice explode on impact.",
	collection = "Frozen",
	colors = { RGB(220, 250, 255), RGB(110, 200, 255) },
})
add(L, {
	id = "land_flame_ring",
	name = "Ring of Flames",
	rarity = "Epic",
	price = 22,
	icon = "🔥",
	desc = "A crown of flames bursts around you.",
	colors = { RGB(255, 180, 30), RGB(255, 40, 0) },
})
add(L, {
	id = "land_meteor",
	name = "Meteor Impact",
	rarity = "Epic",
	price = 26,
	icon = "☄️",
	desc = "Land like a meteorite: crater, dust and sparks.",
	collection = "Fire",
	colors = { RGB(255, 140, 40), RGB(120, 60, 40) },
})
add(L, {
	id = "land_star",
	name = "Star Landing",
	rarity = "Epic",
	price = 30,
	icon = "🌟",
	desc = "A star-shaped flash and twinkles.",
	collection = "Galaxy",
	colors = { RGB(255, 245, 160), RGB(170, 120, 255) },
})
add(L, {
	id = "land_royal_crest",
	name = "Royal Crest",
	rarity = "Legendary",
	price = 50,
	icon = "⚜️",
	desc = "A golden crest stamps the ground.",
	collection = "Royal",
	colors = { RGB(255, 225, 100), RGB(170, 90, 20) },
})
add(L, {
	id = "land_black_hole",
	name = "Mini Black Hole",
	rarity = "Legendary",
	price = 65,
	icon = "🕳️",
	desc = "A tiny (cosmetic!) black hole sucks in the light.",
	collection = "Void",
	colors = { RGB(120, 60, 255), RGB(0, 0, 0) },
})

-- ============================================================= DEATH EFFECTS
local D = "DeathEffect" :: Category
add(D, {
	id = "death_confetti",
	name = "Confetti Blast",
	rarity = "Common",
	price = 3,
	icon = "🎊",
	desc = "Go out with a party.",
	colors = { RGB(255, 100, 180), RGB(100, 220, 255) },
})
add(D, {
	id = "death_color_smoke",
	name = "Colour Smoke",
	rarity = "Common",
	price = 4,
	icon = "🌫️",
	desc = "Vanish in a puff of colourful smoke.",
	colors = { RGB(255, 150, 220), RGB(150, 180, 255) },
})
add(D, {
	id = "death_pixels",
	name = "Pixel Disintegration",
	rarity = "Rare",
	price = 8,
	icon = "🟦",
	desc = "Break apart into floating pixels.",
	collection = "Cyber",
	colors = { RGB(0, 230, 255), RGB(0, 120, 255) },
})
add(D, {
	id = "death_ember",
	name = "Ember Burst",
	rarity = "Rare",
	price = 9,
	icon = "🔥",
	desc = "A burst of rising embers.",
	collection = "Fire",
	colors = { RGB(255, 170, 40), RGB(255, 60, 0) },
})
add(D, {
	id = "death_rainbow",
	name = "Rainbow Pop",
	rarity = "Rare",
	price = 10,
	icon = "🌈",
	desc = "Pop like a rainbow balloon.",
	collection = "Rainbow",
	colors = { RGB(255, 90, 90), RGB(90, 160, 255) },
})
add(D, {
	id = "death_teleport",
	name = "Teleport Out",
	rarity = "Rare",
	price = 12,
	icon = "🛸",
	desc = "Beamed up just in time.",
	colors = { RGB(120, 255, 230), RGB(60, 120, 255) },
})
add(D, {
	id = "death_crystal",
	name = "Crystal Shatter",
	rarity = "Epic",
	price = 22,
	icon = "💠",
	desc = "Shatter into glittering crystal.",
	collection = "Frozen",
	colors = { RGB(180, 250, 255), RGB(120, 160, 255) },
})
add(D, {
	id = "death_retro",
	name = "Retro Game Over",
	rarity = "Epic",
	price = 25,
	icon = "🕹️",
	desc = "8-bit GAME OVER, insert coin to continue.",
	colors = { RGB(255, 60, 60), RGB(255, 230, 60) },
})
add(D, {
	id = "death_void",
	name = "Void Collapse",
	rarity = "Epic",
	price = 35,
	icon = "⚫",
	desc = "Fold into a point and disappear.",
	collection = "Void",
	colors = { RGB(130, 60, 255), RGB(10, 0, 30) },
})
add(D, {
	id = "death_stardust",
	name = "Stellar Fade",
	rarity = "Legendary",
	price = 48,
	icon = "🌠",
	desc = "Dissolve into a cloud of stardust.",
	collection = "Galaxy",
	colors = { RGB(255, 240, 170), RGB(150, 100, 255) },
})
add(D, {
	id = "death_cosmic_ray",
	name = "Cosmic Ray",
	rarity = "Legendary",
	price = 60,
	icon = "🔆",
	desc = "A beam from the heavens lifts you away.",
	colors = { RGB(255, 255, 220), RGB(120, 200, 255) },
})

-- ============================================================ WIN ANIMATIONS
local W = "WinAnimation" :: Category
add(W, {
	id = "win_victory_dance",
	name = "Victory Dance",
	rarity = "Common",
	price = 5,
	icon = "💃",
	desc = "Bust a move on the podium.",
	colors = { RGB(255, 160, 60), RGB(255, 80, 160) },
})
add(W, {
	id = "win_backflip",
	name = "Backflip",
	rarity = "Rare",
	price = 10,
	icon = "🤸",
	desc = "A clean backflip with a dust landing.",
	colors = { RGB(120, 220, 255), RGB(60, 120, 255) },
})
add(W, {
	id = "win_crown",
	name = "Crown Celebration",
	rarity = "Rare",
	price = 12,
	icon = "👑",
	desc = "A crown descends from the sky onto your head.",
	collection = "Royal",
	colors = { RGB(255, 225, 90), RGB(220, 140, 20) },
})
add(W, {
	id = "win_fireworks",
	name = "Fireworks",
	rarity = "Epic",
	price = 20,
	icon = "🎆",
	desc = "A fireworks show in your honour.",
	collection = "Rainbow",
	colors = { RGB(255, 90, 150), RGB(90, 220, 255) },
})
add(W, {
	id = "win_superhero",
	name = "Superhero Landing",
	rarity = "Epic",
	price = 25,
	icon = "🦸",
	desc = "Drop from the sky into the classic pose.",
	colors = { RGB(255, 70, 70), RGB(60, 110, 255) },
})
add(W, {
	id = "win_glitch",
	name = "System Override",
	rarity = "Epic",
	price = 28,
	icon = "🖥️",
	desc = "Glitch into existence with a hacker flourish.",
	collection = "Cyber",
	colors = { RGB(0, 255, 180), RGB(255, 0, 200) },
})
add(W, {
	id = "win_lightning",
	name = "Lightning Strike",
	rarity = "Epic",
	price = 30,
	icon = "🌩️",
	desc = "Call down thunder and power up.",
	colors = { RGB(255, 255, 140), RGB(80, 120, 255) },
})
add(W, {
	id = "win_magic_portal",
	name = "Magic Portal",
	rarity = "Legendary",
	price = 55,
	icon = "🌀",
	desc = "Arrive through a swirling rune portal.",
	colors = { RGB(200, 110, 255), RGB(70, 230, 255) },
})
add(W, {
	id = "win_golden_throne",
	name = "Golden Throne",
	rarity = "Legendary",
	price = 80,
	icon = "🪑",
	desc = "A golden throne rises — take your seat, champion.",
	collection = "Royal",
	colors = { RGB(255, 220, 90), RGB(170, 80, 20) },
})
add(W, {
	id = "win_cosmic",
	name = "Cosmic Champion",
	rarity = "Mythic",
	price = 140,
	icon = "🪐",
	desc = "Ascend among orbiting planets and supernovas.",
	collection = "Galaxy",
	colors = { RGB(170, 90, 255), RGB(255, 240, 160) },
})
add(W, {
	id = "win_dragon",
	name = "Dragon Celebration",
	rarity = "Mythic",
	price = 160,
	icon = "🐲",
	desc = "A fire dragon circles you and roars.",
	collection = "Fire",
	colors = { RGB(255, 200, 50), RGB(220, 20, 0) },
})

-- ==================================================================== EMOTES
local E = "Emote" :: Category
add(E, {
	id = "emote_wave",
	name = "Wave",
	rarity = "Common",
	icon = "👋",
	desc = "Say hi!",
	colors = { RGB(255, 220, 120), RGB(255, 170, 60) },
})
add(E, {
	id = "emote_dance",
	name = "Dance",
	rarity = "Common",
	icon = "🕺",
	desc = "The classic groove.",
	colors = { RGB(255, 120, 200), RGB(120, 160, 255) },
})
add(E, {
	id = "emote_sit",
	name = "Sit",
	rarity = "Common",
	price = 200,
	currency = "Coins",
	icon = "🪑",
	desc = "Take a breather.",
	colors = { RGB(200, 200, 210), RGB(140, 140, 160) },
})
add(E, {
	id = "emote_laugh",
	name = "Laugh",
	rarity = "Common",
	price = 250,
	currency = "Coins",
	icon = "😂",
	desc = "Ha ha ha!",
	colors = { RGB(255, 230, 90), RGB(255, 170, 40) },
})
add(E, {
	id = "emote_clap",
	name = "Clap",
	rarity = "Common",
	price = 250,
	currency = "Coins",
	icon = "👏",
	desc = "Good game, good game.",
	colors = { RGB(255, 210, 160), RGB(230, 150, 90) },
})
add(E, {
	id = "emote_robot",
	name = "Robot",
	rarity = "Common",
	price = 300,
	currency = "Coins",
	icon = "🤖",
	desc = "Beep boop, stiff and precise.",
	colors = { RGB(180, 220, 255), RGB(90, 120, 160) },
})
add(E, {
	id = "emote_spin",
	name = "Spin",
	rarity = "Common",
	price = 400,
	currency = "Coins",
	icon = "🌀",
	desc = "Round and round.",
	colors = { RGB(120, 255, 220), RGB(60, 160, 255) },
})
add(E, {
	id = "emote_sleep",
	name = "Sleep",
	rarity = "Rare",
	price = 600,
	currency = "Coins",
	icon = "😴",
	desc = "Zzz... wake me when the lava rises.",
	colors = { RGB(150, 160, 255), RGB(80, 80, 180) },
})
add(E, {
	id = "emote_flex",
	name = "Flex",
	rarity = "Rare",
	price = 700,
	currency = "Coins",
	icon = "💪",
	desc = "Show off those gains.",
	colors = { RGB(255, 150, 90), RGB(200, 80, 40) },
})
add(E, {
	id = "emote_celebrate",
	name = "Celebrate",
	rarity = "Rare",
	price = 800,
	currency = "Coins",
	icon = "🥳",
	desc = "Jump for joy.",
	colors = { RGB(255, 100, 170), RGB(255, 210, 80) },
})
add(E, {
	id = "emote_moonwalk",
	name = "Moonwalk",
	rarity = "Rare",
	price = 900,
	currency = "Coins",
	icon = "🌙",
	desc = "Smooth criminal.",
	colors = { RGB(200, 200, 255), RGB(60, 60, 120) },
})
add(E, {
	id = "emote_ninja",
	name = "Ninja Pose",
	rarity = "Epic",
	price = 1800,
	currency = "Coins",
	icon = "🥷",
	desc = "Silent. Deadly. Stylish.",
	colors = { RGB(80, 80, 100), RGB(255, 60, 60) },
})
add(E, {
	id = "emote_breakdance",
	name = "Breakdance",
	rarity = "Epic",
	price = 16,
	icon = "🔄",
	desc = "Windmills and freezes.",
	colors = { RGB(255, 80, 80), RGB(255, 220, 80) },
})
add(E, {
	id = "emote_guitar",
	name = "Air Guitar",
	rarity = "Epic",
	price = 20,
	icon = "🎸",
	desc = "Shred a neon guitar solo.",
	colors = { RGB(255, 60, 160), RGB(60, 220, 255) },
})
add(E, {
	id = "emote_victory_pose",
	name = "Victory Pose",
	rarity = "Rare",
	icon = "✌️",
	desc = "Earned with your first victory.",
	unlock = { kind = "Achievement", id = "ach_first_win" },
	colors = { RGB(255, 220, 90), RGB(255, 140, 40) },
})
add(E, {
	id = "emote_champion_bow",
	name = "Champion Bow",
	rarity = "Epic",
	icon = "🙇",
	desc = "A gracious bow for 25 victories.",
	unlock = { kind = "Achievement", id = "ach_wins_25" },
	colors = { RGB(255, 230, 140), RGB(200, 140, 40) },
})
add(E, {
	id = "emote_lava_surf",
	name = "Lava Surfer",
	rarity = "Epic",
	icon = "🏄",
	desc = "Surf's up! Survive 100 rounds.",
	unlock = { kind = "Achievement", id = "ach_survive_100" },
	colors = { RGB(255, 160, 40), RGB(255, 60, 0) },
})
add(E, {
	id = "emote_glitch",
	name = "Glitch Dance",
	rarity = "Legendary",
	icon = "📟",
	desc = "Cyber Collection reward.",
	unlock = { kind = "Collection", id = "Cyber" },
	colors = { RGB(0, 255, 180), RGB(255, 0, 200) },
})

-- =============================================================== ACCESSORIES
local X = "Accessory" :: Category
add(X, {
	id = "acc_party_hat",
	name = "Party Hat",
	slot = "Head",
	rarity = "Common",
	price = 3,
	icon = "🥳",
	desc = "Striped cone hat with a pom-pom.",
	colors = { RGB(255, 90, 170), RGB(90, 220, 255) },
})
add(X, {
	id = "acc_shades",
	name = "Cool Shades",
	slot = "Face",
	rarity = "Common",
	price = 4,
	icon = "🕶️",
	desc = "Too cool for lava.",
	colors = { RGB(40, 40, 50), RGB(255, 120, 60) },
})
add(X, {
	id = "acc_backpack",
	name = "Explorer Pack",
	slot = "Back",
	rarity = "Common",
	price = 5,
	icon = "🎒",
	desc = "A sturdy pack with a bedroll.",
	colors = { RGB(200, 120, 60), RGB(120, 70, 30) },
})
add(X, {
	id = "acc_top_hat",
	name = "Top Hat",
	slot = "Head",
	rarity = "Rare",
	price = 8,
	icon = "🎩",
	desc = "Classy, with a golden band.",
	colors = { RGB(30, 30, 40), RGB(255, 210, 80) },
})
add(X, {
	id = "acc_star_glasses",
	name = "Star Glasses",
	slot = "Face",
	rarity = "Rare",
	price = 9,
	icon = "🤩",
	desc = "Glowing star-shaped frames.",
	colors = { RGB(255, 220, 60), RGB(255, 90, 160) },
})
add(X, {
	id = "acc_spike_pads",
	name = "Spike Pads",
	slot = "Shoulders",
	rarity = "Rare",
	price = 9,
	icon = "🦔",
	desc = "Rugged pads with chrome spikes.",
	colors = { RGB(70, 70, 80), RGB(200, 200, 220) },
})
add(X, {
	id = "acc_viking_helmet",
	name = "Viking Helmet",
	slot = "Head",
	rarity = "Rare",
	price = 10,
	icon = "🪖",
	desc = "Iron helm with curved horns.",
	colors = { RGB(170, 170, 180), RGB(240, 230, 200) },
})
add(X, {
	id = "acc_cloud_feet",
	name = "Cloud Steps",
	slot = "Feet",
	rarity = "Rare",
	price = 11,
	icon = "☁️",
	desc = "Fluffy clouds puff under each foot.",
	colors = { RGB(255, 255, 255), RGB(180, 210, 255) },
})
add(X, {
	id = "acc_ninja_mask",
	name = "Ninja Mask",
	slot = "Face",
	rarity = "Rare",
	price = 12,
	icon = "🥷",
	desc = "A cloth mask with flowing ties.",
	colors = { RGB(40, 40, 60), RGB(220, 40, 60) },
})
add(X, {
	id = "acc_neon_sneakers",
	name = "Neon Kicks",
	slot = "Feet",
	rarity = "Rare",
	price = 13,
	icon = "👟",
	desc = "Light-up soles with a neon stripe.",
	collection = "Cyber",
	colors = { RGB(0, 255, 230), RGB(255, 0, 200) },
})
add(X, {
	id = "acc_gold_pads",
	name = "Gold Pauldrons",
	slot = "Shoulders",
	rarity = "Rare",
	price = 14,
	icon = "🛡️",
	desc = "Polished golden shoulder plates.",
	collection = "Royal",
	colors = { RGB(255, 215, 80), RGB(180, 120, 20) },
})
add(X, {
	id = "acc_star_pet",
	name = "Star Sprite",
	slot = "Float",
	rarity = "Rare",
	price = 15,
	icon = "⭐",
	desc = "A tiny star buddy that floats beside you.",
	colors = { RGB(255, 240, 110), RGB(255, 180, 0) },
})
add(X, {
	id = "acc_hero_mask",
	name = "Hero Mask",
	slot = "Face",
	rarity = "Epic",
	price = 20,
	icon = "🦹",
	desc = "A sleek domino mask for heroes.",
	colors = { RGB(255, 60, 60), RGB(255, 255, 255) },
})
add(X, {
	id = "acc_frost_orb",
	name = "Frost Orb",
	slot = "Float",
	rarity = "Epic",
	price = 20,
	icon = "🔵",
	desc = "An orbiting orb of ice and mist.",
	collection = "Frozen",
	colors = { RGB(200, 250, 255), RGB(90, 180, 255) },
})
add(X, {
	id = "acc_flame_feet",
	name = "Flame Feet",
	slot = "Feet",
	rarity = "Epic",
	price = 22,
	icon = "🦶",
	desc = "Your feet are literally on fire.",
	collection = "Fire",
	colors = { RGB(255, 170, 30), RGB(255, 50, 0) },
})
add(X, {
	id = "acc_cyber_visor",
	name = "Cyber Visor",
	slot = "Face",
	rarity = "Epic",
	price = 24,
	icon = "🥽",
	desc = "A scanning holographic visor.",
	collection = "Cyber",
	colors = { RGB(0, 255, 220), RGB(0, 120, 255) },
})
add(X, {
	id = "acc_halo",
	name = "Halo",
	slot = "Head",
	rarity = "Epic",
	price = 26,
	icon = "😇",
	desc = "A glowing halo above your head.",
	colors = { RGB(255, 250, 200), RGB(255, 220, 120) },
})
add(X, {
	id = "acc_crystal_pads",
	name = "Crystal Pauldrons",
	slot = "Shoulders",
	rarity = "Epic",
	price = 26,
	icon = "💎",
	desc = "Shoulder crystals that catch the light.",
	collection = "Frozen",
	colors = { RGB(170, 250, 255), RGB(200, 120, 255) },
})
add(X, {
	id = "acc_jetpack",
	name = "Jetpack",
	slot = "Back",
	rarity = "Epic",
	price = 28,
	icon = "🚀",
	desc = "Twin thrusters with idle flames. Purely decorative.",
	colors = { RGB(200, 210, 230), RGB(255, 120, 30) },
})
add(X, {
	id = "acc_ice_crown",
	name = "Frost Crown",
	slot = "Head",
	rarity = "Epic",
	price = 30,
	icon = "🧊",
	desc = "A crown of jagged ice crystals.",
	collection = "Frozen",
	colors = { RGB(200, 250, 255), RGB(100, 190, 255) },
})
add(X, {
	id = "acc_lava_buddy",
	name = "Lava Buddy",
	slot = "Float",
	rarity = "Epic",
	price = 30,
	icon = "🫠",
	desc = "A cheerful blob of lava that follows you.",
	collection = "Fire",
	colors = { RGB(255, 140, 20), RGB(200, 30, 0) },
})
add(X, {
	id = "acc_royal_cape",
	name = "Royal Cape",
	slot = "Back",
	rarity = "Epic",
	price = 32,
	icon = "🧣",
	desc = "A velvet cape with golden trim.",
	collection = "Royal",
	colors = { RGB(170, 20, 50), RGB(255, 210, 80) },
})
add(X, {
	id = "acc_astro_helmet",
	name = "Astro Helmet",
	slot = "Head",
	rarity = "Epic",
	price = 35,
	icon = "👨‍🚀",
	desc = "A glass dome helmet with antenna light.",
	collection = "Galaxy",
	colors = { RGB(240, 240, 255), RGB(120, 160, 255) },
})
add(X, {
	id = "acc_mini_planet",
	name = "Mini Planet",
	slot = "Float",
	rarity = "Legendary",
	price = 50,
	icon = "🪐",
	desc = "A ringed planet with its own moon.",
	collection = "Galaxy",
	colors = { RGB(255, 170, 90), RGB(130, 90, 255) },
})
add(X, {
	id = "acc_butterfly_wings",
	name = "Neon Butterfly Wings",
	slot = "Back",
	rarity = "Legendary",
	price = 55,
	icon = "🦋",
	desc = "Gently flapping glowing wings.",
	collection = "Rainbow",
	colors = { RGB(255, 90, 220), RGB(90, 220, 255) },
})
add(X, {
	id = "acc_gold_crown",
	name = "Golden Crown",
	slot = "Head",
	rarity = "Legendary",
	price = 60,
	icon = "👑",
	desc = "Jewelled crown fit for a champion.",
	collection = "Royal",
	colors = { RGB(255, 220, 80), RGB(220, 40, 60) },
})
add(X, {
	id = "acc_drone",
	name = "Cyber Drone",
	slot = "Float",
	rarity = "Legendary",
	price = 65,
	icon = "🛸",
	desc = "A hovering drone with a scanning beam.",
	collection = "Cyber",
	colors = { RGB(60, 70, 90), RGB(0, 255, 220) },
})
add(X, {
	id = "acc_flame_crown",
	name = "Flame Crown",
	slot = "Head",
	rarity = "Legendary",
	price = 70,
	icon = "🔥",
	desc = "A crown made of living fire.",
	collection = "Fire",
	colors = { RGB(255, 200, 40), RGB(255, 40, 0) },
})
add(X, {
	id = "acc_angel_wings",
	name = "Angel Wings",
	slot = "Back",
	rarity = "Legendary",
	price = 75,
	icon = "🪽",
	desc = "Large feathered wings with a soft glow.",
	colors = { RGB(255, 255, 255), RGB(255, 235, 170) },
})
add(X, {
	id = "acc_dragon_wings",
	name = "Dragon Wings",
	slot = "Back",
	rarity = "Mythic",
	price = 190,
	icon = "🐉",
	desc = "Scaled wings with burning edges that beat slowly.",
	collection = "Fire",
	colors = { RGB(200, 30, 20), RGB(255, 170, 30) },
})
add(X, {
	id = "acc_void_wings",
	name = "Void Wings",
	slot = "Back",
	rarity = "Mythic",
	price = 220,
	icon = "🌌",
	desc = "Wings cut from the fabric of space.",
	collection = "Void",
	colors = { RGB(20, 0, 40), RGB(150, 80, 255) },
})

-- ==================================================================== TITLES
local Ti = "Title" :: Category
add(Ti, {
	id = "title_rookie",
	name = "Rookie",
	rarity = "Common",
	icon = "🐣",
	desc = "Everyone starts somewhere.",
	colors = { RGB(220, 230, 240), RGB(160, 170, 190) },
})
add(Ti, {
	id = "title_survivor",
	name = "Survivor",
	rarity = "Common",
	price = 3,
	icon = "🛟",
	desc = "Still standing.",
	colors = { RGB(150, 230, 255), RGB(80, 160, 220) },
})
add(Ti, {
	id = "title_lava_runner",
	name = "Lava Runner",
	rarity = "Rare",
	price = 8,
	icon = "🏃",
	desc = "Fast feet, hot floor.",
	colors = { RGB(255, 150, 40), RGB(255, 60, 0) },
})
add(Ti, {
	id = "title_sky_walker",
	name = "Sky Walker",
	rarity = "Rare",
	price = 10,
	icon = "☁️",
	desc = "Head in the clouds, feet off the ground.",
	colors = { RGB(140, 210, 255), RGB(255, 255, 255) },
})
add(Ti, {
	id = "title_galaxy",
	name = "Star Wanderer",
	rarity = "Epic",
	price = 22,
	icon = "🌌",
	desc = "The Galaxy nameplate: a nebula with drifting stars.",
	collection = "Galaxy",
	colors = { RGB(160, 90, 255), RGB(60, 40, 180) },
})
add(Ti, {
	id = "title_unstoppable",
	name = "Unstoppable",
	rarity = "Epic",
	price = 25,
	icon = "💥",
	desc = "Pulsing red-hot nameplate.",
	colors = { RGB(255, 70, 50), RGB(255, 190, 40) },
})
add(Ti, {
	id = "title_untouchable",
	name = "Untouchable",
	rarity = "Epic",
	price = 35,
	icon = "🫥",
	desc = "Shimmering, almost out of phase.",
	collection = "Void",
	colors = { RGB(170, 120, 255), RGB(40, 20, 90) },
})
add(Ti, {
	id = "title_champion",
	name = "The Champion",
	rarity = "Legendary",
	price = 60,
	icon = "🏆",
	desc = "Golden nameplate with a crown flourish.",
	collection = "Royal",
	colors = { RGB(255, 220, 80), RGB(200, 120, 20) },
})
add(Ti, {
	id = "title_legendary",
	name = "Legendary",
	rarity = "Legendary",
	price = 90,
	icon = "🌟",
	desc = "A sweeping golden shine.",
	colors = { RGB(255, 200, 40), RGB(255, 120, 0) },
})
add(Ti, {
	id = "title_immortal",
	name = "The Immortal",
	rarity = "Mythic",
	price = 150,
	icon = "♾️",
	desc = "Prismatic animated nameplate with orbiting sparks.",
	colors = { RGB(255, 60, 140), RGB(60, 255, 220) },
})
add(Ti, {
	id = "title_king_of_sky",
	name = "King of the Sky",
	rarity = "Mythic",
	price = 200,
	icon = "🦅",
	desc = "Sky-blue royalty with a crown of light.",
	colors = { RGB(120, 220, 255), RGB(255, 230, 120) },
})
-- Achievement titles
add(Ti, {
	id = "title_first_victory",
	name = "First Victory",
	rarity = "Common",
	icon = "🥇",
	desc = "Win your first round.",
	unlock = { kind = "Achievement", id = "ach_first_win" },
	colors = { RGB(255, 220, 90), RGB(220, 160, 40) },
})
add(Ti, {
	id = "title_decorated",
	name = "Decorated",
	rarity = "Rare",
	icon = "🎖️",
	desc = "Win 10 rounds.",
	unlock = { kind = "Achievement", id = "ach_wins_10" },
	colors = { RGB(120, 200, 255), RGB(60, 110, 220) },
})
add(Ti, {
	id = "title_veteran",
	name = "Veteran",
	rarity = "Rare",
	icon = "🪖",
	desc = "Win 50 rounds.",
	unlock = { kind = "Achievement", id = "ach_wins_50" },
	colors = { RGB(140, 220, 140), RGB(60, 140, 60) },
})
add(Ti, {
	id = "title_centurion",
	name = "Centurion",
	rarity = "Epic",
	icon = "🏛️",
	desc = "Win 100 rounds.",
	unlock = { kind = "Achievement", id = "ach_wins_100" },
	colors = { RGB(230, 90, 60), RGB(255, 200, 80) },
})
add(Ti, {
	id = "title_ace",
	name = "Ace",
	rarity = "Legendary",
	icon = "🂡",
	desc = "Win 250 rounds.",
	unlock = { kind = "Achievement", id = "ach_wins_250" },
	colors = { RGB(255, 255, 255), RGB(255, 60, 90) },
})
add(Ti, {
	id = "title_mythmaker",
	name = "Mythmaker",
	rarity = "Mythic",
	icon = "📜",
	desc = "Win 500 rounds.",
	unlock = { kind = "Achievement", id = "ach_wins_500" },
	colors = { RGB(255, 120, 220), RGB(120, 255, 240) },
})
add(Ti, {
	id = "title_living_legend",
	name = "Living Legend",
	rarity = "Mythic",
	icon = "👁️",
	desc = "Win 1,000 rounds.",
	unlock = { kind = "Achievement", id = "ach_wins_1000" },
	colors = { RGB(255, 240, 120), RGB(255, 60, 160) },
})
add(Ti, {
	id = "title_lava_proof",
	name = "Lava Proof",
	rarity = "Epic",
	icon = "🧯",
	desc = "Survive 60+ seconds in 100 rounds.",
	unlock = { kind = "Achievement", id = "ach_survive_100" },
	colors = { RGB(255, 120, 40), RGB(80, 30, 20) },
})
add(Ti, {
	id = "title_featherfoot",
	name = "Featherfoot",
	rarity = "Legendary",
	icon = "🪶",
	desc = "Win a round without jumping once.",
	unlock = { kind = "Achievement", id = "ach_no_jump" },
	colors = { RGB(240, 250, 255), RGB(160, 200, 255) },
})
add(Ti, {
	id = "title_last_standing",
	name = "Last One Standing",
	rarity = "Epic",
	icon = "🏚️",
	desc = "Survive the Final Collapse.",
	unlock = { kind = "Achievement", id = "ach_final_collapse" },
	colors = { RGB(255, 90, 60), RGB(120, 20, 20) },
})
add(Ti, {
	id = "title_globetrotter",
	name = "Globetrotter",
	rarity = "Rare",
	icon = "🗺️",
	desc = "Win on 5 different maps.",
	unlock = { kind = "Achievement", id = "ach_maps_5" },
	colors = { RGB(90, 220, 160), RGB(40, 120, 200) },
})
add(Ti, {
	id = "title_questmaster",
	name = "Questmaster",
	rarity = "Epic",
	icon = "📋",
	desc = "Complete 50 daily quests.",
	unlock = { kind = "Achievement", id = "ach_quests_50" },
	colors = { RGB(255, 200, 90), RGB(140, 90, 255) },
})
add(Ti, {
	id = "title_hopper",
	name = "Hopper",
	rarity = "Common",
	icon = "🐸",
	desc = "Reach level 5.",
	unlock = { kind = "Level", level = 5 },
	colors = { RGB(140, 255, 120), RGB(60, 170, 60) },
})
add(Ti, {
	id = "title_grandmaster",
	name = "Grandmaster",
	rarity = "Legendary",
	icon = "♛",
	desc = "Reach level 60.",
	unlock = { kind = "Level", level = 60 },
	colors = { RGB(255, 230, 140), RGB(90, 40, 160) },
})
-- Collection reward titles
add(Ti, {
	id = "title_inferno_master",
	name = "Inferno Master",
	rarity = "Mythic",
	icon = "🌋",
	desc = "Fire Collection reward.",
	unlock = { kind = "Collection", id = "Fire" },
	colors = { RGB(255, 200, 40), RGB(200, 20, 0) },
})
add(Ti, {
	id = "title_galaxy_master",
	name = "Galaxy Master",
	rarity = "Mythic",
	icon = "🪐",
	desc = "Galaxy Collection reward.",
	unlock = { kind = "Collection", id = "Galaxy" },
	colors = { RGB(190, 120, 255), RGB(255, 240, 170) },
})
add(Ti, {
	id = "title_royal_highness",
	name = "Royal Highness",
	rarity = "Mythic",
	icon = "🤴",
	desc = "Royal Collection reward.",
	unlock = { kind = "Collection", id = "Royal" },
	colors = { RGB(255, 220, 90), RGB(150, 30, 60) },
})

-- =================================================================== PODIUMS
local P = "Podium" :: Category
add(P, {
	id = "podium_basic",
	name = "Champion Block",
	rarity = "Common",
	icon = "🟦",
	desc = "The classic winner's block.",
	colors = { RGB(80, 160, 255), RGB(40, 80, 200) },
})
add(P, {
	id = "podium_gold",
	name = "Golden Podium",
	rarity = "Rare",
	price = 12,
	icon = "🥇",
	desc = "Tiered gold with a laurel trim.",
	collection = "Royal",
	colors = { RGB(255, 215, 80), RGB(190, 130, 20) },
})
add(P, {
	id = "podium_cloud",
	name = "Celestial Cloud",
	rarity = "Epic",
	price = 25,
	icon = "☁️",
	desc = "A fluffy cloud with sunbeams.",
	colors = { RGB(255, 255, 255), RGB(170, 210, 255) },
})
add(P, {
	id = "podium_hologram",
	name = "Hologram Stage",
	rarity = "Epic",
	price = 30,
	icon = "📡",
	desc = "A projected stage with scanning rings.",
	collection = "Cyber",
	colors = { RGB(0, 255, 230), RGB(0, 90, 255) },
})
add(P, {
	id = "podium_crystal",
	name = "Crystal Isle",
	rarity = "Epic",
	price = 35,
	icon = "🏝️",
	desc = "A floating island of crystal spires.",
	collection = "Frozen",
	colors = { RGB(170, 250, 255), RGB(190, 120, 255) },
})
add(P, {
	id = "podium_meteor",
	name = "Floating Meteor",
	rarity = "Legendary",
	price = 55,
	icon = "☄️",
	desc = "A smouldering meteor hovering in place.",
	colors = { RGB(120, 80, 70), RGB(255, 120, 30) },
})
add(P, {
	id = "podium_lava_throne",
	name = "Lava Throne",
	rarity = "Legendary",
	price = 70,
	icon = "🌋",
	desc = "A throne of obsidian above a lava pool.",
	collection = "Fire",
	colors = { RGB(40, 30, 40), RGB(255, 100, 0) },
})
add(P, {
	id = "podium_galaxy",
	name = "Galaxy Portal",
	rarity = "Mythic",
	price = 130,
	icon = "🌀",
	desc = "Stand before a portal into deep space.",
	collection = "Galaxy",
	colors = { RGB(150, 70, 255), RGB(20, 10, 60) },
})
add(P, {
	id = "podium_summit",
	name = "Summit Peak",
	rarity = "Epic",
	icon = "🏔️",
	desc = "A snowy summit for level 35 climbers.",
	unlock = { kind = "Level", level = 35 },
	colors = { RGB(240, 250, 255), RGB(120, 140, 160) },
})
add(P, {
	id = "podium_rainbow_arch",
	name = "Rainbow Arch",
	rarity = "Legendary",
	icon = "🌈",
	desc = "Rainbow Collection reward.",
	unlock = { kind = "Collection", id = "Rainbow" },
	colors = { RGB(255, 90, 90), RGB(90, 160, 255) },
})
add(P, {
	id = "podium_void_rift",
	name = "Void Rift",
	rarity = "Mythic",
	icon = "🕳️",
	desc = "Void Collection reward.",
	unlock = { kind = "Collection", id = "Void" },
	colors = { RGB(130, 60, 255), RGB(0, 0, 0) },
})
add(P, {
	id = "podium_glacier",
	name = "Glacier Throne",
	rarity = "Legendary",
	icon = "🏔️",
	desc = "Frozen Collection reward.",
	unlock = { kind = "Collection", id = "Frozen" },
	colors = { RGB(210, 250, 255), RGB(80, 160, 230) },
})

local CosmeticCatalog = {
	Items = items,
	ById = byId,
	Categories = CATEGORY_INFO,
	-- Items equipped by default for brand new players.
	DefaultLoadout = {
		Title = "title_rookie",
		Podium = "podium_basic",
	},
}

function CosmeticCatalog.get(id: string): Item?
	return byId[id]
end

function CosmeticCatalog.byCategory(category: string): { Item }
	local list = {}
	for _, item in items do
		if item.category == category then
			table.insert(list, item)
		end
	end
	return list
end

function CosmeticCatalog.isPurchasable(item: Item): boolean
	return item.unlock.kind == "Shop" and item.price ~= nil
end

function CosmeticCatalog.defaultOwned(): { string }
	local list = {}
	for _, item in items do
		if item.unlock.kind == "Default" then
			table.insert(list, item.id)
		end
	end
	return list
end

-- Equip slot key used in the profile's `equipped` table.
function CosmeticCatalog.equipSlot(item: Item): string?
	for _, info in CATEGORY_INFO do
		if info.id == item.category then
			return info.equipSlot
		end
	end
	return nil
end

return CosmeticCatalog
