--!nonstrict
-- Camera modes: normal, spectating alive players, scripted results shots,
-- try-on preview close-up, and screen shake for events.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)

local CameraController = {}
CameraController.SpectateChanged = Signal.new() -- (player?)
CameraController.mode = "Normal"
CameraController.reduceMotion = false

local player = Players.LocalPlayer
local spectateTarget: Player? = nil
local shakeUntil = 0
local shakeIntensity = 0
local scripted: ((dt: number, t: number) -> CFrame)? = nil
local scriptedStart = 0

local function aliveOthers(): { Player }
	local list = {}
	for _, other in Players:GetPlayers() do
		if
			other ~= player
			and other:GetAttribute("InRound")
			and other.Character
			and other.Character:FindFirstChild("Humanoid")
		then
			table.insert(list, other)
		end
	end
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	return list
end

function CameraController.Spectate(target: Player?)
	local camera = workspace.CurrentCamera
	spectateTarget = target
	if target and target.Character then
		CameraController.mode = "Spectate"
		local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	else
		CameraController.mode = "Normal"
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
	CameraController.SpectateChanged:Fire(target)
end

function CameraController.CycleSpectate(direction: number)
	local list = aliveOthers()
	if #list == 0 then
		CameraController.Spectate(nil)
		return
	end
	local index = if spectateTarget then table.find(list, spectateTarget) or 0 else 0
	index = ((index - 1 + direction) % #list) + 1
	CameraController.Spectate(list[index])
end

function CameraController.SpectateTarget(): Player?
	return spectateTarget
end

function CameraController.Shake(intensity: number, duration: number)
	if CameraController.reduceMotion then
		intensity *= 0.3
	end
	shakeIntensity = math.max(shakeIntensity, intensity)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

-- Scripted camera: `fn(dt, elapsed)` returns the camera CFrame each frame.
function CameraController.Script(fn: ((dt: number, t: number) -> CFrame)?)
	local camera = workspace.CurrentCamera
	scripted = fn
	scriptedStart = os.clock()
	if fn then
		camera.CameraType = Enum.CameraType.Scriptable
		CameraController.mode = "Scripted"
	else
		camera.CameraType = Enum.CameraType.Custom
		CameraController.mode = if spectateTarget then "Spectate" else "Normal"
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and not spectateTarget then
			camera.CameraSubject = humanoid
		end
	end
end

-- Orbiting close-up around the local character (fitting room / try-on).
function CameraController.FocusSelf(enabled: boolean)
	if enabled then
		CameraController.Script(function(_dt, t)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root then
				return workspace.CurrentCamera.CFrame
			end
			local angle = t * 0.5
			local center = root.Position + Vector3.new(0, 0.6, 0)
			return CFrame.lookAt(center + Vector3.new(math.sin(angle) * 9, 2.5, math.cos(angle) * 9), center)
		end)
	else
		CameraController.Script(nil)
	end
end

function CameraController.Start()
	player.CharacterAdded:Connect(function()
		if CameraController.mode == "Spectate" then
			-- Keep spectating; the new character is in the lobby.
			return
		end
		task.defer(function()
			CameraController.Spectate(nil)
		end)
	end)

	-- Spectate target died or left: move on automatically.
	task.spawn(function()
		while true do
			task.wait(0.5)
			if spectateTarget and (not spectateTarget.Parent or not spectateTarget:GetAttribute("InRound")) then
				CameraController.CycleSpectate(1)
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or CameraController.mode ~= "Spectate" then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1 then
			CameraController.CycleSpectate(-1)
		elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonR1 then
			CameraController.CycleSpectate(1)
		end
	end)

	RunService:BindToRenderStep("DTTG_Camera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local camera = workspace.CurrentCamera
		if scripted then
			camera.CFrame = scripted(dt, os.clock() - scriptedStart)
		end
		local now = os.clock()
		if now < shakeUntil then
			local fade = math.clamp((shakeUntil - now) / 0.5, 0, 1)
			local a = shakeIntensity * fade * 0.02
			camera.CFrame *= CFrame.Angles(
				(math.random() - 0.5) * a,
				(math.random() - 0.5) * a,
				(math.random() - 0.5) * a * 0.5
			)
		else
			shakeIntensity = 0
		end
	end)
end

return CameraController
