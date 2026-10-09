-- ============================================================
-- VISUALS TAB
-- ============================================================
local VisualTab = Window:CreateTab("Visuals", 10726204364)
VisualTab:CreateLabel("Visual effects and ESP are grouped here")

do
    VisualTab:CreateSection("Boss Bar")
    local createdBossEnemies = {}

    _G.BossBarToggle = function(enabled)
        if enabled then
            local aliveFolder = Workspace:FindFirstChild("Alive")
            if aliveFolder then
                for _, character in ipairs(aliveFolder:GetChildren()) do
                    if character:IsA("Model") and character ~= LP.Character then
                        if not character:FindFirstChild("BossEnemy") then
                            local f = Instance.new("Folder")
                            f.Name = "BossEnemy"; f.Parent = character
                            CollectionService:AddTag(f, "BossEnemy")
                            createdBossEnemies[character] = f
                        end
                    end
                end
            end
        else
            for character, bossEnemy in pairs(createdBossEnemies) do
                if bossEnemy and bossEnemy.Parent then bossEnemy:Destroy() end
            end
            createdBossEnemies = {}
        end
    end

    VisualTab:CreateToggle({
        Name = "Boss Bar (All Enemies)", CurrentValue = false, Flag = "BossBar",
        Callback = function(state) _G.BossBarToggle(state) end,
    })

    VisualTab:CreateSection("Fullbright")
    local fullbrightEnabled = false
    local fullbrightDefaults = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        ShadowSoftness = Lighting.ShadowSoftness,
    }
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    local atmosphereDefaults = atmosphere and {
        Density = atmosphere.Density, Offset = atmosphere.Offset,
        Glare = atmosphere.Glare, Haze = atmosphere.Haze,
    } or nil

    local fullbrightTarget = {
        Ambient = Color3.new(1, 1, 1), Brightness = 2, ClockTime = 14,
        FogEnd = 999999, FogStart = 0, GlobalShadows = false,
        OutdoorAmbient = Color3.new(1, 1, 1),
        EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1,
        ShadowSoftness = 0,
    }
    local function applyFullbright()
        -- The game may change Lighting at runtime. Only repair changed fields.
        for property, value in pairs(fullbrightTarget) do
            if Lighting[property] ~= value then Lighting[property] = value end
        end
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo then
            if atmo.Density ~= 0 then atmo.Density = 0 end
            if atmo.Offset ~= 0 then atmo.Offset = 0 end
            if atmo.Glare ~= 0 then atmo.Glare = 0 end
            if atmo.Haze ~= 0 then atmo.Haze = 0 end
        end
    end

    local function restoreFullbright()
        for prop, value in pairs(fullbrightDefaults) do
            pcall(function() Lighting[prop] = value end)
        end
        local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmo and atmosphereDefaults then
            for prop, value in pairs(atmosphereDefaults) do
                pcall(function() atmo[prop] = value end)
            end
        end
    end

    -- Reassert slowly in case the game changes Lighting; doing this every rendered
    -- frame was one of the script's largest avoidable idle costs.
    task.spawn(function()
        while true do
            task.wait(fullbrightEnabled and 0.5 or 1.5)
            if fullbrightEnabled then applyFullbright() end
        end
    end)

    VisualTab:CreateToggle({
        Name = "Fullbright", CurrentValue = false, Flag = "Fullbright",
        Callback = function(state)
            fullbrightEnabled = state
            if state then applyFullbright() else restoreFullbright() end
        end,
    })

    VisualTab:CreateButton({
        Name = "Remove Blood",
        Callback = function()
            local thrown = Workspace:FindFirstChild("Thrown")
            if thrown then
                for _, v in pairs(thrown:GetChildren()) do
                    if v.Name == "BloodOnGroundDecal" then v:Destroy() end
                end
            end
        end,
    })

    VisualTab:CreateSection("Damage Indicator")
    local dmgTracked = {}
    local dmgEnabled = false

    local function spawnDmgNum(target, amount)
        if not target or not target:FindFirstChild("Head") then return end
        local gui = Instance.new("BillboardGui")
        gui.Name = "DamageNumber"
        gui.Size = UDim2.new(0, 100, 0, 50)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.AlwaysOnTop = true; gui.LightInfluence = 0
        gui.Parent = target.Head
        local lbl = Instance.new("TextLabel", gui)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1; lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold; lbl.TextStrokeTransparency = 0.5
        lbl.Text = tostring(math.floor(amount))
        lbl.TextColor3 = Color3.new(1,0,0)
        local xo = (math.random()*2-1)*2
        TweenService:Create(gui,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {StudsOffset=Vector3.new(xo,5,0)}):Play()
        local tw2 = TweenService:Create(lbl,TweenInfo.new(0.5),{TextTransparency=1})
        tw2:Play(); tw2.Completed:Connect(function() gui:Destroy() end)
    end

    local function trackHum(hum, c)
        if dmgTracked[hum] then return end
        local record = {health = hum.Health}
        dmgTracked[hum] = record
        record.connection = hum:GetPropertyChangedSignal("Health"):Connect(function()
            if not dmgEnabled then return end
            local old = record.health
            local current = hum.Health
            local dmg = old - current
            if dmg > 0 and dmg < 1000 then spawnDmgNum(c, dmg) end
            record.health = current
        end)
    end

    VisualTab:CreateToggle({
        Name = "Damage Indicator", CurrentValue = false, Flag = "DamageIndicator",
        Callback = function(state)
            dmgEnabled = state
            if state then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
                        trackHum(obj, obj.Parent)
                    end
                end
            else
                for _, record in pairs(dmgTracked) do
                    if record.connection then record.connection:Disconnect() end
                end
                table.clear(dmgTracked)
            end
        end,
    })

    Workspace.DescendantAdded:Connect(function(obj)
        if dmgEnabled and obj:IsA("Humanoid") then
            task.wait(0.1)
            if obj.Parent and obj.Parent:IsA("Model") then trackHum(obj, obj.Parent) end
        end
    end)
end

