-- ============================================================
-- ESP TAB
-- ============================================================
local ESPTab = VisualTab -- merged into Visuals

do
    local KrostinSettings = {
        Enabled=false, ShowBox=true, ShowHealth=true, ShowName=true, ShowDistance=false,
        Distance=2000, MaxHighlights=10, FontSize=13,
        BoxThickness=2, BoxBaseWidth=45, BoxBaseHeight=65,
        BoxColor=Color3.fromRGB(255,255,255),
        PlayerColor=Color3.fromRGB(0,120,255),
        NPCColor=Color3.fromRGB(255,0,0),
        HPColor=Color3.fromRGB(0,255,0),
        HealthBarWidth=4,
    }

    local ESPObjects = {}
    local espDrawFields = {"Box", "HealthBg", "Health", "HealthText", "Text"}

    local function removeESP(key)
        local data = ESPObjects[key]; if not data then return end
        if data.Connections then for _, c in ipairs(data.Connections) do pcall(c.Disconnect, c) end end
        for _, key in ipairs(espDrawFields) do
            local drawing = data[key]
            if drawing then
                -- Drawing objects must be removed, not just hidden, or NPC turnover leaks them.
                pcall(function()
                    if drawing.Remove then drawing:Remove()
                    elseif drawing.Destroy then drawing:Destroy() end
                end)
            end
        end
        if data.Highlight then pcall(data.Highlight.Destroy, data.Highlight) end
        ESPObjects[key] = nil
    end

    local function addEntityESP(entity)
        if ESPObjects[entity] or not entity:IsA("Model") then return end
        local hum = entity:FindFirstChildOfClass("Humanoid")
        local r = root(entity)
        if not hum or not r or hum.Health <= 0 then return end
        local isPlayer = Players:GetPlayerFromCharacter(entity) ~= nil
        local plrObj = isPlayer and Players:GetPlayerFromCharacter(entity) or nil
        local eName = plrObj and plrObj.Name or entity.Name
        local hlColor = isPlayer and KrostinSettings.PlayerColor or KrostinSettings.NPCColor

        local box = Drawing.new("Square"); box.Thickness = KrostinSettings.BoxThickness
        box.Filled = false; box.Color = KrostinSettings.BoxColor
        local healthBg = Drawing.new("Square"); healthBg.Filled = true
        healthBg.Color = Color3.fromRGB(30,30,30); healthBg.Thickness = 0
        local healthBar = Drawing.new("Square"); healthBar.Filled = true
        healthBar.Color = KrostinSettings.HPColor; healthBar.Thickness = 0
        local healthText = Drawing.new("Text"); healthText.Center = true
        healthText.Outline = true; healthText.Color = KrostinSettings.HPColor
        healthText.Size = KrostinSettings.FontSize - 1
        local nameText = Drawing.new("Text"); nameText.Center = true
        nameText.Outline = true; nameText.Color = KrostinSettings.BoxColor
        nameText.Size = KrostinSettings.FontSize

        local highlight = Instance.new("Highlight")
        highlight.FillColor = hlColor; highlight.OutlineColor = hlColor
        highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0.3
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = entity; highlight.Enabled = false

        local connections = {}
        table.insert(connections, hum.Died:Connect(function() removeESP(entity) end))
        table.insert(connections, entity.AncestryChanged:Connect(function()
            if not entity:IsDescendantOf(Workspace) then removeESP(entity) end
        end))

        ESPObjects[entity] = {
            Box=box, HealthBg=healthBg, Health=healthBar, HealthText=healthText,
            Text=nameText, Highlight=highlight,
            Hum=hum, Root=r, Name=eName, IsPlayer=isPlayer,
            Connections=connections,
        }
    end

    local lastHLUpdate = 0
    local espFrameAccumulator = 0
    local espWasEnabled = false
    RS.RenderStepped:Connect(function(dt)
        KrostinSettings.Enabled = S.ESPEnabled
        KrostinSettings.ShowBox = S.ESPShowBox
        KrostinSettings.ShowHealth = S.ESPShowHealth
        KrostinSettings.ShowName = S.ESPShowName
        KrostinSettings.ShowDistance = S.ESPShowDist
        KrostinSettings.Distance = S.ESPMaxDist

        if not KrostinSettings.Enabled then
            if espWasEnabled then
                for _, data in pairs(ESPObjects) do
                    for _, k in ipairs(espDrawFields) do
                        if data[k] then data[k].Visible = false end
                    end
                    if data.Highlight then data.Highlight.Enabled = false end
                end
            end
            espWasEnabled = false
            return
        end
        espWasEnabled = true
        espFrameAccumulator += dt
        if espFrameAccumulator < (1 / 30) then return end
        espFrameAccumulator = 0

        local myChar = LP.Character; local myRoot = myChar and root(myChar)
        if not myRoot then return end
        local myPos = myRoot.Position
        local candidates = {}

        for entity, data in pairs(ESPObjects) do
            if not entity.Parent then removeESP(entity); continue end
            local pos = data.Root and data.Root.Position
            if data.Hum and data.Hum.Health <= 0 then removeESP(entity); continue end
            if not pos then continue end
            local dist = (pos - myPos).Magnitude
            if dist <= KrostinSettings.Distance then
                table.insert(candidates, {entity=entity, data=data, dist=dist})
            else
                for _, k in ipairs(espDrawFields) do
                    if data[k] then data[k].Visible = false end
                end
                if data.Highlight then data.Highlight.Enabled = false end
            end
        end

        table.sort(candidates, function(a,b) return a.dist < b.dist end)

        local now = tick()
        if now - lastHLUpdate > 0.1 then
            lastHLUpdate = now
            for i, entry in ipairs(candidates) do
                local hl = entry.data.Highlight
                if hl then
                    if i <= KrostinSettings.MaxHighlights then
                        hl.Enabled = true
                        local col = entry.data.IsPlayer and KrostinSettings.PlayerColor or KrostinSettings.NPCColor
                        hl.FillColor = col; hl.OutlineColor = col
                    else hl.Enabled = false end
                end
            end
        end

        for _, entry in ipairs(candidates) do
            local data = entry.data; local dist = entry.dist
            local rootPos = data.Root.Position
            local scaleFactor = 100 / math.max(dist, 1)
            local boxW = math.clamp(KrostinSettings.BoxBaseWidth * scaleFactor, 20, 200)
            local boxH = math.clamp(KrostinSettings.BoxBaseHeight * scaleFactor, 30, 300)
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
            if not onScreen then
                for _, k in ipairs(espDrawFields) do
                    if data[k] then data[k].Visible = false end
                end
                continue
            end
            local cx, cy = screenPos.X, screenPos.Y
            local boxX, boxY = cx - boxW*0.5, cy - boxH*0.5

            if KrostinSettings.ShowBox then
                data.Box.Visible = true; data.Box.Position = Vector2.new(boxX,boxY)
                data.Box.Size = Vector2.new(boxW, boxH)
            else data.Box.Visible = false end

            if KrostinSettings.ShowHealth then
                local pct = math.clamp(data.Hum.Health/data.Hum.MaxHealth,0,1)
                local bw = KrostinSettings.HealthBarWidth
                local bx = boxX - bw - 3; local fillH = boxH*pct
                data.HealthBg.Visible = true; data.HealthBg.Position = Vector2.new(bx,boxY)
                data.HealthBg.Size = Vector2.new(bw,boxH)
                data.Health.Visible = true; data.Health.Position = Vector2.new(bx,boxY+boxH-fillH)
                data.Health.Size = Vector2.new(bw, fillH)
                data.HealthText.Visible = true
                data.HealthText.Text = math.floor(data.Hum.Health) .. " HP"
                data.HealthText.Position = Vector2.new(cx, boxY+boxH+3)
            else
                data.HealthBg.Visible = false; data.Health.Visible = false; data.HealthText.Visible = false
            end

            local nameStr = ""
            if KrostinSettings.ShowName then nameStr = data.Name end
            if KrostinSettings.ShowDistance then
                nameStr = nameStr .. (nameStr ~= "" and " " or "") .. string.format("[%.0fm]", dist)
            end
            data.Text.Visible = nameStr ~= ""
            if nameStr ~= "" then
                data.Text.Text = nameStr
                data.Text.Position = Vector2.new(cx, boxY - KrostinSettings.FontSize - 3)
            end
        end
    end)

    local function scanAliveFolder()
        local al = alive()
        if al then
            if S.ESPEnabled then
                for _, obj in ipairs(al:GetChildren()) do
                    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not isPlr(obj) then
                        addEntityESP(obj)
                    end
                end
            end
            al.ChildAdded:Connect(function(child)
                if not S.ESPEnabled then return end
                task.wait(0.5)
                if S.ESPEnabled and child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") and not isPlr(child) then
                    addEntityESP(child)
                end
            end)
        end
    end

    local function watchPlayer(plr)
        if plr == LP then return end
        if S.ESPEnabled and plr.Character then addEntityESP(plr.Character) end
        plr.CharacterAdded:Connect(function(char)
            if not S.ESPEnabled then return end
            task.wait(1)
            if S.ESPEnabled then addEntityESP(char) end
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do watchPlayer(plr) end
    Players.PlayerAdded:Connect(watchPlayer)

    task.spawn(function()
        while true do
            task.wait(S.ESPEnabled and 3 or 10)
            if S.ESPEnabled then
                local al = alive()
                if al then
                    for _, obj in ipairs(al:GetChildren()) do
                        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not isPlr(obj) then
                            if not ESPObjects[obj] then addEntityESP(obj) end
                        end
                    end
                end
            end
        end
    end)

    task.defer(scanAliveFolder)

    ESPTab:CreateSection("ESP Settings")
    ESPTab:CreateToggle({ Name = "ESP", CurrentValue=false, Flag="ESP",
        Callback = function(state)
            S.ESPEnabled = state
            if not state then
                -- Reclaim all drawings when ESP is off; enable recreates as needed.
                while next(ESPObjects) do removeESP(next(ESPObjects)) end
            end
            if state then
                -- Populate tracked entities immediately instead of waiting for the slow scan.
                local al = alive()
                if al then
                    for _, obj in ipairs(al:GetChildren()) do
                        if obj:IsA("Model") and not isPlr(obj) then addEntityESP(obj) end
                    end
                end
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LP and plr.Character then addEntityESP(plr.Character) end
                end
            end
        end })
    ESPTab:CreateToggle({ Name = "Show Boxes", CurrentValue=true, Flag="ESPBox",
        Callback = function(state) S.ESPShowBox = state end })
    ESPTab:CreateToggle({ Name = "Show Health", CurrentValue=true, Flag="ESPHealth",
        Callback = function(state) S.ESPShowHealth = state end })
    ESPTab:CreateToggle({ Name = "Show Names", CurrentValue=true, Flag="ESPNames",
        Callback = function(state) S.ESPShowName = state end })
    ESPTab:CreateToggle({ Name = "Show Distance", CurrentValue=false, Flag="ESPDist",
        Callback = function(state) S.ESPShowDist = state end })
    ESPTab:CreateSlider({ Name = "Max Distance", Range={100,5000}, Increment=100,
        CurrentValue=2000, Flag="ESPMaxDist", Callback = function(v) S.ESPMaxDist = v end })
end

