--!nonstrict
-- Darkness: clients dim the lighting, platforms keep a soft glow and each
-- player carries a small light so the game stays fair.
return {
	Start = function(ctx)
		ctx.roundState:SetAttribute("Darkness", true)
		ctx.maid:Add(function()
			ctx.roundState:SetAttribute("Darkness", nil)
		end)
	end,
}
