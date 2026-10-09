-- ============================================================
-- ATTACH HELPERS
-- ============================================================
local attachTarget, attachActive = nil, false
local flyOn, noclipOn = false, false
local flyParts = {}
local attachCollisionState = setmetatable({}, {__mode = "k"})
local lastEnemyPos = nil

local function attachKillFly()
    if not flyOn then return end
    for _,p in ipairs(flyParts) do pcall(p.Destroy, p) end
    table.clear(flyParts)
    local c = LP.Character
    if c then local h = c:FindFirstChild("Humanoid"); if h then h.PlatformStand = false end end
    flyOn = false
end

local function attachStartFly()
    if flyOn then return end
    local c = LP.Character; if not c then return end
    local r = root(c); local h = c:FindFirstChild("Humanoid")
    if not r or not h then return end
    local bg = Instance.new("BodyGyro")
    bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.CFrame=r.CFrame; bg.Parent=r
    flyParts[#flyParts+1] = bg
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Velocity=Vector3.zero; bv.Parent=r
    flyParts[#flyParts+1] = bv
    h.PlatformStand = true
    flyOn = true
end

local function attachStartNoclip()
    if noclipOn then return end
    noclipOn = true
    table.clear(attachCollisionState)
    for _, p in ipairs(charParts) do
        if p and p.Parent and p:IsA("BasePart") then
            attachCollisionState[p] = p.CanCollide
            p.CanCollide = false
        end
    end
end

local function attachKillNoclip()
    if not noclipOn and next(attachCollisionState) == nil then return end
    noclipOn = false
    for part, originalCanCollide in pairs(attachCollisionState) do
        if part and part.Parent and part:IsA("BasePart") then
            part.CanCollide = originalCanCollide
        end
    end
    table.clear(attachCollisionState)
end

local function attachSafeTP()
    local c = LP.Character; if not c then return end
    local r = root(c); if not r then return end
    local tp = lastEnemyPos and (lastEnemyPos + Vector3.new(0,5,0)) or (r.Position + Vector3.new(0,5,0))
    r.CFrame = CFrame.new(tp)
end

local function attachStop()
    if not attachActive then return end
    attachActive = false; attachTarget = nil
    attachKillFly(); attachKillNoclip(); attachSafeTP()
    local c = LP.Character
    if c then local h = c:FindFirstChild("Humanoid"); if h then h.AutoRotate = true end end
end

local function attachPos(enemy)
    local er = root(enemy); if not er then return nil end
    local lv = er.CFrame.LookVector
    local dist = S.AttachDistance
    local height = S.AttachHeight
    local n = enemy.Name
    if n == "Big Brother Of The Middle" or n == "Sweeper Brute" or n == "Nothing There" then
        dist = 5; height = -2
    end
    local dir = S.AttachForward <= 1 and -lv*(1-S.AttachForward) or lv*(S.AttachForward-1)
    return er.Position + dir*dist + Vector3.new(0,height,0), lv
end

local function attachClosest()
    local c = LP.Character; if not c then return nil end
    local r = root(c); if not r then return nil end
    local al = alive(); if not al then return nil end
    local best, bestD = nil, math.huge
    for _,t in ipairs(al:GetChildren()) do
        if validTarget(t, S.AttachTargetPlayers) then
            local tr = root(t)
            if tr then
                local d = (r.Position - tr.Position).Magnitude
                if d <= S.AttachRange and d < bestD then
                    bestD = d; best = t
                end
            end
        end
    end
    if best then lastEnemyPos = root(best).Position end
    return best
end

