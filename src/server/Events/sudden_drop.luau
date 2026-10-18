--!nonstrict
-- Sudden Drop: half the platforms flash, then drop 5 studs (closer to the
-- lava) and climb back just before the event ends.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PlatformMotion = require(Shared.Logic.PlatformMotion)

return {
	Start = function(ctx)
		local pool = ctx.rng:Shuffle(ctx.available(function(e)
			return e.part:GetAttribute("E_Kind") == nil
		end))
		local dropAt = ctx.now() + 1
		for i = 1, math.floor(#pool * 0.5) do
			local entry = pool[i]
			if ctx.lock(entry) then
				ctx.hazard.Warn(entry, 1, "Drop")
				PlatformMotion.writeChannel(entry.part, "E_", {
					kind = "Drop",
					vec = Vector3.new(0, 5, 0),
					period = 1,
					phase = 0,
					start = dropAt,
					finish = ctx.endTime - 1.6,
				})
				ctx.maid:Add(function()
					PlatformMotion.writeChannel(entry.part, "E_", nil)
				end)
			end
		end
		ctx.broadcast({ fx = "CameraShake", intensity = 0.35, endsAt = dropAt + 0.6 })
	end,
}
