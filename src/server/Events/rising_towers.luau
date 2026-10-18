--!nonstrict
-- Rising Towers: six tall pillars rise out of the lava, offering safe high
-- ground for a while, then sink back down.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PlatformMotion = require(Shared.Logic.PlatformMotion)

return {
	Start = function(ctx)
		local map = ctx.map
		local lavaY = ctx.hazard.LavaY()
		local created = {}
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2 + ctx.rng:NextNumber() * 0.5
			local r = map.radius * (0.35 + ctx.rng:NextNumber() * 0.5)
			local topY = math.min(map.topY - 6, lavaY + 16 + ctx.rng:NextNumber() * 10)
			local height = math.max(10, topY - (lavaY - 10))
			local center = map.center + Vector3.new(math.cos(a) * r, topY - height / 2 - map.center.Y, math.sin(a) * r)
			local part = map.factory:Create("Temporary", CFrame.new(center), Vector3.new(6, height, 6), {
				color = Color3.fromRGB(120, 255, 220),
				material = Enum.Material.SmoothPlastic,
				name = "RisingTower",
				symbol = "▲",
				transparency = 0,
			})
			PlatformMotion.writeChannel(part, "E_", {
				kind = "Rise",
				vec = Vector3.new(0, height, 0),
				period = 1,
				phase = 0,
				start = ctx.now(),
				finish = ctx.endTime - 2.5,
			})
			local entry = ctx.hazard.RegisterTemporary(part)
			table.insert(created, entry)
		end
		ctx.after(math.max(0, ctx.endTime - ctx.now() - 4), function()
			for _, entry in created do
				ctx.hazard.Warn(entry, 1.5, "Fade")
			end
		end)
		ctx.maid:Add(function()
			for _, entry in created do
				ctx.hazard.RemoveTemporary(entry)
			end
		end)
	end,
}
