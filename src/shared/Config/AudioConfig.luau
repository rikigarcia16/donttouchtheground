--!strict
-- Every sound the game plays, by key. Values marked "rbxasset://" ship with the
-- Roblox client and always load. Music and premium SFX must be uploaded (or
-- taken from the Creator Store with a licence you hold) and pasted here as
-- "rbxassetid://<id>". Empty strings are skipped silently by AudioController.

local AudioConfig = {
	Sfx = {
		UiClick = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35, pitch = 1.6 },
		UiHover = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.12, pitch = 2.4 },
		UiOpen = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.4, pitch = 1.2 },
		UiError = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.4, pitch = 0.6 },
		Countdown = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6, pitch = 1 },
		CountdownGo = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.8, pitch = 1.5 },
		Jump = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.25, pitch = 1.1 },
		Land = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.3, pitch = 1 },
		Eliminated = { id = "rbxasset://sounds/action_falling.mp3", volume = 0.5, pitch = 1.3 },
		LavaSizzle = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.5, pitch = 0.5 },
		PlatformCrack = { id = "rbxasset://sounds/swordslash.wav", volume = 0.35, pitch = 0.6 },
		PlatformBreak = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.4, pitch = 0.5 },
		Bounce = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.5, pitch = 1.6 },
		PurchaseCommon = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, pitch = 1.2 },
		PurchaseRare = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6, pitch = 1.4 },
		PurchaseEpic = { id = "rbxasset://sounds/unsheath.wav", volume = 0.6, pitch = 1.2 },
		PurchaseLegendary = { id = "rbxasset://sounds/unsheath.wav", volume = 0.7, pitch = 1 },
		PurchaseMythic = { id = "rbxasset://sounds/unsheath.wav", volume = 0.8, pitch = 0.8 },
		Equip = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.35, pitch = 1.5 },
		Achievement = { id = "rbxasset://sounds/unsheath.wav", volume = 0.6, pitch = 1.3 },
		Victory = { id = "rbxasset://sounds/unsheath.wav", volume = 0.8, pitch = 0.9 },
		EventDanger = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6, pitch = 0.5 },
		EventMagic = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, pitch = 2 },
		EventRumble = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.7, pitch = 0.3 },
		EventWind = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.6, pitch = 0.6 },
		EventDark = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.5, pitch = 0.4 },
		EventPowerUp = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, pitch = 1.8 },
		EventFinal = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.8, pitch = 0.4 },
		MeteorImpact = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.6, pitch = 0.35 },
		Explosion = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.6, pitch = 0.45 },
		Coin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.4, pitch = 2.2 },
	},
	-- Upload your tracks and paste the ids. Left empty on purpose: the game
	-- never ships references to audio we could not verify.
	Music = {
		MusicLobby = "",
		MusicRainbowSky = "",
		MusicLavaFactory = "",
		MusicCandy = "",
		MusicSkyIslands = "",
		MusicNeonCity = "",
		MusicVolcano = "",
		MusicSuddenDeath = "",
		MusicResults = "",
	},
}

return AudioConfig
