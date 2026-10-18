-- Test harness: loads the Rojo source tree as fake Roblox instances so that
-- game modules using `require(script.Parent.X)` run unmodified under Lune.
-- Roblox datatypes (Vector3, Color3, Instance.new, Enum...) come from
-- @lune/roblox, which validates real property names and types.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local Harness = {}

local moduleCache: { [string]: any } = {}

local function makeNode(path: string, name: string, parent: any)
	local node = { __path = path, Name = name, Parent = parent, __children = {} }
	return setmetatable(node, {
		__index = function(self, key)
			local children = rawget(self, "__children")
			if children[key] then
				return children[key]
			end
			if key == "WaitForChild" or key == "FindFirstChild" then
				return function(_, childName)
					return rawget(self, "__children")[childName]
				end
			elseif key == "GetChildren" then
				return function()
					local list = {}
					for _, child in rawget(self, "__children") do
						table.insert(list, child)
					end
					table.sort(list, function(a, b)
						return a.Name < b.Name
					end)
					return list
				end
			elseif key == "IsA" then
				return function(_, className)
					return className == "ModuleScript"
				end
			end
			error("Harness: " .. tostring(key) .. " is not a child of " .. path, 2)
		end,
		__tostring = function()
			return "FakeInstance(" .. path .. ")"
		end,
	})
end

local function scan(dir: string, node: any)
	for _, entry in fs.readDir(dir) do
		local full = dir .. "/" .. entry
		if fs.isDir(full) then
			local child = makeNode(full, entry, node)
			rawget(node, "__children")[entry] = child
			scan(full, child)
		elseif entry:match("%.luau$") then
			local name = entry:gsub("%.server%.luau$", ""):gsub("%.client%.luau$", ""):gsub("%.luau$", "")
			if name == "init" then
				rawset(node, "__file", full)
			else
				local child = makeNode(full, name, node)
				rawset(child, "__file", full)
				rawget(node, "__children")[name] = child
			end
		end
	end
end

local fakeTask = {
	wait = function()
		return 0
	end,
	spawn = function(fn, ...)
		fn(...)
	end,
	defer = function(fn, ...)
		fn(...)
	end,
	delay = function() end,
	cancel = function() end,
}

Harness.sharedRoot = nil :: any

local function fakeService(name)
	local service = {}
	if name == "ReplicatedStorage" then
		function service.WaitForChild(_, child)
			assert(child == "Shared", "Harness ReplicatedStorage only exposes Shared")
			return Harness.sharedRoot
		end
		service.FindFirstChild = service.WaitForChild
	elseif name == "TweenService" then
		function service.Create(_, instance, _info, goal)
			return {
				Play = function() end,
				Cancel = function() end,
				Completed = {
					Connect = function()
						return { Disconnect = function() end }
					end,
					Wait = function() end,
				},
				__instance = instance,
				__goal = goal,
			}
		end
	elseif name == "Debris" then
		function service.AddItem() end
	elseif name == "RunService" then
		service.Heartbeat = {
			Connect = function()
				return { Disconnect = function() end, Connected = true }
			end,
		}
		service.RenderStepped = service.Heartbeat
		service.Stepped = service.Heartbeat
		service.PreSimulation = service.Heartbeat
		function service.IsStudio()
			return true
		end
		function service.IsServer()
			return false
		end
		function service.IsClient()
			return true
		end
	end
	return service
end

local fakeGame = {
	GetService = function(_, name)
		return fakeService(name)
	end,
}

Harness.env = {
	Instance = roblox.Instance,
	Vector3 = roblox.Vector3,
	Vector2 = roblox.Vector2,
	CFrame = roblox.CFrame,
	Color3 = roblox.Color3,
	ColorSequence = roblox.ColorSequence,
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
	NumberSequence = roblox.NumberSequence,
	NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
	NumberRange = roblox.NumberRange,
	UDim = roblox.UDim,
	UDim2 = roblox.UDim2,
	Rect = roblox.Rect,
	Font = roblox.Font,
	Enum = roblox.Enum,
	PhysicalProperties = roblox.PhysicalProperties,
	BrickColor = roblox.BrickColor,
	TweenInfo = {
		new = function(...)
			return { ... }
		end,
	},
	task = fakeTask,
	game = fakeGame,
	workspace = {},
	typeof = typeof,
	warn = function(...)
		print("[warn]", ...)
	end,
	tick = os.clock,
	os = os,
	math = math,
	string = string,
	table = table,
	bit32 = bit32,
	utf8 = utf8,
	coroutine = coroutine,
	pairs = pairs,
	ipairs = ipairs,
	next = next,
	type = type,
	tostring = tostring,
	tonumber = tonumber,
	select = select,
	pcall = pcall,
	xpcall = xpcall,
	error = error,
	assert = assert,
	setmetatable = setmetatable,
	getmetatable = getmetatable,
	rawget = rawget,
	rawset = rawset,
	rawequal = rawequal,
	print = print,
	unpack = table.unpack,
}

local function requireNode(node: any)
	local file = rawget(node, "__file")
	assert(file, "Harness: no source for " .. tostring(node))
	if moduleCache[file] ~= nil then
		return moduleCache[file]
	end
	local source = fs.readFile(file)
	local env = table.clone(Harness.env)
	env.script = node
	env.require = function(target)
		return requireNode(target)
	end
	local chunk = luau.load(source, { debugName = file, environment = env })
	local result = chunk()
	moduleCache[file] = result
	return result
end

function Harness.load(root: string)
	local node = makeNode(root, root, nil)
	scan(root, node)
	return node
end

Harness.require = requireNode
Harness.roblox = roblox

-- Tiny assertion library -------------------------------------------------
local results = { passed = 0, failed = 0, failures = {} }

function Harness.test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		results.passed += 1
	else
		results.failed += 1
		table.insert(results.failures, name .. ": " .. tostring(err))
		print("  FAIL " .. name .. "\n       " .. tostring(err))
	end
end

function Harness.eq(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", message or "eq", tostring(expected), tostring(actual)), 2)
	end
end

function Harness.ok(value: any, message: string?)
	if not value then
		error(message or "expected truthy", 2)
	end
end

function Harness.results()
	return results
end

return Harness
