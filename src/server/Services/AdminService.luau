--!nonstrict
-- QA commands for live-state testing. Only available in Studio or to user ids
-- listed in GameConfig.AdminUserIds. Never reachable by regular players.
--   /dttg wins <n> | coins <n> | xp <n> | unlockall | event <id> | resetdata

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local CosmeticCatalog = require(Shared.Config.CosmeticCatalog)
local EventConfig = require(Shared.Config.EventConfig)
local ProfileSchema = require(Shared.Logic.ProfileSchema)

local AdminService = {}

local PlayerData: any
local Currency: any
local Events: any

local function isAdmin(player: Player): boolean
	return RunService:IsStudio() or table.find(GameConfig.AdminUserIds, player.UserId) ~= nil
end

local function handle(player: Player, message: string)
	local args = string.split(message, " ")
	if args[1] ~= "/dttg" or not isAdmin(player) then
		return
	end
	local command = args[2]
	local amount = math.clamp(tonumber(args[3]) or 0, 0, 100000)
	if command == "wins" then
		PlayerData.Update(player, { "wins" }, function(p)
			p.wins += math.floor(amount)
		end)
	elseif command == "coins" then
		Currency.Grant(player, { coins = math.min(amount, 20000) }, "admin")
	elseif command == "xp" then
		Currency.Grant(player, { xp = math.min(amount, 20000) }, "admin")
	elseif command == "unlockall" then
		PlayerData.Update(player, { "owned" }, function(p)
			for _, item in CosmeticCatalog.Items do
				p.owned[item.id] = p.owned[item.id] or os.time()
			end
		end)
	elseif command == "event" and args[3] and EventConfig.ById[args[3]] then
		Events.StartScheduled(args[3])
	elseif command == "resetdata" then
		PlayerData.Update(player, nil, function(p)
			local fresh = ProfileSchema.default(os.time())
			for key, value in fresh do
				p[key] = value
			end
		end)
	end
	print(string.format("[Admin] %s ran %s", player.Name, message))
end

function AdminService.Init(services)
	PlayerData = services.PlayerDataService
	Currency = services.CurrencyService
	Events = services.EventService
end

function AdminService.Start()
	local function hook(player: Player)
		player.Chatted:Connect(function(message)
			handle(player, message)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
end

return AdminService
