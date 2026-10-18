--!strict
-- Pure lava pacing. The server integrates `rateAt` every tick (so events can
-- multiply it); the client uses `phaseAt`/`nextChange` for HUD warnings.

local LavaCurve = {}

export type Phase = { from: number, rate: number, label: string }

function LavaCurve.phaseIndexAt(phases: { Phase }, elapsed: number): number
	local index = 1
	for i, phase in phases do
		if elapsed >= phase.from then
			index = i
		end
	end
	return index
end

function LavaCurve.rateAt(phases: { Phase }, elapsed: number, suddenDeath: boolean, suddenDeathRate: number): number
	if suddenDeath then
		return suddenDeathRate
	end
	return phases[LavaCurve.phaseIndexAt(phases, elapsed)].rate
end

-- Next phase that is faster than the current one, or nil.
function LavaCurve.nextChange(phases: { Phase }, elapsed: number): (number?, Phase?)
	local current = LavaCurve.phaseIndexAt(phases, elapsed)
	local nextPhase = phases[current + 1]
	if nextPhase then
		return nextPhase.from - elapsed, nextPhase
	end
	return nil, nil
end

-- Closed-form height without event multipliers. Used by tests and by the map
-- validator to guarantee the lava always reaches the top in sudden death.
function LavaCurve.heightAt(phases: { Phase }, elapsed: number): number
	local height = 0
	for i, phase in phases do
		local nextFrom = if phases[i + 1] then phases[i + 1].from else math.huge
		if elapsed <= phase.from then
			break
		end
		local span = math.min(elapsed, nextFrom) - phase.from
		height += span * phase.rate
	end
	return height
end

return LavaCurve
