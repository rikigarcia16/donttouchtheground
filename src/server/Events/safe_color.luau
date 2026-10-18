--!nonstrict
-- Safe Color: a colour is announced; after 4s every platform of a different
-- colour turns to glass (non-solid) until the event ends.
local COUNTDOWN = 4

return {
	Start = function(ctx)
		local lavaY = ctx.hazard.LavaY()
		local counts = {}
		for _, entry in ctx.available() do
			local group = entry.part:GetAttribute("ColorGroup") :: number?
			if group and entry.basePos.Y > lavaY + 4 then
				counts[group] = (counts[group] or 0) + 1
			end
		end
		local candidates = {}
		for group, count in counts do
			if count >= 3 then
				table.insert(candidates, group)
			end
		end
		if #candidates == 0 then
			return
		end
		table.sort(candidates)
		local safe = candidates[ctx.rng:NextInteger(1, #candidates)]
		local model = ctx.map.model
		local names = string.split(model:GetAttribute("PaletteNames") or "", ",")
		local color = model:GetAttribute("Palette" .. safe)
		local dropAt = ctx.now() + COUNTDOWN
		ctx.roundState:SetAttribute("SafeColor", safe)
		ctx.broadcast({ fx = "SafeColor", group = safe, name = names[safe] or "?", color = color, dropAt = dropAt })
		ctx.maid:Add(function()
			ctx.roundState:SetAttribute("SafeColor", nil)
		end)
		local removed = {}
		ctx.after(COUNTDOWN, function()
			for _, entry in ctx.available() do
				if entry.part:GetAttribute("ColorGroup") ~= safe and ctx.lock(entry) then
					ctx.hazard.SetGone(entry, "SafeColor", nil)
					table.insert(removed, entry)
				end
			end
		end)
		ctx.maid:Add(function()
			for _, entry in removed do
				if entry.part.Parent and entry.basePos.Y > ctx.hazard.LavaY() then
					ctx.hazard.Restore(entry)
				end
			end
		end)
	end,
}
