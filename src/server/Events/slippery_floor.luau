--!nonstrict
-- Slippery Floor: every platform gets ice physics; originals are restored.
local ICE = PhysicalProperties.new(0.7, 0.03, 0.1, 100, 1)

return {
	Start = function(ctx)
		for _, entry in ctx.hazard.Entries() do
			if entry.state == "Solid" and entry.kind ~= "Slippery" then
				local part = entry.part
				local original = part.CustomPhysicalProperties
				part.CustomPhysicalProperties = ICE
				part:SetAttribute("Iced", true)
				ctx.maid:Add(function()
					if part.Parent then
						part.CustomPhysicalProperties = original
						part:SetAttribute("Iced", nil)
					end
				end)
			end
		end
	end,
}
