--!nonstrict
-- Rising Lava: the lava climbs 2.6x faster for the duration.
return {
	Start = function(ctx)
		ctx.hazard.SetLavaMultiplier("rising_lava", 2.6)
		ctx.maid:Add(function()
			ctx.hazard.SetLavaMultiplier("rising_lava", nil)
		end)
		ctx.broadcast({ fx = "LavaSurge" })
	end,
}
