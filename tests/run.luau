-- Entry point: `lune run tests/run.luau` from the repository root.
local fs = require("@lune/fs")
local process = require("@lune/process")
local luau = require("@lune/luau")

local Harness = require("./harness")

local shared = Harness.load("src/shared")
Harness.sharedRoot = shared
local server = Harness.load("src/server")

local specs = {}
for _, entry in fs.readDir("tests/specs") do
	if entry:match("%.spec%.luau$") then
		table.insert(specs, entry)
	end
end
table.sort(specs)

for _, spec in specs do
	print("▶ " .. spec)
	local source = fs.readFile("tests/specs/" .. spec)
	local env = table.clone(Harness.env)
	env.Harness = Harness
	env.Shared = shared
	env.Server = server
	env.require = function(target)
		return Harness.require(target)
	end
	local ok, err = pcall(function()
		luau.load(source, { debugName = spec, environment = env })()
	end)
	if not ok then
		Harness.test(spec .. " (load)", function()
			error(err)
		end)
	end
end

local results = Harness.results()
print(string.format("\n%d passed, %d failed", results.passed, results.failed))
if results.failed > 0 then
	process.exit(1)
end
