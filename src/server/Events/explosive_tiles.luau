--!nonstrict
-- Explosive Tiles: platforms flash red/white for 2.5s, then explode,
-- knocking nearby players away and breaking for 10s.
return {
	Start = function(ctx)
		ctx.nextArm = ctx.now()
	end,
	Step = function(ctx, _dt)
		if ctx.now() < ctx.nextArm or ctx.now() > ctx.endTime - 3 then
			return
		end
		ctx.nextArm = ctx.now() + 3
		local pool = ctx.rng:Shuffle(ctx.available())
		for i = 1, math.min(ctx.rng:NextInteger(2, 3), #pool) do
			local entry = pool[i]
			if ctx.lock(entry) then
				ctx.hazard.Warn(entry, 2.5, "Explosive")
				ctx.after(2.5, function()
					local t = ctx.now()
					local center = ctx.hazard.LogicalTransform(entry, t)
					ctx.broadcast({ fx = "Explosion", position = center })
					for _, player in ctx.alive() do
						local root = player.Character
							and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if root then
							local delta = root.Position - center
							if ctx.hazard.StandingOn(player) == entry or delta.Magnitude < 7 then
								local flat = delta * Vector3.new(1, 0, 1)
								local push = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
								ctx.hazard.KnockbackPlayer(player, push * 40 + Vector3.new(0, 55, 0))
							end
						end
					end
					ctx.hazard.SetGone(entry, "Exploded", 10)
					ctx.hazard.Unlock(entry, ctx.def.id)
				end)
			end
		end
	end,
}
