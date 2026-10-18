--!nonstrict
-- Moving Platforms: some static platforms start sliding back and forth.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local PlatformMotion = require(Shared.Logic.PlatformMotion)

return {
	Start = function(ctx)
		local pool = ctx.rng:Shuffle(ctx.available(function(e)
			return e.part:GetAttribute("M_Kind") == nil
				and e.part:GetAttribute("E_Kind") == nil
				and e.kind ~= "Checkpoint"
		end))
		for i = 1, math.floor(#pool * 0.3) do
			local entry = pool[i]
			if ctx.lock(entry) then
				local angle = ctx.rng:NextNumber() * math.pi * 2
				PlatformMotion.writeChannel(entry.part, "E_", {
					kind = "Slide",
					vec = Vector3.new(math.cos(angle), 0, math.sin(angle)) * 4,
					period = 5 + ctx.rng:NextNumber() * 2,
					phase = 0,
					start = ctx.now(),
					finish = ctx.endTime - 1,
				})
				ctx.maid:Add(function()
					PlatformMotion.writeChannel(entry.part, "E_", nil)
				end)
			end
		end
	end,
}
