-- ============================================================
-- PARRY SYSTEM
-- ============================================================
local parryRemote = nil
local perilousRemote = nil
pcall(function()
    local events = RepStore:FindFirstChild("Events")
    -- Prefer the older Archivist ParryActivate action path; the newer
    -- animation/timing layer only decides when that action should fire.
    parryRemote = events and events:FindFirstChild("ParryActivate")
    perilousRemote = events and events:FindFirstChild("PerilousAttack")
end)

local PARRY_GLOBAL_COOLDOWN = 0.08
local PARRY_TARGET_COOLDOWN = 0.5
local ATK_SIGS = {"StartedAnAttack", "LightAttack", "UsingMove"}
local parryCons = {}
local parryInds = {}
local parryLastFired = 0
local parryTargetLast = setmetatable({}, {__mode = "k"})
local parryQueueStamp = setmetatable({}, {__mode = "k"})
local lastNpcAnimation = setmetatable({}, {__mode = "k"})
local parryProfiler = {}
local parryProfilerOrder = {}
local weaponAnimationTimings = {}

local ATTACK_ANIMATION_NAMES = {
    AttackAnimation1=true, AttackAnimation2=true, AttackAnimation3=true, AttackAnimation4=true,
    Attack=true, RunAttack=true, ChargedAttackAnimation=true,
    Swing=true, Swing1=true, Swing2=true, Swing3=true,
    Punch=true, Slam=true, Lunge=true, Cleave=true, Pound=true, Headbutt=true,
    KickAway=true, Barrage=true, Flail=true, Flurry=true, Rampage=true, Onrush=true,
    GrabAttempt=true, BoneJavelin=true, OilThrow=true, Shoot=true, ShootAlt=true,
    GunShoot=true, DiveKickAnimation=true, Counter=true, FollowUpAnim=true,
}

local IGNORE_ANIMATION_NAMES = {
    Idle=true, IdleAnimation=true, MovingIdle=true, ItemIdleAnimation=true,
    Walk=true, WalkAnim=true, WalkAnimation=true, WeaponWalkAnimation=true,
    Run=true, RunAnim=true, RunAnimation=true, DefaultRunAnimation=true,
    JumpAnim=true, FallAnim=true, ClimbAnim=true, LightParry=true, HardParry=true,
    ParryAttempt=true, ParryAnimation=true, GotParried=true, ParriedAttack=true,
    KnockedBack=true, StaggeredAnimation=true, SpawnAnim=true, Resting=true,
    SitAnim=true, Grabbed=true, BeingGripped=true, BeingCarried=true,
    BlockAnimation=true, EquipAnimation=true, UnequipAnimation=true,
}

-- Known attacks whose visible animation timing differs from ordinary weapon hit timing.
local SPECIAL_PARRY_TIMINGS = {
    ["16390219304"] = 0.60,
    ["16390215619"] = 0.44,
    ["16390221563"] = 0.70,
    ["16390165394"] = 0.92,
    ["16390226552"] = 1.12,
    ["16390229867"] = 0.40,
    ["16428863879"] = 0.00,
    ["16390173071"] = 0.87,
    ["16390234461"] = 1.30,
    ["16390142642"] = 0.30,
    ["16390162562"] = 0.30,
}

local MULTI_HIT_WINDOWS = {
    ["106835137675309"] = {0.19, 0.55, 1.00},
    ["79887420839095"] = {0.10, 0.25, 0.40, 0.55, 0.70, 0.85},
    ["16390215619"] = {0.50, 1.00},
    ["16390219304"] = {0.70},
    ["16428863879"] = {0.025, 1.00, 1.975, 2.95, 3.925, 4.90, 5.875, 6.85, 7.825, 8.80},
}

local IND_COLORS = {M1 = Color3.fromRGB(255, 80, 80), Skill = Color3.fromRGB(255, 165, 0)}

local function animationId(value)
    if not value then return nil end
    return tostring(value):match("%d+")
end

local function looksLikeAttack(name)
    if not name or name == "" then return false end
    if IGNORE_ANIMATION_NAMES[name] then return false end
    if ATTACK_ANIMATION_NAMES[name] then return true end
    local lower = string.lower(name)
    local words = {"attack", "swing", "slash", "strike", "punch", "slam", "lunge", "shoot", "throw", "charge", "rush", "combo", "spin", "cleave", "barrage"}
    for _, word in ipairs(words) do
        if string.find(lower, word, 1, true) then return true end
    end
    return false
end

local function rebuildParryTimingCache()
    table.clear(weaponAnimationTimings)
    local weaponInfo = RepStore:FindFirstChild("WeaponINFO")
    if not weaponInfo then return end
    for _, weapon in ipairs(weaponInfo:GetChildren()) do
        local tuh = weapon:FindFirstChild("TimeUntilHitbox")
        local hitTime = tuh and tonumber(tuh.Value) or nil
        if hitTime then
            for _, entry in ipairs(weapon:GetChildren()) do
                if looksLikeAttack(entry.Name) then
                    local id
                    if entry:IsA("Animation") then
                        id = animationId(entry.AnimationId)
                    elseif entry:IsA("StringValue") then
                        id = animationId(entry.Value)
                    end
                    if id then
                        weaponAnimationTimings[id] = {
                            hitTime = hitTime,
                            weapon = weapon.Name,
                            name = entry.Name,
                            kind = "M1",
                        }
                    end
                end
            end
        end
    end
end
rebuildParryTimingCache()

local function showParryInd(model, isSkill)
    if not S.ParryIndicatorEnabled then return end
    local head = model:FindFirstChild("Head"); if not head then return end
    local ex = parryInds[model]
    if ex then pcall(function() ex.gui:Destroy() end); parryInds[model] = nil end
    local col = isSkill and IND_COLORS.Skill or IND_COLORS.M1
    local gui = Instance.new("BillboardGui")
    gui.Name = "ParryIndicator"; gui.AlwaysOnTop = true; gui.LightInfluence = 0
    gui.Size = UDim2.new(0, 80, 0, 30); gui.StudsOffset = Vector3.new(0, 2.8, 0); gui.Parent = head
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35; frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.TextColor3 = col; lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextStrokeTransparency = 0.3; lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold; lbl.Text = isSkill and " SKILL" or " PARRY"
    local tw = TweenService:Create(lbl, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.35})
    tw:Play(); parryInds[model] = {gui = gui, tw = tw}
end

local function hideParryInd(model)
    local ind = parryInds[model]; if not ind then return end
    ind.tw:Cancel(); pcall(function() ind.gui:Destroy() end); parryInds[model] = nil
end

local function getPing()
    local ok, ms = pcall(function() return LP:GetNetworkPing() * 1000 end)
    return (ok and ms) or 0
end

local function getTimeUntilHitbox(model)
    local wv = model:FindFirstChild("Weapon")
    if not wv or not wv:IsA("StringValue") or wv.Value == "" then return nil end
    local wi = RepStore:FindFirstChild("WeaponINFO"); if not wi then return nil end
    local winfo = wi:FindFirstChild(wv.Value); if not winfo then return nil end
    local tuh = winfo:FindFirstChild("TimeUntilHitbox")
    return tuh and tonumber(tuh.Value) or nil
end

local function getM1D(model)
    local wv = model:FindFirstChild("Weapon")
    if not wv or not wv:IsA("StringValue") or wv.Value == "" then return nil end
    local wi = RepStore:FindFirstChild("WeaponINFO"); if not wi then return nil end
    local winfo = wi:FindFirstChild(wv.Value); if not winfo then return nil end
    local m1d = winfo:FindFirstChild("M1Delay")
    return m1d and tonumber(m1d.Value) or nil
end

local function inParryRange(model)
    local mc = LP.Character; if not mc then return false end
    local mr = root(mc); local er = root(model)
    if not mr or not er then return false end
    return (mr.Position - er.Position).Magnitude <= S.ParryRange
end

local function triggerParryInput(model)
    if not S.ParryEnabled or not model or not model.Parent then return false end
    if not inParryRange(model) then return false end

    local now = tick()
    if now - parryLastFired < PARRY_GLOBAL_COOLDOWN then return false end
    local targetLast = parryTargetLast[model] or 0
    if now - targetLast < PARRY_TARGET_COOLDOWN then return false end

    -- The older Archivist action path used ParryActivate and was more reliable
    -- in Archived. Keep the newer timing engine, but prefer that proven action.
    local events = RepStore:FindFirstChild("Events")
    local parryRemote = events and events:FindFirstChild("ParryActivate")
    local ok = false
    if parryRemote and parryRemote:IsA("RemoteEvent") then
        ok = pcall(function() parryRemote:FireServer() end)
    end
    if not ok then
        ok = pcall(function()
            VIM:SendMouseButtonEvent(0, 0, 1, true, game, 1)
            task.wait(0.05)
            VIM:SendMouseButtonEvent(0, 0, 1, false, game, 1)
        end)
    end

    if ok then
        parryLastFired = tick()
        parryTargetLast[model] = parryLastFired
    end
    return ok
end

local function captureParryTiming(model, track, id, hitTime)
    if not S.ParryProfilerEnabled or not id then return end
    local animation = track and track.Animation
    local key = tostring(model.Name) .. "|" .. id
    local entry = {
        npc = model.Name,
        id = id,
        name = animation and animation.Name or "Animation",
        hitTime = hitTime,
        seenAt = os.date("%H:%M:%S"),
    }
    if not parryProfiler[key] then table.insert(parryProfilerOrder, 1, key) end
    parryProfiler[key] = entry
    while #parryProfilerOrder > 60 do
        parryProfiler[table.remove(parryProfilerOrder)] = nil
    end
end

local function adjustedParryDelay(hitTime)
    local delay = math.max(0, (tonumber(hitTime) or 0) - S.ParryEarlyBuffer)
    if S.AdjustToPing then delay = math.max(0, delay - getPing() / 1000) end
    if S.PanicChance > 0 and math.random(1, 100) <= S.PanicChance then
        delay = math.max(0, delay - math.random(40, 120) / 1000)
    end
    return delay
end

local function queueParry(model, hitTime, isSkill, queueKey)
    if not S.ParryEnabled then return end
    if isSelf(model) or not inParryRange(model) then return end
    if isPlr(model) and not S.ParryTargetPlayers then return end
    if S.MissChance > 0 and math.random(1, 100) <= S.MissChance then return end
    queueKey = queueKey or "generic"
    local now = tick()
    local stamp = parryQueueStamp[model]
    if stamp and stamp.key == queueKey and now - stamp.time < 0.12 then return end
    parryQueueStamp[model] = {key = queueKey, time = now}
    task.spawn(showParryInd, model, isSkill)
    local delay = adjustedParryDelay(hitTime)
    task.delay(delay, function()
        if S.ParryEnabled and model.Parent and inParryRange(model) then triggerParryInput(model) end
    end)
end

local function queueMultiHit(model, offsets, isSkill, queueKey)
    if not offsets then return false end
    for index, offset in ipairs(offsets) do
        task.delay(math.max(0, offset - S.ParryEarlyBuffer), function()
            if S.ParryEnabled and model.Parent and inParryRange(model) then
                -- Multi-hit sequences intentionally use a shorter per-hit target gate.
                parryTargetLast[model] = 0
                triggerParryInput(model)
            end
        end)
    end
    task.spawn(showParryInd, model, isSkill)
    parryQueueStamp[model] = {key = queueKey or "multi", time = tick()}
    return true
end

local function animationTimingFor(model, track)
    local animation = track and track.Animation
    local id = animation and animationId(animation.AnimationId) or nil
    if not id then return nil, nil, nil end
    local known = weaponAnimationTimings[id]
    if SPECIAL_PARRY_TIMINGS[id] ~= nil then
        return SPECIAL_PARRY_TIMINGS[id], id, true
    end
    if known then return known.hitTime, id, known.kind ~= "M1" end
    local name = animation and animation.Name or ""
    if looksLikeAttack(name) then
        return getTimeUntilHitbox(model) or getM1D(model) or S.SkillParryDelay, id, true
    end
    return nil, id, nil
end

local function hookParry(model)
    if not model or not model:IsA("Model") or isSelf(model) or parryCons[model] then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local conns = {}

    local function onSignal(sigName, sigObj)
        if not S.ParryEnabled or not inParryRange(model) then return end
        if isPlr(model) and not S.ParryTargetPlayers then return end
        local isM1 = sigName == "StartedAnAttack" or sigName == "LightAttack"
        local isSkill = sigName == "UsingMove"
        if S.ParryDetection == "M1 Only" and not isM1 then return end
        if S.ParryDetection == "Parryable Only" and sigName ~= "StartedAnAttack" then return end
        if model:FindFirstChild("PerfectParry") or model:FindFirstChild("HitParry") then return end

        if S.ParryMode == "Legacy" or not S.ParryAnimationTiming then
            local hitTime = isSkill and S.SkillParryDelay or (getTimeUntilHitbox(model) or getM1D(model) or 0.15)
            queueParry(model, hitTime, isSkill, "signal:" .. sigName)
            return
        end

        -- AnimationPlayed normally supplies the precise timing. Signals remain a fallback.
        local fallback = isSkill and S.SkillParryDelay or getTimeUntilHitbox(model)
        if fallback and fallback > 0 then
            task.delay(0.03, function()
                local stamp = parryQueueStamp[model]
                if not stamp or tick() - stamp.time > 0.08 then
                    queueParry(model, fallback, isSkill, "signal:" .. sigName)
                end
            end)
        end
    end

    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        table.insert(conns, animator.AnimationPlayed:Connect(function(track)
            -- The profiler can run without Auto Parry. That makes it useful for
            -- observing/tuning timings without actually sending a parry input.
            if not S.ParryAnimationTiming and not S.ParryProfilerEnabled then return end
            if not inParryRange(model) then return end
            local hitTime, id, isSkill = animationTimingFor(model, track)
            if id then lastNpcAnimation[model] = id end
            captureParryTiming(model, track, id, hitTime)

            if not S.ParryEnabled or not S.ParryAnimationTiming or not hitTime then return end
            if isPlr(model) and not S.ParryTargetPlayers then return end
            if S.ParryDetection == "M1 Only" and isSkill then return end
            local multi = id and MULTI_HIT_WINDOWS[id]
            if multi then
                queueMultiHit(model, multi, true, "anim:" .. id)
            elseif hitTime > 0 then
                queueParry(model, hitTime, isSkill, "anim:" .. tostring(id))
            end
        end))
    end

    table.insert(conns, model.ChildAdded:Connect(function(child)
        for _, sig in ipairs(ATK_SIGS) do
            if child.Name == sig then onSignal(sig, child); break end
        end
    end))

    for _, sig in ipairs(ATK_SIGS) do
        local ex = model:FindFirstChild(sig)
        if ex and ex:IsA("BoolValue") then
            local last = ex.Value
            if last then task.spawn(onSignal, sig, ex) end
            table.insert(conns, ex:GetPropertyChangedSignal("Value"):Connect(function()
                if ex.Value and not last then last = true; onSignal(sig, ex)
                elseif not ex.Value then last = false; hideParryInd(model) end
            end))
        elseif ex then
            task.spawn(onSignal, sig, ex)
        end
    end

    table.insert(conns, model.AncestryChanged:Connect(function()
        if not model:IsDescendantOf(Workspace) then
            for _, connection in ipairs(conns) do pcall(function() connection:Disconnect() end) end
            parryCons[model] = nil
            parryTargetLast[model] = nil
            parryQueueStamp[model] = nil
            lastNpcAnimation[model] = nil
            hideParryInd(model)
        end
    end))
    parryCons[model] = conns
end

local function setupParry()
    if not parryRemote then
        warn("[Archivist] ParryActivate not found; Auto Parry will fall back to right-click input.")
    end
    local al = alive(); if not al then return end
    for _, model in ipairs(al:GetChildren()) do
        if not isSelf(model) then task.spawn(hookParry, model) end
    end
    al.ChildAdded:Connect(function(model)
        task.wait(0.15)
        if not isSelf(model) then task.spawn(hookParry, model) end
    end)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            if plr.Character then task.spawn(hookParry, plr.Character) end
            plr.CharacterAdded:Connect(function(c) task.wait(0.15); task.spawn(hookParry, c) end)
        end
    end
    Players.PlayerAdded:Connect(function(plr)
        if plr ~= LP then
            plr.CharacterAdded:Connect(function(c) task.wait(0.15); task.spawn(hookParry, c) end)
        end
    end)
end

if perilousRemote and perilousRemote:IsA("RemoteEvent") then
    perilousRemote.OnClientEvent:Connect(function(model)
        if not S.ParryEnabled or S.ParryDetection == "M1 Only" or not model or not model:IsA("Model") or isSelf(model) then return end
        if isPlr(model) and not S.ParryTargetPlayers then return end
        local id = lastNpcAnimation[model]
        local multi = id and MULTI_HIT_WINDOWS[id]
        if multi then
            queueMultiHit(model, multi, true, "perilous:" .. id)
            return
        end
        local hitTime = (id and SPECIAL_PARRY_TIMINGS[id]) or getTimeUntilHitbox(model) or S.SkillParryDelay
        if hitTime and hitTime > 0 then queueParry(model, hitTime, true, "perilous:" .. tostring(id or model.Name)) end
    end)
end

task.defer(setupParry)

task.spawn(function()
    while true do
        if S.ParrySpamEnabled and parryRemote then
            local now = tick()
            if now - parryLastFired >= 0.2 then
                pcall(function() parryRemote:FireServer() end)
                parryLastFired = now
            end
        end
        task.wait(S.ParrySpamEnabled and 0.05 or 0.25)
    end
end)

CombatTab:CreateSection("Parry Profiler")
CombatTab:CreateToggle({
    Name = "Capture Attack Timings", CurrentValue = false, Flag = "ParryProfiler",
    Callback = function(state) S.ParryProfilerEnabled = state end,
})
CombatTab:CreateButton({
    Name = "Rebuild Timing Cache",
    Callback = function()
        rebuildParryTimingCache()
        Lib:Notify({Title="Parry Profiler", Content="Weapon timing cache rebuilt.", Duration=3})
    end,
})
CombatTab:CreateButton({
    Name = "Copy Captured Timings",
    Callback = function()
        local lines = {"-- Archivist 4.4 parry timing capture", "local timings = {"}
        for _, key in ipairs(parryProfilerOrder) do
            local entry = parryProfiler[key]
            if entry then
                table.insert(lines, string.format("    [%q] = {npc=%q, name=%q, hitTime=%s},",
                    entry.id, entry.npc, entry.name, entry.hitTime and string.format("%.4f", entry.hitTime) or "nil"))
            end
        end
        table.insert(lines, "}")
        if setclipboard then
            pcall(function() setclipboard(table.concat(lines, "\n")) end)
            Lib:Notify({Title="Parry Profiler", Content="Copied " .. tostring(#parryProfilerOrder) .. " capture(s).", Duration=3})
        else
            Lib:Notify({Title="Parry Profiler", Content="Clipboard API is unavailable.", Duration=3})
        end
    end,
})
CombatTab:CreateButton({
    Name = "Clear Captures",
    Callback = function()
        table.clear(parryProfiler)
        table.clear(parryProfilerOrder)
        Lib:Notify({Title="Parry Profiler", Content="Captured timings cleared.", Duration=3})
    end,
})

