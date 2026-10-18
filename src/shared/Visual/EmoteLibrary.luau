--!nonstrict
-- Procedural R15 animations (emotes and victory poses). Each pose maps a
-- Motor6D name to { rx, ry, rz [, px, py, pz] } in degrees/studs applied as
-- Motor6D.Transform. Purely visual: Transform never changes the hitbox.
--
-- Axis cheat-sheet (character faces -Z): shoulders Z+ raises the right arm
-- sideways (Z- for the left arm), X+ swings arms/legs forward, knees bend
-- with X-, waist/neck lean forward with X-.

local EmoteLibrary = {}

export type Pose = { [string]: { number } }
export type Animation = {
	loop: boolean,
	duration: number,
	keys: { { t: number, pose: Pose } },
	rootSpin: number?, -- degrees per second around Y
	jitter: number?, -- random shake amplitude (glitch)
	prop: string?, -- prop builder id
	glyphs: { chars: { string }, colors: { Color3 }, rate: number }?,
}

local RGB = Color3.fromRGB

local IDLE_ARMS = { LeftShoulder = { 0, 0, -8 }, RightShoulder = { 0, 0, 8 } }

local function merge(a: any, b: any): any
	local out = table.clone(a)
	for k, value in b do
		out[k] = value
	end
	return out
end

local A: { [string]: Animation } = {}

A.emote_wave = {
	loop = true,
	duration = 1.2,
	keys = {
		{
			t = 0,
			pose = {
				RightShoulder = { 0, 0, 155 },
				RightElbow = { 0, 0, 25 },
				LeftShoulder = { 0, 0, -8 },
				Neck = { 0, -10, 0 },
			},
		},
		{
			t = 0.3,
			pose = {
				RightShoulder = { 0, 0, 160 },
				RightElbow = { 0, 0, -30 },
				LeftShoulder = { 0, 0, -8 },
				Neck = { 0, -10, 0 },
			},
		},
		{
			t = 0.6,
			pose = {
				RightShoulder = { 0, 0, 155 },
				RightElbow = { 0, 0, 25 },
				LeftShoulder = { 0, 0, -8 },
				Neck = { 0, -10, 0 },
			},
		},
		{
			t = 0.9,
			pose = {
				RightShoulder = { 0, 0, 160 },
				RightElbow = { 0, 0, -30 },
				LeftShoulder = { 0, 0, -8 },
				Neck = { 0, -10, 0 },
			},
		},
	},
}

A.emote_dance = {
	loop = true,
	duration = 1,
	keys = {
		{
			t = 0,
			pose = {
				Root = { 0, 15, 0, 0, -0.2, 0 },
				Waist = { 0, -10, 8 },
				LeftShoulder = { 30, 0, -60 },
				RightShoulder = { -30, 0, 60 },
				LeftElbow = { 70, 0, 0 },
				RightElbow = { 70, 0, 0 },
				LeftHip = { 10, 0, 0 },
				LeftKnee = { -20, 0, 0 },
			},
		},
		{
			t = 0.25,
			pose = {
				Root = { 0, 0, 0, 0, 0.1, 0 },
				Waist = { 0, 0, 0 },
				LeftShoulder = { 80, 0, -20 },
				RightShoulder = { 80, 0, 20 },
				LeftElbow = { 40, 0, 0 },
				RightElbow = { 40, 0, 0 },
			},
		},
		{
			t = 0.5,
			pose = {
				Root = { 0, -15, 0, 0, -0.2, 0 },
				Waist = { 0, 10, -8 },
				LeftShoulder = { -30, 0, -60 },
				RightShoulder = { 30, 0, 60 },
				LeftElbow = { 70, 0, 0 },
				RightElbow = { 70, 0, 0 },
				RightHip = { 10, 0, 0 },
				RightKnee = { -20, 0, 0 },
			},
		},
		{
			t = 0.75,
			pose = {
				Root = { 0, 0, 0, 0, 0.1, 0 },
				LeftShoulder = { 80, 0, -20 },
				RightShoulder = { 80, 0, 20 },
				LeftElbow = { 40, 0, 0 },
				RightElbow = { 40, 0, 0 },
			},
		},
	},
}

A.emote_sit = {
	loop = false,
	duration = 0.6,
	keys = {
		{ t = 0, pose = IDLE_ARMS },
		{
			t = 0.6,
			pose = {
				Root = { 0, 0, 0, 0, -1.6, 0 },
				LeftHip = { 90, 0, -6 },
				RightHip = { 90, 0, 6 },
				LeftKnee = { -90, 0, 0 },
				RightKnee = { -90, 0, 0 },
				LeftShoulder = { 30, 0, -10 },
				RightShoulder = { 30, 0, 10 },
				LeftElbow = { 40, 0, 0 },
				RightElbow = { 40, 0, 0 },
			},
		},
	},
}

A.emote_laugh = {
	loop = true,
	duration = 0.5,
	glyphs = { chars = { "HA", "ha", "😂" }, colors = { RGB(255, 230, 90), RGB(255, 255, 255) }, rate = 3 },
	keys = {
		{
			t = 0,
			pose = {
				Waist = { 15, 0, 0 },
				Neck = { 20, 0, 0 },
				LeftShoulder = { 20, 0, -30 },
				RightShoulder = { 20, 0, 30 },
				LeftElbow = { 90, 0, 0 },
				RightElbow = { 90, 0, 0 },
			},
		},
		{
			t = 0.25,
			pose = {
				Waist = { -15, 0, 0 },
				Neck = { -5, 0, 0 },
				LeftShoulder = { 40, 0, -30 },
				RightShoulder = { 40, 0, 30 },
				LeftElbow = { 110, 0, 0 },
				RightElbow = { 110, 0, 0 },
			},
		},
	},
}

A.emote_clap = {
	loop = true,
	duration = 0.5,
	keys = {
		{
			t = 0,
			pose = {
				LeftShoulder = { 70, -30, -10 },
				RightShoulder = { 70, 30, 10 },
				LeftElbow = { 50, 0, 0 },
				RightElbow = { 50, 0, 0 },
			},
		},
		{
			t = 0.25,
			pose = {
				LeftShoulder = { 75, 20, -10 },
				RightShoulder = { 75, -20, 10 },
				LeftElbow = { 45, 0, 0 },
				RightElbow = { 45, 0, 0 },
			},
		},
	},
}

A.emote_robot = {
	loop = true,
	duration = 1.6,
	keys = {
		{
			t = 0,
			pose = {
				LeftShoulder = { 90, 0, 0 },
				RightShoulder = { 0, 0, 0 },
				LeftElbow = { 0, 0, 0 },
				RightElbow = { 90, 0, 0 },
				Neck = { 0, 30, 0 },
			},
		},
		{
			t = 0.4,
			pose = {
				LeftShoulder = { 90, 0, 0 },
				RightShoulder = { 0, 0, 0 },
				LeftElbow = { 0, 0, 0 },
				RightElbow = { 90, 0, 0 },
				Neck = { 0, 30, 0 },
			},
		},
		{
			t = 0.45,
			pose = {
				LeftShoulder = { 0, 0, 0 },
				RightShoulder = { 90, 0, 0 },
				LeftElbow = { 90, 0, 0 },
				RightElbow = { 0, 0, 0 },
				Neck = { 0, -30, 0 },
				Waist = { 0, 20, 0 },
			},
		},
		{
			t = 0.85,
			pose = {
				LeftShoulder = { 0, 0, 0 },
				RightShoulder = { 90, 0, 0 },
				LeftElbow = { 90, 0, 0 },
				RightElbow = { 0, 0, 0 },
				Neck = { 0, -30, 0 },
				Waist = { 0, 20, 0 },
			},
		},
		{
			t = 0.9,
			pose = {
				LeftShoulder = { 0, 0, -90 },
				RightShoulder = { 0, 0, 90 },
				LeftElbow = { 0, 0, 0 },
				RightElbow = { 0, 0, 0 },
				Waist = { 0, -20, 0 },
			},
		},
		{
			t = 1.55,
			pose = {
				LeftShoulder = { 0, 0, -90 },
				RightShoulder = { 0, 0, 90 },
				LeftElbow = { 0, 0, 0 },
				RightElbow = { 0, 0, 0 },
				Waist = { 0, -20, 0 },
			},
		},
	},
}

A.emote_spin = {
	loop = true,
	duration = 1,
	rootSpin = 540,
	keys = {
		{ t = 0, pose = { LeftShoulder = { 0, 0, -80 }, RightShoulder = { 0, 0, 80 }, Root = { 0, 0, 0, 0, 0.2, 0 } } },
		{
			t = 0.5,
			pose = { LeftShoulder = { 0, 0, -95 }, RightShoulder = { 0, 0, 95 }, Root = { 0, 0, 0, 0, 0.4, 0 } },
		},
	},
}

A.emote_sleep = {
	loop = true,
	duration = 3,
	glyphs = { chars = { "Z", "z", "💤" }, colors = { RGB(170, 180, 255), RGB(255, 255, 255) }, rate = 1.2 },
	keys = {
		{
			t = 0,
			pose = {
				Root = { -80, 0, 0, 0, -2.2, 0 },
				Neck = { 10, 20, 0 },
				LeftShoulder = { 160, 0, -10 },
				RightShoulder = { 30, 0, 20 },
				LeftElbow = { 60, 0, 0 },
				LeftHip = { 20, 0, 0 },
				LeftKnee = { -40, 0, 0 },
			},
		},
		{
			t = 1.5,
			pose = {
				Root = { -80, 0, 0, 0, -2.15, 0 },
				Neck = { 12, 20, 0 },
				LeftShoulder = { 160, 0, -10 },
				RightShoulder = { 32, 0, 20 },
				LeftElbow = { 60, 0, 0 },
				LeftHip = { 20, 0, 0 },
				LeftKnee = { -40, 0, 0 },
			},
		},
	},
}

A.emote_flex = {
	loop = true,
	duration = 1.4,
	keys = {
		{
			t = 0,
			pose = {
				LeftShoulder = { 0, 0, -90 },
				RightShoulder = { 0, 0, 90 },
				LeftElbow = { 0, 0, 0 },
				RightElbow = { 0, 0, 0 },
			},
		},
		{
			t = 0.4,
			pose = {
				LeftShoulder = { 0, 0, -90 },
				RightShoulder = { 0, 0, 90 },
				LeftElbow = { 0, -90, 0 },
				RightElbow = { 0, 90, 0 },
				Waist = { -5, 0, 0 },
			},
		},
		{
			t = 0.9,
			pose = {
				LeftShoulder = { 0, 0, -95 },
				RightShoulder = { 0, 0, 95 },
				LeftElbow = { 0, -110, 0 },
				RightElbow = { 0, 110, 0 },
				Waist = { -10, 0, 0 },
				Root = { 0, 0, 0, 0, -0.2, 0 },
			},
		},
	},
}

A.emote_celebrate = {
	loop = true,
	duration = 0.8,
	keys = {
		{
			t = 0,
			pose = {
				Root = { 0, 0, 0, 0, -0.4, 0 },
				LeftShoulder = { 0, 0, -150 },
				RightShoulder = { 0, 0, 150 },
				LeftHip = { 20, 0, 0 },
				RightHip = { 20, 0, 0 },
				LeftKnee = { -40, 0, 0 },
				RightKnee = { -40, 0, 0 },
			},
		},
		{
			t = 0.4,
			pose = {
				Root = { 0, 0, 0, 0, 1.2, 0 },
				LeftShoulder = { 0, 0, -170 },
				RightShoulder = { 0, 0, 170 },
				LeftElbow = { 20, 0, 0 },
				RightElbow = { 20, 0, 0 },
			},
		},
	},
}

A.emote_moonwalk = {
	loop = true,
	duration = 1,
	keys = {
		{
			t = 0,
			pose = {
				LeftHip = { -20, 0, 0 },
				LeftKnee = { -30, 0, 0 },
				LeftAnkle = { 30, 0, 0 },
				RightHip = { 15, 0, 0 },
				Waist = { -8, 0, 0 },
				LeftShoulder = { 20, 0, -10 },
				RightShoulder = { -20, 0, 10 },
			},
		},
		{
			t = 0.5,
			pose = {
				RightHip = { -20, 0, 0 },
				RightKnee = { -30, 0, 0 },
				RightAnkle = { 30, 0, 0 },
				LeftHip = { 15, 0, 0 },
				Waist = { -8, 0, 0 },
				LeftShoulder = { -20, 0, -10 },
				RightShoulder = { 20, 0, 10 },
			},
		},
	},
}

A.emote_ninja = {
	loop = false,
	duration = 0.5,
	keys = {
		{ t = 0, pose = IDLE_ARMS },
		{
			t = 0.5,
			pose = {
				Root = { 0, 30, 0, 0, -0.8, 0 },
				Waist = { -10, -20, 0 },
				RightShoulder = { 90, -40, 0 },
				RightElbow = { 90, 0, 0 },
				LeftShoulder = { 60, 40, -20 },
				LeftElbow = { 60, 0, 0 },
				LeftHip = { 50, 0, -20 },
				LeftKnee = { -60, 0, 0 },
				RightHip = { -20, 0, 15 },
				RightKnee = { -20, 0, 0 },
			},
		},
	},
}

A.emote_breakdance = {
	loop = true,
	duration = 1.2,
	rootSpin = 360,
	keys = {
		{
			t = 0,
			pose = {
				Root = { 0, 0, 80, 0, -2, 0 },
				LeftShoulder = { 0, 0, -170 },
				RightShoulder = { 0, 0, 20 },
				LeftHip = { 0, 0, -60 },
				RightHip = { 0, 0, 60 },
			},
		},
		{
			t = 0.6,
			pose = {
				Root = { 0, 0, 100, 0, -2, 0 },
				LeftShoulder = { 0, 0, -160 },
				RightShoulder = { 0, 0, 30 },
				LeftHip = { 0, 0, -80 },
				RightHip = { 0, 0, 80 },
			},
		},
	},
}

A.emote_guitar = {
	loop = true,
	duration = 0.6,
	prop = "guitar",
	keys = {
		{
			t = 0,
			pose = {
				Waist = { -10, 0, 0 },
				LeftShoulder = { 60, 40, -20 },
				LeftElbow = { 70, 0, 0 },
				RightShoulder = { 40, -20, 30 },
				RightElbow = { 70, 0, 0 },
				Neck = { -15, 0, 0 },
			},
		},
		{
			t = 0.3,
			pose = {
				Waist = { 5, 0, 0 },
				LeftShoulder = { 60, 40, -20 },
				LeftElbow = { 75, 0, 0 },
				RightShoulder = { 25, -20, 30 },
				RightElbow = { 90, 0, 0 },
				Neck = { 10, 0, 0 },
			},
		},
	},
}

A.emote_victory_pose = {
	loop = false,
	duration = 0.4,
	keys = {
		{ t = 0, pose = IDLE_ARMS },
		{
			t = 0.4,
			pose = {
				RightShoulder = { 0, 0, 165 },
				RightElbow = { 0, 0, 0 },
				LeftShoulder = { 0, 0, -30 },
				LeftElbow = { 0, 0, 0 },
				Waist = { 5, 15, 0 },
				Neck = { 10, 0, 0 },
			},
		},
	},
}

A.emote_champion_bow = {
	loop = false,
	duration = 0.8,
	keys = {
		{ t = 0, pose = IDLE_ARMS },
		{
			t = 0.8,
			pose = {
				Waist = { -50, 0, 0 },
				Neck = { -15, 0, 0 },
				RightShoulder = { 60, 0, 10 },
				RightElbow = { 90, 0, 0 },
				LeftShoulder = { -30, 0, -10 },
			},
		},
	},
}

A.emote_lava_surf = {
	loop = true,
	duration = 1.6,
	prop = "surfboard",
	keys = {
		{
			t = 0,
			pose = {
				Root = { 0, 70, 0, 0, -0.5, 0 },
				Waist = { 0, -60, 5 },
				LeftShoulder = { 0, 0, -80 },
				RightShoulder = { 0, 0, 80 },
				LeftHip = { 20, 0, -10 },
				RightHip = { 10, 0, 10 },
				LeftKnee = { -35, 0, 0 },
				RightKnee = { -25, 0, 0 },
			},
		},
		{
			t = 0.8,
			pose = {
				Root = { 0, 70, 6, 0, -0.3, 0 },
				Waist = { 0, -60, -5 },
				LeftShoulder = { 0, 0, -70 },
				RightShoulder = { 0, 0, 95 },
				LeftHip = { 25, 0, -10 },
				RightHip = { 5, 0, 10 },
				LeftKnee = { -40, 0, 0 },
				RightKnee = { -20, 0, 0 },
			},
		},
	},
}

A.emote_glitch = {
	loop = true,
	duration = 0.8,
	jitter = 12,
	glyphs = { chars = { "▓", "░", "█", "01" }, colors = { RGB(0, 255, 180), RGB(255, 0, 200) }, rate = 5 },
	keys = {
		{
			t = 0,
			pose = {
				LeftShoulder = { 0, 0, -45 },
				RightShoulder = { 0, 0, 130 },
				RightElbow = { 0, 0, 60 },
				Waist = { 0, 20, 0 },
			},
		},
		{
			t = 0.4,
			pose = {
				LeftShoulder = { 0, 0, -130 },
				RightShoulder = { 0, 0, 45 },
				LeftElbow = { 0, 0, -60 },
				Waist = { 0, -20, 0 },
			},
		},
	},
}

-- ======================================================= victory animations
A.win_victory_dance = merge(A.emote_dance, {}) :: any
A.win_backflip = {
	loop = false,
	duration = 1.4,
	keys = {
		{
			t = 0,
			pose = {
				Root = { 0, 0, 0, 0, -0.6, 0 },
				LeftHip = { 30, 0, 0 },
				RightHip = { 30, 0, 0 },
				LeftKnee = { -60, 0, 0 },
				RightKnee = { -60, 0, 0 },
				LeftShoulder = { -40, 0, -10 },
				RightShoulder = { -40, 0, 10 },
			},
		},
		{
			t = 0.35,
			pose = {
				Root = { 120, 0, 0, 0, 3, 0 },
				LeftHip = { 80, 0, 0 },
				RightHip = { 80, 0, 0 },
				LeftKnee = { -100, 0, 0 },
				RightKnee = { -100, 0, 0 },
				LeftShoulder = { 170, 0, -10 },
				RightShoulder = { 170, 0, 10 },
			},
		},
		{
			t = 0.65,
			pose = {
				Root = { 300, 0, 0, 0, 2.5, 0 },
				LeftHip = { 60, 0, 0 },
				RightHip = { 60, 0, 0 },
				LeftKnee = { -80, 0, 0 },
				RightKnee = { -80, 0, 0 },
			},
		},
		{
			t = 0.9,
			pose = {
				Root = { 360, 0, 0, 0, -0.4, 0 },
				LeftHip = { 20, 0, 0 },
				RightHip = { 20, 0, 0 },
				LeftKnee = { -40, 0, 0 },
				RightKnee = { -40, 0, 0 },
				LeftShoulder = { 0, 0, -100 },
				RightShoulder = { 0, 0, 100 },
			},
		},
		{
			t = 1.4,
			pose = { Root = { 360, 0, 0, 0, 0, 0 }, LeftShoulder = { 0, 0, -150 }, RightShoulder = { 0, 0, 150 } },
		},
	},
}
A.win_crown = merge(A.emote_victory_pose, {}) :: any
A.win_superhero = {
	loop = false,
	duration = 1.2,
	keys = {
		{ t = 0, pose = { Root = { 0, 0, 0, 0, 6, 0 }, LeftShoulder = { 0, 0, -170 }, RightShoulder = { 0, 0, 170 } } },
		{
			t = 0.4,
			pose = {
				Root = { -20, 0, 0, 0, -1.6, 0 },
				Waist = { -20, 0, 0 },
				RightHip = { 80, 0, 0 },
				RightKnee = { -110, 0, 0 },
				LeftHip = { -30, 0, 0 },
				LeftKnee = { -100, 0, 0 },
				RightShoulder = { -40, 0, 30 },
				LeftShoulder = { 20, 0, -10 },
				LeftElbow = { 20, 0, 0 },
			},
		},
		{
			t = 1.2,
			pose = {
				Root = { -15, 0, 0, 0, -1.5, 0 },
				Waist = { -15, 0, 0 },
				Neck = { 20, 0, 0 },
				RightHip = { 80, 0, 0 },
				RightKnee = { -110, 0, 0 },
				LeftHip = { -30, 0, 0 },
				LeftKnee = { -100, 0, 0 },
				RightShoulder = { -40, 0, 30 },
				LeftShoulder = { 20, 0, -10 },
			},
		},
	},
}
A.win_glitch = merge(A.emote_glitch, {}) :: any
A.win_lightning = {
	loop = false,
	duration = 0.8,
	keys = {
		{ t = 0, pose = IDLE_ARMS },
		{
			t = 0.8,
			pose = {
				LeftShoulder = { 0, 0, -170 },
				RightShoulder = { 0, 0, 170 },
				Neck = { 25, 0, 0 },
				Waist = { 10, 0, 0 },
				Root = { 0, 0, 0, 0, 0.5, 0 },
			},
		},
	},
}
A.win_fireworks = merge(A.emote_celebrate, {}) :: any
A.win_magic_portal = {
	loop = false,
	duration = 1,
	keys = {
		{ t = 0, pose = { Root = { 0, 0, 0, 0, -6, 0 } } },
		{
			t = 0.7,
			pose = { Root = { 0, 360, 0, 0, 0.5, 0 }, LeftShoulder = { 0, 0, -120 }, RightShoulder = { 0, 0, 120 } },
		},
		{
			t = 1,
			pose = {
				Root = { 0, 360, 0, 0, 0, 0 },
				LeftShoulder = { 0, 0, -60 },
				RightShoulder = { 0, 0, 150 },
				RightElbow = { 0, 0, 30 },
			},
		},
	},
}
A.win_golden_throne = merge(A.emote_sit, {}) :: any
A.win_cosmic = {
	loop = true,
	duration = 3,
	keys = {
		{
			t = 0,
			pose = {
				Root = { 0, 0, 0, 0, 1, 0 },
				LeftShoulder = { 0, 0, -120 },
				RightShoulder = { 0, 0, 120 },
				Neck = { 15, 0, 0 },
				LeftHip = { 10, 0, -10 },
				RightHip = { 10, 0, 10 },
			},
		},
		{
			t = 1.5,
			pose = {
				Root = { 0, 0, 0, 0, 2, 0 },
				LeftShoulder = { 0, 0, -135 },
				RightShoulder = { 0, 0, 135 },
				Neck = { 20, 0, 0 },
				LeftHip = { 15, 0, -15 },
				RightHip = { 15, 0, 15 },
			},
		},
	},
	rootSpin = 30,
}
A.win_dragon = {
	loop = true,
	duration = 1.2,
	keys = {
		{
			t = 0,
			pose = {
				Waist = { 15, 0, 0 },
				Neck = { 25, 0, 0 },
				LeftShoulder = { 0, 0, -140 },
				RightShoulder = { 0, 0, 140 },
				LeftElbow = { 0, 0, -40 },
				RightElbow = { 0, 0, 40 },
			},
		},
		{
			t = 0.6,
			pose = {
				Waist = { 20, 0, 0 },
				Neck = { 30, 0, 0 },
				LeftShoulder = { 0, 0, -160 },
				RightShoulder = { 0, 0, 160 },
				LeftElbow = { 0, 0, -20 },
				RightElbow = { 0, 0, 20 },
				Root = { 0, 0, 0, 0, 0.3, 0 },
			},
		},
	},
}

EmoteLibrary.Animations = A

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

-- Returns { [jointName]: CFrame } for an animation at `elapsed` seconds.
function EmoteLibrary.sample(animation: Animation, elapsed: number): { [string]: CFrame }
	local keys = animation.keys
	local t = elapsed
	if animation.loop then
		t = elapsed % animation.duration
	else
		t = math.min(elapsed, animation.duration)
	end
	local prev, nextKey = keys[1], keys[1]
	local span, alpha = 1, 0
	for i, key in keys do
		if key.t <= t then
			prev = key
			nextKey = keys[i + 1] or (if animation.loop then keys[1] else key)
		end
	end
	if nextKey ~= prev then
		local nextT = if nextKey.t > prev.t then nextKey.t else animation.duration + nextKey.t
		span = math.max(0.001, nextT - prev.t)
		alpha = smooth(math.clamp((t - prev.t) / span, 0, 1))
	end
	local joints: { [string]: CFrame } = {}
	local names = {}
	for name in prev.pose do
		names[name] = true
	end
	for name in nextKey.pose do
		names[name] = true
	end
	for name in names do
		local a = prev.pose[name] or { 0, 0, 0, 0, 0, 0 }
		local b = nextKey.pose[name] or { 0, 0, 0, 0, 0, 0 }
		local rx = math.rad(lerp(a[1] or 0, b[1] or 0, alpha))
		local ry = math.rad(lerp(a[2] or 0, b[2] or 0, alpha))
		local rz = math.rad(lerp(a[3] or 0, b[3] or 0, alpha))
		local px = lerp(a[4] or 0, b[4] or 0, alpha)
		local py = lerp(a[5] or 0, b[5] or 0, alpha)
		local pz = lerp(a[6] or 0, b[6] or 0, alpha)
		joints[name] = CFrame.new(px, py, pz) * CFrame.fromEulerAnglesYXZ(rx, ry, rz)
	end
	if animation.rootSpin then
		local spin = CFrame.Angles(0, math.rad(animation.rootSpin * elapsed), 0)
		joints.Root = spin * (joints.Root or CFrame.new())
	end
	if animation.jitter and math.random() < 0.3 then
		local j = math.rad(animation.jitter)
		for name, cf in joints do
			joints[name] = cf
				* CFrame.Angles((math.random() - 0.5) * j, (math.random() - 0.5) * j, (math.random() - 0.5) * j)
		end
	end
	return joints
end

-- Collects the Motor6Ds of a rig by name (R15: "Root", "Waist", "Neck", ...).
function EmoteLibrary.motors(character: Model): { [string]: Motor6D }
	local motors = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			motors[descendant.Name] = descendant
		end
	end
	return motors
end

-- Props held during some emotes (welded to the right hand / feet).
function EmoteLibrary.buildProp(kit, prop: string)
	if prop == "guitar" then
		local hand = kit:BodyPart("LeftHand")
		kit:Rig(hand, CFrame.new(0.3, -0.2, -0.6) * CFrame.Angles(0, math.rad(90), math.rad(-50)), {
			{
				size = Vector3.new(0.3, 1.5, 1.1),
				offset = CFrame.new(0, -0.8, 0),
				color = RGB(255, 40, 160),
				material = Enum.Material.Neon,
			},
			{
				size = Vector3.new(0.2, 2.2, 0.25),
				offset = CFrame.new(0, 1, 0),
				color = RGB(30, 30, 40),
				material = Enum.Material.SmoothPlastic,
			},
			{
				size = Vector3.new(0.32, 0.12, 0.9),
				offset = CFrame.new(0, -0.6, 0),
				color = RGB(60, 230, 255),
				material = Enum.Material.Neon,
			},
		})
	elseif prop == "surfboard" then
		local root = kit:BodyPart("HumanoidRootPart")
		kit:Rig(root, CFrame.new(0, -3, 0), {
			{
				size = Vector3.new(1.6, 0.25, 5),
				offset = CFrame.new(),
				color = RGB(255, 140, 30),
				material = Enum.Material.SmoothPlastic,
			},
			{
				size = Vector3.new(0.3, 0.27, 4.4),
				offset = CFrame.new(),
				color = RGB(255, 255, 255),
				material = Enum.Material.Neon,
			},
		})
	end
end

return EmoteLibrary
