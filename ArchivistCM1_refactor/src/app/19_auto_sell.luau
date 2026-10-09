-- ------------------------------
-- GENERAL AUTO SELL
-- ------------------------------
do
local SELL_CATEGORIES = {
    "Container", "Augments", "Books", "Consumable", "General", "Gifts",
    "Materials", "Rare Materials", "Tickets", "Unique", "Vestige",
}
local SellConfig = {
    Enabled = false,
    Mode = "Exclude",
    ListText = "",
    Categories = {},
    ProtectSingularities = true,
    AutoMove = true,
    Radius = 8,
    Merchant = "Auto",
    Interval = 60,
    OnlyWhenNearFull = true,
    FullPercent = 90,
    FallbackCount = 80,
}
for _, category in ipairs(SELL_CATEGORIES) do SellConfig.Categories[category] = true end

local SELL_MERCHANTS = {
    [WARP_PLACE_ID] = "Railway Merchant",
    [MAIN_PLACE_ID] = "Restaurant Owner",
}

local function splitCsvSet(text)
    local set = {}
    for token in tostring(text or ""):gmatch("[^,]+") do
        local cleaned = token:match("^%s*(.-)%s*$")
        if cleaned and cleaned ~= "" then set[string.lower(cleaned)] = true end
    end
    return set
end

local function selectionToSet(value)
    local set = {}
    if type(value) ~= "table" then
        if value then set[tostring(value)] = true end
        return set
    end
    for key, item in pairs(value) do
        if type(key) == "string" and type(item) == "boolean" then
            if item then set[key] = true end
        elseif type(item) == "string" then
            set[item] = true
        end
    end
    return set
end

local SellNameSetCache = {}
local SingularityNameCache = nil

local function rebuildSellNameSet()
    SellNameSetCache = splitCsvSet(SellConfig.ListText)
end

local function getSingularityNameCache()
    if SingularityNameCache then return SingularityNameCache end
    SingularityNameCache = {}
    local recipes = RepStore:FindFirstChild("CraftRecipes")
    local singularities = recipes and recipes:FindFirstChild("Singularities")
    if singularities then
        for _, recipe in ipairs(singularities:GetChildren()) do
            SingularityNameCache[string.lower(recipe.Name)] = true
        end
    end
    return SingularityNameCache
end

local function isSingularityItem(item)
    if not item then return false end
    if item.Name == "Singularity" then return true end
    local lowerName = string.lower(item.Name)
    for recipeName in pairs(getSingularityNameCache()) do
        if lowerName:find(recipeName, 1, true) then return true end
    end
    return false
end

local function sellEligible(item, nameSet)
    if not item or not item:IsA("Tool") then return false end
    local price = item:FindFirstChild("SellPrice")
    if not price or not price:IsA("NumberValue") or price.Value <= 0 then return false end
    if SellConfig.ProtectSingularities and isSingularityItem(item) then return false end
    local category = item:GetAttribute("ItemCategory")
    if next(SellConfig.Categories) and category and not SellConfig.Categories[category] then return false end
    local listed = nameSet[string.lower(item.Name)] == true
    if SellConfig.Mode == "Include" then return listed end
    return not listed
end

local function inventoryToolCount()
    local count = 0
    for _, item in ipairs(LP.Backpack:GetChildren()) do if item:IsA("Tool") then count += 1 end end
    local character = LP.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do if item:IsA("Tool") then count += 1 end end
    end
    return count
end

local function inventoryCapacity()
    local data = LP:FindFirstChild("Data")
    local names = {"InventoryCapacity", "MaxInventory", "InventoryLimit", "MaxItems"}
    for _, name in ipairs(names) do
        local value = data and data:FindFirstChild(name)
        if value and tonumber(value.Value) and tonumber(value.Value) > 0 then return tonumber(value.Value) end
        local attr = LP:GetAttribute(name)
        if tonumber(attr) and tonumber(attr) > 0 then return tonumber(attr) end
    end
    return nil
end

local function inventoryNearFull()
    if not SellConfig.OnlyWhenNearFull then return true end
    local count = inventoryToolCount()
    local capacity = inventoryCapacity()
    if capacity then return (count / capacity) * 100 >= SellConfig.FullPercent end
    return count >= SellConfig.FallbackCount
end

local function nextSellableItem()
    for _, item in ipairs(LP.Backpack:GetChildren()) do
        if sellEligible(item, SellNameSetCache) then return item end
    end
    return nil
end

local function sellMerchant()
    local npcs = Workspace:FindFirstChild("NPCS")
    if not npcs then return nil end
    local wanted = SellConfig.Merchant
    if wanted == "Auto" then wanted = SELL_MERCHANTS[game.PlaceId] end
    if wanted and npcs:FindFirstChild(wanted) then return npcs:FindFirstChild(wanted) end
    return npcs:FindFirstChild("Railway Merchant") or npcs:FindFirstChild("Restaurant Owner")
end

local function dialogueOpen()
    return dialogueIsOpen()
end

local function openMerchantDialogue(runtime, merchant)
    local _, _, myRoot = characterParts()
    local pivot = modelPivot(merchant)
    if not myRoot or not pivot then return false end
    local distance = (myRoot.Position - pivot.Position).Magnitude
    if distance > SellConfig.Radius then
        if not SellConfig.AutoMove then return false end
        myRoot.CFrame = pivot * CFrame.new(0, 0, 3)
        myRoot.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.25)
    end

    local deadline = tick() + 5
    repeat
        if not featureAlive(runtime) then return false end
        if dialogueIsOpen() then return true end
        local prompt = findPrompt(merchant)
        if prompt then triggerPrompt(prompt, 1) end
        local talk = merchant:FindFirstChild("TalkToNPC")
        if talk and talk:IsA("RemoteEvent") then pcall(function() talk:FireServer() end) end
        if not prompt and not talk then pressInteraction(Enum.KeyCode.E) end
        task.wait(0.3)
    until tick() >= deadline
    return dialogueIsOpen()
end

local function sellOne(runtime, merchant, item)
    if not featureAlive(runtime) or not item or not item.Parent then return false end
    if not openMerchantDialogue(runtime, merchant) then return false end

    -- Equip exactly the selected sale item, then advance the merchant choices
    -- until the item leaves the inventory or the interaction times out.
    local character = LP.Character
    if character then
        local held = character:FindFirstChildWhichIsA("Tool")
        if held and held ~= item then pcall(function() held.Parent = LP.Backpack end) end
    end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if item.Parent == LP.Backpack then
        if humanoid then pcall(function() humanoid:EquipTool(item) end)
        elseif character then item.Parent = character end
    end
    task.wait(0.18)

    local deadline = tick() + 10
    repeat
        if not featureAlive(runtime) or not item.Parent then break end
        if not dialogueIsOpen() then
            if not openMerchantDialogue(runtime, merchant) then return false end
        end
        DialogueUtil.selectOptionStable("Can", 1, runtime)
        DialogueUtil.selectOptionStable("All", 1, runtime)
        DialogueUtil.selectOptionStable("How", 1, runtime)
        task.wait(0.08)
    until not item.Parent or tick() >= deadline
    return not item.Parent
end

local function runSellCycle(runtime)
    local merchant = sellMerchant()
    if not merchant then return false, 0 end
    local sold = 0
    while featureAlive(runtime) do
        local item = nextSellableItem()
        if not item then break end
        if sellOne(runtime, merchant, item) then
            sold += 1
        else
            break
        end
        task.wait(0.2)
    end
    return true, sold
end

local function startAutoSell()
    SellConfig.Enabled = true
    startFeature("AutoSell", function(runtime)
        local warnedMissing = false
        while featureAlive(runtime) and SellConfig.Enabled do
            if not inventoryNearFull() then
                task.wait(1)
                continue
            end
            local ok, sold = runSellCycle(runtime)
            if not ok and not warnedMissing then
                notify("Auto Sell", "Inventory threshold reached, but no supported merchant is available.")
                warnedMissing = true
            elseif ok then
                warnedMissing = false
            end
            local waited = 0
            while featureAlive(runtime) and SellConfig.Enabled and waited < SellConfig.Interval do
                task.wait(0.5)
                waited += 0.5
            end
        end
    end)
    return true
end

local function stopAutoSell()
    SellConfig.Enabled = false
    stopFeature("AutoSell")
end

local function sellOnce()
    startFeature("SellOnce", function(runtime)
        local ok, sold = runSellCycle(runtime)
        if ok then notify("Auto Sell", "Sold " .. tostring(sold) .. " item(s).")
        else notify("Auto Sell", "No supported merchant is available in this instance.") end
    end)
end

AutoSellTab:CreateSection("General Auto Sell")
AutoSellTab:CreateToggle({
    Name = "Auto Sell", CurrentValue = false, Flag = "GeneralAutoSell",
    Callback = function(state)
        if state then startAutoSell() else stopAutoSell() end
    end,
})
AutoSellTab:CreateButton({Name = "Sell Once", Callback = sellOnce})
AutoSellTab:CreateDropdown({
    Name = "Merchant", Options = {"Auto", "Railway Merchant", "Restaurant Owner"}, CurrentOption = {"Auto"},
    MultipleOptions = false, Flag = "SellMerchant",
    Callback = function(value) SellConfig.Merchant = valueFromOption(value) or "Auto" end,
})
AutoSellTab:CreateDropdown({
    Name = "Mode", Options = {"Exclude", "Include"}, CurrentOption = {"Exclude"}, MultipleOptions = false,
    Flag = "SellMode", Callback = function(value) SellConfig.Mode = valueFromOption(value) or "Exclude" end,
})
AutoSellTab:CreateInput({
    Name = "Item List", PlaceholderText = "Book, Gear, ...", RemoveTextAfterFocusLost = false, Flag = "SellList",
    Callback = function(value) SellConfig.ListText = tostring(value or ""); rebuildSellNameSet() end,
})
AutoSellTab:CreateDropdown({
    Name = "Sell Categories", Options = SELL_CATEGORIES, CurrentOption = SELL_CATEGORIES, MultipleOptions = true,
    Flag = "SellCategories", Callback = function(value) SellConfig.Categories = selectionToSet(value) end,
})
AutoSellTab:CreateToggle({
    Name = "Protect Singularities", CurrentValue = true, Flag = "ProtectSingularities",
    Callback = function(state) SellConfig.ProtectSingularities = state end,
})
AutoSellTab:CreateToggle({
    Name = "Auto Move to Merchant", CurrentValue = true, Flag = "SellAutoMove",
    Callback = function(state) SellConfig.AutoMove = state end,
})
AutoSellTab:CreateToggle({
    Name = "Sell Only When Nearly Full", CurrentValue = true, Flag = "SellNearFullOnly",
    Callback = function(state) SellConfig.OnlyWhenNearFull = state end,
})
AutoSellTab:CreateSlider({
    Name = "Inventory Fullness Trigger", Range = {50, 100}, Increment = 5, Suffix = "%", CurrentValue = 90, Flag = "SellFullPercent",
    Callback = function(value) SellConfig.FullPercent = value end,
})
AutoSellTab:CreateSlider({
    Name = "Fallback Item Count", Range = {10, 200}, Increment = 5, CurrentValue = 80, Flag = "SellFallbackCount",
    Callback = function(value) SellConfig.FallbackCount = value end,
})
AutoSellTab:CreateSlider({
    Name = "Post-Sell Check Interval", Range = {5, 300}, Increment = 5, Suffix = "s", CurrentValue = 60, Flag = "SellInterval",
    Callback = function(value) SellConfig.Interval = value end,
})
AutoSellTab:CreateSlider({
    Name = "Merchant Activation Range", Range = {5, 25}, Increment = 1, CurrentValue = 8, Flag = "SellRange",
    Callback = function(value) SellConfig.Radius = value end,
})
AutoSellTab:CreateLabel("Exclude = sell everything in selected categories except listed names")
AutoSellTab:CreateLabel("Include = sell only listed names in selected categories")
AutoSellTab:CreateLabel("Near-full mode uses a detected inventory capacity when available; otherwise it uses Fallback Item Count.")
end -- GENERAL AUTO SELL scope


