--!nonstrict
-- Client bootstrap. Controllers get Init(controllers) for wiring, then
-- Start() in order. A failing controller is reported but never blocks others.

local Controllers = script.Parent:WaitForChild("Controllers")

local ORDER = {
	"ClientState",
	"QualityController",
	"AudioController",
	"PlatformController",
	"LavaController",
	"MovementController",
	"CosmeticRenderer",
	"EmoteController",
	"CameraController",
	"AmbientController",
	"UIController",
}

local registry: { [string]: any } = {}
for _, name in ORDER do
	local module = Controllers:FindFirstChild(name)
	if module then
		local ok, result = pcall(require, module)
		if ok then
			registry[name] = result
		else
			warn("[Client] failed to load " .. name .. ": " .. tostring(result))
		end
	end
end

for _, name in ORDER do
	local controller = registry[name]
	if controller and controller.Init then
		local ok, err = pcall(controller.Init, registry)
		if not ok then
			warn("[Client] " .. name .. ".Init failed: " .. tostring(err))
		end
	end
end

for _, name in ORDER do
	local controller = registry[name]
	if controller and controller.Start then
		local ok, err = pcall(controller.Start)
		if not ok then
			warn("[Client] " .. name .. ".Start failed: " .. tostring(err))
		end
	end
end
