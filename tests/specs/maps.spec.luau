-- Builds every map and the lobby with real Roblox instances (via @lune/roblox)
-- to validate property names, platform attributes, spawns and reachability rules.
local test, eq, ok = Harness.test, Harness.eq, Harness.ok
local MapConfig = require(Shared.Config.MapConfig)
local GameConfig = require(Shared.Config.GameConfig)
local Prng = require(Shared.Util.Prng)
local PlatformMotion = require(Shared.Logic.PlatformMotion)
local PlatformFactory = require(Server.Maps.PlatformFactory)

local VALID_TYPES = {}
for kind in PlatformFactory.STYLE do
	VALID_TYPES[kind] = true
end

for _, def in MapConfig.List do
	test("map builds: " .. def.id, function()
		local builder = require(Server.Maps[def.builder])
		local folder = Instance.new("Folder")
		local decor = Instance.new("Folder")
		local factory = PlatformFactory.new(folder, { Color3.new(1, 1, 1) })
		local structures = {}
		local result = builder({
			origin = GameConfig.World.MapOrigin,
			platforms = factory,
			decor = decor,
			structures = structures,
			rng = Prng.new(1234),
			def = def,
		})
		ok(#result.spawns >= 8, def.id .. " spawns " .. #result.spawns)
		eq(#result.palette, 4, "palette size")
		ok(#factory.platforms >= 35, def.id .. " platforms " .. #factory.platforms)
		ok(result.topY >= 65 and result.topY <= 95, "topY " .. result.topY)
		local kinds, groups = {}, {}
		local highest = -math.huge
		for _, part in factory.platforms do
			local kind = part:GetAttribute("PType")
			ok(VALID_TYPES[kind], "type " .. tostring(kind))
			kinds[kind] = (kinds[kind] or 0) + 1
			local group = part:GetAttribute("ColorGroup")
			ok(group and group >= 1 and group <= 4, "color group")
			groups[group] = (groups[group] or 0) + 1
			ok(typeof(part:GetAttribute("LSize")) == "Vector3")
			ok(typeof(part:GetAttribute("BasePos")) == "Vector3")
			ok(part.CanCollide, "platform collides")
			local base = part:GetAttribute("BasePos")
			highest = math.max(highest, base.Y)
			-- Moving platforms must stay inside the arena.
			if PlatformMotion.hasMotion(part) then
				for t = 0, 20, 0.5 do
					local offset = PlatformMotion.compute(part, t)
					ok(offset.Magnitude < 50, "motion amplitude " .. part.Name)
				end
			end
		end
		ok((kinds.Checkpoint or 0) >= 4, def.id .. " has safe start pads")
		local variety = 0
		for _ in kinds do
			variety += 1
		end
		ok(variety >= 6, def.id .. " platform variety " .. variety)
		for g = 1, 4 do
			ok((groups[g] or 0) >= 3, def.id .. " colour group " .. g .. " used (Safe Color)")
		end
		ok(math.abs(highest - result.topY) <= 3, "topY matches highest platform")
		-- Lava resolves every map by the end of sudden death.
		ok(highest + 6 < 110, "lava reaches the top platform")
		local decorCount = #decor:GetDescendants()
		ok(decorCount > 30, def.id .. " decoration " .. decorCount)
		ok(decorCount + #folder:GetDescendants() < 4000, "instance budget")
	end)
end

test("maps are not recolours of each other", function()
	local signatures = {}
	for _, def in MapConfig.List do
		local builder = require(Server.Maps[def.builder])
		local factory = PlatformFactory.new(Instance.new("Folder"), { Color3.new(1, 1, 1) })
		builder({
			origin = GameConfig.World.MapOrigin,
			platforms = factory,
			decor = Instance.new("Folder"),
			structures = {},
			rng = Prng.new(1),
			def = def,
		})
		local sig = {}
		for _, part in factory.platforms do
			local p = part:GetAttribute("BasePos")
			table.insert(sig, string.format("%d,%d,%d", math.floor(p.X / 4), math.floor(p.Y / 4), math.floor(p.Z / 4)))
		end
		table.sort(sig)
		signatures[def.id] = table.concat(sig, "|")
	end
	for a, sa in signatures do
		for b, sb in signatures do
			if a < b then
				ok(sa ~= sb, a .. " and " .. b .. " share a layout")
			end
		end
	end
end)

test("lobby builds with all social areas", function()
	local Lobby = require(Server.Maps.Lobby)
	local model, refs = Lobby(GameConfig.World.LobbyOrigin, Instance.new("Folder"))
	ok(refs.spawn and refs.spawn:IsA("SpawnLocation"))
	eq(#refs.podiums, 3)
	eq(#refs.featured, 3)
	ok(refs.leaderboardBody and refs.globalBody and refs.statsBody and refs.portalBody)
	local prompts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			prompts[d:GetAttribute("Kind")] = true
		end
	end
	ok(prompts.Shop and prompts.Preview and prompts.Emotes and prompts.Portal, "interaction prompts")
	ok(#model:GetDescendants() < 3000, "lobby instance budget " .. #model:GetDescendants())
end)

test("platform standing maths matches yaw rotation", function()
	local size = Vector3.new(10, 1, 2)
	-- A long thin platform rotated 90 degrees spans Z instead of X.
	ok(PlatformMotion.isAbove(Vector3.new(4, 3, 0), Vector3.zero, 0, size, false, 5))
	ok(not PlatformMotion.isAbove(Vector3.new(0, 3, 4), Vector3.zero, 0, size, false, 5))
	ok(PlatformMotion.isAbove(Vector3.new(0, 3, 4), Vector3.zero, math.pi / 2, size, false, 5))
	ok(not PlatformMotion.isAbove(Vector3.new(4, 3, 0), Vector3.zero, math.pi / 2, size, false, 5))
	-- Check against a real CFrame transform.
	local yaw = 0.7
	local cf = CFrame.new(5, 0, -3) * CFrame.Angles(0, yaw, 0)
	local point = cf * Vector3.new(4.5, 2, 0.5)
	ok(PlatformMotion.isAbove(point, cf.Position, yaw, size, false, 5))
	local outside = cf * Vector3.new(0.5, 2, 4.5)
	ok(not PlatformMotion.isAbove(outside, cf.Position, yaw, size, false, 5))
	ok(PlatformMotion.isAbove(Vector3.new(0, 3, 4.5), Vector3.zero, 0, Vector3.new(10, 1, 10), true, 5))
	ok(not PlatformMotion.isAbove(Vector3.new(4.5, 3, 4.5), Vector3.zero, 0, Vector3.new(10, 1, 10), true, 5))
end)

test("platform motion envelopes start and end at rest", function()
	local part = Instance.new("Part")
	PlatformMotion.writeChannel(
		part,
		"E_",
		{ kind = "Slide", vec = Vector3.new(4, 0, 0), period = 5, phase = 1, start = 10, finish = 20 }
	)
	eq(PlatformMotion.compute(part, 9).Magnitude, 0)
	ok(PlatformMotion.compute(part, 12).Magnitude > 0)
	ok(PlatformMotion.compute(part, 20.9).Magnitude < 1e-6)
	PlatformMotion.writeChannel(
		part,
		"E_",
		{ kind = "Drop", vec = Vector3.new(0, 5, 0), period = 1, phase = 0, start = 0, finish = 5 }
	)
	ok(math.abs(PlatformMotion.compute(part, 2).Y + 5) < 1e-6)
	ok(math.abs(PlatformMotion.compute(part, 7).Y) < 1e-6)
	PlatformMotion.writeChannel(
		part,
		"E_",
		{ kind = "Rise", vec = Vector3.new(0, 20, 0), period = 1, phase = 0, start = 0, finish = 10 }
	)
	ok(math.abs(PlatformMotion.compute(part, 0).Y + 20) < 1e-6)
	ok(math.abs(PlatformMotion.compute(part, 5).Y) < 1e-6)
	PlatformMotion.writeChannel(part, "E_", nil)
	eq(part:GetAttribute("E_Kind"), nil)
end)
