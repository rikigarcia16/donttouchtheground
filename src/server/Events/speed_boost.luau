--!nonstrict
-- Speed Boost: everyone alive runs faster.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

return {
	Start = function(ctx)
		local boosted = {}
		for _, player in ctx.alive() do
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = GameConfig.Character.WalkSpeed * 1.55
				table.insert(boosted, humanoid)
			end
		end
		ctx.maid:Add(function()
			for _, humanoid in boosted do
				if humanoid.Parent then
					humanoid.WalkSpeed = GameConfig.Character.WalkSpeed
				end
			end
		end)
		ctx.broadcast({ fx = "SpeedLines" })
	end,
}
