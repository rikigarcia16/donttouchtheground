--!nonstrict
-- Plays SFX by key (pooled Sound instances) and one music track at a time
-- with cross-fades. Missing/empty asset ids are skipped silently.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local AudioConfig = require(Shared.Config.AudioConfig)

local AudioController = {}
AudioController.sfxVolume = 0.8
AudioController.musicVolume = 0.5

local sfxGroup: SoundGroup
local musicGroup: SoundGroup
local pool: { [string]: { Sound } } = {}
local currentMusic: Sound? = nil
local currentMusicKey = ""

function AudioController.Play(key: string, pitchJitter: number?)
	local def = AudioConfig.Sfx[key]
	if not def or def.id == "" then
		return
	end
	local list = pool[key]
	if not list then
		list = {}
		pool[key] = list
	end
	local sound: Sound? = nil
	for _, candidate in list do
		if not candidate.IsPlaying then
			sound = candidate
			break
		end
	end
	if not sound then
		if #list >= 4 then
			sound = list[1]
		else
			local created = Instance.new("Sound")
			created.SoundId = def.id
			created.Volume = def.volume
			created.SoundGroup = sfxGroup
			created.Parent = sfxGroup
			table.insert(list, created)
			sound = created
		end
	end
	local s = sound :: Sound
	s.PlaybackSpeed = def.pitch * (1 + (pitchJitter or 0) * (math.random() - 0.5))
	s.TimePosition = 0
	s:Play()
end

function AudioController.PlayMusic(key: string?)
	local id = if key then AudioConfig.Music[key] else nil
	if key == currentMusicKey then
		return
	end
	currentMusicKey = key or ""
	local old = currentMusic
	if old then
		local fade = TweenService:Create(old, TweenInfo.new(1), { Volume = 0 })
		fade:Play()
		fade.Completed:Connect(function()
			old:Destroy()
		end)
		currentMusic = nil
	end
	if not id or id == "" then
		return
	end
	local music = Instance.new("Sound")
	music.SoundId = id
	music.Looped = true
	music.Volume = 0
	music.SoundGroup = musicGroup
	music.Parent = musicGroup
	music:Play()
	TweenService:Create(music, TweenInfo.new(1.5), { Volume = 0.6 }):Play()
	currentMusic = music
end

function AudioController.SetVolumes(sfx: number, music: number)
	AudioController.sfxVolume = sfx
	AudioController.musicVolume = music
	sfxGroup.Volume = sfx
	musicGroup.Volume = music
end

function AudioController.Start()
	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "DTTG_SFX"
	sfxGroup.Volume = AudioController.sfxVolume
	sfxGroup.Parent = SoundService
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "DTTG_Music"
	musicGroup.Volume = AudioController.musicVolume
	musicGroup.Parent = SoundService
	AudioController.PlayMusic("MusicLobby")
end

return AudioController
