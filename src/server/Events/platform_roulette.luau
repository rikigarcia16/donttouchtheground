--!nonstrict
-- Platform Roulette: every 2.5s three random platforms flash and vanish for 4s.
return {
	Start = function(ctx)
		ctx.nextSpin = ctx.now()
	end,
	Step = function(ctx, _dt)
		if ctx.now() < ctx.nextSpin or ctx.now() > ctx.endTime - 2 then
			return
		end
		ctx.nextSpin = ctx.now() + 2.5
		local pool = ctx.rng:Shuffle(ctx.available())
		for i = 1, math.min(3, #pool) do
			local entry = pool[i]
			if ctx.lock(entry) then
				ctx.hazard.Warn(entry, 1.5, "Roulette")
				ctx.after(1.5, function()
					ctx.hazard.SetGone(entry, "Roulette", nil)
				end)
				ctx.after(5.5, function()
					ctx.hazard.Restore(entry)
					ctx.hazard.Unlock(entry, ctx.def.id)
				end)
				ctx.maid:Add(function()
					if entry.state == "Gone" and entry.part.Parent then
						ctx.hazard.Restore(entry)
					end
				end)
			end
		end
	end,
}
