--!nonstrict
-- Local mirror of the server profile and shop rotation. UI reads from here;
-- it never decides anything the server has not confirmed.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)
local Remotes = require(Shared.Net.Remotes)

local ClientState = {}
ClientState.Changed = Signal.new() -- (keys: { string }?)
ClientState.profile = nil :: { [string]: any }?
ClientState.featured = {} :: { string }
ClientState.featuredSet = {} :: { [string]: boolean }
ClientState.featuredEndsAt = 0
ClientState.discountPercent = 15
ClientState.memoryMode = false

function ClientState.Get(): { [string]: any }?
	return ClientState.profile
end

function ClientState.Owns(id: string): boolean
	local profile = ClientState.profile
	return profile ~= nil and profile.owned[id] ~= nil
end

function ClientState.Start()
	Remotes.event("DataSync").OnClientEvent:Connect(function(payload, full)
		if full or not ClientState.profile then
			ClientState.profile = payload
			ClientState.Changed:Fire(nil)
		else
			local keys = {}
			for key, value in payload do
				(ClientState.profile :: any)[key] = value
				table.insert(keys, key)
			end
			ClientState.Changed:Fire(keys)
		end
	end)
	task.spawn(function()
		for _ = 1, 5 do
			local ok, result = pcall(function()
				return Remotes.func("GetBootstrap"):InvokeServer()
			end)
			if ok and type(result) == "table" and result.ok then
				ClientState.profile = ClientState.profile or result.profile
				ClientState.featured = result.featured or {}
				ClientState.featuredSet = {}
				for _, id in ClientState.featured do
					ClientState.featuredSet[id] = true
				end
				ClientState.featuredEndsAt = os.clock() + (result.featuredEndsIn or 0)
				ClientState.discountPercent = result.discountPercent or 15
				ClientState.memoryMode = result.memoryMode == true
				ClientState.Changed:Fire(nil)
				return
			end
			task.wait(3)
		end
	end)
end

return ClientState
