--!nonstrict
-- Earthquake: every free platform shakes (deterministic, animated on clients).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PlatformMotion = require(Shared.Logic.PlatformMotion)

return {
	Start = function(ctx)
		local finishAt = ctx.endTime - 0.5
		for _, entry in
			ctx.available(function(e)
				return e.part:GetAttribute("E_Kind") == nil
			end)
		do
			if ctx.lock(entry) then
				PlatformMotion.writeChannel(entry.part, "E_", {
					kind = "Shake",
					vec = Vector3.new(0.45, 0.3, 0.45),
					period = 1,
					phase = ctx.rng:NextNumber() * 10,
					start = ctx.now(),
					finish = finishAt,
				})
				ctx.maid:Add(function()
					PlatformMotion.writeChannel(entry.part, "E_", nil)
				end)
			end
		end
		ctx.broadcast({ fx = "CameraShake", intensity = 0.6, endsAt = ctx.endTime })
	end,
}
