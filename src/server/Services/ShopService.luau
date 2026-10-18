--!nonstrict
-- Purchases with Wins/Coins. Fully server-validated: item exists, is for
-- sale, not owned, affordable. Deduction + delivery happen in one update and
-- each player can only run one purchase at a time.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local EconomyConfig = require(Shared.Config.EconomyConfig)
local ShopRules = require(Shared.Logic.ShopRules)
local FeaturedRotation = require(Shared.Logic.FeaturedRotation)
local Signal = require(Shared.Util.Signal)
local Remotes = require(Shared.Net.Remotes)
local Guard = require(script.Parent.Parent.Util.Guard)

local ShopService = {}
ShopService.Purchased = Signal.new() -- (player, itemId)

local PlayerData: any
local Currency: any
local Cosmetics: any

local FeaturedCfg = EconomyConfig.FeaturedShop

function ShopService.FeaturedNow(): ({ string }, { [string]: boolean }, number)
	local period = FeaturedRotation.periodIndex(os.time(), FeaturedCfg.RotationHours)
	local picks =
		FeaturedRotation.pick(CosmeticCatalog.Items :: any, period, FeaturedCfg.SlotCount, FeaturedCfg.MaxPerCategory)
	local set = {}
	for _, id in picks do
		set[id] = true
	end
	return picks, set, FeaturedRotation.secondsUntilNext(os.time(), FeaturedCfg.RotationHours)
end

function ShopService.Purchase(player: Player, itemId: string): { [string]: any }
	local profile = PlayerData.Get(player)
	if not profile then
		return { ok = false, reason = "NotLoaded" }
	end
	local item = CosmeticCatalog.get(itemId)
	local _, featuredSet = ShopService.FeaturedNow()
	local allowed, reason, price = ShopRules.canPurchase(profile, item :: any, featuredSet, FeaturedCfg.DiscountPercent)
	if not allowed or not item or not price then
		return { ok = false, reason = reason }
	end
	local delivered = Currency.SpendAtomic(player, item.currency, price, { "owned", "stats" }, function(p)
		p.owned[item.id] = os.time()
		p.stats.purchases += 1
	end)
	if not delivered then
		return { ok = false, reason = "NotEnough" .. item.currency }
	end
	print(string.format("[Shop] %s bought %s for %d %s", player.Name, item.id, price, item.currency))
	ShopService.Purchased:Fire(player, item.id)
	Cosmetics.ItemGranted:Fire(player, item.id, "Shop")
	return { ok = true, itemId = item.id, price = price, currency = item.currency }
end

function ShopService.Init(services)
	PlayerData = services.PlayerDataService
	Currency = services.CurrencyService
	Cosmetics = services.CosmeticService
end

function ShopService.Start()
	-- Initial client payload: profile + shop rotation.
	Guard.func(Remotes.func("GetBootstrap"), {}, 1, function(player)
		local profile = PlayerData.WaitFor(player, 25)
		local picks, _, secondsLeft = ShopService.FeaturedNow()
		return {
			ok = profile ~= nil,
			profile = if profile then PlayerData.Snapshot(profile) else nil,
			featured = picks,
			featuredEndsIn = secondsLeft,
			discountPercent = FeaturedCfg.DiscountPercent,
			memoryMode = PlayerData.IsMemoryMode(),
		}
	end)
	Guard.func(Remotes.func("Purchase"), { "string" }, 3, function(player, itemId)
		local ran, result = Guard.exclusive(player, function()
			return ShopService.Purchase(player, itemId)
		end)
		if not ran then
			return { ok = false, reason = "Busy" }
		end
		return result
	end)
end

return ShopService
