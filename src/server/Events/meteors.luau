--!nonstrict
-- Falling Meteors: impacts are announced with a red circle 2.2s before they
-- land; platforms in the blast break and players are knocked back (never
-- killed outright — falling into lava is what eliminates).
local IMPACT_DELAY = 2.2
local RADIUS = 7

return {
	Start = function(ctx)
		ctx.nextDrop = ctx.now()
	end,
	Step = function(ctx, _dt)
		if ctx.now() < ctx.nextDrop or ctx.now() > ctx.endTime - IMPACT_DELAY then
			return
		end
		ctx.nextDrop = ctx.now() + 1.1
		local targets = {}
		local alive = ctx.alive()
		-- Half the meteors aim near a random player, the rest at random platforms.
		if #alive > 0 and ctx.rng:NextNumber() < 0.5 then
			local player = alive[ctx.rng:NextInteger(1, #alive)]
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local jitter = Vector3.new(ctx.rng:NextNumber() * 10 - 5, 0, ctx.rng:NextNumber() * 10 - 5)
				table.insert(targets, root.Position - Vector3.new(0, 3, 0) + jitter)
			end
		end
		local pool = ctx.available()
		if #pool > 0 then
			local entry = pool[ctx.rng:NextInteger(1, #pool)]
			table.insert(targets, entry.basePos + Vector3.new(0, entry.size.Y / 2, 0))
		end
		for _, target in targets do
			local impactAt = ctx.now() + IMPACT_DELAY
			ctx.broadcast({ fx = "Meteor", position = target, impactAt = impactAt, radius = RADIUS })
			ctx.after(IMPACT_DELAY, function()
				local t = ctx.now()
				for _, entry in ctx.hazard.Entries() do
					if entry.state == "Solid" and not ctx.hazard.IsProtected(entry) then
						local center = ctx.hazard.LogicalTransform(entry, t)
						local flat = (center - target) * Vector3.new(1, 0, 1)
						if
							flat.Magnitude < RADIUS + math.min(entry.size.X, entry.size.Z) * 0.3
							and math.abs(center.Y - target.Y) < 6
						then
							ctx.hazard.SetGone(entry, "Meteor", 12)
						end
					end
				end
				for _, player in ctx.alive() do
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if root then
						local delta = root.Position - target
						local flat = delta * Vector3.new(1, 0, 1)
						if flat.Magnitude < RADIUS + 2 and math.abs(delta.Y) < 10 then
							local push = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(1, 0, 0)
							ctx.hazard.KnockbackPlayer(player, push * 55 + Vector3.new(0, 40, 0))
						end
					end
				end
			end)
		end
	end,
}
