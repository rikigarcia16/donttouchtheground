--!nonstrict
-- Double Jump: clients allow one extra mid-air jump while the flag is set.
return {
	Start = function(ctx)
		ctx.roundState:SetAttribute("DoubleJump", true)
		ctx.maid:Add(function()
			ctx.roundState:SetAttribute("DoubleJump", nil)
		end)
	end,
}
