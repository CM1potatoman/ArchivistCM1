-- ============================================================
-- MISC TAB
-- ============================================================
local MiscTab = InventoryTab -- merged into Utilities

do
    local TARGET_PLAYERS = 5
    local PREFERRED_REGIONS = {"US","EU","ASIA","SA","OCE"}
    local REGION_MAP = {
        Frankfurt="EU",London="EU",Paris="EU",Amsterdam="EU",Warsaw="EU",
        Singapore="ASIA",Tokyo="ASIA",["Hong Kong"]="ASIA",Mumbai="ASIA",
        Sydney="OCE",["Sao Paulo"]="SA",Santiago="SA",
        Ashburn="US",Chicago="US",Dallas="US",["Los Angeles"]="US",
        Miami="US",["New York"]="US",Portland="US",["San Jose"]="US",Atlanta="US",
    }
    local function getServers()
        local servers = RepStore:FindFirstChild("Servers"); if not servers then return {} end
        local list = {}
        for _, s in ipairs(servers:GetChildren()) do
            local regionRaw = s:GetAttribute("ServerRegion") or "Unknown"
            local region = REGION_MAP[regionRaw] or regionRaw
            table.insert(list,{Name=s.Name,Players=s:GetAttribute("Players") or 999,Region=region})
        end
        return list
    end
    local function getRegionPriority(region)
        for i, r in ipairs(PREFERRED_REGIONS) do if region == r then return i end end
        return 99
    end
    local function findBestServer(maxPlayers)
        local servers = getServers(); local valid = {}
        for _, s in ipairs(servers) do if s.Players <= maxPlayers then table.insert(valid, s) end end
        if #valid == 0 then return nil end
        table.sort(valid, function(a,b)
            if a.Players ~= b.Players then return a.Players < b.Players end
            return getRegionPriority(a.Region) < getRegionPriority(b.Region)
        end)
        return valid[1]
    end
    local function joinServer(name)
        local joinEvent = RepStore:FindFirstChild("Events") and RepStore.Events:FindFirstChild("JoinServer")
        if joinEvent then joinEvent:FireServer(name) end
    end

    MiscTab:CreateSection("Server Utilities")
    MiscTab:CreateSlider({
        Name = "Target Player Count", Range = {1, 20}, Increment = 1,
        Suffix = " players", CurrentValue = 5, Flag = "TargetPlayers",
        Callback = function(v) TARGET_PLAYERS = v end,
    })
    MiscTab:CreateButton({
        Name = "Join Low-Pop Server",
        Callback = function()
            local best = findBestServer(TARGET_PLAYERS) or findBestServer(8)
            if not best then
                local all = getServers()
                table.sort(all, function(a,b) return a.Players < b.Players end)
                best = all[1]
            end
            if best then joinServer(best.Name) end
        end,
    })

    MiscTab:CreateSection("Background Music")
    local archivistMusic = Instance.new("Sound")
    archivistMusic.Name = "ArchivistBackgroundMusic"
    archivistMusic.Looped = true
    archivistMusic.Volume = 0.35
    archivistMusic.Parent = SoundService
    local musicAssetId = ""
    local musicEnabled = false
    local function applyMusic()
        if musicAssetId ~= "" then
            local numeric = musicAssetId:match("%d+")
            archivistMusic.SoundId = numeric and ("rbxassetid://" .. numeric) or musicAssetId
        end
        if musicEnabled and archivistMusic.SoundId ~= "" then
            pcall(function() archivistMusic:Play() end)
        else
            pcall(function() archivistMusic:Stop() end)
        end
    end
    MiscTab:CreateInput({
        Name = "Music Asset ID", PlaceholderText = "Roblox audio asset ID",
        RemoveTextAfterFocusLost = false, Flag = "ArchivistMusicId",
        Callback = function(text) musicAssetId = tostring(text or ""); applyMusic() end,
    })
    MiscTab:CreateSlider({
        Name = "Music Volume", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.35, Flag = "ArchivistMusicVolume",
        Callback = function(v) archivistMusic.Volume = v end,
    })
    MiscTab:CreateToggle({
        Name = "Background Music", CurrentValue = false, Flag = "ArchivistMusicEnabled",
        Callback = function(state) musicEnabled = state; applyMusic() end,
    })
    MiscTab:CreateLabel("Optional custom music; Archivist does not force a copyrighted OST ID.")

    MiscTab:CreateSection("Chains of Loyalty Instakill [BETA]")
    local CHAINS_UP   = Vector3.new(-1436.345825, 3118.359863, 313.909546)
    local CHAINS_DOWN = Vector3.new(-1409.645996,  875.399841, 434.929077)
    local chainsGoing = false

    local function doChains()
        if chainsGoing then return end
        chainsGoing = true
        local c = LP.Character; if not c then chainsGoing=false; return end
        local r = root(c); if not r then chainsGoing=false; return end
        task.wait(S.ChainsGlideDelay)
        c = LP.Character; r = root(c); if not r then chainsGoing=false; return end
        local hum = c:FindFirstChild("Humanoid")
        local cFly = {}
        if r and hum then
            local bg = Instance.new("BodyGyro")
            bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.CFrame=r.CFrame; bg.Parent=r
            table.insert(cFly, bg)
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Velocity=Vector3.zero; bv.Parent=r
            table.insert(cFly, bv)
            hum.PlatformStand = true
        end
        local startCF = r.CFrame
        for i = 1, 20 do
            c = LP.Character; r = root(c); if not r then break end
            r.CFrame = startCF:Lerp(CFrame.new(CHAINS_UP), i/20)
            r.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.01)
        end
        task.wait(S.ChainsFloatDuration)
        c = LP.Character; r = root(c)
        if r then r.CFrame = CFrame.new(CHAINS_DOWN); r.AssemblyLinearVelocity = Vector3.zero end
        for _,p in ipairs(cFly) do pcall(p.Destroy, p) end
        c = LP.Character
        if c then local h = c:FindFirstChild("Humanoid"); if h then h.PlatformStand = false end end
        chainsGoing = false
    end

    MiscTab:CreateToggle({Name="Enable", CurrentValue=S.ChainsInstakillEnabled, Flag="ChainsInstakillEnabled", Callback=function(v) S.ChainsInstakillEnabled=v end})
    MiscTab:CreateSlider({Name="Pre-Glide Delay", Range={0.5,3.0}, Increment=0.5, Suffix="s", CurrentValue=S.ChainsGlideDelay,    Flag="ChainsGlideDelay",    Callback=function(v) S.ChainsGlideDelay=v    end})
    MiscTab:CreateSlider({Name="Float Duration",  Range={1.0,8.0}, Increment=0.5, Suffix="s", CurrentValue=S.ChainsFloatDuration, Flag="ChainsFloatDuration", Callback=function(v) S.ChainsFloatDuration=v end})
    MiscTab:CreateLabel("Enable then press R")
    MiscTab:CreateLabel("Need to land a hit | inconsistent on players | beta")

    MiscTab:CreateSection("Index Cleaver [BETA]")

    local function doIndexCleaver()
        if chainsGoing then return end
        chainsGoing = true

        -- Capture the activation point immediately when the crit is triggered.
        local c = LP.Character; if not c then chainsGoing=false; return end
        local r = root(c); if not r then chainsGoing=false; return end
        local startCF = c:GetPivot()
        local targetCF = startCF + Vector3.new(0, S.IndexCleaverHeight, 0)

        task.wait(S.ChainsGlideDelay)
        c = LP.Character; r = root(c); if not c or not r then chainsGoing=false; return end

        local hum = c:FindFirstChild("Humanoid")
        local cFly = {}
        if hum then
            local bg = Instance.new("BodyGyro")
            bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.CFrame=r.CFrame; bg.Parent=r
            table.insert(cFly, bg)
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Velocity=Vector3.zero; bv.Parent=r
            table.insert(cFly, bv)
            hum.PlatformStand = true
        end

        -- Move the whole character by the configured height above the activation point.
        c:PivotTo(targetCF)
        r = root(c)
        if r then r.AssemblyLinearVelocity = Vector3.zero end

        -- Roblox/constraints can occasionally tug the root back on the next frame.
        -- Verify the actual pivot height and snap back to the intended position.
        RunService.Heartbeat:Wait()
        c = LP.Character
        if c and math.abs(c:GetPivot().Position.Y - targetCF.Position.Y) > 1 then
            c:PivotTo(targetCF)
            r = root(c)
            if r then r.AssemblyLinearVelocity = Vector3.zero end
        end

        task.wait(S.ChainsFloatDuration)
        c = LP.Character
        if c then
            c:PivotTo(startCF)
            r = root(c)
            if r then r.AssemblyLinearVelocity = Vector3.zero end
        end
        for _,p in ipairs(cFly) do pcall(p.Destroy, p) end
        c = LP.Character
        if c then local h = c:FindFirstChild("Humanoid"); if h then h.PlatformStand = false end end
        chainsGoing = false
    end

    MiscTab:CreateToggle({Name="Enable", CurrentValue=S.IndexCleaverEnabled, Flag="IndexCleaverEnabled", Callback=function(v) S.IndexCleaverEnabled=v end})
    MiscTab:CreateSlider({
        Name = "Teleport Height",
        Range = {10, 500},
        Increment = 10,
        Suffix = " studs",
        CurrentValue = S.IndexCleaverHeight,
        Flag = "IndexCleaverHeight",
        Callback = function(v) S.IndexCleaverHeight = v end,
    })
    MiscTab:CreateLabel("Enable then press R | teleports upward by the selected height")

    MiscTab:CreateSection("No Killbricks")
    local killbrickFolderConn = nil
    local killbrickWorkspaceConn = nil
    local killbrickStates = setmetatable({}, {__mode = "k"})

    local function disableKillbrickPart(part)
        if not part or not part:IsA("BasePart") then return end
        if killbrickStates[part] == nil then killbrickStates[part] = part.CanTouch end
        part.CanTouch = false
    end

    local function bindKillbrickFolder(folder)
        if killbrickFolderConn then killbrickFolderConn:Disconnect(); killbrickFolderConn = nil end
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do disableKillbrickPart(obj) end
        killbrickFolderConn = folder.DescendantAdded:Connect(function(obj)
            if S.NoKillbricksEnabled then disableKillbrickPart(obj) end
        end)
    end

    local function startKillbricks()
        bindKillbrickFolder(workspace:FindFirstChild("Killbricks"))
        if killbrickWorkspaceConn then killbrickWorkspaceConn:Disconnect() end
        killbrickWorkspaceConn = workspace.ChildAdded:Connect(function(child)
            if S.NoKillbricksEnabled and child.Name == "Killbricks" then
                task.defer(function() bindKillbrickFolder(child) end)
            end
        end)
    end

    local function stopKillbricks()
        if killbrickFolderConn then killbrickFolderConn:Disconnect(); killbrickFolderConn = nil end
        if killbrickWorkspaceConn then killbrickWorkspaceConn:Disconnect(); killbrickWorkspaceConn = nil end
        for part, originalCanTouch in pairs(killbrickStates) do
            if part and part.Parent and part:IsA("BasePart") then
                pcall(function() part.CanTouch = originalCanTouch end)
            end
        end
        table.clear(killbrickStates)
    end

    MiscTab:CreateToggle({
        Name = "No Killbricks", CurrentValue = false, Flag = "NoKillbricks",
        Callback = function(state)
            S.NoKillbricksEnabled = state
            if state then startKillbricks() else stopKillbricks() end
        end,
    })
    MiscTab:CreateLabel("Disables Killbricks locally and restores original CanTouch when turned off")

    MiscTab:CreateSection("Teleport Handler")
    MiscTab:CreateToggle({ Name = "Reload Archivist on Teleport", CurrentValue = true,
        Flag = "TPReload", Callback = function(_) end })
    MiscTab:CreateLabel("Queues the bundled loader; no URL or extra file operations required")

    UIS.InputBegan:Connect(function(input, gp)
        if gp or input.KeyCode ~= Enum.KeyCode.R then return end
        -- Both are crit-attack helpers, so they share the normal crit key.
        -- Keep dispatch deterministic if both toggles are enabled accidentally.
        if S.IndexCleaverEnabled then
            task.spawn(doIndexCleaver)
        elseif S.ChainsInstakillEnabled then
            task.spawn(doChains)
        end
    end)
end

