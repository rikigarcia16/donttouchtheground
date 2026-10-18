--!nonstrict
-- Low Gravity: floaty jumps. Workspace.Gravity replicates to every client.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

return {
	Start = function(ctx)
		workspace.Gravity = GameConfig.World.DefaultGravity * 0.45
		ctx.maid:Add(function()
			workspace.Gravity = GameConfig.World.DefaultGravity
		end)
		ctx.broadcast({ fx = "Gravity", amount = 0.45 })
	end,
}
