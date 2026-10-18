--!nonstrict
-- Lava Wave: a clearly signalled surge — the lava rises 9 studs over 3s,
-- holds briefly, then recedes. Announced 4s in advance.
local HEIGHT, RISE, HOLD, FALL = 9, 3, 1.5, 3

return {
	Start = function(ctx)
		local startElapsed = ctx.elapsed()
		ctx.hazard.SetLavaOffset("lava_wave", function(t: number)
			local x = t - startElapsed
			if x <= 0 then
				return 0
			elseif x < RISE then
				return HEIGHT * math.sin(x / RISE * math.pi / 2)
			elseif x < RISE + HOLD then
				return HEIGHT
			elseif x < RISE + HOLD + FALL then
				return HEIGHT * math.cos((x - RISE - HOLD) / FALL * math.pi / 2)
			end
			return 0
		end)
		ctx.maid:Add(function()
			ctx.hazard.SetLavaOffset("lava_wave", nil)
		end)
		ctx.broadcast({ fx = "LavaWave", height = HEIGHT, peakAt = ctx.now() + RISE })
	end,
}
