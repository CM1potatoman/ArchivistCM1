-- ============================================================
-- INVENTORY VIEWER TAB
-- ============================================================
local InventoryTab = Window:CreateTab("Utilities", 10726204364)
InventoryTab:CreateLabel("Inventory, servers, chat, music and utility tools")

do
    local function createInventoryViewer()
        local PlayerGui = LP:WaitForChild("PlayerGui")

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "PlayerInventoryViewer"
        screenGui.Parent = PlayerGui

        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 800, 0, 600)
        mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
        mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        mainFrame.BorderSizePixel = 0
        mainFrame.Visible = false
        mainFrame.Parent = screenGui
        Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

        local titleBar = Instance.new("Frame")
        titleBar.Name = "TitleBar"
        titleBar.Size = UDim2.new(1, 0, 0, 40)
        titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        titleBar.BorderSizePixel = 0
        titleBar.Parent = mainFrame
        Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -120, 1, 0)
        titleLabel.Position = UDim2.new(0, 10, 0, 0)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Player Inventory Viewer"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextScaled = true
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = titleBar

        local refreshButton = Instance.new("TextButton")
        refreshButton.Name = "RefreshButton"
        refreshButton.Size = UDim2.new(0, 70, 0, 30)
        refreshButton.Position = UDim2.new(1, -110, 0, 5)
        refreshButton.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        refreshButton.Text = "Refresh"
        refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        refreshButton.TextScaled = true
        refreshButton.Font = Enum.Font.GothamBold
        refreshButton.BorderSizePixel = 0
        refreshButton.Parent = titleBar
        Instance.new("UICorner", refreshButton).CornerRadius = UDim.new(0, 5)

        local closeButton = Instance.new("TextButton")
        closeButton.Size = UDim2.new(0, 30, 0, 30)
        closeButton.Position = UDim2.new(1, -35, 0, 5)
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        closeButton.Text = "X"
        closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeButton.TextScaled = true
        closeButton.Font = Enum.Font.GothamBold
        closeButton.BorderSizePixel = 0
        closeButton.Parent = titleBar
        Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 5)

        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, -20, 1, -60)
        contentFrame.Position = UDim2.new(0, 10, 0, 50)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = mainFrame

        local playerFrame = Instance.new("Frame")
        playerFrame.Size = UDim2.new(0, 200, 1, 0)
        playerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        playerFrame.BorderSizePixel = 0
        playerFrame.Parent = contentFrame
        Instance.new("UICorner", playerFrame).CornerRadius = UDim.new(0, 5)

        local playerTitle = Instance.new("TextLabel")
        playerTitle.Size = UDim2.new(1, 0, 0, 30)
        playerTitle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        playerTitle.Text = "Players"
        playerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerTitle.TextScaled = true
        playerTitle.Font = Enum.Font.GothamBold
        playerTitle.BorderSizePixel = 0
        playerTitle.Parent = playerFrame
        Instance.new("UICorner", playerTitle).CornerRadius = UDim.new(0, 5)

        local playerScrollFrame = Instance.new("ScrollingFrame")
        playerScrollFrame.Size = UDim2.new(1, -10, 1, -40)
        playerScrollFrame.Position = UDim2.new(0, 5, 0, 35)
        playerScrollFrame.BackgroundTransparency = 1
        playerScrollFrame.ScrollBarThickness = 5
        playerScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        playerScrollFrame.Parent = playerFrame

        local playerLayout = Instance.new("UIListLayout")
        playerLayout.SortOrder = Enum.SortOrder.Name
        playerLayout.Padding = UDim.new(0, 5)
        playerLayout.Parent = playerScrollFrame

        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -210, 1, 0)
        itemFrame.Position = UDim2.new(0, 210, 0, 0)
        itemFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        itemFrame.BorderSizePixel = 0
        itemFrame.Parent = contentFrame
        Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 5)

        local itemTitle = Instance.new("TextLabel")
        itemTitle.Size = UDim2.new(1, 0, 0, 30)
        itemTitle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        itemTitle.Text = "Items"
        itemTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemTitle.TextScaled = true
        itemTitle.Font = Enum.Font.GothamBold
        itemTitle.BorderSizePixel = 0
        itemTitle.Parent = itemFrame
        Instance.new("UICorner", itemTitle).CornerRadius = UDim.new(0, 5)

        local itemScrollFrame = Instance.new("ScrollingFrame")
        itemScrollFrame.Size = UDim2.new(1, -10, 1, -40)
        itemScrollFrame.Position = UDim2.new(0, 5, 0, 35)
        itemScrollFrame.BackgroundTransparency = 1
        itemScrollFrame.ScrollBarThickness = 5
        itemScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        itemScrollFrame.Parent = itemFrame

        local itemLayout = Instance.new("UIListLayout")
        itemLayout.SortOrder = Enum.SortOrder.Name
        itemLayout.Padding = UDim.new(0, 3)
        itemLayout.Parent = itemScrollFrame

        local selectedPlayerLabel = Instance.new("TextLabel")
        selectedPlayerLabel.Size = UDim2.new(1, -10, 0, 25)
        selectedPlayerLabel.Position = UDim2.new(0, 5, 0, 0)
        selectedPlayerLabel.BackgroundTransparency = 1
        selectedPlayerLabel.Text = "Select a player to view items"
        selectedPlayerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        selectedPlayerLabel.TextScaled = true
        selectedPlayerLabel.Font = Enum.Font.Gotham
        selectedPlayerLabel.TextXAlignment = Enum.TextXAlignment.Left
        selectedPlayerLabel.Parent = itemScrollFrame

        local selectedPlayer = nil

        local specialItems = {
            ["Serum W"]=true,["Serum R"]=true,["Serum K"]=true,
            ["Gravity Manipulation"]=true,["Mist of The Lake"]=true,
            ["Sinner Contract"]=true,["Wild Hunt"]=true,["Enchain"]=true,
            ["Deathseeking"]=true,["Chefs Blessing"]=true,
            ["Borrowed Eyes"]=true,["Silencing Gloves"]=true,
            ["Shockwave"]=true,["Manifested Armor"]=true,
            ["Singularity"]=true,["Rewound Time"]=true,
            ["Executioners Claw"]=true,["Fused blade of Ruined Mirror Worlds"]=true,
        }

        local function updateCanvasSize(scrollFrame, layout)
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end

        local function displayItems(player)
            for _, child in ipairs(itemScrollFrame:GetChildren()) do
                if child:IsA("TextLabel") and child ~= selectedPlayerLabel then child:Destroy() end
            end
            if not player then selectedPlayerLabel.Text = "Select a player to view items"; return end
            selectedPlayerLabel.Text = player.Name .. "'s Inventory"

            local backpack = player:FindFirstChild("Backpack")
            if not backpack then
                local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,0,30)
                l.BackgroundTransparency = 1; l.Text = "No Backpack found"
                l.TextColor3 = Color3.fromRGB(255,100,100); l.TextScaled = true
                l.Font = Enum.Font.Gotham; l.Parent = itemScrollFrame
                updateCanvasSize(itemScrollFrame, itemLayout); return
            end

            local items = {}
            for _, item in ipairs(backpack:GetChildren()) do
                if item:GetAttribute("ItemCategory") ~= "Pages" then table.insert(items, item) end
            end
            if #items == 0 then
                local l = Instance.new("TextLabel"); l.Size = UDim2.new(1,0,0,30)
                l.BackgroundTransparency = 1; l.Text = "Inventory is empty"
                l.TextColor3 = Color3.fromRGB(150,150,150); l.TextScaled = true
                l.Font = Enum.Font.Gotham; l.Parent = itemScrollFrame
                updateCanvasSize(itemScrollFrame, itemLayout); return
            end

            local counts = {}
            for _, item in ipairs(items) do counts[item.Name] = (counts[item.Name] or 0) + 1 end
            local sorted = {}
            for name, count in pairs(counts) do table.insert(sorted, {name=name,count=count}) end
            table.sort(sorted, function(a,b) return a.name:lower() < b.name:lower() end)

            for _, data in ipairs(sorted) do
                local itemLabel = Instance.new("TextLabel")
                itemLabel.Size = UDim2.new(1, 0, 0, 30)
                itemLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                itemLabel.BorderSizePixel = 0
                local isSpecial = specialItems[data.name] == true
                local prefix = isSpecial and "* " or ""
                if data.count > 1 then itemLabel.Text = "  " .. prefix .. data.name .. " x" .. data.count
                else itemLabel.Text = "  " .. prefix .. data.name end
                itemLabel.TextColor3 = isSpecial and Color3.fromRGB(255,215,0) or Color3.fromRGB(255,255,255)
                itemLabel.TextScaled = true; itemLabel.Font = Enum.Font.Gotham
                itemLabel.TextXAlignment = Enum.TextXAlignment.Left
                itemLabel.Parent = itemScrollFrame
                Instance.new("UICorner", itemLabel).CornerRadius = UDim.new(0, 5)
            end
            updateCanvasSize(itemScrollFrame, itemLayout)
        end

        local function refreshPlayerList()
            for _, child in ipairs(playerScrollFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            local sortedPlayers = {}
            for _, p in ipairs(Players:GetPlayers()) do table.insert(sortedPlayers, p) end
            table.sort(sortedPlayers, function(a,b) return a.Name:lower() < b.Name:lower() end)
            for _, player in ipairs(sortedPlayers) do
                local button = Instance.new("TextButton")
                button.Name = player.Name
                button.Size = UDim2.new(1, -10, 0, 35)
                button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                button.Text = player.Name; button.TextColor3 = Color3.fromRGB(255,255,255)
                button.TextScaled = true; button.Font = Enum.Font.Gotham
                button.BorderSizePixel = 0; button.Parent = playerScrollFrame
                Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
                button.MouseButton1Click:Connect(function()
                    if selectedPlayer then
                        for _, child in ipairs(playerScrollFrame:GetChildren()) do
                            if child:IsA("TextButton") then child.BackgroundColor3 = Color3.fromRGB(40,40,40) end
                        end
                    end
                    selectedPlayer = player
                    button.BackgroundColor3 = Color3.fromRGB(0,120,200)
                    displayItems(player)
                end)
            end
            updateCanvasSize(playerScrollFrame, playerLayout)
        end

        refreshButton.MouseButton1Click:Connect(function()
            refreshPlayerList()
            if selectedPlayer then displayItems(selectedPlayer) end
        end)
        closeButton.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
        Players.PlayerAdded:Connect(refreshPlayerList)
        Players.PlayerRemoving:Connect(function(player)
            if selectedPlayer == player then selectedPlayer = nil; displayItems(nil) end
            refreshPlayerList()
        end)

        local dragging, dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = input.Position; startPos = mainFrame.Position
            end
        end)
        titleBar.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        titleBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        refreshPlayerList()
        return mainFrame
    end

    local invMainFrame = createInventoryViewer()

    InventoryTab:CreateSection("Inventory")
    InventoryTab:CreateButton({
        Name = "Open Inventory Viewer",
        Callback = function()
            invMainFrame.Visible = not invMainFrame.Visible
            if invMainFrame.Visible then
                local titleB = invMainFrame:FindFirstChild("TitleBar")
                local refreshBtn = titleB and titleB:FindFirstChild("RefreshButton")
                if refreshBtn then refreshBtn.MouseButton1Click:Fire() end
            end
        end,
    })
end

