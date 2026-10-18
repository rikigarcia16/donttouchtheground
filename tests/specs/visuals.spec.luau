-- Builds every cosmetic on a synthetic R15 rig with real Roblox instances.
local test, eq, ok = Harness.test, Harness.eq, Harness.ok
local Catalog = require(Shared.Config.CosmeticCatalog)
local Visuals = require(Shared.Visual.CosmeticVisuals)
local FxKit = require(Shared.Visual.FxKit)
local EmoteLibrary = require(Shared.Visual.EmoteLibrary)

local R15 = {
	{ "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0) },
	{ "LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, 2.8, 0) },
	{ "UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 3.8, 0) },
	{ "Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 5.2, 0) },
	{ "LeftUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(-1.5, 4, 0) },
	{ "RightUpperArm", Vector3.new(1, 1.2, 1), Vector3.new(1.5, 4, 0) },
	{ "LeftLowerArm", Vector3.new(1, 1, 1), Vector3.new(-1.5, 3, 0) },
	{ "RightLowerArm", Vector3.new(1, 1, 1), Vector3.new(1.5, 3, 0) },
	{ "LeftHand", Vector3.new(1, 0.3, 1), Vector3.new(-1.5, 2.4, 0) },
	{ "RightHand", Vector3.new(1, 0.3, 1), Vector3.new(1.5, 2.4, 0) },
	{ "LeftUpperLeg", Vector3.new(1, 1.2, 1), Vector3.new(-0.5, 2, 0) },
	{ "RightUpperLeg", Vector3.new(1, 1.2, 1), Vector3.new(0.5, 2, 0) },
	{ "LeftLowerLeg", Vector3.new(1, 1, 1), Vector3.new(-0.5, 1, 0) },
	{ "RightLowerLeg", Vector3.new(1, 1, 1), Vector3.new(0.5, 1, 0) },
	{ "LeftFoot", Vector3.new(1, 0.3, 1), Vector3.new(-0.5, 0.3, 0) },
	{ "RightFoot", Vector3.new(1, 0.3, 1), Vector3.new(0.5, 0.3, 0) },
}

local ATTACHMENTS = {
	{ "Head", "HatAttachment", Vector3.new(0, 0.6, 0) },
	{ "Head", "FaceFrontAttachment", Vector3.new(0, 0, -0.6) },
	{ "UpperTorso", "BodyBackAttachment", Vector3.new(0, 0, 0.5) },
	{ "UpperTorso", "LeftShoulderAttachment", Vector3.new(-1, 0.8, 0) },
	{ "UpperTorso", "RightShoulderAttachment", Vector3.new(1, 0.8, 0) },
	{ "LeftFoot", "LeftFootAttachment", Vector3.new(0, -0.15, 0) },
	{ "RightFoot", "RightFootAttachment", Vector3.new(0, -0.15, 0) },
}

local MOTORS = {
	"Root",
	"Waist",
	"Neck",
	"LeftShoulder",
	"RightShoulder",
	"LeftElbow",
	"RightElbow",
	"LeftHip",
	"RightHip",
	"LeftKnee",
	"RightKnee",
}

local function rig()
	local model = Instance.new("Model")
	model.Name = "Dummy"
	local parts = {}
	for _, spec in R15 do
		local part = Instance.new("Part")
		part.Name = spec[1]
		part.Size = spec[2]
		part.CFrame = CFrame.new(spec[3])
		part.Parent = model
		parts[spec[1]] = part
	end
	for _, spec in ATTACHMENTS do
		local a = Instance.new("Attachment")
		a.Name = spec[2]
		a.CFrame = CFrame.new(spec[3])
		a.Parent = parts[spec[1]]
	end
	for _, name in MOTORS do
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Parent = parts.UpperTorso
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	return model
end

test("every catalogue item has a visual implementation", function()
	local missing = {}
	for _, item in Catalog.Items do
		if not Visuals.has(item) then
			table.insert(missing, item.id)
		end
	end
	eq(#missing, 0, "missing visuals: " .. table.concat(missing, ", "))
end)

for _, category in { "Trail", "Aura", "Accessory" } do
	test(category .. " builders run on an R15 rig", function()
		local built = 0
		for _, item in Catalog.byCategory(category) do
			local character = rig()
			local kit = FxKit.new(character, nil)
			local okBuild, err = pcall(Visuals[category][item.id], kit)
			ok(okBuild, item.id .. ": " .. tostring(err))
			-- Run the per-frame updaters with synthetic motion state.
			kit.speed, kit.verticalSpeed, kit.grounded = 10, 0, true
			for _, fn in kit.updaters do
				for _ = 1, 3 do
					local okUpdate, updateErr = pcall(fn, 1 / 30, kit)
					ok(okUpdate, item.id .. " update: " .. tostring(updateErr))
				end
				kit.time += 0.5
			end
			local count = #kit.folder:GetDescendants()
			for _, part in character:GetDescendants() do
				if part:IsA("Attachment") and part.Name == "DTTG_FX" then
					count += 1
				end
			end
			ok(count > 0 or #kit.updaters > 0, item.id .. " produced nothing")
			for _, d in kit.folder:GetDescendants() do
				if d:IsA("BasePart") then
					ok(
						not d.CanCollide and not d.CanQuery and not d.CanTouch,
						item.id .. " cosmetic part must not collide"
					)
				end
			end
			kit:Destroy()
			built += 1
		end
		ok(built > 0)
	end)
end

test("burst effects run (jump, landing, elimination)", function()
	local character = rig()
	for _, category in { "JumpEffect", "LandingEffect", "DeathEffect" } do
		for _, item in Catalog.byCategory(category) do
			local okRun, err = pcall(Visuals[category][item.id], Vector3.new(0, 10, 0), character)
			ok(okRun, item.id .. ": " .. tostring(err))
		end
	end
	ok(pcall(Visuals.DeathEffect.default, Vector3.new(0, 10, 0)))
end)

test("podiums and victory effects build", function()
	local parent = Instance.new("Folder")
	for _, item in Catalog.byCategory("Podium") do
		local okRun, model, height = pcall(Visuals.Podium[item.id], CFrame.new(0, 100, 0), parent)
		ok(okRun, item.id .. ": " .. tostring(model))
		ok(type(height) == "number" and height >= 0, item.id .. " stand height")
	end
	for _, item in Catalog.byCategory("WinAnimation") do
		local okRun, err = pcall(Visuals.WinAnimation[item.id], CFrame.new(0, 100, 0), rig())
		ok(okRun, item.id .. ": " .. tostring(err))
	end
end)

test("emote animations sample to valid joint transforms", function()
	for id, animation in EmoteLibrary.Animations do
		for _, t in { 0, 0.13, 0.5, 1.7, 5 } do
			local joints = EmoteLibrary.sample(animation, t)
			for joint, cf in joints do
				ok(typeof(cf) == "CFrame", id .. " " .. joint)
				ok(
					table.find(MOTORS, joint) or joint:match("Wrist") or joint:match("Ankle"),
					id .. " unknown joint " .. joint
				)
			end
		end
	end
	local motors = EmoteLibrary.motors(rig())
	ok(motors.Root and motors.Neck)
end)

test("title styles: rarer titles get richer treatment", function()
	local TitleStyles = Visuals.TitleStyles
	local common = TitleStyles.get("title_rookie")
	local mythic = TitleStyles.get("title_immortal")
	ok(common and mythic)
	ok(common.animate == 0 and not common.sparkles)
	ok(mythic.animate > 0 and mythic.sparkles and mythic.pulse)
end)
