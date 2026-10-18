local test, eq, ok = Harness.test, Harness.eq, Harness.ok
local GameConfig = require(Shared.Config.GameConfig)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local LavaCurve = require(Shared.Logic.LavaCurve)
local RoundLogic = require(Shared.Logic.RoundLogic)
local RewardRules = require(Shared.Logic.RewardRules)
local LevelCurve = require(Shared.Logic.LevelCurve)
local Prng = require(Shared.Util.Prng)
local RateLimiter = require(Shared.Util.RateLimiter)
local Format = require(Shared.Util.Format)

local opts = { simultaneousWindow = 0.05, minTravelForActive = 40 }
local rewardConfig = {
	rewards = EconomyConfig.Rewards,
	minActiveForWin = GameConfig.Round.MinActiveForWin,
	minRoundTimeForWin = GameConfig.Round.MinRoundTimeForWin,
}

test("lava is stable for the first 20 seconds", function()
	local phases = GameConfig.Lava.Phases
	eq(LavaCurve.rateAt(phases, 0, false, 9), 0)
	eq(LavaCurve.rateAt(phases, 19.9, false, 9), 0)
	ok(LavaCurve.rateAt(phases, 20, false, 9) > 0)
	ok(LavaCurve.rateAt(phases, 130, false, 9) > LavaCurve.rateAt(phases, 70, false, 9))
	eq(LavaCurve.rateAt(phases, 50, true, 9), 9)
end)

test("lava heightAt integrates phases", function()
	local phases =
		{ { from = 0, rate = 0, label = "" }, { from = 10, rate = 1, label = "" }, { from = 20, rate = 2, label = "" } }
	eq(LavaCurve.heightAt(phases, 5), 0)
	eq(LavaCurve.heightAt(phases, 15), 5)
	eq(LavaCurve.heightAt(phases, 25), 20)
	local dt, nextPhase = LavaCurve.nextChange(phases, 12)
	eq(dt, 8)
	eq(nextPhase and nextPhase.rate, 2)
	eq((LavaCurve.nextChange(phases, 30)), nil)
end)

test("lava always resolves the round: reaches 110 studs by end of sudden death", function()
	local base = LavaCurve.heightAt(GameConfig.Lava.Phases, GameConfig.Round.RoundTime)
	local total = base
		+ GameConfig.Lava.SuddenDeathRate * GameConfig.Round.SuddenDeathTime
		+ GameConfig.Lava.StartOffset
	ok(total >= 110, "lava top " .. total)
end)

test("round ends at one survivor, winner flagged", function()
	local round = RoundLogic.new(0, opts)
	round:AddParticipant(1, "a")
	round:AddParticipant(2, "b")
	round:AddParticipant(3, "c")
	ok(not round:ShouldEnd())
	ok(round:Eliminate(3, 10, "Lava"))
	ok(not round:Eliminate(3, 11, "Lava"), "double elimination rejected")
	ok(round:Eliminate(2, 50, "Fall"))
	ok(round:ShouldEnd())
	round:Finish(50)
	local s = round:Standings()
	eq(s[1].id, 1)
	ok(s[1].isWinner)
	eq(s[2].id, 2)
	eq(s[2].placement, 2)
	eq(s[3].placement, 3)
end)

test("simultaneous last eliminations produce a draw", function()
	local round = RoundLogic.new(0, opts)
	round:AddParticipant(1, "a")
	round:AddParticipant(2, "b")
	round:AddParticipant(3, "c")
	round:Eliminate(3, 10, "Lava")
	round:Eliminate(1, 40, "Lava")
	round:Eliminate(2, 40.01, "Lava")
	round:Finish(40.01)
	local s = round:Standings()
	eq(s[1].placement, 1)
	eq(s[2].placement, 1)
	ok(s[1].isDraw and s[2].isDraw)
	ok(not s[1].isWinner)
	eq(s[3].placement, 3)
end)

test("player who left cannot win a draw", function()
	local round = RoundLogic.new(0, opts)
	round:AddParticipant(1, "a")
	round:AddParticipant(2, "b")
	round:Eliminate(1, 30, "Left")
	round:Eliminate(2, 30.01, "Lava")
	round:Finish(30.01)
	local s = round:Standings()
	local winner
	for _, st in s do
		if st.isWinner then
			winner = st.id
		end
	end
	eq(winner, 2)
end)

test("several survivors at the time cap share a draw", function()
	local round = RoundLogic.new(0, opts)
	round:AddParticipant(1, "a")
	round:AddParticipant(2, "b")
	round:AddParticipant(3, "c")
	round:Eliminate(3, 100, "Lava")
	round:Finish(225)
	local s = round:Standings()
	ok(s[1].isDraw and s[2].isDraw)
	ok(not s[1].isWinner and not s[2].isWinner)
	eq(s[3].placement, 3)
end)

test("training round ends only when the player is out", function()
	local round = RoundLogic.new(0, opts)
	round:AddParticipant(1, "solo")
	ok(not round:ShouldEnd())
	round:Eliminate(1, 5, "Lava")
	ok(round:ShouldEnd())
end)

local function standing(id, placement, survived, extra)
	local s = {
		id = id,
		placement = placement,
		survived = survived,
		isWinner = false,
		isDraw = false,
		left = false,
		active = true,
	}
	for k, v in extra or {} do
		s[k] = v
	end
	return s
end

test("winner gets 1 Win + 100 coins; 2nd 50; 3rd 30; first win of day bonus", function()
	local rewards = RewardRules.compute({
		standings = {
			standing(1, 1, 90, { isWinner = true }),
			standing(2, 2, 80),
			standing(3, 3, 30),
		},
		participantCount = 3,
		activeCount = 3,
		duration = 90,
		firstWinToday = { [1] = true },
	}, rewardConfig)
	eq(rewards[1].wins, 2)
	ok(rewards[1].countedWin)
	eq(rewards[1].coins, 100 + 5 + 15 + 5)
	eq(rewards[2].coins, 50 + 5 + 15)
	eq(rewards[3].coins, 30 + 5)
	eq(rewards[2].wins, 0)
end)

test("no Win when opponents were AFK or the round was too short", function()
	local afk = RewardRules.compute({
		standings = { standing(1, 1, 90, { isWinner = true }), standing(2, 2, 10, { active = false }) },
		participantCount = 2,
		activeCount = 1,
		duration = 90,
		firstWinToday = {},
	}, rewardConfig)
	eq(afk[1].wins, 0)
	ok(not afk[1].countedWin)
	eq(afk[2].coins, 0, "inactive gets nothing")

	local short = RewardRules.compute({
		standings = { standing(1, 1, 10, { isWinner = true }), standing(2, 2, 9) },
		participantCount = 2,
		activeCount = 2,
		duration = 10,
		firstWinToday = {},
	}, rewardConfig)
	eq(short[1].wins, 0)
end)

test("training gives XP only", function()
	local r = RewardRules.compute({
		standings = { standing(1, 1, 200, { isWinner = true }) },
		participantCount = 1,
		activeCount = 1,
		duration = 200,
		firstWinToday = { [1] = true },
	}, rewardConfig)
	eq(r[1].wins, 0)
	eq(r[1].coins, 0)
	ok(r[1].xp > 0)
end)

test("players who left get nothing", function()
	local r = RewardRules.compute({
		standings = { standing(1, 1, 100, { isWinner = true }), standing(2, 2, 50, { left = true }) },
		participantCount = 2,
		activeCount = 2,
		duration = 100,
		firstWinToday = {},
	}, rewardConfig)
	eq(r[2].coins, 0)
	eq(#r[2].lines, 0)
end)

test("level curve is monotonic and invertible", function()
	local cfg = EconomyConfig.Level
	eq((LevelCurve.fromTotalXp(0, cfg)), 1)
	local need = LevelCurve.xpToNext(1, cfg)
	eq((LevelCurve.fromTotalXp(need, cfg)), 2)
	for level = 2, 50 do
		local total = LevelCurve.totalXpForLevel(level, cfg)
		eq((LevelCurve.fromTotalXp(total, cfg)), level, "level " .. level)
		eq((LevelCurve.fromTotalXp(total - 1, cfg)), level - 1)
	end
end)

test("prng is deterministic and in range", function()
	local a, b = Prng.new(42), Prng.new(42)
	for _ = 1, 200 do
		local x = a:NextNumber()
		eq(x, b:NextNumber())
		ok(x >= 0 and x < 1)
		local i = a:NextInteger(3, 7)
		b:NextInteger(3, 7)
		ok(i >= 3 and i <= 7 and i == math.floor(i))
	end
	local counts = { 0, 0, 0 }
	local r = Prng.new(7)
	for _ = 1, 3000 do
		local idx = r:WeightedIndex({ 1, 2, 0 })
		counts[idx] += 1
	end
	eq(counts[3], 0)
	ok(counts[2] > counts[1])
end)

test("rate limiter refills over time", function()
	local now = 0
	local rl = RateLimiter.new(2, 1, function()
		return now
	end)
	ok(rl:Check("p"))
	ok(rl:Check("p"))
	ok(not rl:Check("p"))
	now = 1.1
	ok(rl:Check("p"))
end)

test("format helpers", function()
	eq(Format.commas(1234567), "1,234,567")
	eq(Format.commas(999), "999")
	eq(Format.clock(125), "2:05")
	eq(Format.compact(15300), "15.3K")
end)
