-- ------------------------------
-- AUTO L CORP
-- ------------------------------
local LCorpConfig = {
    Enabled = false,
    Boss = "Lei Heng",
    AttachDistance = 3,
    AttachHeight = -5.5,
    KilledBoss = false,
    AutoLoot = true,
    GeneratorAssist = true,
}
local LCORP_BOSSES = {
    ["Lei Heng"] = "Capo IIII of The Thumb",
    Gloom = "Absolute Gloom",
    Pride = "Absolute Pride",
    Wrath = "Absolute Wrath",
    Desire = "Absolute Desire",
    Sloth = "Absolute Sloth",
    Envy = "Absolute Envy",
    Gluttony = "Absolute Gluttony",
}
local LCORP_IGNORE = { ["Thumb Soldato"] = true, ["Thumb Soldato III"] = true }

local function isLCorpBranch()
    local map = Workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Generator Room") ~= nil
end

local function lcorpGenerator()
    local map = Workspace:FindFirstChild("Map")
    local room = map and map:FindFirstChild("Generator Room")
    local generator = room and room:FindFirstChild("Generator")
    if not generator then return nil end
    if generator:IsA("BasePart") then return generator end
    return generator:FindFirstChildWhichIsA("BasePart", true)
end

local function touchLCorpGenerator()
    local generator = lcorpGenerator()
    local _, _, myRoot = characterParts()
    if not generator or not myRoot then return false end
    myRoot.CFrame = generator.CFrame * CFrame.new(0, 0, 3)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.35)
    return true
end

local function enterLCorp(runtime)
    if game.PlaceId ~= MAIN_PLACE_ID then return false end
    local npcs = Workspace:FindFirstChild("NPCS")
    if not npcs then return false end

    local function questActive()
        local c = LP.Character
        return c and c:FindFirstChild("QuestInProgress") ~= nil
    end

    if not questActive() then
        local contractor = npcs:FindFirstChild("Hana Association Contractor")
        if not contractor then return false end
        local accepted = false
        for _ = 1, 5 do
            if not featureAlive(runtime) or not LCorpConfig.Enabled then return false end
            moveToModel(contractor, CFrame.new(0, 0, 2.5))
            task.wait(0.5)
            local prompt = findPrompt(contractor)
            if prompt then triggerPrompt(prompt, 1) else pressInteraction(Enum.KeyCode.E) end
            if not waitForDialogue(1.5) then talkToNpc(contractor, 1.2) end
            if dialogueIsOpen() and DialogueUtil.selectOptionStable("Show me the available jobs", 5, runtime) then
                task.wait(0.5)
                DialogueUtil.selectOptionStable("L Corp Branch", 6, runtime)
                task.wait(1.5)
                if questActive() then accepted = true; break end
            end
            task.wait(0.8)
        end
        if not accepted and not questActive() then return false end
    end

    local entrance = npcs:FindFirstChild("Entrance")
    local shutter = entrance and entrance:FindFirstChild("Shutter Door")
    if not shutter then return false end

    local gateOpened = false
    for _ = 1, 3 do
        if not featureAlive(runtime) or not LCorpConfig.Enabled then return false end
        moveToModel(shutter, CFrame.new(0, 0, 2.5))
        task.wait(0.6)
        pressInteraction(Enum.KeyCode.E)
        if not waitForDialogue(1.2) then triggerPrompt(shutter, 1) end
        if dialogueIsOpen() and DialogueUtil.selectFirstMatchingOption({"Open the Gate.", "Open the Gate"}, 5, runtime) then
            gateOpened = true
            break
        end
        task.wait(0.8)
    end
    if not gateOpened then return false end

    task.wait(1.5)
    local tpBrick = entrance and entrance:FindFirstChild("TPBrick")
    local _, _, myRoot = characterParts()
    if tpBrick and myRoot then
        myRoot.CFrame = tpBrick.CFrame * CFrame.new(0, 3, 0)
        myRoot.AssemblyLinearVelocity = Vector3.zero
        notify("Auto L Corp", "Entry started. Re-run Archivist after the teleport if needed.")
        return true
    end
    return false
end

local function fragmentChoice(runtime, fragment, text, timeout)
    timeout = timeout or 5
    local deadline = tick() + timeout
    repeat
        if not featureAlive(runtime) or not fragment or not fragment.Parent then return false end
        moveToModel(fragment, CFrame.new(0, 0, 3))
        local _, humanoid, myRoot = characterParts()
        if myRoot then
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end
        if humanoid then pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) end) end
        local prompt = findPrompt(fragment)
        if prompt then triggerPrompt(prompt, 1) else pressInteraction(Enum.KeyCode.E) end
        if waitForDialogue(0.8) and DialogueUtil.selectOptionStable(text, 4, runtime) then return true end
        task.wait(0.25)
    until tick() >= deadline
    return false
end

local function spawnSelectedLCorpBoss(runtime)
    local npcs = Workspace:FindFirstChild("NPCS")
    if not npcs then return false end
    local expected = LCORP_BOSSES[LCorpConfig.Boss]
    local al = alive()
    if al and expected and al:FindFirstChild(expected) then return true end

    if LCorpConfig.Boss == "Lei Heng" then
        local entrance = npcs:FindFirstChild("Ordeal Entrance")
        if not entrance then
            local fragment = npcs:FindFirstChild("Fragmented Self")
            if not fragment then return false end
            if not fragmentChoice(runtime, fragment, "Worlds", 5) then return false end
            if not fragmentChoice(runtime, fragment, "Thumb", 5) then return false end

            local deadline = tick() + 8
            repeat
                if not featureAlive(runtime) then return false end
                entrance = npcs:FindFirstChild("Ordeal Entrance")
                if entrance then break end
                task.wait(0.2)
            until tick() >= deadline
            if not entrance then return false end
        end

        local deadline = tick() + 5
        repeat
            if not featureAlive(runtime) then return false end
            moveToModel(entrance, CFrame.new(0, 0, 3))
            local prompt = findPrompt(entrance)
            if prompt then triggerPrompt(prompt, 1) else pressInteraction(Enum.KeyCode.E) end
            if not waitForDialogue(0.7) then talkToNpc(entrance, 0.8) end
            if dialogueIsOpen() and DialogueUtil.selectOptionStable("Face", 4, runtime) then return true end
            task.wait(0.15)
        until tick() >= deadline
        return false
    end

    local fragment = npcs:FindFirstChild("Fragmented Self")
    if not fragment then return false end
    if not fragmentChoice(runtime, fragment, "Sin", 5) then return false end
    return fragmentChoice(runtime, fragment, LCorpConfig.Boss, 5)
end

local function lcorpFightTarget(runtime, target)
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

    local dist = LCorpConfig.AttachDistance or 3
    local height = LCorpConfig.AttachHeight or -5.5
    local tp = targetRoot.Position + (-targetRoot.CFrame.LookVector) * dist + Vector3.new(0, height, 0)
    myRoot.CFrame = CFrame.lookAt(tp, targetRoot.Position)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    pcall(function() humanoid.AutoRotate = false end)
    attackPulse(target, 35)
    return true
end

local function runLCorpBranch(runtime)
    enableRuntimeNoclip(runtime, function() return LCorpConfig.Enabled end)
    addFeatureCleanup(runtime, function()
        local character = LP.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function() humanoid.AutoRotate = true end)
            pcall(function() Camera.CameraSubject = humanoid end)
        end
    end)
    local lastGenerator = 0
    while featureAlive(runtime) and LCorpConfig.Enabled and isLCorpBranch() do
        local expectedBoss = LCORP_BOSSES[LCorpConfig.Boss]
        local priority = expectedBoss and {[expectedBoss] = true} or nil
        local target = bestNonPlayerTarget(LCORP_IGNORE, priority)
        if target then
            if target.Name == expectedBoss then LCorpConfig.KilledBoss = true end
            lcorpFightTarget(runtime, target)
        else
            if LCorpConfig.AutoLoot then lootNearbyDrops(runtime, 650) end
            if LCorpConfig.GeneratorAssist and tick() - lastGenerator > 3 then
                touchLCorpGenerator()
                lastGenerator = tick()
            end
            spawnSelectedLCorpBoss(runtime)
            task.wait(0.35)
        end
        task.wait(0.08)
    end
end

local function startLCorp()
    LCorpConfig.Enabled = true
    if game.PlaceId == MAIN_PLACE_ID then
        startFeature("AutoLCorp", function(runtime)
            if not enterLCorp(runtime) then notify("Auto L Corp", "Could not start the L Corp branch entry path.") end
        end)
        return true
    end
    if not isLCorpBranch() then
        LCorpConfig.Enabled = false
        notify("Auto L Corp", "Run this in the main city or inside an L Corp branch.")
        return false
    end
    startFeature("AutoLCorp", runLCorpBranch)
    return true
end

local function stopLCorp()
    LCorpConfig.Enabled = false
    stopFeature("AutoLCorp")
end

local function lcorpExtract()
    stopLCorp()
    local npcs = Workspace:FindFirstChild("NPCS")
    local elevator = npcs and npcs:FindFirstChild("Elevator Door")
    if not elevator then
        notify("L Corp Extract", "Elevator Door is not available yet.")
        return
    end
    moveToModel(elevator, CFrame.new(0, 0, 3))
    talkToNpc(elevator)
    if waitForDialogue(3) then DialogueUtil.selectOptionStable("Extract", 6) end
end

local function lcorpLootAll()
    stopLCorp()
    startFeature("LCorpLoot", function(runtime)
        local npcs = Workspace:FindFirstChild("NPCS")
        if not npcs then return end
        local wanted = {
            EnkephalinBarrels = true,
            ["Extracted Weapon Crate"] = true,
            Locker = true,
            ["Military Crate"] = true,
            ["Supply Depot"] = true,
            Rack = true,
        }
        for _, object in ipairs(npcs:GetChildren()) do
            if not featureAlive(runtime) then return end
            if wanted[object.Name] then
                moveToModel(object, CFrame.new(0, 0, 2))
                for _ = 1, 6 do
                    if not featureAlive(runtime) then return end
                    talkToNpc(object)
                    if waitForDialogue(1) and not DialogueUtil.selectOptionStable("Search", 4, runtime) then break end
                    task.wait(0.25)
                end
                DialogueUtil.selectOptionStable("Leave", 4, runtime)
                task.wait(0.2)
            end
        end
    end)
end

AdvancedAutomationTab:CreateSection("L Corp")
AdvancedAutomationTab:CreateToggle({
    Name = "Auto L Corp", CurrentValue = false, Flag = "AutoLCorp",
    Callback = function(state)
        if state then
            if not startLCorp() then LCorpConfig.Enabled = false end
        else
            stopLCorp()
        end
    end,
})
AdvancedAutomationTab:CreateDropdown({
    Name = "L Corp Target", Options = {"Lei Heng", "Gloom", "Pride", "Wrath", "Desire", "Sloth", "Envy", "Gluttony"},
    CurrentOption = {"Lei Heng"}, MultipleOptions = false, Flag = "LCorpBoss",
    Callback = function(value) LCorpConfig.Boss = valueFromOption(value) or "Lei Heng" end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Auto Loot Drops", CurrentValue = true, Flag = "LCorpAutoLoot",
    Callback = function(state) LCorpConfig.AutoLoot = state end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Generator Assist", CurrentValue = true, Flag = "LCorpGeneratorAssist",
    Callback = function(state) LCorpConfig.GeneratorAssist = state end,
})
AdvancedAutomationTab:CreateSlider({
    Name = "L Corp Attach Distance", Range = {-20, 20}, Increment = 0.5, CurrentValue = 3, Flag = "LCorpAttachDistance",
    Callback = function(value) LCorpConfig.AttachDistance = value end,
})
AdvancedAutomationTab:CreateSlider({
    Name = "L Corp Attach Height", Range = {-20, 20}, Increment = 0.5, CurrentValue = -5.5, Flag = "LCorpAttachHeight",
    Callback = function(value) LCorpConfig.AttachHeight = value end,
})
AdvancedAutomationTab:CreateLabel("L Corp combat uses the same behind-target distance/height positioning model as Railway.")
AdvancedAutomationTab:CreateButton({Name = "Extract from L Corp", Callback = lcorpExtract})
AdvancedAutomationTab:CreateButton({Name = "Loot L Corp Containers", Callback = lcorpLootAll})

