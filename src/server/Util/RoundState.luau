--!strict
-- The replicated round state: a Folder in ReplicatedStorage whose attributes
-- every client reads (state, timers, alive count, active event flags).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("RoundState") :: Folder?
if not folder then
	local created = Instance.new("Folder")
	created.Name = "RoundState"
	created:SetAttribute("State", "Lobby")
	created.Parent = ReplicatedStorage
	folder = created
end

return folder :: Folder
