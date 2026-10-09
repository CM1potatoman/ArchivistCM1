-- ============================================================
-- COMBAT TAB
-- ============================================================
local CombatTab = Window:CreateTab("Combat", 10726204364)

do
    local weapInfo = RepStore:FindFirstChild("WeaponINFO")
    local weapOrig = {}

    local function saveWeapDefaults()
        if not weapInfo then return end
        for _, w in ipairs(weapInfo:GetChildren()) do
            weapOrig[w.Name] = {}
            local m = w:FindFirstChild("M1Delay")
            if m then weapOrig[w.Name].M1Delay = m.Value end
            local sw = w:FindFirstChild("SwingSpeed")
            if sw then weapOrig[w.Name].SwingSpeed = sw.Value end
        end
    end

    local function applyWeap()
        if not weapInfo or not S.WeaponEnabled then return end
        for _, w in ipairs(weapInfo:GetChildren()) do
            local m = w:FindFirstChild("M1Delay"); if m then m.Value = S.M1Speed end
            local sw = w:FindFirstChild("SwingSpeed"); if sw then sw.Value = S.SwingSpeed end
        end
    end

    local function revertWeap()
        if not weapInfo then return end
        for _, w in ipairs(weapInfo:GetChildren()) do
            local ov = weapOrig[w.Name]
            if ov then
                local m = w:FindFirstChild("M1Delay"); if m and ov.M1Delay then m.Value = ov.M1Delay end
                local sw = w:FindFirstChild("SwingSpeed"); if sw and ov.SwingSpeed then sw.Value = ov.SwingSpeed end
            end
        end
    end

    if weapInfo then task.defer(saveWeapDefaults) end

    CombatTab:CreateSection("Page Manager")
    CombatTab:CreateLabel("normal = page CD attribute (10s fallback); half = floor(CD / 2); none = requests 0s")
    CombatTab:CreateLabel("No Cooldowns forces requested page CD to 0. The server/page can still clamp or reject 0.")
    CombatTab:CreateLabel("Select a page, CD mode, and keybind for each slot")
    CombatTab:CreateButton({
        Name = "Print Current Page CDs",
        Callback = function()
            print("[Archivist] ---- Current Page CDs ----")
            for _, pageName in ipairs(GetPages()) do
                local tool = LP.Backpack:FindFirstChild(pageName)
                if tool then
                    local cd = tool:GetAttribute("CD")
                    print(string.format("[Archivist] %s | CD=%s | normal=%s | half=%s | none=0",
                        pageName, tostring(cd or "fallback 10"), tostring(GetFinalCD(tool, "normal")), tostring(GetFinalCD(tool, "half"))))
                end
            end
        end,
    })

    local pageList = GetPages()

    CombatTab:CreateDropdown({
        Name = "Page Slot 1", Options = pageList, CurrentOption = {""},
        MultipleOptions = false, Flag = "PageSlot1",
        Callback = function(opt) PageSlots[1].name = GetValue(opt) end,
    })
    CombatTab:CreateDropdown({
        Name = "Slot 1 CD Mode", Options = {"normal", "half", "none"},
        CurrentOption = {"normal"}, MultipleOptions = false, Flag = "PageMode1",
        Callback = function(opt) PageSlots[1].mode = GetValue(opt) end,
    })
    CombatTab:CreateInput({
        Name = "Slot 1 Keybind", PlaceholderText = "J",
        RemoveTextAfterFocusLost = false, Flag = "PageKey1",
        Callback = function(text) if text ~= "" then PageSlots[1].key = text:upper() end end,
    })

    CombatTab:CreateDropdown({
        Name = "Page Slot 2", Options = pageList, CurrentOption = {""},
        MultipleOptions = false, Flag = "PageSlot2",
        Callback = function(opt) PageSlots[2].name = GetValue(opt) end,
    })
    CombatTab:CreateDropdown({
        Name = "Slot 2 CD Mode", Options = {"normal", "half", "none"},
        CurrentOption = {"normal"}, MultipleOptions = false, Flag = "PageMode2",
        Callback = function(opt) PageSlots[2].mode = GetValue(opt) end,
    })
    CombatTab:CreateInput({
        Name = "Slot 2 Keybind", PlaceholderText = "K",
        RemoveTextAfterFocusLost = false, Flag = "PageKey2",
        Callback = function(text) if text ~= "" then PageSlots[2].key = text:upper() end end,
    })

    CombatTab:CreateDropdown({
        Name = "Page Slot 3", Options = pageList, CurrentOption = {""},
        MultipleOptions = false, Flag = "PageSlot3",
        Callback = function(opt) PageSlots[3].name = GetValue(opt) end,
    })
    CombatTab:CreateDropdown({
        Name = "Slot 3 CD Mode", Options = {"normal", "half", "none"},
        CurrentOption = {"normal"}, MultipleOptions = false, Flag = "PageMode3",
        Callback = function(opt) PageSlots[3].mode = GetValue(opt) end,
    })
    CombatTab:CreateInput({
        Name = "Slot 3 Keybind", PlaceholderText = "L",
        RemoveTextAfterFocusLost = false, Flag = "PageKey3",
        Callback = function(text) if text ~= "" then PageSlots[3].key = text:upper() end end,
    })

    CombatTab:CreateSection("Auto Kill")
    CombatTab:CreateToggle({
        Name = "Auto Kill NPCs", CurrentValue = false, Flag = "AutoKillNPC",
        Callback = function(state) EnemyValues.autokill = state end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Kill Players", CurrentValue = false, Flag = "AutoKillPlayers",
        Callback = function(state) EnemyValues.autokillplayers = state end,
    })
    CombatTab:CreateToggle({
        Name = "Singularity Only", CurrentValue = false, Flag = "SinguOnly",
        Callback = function(state) EnemyValues.singuonly = state end,
    })
    CombatTab:CreateSlider({
        Name = "Auto Kill Range", Range={0,10000}, Increment=100,
        CurrentValue=10000, Flag="AutoKillRange",
        Callback = function(v) S.AutoKillRange = v end,
    })
    CombatTab:CreateToggle({
        Name = "Wheel's Industry Paced (0.1s)", CurrentValue = false, Flag = "WheelsPaced",
        Callback = function(state) EnemyValues.wheelsIndustryPaced = state end,
    })

    CombatTab:CreateSection("Weapon Modifier")
    CombatTab:CreateToggle({
        Name = "Weapon Modifier", CurrentValue = false, Flag = "WeaponMod",
        Callback = function(state) S.WeaponEnabled = state; if state then applyWeap() else revertWeap() end end,
    })
    CombatTab:CreateSlider({
        Name = "M1 Delay", Range={0.01,1}, Increment=0.01,
        CurrentValue=0.1, Flag="M1Delay",
        Callback = function(v) S.M1Speed = v; if S.WeaponEnabled then applyWeap() end end,
    })
    CombatTab:CreateSlider({
        Name = "Swing Speed", Range={1,10}, Increment=0.5,
        CurrentValue=3, Flag="SwingSpeed",
        Callback = function(v) S.SwingSpeed = v; if S.WeaponEnabled then applyWeap() end end,
    })

    CombatTab:CreateSection("Animation")
    CombatTab:CreateToggle({
        Name = "Animation Speed", CurrentValue=false, Flag="AnimSpeed",
        Callback = function(state) S.AnimEnabled = state end,
    })
    CombatTab:CreateSlider({
        Name = "Anim Speed Multiplier", Range={1,20}, Increment=1,
        CurrentValue=10, Flag="AnimSpeedVal",
        Callback = function(v) S.AnimSpeed = v end,
    })

    CombatTab:CreateSection("Shin & Mang")
    CombatTab:CreateToggle({
        Name = "Auto Shin Gain", CurrentValue=false, Flag="AutoShin",
        Callback = function(state) S.AutoShin = state end,
    })

    CombatTab:CreateSection("Attach")
    local AttachToggle = CombatTab:CreateToggle({
        Name = "Attach to Enemies", CurrentValue=false, Flag="Attach",
        Callback = function(state)
            S.AttachEnabled = state
            if state then attachTarget = attachClosest(); attachActive = true
            else attachStop() end
        end,
    })
    CombatTab:CreateKeybind({
        Name = "Attach Toggle Key", CurrentKeybind = "T", HoldToInteract = false, Flag = "AttachKey",
        Callback = function() AttachToggle:Set(not S.AttachEnabled) end,
    })
    CombatTab:CreateToggle({
        Name = "Attach to Players", CurrentValue=false, Flag="AttachPlayers",
        Callback = function(state) S.AttachTargetPlayers = state end,
    })
    CombatTab:CreateSlider({
        Name = "Attach Range", Range={10,100}, Increment=5,
        CurrentValue=20, Flag="AttachRange",
        Callback = function(v) S.AttachRange = v end,
    })
    CombatTab:CreateSlider({
        Name = "Attach Distance", Range={1,10}, Increment=0.5,
        CurrentValue=3, Flag="AttachDist",
        Callback = function(v) S.AttachDistance = v end,
    })
    CombatTab:CreateSlider({
        Name = "Attach Forward", Range={-5,5}, Increment=0.5,
        CurrentValue=0, Flag="AttachForward",
        Callback = function(v) S.AttachForward = v end,
    })
    CombatTab:CreateSlider({
        Name = "Attach Height", Range={-20,20}, Increment=0.5,
        CurrentValue=-5.5, Flag="AttachHeight",
        Callback = function(v) S.AttachHeight = v end,
    })

    CombatTab:CreateSection("Auto Parry")
    CombatTab:CreateToggle({
        Name = "Auto Parry", CurrentValue=false, Flag="AutoParry",
        Callback = function(state) S.ParryEnabled = state end,
    })
    CombatTab:CreateDropdown({
        Name = "Parry Mode", Options = {"Revamped", "Legacy"},
        CurrentOption = {"Revamped"}, MultipleOptions = false, Flag = "ParryMode",
        Callback = function(v) S.ParryMode = type(v)=="table" and v[1] or v end,
    })
    CombatTab:CreateDropdown({
        Name = "Parry Detection", Options = {"All Attacks", "M1 Only", "Parryable Only"},
        CurrentOption = {"All Attacks"}, MultipleOptions = false, Flag = "ParryDetection",
        Callback = function(v) S.ParryDetection = type(v)=="table" and v[1] or v end,
    })
    CombatTab:CreateToggle({
        Name = "Parry Indicator", CurrentValue=true, Flag="ParryIndicator",
        Callback = function(state) S.ParryIndicatorEnabled = state end,
    })
    CombatTab:CreateToggle({
        Name = "Parry Players", CurrentValue=false, Flag="ParryPlayers",
        Callback = function(state) S.ParryTargetPlayers = state end,
    })
    CombatTab:CreateToggle({
        Name = "Parry Spam", CurrentValue=false, Flag="ParrySpam",
        Callback = function(state) S.ParrySpamEnabled = state end,
    })
    CombatTab:CreateSlider({
        Name = "Parry Early Buffer", Range={0,0.6}, Increment=0.01,
        CurrentValue=0.28, Flag="ParryEarlyBuffer",
        Callback = function(v) S.ParryEarlyBuffer = v end,
    })
    CombatTab:CreateSlider({
        Name = "Parry Range", Range={5,60}, Increment=1,
        CurrentValue=20, Flag="ParryRange",
        Callback = function(v) S.ParryRange = v end,
    })
    CombatTab:CreateToggle({
        Name = "Animation Timing", CurrentValue=true, Flag="ParryAnimationTiming",
        Callback = function(state) S.ParryAnimationTiming = state end,
    })
    CombatTab:CreateSlider({
        Name = "Skill Parry Delay", Range={0,1}, Increment=0.05,
        CurrentValue=0.45, Flag="SkillParryDelay",
        Callback = function(v) S.SkillParryDelay = v end,
    })
    CombatTab:CreateSlider({
        Name = "Miss Chance (%)", Range={0,100}, Increment=1,
        CurrentValue=0, Flag="MissChance",
        Callback = function(v) S.MissChance = v end,
    })
    CombatTab:CreateSlider({
        Name = "Panic Chance (%)", Range={0,100}, Increment=1,
        CurrentValue=0, Flag="PanicChance",
        Callback = function(v) S.PanicChance = v end,
    })
    CombatTab:CreateLabel("Revamped predicts hit timing from attack animations + TimeUntilHitbox")

    task.spawn(function()
        while true do
            RS.Heartbeat:Wait()
            if UIS:IsKeyDown(Enum.KeyCode.N) or S.AutoShin then
                local ev = RepStore:FindFirstChild("Events") and RepStore.Events:FindFirstChild("ShinGain")
                if ev then pcall(function() ev:FireServer() end) end
            end
        end
    end)
end

