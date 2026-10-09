-- ============================================================
-- YSL SETTINGS / CONFIG / ARRAYLIST
-- ============================================================
do
    local settingsTab = YSLRuntime.Window:AddTab("Settings")
    local ambience = YSLRuntime.AmbienceFactory(YSLRuntime.Library)
    ambience:SetMode("Off")

    YSLRuntime.Settings.Setup(settingsTab, {
        Library = YSLRuntime.Library,
        Window = YSLRuntime.Window,
        Config = YSLRuntime.Config,
        PlaceId = game.PlaceId,
        GameName = "Archivist 4.4",
        ShowcaseOnly = true,
        StartupTheme = YSLRuntime.StartupTheme,
        Ambience = ambience,
        SideImage = nil,
        ArrayList = YSLRuntime.ArrayList,
        SetStatus = function(message)
            YSLRuntime.Library:Notify(tostring(message), 3)
        end,
    })

    local handoffContext = (type(getgenv) == "function" and getgenv() or _G).__ArchivistTPContext
    if YSLRuntime.Config:GetAutoLoadName() and not (type(handoffContext) == "table" and type(handoffContext.pending) == "table") then
        local callSuccess, loadSuccess, loadError = pcall(function()
            return YSLRuntime.Config:LoadAutoLoad()
        end)
        if not callSuccess then
            warn("[Archivist] Autoload config failed: " .. tostring(loadSuccess))
        elseif not loadSuccess then
            warn("[Archivist] Autoload config failed: " .. tostring(loadError))
        end
    end

    YSLRuntime.Library:UpdateColorsUsingRegistry()
    YSLRuntime.LoadedSignal:fire()
    YSLRuntime.Library:Toggle()
    YSLRuntime.Library:Notify("Archivist 4.4 loaded", 3)
end

print("[Archivist 4.4 | YSL] Loaded successfully!")

