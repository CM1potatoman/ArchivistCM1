-- ============================================================
-- AUTO RAILWAY TAB
-- ============================================================
local RRTab = Window:CreateTab("Railway", 10726204364)
RRTab:CreateLabel("Refraction Railway automation and boss-specific controls")

do
    local RR = {
        Enabled = false, AttachMode = false,
        AttachRange = 50, AttachDistance = 3, AttachHeight = -5.5,
        ReattackTimeout = 5, DetectionRange = 10000,
        UsePages = false, StaminaThreshold = 30, PageFireInterval = 2,
        AutoSell = true, SellThreshold = 250,
        AutoPickup = true, PickupRange = 50, PickupEnemyRange = 20,
        SellEveryStations = 0, LastSellStation = -1,
        LeaveAtStation = 0, PrioritizeBoss = true,
        BigBroDist = 5, BigBroHeight = -2,
        SweeperDist = 5, SweeperHeight = -2,
        NothingDist = 5, NothingHeight = -2,
        ValuableFirst = true,
        CornerMode = false, CornerCFrame = nil, CornerRadius = 18,
    }
    local RR_BOSSES = {"Big Brother Of The Middle", "Sweeper Brute", "Nothing There"}
    local RRPageSlots = {
        {name = "", priority = 1, lastFired = 0, mode = "normal"},
        {name = "", priority = 2, lastFired = 0, mode = "normal"},
        {name = "", priority = 3, lastFired = 0, mode = "normal"},
    }
    local REWARD_OPTIONS = {"Singularity","SkipFloors","RareItems","Item","HugeAhn","Ahn","RareAccessories","Accessories","HugeExperience","Experience","Heal"}
    local RRRewardPriority = {"Singularity","Item","Ahn","Experience"}
    local SELL_THRESHOLDS = {100, 250, 350, 500, 750, 1000}
    local SELL_THRESHOLD_NAMES = {"<100","<250","<350","<500","<750","<1000"}

    local rrStatus = "Idle"
    local rrPhase = "idle"
    local rrCurrentTarget = nil
    local rrTargetLowHPTime = {}
    local rrCombatConns = {}
    local rrNPCTargetPlate = nil

    local function rrCreatePlate()
        if rrNPCTargetPlate then pcall(function() rrNPCTargetPlate:Destroy() end) end
        rrNPCTargetPlate = Instance.new("Part")
        rrNPCTargetPlate.Name = "RRTargetPlate"
        rrNPCTargetPlate.Shape = Enum.PartType.Block
        rrNPCTargetPlate.Size = Vector3.new(8, 0.5, 8)
        rrNPCTargetPlate.CanCollide = true
        rrNPCTargetPlate.Anchored = true
        rrNPCTargetPlate.Material = Enum.Material.ForceField
        rrNPCTargetPlate.Transparency = 0.3
        rrNPCTargetPlate.Parent = Workspace
    end
    local function rrInRailway()
        local ok, result = pcall(function() return Workspace.Map.StationDisplay ~= nil end)
        return ok and result
    end
    local function rrGetStationNumber()
        local ok, text = pcall(function() return Workspace.Map.StationDisplay.SurfaceGui.TextLabel.Text end)
        if ok and text then local num = text:match("%d+"); return num and tonumber(num) or 0 end
        return 0
    end
    local function rrShouldLeave()
        if RR.LeaveAtStation <= 0 then return false end
        return rrGetStationNumber() >= RR.LeaveAtStation
    end
    local function rrLeaveAvailable()
        local ok, leave = pcall(function() return Workspace.Map.Leave end)
        if not ok or not leave then return false end
        local p = leave:FindFirstChild("Particles")
        if not p then return false end
        return p.Enabled == true
    end
    local function rrExitAvailable()
        local map = Workspace:FindFirstChild("Map"); if not map then return false end
        local ex = map:FindFirstChild("Exit"); if not ex then return false end
        local p = ex:FindFirstChild("Particles"); if not p then return false end
        return p.Enabled == true
    end
    local function rrMerchantAvailable()
        local npcs = Workspace:FindFirstChild("NPCS")
        return npcs and npcs:FindFirstChild("Railway Merchant") ~= nil
    end
    local function rrRewardsDisplayed()
        local map = Workspace:FindFirstChild("Map"); if not map then return false end
        local sd = map:FindFirstChild("StationDisplay"); if not sd then return false end
        local sdY = sd:GetPivot().Position.Y
        for _, desc in ipairs(sd:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local prParent = desc.Parent
                local wPos
                if prParent then
                    if prParent:IsA("Attachment") then wPos = prParent.WorldPosition
                    elseif prParent:IsA("BasePart") then wPos = prParent.Position
                    elseif prParent:IsA("Model") and prParent.PrimaryPart then wPos = prParent.PrimaryPart.Position end
                end
                if wPos and wPos.Y >= (sdY - 5) then return true end
            end
        end
        return false
    end
    local function rrHasEnemies()
        local al = alive(); if not al then return false end
        for _, entity in ipairs(al:GetChildren()) do
            if entity ~= LP.Character and entity:IsA("Model") and not isPlr(entity) then
                local hum = entity:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then return true end
            end
        end
        return false
    end
    local function rrEnemyWithin(range)
        local c = LP.Character; local r = root(c)
        local al = alive()
        if not r or not al then return false end
        for _, entity in ipairs(al:GetChildren()) do
            if entity ~= c and entity:IsA("Model") and not isPlr(entity) then
                local hum = entity:FindFirstChildOfClass("Humanoid")
                local er = root(entity)
                if hum and hum.Health > 0 and er and (r.Position - er.Position).Magnitude <= range then
                    return true
                end
            end
        end
        return false
    end
    local RR_VALUABLE_KEYWORDS = {"ego", "gift", "vial", "singularity", "serum", "vestige", "ticket", "rare"}
    local function rrDropLabel(item, prompt)
        local label = (prompt and prompt.ObjectText) or item.Name or ""
        return string.lower(tostring(label))
    end
    local function rrIsValuableDrop(item, prompt)
        local label = rrDropLabel(item, prompt)
        for _, keyword in ipairs(RR_VALUABLE_KEYWORDS) do
            if label:find(keyword, 1, true) then return true end
        end
        return false
    end
    local function rrPickupItems()
        if not RR.AutoPickup or rrEnemyWithin(RR.PickupEnemyRange) then return 0 end
        local thrown = Workspace:FindFirstChild("Thrown")
        local c = LP.Character; local r = root(c)
        if not thrown or not r then return 0 end
        local candidates = {}
        for _, item in ipairs(thrown:GetChildren()) do
            local pivot = modelPivot(item)
            local prompt = findPrompt(item)
            if pivot and prompt and (r.Position - pivot.Position).Magnitude <= RR.PickupRange then
                table.insert(candidates, {item=item, pivot=pivot, prompt=prompt, valuable=rrIsValuableDrop(item, prompt)})
            end
        end
        if RR.ValuableFirst then
            table.sort(candidates, function(a,b)
                if a.valuable ~= b.valuable then return a.valuable end
                return (r.Position-a.pivot.Position).Magnitude < (r.Position-b.pivot.Position).Magnitude
            end)
        end
        local picked = 0
        for _, entry in ipairs(candidates) do
            if not RR.Enabled or rrEnemyWithin(RR.PickupEnemyRange) then break end
            if entry.item.Parent and entry.prompt.Parent then
                r.CFrame = entry.pivot
                for _ = 1, 4 do
                    if not entry.item.Parent then break end
                    pcall(function() fireproximityprompt(entry.prompt) end)
                    task.wait(0.09)
                end
                if not entry.item.Parent then picked += 1 end
            end
        end
        return picked
    end
    local function rrIsBoss(entity)
        if not entity then return false end
        for _, name in ipairs(RR_BOSSES) do if entity.Name == name then return true end end
        return false
    end
    local function rrFindTarget()
        local al = alive(); if not al then return nil end
        local c = LP.Character; if not c then return nil end
        local r = root(c); if not r then return nil end
        local best, bestD = nil, RR.DetectionRange
        local bestBoss, bestBossD = nil, RR.DetectionRange
        for _, entity in ipairs(al:GetChildren()) do
            if entity ~= c and entity:IsA("Model") and not isPlr(entity) then
                local hum = entity:FindFirstChild("Humanoid")
                local eRoot = root(entity)
                if hum and eRoot and hum.Health > 0 then
                    local d = (r.Position - eRoot.Position).Magnitude
                    if d <= RR.DetectionRange then
                        if RR.PrioritizeBoss and rrIsBoss(entity) then
                            if d < bestBossD then bestBossD = d; bestBoss = entity end
                        end
                        if d < bestD then bestD = d; best = entity end
                    end
                end
            end
        end
        return bestBoss or best
    end
    local function rrCornerStep()
        local c = LP.Character; local r = root(c)
        if not c or not r then return false end
        if not RR.CornerCFrame then RR.CornerCFrame = r.CFrame end
        local al = alive(); if not al then return false end
        local targets = {}
        for _, entity in ipairs(al:GetChildren()) do
            if entity ~= c and entity:IsA("Model") and not isPlr(entity) then
                local hum = entity:FindFirstChildOfClass("Humanoid")
                local er = root(entity)
                if hum and er and hum.Health > 0 then table.insert(targets, entity) end
            end
        end
        if #targets == 0 then r.CFrame = RR.CornerCFrame; return false end
        for _, target in ipairs(targets) do
            if not target:FindFirstChild("Aggrod") then
                local er = root(target)
                if er then
                    r.CFrame = er.CFrame * CFrame.Angles(math.rad(90), 0, 0) + Vector3.new(0, 10, 0)
                    r.AssemblyLinearVelocity = Vector3.zero
                    return true
                end
            end
        end
        r.CFrame = RR.CornerCFrame
        r.AssemblyLinearVelocity = Vector3.zero
        table.sort(targets, function(a,b)
            local ar, br = root(a), root(b)
            if not ar then return false end
            if not br then return true end
            return (ar.Position-RR.CornerCFrame.Position).Magnitude < (br.Position-RR.CornerCFrame.Position).Magnitude
        end)
        rrCurrentTarget = targets[1]
        local tr = rrCurrentTarget and root(rrCurrentTarget)
        if tr and (tr.Position - RR.CornerCFrame.Position).Magnitude <= RR.CornerRadius then
            attackPulse(rrCurrentTarget, 45)
        end
        return true
    end

    local function rrGetPages()
        local pages = {}
        for _, tool in pairs(LP.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("RemoteEvent") then table.insert(pages, tool.Name) end
        end
        return pages
    end
    local function rrCanFirePage(slot)
        if slot.name == "" then return false end
        local data = LP:FindFirstChild("Data")
        local stamina = data and data:FindFirstChild("Stamina")
        if stamina and stamina.Value < RR.StaminaThreshold then return false end
        local tool = LP.Backpack:FindFirstChild(slot.name); if not tool then return false end
        local lightCost = tool:GetAttribute("LightCost") or 0
        if lightCost > 0 then
            local lightStacks = data and data:FindFirstChild("LightStacks")
            if not lightStacks or lightStacks.Value < lightCost then return false end
        end
        return true
    end
    local function rrFirePages()
        if not RR.UsePages then return end
        local sorted = {}
        for _, slot in ipairs(RRPageSlots) do if slot.name ~= "" then table.insert(sorted, slot) end end
        table.sort(sorted, function(a, b) return a.priority < b.priority end)
        for _, slot in ipairs(sorted) do
            if rrCanFirePage(slot) then
                local tool = LP.Backpack:FindFirstChild(slot.name)
                if tool then
                    local remote = tool:FindFirstChild("RemoteEvent")
                    if remote then
                        local cdValue
                        if globalNoCooldowns then cdValue = 0
                        elseif slot.mode == "half" then cdValue = math.floor((tool:GetAttribute("CD") or 10) / 2)
                        elseif slot.mode == "none" then cdValue = 0
                        else cdValue = tool:GetAttribute("CD") or 10 end
                        remote:FireServer(cdValue)
                        slot.lastFired = tick()
                        break
                    end
                end
            end
        end
    end
    local function rrPickReward()
        for _ = 1, 10 do
            if not RR.Enabled then return false end
            local map = Workspace:FindFirstChild("Map"); if not map then task.wait(1); continue end
            local sd = map:FindFirstChild("StationDisplay"); if not sd then task.wait(1); continue end
            local allPrompts = {}
            local sdY = sd:GetPivot().Position.Y
            for _, desc in ipairs(sd:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    local prParent = desc.Parent
                    local wPos
                    if prParent then
                        if prParent:IsA("Attachment") then wPos = prParent.WorldPosition
                        elseif prParent:IsA("BasePart") then wPos = prParent.Position
                        elseif prParent:IsA("Model") and prParent.PrimaryPart then wPos = prParent.PrimaryPart.Position end
                    end
                    if wPos and wPos.Y >= (sdY - 5) then
                        table.insert(allPrompts, {prompt=desc,parent=prParent,name=prParent and prParent.Name or "Unknown"})
                    end
                end
            end
            if #allPrompts == 0 then task.wait(1); continue end
            local picked = nil
            for _, rewardName in ipairs(RRRewardPriority) do
                for _, entry in ipairs(allPrompts) do
                    if string.find(string.lower(entry.name), string.lower(rewardName)) then picked = entry; break end
                end
                if picked then break end
            end
            if not picked then picked = allPrompts[math.random(1, #allPrompts)] end
            local c = LP.Character; local r = root(c)
            if r and picked.prompt and picked.prompt.Parent then
                local tpPos = nil
                local prParent = picked.prompt.Parent
                if prParent:IsA("Attachment") then tpPos = prParent.WorldPosition
                elseif prParent:IsA("BasePart") then tpPos = prParent.Position
                elseif prParent:IsA("Model") and prParent.PrimaryPart then tpPos = prParent.PrimaryPart.Position
                elseif prParent.Parent and prParent.Parent:IsA("BasePart") then tpPos = prParent.Parent.Position end
                if tpPos then
                    r.CFrame = CFrame.new(tpPos + Vector3.new(0, 3, 0))
                    r.AssemblyLinearVelocity = Vector3.zero
                    task.wait(0.5)
                end
            end
            for _ = 1, 10 do
                if not picked.prompt or not picked.prompt.Parent then break end
                pcall(function()
                    picked.prompt.Enabled = true
                    picked.prompt.MaxActivationDistance = 9999
                    picked.prompt.HoldDuration = 0
                    picked.prompt.RequiresLineOfSight = false
                end)
                fireproximityprompt(picked.prompt)
                task.wait(0.1)
            end
            return true
        end
        return false
    end
    local function rrFindSellableItem()
        for _, tool in ipairs(LP.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local sellPrice = tool:FindFirstChild("SellPrice")
                if sellPrice and sellPrice:IsA("NumberValue") and sellPrice.Value > 0 then
                    if sellPrice.Value < RR.SellThreshold then return tool end
                end
            end
        end
        return nil
    end
    local function rrDialogueOpen()
        return dialogueIsOpen()
    end
    local function rrEquipTool(item)
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:EquipTool(item) end) else item.Parent = char end
        task.wait(0.4)
    end
    local function rrSellToMerchant()
        local npcs = Workspace:FindFirstChild("NPCS")
        local merchant = npcs and npcs:FindFirstChild("Railway Merchant")
        if not merchant then return false end
        if not rrFindSellableItem() then return false end
        local dialogueReady = false
        for _ = 1, 5 do
            if not RR.Enabled then return false end
            if rrHasEnemies() then return false end
            if not rrDialogueOpen() then
                local mr = merchant:FindFirstChild("HumanoidRootPart") or merchant.PrimaryPart or merchant:FindFirstChildWhichIsA("BasePart")
                if not mr then task.wait(0.5); continue end
                local r = root(LP.Character)
                if r then
                    r.CFrame = (mr.CFrame or CFrame.new(mr.Position)) + Vector3.new(0, 3, 0)
                    r.AssemblyLinearVelocity = Vector3.zero
                    r.AssemblyAngularVelocity = Vector3.zero
                end
                task.wait(0.5)
                interactWith(merchant)
                if not waitForDialogue(3) then task.wait(0.5); continue end
                task.wait(0.5)
            end
            if not rrDialogueOpen() then continue end
            pressV(); task.wait(0.3)
            local loaded = false
            for _ = 1, 20 do
                local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
                if ok and scroll and #scroll:GetChildren() > 0 then loaded = true; break end
                task.wait(0.2)
            end
            if not loaded then continue end
            if not DialogueUtil.selectFirstMatchingOption({"take a look", "look at", "these items"}, 3) then
                task.wait(0.5)
                continue
            end
            task.wait(0.3)
            if not rrDialogueOpen() then continue end
            if not waitForDialogue(2) then continue end
            task.wait(0.3)
            dialogueReady = true; break
        end
        if not dialogueReady then return false end
        local soldAny = false
        for _ = 1, 60 do
            if not RR.Enabled then break end
            if rrHasEnemies() then break end
            if not rrDialogueOpen() then break end
            local item = rrFindSellableItem(); if not item then break end
            rrEquipTool(item)
            if not rrDialogueOpen() then break end
            local choseItem = false
            for _ = 1, 5 do
                if not rrDialogueOpen() then break end
                pressV(); task.wait(0.2)
                if DialogueUtil.selectFirstMatchingOption({"How about this one", "this one", "What about"}, 1) then
                    choseItem = true
                    break
                end
                task.wait(0.3)
            end
            if not choseItem then break end
            task.wait(0.3)
            if not rrDialogueOpen() then break end
            if not waitForDialogue(2) then break end
            task.wait(0.3)
            local confirmedSale = false
            for _ = 1, 5 do
                if not rrDialogueOpen() then break end
                pressV(); task.wait(0.2)
                if DialogueUtil.selectFirstMatchingOption({"Sell All", "Deal", "Sell"}, 1) then
                    confirmedSale = true
                    break
                end
                task.wait(0.3)
            end
            if not confirmedSale then break end
            soldAny = true
            task.wait(0.5)
            if not rrDialogueOpen() then break end
            if not waitForDialogue(2) then break end
            task.wait(0.3)
        end
        if rrDialogueOpen() then
            for _ = 1, 3 do
                if DialogueUtil.selectFirstMatchingOption({"Bye", "Nevermind"}, 1) then task.wait(0.3) end
                if not rrDialogueOpen() then break end
            end
        end
        waitForClose(2)
        return soldAny
    end
    local function rrTPToExit()
        local map = Workspace:FindFirstChild("Map"); if not map then return false end
        local target = map:FindFirstChild("Exit"); if not target then return false end
        local r = root(LP.Character)
        if r then
            local tpPart = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")) or target
            r.CFrame = tpPart.CFrame + Vector3.new(0, 3, 0)
            r.AssemblyLinearVelocity = Vector3.zero
            VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game); task.wait(0.25)
            VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            return true
        end
        return false
    end
    local function rrTPToLeave()
        local map = Workspace:FindFirstChild("Map"); if not map then return false end
        local target = map:FindFirstChild("Leave"); if not target then return false end
        local r = root(LP.Character)
        if r then
            local tpPart = target:IsA("Model") and (target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")) or target
            r.CFrame = tpPart.CFrame + Vector3.new(0, 3, 0)
            r.AssemblyLinearVelocity = Vector3.zero
            VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game); task.wait(0.25)
            VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            return true
        end
        return false
    end
    local function rrStopCombat()
        for _, conn in ipairs(rrCombatConns) do
            if type(conn) == "function" then conn() else pcall(conn.Disconnect, conn) end
        end
        table.clear(rrCombatConns)
        rrCurrentTarget = nil
        table.clear(rrTargetLowHPTime)
        if rrNPCTargetPlate then pcall(function() rrNPCTargetPlate:Destroy() end); rrNPCTargetPlate = nil end
    end
    local function rrStartCombat()
        rrStopCombat()
        rrCreatePlate()
        local renderConn = RS.RenderStepped:Connect(function()
            if not RR.Enabled or rrPhase ~= "combat" or (RR.AttachMode and not RR.CornerMode) then return end
            local char = LP.Character; if not char then return end
            local hrp = root(char); if not hrp then return end
            if RR.CornerMode then
                rrCornerStep()
                return
            end
            if not rrCurrentTarget or not rrCurrentTarget.Parent then
                rrCurrentTarget = rrFindTarget()
            else
                local hum = rrCurrentTarget:FindFirstChild("Humanoid")
                if not hum or hum.Health <= 0 then rrCurrentTarget = rrFindTarget() end
            end
            if not rrCurrentTarget then return end
            local hum = rrCurrentTarget:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 or not rrCurrentTarget.Parent then rrCurrentTarget = nil; return end
            if hum.Health <= 3 and hum.Health > 0 then
                if not rrTargetLowHPTime[rrCurrentTarget] then
                    rrTargetLowHPTime[rrCurrentTarget] = tick()
                elseif tick() - rrTargetLowHPTime[rrCurrentTarget] >= RR.ReattackTimeout then
                    local Grip = RepStore:FindFirstChild("Events") and RepStore.Events:FindFirstChild("Grip")
                    if Grip then for _ = 1, 5 do Grip:FireServer(rrCurrentTarget); task.wait(0.05) end end
                    rrTargetLowHPTime[rrCurrentTarget] = tick()
                end
            else rrTargetLowHPTime[rrCurrentTarget] = nil end
            local npcHRP = root(rrCurrentTarget)
            if npcHRP then
                hrp.CFrame = CFrame.new(npcHRP.Position)
                if rrNPCTargetPlate then
                    rrNPCTargetPlate.Position = Vector3.new(npcHRP.Position.X, npcHRP.Position.Y - 2.5, npcHRP.Position.Z)
                end
            end
        end)
        table.insert(rrCombatConns, renderConn)

        local rrAttachTarget = nil
        local rrAttachStuckTimer = 0
        local rrLastEnemyPos = nil
        local rrLastAttachPos = nil
        local rrFlyOn, rrNoclipOn = false, false
        local rrFlyParts = {}
        local rrCollisionState = setmetatable({}, {__mode = "k"})

        local function rrAttachStartFly()
            if rrFlyOn then return end
            local c = LP.Character; if not c then return end
            local r = root(c); local h = c:FindFirstChild("Humanoid")
            if not r or not h then return end
            local bg = Instance.new("BodyGyro")
            bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.CFrame = r.CFrame; bg.Parent = r
            table.insert(rrFlyParts, bg)
            h.PlatformStand = true; rrFlyOn = true
        end
        local function rrAttachKillFly()
            if not rrFlyOn then return end
            for _, p in ipairs(rrFlyParts) do pcall(p.Destroy, p) end
            table.clear(rrFlyParts)
            local c = LP.Character
            if c then local h = c:FindFirstChild("Humanoid"); if h then h.PlatformStand = false end end
            rrFlyOn = false
        end
        local function rrAttachFindClosest()
            local c = LP.Character; if not c then return nil end
            local r = root(c); if not r then return nil end
            local al = alive(); if not al then return nil end
            local best, bestD = nil, RR.DetectionRange
            local bestBoss, bestBossD = nil, RR.DetectionRange
            for _, t in ipairs(al:GetChildren()) do
                if validTarget(t, false) then
                    local tr = root(t)
                    if tr then
                        local d = (r.Position - tr.Position).Magnitude
                        if d <= RR.DetectionRange then
                            if RR.PrioritizeBoss and rrIsBoss(t) then
                                if d < bestBossD then bestBossD = d; bestBoss = t end
                            else
                                if d < bestD then bestD = d; best = t end
                            end
                        end
                    end
                end
            end
            if RR.PrioritizeBoss and bestBoss then rrLastEnemyPos = root(bestBoss).Position; return bestBoss end
            if best then rrLastEnemyPos = root(best).Position end
            return best
        end

        local attachConn = RS.Heartbeat:Connect(function(dt)
            if not RR.Enabled or rrPhase ~= "combat" or not RR.AttachMode or RR.CornerMode then
                if rrFlyOn then rrAttachKillFly() end
                if rrNoclipOn then
                    rrNoclipOn = false
                    for part, original in pairs(rrCollisionState) do
                        if part and part.Parent then part.CanCollide = original end
                    end
                    table.clear(rrCollisionState)
                end
                rrAttachStuckTimer = 0
                return
            end
            local mc = LP.Character; if not mc then return end
            local mr = root(mc); if not mr then return end
            if rrNoclipOn then
                for _, p in ipairs(charParts) do
                    if p and p.Parent and p:IsA("BasePart") then
                        if rrCollisionState[p] == nil then rrCollisionState[p] = p.CanCollide end
                        p.CanCollide = false
                    end
                end
            end
            mr.AssemblyLinearVelocity = Vector3.zero
            mr.AssemblyAngularVelocity = Vector3.zero
            if not rrFlyOn then rrAttachStartFly() end
            if not rrNoclipOn then
                rrNoclipOn = true
                for _, p in ipairs(charParts) do
                    if p and p.Parent and p:IsA("BasePart") then
                        if rrCollisionState[p] == nil then rrCollisionState[p] = p.CanCollide end
                        p.CanCollide = false
                    end
                end
            end
            local map = Workspace:FindFirstChild("Map")
            local sd = map and map:FindFirstChild("StationDisplay")
            if sd and (mr.Position - sd:GetPivot().Position).Magnitude > 450 then
                mr.CFrame = CFrame.new(sd:GetPivot().Position + Vector3.new(0, 5, 0))
                mr.AssemblyLinearVelocity = Vector3.zero
                return
            end
            if rrLastAttachPos then
                if (mr.Position - rrLastAttachPos).Magnitude < 1 and rrHasEnemies() then
                    rrAttachStuckTimer = rrAttachStuckTimer + dt
                    if rrAttachStuckTimer >= 3 then rrAttachTarget = nil; rrAttachStuckTimer = 0 end
                else rrAttachStuckTimer = 0 end
            end
            rrLastAttachPos = mr.Position
            local enemy = rrAttachTarget
            if enemy then
                local h = enemy:FindFirstChild("Humanoid")
                if not h or h.Health <= 0 or not enemy.Parent then
                    if root(enemy) then rrLastEnemyPos = root(enemy).Position end
                    enemy = rrAttachFindClosest(); rrAttachTarget = enemy
                end
            end
            if not enemy and rrHasEnemies() then
                enemy = rrAttachFindClosest(); rrAttachTarget = enemy
            end
            if not enemy then
                if rrFlyOn then rrAttachKillFly() end
                if rrNoclipOn then
                    rrNoclipOn = false
                    for part, original in pairs(rrCollisionState) do
                        if part and part.Parent then part.CanCollide = original end
                    end
                    table.clear(rrCollisionState)
                end
                local tp = rrLastEnemyPos and (rrLastEnemyPos + Vector3.new(0,5,0)) or (mr.Position + Vector3.new(0,5,0))
                mr.CFrame = CFrame.new(tp)
                return
            end
            rrCurrentTarget = enemy
            local er = root(enemy); if not er then return end
            rrLastEnemyPos = er.Position
            if er.Position.Magnitude > 2000 then rrAttachTarget = nil; return end
            local hum = enemy:FindFirstChild("Humanoid")
            if hum and hum.Health <= 3 and hum.Health > 0 then
                if not rrTargetLowHPTime[enemy] then
                    rrTargetLowHPTime[enemy] = tick()
                elseif tick() - rrTargetLowHPTime[enemy] >= RR.ReattackTimeout then
                    local Grip = RepStore:FindFirstChild("Events") and RepStore.Events:FindFirstChild("Grip")
                    if Grip then for _ = 1, 5 do Grip:FireServer(enemy); task.wait(0.05) end end
                    rrTargetLowHPTime[enemy] = tick()
                end
            else rrTargetLowHPTime[enemy] = nil end
            local isBoss = rrIsBoss(enemy)
            local dist = RR.AttachDistance
            local height = RR.AttachHeight
            if isBoss then
                if enemy.Name == "Big Brother Of The Middle" then dist = RR.BigBroDist; height = RR.BigBroHeight
                elseif enemy.Name == "Sweeper Brute" then dist = RR.SweeperDist; height = RR.SweeperHeight
                elseif enemy.Name == "Nothing There" then dist = RR.NothingDist; height = RR.NothingHeight end
            end
            local lv = er.CFrame.LookVector
            local tp = er.Position + (-lv) * dist + Vector3.new(0, height, 0)
            if tp.Magnitude > 2000 then return end
            mr.CFrame = CFrame.lookAt(tp, er.Position)
            mr.AssemblyLinearVelocity = Vector3.zero
            local h = mc:FindFirstChild("Humanoid"); if h then h.AutoRotate = false end
        end)
        table.insert(rrCombatConns, attachConn)
        table.insert(rrCombatConns, function()
            rrAttachKillFly()
            rrNoclipOn = false
            for part, original in pairs(rrCollisionState) do
                if part and part.Parent then part.CanCollide = original end
            end
            table.clear(rrCollisionState)
            local c = LP.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                local r = root(c)
                if h then h.PlatformStand = false; h.AutoRotate = true; Camera.CameraSubject = h end
                if r then r.Anchored = false; r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end
            end
        end)

        local animActive = true
        local lastRRAnim = 0
        task.spawn(function()
            while animActive and RR.Enabled do
                RS.Heartbeat:Wait()
                if rrPhase ~= "combat" or not rrCurrentTarget then task.wait(0.1); continue end
                local char = LP.Character; if not char then continue end
                local weapon = char:FindFirstChild("Weapon")
                local humanoid = char:FindFirstChild("Humanoid")
                local wv = weapon and weapon.Value or ""
                local now = tick()
                local interval = 0.03
                if wv == "Wheel's Industry" and EnemyValues.wheelsIndustryPaced then interval = 0.1 end
                if now - lastRRAnim < interval then continue end
                lastRRAnim = now
                if weapon and humanoid and wv ~= "" then
                    local wi = RepStore:FindFirstChild("WeaponINFO")
                    if wi then
                        local wd = wi:FindFirstChild(wv)
                        if wd then
                            local tuh = wd:FindFirstChild("TimeUntilHitbox")
                            local animator = humanoid:FindFirstChild("Animator")
                            if animator and tuh then
                                local animName = (wv == "Wheel's Industry") and "AttackAnimation3" or "AttackAnimation1"
                                local anim = wd:FindFirstChild(animName)
                                if not anim then
                                    for _, child in ipairs(wd:GetChildren()) do
                                        if child:IsA("Animation") and string.find(child.Name, "Attack") then anim = child; break end
                                    end
                                end
                                if anim then
                                    local track = cachedAttackTrack(animator, anim)
                                    if track then
                                        pcall(function() track:Stop(0) end)
                                        track:Play(0.01, 1, 1)
                                        track.TimePosition = math.max(0, tuh.Value - 0.02)
                                        track:AdjustSpeed(50)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        table.insert(rrCombatConns, function() animActive = false end)

        local pageActive = true
        task.spawn(function()
            while pageActive and RR.Enabled do
                task.wait(RR.PageFireInterval)
                if rrPhase == "combat" and RR.UsePages and rrCurrentTarget then rrFirePages() end
            end
        end)
        table.insert(rrCombatConns, function() pageActive = false end)
    end
    local rrCombatRunning = false
    local rrRunId = 0
    local function rrEnsureCombat()
        if not rrCombatRunning then rrStopCombat(); rrStartCombat(); rrCombatRunning = true end
    end
    local function rrPauseCombat()
        if rrCombatRunning then rrStopCombat(); rrCombatRunning = false end
    end
    local function rrMainLoop(runId)
        while RR.Enabled and runId == rrRunId do
            if not rrInRailway() then
                rrStatus = "Not in Railway"; rrPhase = "idle"; rrPauseCombat()
                task.wait(2); continue
            end
            local dgui = LP.PlayerGui:FindFirstChild("Dialogue")
            if dgui and dgui.Enabled and RR.AutoSell and rrMerchantAvailable() and rrFindSellableItem() and not rrHasEnemies() then
                rrPauseCombat(); rrPhase = "selling"; rrStatus = "Selling to Merchant"
                rrSellToMerchant(); task.wait(2); continue
            end
            local stationNum = rrGetStationNumber()
            rrStatus = "Station " .. stationNum
            local roomFinished = rrExitAvailable() or rrLeaveAvailable()
            if roomFinished then
                rrPauseCombat(); task.wait(5)
                if not RR.Enabled or runId ~= rrRunId then break end
                local rewardAttempts = 0
                while RR.Enabled and runId == rrRunId and rrRewardsDisplayed() and rewardAttempts < 15 do
                    rrPhase = "rewards"; rrStatus = "Picking Reward"
                    rrPickReward(); task.wait(1); rewardAttempts = rewardAttempts + 1
                end
                if rewardAttempts > 0 then task.wait(3) end
                if not RR.Enabled or runId ~= rrRunId then break end
                if RR.AutoSell and rrMerchantAvailable() and rrFindSellableItem() and not rrHasEnemies() then
                    rrPhase = "selling"; rrStatus = "Selling to Merchant"
                    rrSellToMerchant(); task.wait(2)
                end
                if not RR.Enabled or runId ~= rrRunId then break end
                if rrShouldLeave() and rrLeaveAvailable() then
                    rrPhase = "leaving"; rrStatus = "Leaving at Station " .. stationNum
                    rrTPToLeave(); task.wait(5); break
                elseif rrExitAvailable() then
                    rrPhase = "exiting"; rrStatus = "Moving to Exit"
                    rrTPToExit()
                    local startStation = rrGetStationNumber()
                    for _ = 1, 30 do
                        if not RR.Enabled or runId ~= rrRunId or rrGetStationNumber() ~= startStation or not rrInRailway() then break end
                        task.wait(0.5)
                    end
                end
                rrEnsureCombat(); continue
            end
            rrPhase = "combat"; rrEnsureCombat()
            if rrHasEnemies() then
                rrStatus = "Fighting (Stn " .. stationNum .. ")"
            else
                rrStatus = "Waiting... (Stn " .. stationNum .. ")"
                rrPickupItems()
                if RR.AutoSell and RR.SellEveryStations > 0 and stationNum > 0
                    and stationNum % RR.SellEveryStations == 0 and RR.LastSellStation ~= stationNum
                    and rrMerchantAvailable() and rrFindSellableItem() then
                    rrPauseCombat(); rrPhase = "selling"; rrStatus = "Scheduled Sell"
                    rrSellToMerchant(); RR.LastSellStation = stationNum
                    rrEnsureCombat()
                end
            end
            task.wait(0.5)
        end
        if runId == rrRunId then rrPhase = "idle"; rrStatus = "Idle" end
        rrPauseCombat()
    end

    RRTab:CreateSection("Main Controls")
    RRTab:CreateLabel("Only works inside Refraction Railway")
    RRTab:CreateLabel("Disable Combat tab Auto Kill before using Auto RR")
    local rrStatusLabel = RRTab:CreateLabel("Status: Idle")
    RRTab:CreateToggle({
        Name = "Auto Railway", CurrentValue = false, Flag = "AutoRR",
        Callback = function(state)
            rrRunId += 1
            RR.Enabled = state
            if state then
                rrCombatRunning = false
                rrEnsureCombat()
                local thisRun = rrRunId
                task.spawn(function() rrMainLoop(thisRun) end)
            else
                rrPhase = "idle"; rrStatus = "Idle"
                rrPauseCombat()
                local c = LP.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                local r = c and root(c)
                if h then h.PlatformStand = false; h.AutoRotate = true; Camera.CameraSubject = h end
                if r then r.Anchored = false; r.AssemblyLinearVelocity = Vector3.zero; r.AssemblyAngularVelocity = Vector3.zero end
            end
        end,
    })
    task.spawn(function()
        local lastStatusText = ""
        while true do
            task.wait(RR.Enabled and 0.5 or 1.5)
            local text = "Status: " .. rrStatus .. " [" .. rrPhase .. "]"
            if text ~= lastStatusText then
                lastStatusText = text
                pcall(function()
                    if rrStatusLabel.Set then rrStatusLabel:Set(text) end
                end)
            end
        end
    end)

    RRTab:CreateSection("Combat Settings")
    RRTab:CreateToggle({ Name = "Attach Mode", CurrentValue = false, Flag = "RRAttach", Callback = function(state) RR.AttachMode = state end })
    RRTab:CreateToggle({ Name = "Prioritize Bosses", CurrentValue = true, Flag = "RRPrioBoss", Callback = function(state) RR.PrioritizeBoss = state end })
    RRTab:CreateSlider({ Name = "Detection Range", Range = {100, 10000}, Increment = 100, CurrentValue = 10000, Flag = "RRDetRange", Callback = function(v) RR.DetectionRange = v end })
    RRTab:CreateSlider({ Name = "Attach Distance", Range = {-20, 20}, Increment = 0.5, CurrentValue = 3, Flag = "RRAttachDist", Callback = function(v) RR.AttachDistance = v end })
    RRTab:CreateSlider({ Name = "Attach Height", Range = {-20, 20}, Increment = 0.5, CurrentValue = -5.5, Flag = "RRAttachHeight", Callback = function(v) RR.AttachHeight = v end })
    RRTab:CreateToggle({ Name = "Corner / Group Strat", CurrentValue = false, Flag = "RRCornerMode", Callback = function(state) RR.CornerMode = state end })
    RRTab:CreateButton({ Name = "Set RR Corner Here", Callback = function()
        local r = root(LP.Character)
        if r then RR.CornerCFrame = r.CFrame; rrStatus = "Corner saved" end
    end })
    RRTab:CreateSlider({ Name = "Corner Attack Radius", Range = {6, 40}, Increment = 1, CurrentValue = 18, Flag = "RRCornerRadius", Callback = function(v) RR.CornerRadius = v end })

    RRTab:CreateSection("Pickup")
    RRTab:CreateToggle({ Name = "Auto Pickup Items", CurrentValue = true, Flag = "RRAutoPickup", Callback = function(state) RR.AutoPickup = state end })
    RRTab:CreateToggle({ Name = "Valuable Drops First", CurrentValue = true, Flag = "RRValuableFirst", Callback = function(state) RR.ValuableFirst = state end })
    RRTab:CreateSlider({ Name = "Pickup Range", Range = {10, 200}, Increment = 5, CurrentValue = 50, Flag = "RRPickupRange", Callback = function(v) RR.PickupRange = v end })
    RRTab:CreateSlider({ Name = "No Enemy Range", Range = {5, 100}, Increment = 5, CurrentValue = 20, Flag = "RRPickupEnemyRange", Callback = function(v) RR.PickupEnemyRange = v end })

    RRTab:CreateSection("Boss Distances")
    RRTab:CreateSlider({ Name = "Big Brother Distance", Range = {0, 20}, Increment = 0.5,
        CurrentValue = 5, Flag = "RRBigBroDist", Callback = function(v) RR.BigBroDist = v end })
    RRTab:CreateSlider({ Name = "Big Brother Height", Range = {-20, 20}, Increment = 0.5,
        CurrentValue = -2, Flag = "RRBigBroHeight", Callback = function(v) RR.BigBroHeight = v end })
    RRTab:CreateSlider({ Name = "Sweeper Brute Distance", Range = {0, 20}, Increment = 0.5,
        CurrentValue = 5, Flag = "RRSweeperDist", Callback = function(v) RR.SweeperDist = v end })
    RRTab:CreateSlider({ Name = "Sweeper Brute Height", Range = {-20, 20}, Increment = 0.5,
        CurrentValue = -2, Flag = "RRSweeperHeight", Callback = function(v) RR.SweeperHeight = v end })
    RRTab:CreateSlider({ Name = "Nothing There Distance", Range = {0, 20}, Increment = 0.5,
        CurrentValue = 5, Flag = "RRNothingDist", Callback = function(v) RR.NothingDist = v end })
    RRTab:CreateSlider({ Name = "Nothing There Height", Range = {-20, 20}, Increment = 0.5,
        CurrentValue = -2, Flag = "RRNothingHeight", Callback = function(v) RR.NothingHeight = v end })

    RRTab:CreateSection("Station Controls")
    local rrStationLabel = RRTab:CreateLabel("Current Station: ?")
    task.spawn(function()
        local lastStationText = ""
        while true do
            task.wait(RR.Enabled and 2 or 5)
            if RR.Enabled and rrInRailway() then
                local text = "Current Station: " .. rrGetStationNumber()
                if text ~= lastStationText then
                    lastStationText = text
                    pcall(function()
                        if rrStationLabel.Set then rrStationLabel:Set(text) end
                    end)
                end
            end
        end
    end)
    RRTab:CreateSlider({ Name = "Leave At Station", Range = {0, 50}, Increment = 1, CurrentValue = 0, Flag = "RRLeaveStation", Callback = function(v) RR.LeaveAtStation = v end })

    RRTab:CreateSection("Page System")
    RRTab:CreateLabel("normal = page CD attribute; half = floor(CD/2); none = requests 0. No Cooldowns forces 0 globally.")
    RRTab:CreateLabel("RR also checks Stamina Threshold and fires the highest-priority available configured slot.")
    RRTab:CreateToggle({ Name = "Use Pages", CurrentValue = false, Flag = "RRUsePages", Callback = function(state) RR.UsePages = state end })
    RRTab:CreateSlider({ Name = "Stamina Threshold", Range = {0, 100}, Increment = 5, CurrentValue = 30, Flag = "RRStamina", Callback = function(v) RR.StaminaThreshold = v end })
    RRTab:CreateSlider({ Name = "Page Fire Interval", Range = {1, 10}, Increment = 1, Suffix = "s", CurrentValue = 2, Flag = "RRPageInterval", Callback = function(v) RR.PageFireInterval = v end })

    local rrPageList = rrGetPages()
    if #rrPageList == 0 then rrPageList = GetPages() end
    for i = 1, 3 do
        RRTab:CreateDropdown({ Name = "RR Page Slot " .. i, Options = rrPageList, CurrentOption = {""}, MultipleOptions = false, Flag = "RRPage" .. i, Callback = function(opt) RRPageSlots[i].name = GetValue(opt) end })
        RRTab:CreateDropdown({ Name = "Slot " .. i .. " CD Mode", Options = {"normal","half","none"}, CurrentOption = {"normal"}, MultipleOptions = false, Flag = "RRPageMode" .. i, Callback = function(opt) RRPageSlots[i].mode = GetValue(opt) end })
        RRTab:CreateDropdown({ Name = "Slot " .. i .. " Priority", Options = {"1 (Highest)","2","3 (Lowest)"}, CurrentOption = {i == 1 and "1 (Highest)" or i == 2 and "2" or "3 (Lowest)"}, MultipleOptions = false, Flag = "RRPrio" .. i, Callback = function(opt) local v = GetValue(opt); RRPageSlots[i].priority = tonumber(v:sub(1,1)) or i end })
    end

    RRTab:CreateSection("Rewards")
    for i = 1, 4 do
        local defaults = {"Singularity", "Item", "Ahn", "Experience"}
        RRTab:CreateDropdown({ Name = "Reward Priority " .. i, Options = REWARD_OPTIONS, CurrentOption = {defaults[i]}, MultipleOptions = false, Flag = "RRReward" .. i, Callback = function(opt) RRRewardPriority[i] = GetValue(opt) end })
    end

    RRTab:CreateSection("Auto Sell")
    RRTab:CreateLabel("Sells items below threshold to Railway Merchant")
    RRTab:CreateToggle({ Name = "Auto Sell to Merchant", CurrentValue = true, Flag = "RRAutoSell", Callback = function(state) RR.AutoSell = state end })
    RRTab:CreateSlider({ Name = "Sell Every N Stations", Range = {0, 10}, Increment = 1, CurrentValue = 0, Flag = "RRSellEvery", Callback = function(v) RR.SellEveryStations = v; RR.LastSellStation = -1 end })
    RRTab:CreateDropdown({ Name = "Sell Items Below", Options = SELL_THRESHOLD_NAMES, CurrentOption = {"<250"}, MultipleOptions = false, Flag = "RRSellThreshold", Callback = function(opt)
        local v = GetValue(opt)
        for idx, name in ipairs(SELL_THRESHOLD_NAMES) do if name == v then RR.SellThreshold = SELL_THRESHOLDS[idx]; break end end
    end })
end

