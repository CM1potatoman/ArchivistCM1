-- ============================================================
-- AUTOFARMS TAB
-- ============================================================
local QuestTab = Window:CreateTab("Jobs", 10726204364)
QuestTab:CreateLabel("Quest, delivery, cooking and grade automation")

do
    -- AUTO COOK
    QuestTab:CreateSection("Auto Cook")
    local pot = Workspace.NPCS and Workspace.NPCS:FindFirstChild("Cooking Pot")
    local autoCook = false
    local cookBusy = false

    local Recipes = {
        CookedMeat    = {Name="Cooked Meat",    Ingredients={"Raw Meat"},                               Plating=nil},
        JelloSkewer   = {Name="Jello Skewer",   Ingredients={"Jello"},                                  Plating="Skewer"},
        MeatSkewer    = {Name="Meat Skewer",    Ingredients={"Cooked Meat","Spices"},                   Plating="Skewer"},
        SpicySoup     = {Name="Spicy Soup",     Ingredients={"Spices"},                                 Plating="Plate"},
        Bread         = {Name="Bread",          Ingredients={"Flour","Flour"},                          Plating=nil},
        GoldenBisque  = {Name="Golden Bisque",  Ingredients={"Cooked Meat","Spices","Uncharged Golden Bough"}, Plating="Plate"},
        Burger        = {Name="Burger",         Ingredients={"Cooked Meat","Spices","Bread","Bread"},   Plating=nil},
        CoffeeJelly   = {Name="Coffee Jelly",   Ingredients={"Cup of Coffee","Jello"},                  Plating=nil},
        ShiranoSpecial= {Name="Shirano Special",Ingredients={"Spicy Soup","Cooked Meat"},               Plating=nil},
    }
    local RecipeNames = {}
    for k, r in pairs(Recipes) do RecipeNames[#RecipeNames+1] = r.Name end
    table.sort(RecipeNames)
    local SelectedRecipe = Recipes.SpicySoup

    local function hasIngredients(recipe)
        local count = {}
        for _, item in ipairs(LP.Backpack:GetChildren()) do
            count[item.Name] = (count[item.Name] or 0) + 1
        end
        for _, ing in ipairs(recipe.Ingredients) do
            local c = count[ing] or 0
            if c < 1 then return false end
            count[ing] = c - 1
        end
        if recipe.Plating and (count[recipe.Plating] or 0) < 1 then return false end
        return true
    end

    local function equipTool(toolName)
        local tool = LP.Backpack:FindFirstChild(toolName)
        if tool then tool.Parent = LP.Character; task.wait(0.3); return true end
        return false
    end

    local function firePromptPot()
        if not pot then return end
        for _, p in ipairs(pot:GetDescendants()) do
            if p:IsA("ProximityPrompt") then fireproximityprompt(p); return end
        end
    end

    local function potHasIngredient(name)
        local added = pot and pot:FindFirstChild("AddedIngredients")
        return added and added:FindFirstChild(name) ~= nil
    end

    local function potHasPlating()
        local plating = pot and pot:FindFirstChild("PlatingAdded")
        return plating and plating.Value ~= ""
    end

    local function waitForPotIngredient(name, timeout)
        for _ = 1, (timeout or 5) * 5 do
            if potHasIngredient(name) then return true end
            task.wait(0.2)
        end
        return false
    end

    local function cookOne()
        if not hasIngredients(SelectedRecipe) then return false end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and pot then hrp.CFrame = pot:GetPivot() * CFrame.new(0, 0, 5); task.wait(0.3) end
        firePromptPot(); task.wait(1)
        local scroll = LP.PlayerGui.Dialogue.MainFrame.Options.Scroll
        local startBtn = scroll:FindFirstChild("Option")
        if startBtn then clickButton(startBtn:FindFirstChild("OptionButton")) end
        task.wait(3)
        firePromptPot(); task.wait(1)
        for _, ing in ipairs(SelectedRecipe.Ingredients) do
            equipTool(ing)
            scroll = LP.PlayerGui.Dialogue.MainFrame.Options.Scroll
            local addBtn = scroll:FindFirstChild("Option")
            if addBtn then clickButton(addBtn:FindFirstChild("OptionButton")) end
            if not waitForPotIngredient(ing, 5) then return false end
            task.wait(0.3)
        end
        if SelectedRecipe.Plating then
            equipTool(SelectedRecipe.Plating)
            scroll = LP.PlayerGui.Dialogue.MainFrame.Options.Scroll
            local plateBtn = scroll:GetChildren()[3]
            if plateBtn then
                clickButton(plateBtn:FindFirstChild("OptionButton"))
                for _ = 1, 25 do if potHasPlating() then break end; task.wait(0.2) end
            end
            task.wait(0.3)
        end
        scroll = LP.PlayerGui.Dialogue.MainFrame.Options.Scroll
        scroll.CanvasPosition = Vector2.new(0, 100); task.wait(0.3)
        local completeBtn = scroll:GetChildren()[4]
        if completeBtn then clickButton(completeBtn:FindFirstChild("OptionButton")) end
        return true
    end

    local function autoCookLoop()
        while autoCook and not cookBusy do
            cookBusy = true
            if not hasIngredients(SelectedRecipe) then
                autoCook = false; cookBusy = false; break
            end
            if not cookOne() then autoCook = false end
            cookBusy = false
            task.wait(1)
        end
    end

    QuestTab:CreateDropdown({
        Name = "Recipe", Options = RecipeNames, CurrentOption = {"Spicy Soup"},
        MultipleOptions = false, Flag = "CookRecipe",
        Callback = function(selected)
            local sel = type(selected) == "table" and selected[1] or selected
            for _, r in pairs(Recipes) do if r.Name == sel then SelectedRecipe = r; break end end
        end,
    })

    QuestTab:CreateToggle({
        Name = "Auto Cook", CurrentValue = false, Flag = "AutoCook",
        Callback = function(state)
            autoCook = state
            if state then task.spawn(autoCookLoop) end
        end,
    })

    -- DOCKS DELIVERY
    QuestTab:CreateSection("Docks Delivery")
    local docksEnabled = false
    local docksBusy = false

    local function dockHasShipment()
        local al = Workspace:FindFirstChild("Alive")
        if not al then return false end
        local pc = al:FindFirstChild(LP.Name)
        return pc and pc:FindFirstChild("WhaleShipment") ~= nil
    end

    local function dockFindPirates()
        local pirates = {}
        local f = Workspace:FindFirstChild("NPCS")
        if f then
            for _, npc in ipairs(f:GetChildren()) do
                if npc.Name == "Twinhook Pirate" then table.insert(pirates, npc) end
            end
        end
        return pirates
    end

    local function dockGetQuest()
        local btn = scrollAndFind("Show me the available jobs", false)
        if not btn then btn = scrollAndFind("available jobs", false) end
        if not btn then btn = findButtonByText("Jobs", false) end
        if not btn then
            local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
            if ok and scroll then
                local first = scroll:FindFirstChild("Option")
                if first then btn = first:FindFirstChild("OptionButton") end
            end
        end
        if not btn then return false end
        safeClick(btn); task.wait(0.5)
        if not waitForDialogue(3) then return false end
        task.wait(0.3)
        local questBtn = scrollAndFind("Docks Delivery", false)
        if not questBtn then return false end
        safeClick(questBtn); task.wait(0.5)
        waitForClose(2)
        return hasQuest()
    end

    local function dockGetShipment()
        local pirates = dockFindPirates()
        if #pirates == 0 then return false end
        for _, pirate in ipairs(pirates) do
            if dockHasShipment() then return true end
            local pRoot = root(pirate)
            if pRoot then safeTP(pRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
            interactWith(pirate); task.wait(0.5)
            if dockHasShipment() then return true end
        end
        return false
    end

    local function dockTurnIn()
        for _ = 1, 20 do
            if not hasQuest() or not docksEnabled then break end
            local contractor = getNearestNPC(DOCK_NPCS)
            if not contractor then task.wait(1); continue end
            local cRoot = root(contractor)
            if cRoot then safeTP(cRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.4) end
            interactWith(contractor)
            if not waitForDialogue(3) then task.wait(1); continue end
            task.wait(0.5)
            pressV()
            local turnInBtn = scrollAndFind("I'm here to turn this in", false)
                or scrollAndFind("turn this in", false)
                or scrollAndFind("Turn In", false)
                or scrollAndFind("Complete", false)
            if not turnInBtn then
                local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
                if ok and scroll then
                    local btn3 = scroll:GetChildren()[3]
                    if btn3 then turnInBtn = btn3:FindFirstChild("OptionButton") end
                end
            end
            if not turnInBtn then task.wait(1); continue end
            safeClick(turnInBtn); task.wait(0.5)
            waitForClose(2)
            if not hasQuest() then return true end
            task.wait(0.5)
        end
        return not hasQuest()
    end

    local function docksLoop()
        while docksEnabled do
            if docksBusy then task.wait(0.2); continue end
            docksBusy = true
            local contractor = getNearestNPC(DOCK_NPCS)
            if not contractor then docksBusy = false; task.wait(2); continue end
            local cRoot = root(contractor)
            if cRoot then safeTP(cRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
            interactWith(contractor); task.wait(0.5)
            if not waitForDialogue(3) then docksBusy = false; task.wait(2); continue end
            if not dockGetQuest() then docksBusy = false; task.wait(2); continue end
            if not dockGetShipment() then docksBusy = false; task.wait(2); continue end
            if cRoot then safeTP(cRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
            if dockTurnIn() then
                for _ = 180, 1, -1 do if not docksEnabled then break end; task.wait(1) end
            else task.wait(2) end
            GuiService.SelectedObject = nil
            GuiService.GuiNavigationEnabled = false
            GuiService.AutoSelectGuiEnabled = false
            docksBusy = false
            task.wait(1)
        end
        GuiService.SelectedObject = nil
        GuiService.GuiNavigationEnabled = false
        GuiService.AutoSelectGuiEnabled = false
    end

    QuestTab:CreateToggle({
        Name = "Docks Delivery", CurrentValue = false, Flag = "DocksDelivery",
        Callback = function(state)
            docksEnabled = state
            if state then task.spawn(docksLoop) end
        end,
    })

    -- DEBT COLLECTOR
    QuestTab:CreateSection("Debt Collector")
    QuestTab:CreateLabel("Grade 8+ required")
    local debtEnabled = false
    local debtBusy = false
    local debtAttacking = false
    local debtAttackCon = nil

    local function getDebtTarget()
        local debtFolder = Workspace.NPCS:FindFirstChild("ContractNPCS")
        if not debtFolder then return nil end
        local dc = debtFolder:FindFirstChild("DebtCollector")
        if not dc then return nil end
        for _, child in ipairs(dc:GetChildren()) do
            if child:IsA("Model") then
                local jobID = child:GetAttribute("JobID")
                if jobID and type(jobID) == "number" then return child end
            end
        end
        return nil
    end

    local function stopDebtAttack()
        if debtAttackCon then debtAttackCon:Disconnect(); debtAttackCon = nil end
        debtAttacking = false
    end

    local function startDebtAttack(target)
        if debtAttacking then return end
        debtAttacking = true
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local tHrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
        if hrp and tHrp then hrp.CFrame = tHrp.CFrame end
        debtAttackCon = RS.RenderStepped:Connect(function()
            if not debtAttacking or not target or not target.Parent then return end
            local hum = target:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then stopDebtAttack(); return end
            local char = LP.Character; if not char then return end
            local weapon = char:FindFirstChild("Weapon")
            local humanoid = char:FindFirstChild("Humanoid")
            if weapon and humanoid then
                local wv = weapon.Value
                if wv and wv ~= "" then
                    local wi = RepStore:FindFirstChild("WeaponINFO")
                    if wi then
                        local wd = wi:FindFirstChild(wv)
                        if wd then
                            local anim = wd:FindFirstChild("AttackAnimation1")
                            local animator = humanoid:FindFirstChild("Animator")
                            if anim and animator then
                                local track = animator:LoadAnimation(anim)
                                track:Play(); track:AdjustSpeed(50)
                            end
                        end
                    end
                end
            end
        end)
    end

    local function debtTurnIn()
        local contractor = getNearestNPC(DOCK_NPCS)
        if not contractor then return false end
        local cRoot = root(contractor)
        if cRoot then safeTP(cRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
        interactWith(contractor)
        if not waitForDialogue(3) then return false end
        task.wait(0.3)
        local turnInBtn = scrollAndFind("Turn In", false) or scrollAndFind("Complete", false)
        if not turnInBtn then
            local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
            if ok and scroll then
                local btn3 = scroll:GetChildren()[3]
                if btn3 then turnInBtn = btn3:FindFirstChild("OptionButton") end
            end
        end
        if not turnInBtn then return false end
        safeClick(turnInBtn); task.wait(0.5)
        waitForClose(2)
        return not hasQuest()
    end

    local function debtLoop()
        while debtEnabled do
            if debtBusy then task.wait(0.2); continue end
            debtBusy = true
            if not hasQuest() then
                local contractor = getNearestNPC(DOCK_NPCS)
                if not contractor then debtBusy = false; task.wait(1); continue end
                local cRoot = root(contractor)
                if cRoot then safeTP(cRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
                interactWith(contractor); task.wait(0.5)
                if not waitForDialogue(3) then debtBusy = false; task.wait(1); continue end
                local btn = findButtonByText("Jobs", false)
                if not btn then
                    local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
                    if ok and scroll then
                        local first = scroll:FindFirstChild("Option")
                        if first then btn = first:FindFirstChild("OptionButton") end
                    end
                end
                if btn then safeClick(btn); task.wait(0.5) end
                if not waitForDialogue(3) then debtBusy = false; task.wait(1); continue end
                local questBtn = scrollAndFind("Debt Collector", false)
                if not questBtn then debtBusy = false; task.wait(1); continue end
                safeClick(questBtn); task.wait(0.5)
                waitForClose(2)
            end
            local target = getDebtTarget()
            if not target then debtBusy = false; task.wait(2); continue end
            local tRoot = root(target)
            if tRoot then safeTP(tRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.5) end
            interactWith(target); task.wait(0.5)
            if waitForDialogue(2) then
                local attackBtn = scrollAndFind("Attack", false)
                if not attackBtn then
                    local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
                    if ok and scroll then
                        local btn3 = scroll:GetChildren()[3]
                        if btn3 then attackBtn = btn3:FindFirstChild("OptionButton") end
                    end
                end
                if attackBtn then safeClick(attackBtn); task.wait(0.5); waitForClose(2) end
            end
            startDebtAttack(target)
            for _ = 1, 30 do
                task.wait(1)
                local hum = target:FindFirstChild("Humanoid")
                if not hum or hum.Health <= 0 then break end
            end
            stopDebtAttack()
            if debtTurnIn() then
                for _ = 180, 1, -1 do if not debtEnabled then break end; task.wait(1) end
            else task.wait(2) end
            debtBusy = false; task.wait(1)
        end
        stopDebtAttack()
    end

    QuestTab:CreateToggle({
        Name = "Debt Collector", CurrentValue = false, Flag = "AutoDebt",
        Callback = function(state)
            debtEnabled = state
            if state then task.spawn(debtLoop) end
            if not state then stopDebtAttack() end
        end,
    })

    -- BACK ONLINE
    QuestTab:CreateSection("Back Online")
    QuestTab:CreateLabel("Grade 5+ required")
    local backOnlineEnabled = false
    local backOnlineBusy = false

    local function backOnlineGetQuest()
        local btn = findButtonByText("Jobs", false)
        if not btn then
            local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
            if ok and scroll then
                local first = scroll:FindFirstChild("Option")
                if first then btn = first:FindFirstChild("OptionButton") end
            end
        end
        if not btn then return false end
        safeClick(btn); task.wait(0.5)
        if not waitForDialogue(3) then return false end
        task.wait(0.3)
        local questBtn = scrollAndFind("Back Online", false)
        if not questBtn then return false end
        safeClick(questBtn); task.wait(0.5)
        waitForClose(2)
        return true
    end

    local function findNearbyPirates(position, radius)
        local pirates = {}
        local npcs = Workspace:FindFirstChild("NPCS")
        if not npcs then return pirates end
        for _, child in ipairs(npcs:GetChildren()) do
            if child:IsA("Model") and child.Name == "Twinhook Pirate" then
                local hrp2 = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
                if hrp2 and (hrp2.Position - position).Magnitude <= radius then
                    table.insert(pirates, child)
                end
            end
        end
        return pirates
    end

    local function allPiratesGone(pirates)
        for _, pirate in ipairs(pirates) do
            if pirate and pirate.Parent then return false end
        end
        return true
    end

    local function backOnlineLoop()
        while backOnlineEnabled do
            if backOnlineBusy then task.wait(0.2); continue end
            backOnlineBusy = true
            if not hasQuest() then
                local contractor = getNearestNPC(DOCK_NPCS)
                if not contractor then backOnlineBusy = false; task.wait(1); continue end
                local cRoot = root(contractor)
                if cRoot then safeTP(cRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
                interactWith(contractor); task.wait(0.5)
                if not waitForDialogue(3) then backOnlineBusy = false; task.wait(1); continue end
                if not backOnlineGetQuest() then backOnlineBusy = false; task.wait(1); continue end
            end
            local laptop = Workspace:FindFirstChild("Thrown") and Workspace.Thrown:FindFirstChild("HackingLaptop")
            if not laptop then backOnlineBusy = false; task.wait(2); continue end
            local laptopCF = laptop:GetPivot()
            safeTP(laptopCF * CFrame.new(0, 0, 3)); task.wait(0.3)
            local pirates = findNearbyPirates(laptopCF.Position, 80)
            if #pirates > 0 then
                while backOnlineEnabled and hasQuest() and not allPiratesGone(pirates) do
                    task.wait(1)
                end
            end
            if hasQuest() then
                task.wait(5)
                safeTP(laptopCF * CFrame.new(0, 0, 3)); task.wait(0.3)
                task.wait(1)
                interactWith(laptop); task.wait(0.5)
                if not hasQuest() then
                    for _ = 180, 1, -1 do if not backOnlineEnabled then break end; task.wait(1) end
                else task.wait(2) end
            end
            backOnlineBusy = false; task.wait(1)
        end
    end

    QuestTab:CreateToggle({
        Name = "Back Online", CurrentValue = false, Flag = "BackOnline",
        Callback = function(state)
            backOnlineEnabled = state
            if state then task.spawn(backOnlineLoop) end
        end,
    })

    -- EYE GOUGER
    QuestTab:CreateSection("Eye Gouger")
    QuestTab:CreateLabel("Grade 5+ required")
    local eyeEnabled = false
    local eyeBusy = false

    local function getEyeQuestGiver()
        local faction = LP.Data and LP.Data.Association and LP.Data.Association.Value
        local syndicates = {"Blade Lineage","Kurokumo Clan","The Index","The Middle","The Ring","The Thumb"}
        if faction then
            for _, s in ipairs(syndicates) do
                if faction == s then return Workspace.NPCS:FindFirstChild("Kurokumo Clan Captain") end
            end
        end
        return Workspace.NPCS:FindFirstChild("Hana Association Contractor")
    end

    local function eyeAcceptQuest()
        local giver = getEyeQuestGiver()
        if not giver then return false end
        local gRoot = root(giver)
        if gRoot then safeTP(gRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
        interactWith(giver); task.wait(0.5)
        if not waitForDialogue(3) then return false end
        local opt = findButtonByText("Jobs", false)
        if not opt then
            local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
            if ok and scroll then
                local first = scroll:FindFirstChild("Option")
                if first then opt = first:FindFirstChild("OptionButton") end
            end
        end
        if opt then safeClick(opt); task.wait(0.5) end
        if not waitForDialogue(3) then return false end
        task.wait(0.3)
        local questBtn = scrollAndFind("Eye Gouger", false)
        if not questBtn then waitForClose(2); return false end
        safeClick(questBtn); task.wait(0.5)
        waitForClose(2)
        return true
    end

    local function eyeLoop()
        while eyeEnabled do
            if eyeBusy then task.wait(0.2); continue end
            eyeBusy = true
            if not hasQuest() then
                if not eyeAcceptQuest() then eyeBusy = false; task.wait(15); continue end
            end
            local target = Workspace.NPCS:FindFirstChild("The Eye Gouger")
            if not target then eyeBusy = false; task.wait(2); continue end
            local tRoot = root(target)
            if tRoot then safeTP(tRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.5) end
            interactWith(target); task.wait(0.5)
            if waitForDialogue(2) then
                local attackBtn = scrollAndFind("Attack", false)
                if not attackBtn then
                    local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
                    if ok and scroll then
                        local btn3 = scroll:GetChildren()[3]
                        if btn3 then attackBtn = btn3:FindFirstChild("OptionButton") end
                    end
                end
                if attackBtn then safeClick(attackBtn); task.wait(0.5); waitForClose(2) end
            end
            while eyeEnabled and hasQuest() do task.wait(1) end
            for _ = 180, 1, -1 do if not eyeEnabled then break end; task.wait(1) end
            eyeBusy = false; task.wait(1)
        end
    end

    QuestTab:CreateToggle({
        Name = "Eye Gouger Quest", CurrentValue = false, Flag = "EyeGouger",
        Callback = function(state)
            eyeEnabled = state
            if state then task.spawn(eyeLoop) end
        end,
    })

    -- CONTRABAND TECH
    QuestTab:CreateSection("Contraband Tech")
    QuestTab:CreateLabel("Grade 5+ required")
    local amonEnabled = false
    local amonBusy = false

    local function getAmonQuestGiver()
        local faction = LP.Data and LP.Data.Association and LP.Data.Association.Value
        local syndicates = {"Blade Lineage","Kurokumo Clan","The Index","The Middle","The Ring","The Thumb"}
        if faction then
            for _, s in ipairs(syndicates) do
                if faction == s then return Workspace.NPCS:FindFirstChild("Kurokumo Clan Captain") end
            end
        end
        return Workspace.NPCS:FindFirstChild("Hana Association Contractor")
    end

    local function amonAcceptQuest()
        local giver = getAmonQuestGiver()
        if not giver then return false end
        local gRoot = root(giver)
        if gRoot then safeTP(gRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.3) end
        interactWith(giver); task.wait(0.5)
        if not waitForDialogue(3) then return false end
        local opt = findButtonByText("Jobs", false)
        if not opt then
            local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
            if ok and scroll then
                local first = scroll:FindFirstChild("Option")
                if first then opt = first:FindFirstChild("OptionButton") end
            end
        end
        if opt then safeClick(opt); task.wait(0.5) end
        if not waitForDialogue(3) then return false end
        task.wait(0.3)
        local questBtn = scrollAndFind("Contraband Tech", false)
        if not questBtn then waitForClose(2); return false end
        safeClick(questBtn); task.wait(0.5)
        waitForClose(2)
        return true
    end

    local function amonLoop()
        while amonEnabled do
            if amonBusy then task.wait(0.2); continue end
            amonBusy = true
            if not hasQuest() then
                if not amonAcceptQuest() then amonBusy = false; task.wait(2); continue end
            end
            local target = Workspace.NPCS:FindFirstChild("Shady Person")
            if not target then amonBusy = false; task.wait(2); continue end
            local tRoot = root(target)
            if tRoot then safeTP(tRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.5) end
            interactWith(target); task.wait(0.5)
            if waitForDialogue(2) then
                local attackBtn = scrollAndFind("Attack", false)
                if not attackBtn then
                    local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
                    if ok and scroll then
                        local btn3 = scroll:GetChildren()[3]
                        if btn3 then attackBtn = btn3:FindFirstChild("OptionButton") end
                    end
                end
                if attackBtn then safeClick(attackBtn); task.wait(0.5); waitForClose(2) end
            end
            while amonEnabled and hasQuest() do task.wait(1) end
            for _ = 180, 1, -1 do if not amonEnabled then break end; task.wait(1) end
            amonBusy = false; task.wait(1)
        end
    end

    QuestTab:CreateToggle({
        Name = "Contraband Tech Quest", CurrentValue = false, Flag = "ContrabandTech",
        Callback = function(state)
            amonEnabled = state
            if state then task.spawn(amonLoop) end
        end,
    })

    -- AUTO GRADE UP
    QuestTab:CreateSection("Auto Grade Up")
    QuestTab:CreateLabel("Requires enough Grade Up Points")
    local gradeEnabled = false
    local gradeBusy = false

    local ELEVATOR_POS = Vector3.new(2532.906494, 2518.095703, 2283.699219)
    local GRADE_REQUIREMENTS = {
        [9]=250,[8]=500,[7]=1200,[6]=1300,
        [5]=1500,[4]=1900,[3]=2000,[2]=3000,[1]=0
    }

    local function gradeIsFixer()
        local assoc = LP.Data and LP.Data.Association and LP.Data.Association.Value
        local syndicates = {"Blade Lineage","Kurokumo Clan","The Index","The Middle","The Ring","The Thumb"}
        if assoc then
            for _, s in ipairs(syndicates) do
                if assoc == s then return false end
            end
        end
        return true
    end

    local function gradeCanGradeUp()
        local currentGrade = LP.Data and LP.Data.Grade and LP.Data.Grade.Value
        local gradePoints = LP.Data and LP.Data.GradeUpPoints and LP.Data.GradeUpPoints.Value
        if not currentGrade or not gradePoints then return false end
        local required = GRADE_REQUIREMENTS[currentGrade]
        if currentGrade <= 1 or not required then return false end
        return gradePoints >= required
    end

    local function gradeTalk(npc)
        if not npc or not npc.Parent then return false end
        local nRoot = root(npc)
        if nRoot then safeTP(nRoot.CFrame * CFrame.new(0, 0, 3)); task.wait(0.2) end
        local talk = npc:FindFirstChild("TalkToNPC")
        if talk and talk:IsA("RemoteEvent") then
            pcall(function() talk:FireServer() end)
            return true
        end
        return interactWith(npc)
    end

    local function gradeChoose(text, exact, attempts)
        attempts = attempts or 10
        for _ = 1, attempts do
            if not gradeEnabled or not dialogueIsOpen() then return false end
            local btn = scrollAndFind(text, exact == true)
            if btn and safeClick(btn, 2) then return true end
            task.wait(0.1)
        end
        return false
    end

    local function gradeAnswerQ9()
        local answerMap = {
            ["how many fixer grades are there?"] = "9",
            ["most dangerous time in the city"] = "Every moment",
            ["i have 500 ahn"] = "125",
            ["a bamboo hatted master"] = "13.5",
            ["area leading to the ocean"] = "The Tower",
            ["role of the hana association"] = "Oversees Fixers",
        }

        for _ = 1, 6 do
            if not gradeEnabled then return false end

            local questionText = ""
            local deadline = tick() + 15
            repeat
                local ok, text = pcall(function()
                    local dialogue = LP.PlayerGui:FindFirstChild("Dialogue")
                    if not dialogue then return "" end
                    for _, obj in ipairs(dialogue:GetDescendants()) do
                        if obj.Name == "DialogueText" and obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
                            return obj.Text
                        end
                    end
                    return ""
                end)
                if ok then questionText = text or "" end
                if questionText ~= "" and dialogueIsOpen() then break end
                task.wait(0.2)
            until tick() >= deadline or not gradeEnabled

            if not gradeEnabled or questionText == "" then return false end

            local lowerQuestion = string.lower(questionText)
            local answer = nil
            for needle, candidate in pairs(answerMap) do
                if string.find(lowerQuestion, needle, 1, true) then
                    answer = candidate
                    break
                end
            end
            if not answer then return false end
            if not gradeChoose(answer, false, 12) then return false end
            task.wait(0.5)
        end

        return true
    end

    local function gradeRunExam()
        local examiner = Workspace.NPCS:FindFirstChild("Hana Association Examiner")
        if not examiner then return false end
        local currentGrade = LP.Data and LP.Data.Grade and LP.Data.Grade.Value

        for _ = 1, 20 do
            if not gradeEnabled then return false end
            if not dialogueIsOpen() then gradeTalk(examiner) end
            if waitForDialogue(1.5) then
                if gradeChoose("Let's Begin.", true, 4) or gradeChoose("Begin", false, 4) then break end
            end
            task.wait(0.15)
        end

        if currentGrade == 9 then
            if not gradeAnswerQ9() then return false end
        else
            while gradeEnabled do
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - ELEVATOR_POS).Magnitude <= 20 then break end
                task.wait(0.5)
            end
        end

        while gradeEnabled do
            local elevator = Workspace.NPCS and Workspace.NPCS:FindFirstChild("Elevator")
            if elevator then
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local eRoot = root(elevator) or elevator:FindFirstChildWhichIsA("BasePart", true)
                if hrp and eRoot and (hrp.Position - eRoot.Position).Magnitude > 8 then
                    safeTP(eRoot.CFrame * CFrame.new(0, 0, 2.5))
                end
                if not dialogueIsOpen() then gradeTalk(elevator) end
                if waitForDialogue(1.5) then
                    local took = gradeChoose("Take me back", false, 6)
                    if not took and dialogueIsOpen() then took = gradeChoose("Take", false, 6) end
                    if took then
                        waitForClose(2)
                        return true
                    end
                end
            end
            task.wait(0.4)
        end
        return true
    end

    local function gradeStartUp()
        if not gradeCanGradeUp() then return false end
        local manager
        if gradeIsFixer() then
            manager = Workspace.NPCS:FindFirstChild("Hana Association Manager")
        else
            manager = Workspace.NPCS:FindFirstChild("Questionable Office Manager")
        end
        if not manager then return false end

        for _ = 1, 20 do
            if not gradeEnabled then return false end
            if not dialogueIsOpen() then gradeTalk(manager) end
            if waitForDialogue(1.5) then
                local selected = gradeChoose("I'm here to take the Fixer Grade Evaluation Exam.", true, 5)
                if not selected then selected = gradeChoose("Fixer Grade Evaluation Exam", false, 5) end
                if not selected and not gradeIsFixer() then
                    selected = gradeChoose("I'm here to get my ranking updated.", true, 4)
                end
                if selected then return true end
            end
            task.wait(0.25)
        end
        return false
    end

    local function gradeLoop()
        while gradeEnabled do
            if gradeBusy then task.wait(0.2); continue end
            gradeBusy = true
            local currentGrade = LP.Data and LP.Data.Grade and LP.Data.Grade.Value
            if not currentGrade or currentGrade <= 1 then
                gradeEnabled = false; gradeBusy = false; break
            end
            local isExam = Workspace.NPCS:FindFirstChild("Hana Association Examiner") ~= nil
            if isExam then
                gradeRunExam()
            else
                if not gradeCanGradeUp() then
                    gradeBusy = false; task.wait(10); continue
                end
                gradeStartUp()
            end
            task.wait(5)
            gradeBusy = false
        end
    end

    QuestTab:CreateToggle({
        Name = "Auto Grade Up", CurrentValue = false, Flag = "AutoGradeUp",
        Callback = function(state)
            gradeEnabled = state
            if state then task.spawn(gradeLoop) end
        end,
    })

    -- DEATH SENTENCE
    QuestTab:CreateSection("Death Sentence")
    local dsEnabled = false
    local dsBusy = false

    local function allEnemiesDead()
        local al = Workspace:FindFirstChild("Alive")
        if not al then return true end
        for _, child in ipairs(al:GetChildren()) do
            if child:IsA("Model") and child ~= LP.Character then
                if Players:GetPlayerFromCharacter(child) then continue end
                local hum = child:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local hrp = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
                    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and myHrp and (hrp.Position - myHrp.Position).Magnitude <= 250 then
                        return false
                    end
                end
            end
        end
        return true
    end

    local function dsChoose(text, fallbackText, attempts)
        attempts = attempts or 12
        for _ = 1, attempts do
            if not dsEnabled then return false end
            if not dialogueIsOpen() then return false end
            local btn = scrollAndFind(text, true)
            if not btn and fallbackText then btn = scrollAndFind(fallbackText, false) end
            if btn and safeClick(btn, 2) then return true end
            task.wait(0.12)
        end
        return false
    end

    local function dsClickUntilGone(searchText)
        for _ = 1, 10 do
            if not dsEnabled or not dialogueIsOpen() then break end
            local btn = scrollAndFind(searchText, false)
            if not btn then break end
            safeClick(btn, 2)
            task.wait(0.25)
        end
    end

    local function dsStart()
        local shay = Workspace.NPCS:FindFirstChild("Shay Mu")
        if not shay then return false end
        local sRoot = root(shay)

        for _ = 1, 15 do
            if not dsEnabled then return false end
            if sRoot then safeTP(sRoot.CFrame * CFrame.new(0,0,3)); task.wait(0.25) end

            local talk = shay:FindFirstChild("TalkToNPC")
            if talk and talk:IsA("RemoteEvent") then
                pcall(function() talk:FireServer() end)
            else
                interactWith(shay)
            end

            if waitForDialogue(2.5) then
                if dsChoose("I'm here for glory.", "glory", 4) then break end
            end
            task.wait(0.5)
        end

        if not dsEnabled then return false end
        if not waitForDialogue(3) then return false end
        if not dsChoose("I'm ready.", "ready", 8) then return false end
        waitForClose(2)
        return true
    end

    local function dsFightWaves()
        while dsEnabled do
            while dsEnabled and not allEnemiesDead() do task.wait(1) end
            task.wait(1)
            if not dsEnabled then return end
            if not waitForDialogue(3) then task.wait(2); continue end
            local isLast = false
            pcall(function()
                local t = LP.PlayerGui.Dialogue.MainFrame.DialogueHolder.DialogueText.Text
                isLast = string.find(string.lower(t), "last round") or string.find(string.lower(t), "scrap guy")
            end)
            dsClickUntilGone("more")
            task.wait(2); waitForClose(2)
            if isLast then
                while dsEnabled do
                    local fixer = Workspace.Alive and Workspace.Alive:FindFirstChild("Prosthetic Fixer")
                    if not fixer or not fixer:FindFirstChild("Humanoid") or fixer.Humanoid.Health <= 0 then break end
                    task.wait(1)
                end
                return true
            end
        end
    end

    local function dsLoop()
        while dsEnabled do
            if dsBusy then task.wait(0.2); continue end
            dsBusy = true
            if not dsStart() then dsBusy = false; task.wait(5); continue end
            dsFightWaves()
            task.wait(5)
            dsBusy = false; task.wait(1)
        end
    end

    QuestTab:CreateToggle({
        Name = "Auto Death Sentence", CurrentValue = false, Flag = "AutoDeathSentence",
        Callback = function(state)
            dsEnabled = state
            if state then task.spawn(dsLoop) end
        end,
    })
end

