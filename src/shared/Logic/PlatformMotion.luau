--!strict
-- Deterministic platform motion shared by server and clients. The server only
-- writes attributes (kind, vector, period, start/end in server time); every
-- client animates its local copy from them, so moving platforms are smooth
-- and cost no replication. The server evaluates the same maths to know where
-- a platform logically is (standing detection, meteors, events).

local PlatformMotion = {}

local TAU = math.pi * 2

export type Channel = {
	kind: string,
	vec: Vector3,
	period: number,
	phase: number,
	start: number,
	finish: number,
}

local function clamp01(x: number): number
	return if x < 0 then 0 elseif x > 1 then 1 else x
end

local function easeOut(x: number): number
	local c = clamp01(x)
	return 1 - (1 - c) * (1 - c)
end

-- 0 -> 1 over `ramp` seconds after start, 1 -> 0 over `ramp` seconds after finish.
function PlatformMotion.envelope(t: number, start: number, finish: number, ramp: number): number
	if t < start then
		return 0
	end
	local rampIn = clamp01((t - start) / ramp)
	local rampOut = 1 - clamp01((t - finish) / ramp)
	return math.min(rampIn, rampOut)
end

function PlatformMotion.readChannel(part: Instance, prefix: string): Channel?
	local kind = part:GetAttribute(prefix .. "Kind")
	if type(kind) ~= "string" or kind == "" then
		return nil
	end
	local vec = part:GetAttribute(prefix .. "Vec")
	return {
		kind = kind,
		vec = if typeof(vec) == "Vector3" then vec else Vector3.zero,
		period = (part:GetAttribute(prefix .. "Period") :: number?) or 4,
		phase = (part:GetAttribute(prefix .. "Phase") :: number?) or 0,
		start = (part:GetAttribute(prefix .. "Start") :: number?) or 0,
		finish = (part:GetAttribute(prefix .. "End") :: number?) or math.huge,
	}
end

function PlatformMotion.writeChannel(part: Instance, prefix: string, channel: Channel?)
	if channel then
		part:SetAttribute(prefix .. "Kind", channel.kind)
		part:SetAttribute(prefix .. "Vec", channel.vec)
		part:SetAttribute(prefix .. "Period", channel.period)
		part:SetAttribute(prefix .. "Phase", channel.phase)
		part:SetAttribute(prefix .. "Start", channel.start)
		part:SetAttribute(prefix .. "End", if channel.finish == math.huge then 1e12 else channel.finish)
	else
		part:SetAttribute(prefix .. "Kind", nil)
		part:SetAttribute(prefix .. "Vec", nil)
		part:SetAttribute(prefix .. "Period", nil)
		part:SetAttribute(prefix .. "Phase", nil)
		part:SetAttribute(prefix .. "Start", nil)
		part:SetAttribute(prefix .. "End", nil)
	end
end

-- Returns translation and yaw contributed by one channel at time t.
function PlatformMotion.evaluate(channel: Channel, t: number): (Vector3, number)
	local kind = channel.kind
	local local_t = t - channel.start
	if kind == "Slide" then
		local env = PlatformMotion.envelope(t, channel.start, channel.finish, 0.8)
		return channel.vec * (math.sin(TAU * local_t / channel.period + channel.phase) * env), 0
	elseif kind == "Orbit" then
		local env = PlatformMotion.envelope(t, channel.start, channel.finish, 1)
		local theta = TAU * local_t / channel.period + channel.phase
		-- Circles around the base position (the base is the orbit centre).
		local r = channel.vec.X
		return Vector3.new(math.cos(theta) * r, math.sin(theta * 2) * channel.vec.Y, math.sin(theta) * r) * env, 0
	elseif kind == "Spin" then
		if t < channel.start or t > channel.finish then
			return Vector3.zero, 0
		end
		local direction = if channel.vec.X < 0 then -1 else 1
		return Vector3.zero, direction * TAU * local_t / channel.period + channel.phase
	elseif kind == "Shake" then
		local env = PlatformMotion.envelope(t, channel.start, channel.finish, 0.4)
		local p = channel.phase
		local n1 = math.sin(t * 23.7 + p) * 0.6 + math.sin(t * 41.3 + p * 2) * 0.4
		local n2 = math.sin(t * 29.1 + p * 3) * 0.6 + math.sin(t * 37.9 + p) * 0.4
		local n3 = math.sin(t * 31.3 + p * 5) * 0.5 + math.sin(t * 19.7 + p * 4) * 0.5
		return Vector3.new(channel.vec.X * n1, channel.vec.Y * n2, channel.vec.Z * n3) * env, 0
	elseif kind == "Drop" then
		if t < channel.start then
			return Vector3.zero, 0
		end
		local down = easeOut((t - channel.start) / 0.35)
		local up = clamp01((t - channel.finish) / 1.5)
		return Vector3.new(0, -channel.vec.Y * down * (1 - up), 0), 0
	elseif kind == "Rise" then
		local rise = easeOut((t - channel.start) / 2.5)
		local sink = clamp01((t - channel.finish) / 2.5)
		local amount = rise * (1 - sink)
		return Vector3.new(0, -channel.vec.Y * (1 - amount), 0), 0
	elseif kind == "Bob" then
		return Vector3.new(0, channel.vec.Y * math.sin(TAU * t / channel.period + channel.phase), 0), 0
	end
	return Vector3.zero, 0
end

-- Horizontal scale factor from the S_ attributes (Tiny Platforms).
function PlatformMotion.scaleAt(part: Instance, t: number): number
	local target = part:GetAttribute("S_Scale")
	if type(target) ~= "number" then
		return 1
	end
	local start = (part:GetAttribute("S_Start") :: number?) or 0
	local finish = (part:GetAttribute("S_End") :: number?) or math.huge
	local env = PlatformMotion.envelope(t, start, finish, 0.8)
	return 1 + (target - 1) * env
end

-- Full transform: translation, extra yaw (radians) and XZ scale.
function PlatformMotion.compute(part: Instance, t: number): (Vector3, number, number)
	local offset, yaw = Vector3.zero, 0
	local intrinsic = PlatformMotion.readChannel(part, "M_")
	if intrinsic then
		local o, y = PlatformMotion.evaluate(intrinsic, t)
		offset += o
		yaw += y
	end
	local eventChannel = PlatformMotion.readChannel(part, "E_")
	if eventChannel then
		local o, y = PlatformMotion.evaluate(eventChannel, t)
		offset += o
		yaw += y
	end
	return offset, yaw, PlatformMotion.scaleAt(part, t)
end

function PlatformMotion.hasMotion(part: Instance): boolean
	return part:GetAttribute("M_Kind") ~= nil
		or part:GetAttribute("E_Kind") ~= nil
		or part:GetAttribute("S_Scale") ~= nil
end

-- Is `point` standing on the platform (top face) given its logical transform?
-- `center` is the logical centre, `yaw` its total yaw, `size` logical (X, thickness, Z).
function PlatformMotion.isAbove(
	point: Vector3,
	center: Vector3,
	yaw: number,
	size: Vector3,
	round: boolean,
	maxHeight: number
): boolean
	local rel = point - center
	-- Inverse of CFrame.Angles(0, yaw, 0) applied to the horizontal offset.
	local cosY, sinY = math.cos(yaw), math.sin(yaw)
	local lx = rel.X * cosY - rel.Z * sinY
	local lz = rel.X * sinY + rel.Z * cosY
	local top = size.Y / 2
	if rel.Y < top - 0.5 or rel.Y > top + maxHeight then
		return false
	end
	local margin = 0.75
	if round then
		local r = size.X / 2 + margin
		return lx * lx + lz * lz <= r * r
	end
	return math.abs(lx) <= size.X / 2 + margin and math.abs(lz) <= size.Z / 2 + margin
end

return PlatformMotion
