--!nonstrict
-- Tiny Platforms: 40% of the larger platforms shrink to half width.
return {
	Start = function(ctx)
		local pool = ctx.rng:Shuffle(ctx.available(function(e)
			return math.min(e.size.X, e.size.Z) >= 5 and e.part:GetAttribute("S_Scale") == nil
		end))
		local count = math.floor(#pool * 0.4)
		for i = 1, count do
			local entry = pool[i]
			if ctx.lock(entry) then
				local part = entry.part
				part:SetAttribute("S_Scale", 0.5)
				part:SetAttribute("S_Start", ctx.now())
				part:SetAttribute("S_End", ctx.endTime - 0.9)
				ctx.maid:Add(function()
					part:SetAttribute("S_Scale", nil)
					part:SetAttribute("S_Start", nil)
					part:SetAttribute("S_End", nil)
				end)
			end
		end
	end,
}
