--!strict
-- Minimal pure-Luau signal used for in-process communication between services.

local Signal = {}
Signal.__index = Signal

export type Connection = { Connected: boolean, Disconnect: (self: Connection) -> () }
export type Signal = typeof(setmetatable(
	{} :: { _handlers: { [number]: { fn: (...any) -> (), connected: boolean } } },
	Signal
))

function Signal.new(): Signal
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal.Connect(self: Signal, fn: (...any) -> ()): Connection
	local handler = { fn = fn, connected = true }
	table.insert(self._handlers, handler)
	local connection = {} :: any
	connection.Connected = true
	function connection.Disconnect(conn)
		conn.Connected = false
		handler.connected = false
		local index = table.find(self._handlers, handler)
		if index then
			table.remove(self._handlers, index)
		end
	end
	return connection
end

function Signal.Fire(self: Signal, ...: any)
	-- Copy so handlers may disconnect while firing.
	local snapshot = table.clone(self._handlers)
	for _, handler in snapshot do
		if handler.connected then
			local args = table.pack(...)
			local ok, err = pcall(function()
				handler.fn(table.unpack(args, 1, args.n))
			end)
			if not ok then
				warn("[Signal] handler error:", err)
			end
		end
	end
end

function Signal.DisconnectAll(self: Signal)
	for _, handler in self._handlers do
		handler.connected = false
	end
	table.clear(self._handlers)
end

return Signal
