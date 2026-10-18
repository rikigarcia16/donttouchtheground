--!nonstrict
-- Animates emotes procedurally on every character carrying an "Emote"
-- attribute (synced by EmoteStart), plus any model registered for a victory
-- pose. Runs in PreSimulation, after the Animator, so Transform overrides it.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local EmoteLibrary = require(Shared.Visual.EmoteLibrary)
local FxKit = require(Shared.Visual.FxKit)

local EmoteController = {}

type Active = {
	animationId: string,
	start: number,
	motors: { [string]: Motor6D },
	kit: any?,
	glyphTimer: number,
	model: Model,
	serverTime: boolean,
}

local active: { [Model]: Active } = {}
local emoteRequest: RemoteEvent
local Quality: any

local function stop(model: Model)
	local current = active[model]
	if not current then
		return
	end
	active[model] = nil
	for _, motor in current.motors do
		if motor.Parent then
			motor.Transform = CFrame.new()
		end
	end
	if current.kit then
		current.kit:Destroy()
	end
end

-- Plays an animation on any rig. `serverStart` syncs replicated emotes.
function EmoteController.Play(model: Model, animationId: string, serverStart: number?)
	stop(model)
	local animation = EmoteLibrary.Animations[animationId]
	if not animation then
		return
	end
	local kit = nil
	if animation.prop then
		kit = FxKit.new(model, Quality.Get())
		EmoteLibrary.buildProp(kit, animation.prop)
	end
	active[model] = {
		animationId = animationId,
		start = serverStart or os.clock(),
		motors = EmoteLibrary.motors(model),
		kit = kit,
		glyphTimer = 0,
		model = model,
		serverTime = serverStart ~= nil,
	}
end

EmoteController.Stop = stop

-- Local player asks to emote: the server validates ownership and state.
function EmoteController.Request(emoteId: string)
	local item = CosmeticCatalog.get(emoteId)
	if not item or item.category ~= "Emote" then
		return
	end
	emoteRequest:FireServer(emoteId)
end

function EmoteController.StopLocal()
	local character = Players.LocalPlayer.Character
	if character then
		emoteRequest:FireServer("")
	end
end

local function watchCharacter(character: Model)
	local function sync()
		local emote = character:GetAttribute("Emote")
		if emote then
			EmoteController.Play(character, emote :: string, character:GetAttribute("EmoteStart") :: number?)
		else
			stop(character)
		end
	end
	character:GetAttributeChangedSignal("Emote"):Connect(sync)
	character:GetAttributeChangedSignal("EmoteStart"):Connect(sync)
	character.AncestryChanged:Connect(function()
		if not character.Parent then
			stop(character)
		end
	end)
	sync()
end

function EmoteController.Init(controllers)
	Quality = controllers.QualityController
end

function EmoteController.Start()
	emoteRequest = Remotes.event("EmoteRequest")
	local function hook(player: Player)
		player.CharacterAdded:Connect(watchCharacter)
		if player.Character then
			watchCharacter(player.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end

	RunService.PreSimulation:Connect(function(dt)
		local serverNow = workspace:GetServerTimeNow()
		local clock = os.clock()
		for model, current in active do
			if not model.Parent then
				stop(model)
				continue
			end
			local animation = EmoteLibrary.Animations[current.animationId]
			local elapsed = if current.serverTime then serverNow - current.start else clock - current.start
			local joints = EmoteLibrary.sample(animation, math.max(0, elapsed))
			for name, cf in joints do
				local motor = current.motors[name]
				if motor then
					motor.Transform = cf
				end
			end
			if current.kit then
				current.kit:Update(dt)
			end
			local glyphs = animation.glyphs
			if glyphs then
				current.glyphTimer -= dt
				if current.glyphTimer <= 0 then
					current.glyphTimer = 1 / glyphs.rate
					local head = model:FindFirstChild("Head")
					if head then
						FxKit.SpawnGlyph({
							char = glyphs.chars[math.random(1, #glyphs.chars)],
							color = glyphs.colors[math.random(1, #glyphs.colors)],
							position = head.Position
								+ Vector3.new((math.random() - 0.5) * 1.5, 1.2, (math.random() - 0.5) * 1.5),
							velocity = Vector3.new(0.4, 1.6, 0),
							lifetime = 1.4,
							size = 1.1,
						})
					end
				end
			end
		end
	end)
end

return EmoteController
