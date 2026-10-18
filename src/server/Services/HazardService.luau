--!nonstrict
-- Server-authoritative hazards: lava height and every platform behaviour.
-- Standing detection is mathematical (logical platform transform from
-- PlatformMotion) instead of Touched events, so it is reliable for moving
-- platforms and never misses a contact.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local LavaCurve = require(Shared.Logic.LavaCurve)
local PlatformMotion = require(Shared.Logic.PlatformMotion)
local Remotes = require(Shared.Net.Remotes)

local HazardService = {}

export type Entry = {
	part: BasePart,
	kind: string,
	size: Vector3,
	round: boolean,
	basePos: Vector3,
	baseYaw: number,
	state: "Solid" | "Gone",
	standTime: number,
	nextChange: number,
	cycle: string,
	respawnAt: number?,
	protectedUntil: number,
	lockedBy: string?, -- event currently controlling this platform
	originalPhysics: PhysicalProperties?,
	temporary: boolean,
}

local LavaCfg = GameConfig.Lava
local entries: { Entry } = {}
local byPart: { [BasePart]: Entry } = {}
local map: any = nil
local running = false
local startServerTime = 0
local lavaRise = 0
local lavaMultipliers: { [string]: number } = {}
local lavaOffsets: { [string]: (number) -> number } = {}
local standingCache: { [Player]: Entry? } = {}
local roundEvent: RemoteEvent
local knockback: RemoteEvent

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function setState(entry: Entry, state: "Solid" | "Gone", reason: string?)
	if entry.state == state then
		return
	end
	entry.state = state
	local part = entry.part
	part.CanCollide = state == "Solid"
	part:SetAttribute("State", state)
	part:SetAttribute("StateReason", reason)
	part:SetAttribute("Cracking", nil)
	part:SetAttribute("WarnUntil", nil)
	entry.standTime = 0
end

function HazardService.SetGone(entry: Entry, reason: string, respawnAfter: number?)
	setState(entry, "Gone", reason)
	entry.respawnAt = if respawnAfter then serverNow() + respawnAfter else nil
end

function HazardService.Restore(entry: Entry)
	if entry.temporary then
		return
	end
	setState(entry, "Solid", nil)
	entry.respawnAt = nil
end

-- Client blinks the platform until `untilTime` (server time).
function HazardService.Warn(entry: Entry, seconds: number, style: string?)
	entry.part:SetAttribute("WarnUntil", serverNow() + seconds)
	entry.part:SetAttribute("WarnStyle", style or "Red")
end

function HazardService.IsProtected(entry: Entry): boolean
	return serverNow() < entry.protectedUntil
end

function HazardService.LogicalTransform(entry: Entry, t: number): (Vector3, number, number)
	local offset, yaw, scale = PlatformMotion.compute(entry.part, t)
	return entry.basePos + offset, entry.baseYaw + yaw, scale
end

function HazardService.Entries(): { Entry }
	return entries
end

-- Platforms an event may take over: solid, unprotected, not already locked.
function HazardService.Available(filter: ((Entry) -> boolean)?): { Entry }
	local list = {}
	for _, entry in entries do
		if
			entry.state == "Solid"
			and not entry.lockedBy
			and not entry.temporary
			and not HazardService.IsProtected(entry)
		then
			if not filter or filter(entry) then
				table.insert(list, entry)
			end
		end
	end
	return list
end

function HazardService.Lock(entry: Entry, owner: string): boolean
	if entry.lockedBy and entry.lockedBy ~= owner then
		return false
	end
	entry.lockedBy = owner
	return true
end

function HazardService.Unlock(entry: Entry, owner: string)
	if entry.lockedBy == owner then
		entry.lockedBy = nil
	end
end

function HazardService.EntryFor(part: BasePart): Entry?
	return byPart[part]
end

local function register(part: BasePart, temporary: boolean): Entry
	local kind = (part:GetAttribute("PType") :: string?) or "Normal"
	local entry: Entry = {
		part = part,
		kind = kind,
		size = (part:GetAttribute("LSize") :: Vector3?) or part.Size,
		round = part:GetAttribute("Round") == true,
		basePos = (part:GetAttribute("BasePos") :: Vector3?) or part.Position,
		baseYaw = (part:GetAttribute("BaseYaw") :: number?) or 0,
		state = "Solid",
		standTime = 0,
		nextChange = 0,
		cycle = "Solid",
		respawnAt = nil,
		protectedUntil = 0,
		lockedBy = nil,
		originalPhysics = nil,
		temporary = temporary,
	}
	part:SetAttribute("State", "Solid")
	if kind == "Disappearing" then
		entry.nextChange = startServerTime + 4 + math.random() * 5
	elseif kind == "Checkpoint" then
		entry.protectedUntil = startServerTime + GameConfig.Round.SpawnProtectionTime
		part:SetAttribute("ProtectedUntil", entry.protectedUntil)
	elseif kind == "Slippery" then
		part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.02, 0.1, 100, 1)
	end
	local conveyor = part:GetAttribute("Conveyor")
	if typeof(conveyor) == "Vector3" then
		part.AssemblyLinearVelocity = conveyor
	end
	table.insert(entries, entry)
	byPart[part] = entry
	return entry
end

-- Used by events that spawn extra platforms (Rainbow Rush, Rising Towers).
function HazardService.RegisterTemporary(part: BasePart): Entry
	return register(part, true)
end

function HazardService.RemoveTemporary(entry: Entry)
	local index = table.find(entries, entry)
	if index then
		table.remove(entries, index)
	end
	byPart[entry.part] = nil
	entry.part:Destroy()
end

-- ===== Lava
function HazardService.LavaY(): number
	if not map then
		return -math.huge
	end
	local t = serverNow() - startServerTime
	local offset = 0
	for _, fn in lavaOffsets do
		offset += fn(t)
	end
	return map.baseY + LavaCfg.StartOffset + lavaRise + offset
end

function HazardService.SetLavaMultiplier(id: string, multiplier: number?)
	(lavaMultipliers :: any)[id] = multiplier
end

function HazardService.SetLavaOffset(id: string, fn: ((number) -> number)?)
	(lavaOffsets :: any)[id] = fn
end

local function lavaMultiplier(): number
	local m = 1
	for _, value in lavaMultipliers do
		m *= value
	end
	return m
end

-- ===== Standing detection
local function computeStanding(root: BasePart, humanoid: Humanoid, t: number): Entry?
	local position = root.Position
	local feetDrop = humanoid.HipHeight + root.Size.Y / 2
	for _, entry in entries do
		if entry.state == "Solid" then
			local center, yaw, scale = HazardService.LogicalTransform(entry, t)
			local size = if scale ~= 1
				then Vector3.new(entry.size.X * scale, entry.size.Y, entry.size.Z * scale)
				else entry.size
			if PlatformMotion.isAbove(position, center, yaw, size, entry.round, feetDrop + 1.5) then
				return entry
			end
		end
	end
	return nil
end

function HazardService.StandingOn(player: Player): Entry?
	return standingCache[player]
end

function HazardService.KnockbackPlayer(player: Player, velocity: Vector3)
	knockback:FireClient(player, velocity)
end

-- ===== Lifecycle
function HazardService.Begin(loadedMap, roundStartServerTime: number)
	HazardService.Stop()
	map = loadedMap
	startServerTime = roundStartServerTime
	lavaRise = 0
	for _, part in loadedMap.platforms do
		register(part, false)
	end
	running = true
	map.model:SetAttribute("RoundStart", startServerTime)
	HazardService.PublishLava(0, false)
end

function HazardService.Stop()
	running = false
	entries = {}
	byPart = {}
	standingCache = {}
	lavaMultipliers = {}
	lavaOffsets = {}
	map = nil
end

function HazardService.PublishLava(elapsed: number, suddenDeath: boolean)
	if not map then
		return
	end
	local rate = LavaCurve.rateAt(LavaCfg.Phases, elapsed, suddenDeath, LavaCfg.SuddenDeathRate) * lavaMultiplier()
	map.model:SetAttribute("LavaY", HazardService.LavaY())
	map.model:SetAttribute("LavaRate", rate)
	map.model:SetAttribute("LavaStamp", serverNow())
end

-- Called by RoundService every tick with the alive participants.
function HazardService.Step(dt: number, elapsed: number, suddenDeath: boolean, alive: { Player })
	if not running or not map then
		return
	end
	local rate = LavaCurve.rateAt(LavaCfg.Phases, elapsed, suddenDeath, LavaCfg.SuddenDeathRate) * lavaMultiplier()
	lavaRise += rate * dt
	local now = serverNow()
	local lavaY = HazardService.LavaY()

	-- Who stands where.
	local stoodOn: { [Entry]: boolean } = {}
	for _, player in alive do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid then
			local entry = computeStanding(root, humanoid, now)
			standingCache[player] = entry
			if entry then
				stoodOn[entry] = true
			end
		else
			standingCache[player] = nil
		end
	end

	for _, entry in entries do
		local part = entry.part
		if entry.state == "Solid" then
			if entry.kind == "Fragile" and not entry.lockedBy then
				if stoodOn[entry] then
					entry.standTime += dt
					if entry.standTime >= 1 and not part:GetAttribute("Cracking") then
						part:SetAttribute("Cracking", now)
					end
					if entry.standTime >= 2.2 then
						HazardService.SetGone(entry, "Broke", 14)
						roundEvent:FireAllClients({ type = "PlatformBreak", position = entry.basePos })
					end
				elseif entry.standTime > 0 then
					-- Cracks slowly heal when nobody is on it.
					entry.standTime = math.max(0, entry.standTime - dt * 0.5)
					if entry.standTime < 1 then
						part:SetAttribute("Cracking", nil)
					end
				end
			elseif entry.kind == "Fake" and not entry.lockedBy then
				if stoodOn[entry] then
					entry.standTime += dt
					if entry.standTime >= 0.2 then
						HazardService.SetGone(entry, "Fake", 20)
						roundEvent:FireAllClients({ type = "PlatformBreak", position = entry.basePos, fake = true })
					end
				end
			elseif entry.kind == "Disappearing" and not entry.lockedBy then
				if now >= entry.nextChange then
					if entry.cycle == "Solid" then
						entry.cycle = "Warning"
						HazardService.Warn(entry, 1.6, "Red")
						entry.nextChange = now + 1.6
					else
						entry.cycle = "Solid"
						HazardService.SetGone(entry, "Vanished", 3)
						entry.nextChange = now + 3 + 5 + math.random() * 3
					end
				end
			elseif entry.kind == "Checkpoint" and entry.protectedUntil > 0 and now >= entry.protectedUntil then
				entry.protectedUntil = 0
				part:SetAttribute("ProtectedUntil", nil)
			end
		elseif entry.respawnAt and now >= entry.respawnAt and not entry.lockedBy then
			-- Only respawn platforms still above the lava.
			if entry.basePos.Y - entry.size.Y / 2 > lavaY + 2 then
				HazardService.Restore(entry)
				if entry.kind == "Disappearing" then
					entry.cycle = "Solid"
				end
			else
				entry.respawnAt = nil
			end
		end

		-- Platforms swallowed by lava are gone for good.
		if entry.state == "Solid" and entry.basePos.Y + entry.size.Y / 2 < lavaY - 1 then
			HazardService.SetGone(entry, "Lava", nil)
		end
	end
end

function HazardService.Init()
	roundEvent = Remotes.event("RoundEvent")
	knockback = Remotes.event("Knockback")
end

function HazardService.Start()
	Players.PlayerRemoving:Connect(function(player)
		standingCache[player] = nil
	end)
end

return HazardService
