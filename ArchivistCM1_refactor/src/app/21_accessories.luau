-- ============================================================
-- EXTRAS TAB
-- ============================================================
local ExtrasTab = InventoryTab -- merged into Utilities

do
    ExtrasTab:CreateSection("Detect Singularities")
    ExtrasTab:CreateLabel("Highlights every player carrying a Singularity")

    local function detectSingularities()
        local ev = RepStore:FindFirstChild("Events")
        local found = 0
        for _, v in ipairs(Players:GetPlayers()) do
            local data = v:FindFirstChild("Data")
            if data then
                local sing = data:FindFirstChild("Singularity")
                if sing and sing.Value ~= "" then
                    found = found + 1
                    task.spawn(function()
                        if ev and ev:FindFirstChild("Subtitle") then
                            pcall(function() ev.Subtitle:FireClient(LP, v.Name, "#FFAA00") end)
                        end
                        if v.Character then
                            local hl = Instance.new("Highlight")
                            hl.Name = "ArchivistSingHL"
                            hl.Parent = v.Character
                            hl.Adornee = v.Character
                            hl.OutlineColor = Color3.fromRGB(255, 170, 0)
                            hl.FillColor = Color3.fromRGB(255, 170, 0)
                            hl.FillTransparency = 0.7
                            hl.OutlineTransparency = 0.2
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            task.wait(5)
                            pcall(function() hl:Destroy() end)
                        end
                    end)
                end
            end
        end
        if found == 0 and ev and ev:FindFirstChild("Subtitle") then
            pcall(function() ev.Subtitle:FireClient(LP, "No singularities in this server", "#888888") end)
        end
    end

    ExtrasTab:CreateButton({ Name = "Detect Singularities (Highlight)", Callback = detectSingularities })

    ExtrasTab:CreateButton({
        Name = "Give Detect Singularities Tool",
        Callback = function()
            for _, t in ipairs(LP.Backpack:GetChildren()) do if t.Name == "Detect Singularities" then t:Destroy() end end
            if LP.Character then
                for _, t in ipairs(LP.Character:GetChildren()) do if t.Name == "Detect Singularities" then t:Destroy() end end
            end
            local Skill = Instance.new("Tool")
            Skill.Name = "Detect Singularities"
            Skill.CanBeDropped = false; Skill.RequiresHandle = false
            Skill.ToolTip = "Finds all singularities in the server"
            for _, tag in ipairs({"Special","Page"}) do
                local f = Instance.new("Folder"); f.Name = tag; f.Parent = Skill
            end
            Skill:SetAttribute("CD", 5)
            Skill:SetAttribute("LightCost", 0)
            Skill:SetAttribute("RealPageName", "Detect Singularities")
            Skill.Equipped:Connect(function()
                task.spawn(function()
                    detectSingularities()
                    task.wait(0.15)
                    if LP.Character then Skill.Parent = LP.Backpack end
                end)
            end)
            Skill.Parent = LP.Backpack
            print("[Archivist] Detect Singularities tool added")
        end,
    })

    ExtrasTab:CreateSection("Accessories")
    ExtrasTab:CreateLabel("Equip cosmetic accessories from the main Archivist UI")

    local accessoryRemote = RepStore:FindFirstChild("Events") and RepStore.Events:FindFirstChild("AddAccessory")
    local accessoryRoot = RepStore:FindFirstChild("Assets") and RepStore.Assets:FindFirstChild("Accessories")
    local accessoryEntries = {}
    local accessoryLabels = {}

    if accessoryRoot then
        for _, category in ipairs(accessoryRoot:GetChildren()) do
            if category:IsA("Folder") and category.Name ~= "SpecialAccessories" then
                for _, accessory in ipairs(category:GetChildren()) do
                    if accessory:IsA("Accessory") or accessory:IsA("Folder") or accessory:IsA("Model") then
                        local label = category.Name .. " / " .. accessory.Name
                        accessoryEntries[label] = {category = category.Name, object = accessory}
                        table.insert(accessoryLabels, label)
                    end
                end
            end
        end
        table.sort(accessoryLabels)
    end

    if #accessoryLabels == 0 then
        accessoryLabels = {"No accessories found"}
    end

    local selectedAccessory = accessoryLabels[1]
    ExtrasTab:CreateDropdown({
        Name = "Accessory",
        Options = accessoryLabels,
        CurrentOption = {selectedAccessory},
        MultipleOptions = false,
        Flag = "AccessorySelection",
        Callback = function(option)
            selectedAccessory = GetValue(option)
        end,
    })

    ExtrasTab:CreateButton({
        Name = "Equip Selected Accessory",
        Callback = function()
            local entry = accessoryEntries[selectedAccessory]
            if not entry or not accessoryRemote then
                warn("[Archivist] Accessory equip unavailable")
                return
            end
            pcall(function()
                accessoryRemote:FireServer(entry.category, entry.object)
            end)
        end,
    })

end

-- Persistent configuration and teleport-resume controls are omitted from the public build.

