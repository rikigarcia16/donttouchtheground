--!nonstrict
-- Strong Wind: a horizontal force (applied by each client to its own
-- character) that changes direction every few seconds, with a warning.
return {
	Start = function(ctx)
		local function setWind()
			local angle = ctx.rng:NextNumber() * math.pi * 2
			ctx.roundState:SetAttribute("Wind", Vector3.new(math.cos(angle), 0, math.sin(angle)) * 26)
			ctx.roundState:SetAttribute("WindChangedAt", ctx.now())
		end
		setWind()
		ctx.nextShift = ctx.now() + 4.5
		ctx.setWind = setWind
		ctx.maid:Add(function()
			ctx.roundState:SetAttribute("Wind", nil)
		end)
	end,
	Step = function(ctx, _dt)
		if ctx.now() >= ctx.nextShift then
			ctx.nextShift = ctx.now() + 4.5
			ctx.setWind()
		end
	end,
}
