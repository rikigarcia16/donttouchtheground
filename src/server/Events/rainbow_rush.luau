--!nonstrict
-- Rainbow Rush: ten temporary rainbow platforms appear in open air above
-- the lava, giving new routes upward. They blink before disappearing.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Build = require(Shared.Util.Build)

return {
	Start = function(ctx)
		local map = ctx.map
		local lavaY = ctx.hazard.LavaY()
		local created = {}
		local attempts = 0
		while #created < 10 and attempts < 80 do
			attempts += 1
			local a = ctx.rng:NextNumber() * math.pi * 2
			local r = 8 + ctx.rng:NextNumber() * (map.radius - 4)
			local y = lavaY + 7 + ctx.rng:NextNumber() * math.max(6, map.topY - lavaY - 10)
			local position = map.center + Vector3.new(math.cos(a) * r, y - map.center.Y, math.sin(a) * r)
			local clear = true
			for _, entry in ctx.hazard.Entries() do
				if (entry.basePos - position).Magnitude < 9 then
					clear = false
					break
				end
			end
			if clear then
				local part = map.factory:Create("Temporary", CFrame.new(position), Vector3.new(6, 1, 6), {
					color = Build.hue(#created / 10, 0.7, 1),
					name = "RainbowRush",
				})
				local entry = ctx.hazard.RegisterTemporary(part)
				table.insert(created, entry)
			end
		end
		ctx.after(math.max(0, ctx.endTime - ctx.now() - 3), function()
			for _, entry in created do
				ctx.hazard.Warn(entry, 3, "Fade")
			end
		end)
		ctx.maid:Add(function()
			for _, entry in created do
				ctx.hazard.RemoveTemporary(entry)
			end
		end)
	end,
}
