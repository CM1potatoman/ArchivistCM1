-- ------------------------------
-- AUTO WARP TRAIN
-- ------------------------------
local WarpConfig = {
    Enabled = false,
    YOffset = 10,
    AutoProgress = true,
}
local WARP_PLACE_ID = 99831550635699
local MAIN_PLACE_ID = 14038329225

local function isWarpTrainInstance()
    if game.PlaceId ~= WARP_PLACE_ID then return false end
    local map = Workspace:FindFirstChild("Map")
    local inner = map and map:FindFirstChild("Map")
    return inner and (inner:FindFirstChild("Carriage_2") or inner:FindFirstChild("Carriage_6")) ~= nil
end

local function pressInteraction(keyCode)
    VIM:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.08)
    VIM:SendKeyEvent(false, keyCode, false, game)
end

local function warpCarriageButton(index)
    local map = Workspace:FindFirstChild("Map")
    local inner = map and map:FindFirstChild("Map")
    local carriage = inner and inner:FindFirstChild("Carriage_" .. tostring(index))
    local doors = carriage and carriage:FindFirstChild("Doors")
    local doorButton = doors and doors:FindFirstChild("DoorButton")
    return doorButton and (doorButton:FindFirstChild("DoorButtonPress") or doorButton:FindFirstChildWhichIsA("BasePart", true)) or nil
end

local function advanceWarpCarriage(runtime, index)
    if not featureAlive(runtime) then return false end
    local button = warpCarriageButton(index)
    if not button then return false end
    local _, _, myRoot = characterParts()
    if not myRoot then return false end
    myRoot.CFrame = button.CFrame * CFrame.new(0, 0, 3)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.25)
    local prompt = findPrompt(button.Parent)
    if prompt then
        triggerPrompt(prompt)
    else
        pressInteraction(Enum.KeyCode.F)
    end
    task.wait(0.8)
    return true
end

local function talkToDumpster(runtime, destination)
    local npcs = Workspace:FindFirstChild("NPCS")
    local dumpster = npcs and (npcs:FindFirstChild("Dumpster Guy") or npcs:FindFirstChild("Ragpicker"))
    local dgRoot = dumpster and root(dumpster)
    if not dumpster or not dgRoot then return false end

    enableRuntimeNoclip(runtime, function() return WarpConfig.Enabled end)
    local _, _, myRoot = characterParts()
    if not myRoot then return false end

    -- Use the known stable approach: stand seven studs to the side and aim the camera.
    -- at Dumpster Guy, temporarily force a fixed 10-stud zoom, then press E.
    local lookAt = dgRoot.Position
    myRoot.CFrame = CFrame.lookAt(dgRoot.Position + Vector3.new(7, 0, 0), lookAt)
    myRoot.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)

    local oldMin, oldMax = LP.CameraMinZoomDistance, LP.CameraMaxZoomDistance
    local oldCamera = Camera.CFrame
    pcall(function() Camera.CFrame = CFrame.lookAt(dgRoot.Position + Vector3.new(7, 3, 0), lookAt) end)
    pcall(function() LP.CameraMaxZoomDistance = 10; LP.CameraMinZoomDistance = 10 end)
    task.wait(0.5)
    pressInteraction(Enum.KeyCode.E)
    pcall(function() LP.CameraMinZoomDistance = oldMin; LP.CameraMaxZoomDistance = oldMax end)
    task.wait(3)

    if not dialogueIsOpen() then
        -- Fall back to the remote/prompt path only if the normal interaction did not open dialogue.
        moveToModel(dumpster, CFrame.new(0, 0, 3))
        talkToNpc(dumpster, 2)
    end
    if not dialogueIsOpen() then
        pcall(function() Camera.CFrame = oldCamera end)
        return false
    end

    if not DialogueUtil.selectFirstMatchingOption({"Hand him some Ahn. (2.5M", "Hand him some Ahn"}, 5, runtime) then
        pcall(function() Camera.CFrame = oldCamera end)
        return false
    end
    task.wait(0.5)

    -- Keep selecting the destination while the dialogue remains open;
    -- it does not assume one click means the server accepted the transition.
    local deadline = tick() + 60
    repeat
        if not featureAlive(runtime) or not WarpConfig.Enabled then return false end
        if isWarpTrainInstance() then return true end
        if dialogueIsOpen() then
            DialogueUtil.selectFirstMatchingOption({destination, destination == "WARPTrain" and "WARP Train" or destination}, 2, runtime)
        else
            moveToModel(dumpster, CFrame.new(0, 0, 3))
            talkToNpc(dumpster, 1.5)
        end
        task.wait(1.1)
    until tick() >= deadline

    pcall(function() Camera.CFrame = oldCamera end)
    return isWarpTrainInstance()
end

local function runWarpInstance(runtime)
    local carriage = 2
    local carriageMisses = 0
    local lastEnemyAt = tick()
    local princeAttempted = false

    while featureAlive(runtime) and WarpConfig.Enabled and isWarpTrainInstance() do
        local target = bestNonPlayerTarget()
        if target then
            lastEnemyAt = tick()
            fightTarget(runtime, target, WarpConfig.YOffset)
            carriageMisses = 0
        elseif tick() - lastEnemyAt > 0.65 then
            if WarpConfig.AutoProgress and carriage <= 6 then
                if advanceWarpCarriage(runtime, carriage) then
                    carriage += 1
                    carriageMisses = 0
                    lastEnemyAt = tick()
                else
                    carriageMisses += 1
                    if carriageMisses >= 4 then
                        carriage += 1
                        carriageMisses = 0
                    end
                end
            else
                local npcs = Workspace:FindFirstChild("NPCS")
                local princeFolder = npcs and npcs:FindFirstChild("PrinceFight")
                local prince = princeFolder and princeFolder:FindFirstChild("The Prince of the Parade")
                if prince and not princeAttempted then
                    princeAttempted = true
                    moveToModel(prince, CFrame.new(0, 0, 3))
                    talkToNpc(prince)
                    if waitForDialogue(2) then
                        DialogueUtil.selectOptionStable("I'm here to end", 5, runtime)
                        DialogueUtil.selectOptionStable("...", 5, runtime)
                        DialogueUtil.selectOptionStable("What", 5, runtime)
                    end
                    lastEnemyAt = tick()
                end
            end
        end
        task.wait(0.08)
    end
end

local function startWarp()
    WarpConfig.Enabled = true
    if game.PlaceId == MAIN_PLACE_ID then
        startFeature("AutoWarp", function(runtime)
            notify("Auto Warp", "Starting Warp Train entry...")
            if not talkToDumpster(runtime, "WARPTrain") then
                notify("Auto Warp", "Could not start the Warp Train dialogue path.")
            end
        end)
        return true
    end
    if not isWarpTrainInstance() then
        WarpConfig.Enabled = false
        notify("Auto Warp", "Run this in the main city or inside a Warp Train instance.")
        return false
    end
    startFeature("AutoWarp", runWarpInstance)
    return true
end

local function stopWarp()
    WarpConfig.Enabled = false
    stopFeature("AutoWarp")
    if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
        Camera.CameraSubject = LP.Character:FindFirstChildOfClass("Humanoid")
    end
end

AdvancedAutomationTab:CreateSection("Warp Train")
AdvancedAutomationTab:CreateToggle({
    Name = "Auto Warp Train", CurrentValue = false, Flag = "AutoWarpTrain",
    Callback = function(state)
        if state then
            if not startWarp() then WarpConfig.Enabled = false end
        else
            stopWarp()
        end
    end,
})
AdvancedAutomationTab:CreateToggle({
    Name = "Auto Progress Carriages", CurrentValue = true, Flag = "WarpAutoProgress",
    Callback = function(state) WarpConfig.AutoProgress = state end,
})
AdvancedAutomationTab:CreateSlider({
    Name = "Warp Y Offset", Range = {0, 30}, Increment = 1, CurrentValue = 10, Flag = "WarpYOffset",
    Callback = function(value) WarpConfig.YOffset = value end,
})

