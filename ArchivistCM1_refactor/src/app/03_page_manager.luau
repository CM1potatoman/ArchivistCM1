-- ============================================================
-- PAGE MANAGER HELPERS
-- ============================================================
local function GetPages()
    local pages = {}
    for _, tool in pairs(LP.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("RemoteEvent") then
            table.insert(pages, tool.Name)
        end
    end
    return pages
end

local globalNoCooldowns = false

local function GetFinalCD(tool, mode)
    if globalNoCooldowns then return 0 end
    local original = tool:GetAttribute("CD") or 10
    if mode == "none" then return 0
    elseif mode == "half" then return math.floor(original / 2)
    else return original end
end

local function GetValue(opt)
    if type(opt) == "table" then return opt.Value or opt[1] or "" end
    return opt or ""
end

local function FirePage(pageName, mode)
    local tool = LP.Backpack:FindFirstChild(pageName)
    if tool then
        local remote = tool:FindFirstChild("RemoteEvent")
        if remote then
            remote:FireServer(GetFinalCD(tool, mode))
        end
    end
end

local PageSlots = {
    {name="", mode="normal", key="J"},
    {name="", mode="normal", key="K"},
    {name="", mode="normal", key="L"},
}

local charParts = {}
local function rebuildCharParts(c)
    charParts = {}
    if not c then return end
    for _,v in ipairs(c:GetDescendants()) do
        if v:IsA("BasePart") then charParts[#charParts+1] = v end
    end
end
if LP.Character then rebuildCharParts(LP.Character) end

