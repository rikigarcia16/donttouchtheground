--!nonstrict
-- Local character movement extras: bounce pads, the Double Jump event,
-- Strong Wind force, knockback impulses, and jump/landing cosmetic reports.
-- All of these only shape the local player's own (client-simulated) motion.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Remotes = require(Shared.Net.Remotes)
local Signal = require(Shared.Util.Signal)

local MovementController = {}
MovementController.Jumped = Signal.new()
MovementController.Landed = Signal.new()

local player = Players.LocalPlayer
local RoundState: Instance
local fx: RemoteEvent
local emoteRequest: RemoteEvent
local Audio: any

local BOUNCE_VELOCITY = 95
local DOUBLE_JUMP_VELOCITY = 55

local function gravityScale(): number
	return math.sqrt(workspace.Gravity / GameConfig.World.DefaultGravity)
end

local function floorPart(root: BasePart, character: Model): BasePart?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(root.Position, Vector3.new(0, -5, 0), params)
	return if result then result.Instance :: BasePart else nil
end

local function setupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end
	local connections = {}
	local usedDoubleJump = false
	local lastBounce = 0

	-- Wind force (only while the event is active and we are in the round).
	local windAttachment = Instance.new("Attachment")
	windAttachment.Name = "DTTG_Wind"
	windAttachment.Parent = root
	local wind = Instance.new("VectorForce")
	wind.Attachment0 = windAttachment
	wind.RelativeTo = Enum.ActuatorRelativeTo.World
	wind.ApplyAtCenterOfMass = true
	wind.Force = Vector3.zero
	wind.Parent = root

	table.insert(
		connections,
		humanoid.StateChanged:Connect(function(_old, new)
			if new == Enum.HumanoidStateType.Jumping then
				fx:FireServer("Jump")
				MovementController.Jumped:Fire(character)
				if Audio then
					Audio.Play("Jump", 0.1)
				end
			elseif new == Enum.HumanoidStateType.Landed then
				usedDoubleJump = false
				fx:FireServer("Land")
				MovementController.Landed:Fire(character)
				if Audio then
					Audio.Play("Land", 0.1)
				end
			end
		end)
	)

	table.insert(
		connections,
		UserInputService.JumpRequest:Connect(function()
			if not RoundState:GetAttribute("DoubleJump") or not player:GetAttribute("InRound") then
				return
			end
			local state = humanoid:GetState()
			if
				(state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)
				and not usedDoubleJump
			then
				usedDoubleJump = true
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(v.X, DOUBLE_JUMP_VELOCITY * gravityScale(), v.Z)
				MovementController.Jumped:Fire(character)
				fx:FireServer("Jump")
			end
		end)
	)

	table.insert(
		connections,
		RunService.Heartbeat:Connect(function()
			if humanoid.Health <= 0 then
				return
			end
			-- Bounce pads.
			local now = os.clock()
			if now - lastBounce > 0.35 and humanoid.FloorMaterial ~= Enum.Material.Air then
				local floor = floorPart(root, character)
				if floor and floor:GetAttribute("PType") == "Bounce" and floor:GetAttribute("State") ~= "Gone" then
					lastBounce = now
					local v = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = Vector3.new(v.X, BOUNCE_VELOCITY * gravityScale(), v.Z)
					humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
					if Audio then
						Audio.Play("Bounce", 0.15)
					end
				end
			end
			-- Wind.
			local windVector = RoundState:GetAttribute("Wind")
			if typeof(windVector) == "Vector3" and player:GetAttribute("InRound") then
				wind.Force = windVector * root.AssemblyMass * 1.2
			elseif wind.Force ~= Vector3.zero then
				wind.Force = Vector3.zero
			end
			-- Moving cancels emotes (they are cosmetic, never a movement lock).
			if
				character:GetAttribute("Emote")
				and (humanoid.MoveDirection.Magnitude > 0.1 or humanoid:GetState() == Enum.HumanoidStateType.Jumping)
			then
				character:SetAttribute("Emote", nil)
				emoteRequest:FireServer("")
			end
		end)
	)

	humanoid.Died:Connect(function()
		for _, c in connections do
			c:Disconnect()
		end
	end)
	character.AncestryChanged:Connect(function()
		if not character.Parent then
			for _, c in connections do
				c:Disconnect()
			end
		end
	end)
end

function MovementController.Init(controllers)
	Audio = controllers.AudioController
end

function MovementController.Start()
	RoundState = ReplicatedStorage:WaitForChild("RoundState")
	fx = Remotes.event("FX")
	emoteRequest = Remotes.event("EmoteRequest")
	Remotes.event("Knockback").OnClientEvent:Connect(function(velocity)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and typeof(velocity) == "Vector3" and velocity.Magnitude < 200 then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			root.AssemblyLinearVelocity = velocity
		end
	end)
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
end

return MovementController
