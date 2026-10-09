	["@src/config"] = function()
local ConfigStore = {}
ConfigStore.__index = ConfigStore
local HttpService = game:GetService("HttpService")
local CONFIG_DIRECTORY = "WigginsHub"
local CONFIG_PATH = CONFIG_DIRECTORY .. "/configs.json"

local function copy(value, ancestors)
	local valueType = typeof(value)
	if valueType == "Instance" then
		return value.Name, true
	elseif valueType == "EnumItem" then
		return value.Name, true
	elseif type(value) ~= "table" then
		if value == nil or valueType == "boolean" or valueType == "number" or valueType == "string" then
			return value, false
		end
		return nil, true
	end
	ancestors = ancestors or {}
	if ancestors[value] then
		return nil, true
	end
	ancestors[value] = true
	local result = {}
	local changed = false
	for key, item in pairs(value) do
		local keyType = typeof(key)
		if keyType ~= "string" and keyType ~= "number" then
			changed = true
		else
			local copied, itemChanged = copy(item, ancestors)
			if copied ~= nil then
				result[key] = copied
			elseif item ~= nil then
				changed = true
			end
			changed = changed or itemChanged
		end
	end
	ancestors[value] = nil
	return result, changed
end

local function readValue(option)
	if option.Type == "ColorPicker" then
		return { hex = option.Value:ToHex(), transparency = option.Transparency }
	end
	if option.Type == "KeyPicker" then
		return { key = option.Value, mode = option.Mode }
	end
	return option.Value
end

local function isConfigSnapshot(value)
	return type(value) == "table"
		and (type(value.toggles) == "table" or type(value.options) == "table" or type(value.layout) == "table")
end

function ConfigStore.new(library)
	local store = setmetatable({
		configs = {},
		autoloadByGame = {},
		activeGame = nil,
		legacyConfigs = {},
		legacyAutoloadName = nil,
		defaultTheme = nil,
		selectedGames = {},
		sideImages = nil,
		library = library,
	}, ConfigStore)
	if type(readfile) == "function" then
		local readSuccess, contents = pcall(readfile, CONFIG_PATH)
		if readSuccess and type(contents) == "string" then
			local decodeSuccess, data = pcall(HttpService.JSONDecode, HttpService, contents)
			if decodeSuccess and type(data) == "table" then
				store.defaultTheme = type(data.defaultTheme) == "string" and data.defaultTheme or nil
				store.selectedGames = type(data.selectedGames) == "table" and data.selectedGames or {}
				store.sideImages = type(data.sideImages) == "table" and data.sideImages or nil
				store.autoloadByGame = type(data.autoloadByGame) == "table" and data.autoloadByGame or {}
				store.legacyAutoloadName = type(data.autoloadName) == "string" and data.autoloadName or nil
				if type(data.legacyAutoloadName) == "string" then
					store.legacyAutoloadName = data.legacyAutoloadName
				end
				if type(data.legacyConfigs) == "table" then
					store.legacyConfigs = data.legacyConfigs
				end
				local savedConfigs = type(data.configs) == "table" and data.configs or {}
				if data.configSchemaVersion == 2 then
					for gameName, profiles in pairs(savedConfigs) do
						if type(gameName) == "string" and type(profiles) == "table" then
							local validProfiles = {}
							for profileName, snapshot in pairs(profiles) do
								if type(profileName) == "string" and isConfigSnapshot(snapshot) then
									validProfiles[profileName] = snapshot
								end
							end
							if next(validProfiles) then
								store.configs[gameName] = validProfiles
							end
						end
					end
				else
					for profileName, snapshot in pairs(savedConfigs) do
						if type(profileName) == "string" and isConfigSnapshot(snapshot) then
							store.legacyConfigs[profileName] = snapshot
						end
					end
				end
				store.activeGame = store.selectedGames[tostring(game.PlaceId)]
			end
		end
	end
	return store
end

function ConfigStore:Persist()
	if type(writefile) ~= "function" then
		return false, "Executor file APIs are unavailable; configs will only last this session."
	end
	if type(makefolder) == "function" then
		pcall(makefolder, CONFIG_DIRECTORY)
	end
	local payload, normalized = copy({
		configSchemaVersion = 2,
		configs = self.configs,
		autoloadByGame = self.autoloadByGame,
		defaultTheme = self.defaultTheme,
		selectedGames = self.selectedGames,
		sideImages = self.sideImages,
		legacyConfigs = self.legacyConfigs,
		legacyAutoloadName = self.legacyAutoloadName,
	})
	if normalized then
		warn("[YSL Method] Config data contained unsupported or cyclic values; affected values were omitted from the saved file.")
	end
	local encoded, contents = pcall(HttpService.JSONEncode, HttpService, payload)
	if not encoded then
		return false, "Could not serialize config data: " .. tostring(contents)
	end
	local written, writeError = pcall(writefile, CONFIG_PATH, contents)
	if not written then
		return false, tostring(writeError)
	end
	return true
end

function ConfigStore:GetSideImages()
	return self.sideImages
end

function ConfigStore:SaveSideImages(state)
	local safeState, normalized = copy(state)
	if type(safeState) ~= "table" then
		return false, "Could not save mascot settings: invalid state."
	end
	if normalized then
		warn("[YSL Method] Mascot settings contained unsupported values; affected values were omitted.")
	end
	local previousState = self.sideImages
	self.sideImages = safeState
	local success, err = self:Persist()
	if not success then
		self.sideImages = previousState
		return false, err
	end
	return true
end

function ConfigStore:SetGameContext(gameName)
	if type(gameName) ~= "string" or gameName == "" then
		return false, "Select a game before managing configs."
	end
	self.activeGame = gameName
	local migrated = next(self.legacyConfigs) ~= nil or self.legacyAutoloadName ~= nil
	local gameProfiles = self.configs[gameName]
	if not gameProfiles then
		gameProfiles = {}
		self.configs[gameName] = gameProfiles
	end
	for profileName, snapshot in pairs(self.legacyConfigs) do
		if not gameProfiles[profileName] then
			gameProfiles[profileName] = snapshot
		end
		self.legacyConfigs[profileName] = nil
	end
	if self.legacyAutoloadName then
		if not self.autoloadByGame[gameName] and gameProfiles[self.legacyAutoloadName] then
			self.autoloadByGame[gameName] = self.legacyAutoloadName
		end
		self.legacyAutoloadName = nil
	end
	if next(gameProfiles) == nil then
		self.configs[gameName] = nil
	end
	if migrated then
		return self:Persist()
	end
	return true
end

local function getGameProfiles(store)
	if not store.activeGame then
		return nil
	end
	return store.configs[store.activeGame]
end

function ConfigStore:Save(name)
	local gameProfiles = getGameProfiles(self)
	if not gameProfiles then
		if not self.activeGame then
			return false, "Select a game before saving a config."
		end
		gameProfiles = {}
		self.configs[self.activeGame] = gameProfiles
	end
	name = string.gsub(name or "", "^%s*(.-)%s*$", "%1")
	if name == "" or not string.match(name, "^[%w _%-]+$") then
		return false, "Use letters, numbers, spaces, _ or - for config names."
	end
	local snapshot = {
		toggles = {},
		options = {},
		layout = self.library and self.library:GetLayoutSnapshot() or nil,
		sideImages = self.library and self.library.SideImageController
			and self.library.SideImageController:GetConfigState() or nil,
	}
	for id, toggle in pairs(aztup_toggles) do
		if toggle.Type == "Toggle" then
			snapshot.toggles[id] = toggle.Value
		end
	end
	for id, option in pairs(aztup_options) do
		if option.Type then
			local value, normalized = copy(readValue(option))
			if value ~= nil then
				snapshot.options[id] = { type = option.Type, value = value }
			end
			if normalized then
				warn(string.format(
					"[YSL Method] Config option %s contained unsupported or cyclic values; unsupported branches were omitted.",
					tostring(id)
				))
			end
		end
	end
	local safeSnapshot, normalized = copy(snapshot)
	if normalized then
		warn("[YSL Method] Config snapshot contained unsupported or cyclic values; affected values were omitted.")
	end
	local encoded, encodeError = pcall(HttpService.JSONEncode, HttpService, safeSnapshot)
	if not encoded then
		return false, "Could not serialize config snapshot: " .. tostring(encodeError)
	end
	local previousSnapshot = gameProfiles[name]
	gameProfiles[name] = safeSnapshot
	local success, err = self:Persist()
	if not success then
		gameProfiles[name] = previousSnapshot
		if next(gameProfiles) == nil then
			self.configs[self.activeGame] = nil
		end
	end
	return success, err
end

function ConfigStore:Load(name)
	local gameProfiles = getGameProfiles(self)
	local snapshot = gameProfiles and gameProfiles[name]
	if not snapshot then
		return false, "Config not found."
	end
	local loadErrors = {}
	if self.library then
		self.library.ConfigLoading = true
		self.library.ConfigLoadingOption = nil
		self.library.ConfigLoadErrors = loadErrors
	end
	local function apply(label, callback)
		if self.library then
			self.library.ConfigLoadingOption = label
		end
		local success, err = pcall(callback)
		if not success then
			table.insert(loadErrors, string.format("%s: %s", tostring(label), tostring(err)))
			warn(string.format("[YSL Method] Could not load config value %s: %s", tostring(label), tostring(err)))
		end
	end
	for id, value in pairs(snapshot.toggles or {}) do
		local toggle = aztup_toggles[id]
		if toggle then
			apply(id, function()
				toggle:SetValue(value)
			end)
		end
	end
	if snapshot.sideImages and self.library and self.library.SideImageController then
		apply("side images", function()
			self.library.SideImageController:SetConfigState(snapshot.sideImages)
		end)
	end
	for id, item in pairs(snapshot.options or {}) do
		local option = aztup_options[id]
		if option and type(item) == "table" then
			apply(id, function()
				if item.type == "ColorPicker" then
					assert(type(item.value) == "table" and type(item.value.hex) == "string", "invalid color value")
					option:SetValueRGB(Color3.fromHex(item.value.hex), item.value.transparency)
				elseif item.type == "KeyPicker" then
					assert(type(item.value) == "table", "invalid keybind value")
					option:SetValue({ item.value.key, item.value.mode })
				elseif option.SetValue then
					option:SetValue(item.value)
				end
			end)
		end
	end
	if snapshot.layout and self.library and self.library.SetLayoutSnapshot then
		apply("layout", function()
			self.library:SetLayoutSnapshot(snapshot.layout)
		end)
	end
	if self.library then
		self.library.ConfigLoading = false
		self.library.ConfigLoadingOption = nil
		self.library.ConfigLoadErrors = nil
	end
	if #loadErrors > 0 then
		return false, string.format(
			"Loaded config with %d value error(s). See Output for the affected settings.",
			#loadErrors
		)
	end
	return true
end

function ConfigStore:Delete(name)
	local gameProfiles = getGameProfiles(self)
	if not gameProfiles or not gameProfiles[name] then
		return false
	end
	local previousSnapshot = gameProfiles[name]
	local previousAutoload = self.activeGame and self.autoloadByGame[self.activeGame]
	gameProfiles[name] = nil
	if next(gameProfiles) == nil then
		self.configs[self.activeGame] = nil
	end
	if self.activeGame and self.autoloadByGame[self.activeGame] == name then
		self.autoloadByGame[self.activeGame] = nil
	end
	local success, err = self:Persist()
	if not success then
		self.configs[self.activeGame] = gameProfiles
		gameProfiles[name] = previousSnapshot
		self.autoloadByGame[self.activeGame] = previousAutoload
	end
	return success, err
end

function ConfigStore:SetAutoLoad(name)
	local gameProfiles = getGameProfiles(self)
	if not self.activeGame then
		return false, "Select a game before setting an autoload config."
	end
	if name ~= nil and (not gameProfiles or not gameProfiles[name]) then
		return false, "Config not found."
	end
	local previousName = self.autoloadByGame[self.activeGame]
	self.autoloadByGame[self.activeGame] = name
	local success, err = self:Persist()
	if not success then
		self.autoloadByGame[self.activeGame] = previousName
	end
	return success, err
end

function ConfigStore:GetAutoLoadName()
	return self.activeGame and self.autoloadByGame[self.activeGame] or nil
end

function ConfigStore:GetGameContext()
	return self.activeGame
end

function ConfigStore:GetAutoLoadSnapshot()
	local gameProfiles = getGameProfiles(self)
	local name = self:GetAutoLoadName()
	return gameProfiles and name and gameProfiles[name] or nil
end

function ConfigStore:SetDefaultTheme(name)
	if type(name) ~= "string" or name == "" then
		return false, "Select a theme first."
	end
	local previousTheme = self.defaultTheme
	self.defaultTheme = name
	local success, err = self:Persist()
	if not success then
		self.defaultTheme = previousTheme
	end
	return success, err
end

function ConfigStore:GetDefaultTheme()
	return self.defaultTheme
end

function ConfigStore:GetSelectedGame(placeId)
	return self.selectedGames[tostring(placeId)]
end

function ConfigStore:SetSelectedGame(placeId, name)
	if name ~= nil and (type(name) ~= "string" or name == "") then
		return false, "Select a valid game."
	end
	local key = tostring(placeId)
	if name == nil then
		self.selectedGames[key] = nil
	else
		self.selectedGames[key] = name
	end
	return self:Persist()
end

function ConfigStore:LoadAutoLoad()
	local autoloadName = self:GetAutoLoadName()
	if not autoloadName then
		return false, "No autoload config is set."
	end
	return self:Load(autoloadName)
end

function ConfigStore:List()
	local names = {}
	for name in pairs(getGameProfiles(self) or {}) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function ConfigStore:GetValue(id)
	local option = aztup_options[id]
	return option and option.Value
end

return ConfigStore
	end,
}

    local signal = require("@src/utility/signal")
    loaded_signal = signal.new()

    local Library = require("@src/utility/librarys/ui")
    local ConfigStore = require("@src/config")
    local settingsModule = require("@src/ui/tabs/Settings")
    local createArrayList = require("@src/ui/arraylist")
    local createAmbience = require("@src/ui/ambience")

    local configStore = ConfigStore.new(Library)
    local contextLoaded, contextError = configStore:SetGameContext("Archivist 4.4")
    if not contextLoaded then
        warn("[Archivist] Could not initialize YSL config context: " .. tostring(contextError))
    end

    local startupTheme = settingsModule.ApplySavedTheme(
        Library,
        configStore:GetAutoLoadSnapshot(),
        configStore:GetDefaultTheme() or "Luma"
    )

    local window = Library:CreateWindow({
        Title = "Archivist 4.4",
        Center = true,
        AutoShow = false,
        MenuFadeTime = 0,
        TabPadding = 0,
        Size = UDim2.fromOffset(650, 660),
    })

    local arrayList = createArrayList(Library)
    if Library.ArrayListFrame then
        Library.ArrayListFrame.AnchorPoint = Vector2.new(0, 0)
        Library.ArrayListFrame.Position = UDim2.new(0, 8, 0, 88)
        arrayList:SyncPlacement()
    end
    arrayList:SetVisible(true)

    -- Auto-save the selected autoload profile on UI changes. Without an
    -- autoload profile, YSL only writes when the user explicitly saves.
    Library.SaveManager = {
        Save = function()
            if Library.ConfigLoading then return end
            local name = configStore:GetAutoLoadName()
            if name then
                local ok, err = configStore:Save(name)
                if not ok and err then
                    warn("[Archivist] Config autosave failed: " .. tostring(err))
                end
            end
        end,
    }

    local counter = 0
    local function nextFlag(info, prefix)
        counter += 1
        return (info and info.Flag and tostring(info.Flag)) or (prefix .. "_" .. tostring(counter))
    end
    local function decimals(step)
        step = tonumber(step) or 1
        local text = tostring(step)
        local dot = text:find("%.")
        return dot and math.min(#text - dot, 4) or 0
    end
    local function currentOption(value, multi)
        if multi then
            if type(value) == "table" then return value end
            return value and {value} or {}
        end
        return type(value) == "table" and value[1] or value
    end
    local function wrapToggle(raw)
        raw.Set = function(_, value) raw:SetValue(value) end
        return raw
    end
    local function wrapLabel(raw)
        raw.Set = function(_, value) raw:SetText(tostring(value or "")) end
        return raw
    end

    local function makeTabAdapter(rawTab)
        local adapter = { _raw = rawTab, _group = nil, _sectionIndex = 0 }
        local function group()
            if not adapter._group then adapter:CreateSection("General") end
            return adapter._group
        end

        function adapter:CreateSection(name)
            self._sectionIndex += 1
            local sectionName = tostring(name or "Section")
            self._group = (self._sectionIndex % 2 == 1)
                and self._raw:AddLeftGroupbox(sectionName)
                or self._raw:AddRightGroupbox(sectionName)
            return self._group
        end
        function adapter:CreateLabel(text)
            return wrapLabel(group():AddLabel(tostring(text or ""), true))
        end
        function adapter:CreateButton(info)
            info = info or {}
            return group():AddButton(tostring(info.Name or "Button"), info.Callback or function() end)
        end
        function adapter:CreateToggle(info)
            info = info or {}
            return wrapToggle(group():AddToggle(nextFlag(info, "Toggle"), {
                Text = tostring(info.Name or "Toggle"),
                Default = info.CurrentValue == true,
                Callback = info.Callback or function() end,
                Tooltip = info.Tooltip,
                ArrayList = info.ArrayList ~= false,
            }))
        end
        function adapter:CreateSlider(info)
            info = info or {}
            local range = info.Range or {0, 100}
            local raw = group():AddSlider(nextFlag(info, "Slider"), {
                Text = tostring(info.Name or "Slider"),
                Default = tonumber(info.CurrentValue) or tonumber(range[1]) or 0,
                Min = tonumber(range[1]) or 0,
                Max = tonumber(range[2]) or 100,
                Rounding = decimals(info.Increment),
                Suffix = info.Suffix or "",
                Callback = info.Callback or function() end,
                Tooltip = info.Tooltip,
            })
            raw.Set = function(_, value) raw:SetValue(value) end
            return raw
        end
        function adapter:CreateDropdown(info)
            info = info or {}
            local multi = info.MultipleOptions == true
            local values = info.Options or {}
            local default = currentOption(info.CurrentOption, multi)
            local allowNull = (not multi and (default == nil or default == "")) or (#values == 0)
            if not multi and default == "" then default = nil end
            local raw = group():AddDropdown(nextFlag(info, "Dropdown"), {
                Text = tostring(info.Name or "Dropdown"),
                Values = values,
                Default = default,
                Multi = multi,
                AllowNull = allowNull,
                Searchable = #values > 8,
                Callback = info.Callback or function() end,
                Tooltip = info.Tooltip,
            })
            raw.Set = function(_, value)
                if multi and type(value) == "table" then
                    local map = {}
                    for k, v in pairs(value) do
                        if type(k) == "string" and v == true then map[k] = true
                        elseif type(v) == "string" then map[v] = true end
                    end
                    raw:SetValue(map)
                else
                    raw:SetValue(type(value) == "table" and value[1] or value)
                end
            end
            raw.Refresh = function(_, newValues) raw:SetValues(newValues or values) end
            return raw
        end
        function adapter:CreateInput(info)
            info = info or {}
            local raw = group():AddInput(nextFlag(info, "Input"), {
                Text = tostring(info.Name or "Input"),
                Placeholder = info.PlaceholderText or "",
                Default = tostring(info.CurrentValue or info.Default or ""),
                Finished = true,
                Callback = info.Callback or function() end,
                Tooltip = info.Tooltip,
            })
            raw.Set = function(_, value) raw:SetValue(tostring(value or "")) end
            return raw
        end
        function adapter:CreateKeybind(info)
            info = info or {}
            return group():AddKeyPicker(nextFlag(info, "Keybind"), {
                Text = tostring(info.Name or "Keybind"),
                Default = tostring(info.CurrentKeybind or "None"),
                Mode = "Toggle",
                Callback = function()
                    if info.Callback then info.Callback() end
                end,
            })
        end
        return adapter
    end

    local compatWindow = {}
    function compatWindow:CreateTab(name)
        return makeTabAdapter(window:AddTab(tostring(name)))
    end
    local compatLib = {}
    function compatLib:CreateWindow(_)
        return compatWindow
    end
    function compatLib:Notify(info)
        if type(info) == "table" then
            local title = tostring(info.Title or "Archivist")
            local content = tostring(info.Content or "")
            Library:Notify(title .. (content ~= "" and (" - " .. content) or ""), tonumber(info.Duration) or 3)
        else
            Library:Notify(tostring(info), 3)
        end
    end

    return {
        Library = Library,
        Window = window,
        Config = configStore,
        Settings = settingsModule,
        ArrayList = arrayList,
        AmbienceFactory = createAmbience,
        StartupTheme = startupTheme,
        LoadedSignal = loaded_signal,
        Toggles = aztup_toggles,
        Options = aztup_options,
        Lib = compatLib,
    }
end)()

