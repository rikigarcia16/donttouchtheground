--!nonstrict
-- Visual language of the UI: high-contrast slanted panels, punchy display
-- fonts, a hot-pink / electric-cyan / sun-yellow accent trio, controlled
-- shadows and snappy motion. Every screen pulls colours and fonts from here.

local RGB = Color3.fromRGB

local Theme = {
	Colors = {
		Ink = RGB(14, 12, 28), -- panel base
		InkSoft = RGB(28, 24, 52),
		InkLight = RGB(46, 40, 82),
		Paper = RGB(250, 248, 255),
		Muted = RGB(170, 165, 205),
		Pink = RGB(255, 46, 136),
		Cyan = RGB(32, 224, 255),
		Yellow = RGB(255, 214, 40),
		Green = RGB(70, 235, 130),
		Red = RGB(255, 70, 70),
		Orange = RGB(255, 140, 40),
		Purple = RGB(150, 90, 255),
		Wins = RGB(255, 205, 50),
		Coins = RGB(255, 170, 40),
		Xp = RGB(90, 220, 255),
		Shadow = RGB(0, 0, 0),
	},
	Fonts = {
		Display = Enum.Font.LuckiestGuy,
		Heavy = Enum.Font.GothamBlack,
		Bold = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Fun = Enum.Font.FredokaOne,
	},
	Motion = {
		Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Pop = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		Slide = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		Slow = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	},
	Slant = -4, -- degrees used by header ribbons and accent bars
	DesignSize = Vector2.new(1280, 720),
}

return Theme
