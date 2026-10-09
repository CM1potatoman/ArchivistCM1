-- ============================================================
-- LOCK-ON TAB
-- ============================================================
local LockonTab = CombatTab -- merged into Combat

do
    local lkTarget, lkPart = nil, nil
    local lkLocked = false
    local lkCircle = Drawing.new("Circle")
    lkCircle.Visible = false; lkCircle.Radius = S.LockonFOV
    lkCircle.Color = Color3.new(1,1,1); lkCircle.Thickness = 1
    lkCircle.Filled = false; lkCircle.NumSides = 64

    local function validLk(obj)
        if not obj or not obj:IsA("Model") or isSelf(obj) then return false end
        local h = obj:FindFirstChild("Humanoid")
        if not h or h.Health <= 0 then return false end
        local ip = isPlr(obj)
        if S.LockonFilter == "NPCs Only" and ip then return false end
        if S.LockonFilter == "Players Only" and not ip then return false end
        return true
    end

    local function lkGetPart(obj)
        if not obj then return nil end
        if S.LockonPart == "Head" then return obj:FindFirstChild("Head") or root(obj) end
        if S.LockonPart == "Torso" then return obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso") or root(obj) end
        return root(obj)
    end

    local function lkFindTarget()
        local al = alive(); if not al then return nil end
        local isCam = S.LockonMode == "Camera"
        local isDist = S.LockonMode == "Distance"
        local mouse = not isCam and not isDist and UIS:GetMouseLocation()
        local center = isCam and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local myRoot = isDist and root(LP.Character)
        local best, bestD = nil, isDist and math.huge or S.LockonFOV
        for _, obj in ipairs(al:GetChildren()) do
            if not validLk(obj) then continue end
            local part = lkGetPart(obj); if not part then continue end
            if isDist then
                if not myRoot then continue end
                local d = (myRoot.Position - part.Position).Magnitude
                if d < bestD then bestD = d; best = obj end
            else
                local sp, on = Camera:WorldToViewportPoint(part.Position)
                if not on then continue end
                local ref = isCam and center or mouse
                local d = (Vector2.new(sp.X, sp.Y) - ref).Magnitude
                if d <= S.LockonFOV and d < bestD then bestD = d; best = obj end
            end
        end
        return best
    end

    local function toggleLk()
        if lkLocked then
            lkLocked = false; lkTarget = nil; lkPart = nil
        else
            lkTarget = lkFindTarget()
            if lkTarget then lkPart = lkGetPart(lkTarget); lkLocked = true end
        end
    end

    RS.RenderStepped:Connect(function()
        local show = S.LockonShowFOV and S.LockonEnabled
        lkCircle.Visible = show
        if show then
            lkCircle.Radius = S.LockonFOV
            lkCircle.Color = lkLocked and Color3.new(1,0,0) or Color3.new(1,1,1)
            lkCircle.Position = S.LockonMode == "Cursor"
                and UIS:GetMouseLocation()
                or Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        end
        if S.LockonEnabled then
            if S.LockonAuto and not lkLocked then
                local t = lkFindTarget()
                if t then lkTarget = t; lkPart = lkGetPart(t); lkLocked = true end
            end
            if lkLocked and lkTarget and lkPart and lkPart.Parent then
                if not validLk(lkTarget) then
                    lkLocked = false; lkTarget = nil; lkPart = nil
                else
                    lkPart = lkGetPart(lkTarget)
                    if lkPart then
                        local tp = lkPart.Position; local cp = Camera.CFrame.Position
                        if S.LockonStrength >= 100 then
                            local tcf = CFrame.lookAt(cp, tp)
                            Camera.CFrame = S.LockonSmooth and Camera.CFrame:Lerp(tcf, S.LockonSmoothness) or tcf
                        elseif S.LockonStrength > 0 then
                            local ml = Camera.CFrame.LookVector:Lerp((tp - cp).Unit, S.LockonStrength/100)
                            Camera.CFrame = CFrame.lookAt(cp, cp + ml)
                        end
                    else lkLocked = false; lkTarget = nil end
                end
            elseif lkLocked then lkLocked = false; lkTarget = nil; lkPart = nil end
        end
    end)

    LockonTab:CreateSection("Lock-On Settings")
    LockonTab:CreateToggle({ Name = "Lock-On", CurrentValue=false, Flag="Lockon",
        Callback = function(state)
            S.LockonEnabled = state
            if not state then lkLocked = false; lkTarget = nil end
        end })
    LockonTab:CreateKeybind({ Name = "Toggle Lock-On Key", CurrentKeybind = "Q",
        HoldToInteract = false, Flag = "LockonKey",
        Callback = function() if S.LockonEnabled then toggleLk() end end })
    LockonTab:CreateSlider({ Name = "Lock-On FOV", Range={10,200}, Increment=5,
        CurrentValue=45, Flag="LockonFOV", Callback = function(v) S.LockonFOV = v end })
    LockonTab:CreateDropdown({ Name = "Lock-On Mode", Options={"Cursor","Camera","Distance"},
        CurrentOption={"Cursor"}, MultipleOptions=false, Flag="LockonMode",
        Callback = function(v) S.LockonMode = type(v)=="table" and v[1] or v end })
    LockonTab:CreateDropdown({ Name = "Target Filter", Options={"All","NPCs Only","Players Only"},
        CurrentOption={"All"}, MultipleOptions=false, Flag="LockonFilter",
        Callback = function(v) S.LockonFilter = type(v)=="table" and v[1] or v end })
    LockonTab:CreateSlider({ Name = "Strength", Range={0,100}, Increment=5,
        CurrentValue=80, Flag="LockonStrength", Callback = function(v) S.LockonStrength = v end })
    LockonTab:CreateToggle({ Name = "Smooth Camera", CurrentValue=true, Flag="LockonSmooth",
        Callback = function(state) S.LockonSmooth = state end })
    LockonTab:CreateToggle({ Name = "Auto Lock", CurrentValue=false, Flag="LockonAuto",
        Callback = function(state) S.LockonAuto = state end })
    LockonTab:CreateToggle({ Name = "Show FOV Circle", CurrentValue=true, Flag="LockonFOVCircle",
        Callback = function(state) S.LockonShowFOV = state end })
end

