--!nonstrict
-- Final Collapse (sudden death only): the arena crumbles from the outside in.
-- Platforms and ramps flash for 1.5s before they fall. Lava rises at the
-- sudden-death rate meanwhile, so the round always resolves.
return {
	Start = function(ctx)
		local entries = ctx.available()
		local center = ctx.map.center
		table.sort(entries, function(a, b)
			local da = ((a.basePos - center) * Vector3.new(1, 0, 1)).Magnitude
			local db = ((b.basePos - center) * Vector3.new(1, 0, 1)).Magnitude
			return da > db
		end)
		ctx.queue = entries
		ctx.structures = table.clone(ctx.map.structures)
		local duration = math.max(10, ctx.endTime - ctx.now())
		local ticks = math.floor(duration / 1.5)
		-- Leave a few central platforms for the very end.
		ctx.batch = math.max(1, math.ceil(#entries * 0.9 / math.max(1, ticks)))
		ctx.nextCrumble = ctx.now() + 1
	end,
	Step = function(ctx, _dt)
		if ctx.now() < ctx.nextCrumble then
			return
		end
		ctx.nextCrumble = ctx.now() + 1.5
		for _ = 1, ctx.batch do
			local entry = table.remove(ctx.queue, 1)
			if not entry then
				break
			end
			if entry.state == "Solid" and ctx.lock(entry) then
				ctx.hazard.Warn(entry, 1.5, "Collapse")
				ctx.after(1.5, function()
					ctx.hazard.SetGone(entry, "Collapse", nil)
				end)
			end
		end
		local structure = table.remove(ctx.structures, 1)
		if structure and structure.Parent then
			structure:SetAttribute("WarnUntil", ctx.now() + 1.5)
			structure:SetAttribute("WarnStyle", "Collapse")
			ctx.after(1.5, function()
				structure.CanCollide = false
				structure:SetAttribute("State", "Gone")
			end)
		end
	end,
}
