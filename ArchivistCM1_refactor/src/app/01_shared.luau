-- ============================================================
-- SHARED UTILITIES
-- ============================================================
local function root(c)
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
        or c:FindFirstChild("Torso")
        or c:FindFirstChild("UpperTorso")
end

local function isPlr(c)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == c then return true end
    end
    return false
end

local function isSelf(m) return m == LP.Character end

local function validTarget(m, allowPlrs)
    if not m or not m:IsA("Model") then return false end
    if isSelf(m) then return false end
    local h = m:FindFirstChild("Humanoid")
    if h and h.Health <= 0 then
        if m.Parent and m.Parent.Name == "Alive" then return true end
        return false
    end
    if not h then
        if m.Parent and m.Parent.Name == "Alive" then return true end
        return false
    end
    if isPlr(m) and not allowPlrs then return false end
    return true
end

local function alive() return Workspace:FindFirstChild("Alive") end

local function getNearestNPC(list)
    local c = LP.Character
    if not c then return nil end
    local r = root(c)
    if not r then return nil end
    local f = Workspace:FindFirstChild("NPCS")
    if not f then return nil end
    local best, bestD = nil, math.huge
    for _, npc in ipairs(f:GetChildren()) do
        for _, name in ipairs(list) do
            if npc.Name == name then
                local nr = root(npc)
                if nr then
                    local d = (r.Position - nr.Position).Magnitude
                    if d < bestD then bestD = d; best = npc end
                end
                break
            end
        end
    end
    return best
end

local function interactWith(npc)
    for _, child in ipairs(npc:GetDescendants()) do
        if child:IsA("ProximityPrompt") then
            fireproximityprompt(child)
            return true
        end
    end
    return false
end

local function dialogueIsOpen()
    -- IsTalking is useful when it updates correctly, but some dialogue paths
    -- render their GUI before/without flipping the value. Treat either source
    -- as evidence instead of letting a false BoolValue hide a visible menu.
    local data = LP:FindFirstChild("Data")
    local talking = data and data:FindFirstChild("IsTalking")
    if talking and talking:IsA("BoolValue") and talking.Value == true then
        return true
    end

    local ok, visible = pcall(function()
        local dialogue = LP.PlayerGui:FindFirstChild("Dialogue")
        local main = dialogue and dialogue:FindFirstChild("MainFrame")
        if not dialogue or not main then return false end
        if dialogue:IsA("ScreenGui") and dialogue.Enabled == false then return false end
        if main:IsA("GuiObject") and main.Visible == false then return false end

        -- Prefer an actually visible option/dialogue element over the mere
        -- existence of MainFrame (which can stay mounted while dialogue is off).
        for _, obj in ipairs(main:GetDescendants()) do
            if obj:IsA("TextButton") and obj.Name == "OptionButton" and obj.Visible then
                return true
            end
            if obj.Name == "DialogueText" and obj:IsA("TextLabel") and obj.Visible and obj.Text ~= "" then
                return true
            end
        end
        return false
    end)
    return ok and visible or false
end

local function clickButton(btn)
    if not btn or not btn.Parent or not btn:IsA("GuiButton") then return false end

    local okScroll, scroll = pcall(function()
        return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll
    end)
    if not okScroll or not scroll or not btn:IsDescendantOf(scroll) then return false end

    local function dialogueSignature()
        local ok, liveScroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
        if not ok or not liveScroll then return "closed" end

        local texts = {}
        for _, child in ipairs(liveScroll:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible then
                local opt = child:FindFirstChild("OptionText")
                if opt and (opt:IsA("TextLabel") or opt:IsA("TextButton")) then
                    table.insert(texts, opt.Text)
                elseif opt and opt:IsA("StringValue") then
                    table.insert(texts, opt.Value)
                elseif child:IsA("TextButton") then
                    table.insert(texts, child.Text)
                end
            end
        end
        table.sort(texts)

        local dialogueText = ""
        pcall(function()
            local holder = LP.PlayerGui.Dialogue.MainFrame:FindFirstChild("DialogueHolder")
            local label = holder and holder:FindFirstChild("DialogueText")
            if label and label:IsA("TextLabel") then dialogueText = label.Text or "" end
        end)

        return dialogueText .. "\30" .. table.concat(texts, "\31")
    end

    local before = dialogueSignature()

    local function clearDialogueNav()
        pcall(function()
            GuiService.SelectedObject = nil
            GuiService.GuiNavigationEnabled = false
            GuiService.AutoSelectGuiEnabled = false
        end)
        task.defer(function()
            task.wait()
            pcall(function()
                GuiService.SelectedObject = nil
                GuiService.GuiNavigationEnabled = false
                GuiService.AutoSelectGuiEnabled = false
            end)
        end)
    end

    -- One activation path everywhere: select the live dialogue button directly,
    -- press Return with the same timings used by the working Library flow, then
    -- clear navigation state immediately after the choice.
    local selected = pcall(function()
        GuiService.AutoSelectGuiEnabled = false
        GuiService.GuiNavigationEnabled = true
        GuiService.SelectedObject = btn
    end)
    if not selected then
        clearDialogueNav()
        return false
    end

    task.wait(0.1)
    local stillValid = btn.Parent ~= nil
        and btn.Visible
        and btn:IsDescendantOf(scroll)
        and GuiService.SelectedObject == btn
    if not stillValid then
        clearDialogueNav()
        return false
    end

    VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
    task.wait(0.2)
    VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    task.wait(0.3)
    clearDialogueNav()

    local deadline = tick() + 0.9
    repeat
        if not dialogueIsOpen() then return true end
        if dialogueSignature() ~= before then return true end
        task.wait(0.03)
    until tick() >= deadline

    return false
end

local function waitForDialogue(t)
    t = t or 3
    local deadline = tick() + t
    repeat
        if dialogueIsOpen() then
            task.wait(0.12)
            return true
        end
        task.wait(0.1)
    until tick() >= deadline
    return false
end

local function waitForClose(t)
    t = t or 2
    local deadline = tick() + t
    repeat
        if not dialogueIsOpen() then return true end
        task.wait(0.1)
    until tick() >= deadline
    return false
end

local function hasQuest()
    local c = LP.Character
    if not c then return false end
    return c:FindFirstChild("QuestInProgress") ~= nil
end

local function findButtonByText(searchText, exact)
    local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
    if not ok or not scroll then return nil end
    searchText = string.lower(tostring(searchText or ""))

    for _, button in ipairs(scroll:GetDescendants()) do
        if button:IsA("TextButton") and button.Name == "OptionButton" and button.Visible then
            local text = ""
            local holder = button.Parent
            local optionText = holder and holder:FindFirstChild("OptionText")
            if optionText and (optionText:IsA("TextLabel") or optionText:IsA("TextButton")) then
                text = optionText.Text or ""
            elseif optionText and optionText:IsA("StringValue") then
                text = optionText.Value or ""
            else
                local label = button:FindFirstChildOfClass("TextLabel")
                text = (label and label.Text) or button.Text or ""
            end

            local candidate = string.lower(text)
            if (exact and candidate == searchText)
                or (not exact and string.find(candidate, searchText, 1, true)) then
                return button
            end
        end
    end
    return nil
end

local function scrollAndFind(searchText, exact)
    local ok, scroll = pcall(function() return LP.PlayerGui.Dialogue.MainFrame.Options.Scroll end)
    if not ok or not scroll then return nil end
    local btn = findButtonByText(searchText, exact)
    if btn then return btn end
    local maxScroll = scroll.CanvasSize.Y.Offset or 600
    for pos = 0, maxScroll, 50 do
        scroll.CanvasPosition = Vector2.new(0, pos)
        task.wait(0.15)
        btn = findButtonByText(searchText, exact)
        if btn then return btn end
    end
    return nil
end

local function safeClick(btn, retries)
    retries = retries or 3
    for _ = 1, retries do
        if btn and btn.Parent and clickButton(btn) then
            task.wait(0.18)
            return true
        end
        task.wait(0.1)
    end
    return false
end

local function safeTP(cf)
    if not cf then return false end
    local c = LP.Character; if not c then return false end
    local r = root(c); if not r then return false end
    r.CFrame = cf; return true
end

local function pressV()
    VIM:SendKeyEvent(true,  Enum.KeyCode.V, false, game); task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.V, false, game)
end

local DOCK_NPCS = {"Office Contractor","Questionable Office Contractor","Shady Office Contractor"}

