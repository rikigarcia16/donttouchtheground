--!strict
-- Tracks connections, instances, threads and cleanup callbacks so every
-- temporary state (an event, a round, a cosmetic) can be torn down in one call.

local Maid = {}
Maid.__index = Maid

export type Maid = typeof(setmetatable({} :: { _tasks: { any } }, Maid))

function Maid.new(): Maid
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid.Add<T>(self: Maid, item: T): T
	table.insert(self._tasks, item)
	return item
end

local function cleanupTask(item: any)
	local kind = typeof(item)
	if kind == "function" then
		item()
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "thread" then
		if coroutine.status(item) ~= "dead" then
			pcall(task.cancel, item)
		end
	elseif kind == "table" then
		if type(item.Destroy) == "function" then
			item:Destroy()
		elseif type(item.Disconnect) == "function" then
			item:Disconnect()
		end
	end
end

function Maid.Clean(self: Maid)
	local tasks = self._tasks
	self._tasks = {}
	-- Clean in reverse so dependants are released before what they depend on.
	for i = #tasks, 1, -1 do
		local item = tasks[i]
		local ok, err = pcall(function()
			cleanupTask(item)
		end)
		if not ok then
			warn("[Maid] cleanup failed:", err)
		end
	end
end

Maid.Destroy = Maid.Clean

return Maid
