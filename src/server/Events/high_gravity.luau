--!nonstrict
-- High Gravity: shorter jumps (still enough for every map step: 6.4 / 1.3 ≈ 4.9 studs).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

return {
	Start = function(ctx)
		workspace.Gravity = GameConfig.World.DefaultGravity * 1.3
		ctx.maid:Add(function()
			workspace.Gravity = GameConfig.World.DefaultGravity
		end)
		ctx.broadcast({ fx = "Gravity", amount = 1.3 })
	end,
}
