--!strict
local Format = {}

function Format.commas(n: number): string
	local negative = n < 0
	local s = tostring(math.floor(math.abs(n)))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (if negative then "-" else "") .. out
end

function Format.compact(n: number): string
	local abs = math.abs(n)
	if abs >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif abs >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return Format.commas(n)
end

function Format.clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function Format.percent(fraction: number): string
	return string.format("%d%%", math.floor(math.clamp(fraction, 0, 1) * 100 + 0.5))
end

return Format
