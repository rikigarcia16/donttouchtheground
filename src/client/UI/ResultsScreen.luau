--!nonstrict
-- Results: a dedicated stage in the sky where the winner's avatar appears
-- on their podium with all their cosmetics and victory animation, filmed by
-- a scripted camera, plus the standings, round stats and personal rewards.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local MapConfig = require(Shared.Config.MapConfig)
local EventConfig = require(Shared.Config.EventConfig)
local Remotes = require(Shared.Net.Remotes)
local Format = require(Shared.Util.Format)
local Visuals = require(Shared.Visual.CosmeticVisuals)
local TitleStyles = require(Shared.Visual.TitleStyles)
local Bursts = require(Shared.Visual.Bursts)

local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local C, F = Theme.Colors, Theme.Fonts
local new, label = Widgets.new, Widgets.label

local ResultsScreen = {}

local STAGE = GameConfig.World.ResultsStageOrigin

local function buildStage(parent: Instance)
	local stage = Instance.new("Model")
	stage.Name = "ResultsStage"
	local function part(size, cf, color, material, transparency, shape)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		if shape then
			p.Shape = shape
		end
		p.Parent = stage
		return p
	end
	part(
		Vector3.new(2, 60, 60),
		STAGE * CFrame.new(0, -1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		C.Ink,
		Enum.Material.SmoothPlastic,
		0,
		Enum.PartType.Cylinder
	)
	for i = 0, 2 do
		part(
			Vector3.new(0.4, 62 - i * 14, 62 - i * 14),
			STAGE * CFrame.new(0, 0.05 + i * 0.02, 0) * CFrame.Angles(0, 0, math.rad(90)),
			if i % 2 == 0 then C.Pink else C.Cyan,
			Enum.Material.Neon,
			0.2,
			Enum.PartType.Cylinder
		)
	end
	-- Curved backdrop of slanted neon panels.
	for i = -6, 6 do
		local a = math.rad(i * 12)
		local cf = STAGE
			* CFrame.new(math.sin(a) * 34, 14, math.cos(a) * 34 + 6)
			* CFrame.Angles(0, a, math.rad(Theme.Slant))
		part(Vector3.new(7.4, 30, 1), cf, if i % 2 == 0 then C.InkSoft else C.Ink)
		part(
			Vector3.new(7.6, 0.6, 1.2),
			cf * CFrame.new(0, 15, 0),
			if i % 2 == 0 then C.Yellow else C.Pink,
			Enum.Material.Neon
		)
	end
	for i = 0, 3 do
		local holder =
			part(Vector3.new(1, 1, 1), STAGE * CFrame.new(-18 + i * 12, 30, -14), C.Paper, Enum.Material.Neon, 1)
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Angle = 50
		spot.Range = 60
		spot.Brightness = 4
		spot.Color = if i % 2 == 0 then C.Pink else C.Cyan
		spot.Parent = holder
	end
	stage.Parent = parent
	return stage
end

function ResultsScreen.build(UI, controllers)
	local Camera = controllers.CameraController
	local Renderer = controllers.CosmeticRenderer
	local Emotes = controllers.EmoteController
	local Audio = controllers.AudioController
	local overlay = UI.Layers().overlay
	local localPlayer = Players.LocalPlayer

	local root = new("Frame", {
		Name = "Results",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = overlay,
	})
	local winnerBanner = new("Frame", {
		Name = "Winner",
		BackgroundColor3 = C.Ink,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(700, 110),
		Rotation = Theme.Slant / 2,
		Parent = root,
	})
	Widgets.stroke(winnerBanner, C.Shadow, 4)
	local bannerGradient = Widgets.gradient(winnerBanner, { C.Pink, C.Purple }, 0)
	local winnerTitle = label({
		Text = "",
		Font = F.Display,
		Size = UDim2.new(1, -40, 0, 60),
		Position = UDim2.fromOffset(20, 8),
		AlignX = Enum.TextXAlignment.Center,
		Color = C.Yellow,
		Stroke = 3,
		Parent = winnerBanner,
	})
	local winnerSub = label({
		Text = "",
		Font = F.Heavy,
		Size = UDim2.new(1, -40, 0, 28),
		Position = UDim2.fromOffset(20, 72),
		AlignX = Enum.TextXAlignment.Center,
		Stroke = 2,
		Parent = winnerBanner,
	})

	local _, standingsContent = Widgets.panel({
		Name = "Standings",
		Title = "STANDINGS",
		Accent = C.Cyan,
		Position = UDim2.new(0, 30, 0, 280),
		Size = UDim2.fromOffset(330, 360),
		Parent = root,
	})
	local standingsList = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.new(1, -24, 1, -24),
		Parent = standingsContent,
	})
	Widgets.list(standingsList, Enum.FillDirection.Vertical, 6)
	local _, rewardsContent = Widgets.panel({
		Name = "Rewards",
		Title = "YOUR REWARDS",
		Accent = C.Yellow,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 280),
		Size = UDim2.fromOffset(360, 360),
		Parent = root,
	})
	local rewardsList = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.new(1, -24, 1, -24),
		Parent = rewardsContent,
	})
	Widgets.list(rewardsList, Enum.FillDirection.Vertical, 6)

	local stage: Model? = nil
	local clone: Model? = nil
	local podium: Model? = nil

	local function cleanup()
		root.Visible = false
		Camera.Script(nil)
		if clone then
			Emotes.Stop(clone)
			Renderer.Detach(clone)
			clone:Destroy()
			clone = nil
		end
		if podium then
			podium:Destroy()
			podium = nil
		end
		if stage then
			stage:Destroy()
			stage = nil
		end
	end

	local function showStandings(payload)
		for _, child in standingsList:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for i, s in payload.standings do
			local color = if s.isWinner
				then C.Yellow
				elseif s.isDraw then C.Cyan
				elseif s.placement == 2 then Color3.fromRGB(210, 220, 235)
				elseif s.placement == 3 then Color3.fromRGB(230, 150, 80)
				else C.InkLight
			local row = new(
				"Frame",
				{ BackgroundColor3 = C.Ink, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = i, Parent = standingsList }
			)
			Widgets.corner(row, 4)
			Widgets.stroke(row, color, 2)
			label({
				Text = string.format("#%d  %s", s.placement, s.name),
				Font = F.Heavy,
				Size = UDim2.new(0.7, -8, 1, -6),
				Position = UDim2.fromOffset(8, 3),
				Color = if s.userId == localPlayer.UserId then C.Cyan else C.Paper,
				MaxTextSize = 18,
				Parent = row,
			})
			label({
				Text = Format.clock(s.survived),
				Font = F.Display,
				Size = UDim2.new(0.3, -8, 1, -6),
				Position = UDim2.new(0.7, 0, 0, 3),
				AlignX = Enum.TextXAlignment.Right,
				Color = color,
				Parent = row,
			})
		end
		local events = {}
		for _, id in payload.events or {} do
			local def = EventConfig.ById[id]
			if def then
				table.insert(events, def.icon)
			end
		end
		label({
			Text = string.format(
				"⏱ %s   ·   events: %s",
				Format.clock(payload.duration or 0),
				if #events > 0 then table.concat(events, " ") else "none"
			),
			Font = F.Heavy,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = 99,
			Color = C.Muted,
			MaxTextSize = 16,
			Parent = standingsList,
		})
	end

	local function showRewards(reward)
		for _, child in rewardsList:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for i, line in reward.lines do
			local parts = {}
			if line.wins > 0 then
				table.insert(parts, "+" .. line.wins .. " 🏆")
			end
			if line.coins > 0 then
				table.insert(parts, "+" .. line.coins .. " 🪙")
			end
			if line.xp > 0 then
				table.insert(parts, "+" .. line.xp .. " XP")
			end
			local row = new(
				"Frame",
				{ BackgroundColor3 = C.Ink, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = i, Parent = rewardsList }
			)
			Widgets.corner(row, 4)
			label({
				Text = line.label,
				Font = F.Heavy,
				Size = UDim2.new(0.55, -8, 1, -6),
				Position = UDim2.fromOffset(8, 3),
				MaxTextSize = 15,
				Parent = row,
			})
			label({
				Text = table.concat(parts, "  "),
				Font = F.Display,
				Size = UDim2.new(0.45, -8, 1, -6),
				Position = UDim2.new(0.55, 0, 0, 3),
				AlignX = Enum.TextXAlignment.Right,
				Color = if line.wins > 0 then C.Wins else C.Coins,
				MaxTextSize = 18,
				Parent = row,
			})
			row.Position = UDim2.fromOffset(400, 0)
			task.delay(0.15 * i, function()
				Widgets.tween(row, Theme.Motion.Slide, { Position = UDim2.new() })
				Audio.Play("Coin")
			end)
		end
		label({
			Text = string.format("TOTAL  +%d 🏆   +%d 🪙   +%d XP", reward.wins, reward.coins, reward.xp),
			Font = F.Display,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = 99,
			Color = C.Yellow,
			Stroke = 2,
			Parent = rewardsList,
		})
		if reward.countedWin then
			Audio.Play("Victory")
		end
	end

	local function stageWinner(payload)
		stage = buildStage(workspace)
		local loadout = payload.winnerLoadout or {}
		local podiumId = loadout.Podium or "podium_basic"
		local builder = Visuals.Podium[podiumId] or Visuals.Podium.podium_basic
		local ok, model, height = pcall(builder, STAGE, workspace)
		if ok then
			podium = model
		else
			height = 3
		end
		local standCF = STAGE * CFrame.new(0, height, 0)
		local winner = payload.winnerId and Players:GetPlayerByUserId(payload.winnerId)
		local character = winner and winner.Character
		if character then
			local archivable = character.Archivable
			character.Archivable = true
			local copy = character:Clone()
			character.Archivable = archivable
			if copy then
				for _, d in copy:GetDescendants() do
					if
						d:IsA("Script")
						or d:IsA("LocalScript")
						or d:IsA("Sound")
						or d.Name == "DTTG_Cosmetics"
						or d.Name == "DTTG_Nameplate"
					then
						d:Destroy()
					elseif d:IsA("BasePart") then
						d.Anchored = d.Name == "HumanoidRootPart"
						d.CanCollide = false
						d.CanQuery = false
					end
				end
				local humanoid = copy:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					humanoid.PlatformStand = true
				end
				copy.Name = "WinnerClone"
				local hip = if humanoid then humanoid.HipHeight else 2
				copy:PivotTo(standCF * CFrame.new(0, hip + 1, 0) * CFrame.Angles(0, math.pi, 0))
				copy.Parent = workspace
				clone = copy
				Renderer.RenderLoadout(copy, loadout)
				-- Title nameplate above the clone.
				local style, titleName = TitleStyles.get(loadout.Title)
				local head = copy:FindFirstChild("Head")
				if head then
					local gui = Instance.new("BillboardGui")
					gui.Size = UDim2.fromOffset(300, 70)
					gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
					gui.Adornee = head
					gui.LightInfluence = 0
					local text = label({
						Text = (if titleName then string.upper(titleName) .. "\n" else "") .. winner.DisplayName,
						Font = if style then style.font else F.Display,
						Size = UDim2.fromScale(1, 1),
						AlignX = Enum.TextXAlignment.Center,
						Stroke = 2,
						Parent = gui,
					})
					if style then
						Widgets.gradient(text, style.colors, 90)
					end
					gui.Parent = copy
				end
				local winAnim = loadout.WinAnimation or "win_victory_dance"
				Emotes.Play(copy, winAnim, nil)
				local effect = Visuals.WinAnimation[winAnim]
				if effect then
					task.spawn(function()
						local okEffect, err = pcall(effect, standCF, copy)
						if not okEffect then
							warn("[Results] win effect: " .. tostring(err))
						end
					end)
				end
			end
		end
		Bursts.Land.land_confetti(standCF.Position + Vector3.new(0, 3, 0))
		local focus = standCF.Position + Vector3.new(0, 3, 0)
		Camera.Script(function(_dt, t)
			local dolly = math.clamp(t / 2.5, 0, 1)
			local distance = 26 - dolly * 12
			local angle = math.rad(-25) + t * 0.18
			return CFrame.lookAt(
				focus + Vector3.new(math.sin(angle) * distance, 4 + (1 - dolly) * 6, -math.cos(angle) * distance),
				focus
			)
		end)
	end

	Remotes.event("RoundEvent").OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if payload.type == "Results" then
			cleanup()
			root.Visible = true
			UI.Close()
			local mapDef = MapConfig.ById[payload.mapId or ""]
			local winner = payload.winnerId and Players:GetPlayerByUserId(payload.winnerId)
			if payload.training then
				winnerTitle.Text = "TRAINING COMPLETE"
				winnerSub.Text = "Play with 2+ players to earn Wins!"
				bannerGradient.Color = ColorSequence.new(C.Cyan, C.Purple)
			elseif winner or payload.winnerId then
				local name = if winner then winner.DisplayName else "A champion"
				winnerTitle.Text = "👑 " .. string.upper(name) .. " WINS!"
				winnerSub.Text = if mapDef then mapDef.icon .. " " .. mapDef.name else ""
				bannerGradient.Color = ColorSequence.new(C.Pink, C.Purple)
			elseif payload.isDraw then
				winnerTitle.Text = "DRAW!"
				winnerSub.Text = "The last players fell at the same instant"
				bannerGradient.Color = ColorSequence.new(C.Cyan, C.Green)
			else
				winnerTitle.Text = "NO WINNER"
				winnerSub.Text = ""
				bannerGradient.Color = ColorSequence.new(C.InkLight, C.Ink)
			end
			local bannerScale = winnerBanner:FindFirstChildOfClass("UIScale")
				or new("UIScale", { Parent = winnerBanner })
			bannerScale.Scale = 1.6
			Widgets.tween(bannerScale, Theme.Motion.Pop, { Scale = 1 })
			showStandings(payload)
			for _, child in rewardsList:GetChildren() do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
			local okStage, err = pcall(stageWinner, payload)
			if not okStage then
				warn("[Results] stage failed: " .. tostring(err))
			end
			task.delay(GameConfig.Round.ResultsTime - 0.3, cleanup)
		elseif payload.type == "Rewards" and payload.reward then
			showRewards(payload.reward)
		end
	end)
end

return ResultsScreen
