-- ============================================================
-- ADVANCED AUTOMATION
-- Reimplemented around Archivist helpers. No anti-cheat hooks,
-- obfuscation, executor virtualization wrappers, or detection bypasses.
-- ============================================================
local AdvancedAutomationTab = Window:CreateTab("Automation", 10726204364)
AdvancedAutomationTab:CreateLabel("Library, Warp Train, L Corp and Auto Sell")
local AutoSellTab = AdvancedAutomationTab -- merged into Automation

local FeatureRuntime = {}
-- Expensive feature work is cached/reused where possible.
-- Render/Heartbeat paths should move existing state, not rebuild it.

local function stopFeature(name)
    local runtime = FeatureRuntime[name]
    if not runtime then return end
    runtime.active = false
    for _, connection in ipairs(runtime.connections) do
        pcall(function() connection:Disconnect() end)
    end
    for _, track in ipairs(runtime.tracks) do
        pcall(function() track:Stop() end)
        pcall(function() track:Destroy() end)
    end
    for i = #runtime.cleanups, 1, -1 do
        pcall(runtime.cleanups[i])
    end
    FeatureRuntime[name] = nil
end

local function startFeature(name, callback)
    stopFeature(name)
    local runtime = {active = true, connections = {}, tracks = {}, cleanups = {}}
    FeatureRuntime[name] = runtime
    task.spawn(function()
        local ok, err = pcall(callback, runtime)
        if not ok then
            warn("[Archivist:" .. name .. "] " .. tostring(err))
        end
        if FeatureRuntime[name] == runtime then
            stopFeature(name)
        end
    end)
    return runtime
end

local function featureAlive(runtime)
    return runtime ~= nil and runtime.active == true
end

local function addFeatureCleanup(runtime, callback)
    if runtime and callback then table.insert(runtime.cleanups, callback) end
end

local function enableRuntimeNoclip(runtime, enabledFn)
    if not runtime or runtime._noclipEnabled then return end
    runtime._noclipEnabled = true
    local originals = setmetatable({}, {__mode = "k"})
    local watchedCharacter = nil
    local descendantConn = nil
    local function restore()
        for part, canCollide in pairs(originals) do
            if part and part.Parent then pcall(function() part.CanCollide = canCollide end) end
        end
        table.clear(originals)
    end
    local function stopWatching()
        if descendantConn then descendantConn:Disconnect(); descendantConn = nil end
        watchedCharacter = nil
        restore()
    end
    local function watchPart(part)
        if not part:IsA("BasePart") then return end
        if originals[part] == nil then originals[part] = part.CanCollide end
        if part.CanCollide then part.CanCollide = false end
    end
    local function watchCharacter(character)
        if watchedCharacter == character then return end
        stopWatching()
        watchedCharacter = character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do watchPart(part) end
        descendantConn = character.DescendantAdded:Connect(watchPart)
    end
    local conn = RS.Stepped:Connect(function()
        if not featureAlive(runtime) then return end
        if enabledFn and not enabledFn() then
            if watchedCharacter then stopWatching() end
            return
        end
        local character = LP.Character
        if watchedCharacter ~= character then watchCharacter(character) end
        if not character then return end
        for part in pairs(originals) do
            if part.Parent and part:IsDescendantOf(character) and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
    table.insert(runtime.connections, conn)
    addFeatureCleanup(runtime, function()
        stopWatching()
        runtime._noclipEnabled = nil
    end)
end

local function notify(title, content)
    pcall(function()
        Lib:Notify({
            Title = title or "Archivist",
            Content = content or "",
            Duration = 6,
        })
    end)
end

local function characterParts()
    local character = LP.Character
    if not character then return nil, nil, nil end
    return character, character:FindFirstChildOfClass("Humanoid"), root(character)
end

local function modelPivot(model)
    if not model then return nil end
    local ok, pivot = pcall(function() return model:GetPivot() end)
    return ok and pivot or nil
end

local function moveToModel(model, offset)
    local _, _, myRoot = characterParts()
    local pivot = modelPivot(model)
    if not myRoot or not pivot then return false end
    myRoot.CFrame = pivot * (offset or CFrame.new(0, 0, 3))
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    return true
end

local function findPrompt(instance)
    if not instance then return nil end
    if instance:IsA("ProximityPrompt") then return instance end
    return instance:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function triggerPrompt(instance, attempts)
    local prompt = findPrompt(instance)
    if not prompt then return false end
    attempts = attempts or 2
    local fired = false
    for _ = 1, attempts do
        if not prompt.Parent then break end
        local ok = pcall(function() fireproximityprompt(prompt) end)
        fired = fired or ok
        task.wait(0.12)
    end
    return fired
end

local function talkToNpc(npc, timeout)
    if not npc then return false end
    timeout = timeout or 2.5
    local deadline = tick() + timeout
    repeat
        if dialogueIsOpen() then return true end

        local talk = npc:FindFirstChild("TalkToNPC")
        if talk and talk:IsA("RemoteEvent") then
            pcall(function() talk:FireServer() end)
        end

        local prompt = findPrompt(npc)
        if prompt then
            pcall(function() fireproximityprompt(prompt) end)
        else
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)
        end
        task.wait(0.22)
    until tick() >= deadline
    return dialogueIsOpen()
end

local DialogueUtil = {}

function DialogueUtil.visibleButtons()
    local dialogue = LP.PlayerGui:FindFirstChild("Dialogue")
    if not dialogue then return {} end
    local buttons = {}
    for _, obj in ipairs(dialogue:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Name == "OptionButton" and obj.Visible then
            table.insert(buttons, obj)
        end
    end
    table.sort(buttons, function(a, b)
        return a.AbsolutePosition.Y < b.AbsolutePosition.Y
    end)
    return buttons
end

function DialogueUtil.buttonText(button)
    if not button then return "" end
    local parent = button.Parent
    local optionText = parent and parent:FindFirstChild("OptionText")
    if optionText then
        if optionText:IsA("TextLabel") or optionText:IsA("TextButton") then
            return optionText.Text or ""
        elseif optionText:IsA("StringValue") then
            return optionText.Value or ""
        end
    end
    local label = button:FindFirstChildOfClass("TextLabel")
    if label then return label.Text or "" end
    return button.Text or ""
end

function DialogueUtil.selectOptionStable(text, attempts, runtime)
    attempts = attempts or 8
    local needle = string.lower(tostring(text or ""))
    for _ = 1, attempts do
        if runtime and not featureAlive(runtime) then return false end
        local buttons = DialogueUtil.visibleButtons()
        for _, button in ipairs(buttons) do
            local candidate = string.lower(DialogueUtil.buttonText(button))
            if candidate == needle or string.find(candidate, needle, 1, true) then
                if clickButton(button) then
                    task.wait(0.12)
                    return true
                end
            end
        end
        task.wait(0.12)
    end
    return false
end

function DialogueUtil.selectFirstMatchingOption(options, attempts, runtime)
    for _, text in ipairs(options) do
        if DialogueUtil.selectOptionStable(text, attempts or 3, runtime) then return true end
    end
    return false
end

local function bestNonPlayerTarget(ignoreNames, priorityNames)
    local folder = alive()
    local _, _, myRoot = characterParts()
    if not folder or not myRoot then return nil end

    local best, bestPriority, bestMaxHealth, bestDistance = nil, -1, -1, math.huge
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") and model ~= LP.Character and not isPlr(model)
            and not (ignoreNames and ignoreNames[model.Name]) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local targetRoot = root(model)
            if hum and targetRoot and hum.Health > 0 then
                local priority = priorityNames and priorityNames[model.Name] and 1 or 0
                local maxHealth = hum.MaxHealth or 0
                local distance = (myRoot.Position - targetRoot.Position).Magnitude
                if priority > bestPriority
                    or (priority == bestPriority and maxHealth > bestMaxHealth)
                    or (priority == bestPriority and maxHealth == bestMaxHealth and distance < bestDistance) then
                    best = model
                    bestPriority = priority
                    bestMaxHealth = maxHealth
                    bestDistance = distance
                end
            end
        end
    end
    return best
end

local AttackTrackCache = setmetatable({}, {__mode = "k"})

local function cachedAttackTrack(animator, animation)
    if not animator or not animation then return nil end
    local animatorCache = AttackTrackCache[animator]
    if not animatorCache then
        animatorCache = {}
        AttackTrackCache[animator] = animatorCache
    end
    local key = animation.AnimationId ~= "" and animation.AnimationId or animation
    local track = animatorCache[key]
    if track then return track end
    local ok, loaded = pcall(function() return animator:LoadAnimation(animation) end)
    if ok and loaded then
        animatorCache[key] = loaded
        return loaded
    end
    return nil
end

local function clearAttackTrackCache()
    for _, animatorCache in pairs(AttackTrackCache) do
        for _, track in pairs(animatorCache) do
            pcall(function() track:Stop(0) end)
            pcall(function() track:Destroy() end)
        end
    end
    AttackTrackCache = setmetatable({}, {__mode = "k"})
end

local lastAttackPulse = 0
local function attackPulse(target, speed)
    local character, humanoid = characterParts()
    if not character or not humanoid or not target then return false end
    local now = tick()
    if now - lastAttackPulse < 0.08 then return false end
    lastAttackPulse = now

    local weaponValue = character:FindFirstChild("Weapon") or LP:FindFirstChild("Data") and LP.Data:FindFirstChild("Weapon")
    local weaponName = weaponValue and weaponValue.Value
    local weaponInfo = weaponName and RepStore:FindFirstChild("WeaponINFO") and RepStore.WeaponINFO:FindFirstChild(weaponName)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not weaponInfo or not animator then return false end

    local animation = weaponInfo:FindFirstChild("AttackAnimation1")
    if not animation then
        for _, child in ipairs(weaponInfo:GetChildren()) do
            if child:IsA("Animation") and child.Name:find("AttackAnimation", 1, true) then
                animation = child
                break
            end
        end
    end
    if not animation then return false end

    local track = cachedAttackTrack(animator, animation)
    if not track then return false end
    pcall(function() track:Stop(0) end)
    track:Play(0.02, 1, 1)
    local hitboxDelay = weaponInfo:FindFirstChild("TimeUntilHitbox")
    if hitboxDelay and hitboxDelay.Value > 0 then
        pcall(function() track.TimePosition = math.max(0, hitboxDelay.Value - 0.02) end)
    end
    track:AdjustSpeed(speed or 35)
    return true
end

local function fightTarget(runtime, target, yOffset)
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

    local offset = Vector3.new(0, -(yOffset or 5), 0)
    myRoot.CFrame = targetRoot.CFrame * CFrame.Angles(math.rad(90), 0, 0) + offset
    myRoot.AssemblyLinearVelocity = Vector3.zero
    myRoot.AssemblyAngularVelocity = Vector3.zero
    attackPulse(target, 35)
    return true
end

local function valueFromOption(value)
    if type(value) == "table" then return value[1] or next(value) end
    return value
end

