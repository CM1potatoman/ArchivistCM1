-- ============================================================
-- HEARTBEAT LOOPS
-- ============================================================
local noclipT = 0
local NOCLIP_R = 0.05

RS.Heartbeat:Connect(function(dt)
    if S.AttachEnabled and attachActive and noclipOn then
        noclipT = noclipT + dt
        if noclipT >= NOCLIP_R then
            noclipT = 0
            for _, p in ipairs(charParts) do
                if p and p.Parent and p:IsA("BasePart") then
                    if attachCollisionState[p] == nil then
                        attachCollisionState[p] = p.CanCollide
                    end
                    p.CanCollide = false
                end
            end
        end
    end
    if S.AttachEnabled and attachActive then
        local mc = LP.Character; if not mc then attachActive=false; return end
        local mr = root(mc); if not mr then return end
        if mr.AssemblyLinearVelocity.Magnitude > 50 then mr.AssemblyLinearVelocity = Vector3.zero end
        if not flyOn then attachStartFly() end
        if not noclipOn then attachStartNoclip() end
        local enemy = attachTarget
        if enemy then
            local h = enemy:FindFirstChild("Humanoid")
            if not h or h.Health <= 1 then
                if root(enemy) then lastEnemyPos = root(enemy).Position end
                attachStop(); return
            end
        end
        if not enemy or not enemy.Parent or not root(enemy) then
            enemy = attachClosest()
            if enemy then attachTarget = enemy else attachStop(); return end
        else
            local er = root(enemy)
            if er and (mr.Position-er.Position).Magnitude > S.AttachRange then
                enemy = attachClosest()
                if enemy then attachTarget = enemy else attachStop(); return end
            end
        end
        local er = root(enemy); if not er then return end
        lastEnemyPos = er.Position
        local tp = attachPos(enemy); if not tp then return end
        mr.CFrame = CFrame.lookAt(tp, er.Position); mr.AssemblyLinearVelocity = Vector3.zero
        local hum = mc:FindFirstChild("Humanoid"); if hum then hum.AutoRotate = false end
    else
        if flyOn then attachKillFly() end
        if noclipOn then attachKillNoclip() end
    end
end)

-- Hitbox applier
local hitboxOrigSizes = {}
local aliveFolder = alive()
if aliveFolder then
    aliveFolder.ChildAdded:Connect(function(child)
        task.wait(0.1)
        if S.HitboxEnabled and not isPlr(child) and child:IsA("Model") then
            local r = root(child)
            if r and r:IsA("BasePart") then
                if not hitboxOrigSizes[r] then hitboxOrigSizes[r] = r.Size end
                r.Size = Vector3.new(S.HitboxSize, S.HitboxSize, S.HitboxSize)
                r.Transparency = S.HitboxTrans; r.CanCollide = false
            end
        end
    end)
end

-- Auto Kill
local _G_CurrentNPCTarget = nil
local function findAliveNPC()
    local al = alive(); if not al then return nil end
    local myChar = LP.Character
    local myRoot = myChar and root(myChar)
    if not myRoot then return nil end
    local best, bestD = nil, S.AutoKillRange or 10000
    for _, entity in pairs(al:GetChildren()) do
        if EnemyValues.autokillplayers then
            local plr = Players:GetPlayerFromCharacter(entity)
            if plr and entity:FindFirstChild("Humanoid") and entity ~= LP.Character then
                if EnemyValues.singuonly then
                    if not (plr.Data and plr.Data.Singularity and plr.Data.Singularity.Value) then continue end
                end
                local humanoid = entity.Humanoid
                local eRoot = entity:FindFirstChild("HumanoidRootPart")
                if eRoot and humanoid.Health > 2 then
                    local plrData = plr:FindFirstChild("Data")
                    if plrData then
                        if plrData.Wiped and plrData.Wiped.Value then continue end
                        local area = plrData.CurrentArea and plrData.CurrentArea.Value
                        if area == "The Darius" or area == "Sentenza" or area == "Syndicate Office" or area == "Underground Railway" then continue end
                    end
                    local d = (myRoot.Position - eRoot.Position).Magnitude
                    if d <= S.AutoKillRange and d < bestD then bestD = d; best = entity end
                end
            end
        else
            if validTarget(entity, false) then
                local eRoot = entity:FindFirstChild("HumanoidRootPart") or entity.PrimaryPart
                if eRoot then
                    local h = entity:FindFirstChild("Humanoid")
                    local isAlive = true
                    if h and h.Health <= 2 then
                        if entity.Parent and entity.Parent.Name == "Alive" and (entity.Name == "Nothing There" or string.find(entity.Name, "Scavenger")) then
                            isAlive = true
                        else isAlive = false end
                    end
                    if isAlive then
                        local d = (myRoot.Position - eRoot.Position).Magnitude
                        if d <= S.AutoKillRange and d < bestD then
                            if entity.Name == "Angelica" then return entity end
                            bestD = d; best = entity
                        end
                    end
                end
            end
        end
    end
    return best
end

local npcTargetPlate = nil
local function createNPCTargetPlate()
    if npcTargetPlate then npcTargetPlate:Destroy() end
    npcTargetPlate = Instance.new("Part"); npcTargetPlate.Name = "NPCTargetPlate"
    npcTargetPlate.Shape = Enum.PartType.Block; npcTargetPlate.Size = Vector3.new(8,0.5,8)
    npcTargetPlate.CanCollide = true; npcTargetPlate.Anchored = true
    npcTargetPlate.Material = Enum.Material.ForceField
    npcTargetPlate.Transparency = 0.3; npcTargetPlate.Parent = Workspace
end
-- Defer the auxiliary target plate until Auto Kill is actually enabled.

local currentNPCTarget = nil
local nextNPCSearch = 0
RS.RenderStepped:Connect(function()
    if EnemyValues.autokill or EnemyValues.autokillplayers then
        if not npcTargetPlate then createNPCTargetPlate() end
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        if currentNPCTarget and currentNPCTarget:FindFirstChild("Humanoid") then
            local hum = currentNPCTarget.Humanoid
            if hum.Health <= 2 then
                local Grip = RepStore.Events and RepStore.Events.Grip
                if Grip then for _ = 1, 3 do Grip:FireServer(currentNPCTarget); task.wait(0.05) end end
                currentNPCTarget = nil
            end
        else currentNPCTarget = nil end
        if not currentNPCTarget then
            local now = os.clock()
            if now >= nextNPCSearch then
                nextNPCSearch = now + 0.12
                currentNPCTarget = findAliveNPC()
            end
            _G_CurrentNPCTarget = (EnemyValues.autokill and not EnemyValues.autokillplayers) and currentNPCTarget or nil
        else
            local tRoot = currentNPCTarget:FindFirstChild("HumanoidRootPart")
            if tRoot and (hrp.Position - tRoot.Position).Magnitude > S.AutoKillRange then currentNPCTarget = nil end
            _G_CurrentNPCTarget = (EnemyValues.autokill and not EnemyValues.autokillplayers) and currentNPCTarget or nil
        end
        local mapExit = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Exit")
        if mapExit and mapExit.Particles and mapExit.Particles.Enabled then
            hrp.CFrame = mapExit.CFrame
        elseif currentNPCTarget and not S.AttachEnabled then
            local npcHRP = currentNPCTarget:FindFirstChild("HumanoidRootPart") or currentNPCTarget:FindFirstChild("Torso")
            if npcHRP then
                local pos = npcHRP.Position
                hrp.CFrame = CFrame.new(pos)
                if npcTargetPlate then npcTargetPlate.Position = Vector3.new(pos.X, pos.Y-2.5, pos.Z) end
            end
        end
    else
        _G_CurrentNPCTarget = nil
        -- Remove the helper part while inactive; recreate it on the next enable.
        if npcTargetPlate then
            npcTargetPlate:Destroy()
            npcTargetPlate = nil
        end
    end
end)

-- Anim speed loop
local animT = 0
RS.Heartbeat:Connect(function(dt)
    if S.AnimEnabled then
        animT = animT + dt
        if animT >= 0.1 then
            animT = 0
            local c = LP.Character; if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid") or c:FindFirstChildOfClass("AnimationController")
            if h then
                for _, track in ipairs(h:GetPlayingAnimationTracks()) do
                    pcall(track.AdjustSpeed, track, S.AnimSpeed)
                end
            end
        end
    end
end)

-- Auto Kill animation loop
local lastAutoKillAnim = 0
local chargedAttackAnimation = Instance.new("Animation")
chargedAttackAnimation.AnimationId = "rbxassetid://85895226062060"
task.spawn(function()
    while true do
        local autoKillActive = EnemyValues.autokill or EnemyValues.autokillplayers
        task.wait(autoKillActive and 0.01 or 0.25)
        if autoKillActive then
            local now = tick()
            local char = LP.Character; if not char then continue end
            local weapon = char:FindFirstChild("Weapon")
            local humanoid = char:FindFirstChild("Humanoid")
            local wv = weapon and weapon.Value or ""
            local interval = 0.01
            if wv == "Wheel's Industry" and EnemyValues.wheelsIndustryPaced then interval = 0.1 end
            if now - lastAutoKillAnim >= interval then
                lastAutoKillAnim = now
                if weapon and humanoid and wv ~= "" then
                    local wi = RepStore:FindFirstChild("WeaponINFO")
                    if wi then
                        local wd = wi:FindFirstChild(wv)
                        if wd then
                            local tuh = wd:FindFirstChild("TimeUntilHitbox")
                            local animator = humanoid:FindFirstChild("Animator")
                            if animator and tuh then
                                local useCharged = false
                                if _G_CurrentNPCTarget and EnemyValues.autokill then
                                    local npcHum = _G_CurrentNPCTarget:FindFirstChild("Humanoid")
                                    if npcHum and npcHum.Health < 10 then useCharged = true end
                                end
                                local attackAnim = nil
                                if useCharged then
                                    attackAnim = chargedAttackAnimation
                                end
                                if not attackAnim then
                                    local animName = (wv == "Wheel's Industry") and "AttackAnimation3" or "AttackAnimation1"
                                    attackAnim = wd:FindFirstChild(animName)
                                    if not attackAnim then
                                        for _, child in ipairs(wd:GetChildren()) do
                                            if child:IsA("Animation") and string.find(child.Name, "Attack") then attackAnim = child; break end
                                        end
                                    end
                                end
                                if attackAnim then
                                    local track = cachedAttackTrack(animator, attackAnim)
                                    if track then
                                        pcall(function() track:Stop(0) end)
                                        track:Play(); track.TimePosition = tuh.Value
                                        track:AdjustSpeed(50)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Permanent EXP bar
task.spawn(function()
    while true do
        task.wait(QolValues.permexp and 0.25 or 1.5)
        if QolValues.permexp then
            pcall(function()
                local stats = LP.PlayerGui:FindFirstChild("Stats")
                local ui = stats and stats:FindFirstChild("UI")
                local slider = ui and ui:FindFirstChild("GradeSlider")
                local data = LP:FindFirstChild("Data")
                local gradeValue = data and data:FindFirstChild("Grade")
                local pointValue = data and data:FindFirstChild("GradeUpPoints")
                if not (slider and gradeValue and pointValue) then return end

                local grade = tonumber(gradeValue.Value)
                local points = tonumber(pointValue.Value) or 0
                local required = QolValues.gradeReq[grade] or 10000

                slider.Visible = true
                local clip = slider:FindFirstChild("SliderClip")
                    or slider:FindFirstChild("Fill")
                    or slider:FindFirstChild("Bar")
                if clip and clip:IsA("GuiObject") then
                    clip.Size = UDim2.fromScale(math.clamp(points / math.max(required, 1), 0, 1), 1)
                end
            end)
        end
    end
end)

-- Character respawn
LP.CharacterAdded:Connect(function(nc)
    clearAttackTrackCache()
    S.AttachEnabled = false
    attachActive = false
    attachTarget = nil
    attachKillFly()
    attachKillNoclip()
    rebuildCharParts(nc)
    nc.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then charParts[#charParts+1] = d end
    end)
    nc.DescendantRemoving:Connect(function(d)
        if not d:IsA("BasePart") then return end
        for i = #charParts, 1, -1 do
            if charParts[i] == d then table.remove(charParts, i); break end
        end
    end)
end)

-- Global keybinds
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.X and S.AttachEnabled then
        local t = attachClosest(); if t then attachTarget = t end
    end
    local keyName = input.KeyCode.Name
    for i = 1, 3 do
        if keyName == PageSlots[i].key and PageSlots[i].name ~= "" then
            FirePage(PageSlots[i].name, PageSlots[i].mode)
        end
    end
end)

