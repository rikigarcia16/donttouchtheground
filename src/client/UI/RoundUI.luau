--!nonstrict
-- In-round presentation: countdown, GO!, event warning banners, lava level
-- indicator and proximity vignette, elimination feed, spectate bar, map vote,
-- sudden death, AFK notice and the client side of every event's visuals.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EventConfig = require(Shared.Config.EventConfig)
local MapConfig = require(Shared.Config.MapConfig)
local GameConfig = require(Shared.Config.GameConfig)
local Remotes = require(Shared.Net.Remotes)
local Bursts = require(Shared.Visual.Bursts)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local RoundUI = {}

local player = Players.LocalPlayer

function RoundUI.build(UI, controllers)
	local layers = UI.Layers()
	local hud, overlay = layers.hud, layers.overlay
	local Audio = controllers.AudioController
	local Camera = controllers.CameraController
	local Lava = controllers.LavaController
	local roundState = ReplicatedStorage:WaitForChild("RoundState")
	local reduceFlashing = false
	UI.SetReduceFlashing = function(value)
		reduceFlashing = value
	end

	-- ================================================================ Countdown
	local countdown = label({
		Name = "Countdown",
		Text = "",
		Font = F.Display,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(500, 220),
		AlignX = Enum.TextXAlignment.Center,
		Color = C.Yellow,
		Stroke = 5,
		Parent = overlay,
	})
	local countdownScale = new("UIScale", { Parent = countdown })
	local function showCountdown(text: string, color: Color3)
		countdown.Text = text
		countdown.TextColor3 = color
		countdown.TextTransparency = 0
		countdownScale.Scale = 2
		Widgets.tween(countdownScale, Theme.Motion.Pop, { Scale = 1 })
		task.delay(0.75, function()
			if countdown.Text == text then
				Widgets.tween(countdown, Theme.Motion.Fast, { TextTransparency = 1 })
			end
		end)
	end

	-- ============================================================ Event banner
	local bannerHolder = new("Frame", {
		Name = "EventBanner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 132),
		Size = UDim2.fromOffset(620, 110),
		Parent = overlay,
	})
	local function eventBanner(def, startsAt: number?)
		for _, child in bannerHolder:GetChildren() do
			child:Destroy()
		end
		local card = new("Frame", {
			BackgroundColor3 = C.Ink,
			Size = UDim2.new(1, 0, 0, 92),
			Position = UDim2.fromOffset(-900, 0),
			Rotation = Theme.Slant / 2,
			Parent = bannerHolder,
		})
		Widgets.stroke(card, C.Shadow, 4)
		Widgets.gradient(card, { def.color:Lerp(C.Ink, 0.55), C.Ink }, 0)
		local stripe = new("Frame", {
			BackgroundColor3 = def.color,
			Size = UDim2.new(0, 110, 1, 12),
			Position = UDim2.fromOffset(-14, -6),
			Rotation = Theme.Slant,
			Parent = card,
		})
		Widgets.stroke(stripe, C.Shadow, 3)
		label({
			Text = def.icon,
			Font = F.Heavy,
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.15, 0.15),
			AlignX = Enum.TextXAlignment.Center,
			Parent = stripe,
		})
		label({
			Text = string.upper(def.name),
			Font = F.Display,
			Size = UDim2.new(1, -240, 0, 44),
			Position = UDim2.fromOffset(110, 6),
			Color = def.color:Lerp(C.Paper, 0.4),
			Stroke = 3,
			Parent = card,
		})
		label({
			Text = def.description,
			Font = F.Heavy,
			Size = UDim2.new(1, -240, 0, 26),
			Position = UDim2.fromOffset(110, 54),
			MaxTextSize = 20,
			Parent = card,
		})
		local pips = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 14),
			Size = UDim2.fromOffset(110, 20),
			Parent = card,
		})
		Widgets.list(pips, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right)
		for i = 1, 5 do
			local pip = new("Frame", {
				BackgroundColor3 = if i <= def.difficulty then def.color else C.InkLight,
				Size = UDim2.fromOffset(18, 18),
				Rotation = 45,
				LayoutOrder = i,
				Parent = pips,
			})
			Widgets.stroke(pip, C.Shadow, 2)
		end
		local countdownText = label({
			Text = "",
			Font = F.Display,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 44),
			Size = UDim2.fromOffset(110, 36),
			AlignX = Enum.TextXAlignment.Right,
			Color = C.Yellow,
			Stroke = 2,
			Parent = card,
		})
		Widgets.tween(card, Theme.Motion.Slide, { Position = UDim2.fromOffset(0, 0) })
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not card.Parent then
				connection:Disconnect()
				return
			end
			if startsAt then
				local remaining = startsAt - workspace:GetServerTimeNow()
				countdownText.Text = if remaining > 0 then string.format("%.1fs", remaining) else "NOW!"
			end
		end)
		task.delay(if startsAt then math.max(2.5, startsAt - workspace:GetServerTimeNow() + 1.5) else 3, function()
			if card.Parent then
				Widgets.tween(card, Theme.Motion.Slide, { Position = UDim2.fromOffset(900, 0) })
				task.wait(0.4)
				card:Destroy()
			end
		end)
		if not reduceFlashing then
			local flash = new("Frame", {
				BackgroundColor3 = def.color,
				BackgroundTransparency = 0.6,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 0,
				Parent = overlay,
			})
			Widgets.tween(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
			game:GetService("Debris"):AddItem(flash, 0.6)
		end
	end

	local function textBanner(title: string, sub: string, color: Color3)
		eventBanner({ name = title, description = sub, icon = "⚠️", color = color, difficulty = 0 }, nil)
	end

	-- ======================================================= Elimination feed
	local feed = new("Frame", {
		Name = "Feed",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -170),
		Size = UDim2.fromOffset(320, 200),
		Parent = hud,
	})
	Widgets.list(feed, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
	local feedOrder = 0
	local CAUSE_TEXT = {
		Lava = "touched the lava 🔥",
		Fall = "fell off the map",
		Left = "left the game",
		Reset = "was eliminated",
		Hazard = "got blasted",
		Collapse = "fell in the collapse",
	}
	local function addFeed(text: string, color: Color3)
		feedOrder += 1
		local row = new("Frame", {
			BackgroundColor3 = C.Ink,
			BackgroundTransparency = 0.15,
			Size = UDim2.fromOffset(310, 30),
			LayoutOrder = feedOrder,
			Parent = feed,
		})
		Widgets.corner(row, 4)
		Widgets.stroke(row, color, 2)
		label({
			Text = text,
			Font = F.Heavy,
			Size = UDim2.new(1, -12, 1, -6),
			Position = UDim2.fromOffset(6, 3),
			AlignX = Enum.TextXAlignment.Right,
			MaxTextSize = 16,
			Parent = row,
		})
		task.delay(5, function()
			if row.Parent then
				Widgets.tween(row, Theme.Motion.Fast, { BackgroundTransparency = 1 })
				task.wait(0.2)
				row:Destroy()
			end
		end)
		local children = feed:GetChildren()
		if #children > 7 then
			for _, child in children do
				if child:IsA("Frame") then
					child:Destroy()
					break
				end
			end
		end
	end

	-- ============================================== Lava indicator + vignette
	local meter = new("Frame", {
		Name = "LavaMeter",
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.2,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -24, 0.5, 30),
		Size = UDim2.fromOffset(34, 300),
		Visible = false,
		Parent = hud,
	})
	Widgets.corner(meter, 8)
	Widgets.stroke(meter, C.Shadow, 3)
	local lavaFill = new("Frame", {
		BackgroundColor3 = C.Orange,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		Parent = meter,
	})
	Widgets.corner(lavaFill, 8)
	Widgets.gradient(lavaFill, { C.Yellow, C.Red }, 90)
	local youMarker = new("Frame", {
		BackgroundColor3 = C.Cyan,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(46, 10),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = meter,
	})
	Widgets.stroke(youMarker, C.Shadow, 2)
	label({
		Text = "YOU",
		Font = F.Heavy,
		Size = UDim2.fromOffset(40, 16),
		Position = UDim2.fromOffset(-44, -4),
		AlignX = Enum.TextXAlignment.Right,
		Color = C.Cyan,
		Stroke = 1.5,
		Parent = youMarker,
	})
	label({
		Text = "🌋",
		Font = F.Heavy,
		Size = UDim2.fromOffset(34, 30),
		Position = UDim2.new(0, 0, 1, 4),
		AlignX = Enum.TextXAlignment.Center,
		Parent = meter,
	})
	local vignetteFrame = new("Frame", {
		BackgroundColor3 = C.Red,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = overlay,
	})
	Lava.ProximityChanged:Connect(function(distance)
		if distance and distance < 10 then
			local intensity = math.clamp(1 - distance / 10, 0, 1)
			vignetteFrame.BackgroundTransparency = 1 - intensity * 0.35
		else
			vignetteFrame.BackgroundTransparency = 1
		end
	end)

	-- ============================================================ Spectate bar
	local spectate = new("Frame", {
		Name = "Spectate",
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -30),
		Size = UDim2.fromOffset(520, 64),
		Visible = false,
		Parent = hud,
	})
	Widgets.corner(spectate, 8)
	Widgets.stroke(spectate, C.Cyan, 3)
	Widgets.button({
		Name = "Prev",
		Text = "◀",
		Style = "Ghost",
		Size = UDim2.fromOffset(64, 48),
		Position = UDim2.fromOffset(8, 8),
		OnClick = function()
			Camera.CycleSpectate(-1)
		end,
		Parent = spectate,
	})
	Widgets.button({
		Name = "Next",
		Text = "▶",
		Style = "Ghost",
		Size = UDim2.fromOffset(64, 48),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		OnClick = function()
			Camera.CycleSpectate(1)
		end,
		Parent = spectate,
	})
	local spectateName = label({
		Text = "",
		Font = F.Display,
		Size = UDim2.new(1, -170, 0, 30),
		Position = UDim2.fromOffset(85, 4),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 2,
		Parent = spectate,
	})
	label({
		Text = "SPECTATING · Q/E or LB/RB",
		Font = F.Heavy,
		Size = UDim2.new(1, -170, 0, 18),
		Position = UDim2.fromOffset(85, 38),
		AlignX = Enum.TextXAlignment.Center,
		Color = C.Muted,
		Parent = spectate,
	})
	local stopSpectate = Widgets.button({
		Name = "Watch",
		Text = "👁 SPECTATE",
		Style = "Primary",
		Size = UDim2.fromOffset(190, 46),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -30),
		Visible = false,
		OnClick = function()
			if Camera.SpectateTarget() then
				Camera.Spectate(nil)
			else
				Camera.CycleSpectate(1)
			end
		end,
		Parent = hud,
	})
	Camera.SpectateChanged:Connect(function(target)
		spectate.Visible = target ~= nil
		spectateName.Text = if target then target.DisplayName else ""
	end)

	-- ================================================================ Map vote
	local votePanel, voteContent = Widgets.panel({
		Name = "MapVote",
		Title = "VOTE THE MAP",
		Accent = C.Purple,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -26),
		Size = UDim2.fromOffset(700, 190),
		Visible = false,
		Parent = hud,
	})
	local voteRow = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 1, -16),
		Position = UDim2.fromOffset(12, 4),
		Parent = voteContent,
	})
	Widgets.list(voteRow, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Center)
	local voteButtons: { [string]: any } = {}
	local myVote: string? = nil
	local function rebuildVote()
		for _, child in voteRow:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		voteButtons = {}
		local options = string.split(roundState:GetAttribute("VoteOptions") or "", ",")
		for i, mapId in options do
			local def = MapConfig.ById[mapId]
			if def then
				local button = Widgets.button({
					Name = mapId,
					Style = "Ghost",
					Size = UDim2.fromOffset(210, 130),
					LayoutOrder = i,
					OnClick = function()
						myVote = mapId
						Remotes.event("MapVote"):FireServer(mapId)
					end,
					Parent = voteRow,
				})
				local text = button:FindFirstChild("Text") :: TextLabel
				text.Text = def.icon
				text.Size = UDim2.new(1, -10, 0, 54)
				text.Position = UDim2.fromOffset(5, 6)
				label({
					Text = string.upper(def.name),
					Font = F.Display,
					Size = UDim2.new(1, -10, 0, 28),
					Position = UDim2.fromOffset(5, 62),
					AlignX = Enum.TextXAlignment.Center,
					Stroke = 2,
					ZIndex = 3,
					Parent = button,
				})
				local votes = label({
					Name = "Votes",
					Text = "0 votes",
					Font = F.Heavy,
					Size = UDim2.new(1, -10, 0, 20),
					Position = UDim2.fromOffset(5, 96),
					AlignX = Enum.TextXAlignment.Center,
					Color = C.Yellow,
					ZIndex = 3,
					Parent = button,
				})
				Widgets.gradient(button, { def.colors[1]:Lerp(C.Ink, 0.4), def.colors[2]:Lerp(C.Ink, 0.6) }, 90)
				voteButtons[mapId] = { button = button, votes = votes }
			end
		end
	end
	local function refreshVotes()
		local ok, counts = pcall(HttpService.JSONDecode, HttpService, roundState:GetAttribute("VoteCounts") or "{}")
		for mapId, entry in voteButtons do
			local n = if ok and type(counts) == "table" then counts[mapId] or 0 else 0
			entry.votes.Text = (if myVote == mapId then "✔ " else "") .. n .. (if n == 1 then " vote" else " votes")
		end
	end
	roundState:GetAttributeChangedSignal("VoteOptions"):Connect(function()
		myVote = nil
		rebuildVote()
		refreshVotes()
	end)
	roundState:GetAttributeChangedSignal("VoteCounts"):Connect(refreshVotes)
	rebuildVote()
	UI.Register("Portal", {
		open = function()
			if roundState:GetAttribute("State") == "Intermission" then
				votePanel.Visible = true
			elseif not player:GetAttribute("InRound") then
				Camera.CycleSpectate(1)
			end
			task.defer(UI.Close, "Portal")
		end,
		close = function() end,
	})

	-- ======================================================= State reactions
	local function refreshVisibility()
		local state = roundState:GetAttribute("State")
		local inRound = player:GetAttribute("InRound") == true
		votePanel.Visible = state == "Intermission" and UI.current == nil
		meter.Visible = inRound and (state == "Active" or state == "SuddenDeath")
		local roundRunning = state == "Active" or state == "SuddenDeath" or state == "Preparation"
		stopSpectate.Visible = roundRunning and not inRound and Camera.SpectateTarget() == nil and UI.current == nil
		if not roundRunning and Camera.SpectateTarget() then
			Camera.Spectate(nil)
		end
	end
	roundState:GetAttributeChangedSignal("State"):Connect(function()
		local state = roundState:GetAttribute("State")
		if state == "Intermission" or state == "Lobby" then
			Audio.PlayMusic("MusicLobby")
		elseif state == "Preparation" then
			local def = MapConfig.ById[roundState:GetAttribute("MapId") or ""]
			if def then
				Audio.PlayMusic(def.music)
			end
		elseif state == "SuddenDeath" then
			Audio.PlayMusic("MusicSuddenDeath")
		elseif state == "Results" then
			Audio.PlayMusic("MusicResults")
		end
		refreshVisibility()
	end)
	player:GetAttributeChangedSignal("InRound"):Connect(refreshVisibility)
	UI.MenuChanged:Connect(refreshVisibility)
	Camera.SpectateChanged:Connect(refreshVisibility)
	refreshVisibility()

	-- AFK notice
	local afk = label({
		Name = "AFK",
		Text = "💤 You are AFK — move to join the next round",
		Font = F.Heavy,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 118),
		Size = UDim2.fromOffset(560, 28),
		AlignX = Enum.TextXAlignment.Center,
		Color = C.Yellow,
		Stroke = 2,
		Parent = hud,
	})
	afk.Visible = false
	player:GetAttributeChangedSignal("AFK"):Connect(function()
		afk.Visible = player:GetAttribute("AFK") == true
	end)

	-- Lava meter per frame.
	RunService.RenderStepped:Connect(function()
		if not meter.Visible then
			return
		end
		local map = workspace:FindFirstChild("Map")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not map or not root then
			return
		end
		local baseY = (map:GetAttribute("BaseY") or 0) + GameConfig.Lava.StartOffset
		local topY = (map:GetAttribute("TopY") or 80) + 6
		local function fraction(y)
			return math.clamp((y - baseY) / (topY - baseY), 0, 1)
		end
		lavaFill.Size = UDim2.fromScale(1, fraction(Lava.currentY))
		youMarker.Position = UDim2.fromScale(0.5, 1 - fraction(root.Position.Y - 3))
	end)

	-- ================================================== Darkness (client side)
	local savedLighting: { [string]: any }? = nil
	local selfLight: PointLight? = nil
	roundState:GetAttributeChangedSignal("Darkness"):Connect(function()
		if roundState:GetAttribute("Darkness") then
			savedLighting = {
				Brightness = Lighting.Brightness,
				ClockTime = Lighting.ClockTime,
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
			}
			TweenService:Create(Lighting, TweenInfo.new(1.5), {
				Brightness = 0.1,
				ClockTime = 0,
				Ambient = Color3.fromRGB(15, 10, 25),
				OutdoorAmbient = Color3.fromRGB(20, 15, 35),
			}):Play()
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local light = Instance.new("PointLight")
				light.Range = 22
				light.Brightness = 1.6
				light.Color = Color3.fromRGB(200, 220, 255)
				light.Shadows = false
				light.Parent = root
				selfLight = light
			end
		else
			if savedLighting then
				TweenService:Create(Lighting, TweenInfo.new(1.5), savedLighting):Play()
				savedLighting = nil
			end
			if selfLight then
				selfLight:Destroy()
				selfLight = nil
			end
		end
	end)

	-- =========================================================== Event visuals
	local function meteor(position: Vector3, impactAt: number, radius: number)
		local warning = Instance.new("Part")
		warning.Name = "MeteorWarning"
		warning.Anchored = true
		warning.CanCollide = false
		warning.CanQuery = false
		warning.CanTouch = false
		warning.Shape = Enum.PartType.Cylinder
		warning.Size = Vector3.new(0.2, radius * 2, radius * 2)
		warning.CFrame = CFrame.new(position + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		warning.Material = Enum.Material.Neon
		warning.Color = C.Red
		warning.Transparency = 0.45
		warning.Parent = workspace
		local rock = Instance.new("Part")
		rock.Name = "Meteor"
		rock.Anchored = true
		rock.CanCollide = false
		rock.CanQuery = false
		rock.CanTouch = false
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(5, 5, 5)
		rock.Material = Enum.Material.Basalt
		rock.Color = Color3.fromRGB(90, 60, 50)
		rock.Parent = workspace
		local fire = Instance.new("Fire")
		fire.Size = 8
		fire.Heat = 12
		fire.Parent = rock
		local start = workspace:GetServerTimeNow()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local now = workspace:GetServerTimeNow()
			local remaining = impactAt - now
			if remaining <= 0 then
				connection:Disconnect()
				warning:Destroy()
				rock:Destroy()
				Bursts.Land.land_meteor(position + Vector3.new(0, 2.8, 0))
				Audio.Play("MeteorImpact", 0.2)
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - position).Magnitude < 30 then
					Camera.Shake(1, 0.4)
				end
				return
			end
			local t = math.clamp((now - start) / math.max(0.1, impactAt - start), 0, 1)
			rock.CFrame = CFrame.new(position + Vector3.new(30, 80, 20) * (1 - t))
			warning.Transparency = 0.25 + (math.sin(now * 14) + 1) * 0.2
		end)
	end

	Remotes.event("RoundEvent").OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		local kind = payload.type
		if kind == "Countdown" then
			showCountdown(tostring(payload.value), C.Yellow)
			Audio.Play("Countdown")
		elseif kind == "Go" then
			showCountdown("GO!", C.Green)
			Audio.Play("CountdownGo")
		elseif kind == "Preparation" then
			local def = MapConfig.ById[payload.mapId or ""]
			if def then
				textBanner(
					def.name,
					if payload.training then "Training run — no Wins. Invite a friend!" else def.description,
					def.colors[1]
				)
			end
		elseif kind == "MapSelected" then
			local def = MapConfig.ById[payload.mapId or ""]
			if def then
				showCountdown(def.icon .. " " .. string.upper(def.name), def.colors[1])
			end
		elseif kind == "EventWarning" then
			local def = EventConfig.ById[payload.eventId or ""]
			if def then
				eventBanner(def, payload.startsAt)
				Audio.Play(def.sound)
			end
		elseif kind == "Eliminated" then
			local isMe = payload.userId == player.UserId
			addFeed(
				string.format(
					"%s %s · %d left",
					payload.name or "?",
					CAUSE_TEXT[payload.cause] or "is out",
					payload.alive or 0
				),
				if isMe then C.Red else C.Orange
			)
			if isMe then
				Audio.Play("Eliminated")
				showCountdown("ELIMINATED", C.Red)
			end
		elseif kind == "LavaWarning" then
			textBanner(
				"LAVA " .. string.upper(payload.label or "RISING"),
				"The lava is about to speed up — climb!",
				C.Orange
			)
			Audio.Play("EventDanger")
		elseif kind == "SuddenDeath" then
			textBanner("SUDDEN DEATH", "The arena collapses and the lava surges!", C.Red)
			Camera.Shake(0.6, 1)
		elseif kind == "PlatformBreak" then
			Audio.Play("PlatformBreak", 0.2)
		elseif kind == "EventFX" then
			local fx = payload.fx
			if fx == "Meteor" and typeof(payload.position) == "Vector3" then
				meteor(payload.position, payload.impactAt or workspace:GetServerTimeNow() + 2, payload.radius or 7)
			elseif fx == "CameraShake" then
				Camera.Shake(
					payload.intensity or 0.5,
					math.max(0.5, (payload.endsAt or 0) - workspace:GetServerTimeNow())
				)
				Audio.Play("EventRumble")
			elseif fx == "Explosion" and typeof(payload.position) == "Vector3" then
				Bursts.sphere(
					payload.position,
					{ color = C.Orange, from = 2, to = 14, duration = 0.4, transparency = 0.2 }
				)
				Bursts.emit(payload.position, {
					texture = "Fire",
					color = { C.Yellow, C.Red },
					size = { 3, 0.5 },
					lifetime = { 0.4, 0.7 },
					speed = { 10, 18 },
				}, 30)
				Audio.Play("Explosion", 0.2)
				Camera.Shake(0.7, 0.3)
			elseif fx == "SafeColor" then
				local color = payload.color or C.Paper
				eventBanner({
					name = "SAFE COLOR: " .. tostring(payload.name),
					description = "Get onto " .. tostring(payload.name) .. " platforms NOW!",
					icon = "🎨",
					color = color,
					difficulty = 4,
				}, payload.dropAt)
			elseif fx == "LavaWave" then
				Camera.Shake(0.5, 3)
			end
		end
	end)
end

return RoundUI
