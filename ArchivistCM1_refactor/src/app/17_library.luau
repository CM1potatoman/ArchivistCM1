-- ------------------------------
-- AUTO LIBRARY
-- ------------------------------
local LibraryConfig = {
    Enabled = false,
    Floor = "Kether",
    YOffset = 5, -- legacy compatibility; combat now uses AttachDistance/AttachHeight
    AttachDistance = 3,
    AttachHeight = -5.5,
    Buff = false,
    UseInvitation = false,
    WaitForEnemies = true,
    Noclip = true,
    CornerMode = false,
    CornerCFrame = nil,
    CornerRadius = 18,
}
local LIBRARY_SAFE_ZONES = {
    Kether = CFrame.new(4729.77637, 338.901337, -1197.84521),
    Language = CFrame.new(4799.5625, 390.056946, -1166.06909),
    Philosophy = CFrame.new(996.82196, 1746.71643, -1511.82288),
}
local LIBRARY_FLOOR_MARKERS = {
    Kether = "Books",
    Language = "Language VFX",
    Philosophy = "Binah Floor",
}

local function isLibraryInstance()
    if game.PlaceId ~= WARP_PLACE_ID or isWarpTrainInstance() then return false end
    local npcs = Workspace:FindFirstChild("NPCS")
    if npcs and (npcs:FindFirstChild("Angela") or npcs:FindFirstChild("Library Director") or npcs:FindFirstChild("Ordeal Entrance")) then
        return true
    end
    local map = Workspace:FindFirstChild("Map")
    return map and (map:FindFirstChild("Books") or map:FindFirstChild("Language VFX") or map:FindFirstChild("Binah Floor")) ~= nil
end

local function libraryFloorReady()
    -- Treat any CurrentArea other than The Lobby as an active Library run.
    -- run. Keep the old map marker check as a compatibility fallback.
    local data = LP:FindFirstChild("Data")
    local currentArea = data and data:FindFirstChild("CurrentArea")
    if currentArea and currentArea:IsA("StringValue") and currentArea.Value ~= "" and currentArea.Value ~= "The Lobby" then
        return true
    end
    local map = Workspace:FindFirstChild("Map")
    local marker = LIBRARY_FLOOR_MARKERS[LibraryConfig.Floor]
    return map and marker and map:FindFirstChild(marker) ~= nil
end

local function useLibraryInvitation(runtime)
    -- Isolate the player briefly before using the Invitation so the transition starts reliably.
    -- on a temporary platform, use Invitation once, then wait for Library.
    local character, humanoid, myRoot = characterParts()
    if not character or not humanoid or not myRoot then return false end

    local invitation = LP.Backpack:FindFirstChild("Invitation") or character:FindFirstChild("Invitation")
    if not invitation or not invitation:IsA("Tool") then return false end

    local away = myRoot.Position + Vector3.new(500, 0, 0)
    local skyPlatform = Instance.new("Part")
    skyPlatform.Name = "ArchivistLibraryInvitePlatform"
    skyPlatform.Size = Vector3.new(10, 1, 10)
    skyPlatform.Anchored = true
    skyPlatform.CanCollide = true
    skyPlatform.Transparency = 1
    skyPlatform.CFrame = CFrame.new(away)
    skyPlatform.Parent = Workspace

    local function cleanupPlatform()
        if skyPlatform and skyPlatform.Parent then
            pcall(function() skyPlatform:Destroy() end)
        end
    end

    myRoot.CFrame = CFrame.new(away + Vector3.new(0, 3, 0))
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.5)

    if invitation.Parent == LP.Backpack then
        pcall(function() humanoid:EquipTool(invitation) end)
        task.wait(0.5)
    end

    notify("Auto Library", "Using Invitation...")
    pcall(function()
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.1)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)

    local waited = 0
    while featureAlive(runtime) and LibraryConfig.Enabled and waited < 15 and not isLibraryInstance() do
        task.wait(0.5)
        waited += 0.5
    end

    local success = isLibraryInstance()
    cleanupPlatform()
    return success
end

local function enterLibrary(runtime)
    if game.PlaceId ~= MAIN_PLACE_ID then return false end
    enableRuntimeNoclip(runtime, function() return LibraryConfig.Noclip end)

    local character = LP.Character
    local hasInvitation = LP.Backpack:FindFirstChild("Invitation")
        or (character and character:FindFirstChild("Invitation"))

    if LibraryConfig.UseInvitation and hasInvitation then
        notify("Auto Library", "Teleported away, using Invitation...")
        if useLibraryInvitation(runtime) then return true end
        notify("Auto Library", "Invitation failed, trying NPC...")
    end

    -- Reuse the same shared dialogue selector for Library entry choices.
    local function selectOption(needle)
        return DialogueUtil.selectOptionStable(needle, 8, runtime)
    end

    local npcs = Workspace:FindFirstChild("NPCS")
    local dumpster = npcs and npcs:FindFirstChild("Dumpster Guy")
    local dumpsterRoot = dumpster and dumpster:FindFirstChild("HumanoidRootPart")
    local _, _, myRoot = characterParts()
    if not dumpster or not dumpsterRoot or not myRoot then
        notify("Auto Library", "Dumpster Guy not found")
        return false
    end

    -- Use the known stable approach/camera interaction sequence.
    local oldMinZoom, oldMaxZoom = LP.CameraMinZoomDistance, LP.CameraMaxZoomDistance
    myRoot.CFrame = CFrame.lookAt(dumpsterRoot.Position + Vector3.new(7, 0, 0), dumpsterRoot.Position)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.3)

    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.CFrame = CFrame.lookAt(dumpsterRoot.Position + Vector3.new(7, 3, 0), dumpsterRoot.Position)
    end
    LP.CameraMaxZoomDistance = 10
    LP.CameraMinZoomDistance = 10
    task.wait(0.5)
    VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.15)
    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    LP.CameraMinZoomDistance = oldMinZoom
    LP.CameraMaxZoomDistance = oldMaxZoom
    task.wait(3)

    if not LP.PlayerGui:FindFirstChild("Dialogue") then return false end
    if not selectOption("Hand him some Ahn. (2.5M") then return false end
    pcall(function() GuiService.SelectedObject = nil; GuiService.GuiNavigationEnabled = false; GuiService.AutoSelectGuiEnabled = false end)
    task.wait(0.5)

    notify("Auto Library", "Selecting Library...")
    local attempts = 0
    repeat
        if not featureAlive(runtime) or not LibraryConfig.Enabled then return false end
        if isLibraryInstance() then return true end
        attempts += 1
        if LP.PlayerGui:FindFirstChild("Dialogue") then
            selectOption("Library")
        end
        task.wait(1.5)
    until attempts > 60

    notify("Auto Library", "60s timeout")
    return isLibraryInstance()
end

local function startLibraryOrdeal(runtime)
    local npcs = Workspace:FindFirstChild("NPCS")
    if not npcs then return false end

    -- Use the same shared selector as every other dialogue path.
    local function selectOption(needle)
        return DialogueUtil.selectOptionStable(needle, 8, runtime)
    end

    local function findLibraryBook()
        local containers = {LP:FindFirstChild("Backpack"), LP.Character}
        local al = Workspace:FindFirstChild("Alive")
        if al then table.insert(containers, al:FindFirstChild(LP.Name)) end
        for _, container in ipairs(containers) do
            if container then
                local exact = container:FindFirstChild("Book Of The Library")
                if exact then return exact end
                for _, child in ipairs(container:GetChildren()) do
                    local lower = string.lower(child.Name)
                    if string.find(lower, "book", 1, true) and string.find(lower, "library", 1, true) then
                        return child
                    end
                end
            end
        end
        return nil
    end

    -- Book hand-off path: equip by parenting the book into the character before interacting.
    -- character, stand three studs in front of Library Director, press E up to
    -- three times, and consider it handed off only when the book disappears.
    if LibraryConfig.Buff and not libraryFloorReady() then
        local director = npcs:FindFirstChild("Library Director")
        local directorRoot = director and director:FindFirstChild("HumanoidRootPart")
        if not directorRoot then
            notify("Auto Library", "Impuritas: Library Director not found, retrying...")
        else
            local book = findLibraryBook()
            if not book then
                for _ = 1, 5 do
                    if not featureAlive(runtime) then return false end
                    task.wait(1)
                    book = findLibraryBook()
                    if book then break end
                end
            end

            if not book then
                notify("Auto Library", "Impuritas: 'Book Of The Library' not found in inventory!")
            else
                local character = LP.Character
                if character then
                    pcall(function() book.Parent = character end)
                    task.wait(2)
                    notify("Auto Library", "Impuritas: Handing book to Library Director...")

                    local _, _, myRoot = characterParts()
                    if myRoot then
                        myRoot.CFrame = CFrame.lookAt(
                            directorRoot.Position + directorRoot.CFrame.LookVector * 3,
                            directorRoot.Position
                        )
                        myRoot.AssemblyLinearVelocity = Vector3.zero
                        myRoot.AssemblyAngularVelocity = Vector3.zero
                    end
                    task.wait(0.5)

                    local handed = false
                    for attempt = 1, 3 do
                        if not featureAlive(runtime) then return false end
                        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.15)
                        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        task.wait(2)
                        if not findLibraryBook() or not book.Parent then
                            handed = true
                            break
                        end
                        if attempt < 3 then
                            notify("Auto Library", "Impuritas: Retrying hand-off (" .. tostring(attempt + 1) .. "/3)...")
                            task.wait(1)
                        end
                    end
                    if not handed then
                        notify("Auto Library", "Impuritas: Could not hand book — continuing anyway")
                    else
                        notify("Auto Library", "Impuritas: Done! Heading to Ordeal door...")
                    end
                    task.wait(1)
                end
            end
        end
    end

    if libraryFloorReady() then return true end

    local floorName = ({
        Kether = "Kether Floor",
        Language = "Language Floor",
        Philosophy = "Philosophy Floor",
    })[LibraryConfig.Floor] or (tostring(LibraryConfig.Floor) .. " Floor")

    -- Known stable Ordeal Entrance position and timing.
    for _ = 1, 5 do
        if not featureAlive(runtime) or not LibraryConfig.Enabled then return false end
        local _, _, myRoot = characterParts()
        if not myRoot then return false end

        myRoot.CFrame = CFrame.new(730.009, 525.687, 1013.84)
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
        task.wait(2)
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)

        local opened = false
        local waited = 0
        repeat
            if LP.PlayerGui:FindFirstChild("Dialogue") then opened = true; break end
            task.wait(0.3)
            waited += 0.3
        until waited >= 6 or not featureAlive(runtime)

        if not opened then
            notify("Auto Library", "Ordeal door dialogue did not open")
            task.wait(3)
            continue
        end

        task.wait(1)
        if not selectOption("Select a floor") then
            notify("Auto Library", "Could not select floor option")
            pcall(function() GuiService.SelectedObject = nil; GuiService.GuiNavigationEnabled = false; GuiService.AutoSelectGuiEnabled = false end)
            task.wait(3)
            continue
        end

        pcall(function() GuiService.SelectedObject = nil; GuiService.GuiNavigationEnabled = false; GuiService.AutoSelectGuiEnabled = false end)
        task.wait(1)
        if not selectOption(floorName) then
            notify("Auto Library", "Could not select " .. floorName)
            pcall(function() GuiService.SelectedObject = nil; GuiService.GuiNavigationEnabled = false; GuiService.AutoSelectGuiEnabled = false end)
            task.wait(3)
            continue
        end

        -- Re-interact after the floor selection, then choose the final start option.
        -- Begin Ordeal. If Begin is not offered, it probes Select a floor again.
        pcall(function() GuiService.SelectedObject = nil; GuiService.GuiNavigationEnabled = false; GuiService.AutoSelectGuiEnabled = false end)
        task.wait(1)
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.15)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        task.wait(2)

        if LP.PlayerGui:FindFirstChild("Dialogue") then
            if not selectOption("Begin Ordeal") then
                selectOption("Select a floor")
            end
        end
        pcall(function() GuiService.SelectedObject = nil; GuiService.GuiNavigationEnabled = false; GuiService.AutoSelectGuiEnabled = false end)
        task.wait(2)

        if libraryFloorReady() then return true end
        -- The floor can already be selected even if its map marker arrives a
        -- little later; give the game the same breathing room before retrying.
        local readyWait = 0
        while featureAlive(runtime) and readyWait < 3 and not libraryFloorReady() do
            task.wait(0.3)
            readyWait += 0.3
        end
        if libraryFloorReady() then return true end
    end

    return libraryFloorReady()
end

local function lootNearbyDrops(runtime, radius)
    local thrown = Workspace:FindFirstChild("Thrown")
    local _, _, myRoot = characterParts()
    if not thrown or not myRoot then return 0 end
    local collected = 0
    for _, item in ipairs(thrown:GetChildren()) do
        if not featureAlive(runtime) then return collected end
        local pivot = modelPivot(item)
        if pivot and (myRoot.Position - pivot.Position).Magnitude <= (radius or 500) then
            local prompt = findPrompt(item)
            if prompt then
                myRoot.CFrame = pivot
                if triggerPrompt(prompt) then collected += 1 end
                task.wait(0.12)
            end
        end
    end
    return collected
end

local function libraryLivingTargets()
    local list = {}
    local folder = alive()
    if not folder then return list end
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model ~= LP.Character and not isPlr(model) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local r = root(model)
            if hum and r and hum.Health > 0 then table.insert(list, model) end
        end
    end
    return list
end

local function libraryCornerStep(runtime)
    local _, _, myRoot = characterParts()
    if not myRoot then return false end
    if not LibraryConfig.CornerCFrame then LibraryConfig.CornerCFrame = myRoot.CFrame end

    local targets = libraryLivingTargets()
    if #targets == 0 then
        myRoot.CFrame = LibraryConfig.CornerCFrame
        return false
    end

    -- Grouping strategy: touch each un-aggroed enemy first, then hold the configured corner.
    -- hold one point so the group converges instead of chasing targets around.
    for _, target in ipairs(targets) do
        if not featureAlive(runtime) then return false end
        if not target:FindFirstChild("Aggrod") then
            local tr = root(target)
            if tr then
                myRoot.CFrame = tr.CFrame * CFrame.Angles(math.rad(90), 0, 0) + Vector3.new(0, 10, 0)
                myRoot.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.12)
                return true
            end
        end
    end

    myRoot.CFrame = LibraryConfig.CornerCFrame
    myRoot.AssemblyLinearVelocity = Vector3.zero
    table.sort(targets, function(a, b)
        local ar, br = root(a), root(b)
        if not ar then return false end
        if not br then return true end
        return (ar.Position - LibraryConfig.CornerCFrame.Position).Magnitude < (br.Position - LibraryConfig.CornerCFrame.Position).Magnitude
    end)
    local target = targets[1]
    local tr = target and root(target)
    if target and tr and (tr.Position - LibraryConfig.CornerCFrame.Position).Magnitude <= LibraryConfig.CornerRadius then
        attackPulse(target, 35)
        local hum = target:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 3 then
            local grip = RepStore:FindFirstChild("Events") and RepStore.Events:FindFirstChild("Grip")
            if grip then pcall(function() grip:FireServer(target) end) end
        end
    end
    return true
end

function LibraryConfig.fightTarget(runtime, target)
    if not featureAlive(runtime) or not target or not target.Parent then return false end
    local character, humanoid, myRoot = characterParts()
    local targetRoot = root(target)
    local targetHum = target:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid or not myRoot or not targetRoot or not targetHum or targetHum.Health <= 0 then
        return false
    end

    if target:FindFirstChild("Knocked") or targetHum.Health <= 3 then
        local grip = RepStore:FindFirstChild("Events") and RepStore.Events:FindFirstChild("Grip")
        if grip then pcall(function() grip:FireServer(target) end) end
    end

    local dist = LibraryConfig.AttachDistance or 3
    local height = LibraryConfig.AttachHeight or -5.5
    local tp = targetRoot.Position + (-targetRoot.CFrame.LookVector) * dist + Vector3.new(0, height, 0)
    myRoot.CFrame = CFrame.lookAt(tp, targetRoot.Position)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    pcall(function() humanoid.AutoRotate = false end)
    attackPulse(target, 35)
    return true
end

local function runLibraryInstance(runtime)
    enableRuntimeNoclip(runtime, function() return LibraryConfig.Noclip end)
    addFeatureCleanup(runtime, function()
        local character = LP.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then pcall(function() humanoid.AutoRotate = true end) end
        if humanoid then pcall(function() Camera.CameraSubject = humanoid end) end
    end)
    if not startLibraryOrdeal(runtime) then
        notify("Auto Library", "Could not start the selected Library floor.")
        return
    end
    local started = tick()
    while featureAlive(runtime) and LibraryConfig.Enabled and not libraryFloorReady() and tick() - started < 20 do
        task.wait(0.25)
    end

    local priority = {Angelica = true}
    if LibraryConfig.CornerMode and not LibraryConfig.CornerCFrame then
        local _, _, myRoot = characterParts()
        LibraryConfig.CornerCFrame = myRoot and myRoot.CFrame or LIBRARY_SAFE_ZONES[LibraryConfig.Floor]
    end
    while featureAlive(runtime) and LibraryConfig.Enabled and isLibraryInstance() do
        if LibraryConfig.CornerMode then
            libraryCornerStep(runtime)
        else
            local al = alive()
            local angelica = al and al:FindFirstChild("Angelica")
            local target = angelica or bestNonPlayerTarget(nil, priority)
            if target then
                LibraryConfig.fightTarget(runtime, target)
            else
                lootNearbyDrops(runtime, 500)
                local _, _, myRoot = characterParts()
                local safe = LIBRARY_SAFE_ZONES[LibraryConfig.Floor]
                if myRoot and safe then myRoot.CFrame = safe end
                if LibraryConfig.WaitForEnemies then task.wait(0.22) end
            end
        end
        task.wait(0.08)
    end
end

local function startLibrary()
    LibraryConfig.Enabled = true
    if game.PlaceId == MAIN_PLACE_ID then
        startFeature("AutoLibrary", function(runtime)
            if not enterLibrary(runtime) then
                notify("Auto Library", "Could not start Library entry.")
            end
        end)
        return true
    end
    if not isLibraryInstance() then
        LibraryConfig.Enabled = false
        notify("Auto Library", "Run this in the main city or inside a Library instance.")
        return false
    end
    startFeature("AutoLibrary", runLibraryInstance)
    return true
end

local function stopLibrary()
    LibraryConfig.Enabled = false
    stopFeature("AutoLibrary")
    if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
        Camera.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid")
    end
end

AdvancedAutomationTab:CreateSection("Library")
AdvancedAutomationTab:CreateToggle({
    Name = "Auto Library", CurrentValue = false, Flag = "AutoLibrary",
    Callback = function(state)
        if state then
            if not startLibrary() then LibraryConfig.Enabled = false end
        else
            stopLibrary()
        end
    end,
})
AdvancedAutomationTab:CreateDropdown({
    Name = "Library Floor", Options = {"Kether", "Language", "Philosophy"}, CurrentOption = {"Kether"},
    MultipleOptions = false, Flag = "LibraryFloor",
    Callback = function(value) LibraryConfig.Floor = valueFromOption(value) or "Kether" end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Use Invitation", CurrentValue = false, Flag = "LibraryUseInvitation",
    Callback = function(state) LibraryConfig.UseInvitation = state end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Use Book of the Library Buff", CurrentValue = false, Flag = "LibraryBuff",
    Callback = function(state) LibraryConfig.Buff = state end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Wait For Enemies", CurrentValue = true, Flag = "LibraryWaitEnemies",
    Callback = function(state) LibraryConfig.WaitForEnemies = state end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Auto Library Noclip", CurrentValue = true, Flag = "LibraryNoclip",
    Callback = function(state) LibraryConfig.Noclip = state end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Corner / Group Strat", CurrentValue = false, Flag = "LibraryCornerMode",
    Callback = function(state) LibraryConfig.CornerMode = state end,
})
AdvancedAutomationTab:CreateButton({
    Name = "Set Library Corner Here",
    Callback = function()
        local _, _, r = characterParts()
        if r then LibraryConfig.CornerCFrame = r.CFrame; notify("Auto Library", "Corner position saved for this session.") end
    end,
})
AdvancedAutomationTab:CreateSlider({
    Name = "Corner Attack Radius", Range = {6, 40}, Increment = 1, CurrentValue = 18, Flag = "LibraryCornerRadius",
    Callback = function(value) LibraryConfig.CornerRadius = value end,
})
AdvancedAutomationTab:CreateSection("Library Combat Position")
AdvancedAutomationTab:CreateSlider({
    Name = "Library Attach Distance", Range = {-20, 20}, Increment = 0.5, CurrentValue = 3, Flag = "LibraryAttachDistance",
    Callback = function(value) LibraryConfig.AttachDistance = value end,
})
AdvancedAutomationTab:CreateSlider({
    Name = "Library Attach Height", Range = {-20, 20}, Increment = 0.5, CurrentValue = -5.5, Flag = "LibraryAttachHeight",
    Callback = function(value) LibraryConfig.AttachHeight = value end,
})
AdvancedAutomationTab:CreateLabel("RR-style positioning: Distance moves behind/in front of the target; Height moves vertically.")

