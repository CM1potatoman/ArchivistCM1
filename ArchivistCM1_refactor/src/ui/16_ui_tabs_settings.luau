	["@src/ui/tabs/Settings"] = function()
local themes = {
	Nord = {
		FontColor = Color3.fromHex("e5e9f0"),
		MainColor = Color3.fromHex("2e3440"),
		AccentColor = Color3.fromHex("88c0d0"),
		BackgroundColor = Color3.fromHex("242933"),
		OutlineColor = Color3.fromHex("3b4252"),
	},
	Forest = {
		FontColor = Color3.fromHex("e8f5e9"),
		MainColor = Color3.fromHex("1b3124"),
		AccentColor = Color3.fromHex("66bb6a"),
		BackgroundColor = Color3.fromHex("15261c"),
		OutlineColor = Color3.fromHex("294334"),
	},
	Mint = {
		FontColor = Color3.fromHex("ffffff"),
		MainColor = Color3.fromHex("242424"),
		AccentColor = Color3.fromHex("3db488"),
		BackgroundColor = Color3.fromHex("1c1c1c"),
		OutlineColor = Color3.fromHex("373737"),
	},
	Transparent = {
		FontColor = Color3.fromHex("f1f5f9"),
		MainColor = Color3.fromHex("24313a"),
		AccentColor = Color3.fromHex("3db488"),
		BackgroundColor = Color3.fromHex("172129"),
		OutlineColor = Color3.fromHex("3b5964"),
	},
	Dracula = {
		FontColor = Color3.fromHex("ffffff"),
		MainColor = Color3.fromHex("232533"),
		AccentColor = Color3.fromHex("6271a5"),
		BackgroundColor = Color3.fromHex("1b1c27"),
		OutlineColor = Color3.fromHex("7c82a7"),
	},
	Midnight = {
		FontColor = Color3.fromHex("f5f7ff"),
		MainColor = Color3.fromHex("151826"),
		AccentColor = Color3.fromHex("4f7dff"),
		BackgroundColor = Color3.fromHex("10121b"),
		OutlineColor = Color3.fromHex("272c3f"),
	},
	Luma = {
		FontColor = Color3.fromHex("d7dff2"),
		MainColor = Color3.fromHex("171a2a"),
		AccentColor = Color3.fromHex("7896d4"),
		BackgroundColor = Color3.fromHex("0c0e18"),
		OutlineColor = Color3.fromHex("303b5e"),
	},
	Iceberg = {
		FontColor = Color3.fromHex("e0f4ff"),
		MainColor = Color3.fromHex("1f2933"),
		AccentColor = Color3.fromHex("5bc0eb"),
		BackgroundColor = Color3.fromHex("151a23"),
		OutlineColor = Color3.fromHex("324154"),
	},
	Monokai = {
		FontColor = Color3.fromHex("f8f8f2"),
		MainColor = Color3.fromHex("272822"),
		AccentColor = Color3.fromHex("a6e22e"),
		BackgroundColor = Color3.fromHex("1e1f1c"),
		OutlineColor = Color3.fromHex("49483e"),
	},
	Ocean = {
		FontColor = Color3.fromHex("e2f3f8"),
		MainColor = Color3.fromHex("173744"),
		AccentColor = Color3.fromHex("36c2c9"),
		BackgroundColor = Color3.fromHex("0d232c"),
		OutlineColor = Color3.fromHex("2a5663"),
	},
	Terminal = {
		FontColor = Color3.fromHex("d6f5d6"),
		MainColor = Color3.fromHex("13271a"),
		AccentColor = Color3.fromHex("78d882"),
		BackgroundColor = Color3.fromHex("0b180f"),
		OutlineColor = Color3.fromHex("31523a"),
	},
	["Solarized Light"] = {
		FontColor = Color3.fromHex("586e75"),
		MainColor = Color3.fromHex("eee8d5"),
		AccentColor = Color3.fromHex("268bd2"),
		BackgroundColor = Color3.fromHex("fdf6e3"),
		OutlineColor = Color3.fromHex("93a1a1"),
	},
	Ruby = {
		FontColor = Color3.fromHex("ffebf0"),
		MainColor = Color3.fromHex("321c28"),
		AccentColor = Color3.fromHex("f05a79"),
		BackgroundColor = Color3.fromHex("23131c"),
		OutlineColor = Color3.fromHex("633348"),
	},
	Sunset = {
		FontColor = Color3.fromHex("fff1e6"),
		MainColor = Color3.fromHex("38243d"),
		AccentColor = Color3.fromHex("ff8a5b"),
		BackgroundColor = Color3.fromHex("24182e"),
		OutlineColor = Color3.fromHex("70445d"),
	},
	Amethyst = {
		FontColor = Color3.fromHex("f4edff"),
		MainColor = Color3.fromHex("282039"),
		AccentColor = Color3.fromHex("b58cff"),
		BackgroundColor = Color3.fromHex("1b1628"),
		OutlineColor = Color3.fromHex("51406c"),
	},
	["Cherry Blossom"] = {
		FontColor = Color3.fromHex("fff0f5"),
		MainColor = Color3.fromHex("382632"),
		AccentColor = Color3.fromHex("ff8fb1"),
		BackgroundColor = Color3.fromHex("261a24"),
		OutlineColor = Color3.fromHex("70485d"),
	},
	Ember = {
		FontColor = Color3.fromHex("fff1dc"),
		MainColor = Color3.fromHex("38251e"),
		AccentColor = Color3.fromHex("ff7138"),
		BackgroundColor = Color3.fromHex("241813"),
		OutlineColor = Color3.fromHex("75432e"),
	},
	Sapphire = {
		FontColor = Color3.fromHex("e9f2ff"),
		MainColor = Color3.fromHex("1d2b43"),
		AccentColor = Color3.fromHex("5b9dff"),
		BackgroundColor = Color3.fromHex("121b2c"),
		OutlineColor = Color3.fromHex("354f75"),
	},
	["Lavender Mist"] = {
		FontColor = Color3.fromHex("f3f0ff"),
		MainColor = Color3.fromHex("29283d"),
		AccentColor = Color3.fromHex("a89aff"),
		BackgroundColor = Color3.fromHex("1b1a2c"),
		OutlineColor = Color3.fromHex("4b486f"),
	},
	["Golden Hour"] = {
		FontColor = Color3.fromHex("fff6df"),
		MainColor = Color3.fromHex("39301f"),
		AccentColor = Color3.fromHex("f2c14e"),
		BackgroundColor = Color3.fromHex("241e14"),
		OutlineColor = Color3.fromHex("75613b"),
	},
	Crimson = {
		FontColor = Color3.fromHex("ffe9ed"),
		MainColor = Color3.fromHex("351c25"),
		AccentColor = Color3.fromHex("f0445e"),
		BackgroundColor = Color3.fromHex("21131a"),
		OutlineColor = Color3.fromHex("6b3443"),
	},
	["Rose Quartz"] = {
		FontColor = Color3.fromHex("fff2f6"),
		MainColor = Color3.fromHex("382b37"),
		AccentColor = Color3.fromHex("e89bb9"),
		BackgroundColor = Color3.fromHex("251d28"),
		OutlineColor = Color3.fromHex("715268"),
	},
	["Coral Reef"] = {
		FontColor = Color3.fromHex("eafffb"),
		MainColor = Color3.fromHex("1e3537"),
		AccentColor = Color3.fromHex("39d6c5"),
		BackgroundColor = Color3.fromHex("122527"),
		OutlineColor = Color3.fromHex("397a78"),
	},
	Tangerine = {
		FontColor = Color3.fromHex("fff4e5"),
		MainColor = Color3.fromHex("3d2b20"),
		AccentColor = Color3.fromHex("ff9c38"),
		BackgroundColor = Color3.fromHex("281b14"),
		OutlineColor = Color3.fromHex("805333"),
	},
	Lemon = {
		FontColor = Color3.fromHex("fffde6"),
		MainColor = Color3.fromHex("36351e"),
		AccentColor = Color3.fromHex("e6dc45"),
		BackgroundColor = Color3.fromHex("242311"),
		OutlineColor = Color3.fromHex("77733a"),
	},
	Jade = {
		FontColor = Color3.fromHex("e6fff5"),
		MainColor = Color3.fromHex("1d382e"),
		AccentColor = Color3.fromHex("38d99a"),
		BackgroundColor = Color3.fromHex("12271f"),
		OutlineColor = Color3.fromHex("367a5c"),
	},
	Evergreen = {
		FontColor = Color3.fromHex("e8f3e8"),
		MainColor = Color3.fromHex("24352a"),
		AccentColor = Color3.fromHex("8dbb67"),
		BackgroundColor = Color3.fromHex("17251c"),
		OutlineColor = Color3.fromHex("4c6849"),
	},
	Arctic = {
		FontColor = Color3.fromHex("effaff"),
		MainColor = Color3.fromHex("263641"),
		AccentColor = Color3.fromHex("70d7f5"),
		BackgroundColor = Color3.fromHex("17232d"),
		OutlineColor = Color3.fromHex("4a7182"),
	},
	Glacier = {
		FontColor = Color3.fromHex("eaf7ff"),
		MainColor = Color3.fromHex("253849"),
		AccentColor = Color3.fromHex("8bbcff"),
		BackgroundColor = Color3.fromHex("172635"),
		OutlineColor = Color3.fromHex("4d6e94"),
	},
	Cobalt = {
		FontColor = Color3.fromHex("edf1ff"),
		MainColor = Color3.fromHex("202947"),
		AccentColor = Color3.fromHex("536dfe"),
		BackgroundColor = Color3.fromHex("141b35"),
		OutlineColor = Color3.fromHex("3a4d8d"),
	},
	["Royal Purple"] = {
		FontColor = Color3.fromHex("f6eeff"),
		MainColor = Color3.fromHex("30213f"),
		AccentColor = Color3.fromHex("bd75f5"),
		BackgroundColor = Color3.fromHex("1e162b"),
		OutlineColor = Color3.fromHex("654586"),
	},
	["Grape Soda"] = {
		FontColor = Color3.fromHex("f8eeff"),
		MainColor = Color3.fromHex("34213c"),
		AccentColor = Color3.fromHex("dc72e8"),
		BackgroundColor = Color3.fromHex("24162d"),
		OutlineColor = Color3.fromHex("70427a"),
	},
	["Neon Noir"] = {
		FontColor = Color3.fromHex("f1f5f9"),
		MainColor = Color3.fromHex("20242c"),
		AccentColor = Color3.fromHex("ff3cac"),
		BackgroundColor = Color3.fromHex("12151b"),
		OutlineColor = Color3.fromHex("64405f"),
	},
	Coffee = {
		FontColor = Color3.fromHex("f4e6d5"),
		MainColor = Color3.fromHex("382b23"),
		AccentColor = Color3.fromHex("c58b5b"),
		BackgroundColor = Color3.fromHex("241b16"),
		OutlineColor = Color3.fromHex("70513b"),
	},
	Sandstone = {
		FontColor = Color3.fromHex("453b2c"),
		MainColor = Color3.fromHex("e8dcc5"),
		AccentColor = Color3.fromHex("b47b45"),
		BackgroundColor = Color3.fromHex("f4ead7"),
		OutlineColor = Color3.fromHex("b8a486"),
	},
	Paper = {
		FontColor = Color3.fromHex("30343b"),
		MainColor = Color3.fromHex("f0f1ed"),
		AccentColor = Color3.fromHex("4776a8"),
		BackgroundColor = Color3.fromHex("fafaf7"),
		OutlineColor = Color3.fromHex("a9b0b8"),
	},
	Graphite = {
		FontColor = Color3.fromHex("e1e5e9"),
		MainColor = Color3.fromHex("292d32"),
		AccentColor = Color3.fromHex("aeb8c2"),
		BackgroundColor = Color3.fromHex("1a1d21"),
		OutlineColor = Color3.fromHex("555d65"),
	},
	Steel = {
		FontColor = Color3.fromHex("e7edf2"),
		MainColor = Color3.fromHex("28333c"),
		AccentColor = Color3.fromHex("8da9bd"),
		BackgroundColor = Color3.fromHex("19232b"),
		OutlineColor = Color3.fromHex("526978"),
	},
	Toxic = {
		FontColor = Color3.fromHex("f0ffe8"),
		MainColor = Color3.fromHex("28351e"),
		AccentColor = Color3.fromHex("a8ef38"),
		BackgroundColor = Color3.fromHex("192411"),
		OutlineColor = Color3.fromHex("5e7d34"),
	},
	Void = {
		FontColor = Color3.fromHex("eeeaff"),
		MainColor = Color3.fromHex("211d36"),
		AccentColor = Color3.fromHex("806bff"),
		BackgroundColor = Color3.fromHex("131123"),
		OutlineColor = Color3.fromHex("453d75"),
	},
	["High Contrast"] = {
		FontColor = Color3.fromHex("f5f5f5"),
		MainColor = Color3.fromHex("1b1b1b"),
		AccentColor = Color3.fromHex("ffda44"),
		BackgroundColor = Color3.fromHex("101010"),
		OutlineColor = Color3.fromHex("505050"),
	},
}

local createAmbience = require("@src/ui/ambience")
local customThemes = {}
local themeTransparencies = {
	Luma = {
		MainColor = 0.14,
		BackgroundColor = 0.24,
		OutlineColor = 0.34,
	},
	Transparent = {
		MainColor = 0.16,
		BackgroundColor = 0.24,
		OutlineColor = 0.32,
	},
}
local watermarkGeneration = 0
local watermarkRenderConnection
local honeyPerHourGeneration = 0
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local titleFontNames = {}
for _, font in ipairs(Enum.Font:GetEnumItems()) do
	table.insert(titleFontNames, font.Name)
end
table.sort(titleFontNames)

local function getPingText()
	local ok, result = pcall(function()
		local stats = game:GetService("Stats")
		local network = stats:FindFirstChild("Network")
		local serverStats = network and network:FindFirstChild("ServerStatsItem")
		local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")
		return dataPing and dataPing:GetValueString() or "n/a"
	end)
	local ping = ok and tonumber(tostring(result):match("[%d%.]+"))
	return ping and string.format("%d ms", math.floor(ping + 0.5)) or "n/a"
end

local function setThemeTransparency(library, transparencies)
	local connection = library.ThemeTransparencyConnection
	if connection then
		connection:Disconnect()
		library.ThemeTransparencyConnection = nil
	end

	local defaults = library.ThemeTransparencyDefaults
	if defaults then
		for object, transparency in pairs(defaults) do
			if object.Parent then
				object.BackgroundTransparency = transparency
			end
		end
	end
	library.ThemeTransparencyDefaults = nil

	if type(transparencies) ~= "table" then
		return
	end

	defaults = setmetatable({}, { __mode = "k" })
	local function applyTransparency(object)
		if not object:IsA("GuiObject") or object.BackgroundTransparency >= 1 then
			return
		end

		local surfaceName
		if object.BackgroundColor3 == library.MainColor then
			surfaceName = "MainColor"
		elseif object.BackgroundColor3 == library.BackgroundColor then
			surfaceName = "BackgroundColor"
		elseif object.BackgroundColor3 == library.OutlineColor then
			surfaceName = "OutlineColor"
		end
		local transparency = surfaceName and transparencies[surfaceName]
		if transparency then
			defaults[object] = object.BackgroundTransparency
			object.BackgroundTransparency = math.max(object.BackgroundTransparency, transparency)
		end
	end

	library.ThemeTransparencyDefaults = defaults
	for _, descendant in ipairs(library.ScreenGui:GetDescendants()) do
		applyTransparency(descendant)
	end
	library.ThemeTransparencyConnection = library.ScreenGui.DescendantAdded:Connect(applyTransparency)
end

local function applyTheme(library, colors, themeName)
	for key, color in pairs(colors) do
		library[key] = color
		local option = aztup_options["Wiggins_" .. key]
		if option then
			option:SetValueRGB(color)
		end
	end
	library.AccentColorDark = library:GetDarkerColor(library.AccentColor)
	library:UpdateColorsUsingRegistry()
	local gradientEnabled = library.WindowOutlineGradientEnabled
	library:SetWindowOutlineGradient(
		gradientEnabled,
		library.AccentColor,
		library.AccentColorDark,
		library.WindowOutlineGradientDuration
	)
	library:SetThemeStyle(themeName)
	setThemeTransparency(library, themeTransparencies[themeName])
end

local function applySavedTheme(library, snapshot, defaultTheme)
	if type(defaultTheme) == "string" and themes[defaultTheme] then
		for key, color in pairs(themes[defaultTheme]) do
			library[key] = color
		end
		library.AccentColorDark = library:GetDarkerColor(library.AccentColor)
		library:UpdateColorsUsingRegistry()
		library:SetThemeStyle(defaultTheme)
		setThemeTransparency(library, themeTransparencies[defaultTheme])
		return defaultTheme
	end

	local options = snapshot and snapshot.options
	if type(options) ~= "table" then
		local fallbackTheme = "Luma"
		for key, color in pairs(themes[fallbackTheme]) do
			library[key] = color
		end
		library.AccentColorDark = library:GetDarkerColor(library.AccentColor)
		library:UpdateColorsUsingRegistry()
		library:SetThemeStyle(fallbackTheme)
		setThemeTransparency(library, themeTransparencies[fallbackTheme])
		return fallbackTheme
	end

	local themeOption = options.Wiggins_Theme
	local themeName = themeOption and themeOption.value
	if type(themeName) == "string" and themes[themeName] then
		for key, color in pairs(themes[themeName]) do
			library[key] = color
		end
	else
		themeName = "Luma"
		for key, color in pairs(themes[themeName]) do
			library[key] = color
		end
	end

	for _, key in ipairs({ "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }) do
		local colorOption = options["Wiggins_" .. key]
		local colorValue = colorOption and colorOption.value
		if colorOption and colorOption.type == "ColorPicker" and type(colorValue) == "table" and type(colorValue.hex) == "string" then
			library[key] = Color3.fromHex(colorValue.hex)
		end
	end

	library.AccentColorDark = library:GetDarkerColor(library.AccentColor)
	library:UpdateColorsUsingRegistry()
	library:SetThemeStyle(themeName)
	setThemeTransparency(library, themeTransparencies[themeName])
	return themeName
end

local function applyThemeByName(library, name)
	local colors = themes[name]
	if not colors then
		return false
	end
	applyTheme(library, colors, name)
	return true
end

local function setupSettings(tab, context)
	local outlineGradientEnabled = true
	local outlineGradientDuration = 2
	local function updateOutlineGradient()
		context.Library.WindowOutlineGradientEnabled = outlineGradientEnabled
		context.Library.WindowOutlineGradientDuration = outlineGradientDuration
		context.Library:SetWindowOutlineGradient(
			outlineGradientEnabled,
			context.Library.AccentColor,
			context.Library.AccentColorDark,
			outlineGradientDuration
		)
		if context.Library.VisualsController then
			context.Library.VisualsController:SetGradient(outlineGradientEnabled, outlineGradientDuration)
		end
	end
	updateOutlineGradient()

	local ambience = context.Ambience or createAmbience(context.Library)
	context.Ambience = ambience
	ambience:SetMode("Rain")
	local atmosphere = tab:AddLeftGroupbox("Screen Effect")
	atmosphere:AddDropdown("YSL_Ambience", {
		Text = "Screen effect",
		Values = { "Off", "Rain", "Snow" },
		Default = "Rain",
		Callback = function(value)
			ambience:SetMode(value)
		end,
	})
	atmosphere:AddSlider("YSL_AmbienceIntensity", {
		Text = "Rain / snow intensity",
		Default = 36,
		Min = 12,
		Max = 48,
		Rounding = 0,
		Callback = function(value)
			ambience:SetIntensity(value)
		end,
	})

	local themesGroup = tab:AddLeftGroupbox("Themes")
	local themeNames = {}
	local defaultTheme = context.StartupTheme
	if not defaultTheme then
		defaultTheme = "Luma"
	end
	for name in pairs(themes) do
		table.insert(themeNames, name)
	end
	table.sort(themeNames)
	themesGroup:AddDropdown("Wiggins_Theme", {
		Text = "Theme list",
		Tooltip = "Choose a color theme. Transparent also adds translucency to the UI surfaces.",
		Values = themeNames,
		Default = defaultTheme,
		Searchable = true,
		Callback = function(name)
			if themes[name] then
				outlineGradientEnabled = true
				applyTheme(context.Library, themes[name], name)
				updateOutlineGradient()
			end
		end,
	})
	themesGroup:AddButton("Set theme as default", function()
		local themeName = aztup_options.Wiggins_Theme.Value
		if not themeName then
			context.SetStatus("select a theme first")
			return
		end
		local ok, err = context.Config:SetDefaultTheme(themeName)
		context.SetStatus(ok and ("default theme: " .. themeName) or err)
	end)
	themesGroup:AddInput("Wiggins_CustomThemeName", {
		Text = "Custom theme name",
		Default = "My theme",
		Finished = true,
	})
	themesGroup:AddButton("Save custom theme", function()
		local name = aztup_options.Wiggins_CustomThemeName.Value
		if name == "" then
			context.SetStatus("enter a theme name")
			return
		end
		local colors = {}
		for _, key in ipairs({ "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }) do
			colors[key] = context.Library[key]
		end
		customThemes[name] = colors
		context.SetStatus("saved theme " .. name)
	end)
	themesGroup:AddDropdown("Wiggins_CustomThemeList", {
		Text = "Custom themes",
		Values = {},
		AllowNull = true,
		Searchable = true,
	})
	themesGroup:AddButton("Refresh custom themes", function()
		local names = {}
		for name in pairs(customThemes) do
			table.insert(names, name)
		end
		table.sort(names)
		aztup_options.Wiggins_CustomThemeList:SetValues(names)
		context.SetStatus("custom themes refreshed")
	end)
	themesGroup:AddButton("Load custom theme", function()
		local name = aztup_options.Wiggins_CustomThemeList.Value
		if customThemes[name] then
			applyTheme(context.Library, customThemes[name])
			context.SetStatus("loaded theme " .. name)
		end
	end)
	themesGroup:AddDivider()
	for _, name in ipairs({ "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor" }) do
		local title = name:gsub("(%l)(%u)", "%1 %2")
		themesGroup:AddLabel(title):AddColorPicker("Wiggins_" .. name, {
			Default = context.Library[name],
			Title = title,
			Callback = function(color)
				context.Library[name] = color
				context.Library.AccentColorDark = context.Library:GetDarkerColor(context.Library.AccentColor)
				context.Library:UpdateColorsUsingRegistry()
				setThemeTransparency(
					context.Library,
					themeTransparencies[aztup_options.Wiggins_Theme.Value]
				)
				updateOutlineGradient()
			end,
		})
	end

	local interface = tab:AddLeftGroupbox("Interface")
	interface:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
		Default = "RightAlt",
		NoUI = true,
		Text = "Menu keybind",
	})
	context.Library.ToggleKeybind = aztup_options.MenuKeybind
	interface:AddSlider("Wiggins_UIScale", {
		Text = "UI Scale",
		Default = 100,
		Min = 50,
		Max = 150,
		Rounding = 0,
		Suffix = "%",
		Callback = function(value)
			context.Library:SetUIScale(value / 100)
		end,
	})
	local customTitleColorEnabled = false
	local titleColor = context.Library.FontColor
	interface:AddLabel("Script title color"):AddColorPicker("YSL_WindowTitleColor", {
		Default = titleColor,
		Title = "Script title color",
		Callback = function(color)
			titleColor = color
			if customTitleColorEnabled then
				context.Library:SetWindowTitleColor(titleColor)
			end
		end,
	})
	interface:AddToggle("YSL_UseCustomTitleColor", {
		Text = "Use custom title color",
		Tooltip = "When off, the title follows the theme and animated gradient.",
		Default = false,
		Callback = function(enabled)
			customTitleColorEnabled = enabled
			context.Library:SetWindowTitleColor(enabled and titleColor or nil)
		end,
	})
	interface:AddInput("YSL_WindowTitle", {
		Text = "Script name",
		Default = "YSL METHOD",
		MaxLength = 24,
		Finished = true,
		Callback = function(value)
			value = string.gsub(value, "^%s*(.-)%s*$", "%1")
			if value ~= "" then
				local title, accent = value:match("^(%S+)%s*(.-)$")
				context.Window:SetWindowTitle(title or value, accent or "")
			end
		end,
	})
	interface:AddDropdown("YSL_WindowTitleFont", {
		Text = "Interface font",
		Tooltip = "Change the font used by all script UI text.",
		Values = titleFontNames,
		Default = context.Library.UIFontName or "Gotham",
		Searchable = true,
		Callback = function(fontName)
			context.Library:SetUIFont(fontName)
		end,
	})
	local windowCornerRadius = 8
	local windowCornerRadiusSlider = interface:AddSlider("Wiggins_OuterWindowRadius", {
		Text = "UI corner radius",
		Tooltip = "Set the radius of the window and UI widget corners. Set to zero for square corners.",
		Default = windowCornerRadius,
		Min = 0,
		Max = 16,
		Rounding = 0,
		Suffix = " px",
		Disabled = true,
		Callback = function(value)
			windowCornerRadius = value
			local cornerToggle = aztup_toggles.Wiggins_RoundOuterWindow
			if cornerToggle and cornerToggle.Value then
				context.Library:SetWindowCornerRadius(windowCornerRadius)
			end
		end,
	})
	interface:AddToggle("Wiggins_RoundOuterWindow", {
		Text = "Round window and widgets",
		Tooltip = "Applies the selected corner radius to the window and UI widgets.",
		Default = false,
		Callback = function(enabled)
			windowCornerRadiusSlider:SetDisabled(not enabled)
			context.Library:SetWindowCornerRadius(enabled and windowCornerRadius or nil)
		end,
	})
	interface:AddToggle("YSL_ShowSideImage", {
		Text = "Cute anime girl",
		Tooltip = "Show or hide the anime girl image above the window.",
		Default = true,
		Callback = function(enabled)
			if context.SideImage then
				context.SideImage:SetEnabled(enabled)
			end
		end,
	})

	local configuration = tab:AddRightGroupbox("Configuration")
	configuration:AddLabel("Configuration profiles")
	configuration:AddLabel("Configs are saved locally when file APIs are available.")
	configuration:AddInput("Wiggins_ConfigName", {
		Text = "Config name",
		Default = "default",
		Finished = false,
	})
	configuration:AddButton("Create / overwrite", function()
		local name = aztup_options.Wiggins_ConfigName.Value
		local ok, err = context.Config:Save(name)
		if ok then
			aztup_options.Wiggins_ConfigList:SetValues(context.Config:List())
			aztup_options.Wiggins_ConfigList:SetValue(name)
		end
		context.SetStatus(ok and ("saved " .. name) or err)
	end)
	configuration:AddDropdown("Wiggins_ConfigList", {
		Text = "Config list",
		Values = context.Config:List(),
		AllowNull = true,
		Searchable = true,
	})
	configuration:AddButton("Load config", function()
		local name = aztup_options.Wiggins_ConfigList.Value
		local ok, err = context.Config:Load(name)
		context.SetStatus(ok and ("loaded " .. tostring(name)) or err)
	end)
	configuration:AddButton("Overwrite config", function()
		local name = aztup_options.Wiggins_ConfigList.Value
		local ok, err = context.Config:Save(name)
		context.SetStatus(ok and ("overwrote " .. tostring(name)) or err)
	end)
	configuration:AddButton("Refresh config list", function()
		aztup_options.Wiggins_ConfigList:SetValues(context.Config:List())
		context.SetStatus("config list refreshed")
	end)
	local autoloadStatus = configuration:AddLabel("Autoload config: " .. tostring(context.Config:GetAutoLoadName() or "off"))
	configuration:AddButton("Set selected as autoload", function()
		local name = aztup_options.Wiggins_ConfigList.Value
		local ok, err = context.Config:SetAutoLoad(name)
		if ok then
			autoloadStatus:SetText("Autoload config: " .. name)
		end
		context.SetStatus(ok and ("autoload config: " .. name) or err)
	end)
	configuration:AddButton("Clear autoload config", function()
		local ok, err = context.Config:SetAutoLoad(nil)
		if ok then
			autoloadStatus:SetText("Autoload config: off")
		end
		context.SetStatus(ok and "autoload config cleared" or err)
	end)
	configuration:AddButton("Delete config", function()
		local name = aztup_options.Wiggins_ConfigList.Value
		local ok = context.Config:Delete(name)
		aztup_options.Wiggins_ConfigList:SetValues(context.Config:List())
		if ok and context.Config:GetAutoLoadName() then
			autoloadStatus:SetText("Autoload config: " .. context.Config:GetAutoLoadName())
		elseif ok then
			autoloadStatus:SetText("Autoload config: off")
		end
		context.SetStatus(ok and ("deleted " .. tostring(name)) or "config not found")
	end)

	local arrayListGroup = tab:AddLeftGroupbox("Array List")
	local arrayList = context.ArrayList
	arrayListGroup:AddToggle("YSL_ArrayListEnabled", {
		Text = "Show enabled features",
		Tooltip = "Show currently enabled toggles in the movable ArrayList.",
		Default = true,
		ArrayList = false,
		Callback = function(enabled)
			if arrayList then
				arrayList:SetVisible(enabled)
			end
		end,
	})
	arrayListGroup:AddToggle("YSL_ArrayListBackground", {
		Text = "Word backgrounds",
		Tooltip = "Show a compact background behind each enabled feature.",
		Default = true,
		ArrayList = false,
		Callback = function(enabled)
			if arrayList then
				arrayList:SetBackgroundEnabled(enabled)
			end
		end,
	})
	if arrayList then
		arrayList:SetVisible(aztup_toggles.YSL_ArrayListEnabled.Value)
		arrayList:SetBackgroundEnabled(aztup_toggles.YSL_ArrayListBackground.Value)
	end

	local other = tab:AddRightGroupbox("Other")
	local originalFpsCap
	local originalFpsCapKnown = false
	local fpsCapEnabled = false
	local function restoreFpsCap()
		if not fpsCapEnabled then
			return
		end
		fpsCapEnabled = false
		if type(setfpscap) ~= "function" then
			warn("[YSL Method] FPS cap API is unavailable; the original cap could not be restored")
			originalFpsCap = nil
			originalFpsCapKnown = false
			return
		end
		local restored, restoreError = pcall(setfpscap, originalFpsCap or 60)
		if not restored then
			warn("[YSL Method] Could not restore FPS cap: " .. tostring(restoreError))
		end
		originalFpsCap = nil
		originalFpsCapKnown = false
	end
	local fpsToggle
	fpsToggle = other:AddToggle("YSL_UncapFPS", {
		Text = "Uncap FPS",
		Tooltip = "Removes the client frame-rate cap. Restores the previous cap when getfpscap is available; otherwise restores 60 FPS.",
		Default = false,
		Callback = function(enabled)
			if enabled then
				if type(setfpscap) ~= "function" then
					context.SetStatus("Uncap FPS requires executor setfpscap support")
					task.defer(function()
						if fpsToggle then
							fpsToggle:SetValue(false)
						end
					end)
					return
				end
				originalFpsCap = 60
				originalFpsCapKnown = false
				if type(getfpscap) == "function" then
					local readSuccess, cap = pcall(getfpscap)
					if readSuccess and type(cap) == "number" and cap >= 0 then
						originalFpsCap = cap
						originalFpsCapKnown = true
					end
				end
				local changed, changeError = pcall(setfpscap, 0)
				if not changed then
					warn("[YSL Method] Could not uncap FPS: " .. tostring(changeError))
					context.SetStatus("Could not uncap FPS")
					task.defer(function()
						if fpsToggle then
							fpsToggle:SetValue(false)
						end
					end)
					return
				end
				fpsCapEnabled = true
				context.SetStatus(originalFpsCapKnown and "FPS cap removed" or "FPS cap removed; restoring to 60 FPS")
			else
				local wasEnabled = fpsCapEnabled
				restoreFpsCap()
				if wasEnabled then
					context.SetStatus("FPS cap restored")
				end
			end
		end,
	})
	context.Library:OnUnload(restoreFpsCap)

	local honeyCard = context.Library:Create('Frame', {
		Position = UDim2.new(1, -264, 1, -226);
		Size = UDim2.fromOffset(250, 190);
		BackgroundColor3 = context.Library.AccentColor;
		BorderSizePixel = 1;
		Visible = false;
		ZIndex = 300;
		Parent = context.Library.ScreenGui;
	})
	context.Library:Create('UICorner', {
		CornerRadius = UDim.new(0, 2);
		Parent = honeyCard;
	})
	context.Library:AddUIScale(honeyCard)
	context.Library:AddToRegistry(honeyCard, {
		BackgroundColor3 = 'AccentColor';
	}, true)

	local honeyInner = context.Library:Create('Frame', {
		Position = UDim2.fromOffset(1, 1);
		Size = UDim2.new(1, -2, 1, -2);
		BackgroundColor3 = context.Library.MainColor;
		BorderSizePixel = 0;
		ZIndex = 301;
		Parent = honeyCard;
	})
	context.Library:Create('UICorner', {
		CornerRadius = UDim.new(0, 1);
		Parent = honeyInner;
	})
	context.Library:AddToRegistry(honeyInner, {
		BackgroundColor3 = 'MainColor';
	}, true)

	local honeyHeader = context.Library:Create('Frame', {
		Size = UDim2.new(1, 0, 0, 30);
		BackgroundColor3 = context.Library.BackgroundColor;
		BorderSizePixel = 0;
		ZIndex = 302;
		Parent = honeyInner;
	})
	context.Library:AddToRegistry(honeyHeader, {
		BackgroundColor3 = 'BackgroundColor';
	}, true)

	local honeyTitle = context.Library:CreateLabel({
		Position = UDim2.fromOffset(10, 3);
		Size = UDim2.new(0.65, 0, 0, 16);
		Text = 'HONEY PER HOUR';
		TextSize = 12;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 303;
		Parent = honeyHeader;
	}, true)
	context.Library:AddToRegistry(honeyTitle, { TextColor3 = 'FontColor' }, true)

	local honeySession = context.Library:CreateLabelNoStroke({
		Position = UDim2.new(0.65, 0, 0, 3);
		Size = UDim2.new(0.35, -8, 0, 16);
		Text = 'SESSION 00:00';
		TextSize = 10;
		TextXAlignment = Enum.TextXAlignment.Right;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 303;
		Parent = honeyHeader;
	}, true)
	context.Library:AddToRegistry(honeySession, { TextColor3 = 'FontColor' }, true)

	local honeyRate = context.Library:CreateLabel({
		Position = UDim2.fromOffset(10, 34);
		Size = UDim2.new(0.62, 0, 0, 28);
		Text = '0 / HR';
		TextSize = 22;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 303;
		Parent = honeyInner;
	}, true)
	context.Library:AddToRegistry(honeyRate, { TextColor3 = 'FontColor' }, true)

	local honeyTotal = context.Library:CreateLabelNoStroke({
		Position = UDim2.new(0.62, 0, 0, 37);
		Size = UDim2.new(0.38, -10, 0, 22);
		Text = 'TOTAL 0';
		TextSize = 11;
		TextXAlignment = Enum.TextXAlignment.Right;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 303;
		Parent = honeyInner;
	}, true)
	context.Library:AddToRegistry(honeyTotal, { TextColor3 = 'FontColor' }, true)

	local honeyGraph = context.Library:Create('Frame', {
		Position = UDim2.fromOffset(10, 70);
		Size = UDim2.new(1, -20, 0, 82);
		BackgroundColor3 = context.Library.BackgroundColor;
		BorderColor3 = context.Library.OutlineColor;
		BorderSizePixel = 1;
		ClipsDescendants = true;
		ZIndex = 302;
		Parent = honeyInner;
	})
	context.Library:Create('UICorner', {
		CornerRadius = UDim.new(0, 1);
		Parent = honeyGraph;
	})
	context.Library:AddToRegistry(honeyGraph, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	}, true)

	local honeyGrid = {}
	for index = 1, 3 do
		local line = context.Library:Create('Frame', {
			Position = UDim2.new(0, 0, index / 4, 0);
			Size = UDim2.new(1, 0, 0, 1);
			BackgroundColor3 = context.Library.OutlineColor;
			BackgroundTransparency = 0.45;
			BorderSizePixel = 0;
			ZIndex = 303;
			Parent = honeyGraph;
		})
		context.Library:AddToRegistry(line, {
			BackgroundColor3 = 'OutlineColor';
		}, true)
		table.insert(honeyGrid, line)
	end

	local honeyPlot = context.Library:Create('Frame', {
		Position = UDim2.fromOffset(4, 4);
		Size = UDim2.new(1, -8, 1, -8);
		BackgroundTransparency = 1;
		ZIndex = 304;
		Parent = honeyGraph;
	})
	local honeyPoints = {}
	local honeySegments = {}
	for index = 1, 30 do
		local point = context.Library:Create('Frame', {
			AnchorPoint = Vector2.new(0.5, 0.5);
			Size = UDim2.fromOffset(3, 3);
			BackgroundColor3 = context.Library.FontColor;
			BorderSizePixel = 0;
			ZIndex = 306;
			Parent = honeyPlot;
		})
		context.Library:AddToRegistry(point, { BackgroundColor3 = 'FontColor' }, true)
		table.insert(honeyPoints, point)
		if index > 1 then
			local segment = context.Library:Create('Frame', {
				AnchorPoint = Vector2.new(0.5, 0.5);
				BackgroundColor3 = context.Library.AccentColor;
				BorderSizePixel = 0;
				ZIndex = 305;
				Parent = honeyPlot;
			})
			context.Library:AddToRegistry(segment, { BackgroundColor3 = 'AccentColor' }, true)
			table.insert(honeySegments, segment)
		end
	end

	local function formatHoney(value)
		value = math.max(0, tonumber(value) or 0)
		if value >= 1000000000000000 then
			return string.format('%.2fQa', value / 1000000000000000)
		elseif value >= 1000000000000 then
			return string.format('%.2fT', value / 1000000000000)
		elseif value >= 1000000000 then
			return string.format('%.2fB', value / 1000000000)
		elseif value >= 1000000 then
			return string.format('%.2fM', value / 1000000)
		elseif value >= 1000 then
			return string.format('%.1fK', value / 1000)
		end
		return string.format('%.0f', value)
	end

	local function updateHoneyGraph(values)
		local minimum = math.huge
		local maximum = -math.huge
		for _, value in ipairs(values) do
			minimum = math.min(minimum, value)
			maximum = math.max(maximum, value)
		end
		local range = math.max(1, maximum - minimum)
		for index, point in ipairs(honeyPoints) do
			local value = values[index] or values[#values] or 0
			local x = (#honeyPoints == 1) and 0.5 or (index - 1) / (#honeyPoints - 1)
			local y = 0.9 - ((value - minimum) / range) * 0.8
			point.Position = UDim2.new(x, 0, y, 0)
			point.Visible = #values > 1
			if index > 1 then
				local previousValue = values[index - 1] or value
				local previousX = (index - 2) / (#honeyPoints - 1)
				local previousY = 0.9 - ((previousValue - minimum) / range) * 0.8
				local dx = (x - previousX) * honeyPlot.AbsoluteSize.X
				local dy = (y - previousY) * honeyPlot.AbsoluteSize.Y
				local length = math.sqrt(dx * dx + dy * dy)
				local segment = honeySegments[index - 1]
				segment.Position = UDim2.new((x + previousX) / 2, 0, (y + previousY) / 2, 0)
				segment.Size = UDim2.fromOffset(length, 2)
				segment.Rotation = math.deg(math.atan2(dy, dx))
				segment.Visible = #values > 1
			end
		end
	end

	context.Library:AddToRegistry(honeySession, { TextColor3 = 'FontColor' }, true)
	context.Library:MakeDraggable(honeyCard, 30)
	context.Library.HoneyPerHourCard = honeyCard

	local enabledKeybinds = other:AddToggle("OnlyShowEnabledKeybinds", {
		Text = "Only Show Enabled Keybinds",
		Default = false,
	})
	enabledKeybinds:OnChanged(function()
		for _, option in pairs(aztup_options) do
			if option.Type == "KeyPicker" and option.Update then
				option:Update()
			end
		end
	end)
	other:AddToggle("Watermark", {
		Text = "Watermark",
		Default = false,
		Callback = function(enabled)
			watermarkGeneration += 1
			local generation = watermarkGeneration
			if watermarkRenderConnection then
				watermarkRenderConnection:Disconnect()
				watermarkRenderConnection = nil
			end
			context.Library:SetWatermarkVisibility(enabled)
			if enabled then
				task.spawn(function()
					local elapsed = 0
					local frames = 0
					local fps = 0
					local renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
						frames += 1
						elapsed += deltaTime
						if elapsed >= 1 then
							fps = math.floor(frames / elapsed + 0.5)
							frames = 0
							elapsed = 0
						end
					end)
					watermarkRenderConnection = renderConnection
					while watermarkGeneration == generation and context.Library.ScreenGui.Parent do
						local player = Players.LocalPlayer
						local ping = getPingText()
						local plainText = string.format("YSL METHOD  |  %s  |  %d FPS  |  %s", player.Name, fps, ping)
						context.Library:SetWatermark(plainText, plainText, {
							Brand = "YSL METHOD",
							Player = player.Name,
							FPS = string.format("%d FPS", fps),
							Ping = ping,
						})
						task.wait(1)
					end
					renderConnection:Disconnect()
					if watermarkRenderConnection == renderConnection then
						watermarkRenderConnection = nil
					end
				end)
			end
		end,
	})
	other:AddToggle("Console", {
		Text = "Console",
		Default = false,
		Callback = function(enabled)
			context.Library:SetInfoLoggerVisibility(enabled)
		end,
	})
	other:AddToggle("KeybindShower", {
		Text = "Show Keybinds",
		Default = false,
		Callback = function(enabled)
			context.Library:SetKeybindVisibility(enabled)
		end,
	})
	other:AddSlider("YSL_HudTransparency", {
		Text = "HUD background transparency",
		Tooltip = "Adjusts the transparency of the watermark, hotkeys, and ESP preview panels.",
		Default = 18,
		Min = 0,
		Max = 80,
		Rounding = 0,
		Suffix = "%",
		Callback = function(value)
			context.Library:SetHudTransparency(value / 100)
		end,
	})
	context.Library:SetHudTransparency(0.18)
	if context.GameName == "Bee Swarm Remastered" then
		other:AddToggle("HoneyPerHour", {
			Text = "Honey per hour",
			Default = false,
			Callback = function(enabled)
				honeyPerHourGeneration += 1
				local generation = honeyPerHourGeneration
				honeyCard.Visible = enabled
				if not enabled then
					return
				end
				task.spawn(function()
					local samples = {}
					local startedAt = os.clock()
					local lastHoney
					while honeyPerHourGeneration == generation and context.Library.ScreenGui.Parent do
						local player = Players.LocalPlayer
						local coreStats = player and player:FindFirstChild("CoreStats")
						local honeyObject = coreStats and coreStats:FindFirstChild("Honey")
						local honey = honeyObject and tonumber(honeyObject.Value)
						if honey then
							lastHoney = lastHoney or honey
							if honey < lastHoney then
								samples = {}
							end
							lastHoney = honey
							table.insert(samples, { time = os.clock(), value = honey })
							while #samples > 1 and os.clock() - samples[1].time > 60 do
								table.remove(samples, 1)
							end
							local first = samples[1]
							local duration = math.max(1, os.clock() - first.time)
							local rate = (honey - first.value) / duration * 3600
							honeyRate.Text = formatHoney(rate) .. ' / HR'
							honeyTotal.Text = 'TOTAL ' .. formatHoney(honey)
							local sessionSeconds = math.floor(os.clock() - startedAt)
							honeySession.Text = string.format(
								'SESSION %02d:%02d',
								math.floor(sessionSeconds / 60),
								sessionSeconds % 60
							)
							local values = {}
							for _, sample in ipairs(samples) do
								table.insert(values, sample.value)
							end
							while #values < #honeyPoints do
								table.insert(values, 1, values[1] or honey)
							end
							if #values > #honeyPoints then
								local trimmed = {}
								for index = #values - #honeyPoints + 1, #values do
									table.insert(trimmed, values[index])
								end
								values = trimmed
							end
							updateHoneyGraph(values)
						end
						task.wait(1)
					end
				end)
			end,
		})
	end

	local outline = tab:AddRightGroupbox("Window Outline")
	outline:AddToggle("Wiggins_AnimatedOutline", {
		Text = "Animated Gradient",
		Default = outlineGradientEnabled,
		Callback = function(enabled)
			outlineGradientEnabled = enabled
			updateOutlineGradient()
		end,
	})
	outline:AddSlider("Wiggins_OutlineGradientDuration", {
		Text = "Gradient cycle time",
		Default = outlineGradientDuration,
		Min = 1,
		Max = 12,
		Rounding = 0,
		Suffix = "s",
		Callback = function(duration)
			outlineGradientDuration = duration
			updateOutlineGradient()
		end,
	})
	local management = tab:AddRightGroupbox("YSL Method")
	if not context.ShowcaseOnly then
		management:AddButton("Forget remembered game", function()
			local success, err = context.Config:SetSelectedGame(context.PlaceId, nil)
			if success then
				context.SetStatus("Game picker will appear next time you run YSL Method")
			else
				warn("[YSL Method] Could not forget remembered game: " .. tostring(err))
				context.SetStatus("Could not save game selection change")
			end
		end, true)
	end
	management:AddButton("Unload hub", function()
		context.Library:Unload()
	end, true)
end

return {
	Setup = setupSettings,
	ApplySavedTheme = applySavedTheme,
	ApplyTheme = applyTheme,
	ApplyThemeByName = applyThemeByName,
}
	end,
