-- ============================================================
-- CHARACTER TAB
-- ============================================================
local CharTab = Window:CreateTab("Character", 10726204364)

do
    local ragdollConn = nil
    local staminaConn = nil
    local staminaValue = nil
    local staminaLast = nil
    local staminaWriting = false
    local dashConn = nil
    local dashWaitConn = nil
    local dashValue = nil
    local dashOriginal = nil
    local cooldownChildConn = nil
    local cooldownAttrConns = {}
    local fallRecords = setmetatable({}, {__mode = "k"})
    local ragTags = {Ragdolled=true, Ragdoll=true, IsRagdoll=true, KnockedDown=true, Stunned=true, DashDisabled=true}

    local function localCharacterModel()
        local al = alive()
        return (al and al:FindFirstChild(LP.Name)) or LP.Character
    end

    local function disconnect(conn)
        if conn then pcall(function() conn:Disconnect() end) end
    end

    -- Character movement uses the same simple BodyVelocity/BodyGyro pattern
    -- used by the other two source bases, but keeps exact collision state so
    -- turning Noclip off does not force every limb to CanCollide=true.
    local charFlyConn = nil
    local charFlyBV, charFlyBG = nil, nil
    local charFlyHumanoid = nil
    local charNoclipConn = nil
    local charNoclipAddedConn = nil
    local charNoclipCharacter = nil
    local charNoclipStates = setmetatable({}, {__mode = "k"})

    local function stopCharacterFly()
        disconnect(charFlyConn); charFlyConn = nil
        if charFlyBV then pcall(function() charFlyBV:Destroy() end); charFlyBV = nil end
        if charFlyBG then pcall(function() charFlyBG:Destroy() end); charFlyBG = nil end
        if charFlyHumanoid and charFlyHumanoid.Parent then
            pcall(function() charFlyHumanoid.PlatformStand = false end)
        end
        charFlyHumanoid = nil
    end

    local function startCharacterFly()
        stopCharacterFly()
        if not S.FlyEnabled then return end
        charFlyConn = RS.Heartbeat:Connect(function()
            if not S.FlyEnabled then return end
            local character = LP.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local hrp = root(character)
            if not humanoid or not hrp then return end
            charFlyHumanoid = humanoid
            humanoid.PlatformStand = true

            if not charFlyBV or charFlyBV.Parent ~= hrp then
                if charFlyBV then pcall(function() charFlyBV:Destroy() end) end
                charFlyBV = Instance.new("BodyVelocity")
                charFlyBV.Name = "ArchivistFlyVelocity"
                charFlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                charFlyBV.P = 1e4
                charFlyBV.Parent = hrp
            end
            if not charFlyBG or charFlyBG.Parent ~= hrp then
                if charFlyBG then pcall(function() charFlyBG:Destroy() end) end
                charFlyBG = Instance.new("BodyGyro")
                charFlyBG.Name = "ArchivistFlyGyro"
                charFlyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                charFlyBG.P = 1e4
                charFlyBG.Parent = hrp
            end

            local camera = Workspace.CurrentCamera
            local direction = Vector3.zero
            if camera then
                if UIS:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.yAxis end
                charFlyBG.CFrame = camera.CFrame
            end
            charFlyBV.Velocity = direction.Magnitude > 0 and direction.Unit * S.FlySpeed or Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    local function stopCharacterNoclip()
        disconnect(charNoclipConn); charNoclipConn = nil
        disconnect(charNoclipAddedConn); charNoclipAddedConn = nil
        charNoclipCharacter = nil
        for part, original in pairs(charNoclipStates) do
            if part and part.Parent then pcall(function() part.CanCollide = original end) end
        end
        table.clear(charNoclipStates)
    end

    local function startCharacterNoclip()
        stopCharacterNoclip()
        if not S.NoclipEnabled then return end
        local function watchPart(part)
            if not part:IsA("BasePart") then return end
            if charNoclipStates[part] == nil then charNoclipStates[part] = part.CanCollide end
            if part.CanCollide then part.CanCollide = false end
        end
        local function watchCharacter(character)
            if charNoclipCharacter == character then return end
            disconnect(charNoclipAddedConn); charNoclipAddedConn = nil
            for part, original in pairs(charNoclipStates) do
                if part and part.Parent then pcall(function() part.CanCollide = original end) end
            end
            table.clear(charNoclipStates)
            charNoclipCharacter = character
            if not character then return end
            for _, part in ipairs(character:GetDescendants()) do watchPart(part) end
            charNoclipAddedConn = character.DescendantAdded:Connect(watchPart)
        end
        watchCharacter(LP.Character)
        charNoclipConn = RS.Stepped:Connect(function()
            if not S.NoclipEnabled then return end
            if LP.Character ~= charNoclipCharacter then watchCharacter(LP.Character) end
            -- Iterate cached parts, not the entire avatar hierarchy every frame.
            for part in pairs(charNoclipStates) do
                if part.Parent and part:IsDescendantOf(charNoclipCharacter) and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end

    local function clearRagdollObject(child)
        if not child or not ragTags[child.Name] then return end
        pcall(function()
            if child:IsA("BoolValue") then
                child.Value = false
            elseif child:IsA("StringValue") or child:IsA("ObjectValue") then
                child:Destroy()
            end
        end)
    end

    local function bindNoRagdoll()
        disconnect(ragdollConn)
        ragdollConn = nil
        if not S.NoRagdollEnabled then return end
        local c = localCharacterModel()
        if not c then return end
        for _, child in ipairs(c:GetChildren()) do clearRagdollObject(child) end
        ragdollConn = c.ChildAdded:Connect(function(child)
            if S.NoRagdollEnabled then clearRagdollObject(child) end
        end)
    end

    local function ensureNoFall()
        if not S.NoFallEnabled then return end
        local c = localCharacterModel()
        if not c then return end
        local rec = fallRecords[c]
        if rec and (not rec.marker or not rec.marker.Parent) then
            fallRecords[c] = nil
            rec = nil
        end
        if not rec then
            local marker = c:FindFirstChild("NoFallDamage")
            if marker and marker:IsA("BoolValue") then
                rec = {marker = marker, created = false, original = marker.Value}
            elseif not marker then
                marker = Instance.new("BoolValue")
                marker.Name = "NoFallDamage"
                marker.Value = true
                marker.Parent = c
                rec = {marker = marker, created = true, original = nil}
            else
                return
            end
            fallRecords[c] = rec
        end
        if rec.marker and rec.marker.Parent and rec.marker:IsA("BoolValue") then
            rec.marker.Value = true
        end
    end

    local function restoreNoFall()
        for _, rec in pairs(fallRecords) do
            local marker = rec.marker
            if marker and marker.Parent then
                pcall(function()
                    if rec.created then marker:Destroy()
                    elseif marker:IsA("BoolValue") then marker.Value = rec.original end
                end)
            end
        end
        table.clear(fallRecords)
    end

    local function unbindStamina()
        disconnect(staminaConn)
        staminaConn = nil
        staminaValue = nil
        staminaLast = nil
        staminaWriting = false
    end

    local function bindStamina()
        unbindStamina()
        if not S.NoStaminaEnabled then return end
        local data = LP:FindFirstChild("Data")
        local st = data and data:FindFirstChild("Stamina")
        if not st or not st:IsA("ValueBase") then return end
        staminaValue = st
        staminaLast = st.Value
        staminaConn = st:GetPropertyChangedSignal("Value"):Connect(function()
            if not S.NoStaminaEnabled or staminaWriting or staminaValue ~= st then return end
            local value = st.Value
            if value < staminaLast then
                staminaWriting = true
                pcall(function() st.Value = staminaLast end)
                staminaWriting = false
            else
                staminaLast = value
            end
        end)
    end

    local function unbindDash(restore)
        disconnect(dashConn)
        disconnect(dashWaitConn)
        dashConn, dashWaitConn = nil, nil
        if restore and dashValue and dashValue.Parent and dashOriginal ~= nil then
            pcall(function() dashValue.Value = dashOriginal end)
        end
        dashValue, dashOriginal = nil, nil
    end

    local function bindDash()
        unbindDash(false)
        if not S.NoDashCDEnabled then return end
        local data = LP:FindFirstChild("Data")
        if not data then return end
        local haste = data:FindFirstChild("HasteStacks")
        if not haste or not haste:IsA("ValueBase") then
            dashWaitConn = data.ChildAdded:Connect(function(child)
                if S.NoDashCDEnabled and child.Name == "HasteStacks" then
                    task.defer(bindDash)
                end
            end)
            return
        end
        dashValue = haste
        dashOriginal = haste.Value
        pcall(function() haste.Value = 99 end)
        dashConn = haste:GetPropertyChangedSignal("Value"):Connect(function()
            if S.NoDashCDEnabled and dashValue == haste and haste.Value ~= 99 then
                pcall(function() haste.Value = 99 end)
            end
        end)
    end

    local function clearKnownCooldowns(c)
        if not c then return end
        local gunCD = c:FindFirstChild("GunFireCD")
        if gunCD then pcall(function() gunCD:Destroy() end) end
        for _, attr in ipairs({"IsSwinging", "CurrentM1"}) do
            if c:GetAttribute(attr) ~= nil then
                pcall(function() c:SetAttribute(attr, nil) end)
            end
        end
    end

    local function unbindCooldowns()
        disconnect(cooldownChildConn)
        cooldownChildConn = nil
        for _, conn in ipairs(cooldownAttrConns) do disconnect(conn) end
        table.clear(cooldownAttrConns)
    end

    local function bindCooldowns()
        unbindCooldowns()
        globalNoCooldowns = S.NoCooldownsEnabled
        if not S.NoCooldownsEnabled then return end
        local c = localCharacterModel()
        if not c then return end
        clearKnownCooldowns(c)
        cooldownChildConn = c.ChildAdded:Connect(function(child)
            if S.NoCooldownsEnabled and child.Name == "GunFireCD" then
                task.defer(function()
                    if S.NoCooldownsEnabled and child.Parent then pcall(function() child:Destroy() end) end
                end)
            end
        end)
        for _, attr in ipairs({"IsSwinging", "CurrentM1"}) do
            table.insert(cooldownAttrConns, c:GetAttributeChangedSignal(attr):Connect(function()
                if S.NoCooldownsEnabled and c:GetAttribute(attr) ~= nil then
                    pcall(function() c:SetAttribute(attr, nil) end)
                end
            end))
        end
    end

    CharTab:CreateSection("Movement")
    local FlyToggle = CharTab:CreateToggle({ Name = "Fly", CurrentValue=false, Flag="CharacterFly",
        Callback = function(state)
            S.FlyEnabled = state
            if state then startCharacterFly() else stopCharacterFly() end
        end })
    CharTab:CreateKeybind({ Name = "Fly Key", CurrentKeybind = "F", HoldToInteract = false, Flag = "CharacterFlyKey",
        Callback = function() FlyToggle:Set(not S.FlyEnabled) end })
    CharTab:CreateSlider({ Name = "Fly Speed", Range={20,250}, Increment=5,
        CurrentValue=70, Flag="CharacterFlySpeed", Callback = function(v) S.FlySpeed = v end })

    local NoclipToggle = CharTab:CreateToggle({ Name = "Noclip", CurrentValue=false, Flag="CharacterNoclip",
        Callback = function(state)
            S.NoclipEnabled = state
            if state then startCharacterNoclip() else stopCharacterNoclip() end
        end })
    CharTab:CreateKeybind({ Name = "Noclip Key", CurrentKeybind = "N", HoldToInteract = false, Flag = "CharacterNoclipKey",
        Callback = function() NoclipToggle:Set(not S.NoclipEnabled) end })
    CharTab:CreateLabel("Fly: WASD + Space/LeftShift | Noclip restores original collision states")

    local TPWalkToggle = CharTab:CreateToggle({ Name = "TP Walk", CurrentValue=false, Flag="TPWalk",
        Callback = function(state) CharacterValues.tpwalk = state end })
    CharTab:CreateKeybind({ Name = "TP Walk Key", CurrentKeybind = "G", HoldToInteract = false, Flag = "TPWalkKey",
        Callback = function() TPWalkToggle:Set(not CharacterValues.tpwalk) end })
    CharTab:CreateSlider({ Name = "TP Walk Speed", Range={1,15}, Increment=1,
        CurrentValue=1, Flag="TPWalkSpeed", Callback = function(v) CharacterValues.tpwalknum = v end })

    local InfJumpToggle = CharTab:CreateToggle({ Name = "Infinite Jump", CurrentValue=false, Flag="InfJump",
        Callback = function(state) CharacterValues.infjump = state end })
    CharTab:CreateKeybind({ Name = "Infinite Jump Key", CurrentKeybind = "I", HoldToInteract = false, Flag = "InfJumpKey",
        Callback = function() InfJumpToggle:Set(not CharacterValues.infjump) end })

    CharTab:CreateToggle({ Name = "Warp Dash (Long Dash)", CurrentValue=false, Flag="WarpDash",
        Callback = function(state) S.WarpDashEnabled = state end })
    CharTab:CreateLabel("Warp Dash is kept as an experimental long-dash helper.")
    CharTab:CreateToggle({ Name = "Haste Stacks", CurrentValue=false, Flag="Haste",
        Callback = function(state) S.HasteEnabled = state end })

    CharTab:CreateSection("Defense")
    CharTab:CreateToggle({ Name = "No Ragdoll", CurrentValue=false, Flag="NoRagdoll",
        Callback = function(state)
            S.NoRagdollEnabled = state
            bindNoRagdoll()
        end })
    CharTab:CreateToggle({ Name = "No Fall Damage", CurrentValue=false, Flag="NoFall",
        Callback = function(state)
            S.NoFallEnabled = state
            if state then ensureNoFall() else restoreNoFall() end
        end })
    CharTab:CreateToggle({ Name = "No Stamina Drain", CurrentValue=false, Flag="NoStamina",
        Callback = function(state)
            S.NoStaminaEnabled = state
            if state then bindStamina() else unbindStamina() end
        end })
    CharTab:CreateToggle({ Name = "No Dash Cooldown", CurrentValue=false, Flag="NoDashCD",
        Callback = function(state)
            S.NoDashCDEnabled = state
            if state then bindDash() else unbindDash(true) end
        end })
    CharTab:CreateToggle({ Name = "No Cooldowns", CurrentValue=false, Flag="NoCooldowns",
        Callback = function(state)
            S.NoCooldownsEnabled = state
            globalNoCooldowns = state
            if state then bindCooldowns() else unbindCooldowns() end
        end })

    CharTab:CreateSection("Misc")
    CharTab:CreateToggle({ Name = "Permanent EXP Bar", CurrentValue=false, Flag="PermExp",
        Callback = function(state)
            QolValues.permexp = state
            if not state then
                pcall(function()
                    LP.PlayerGui.Stats.UI.GradeSlider.Visible = false
                end)
            end
        end })

    task.spawn(function()
        while true do
            local delta = RS.Heartbeat:Wait()
            if CharacterValues.tpwalk then
                if LP.Character and LP.Character:FindFirstChild("Humanoid")
                    and LP.Character.Humanoid.MoveDirection.Magnitude > 0 then
                    LP.Character:TranslateBy(LP.Character.Humanoid.MoveDirection * CharacterValues.tpwalknum * delta * 10)
                end
            end
        end
    end)

    UIS.JumpRequest:Connect(function()
        if CharacterValues.infjump then
            local hum = LP.Character and LP.Character:FindFirstChildWhichIsA("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    -- Legacy stack helpers are throttled; the defense toggles above are event-driven.
    task.spawn(function()
        while true do
            local active = S.NoFallEnabled or S.HasteEnabled or S.WarpDashEnabled
            task.wait(active and 0.1 or 0.5)
            if S.NoFallEnabled then ensureNoFall() end
            if S.HasteEnabled then
                local d = LP:FindFirstChild("Data")
                local b = d and d:FindFirstChild("HasteStacks")
                if b and b:IsA("ValueBase") and b.Value ~= 99 then b.Value = 99 end
            end
            if S.WarpDashEnabled then
                local d = LP:FindFirstChild("Data")
                local b = d and d:FindFirstChild("WarpDashStacks")
                if b and b:IsA("ValueBase") and b.Value ~= 1 then b.Value = 1 end
            end
        end
    end)

    -- One respawn listener owns all character-feature rebinding.
    LP.CharacterAdded:Connect(function()
        task.wait(0.3)
        if S.FlyEnabled then startCharacterFly() end
        if S.NoclipEnabled then startCharacterNoclip() end
        if S.NoRagdollEnabled then bindNoRagdoll() end
        if S.NoFallEnabled then ensureNoFall() end
        if S.NoStaminaEnabled then bindStamina() end
        if S.NoDashCDEnabled then bindDash() end
        if S.NoCooldownsEnabled then bindCooldowns() end
    end)
end

