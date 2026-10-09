	["@src/ui/arraylist"] = function()
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

return function(library)
	local gradientEnabled = true
	local gradientDuration = 5
	local visible = false
	local backgroundEnabled = true
	local textSize = 18
	local lastColorRefresh = 0
	local labels = {}
	local rowsById = {}
	local exitingRows = {}
	local leftSide = true
	local bottomSide = false
	local dragging = false
	local refresh

	local panel = library:Create("Frame", {
		Name = "YSLArrayList",
		Active = true,
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0, 88),
		Size = UDim2.fromOffset(240, 20),
		Visible = false,
		ZIndex = 80,
		Parent = library.ScreenGui,
	})
	library.ArrayListFrame = panel
	library:MakeDraggable(panel, 16, true)
	panel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
		end
	end)

	local function updatePlacement()
		local absolutePosition = panel.AbsolutePosition
		local absoluteSize = panel.AbsoluteSize
		local center = absolutePosition + absoluteSize * 0.5
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize
		if not viewport then
			return
		end

		local newLeftSide = center.X < viewport.X * 0.5
		local newBottomSide = center.Y > viewport.Y * 0.5
		local changed = newLeftSide ~= leftSide or newBottomSide ~= bottomSide
		leftSide = newLeftSide
		bottomSide = newBottomSide
		panel.AnchorPoint = Vector2.new(leftSide and 0 or 1, bottomSide and 1 or 0)
		library.ArrayListAnchorPoint = panel.AnchorPoint
		panel.Position = UDim2.fromOffset(
			leftSide and absolutePosition.X or absolutePosition.X + absoluteSize.X,
			bottomSide and absolutePosition.Y + absoluteSize.Y or absolutePosition.Y
		)
		if changed then
			refresh()
		end
	end

	library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			updatePlacement()
		end
	end))

	local list = library:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.new(1, 0, 1, -16),
		ZIndex = 80,
		Parent = panel,
	})
	local layout = library:Create("UIListLayout", {
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = list,
	})

	local function getGradientColor(position)
		local dark = library.AccentColorDark or library:GetDarkerColor(library.AccentColor)
		position = position % 1
		local section = position * 4
		local index = math.floor(section)
		local blend = section - index
		blend = blend * blend * (3 - 2 * blend)
		if index == 0 then
			return library.AccentColor:Lerp(library.FontColor, blend)
		elseif index == 1 then
			return library.FontColor:Lerp(dark, blend)
		elseif index == 2 then
			return dark:Lerp(library.FontColor, blend)
		end
		return library.FontColor:Lerp(library.AccentColor, blend)
	end

	local function refreshColors()
		local count = #labels
		local phase = gradientEnabled and ((os.clock() / gradientDuration) % 1) or 0
		for index, entry in ipairs(labels) do
			local color
			if gradientEnabled then
				local rowPosition = count <= 1 and 0.5 or (index - 1) / (count - 1)
				color = getGradientColor((rowPosition + phase) % 1)
			else
				color = library.AccentColor
			end
			entry.Label.TextColor3 = color
			local nameText = string.format(
				'<font color="#%s">%s</font>',
				color:ToHex(),
				entry.EscapedName
			)
			local detailText = entry.EscapedDetail ~= ""
				and string.format(
					'  <font color="#%s">%s</font>',
					library.FontColor:ToHex(),
					entry.EscapedDetail
				)
				or ""
			entry.Label.Text = nameText .. detailText
			entry.Sidebar.BackgroundColor3 = color
		end
	end

	local function escapeRichText(text)
		return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end

	local function createRow(entry, order, animateIn)
		local horizontalAnchor = leftSide and 0 or 1
		local textAlignment = leftSide and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
		local rowHeight = math.ceil(textSize * 1.36)
		local row = library:Create("Frame", {
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, animateIn and 0 or rowHeight),
			ZIndex = 81,
			Parent = list,
		})
		local background = library:Create("Frame", {
			Active = true,
			AnchorPoint = Vector2.new(horizontalAnchor, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = animateIn and 1 or (backgroundEnabled and 0.25 or 1),
			BorderSizePixel = 0,
			Position = UDim2.new(horizontalAnchor, 0, 0, 0),
			Size = UDim2.fromOffset(entry.TextWidth + 12, rowHeight),
			ZIndex = 81,
			Parent = row,
		})
		local sidebar = library:Create("Frame", {
			Active = true,
			AnchorPoint = Vector2.new(horizontalAnchor, 0),
			BackgroundColor3 = library.AccentColor,
			BackgroundTransparency = animateIn and 1 or 0,
			BorderSizePixel = 0,
			Position = UDim2.new(horizontalAnchor, 0, 0, 0),
			Size = UDim2.new(0, 2, 1, 0),
			ZIndex = 83,
			Parent = row,
		})
		local label = library:CreateLabel({
			Active = true,
			AnchorPoint = Vector2.new(horizontalAnchor, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(horizontalAnchor, leftSide and 5 or -5, 0, 0),
			Size = UDim2.fromOffset(entry.TextWidth + 2, rowHeight),
			FontFace = lexend.bold,
			Text = entry.EscapedName,
			RichText = true,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = textSize,
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = animateIn and 1 or 0.15,
			TextTransparency = animateIn and 1 or 0,
			TextXAlignment = textAlignment,
			ZIndex = 82,
			Parent = row,
		})
		library:AddToRegistry(label, {
			TextStrokeColor3 = "Black",
		})

		local result = {
			Id = entry.Id,
			Toggle = entry.Toggle,
			Row = row,
			Background = background,
			Label = label,
			EscapedName = entry.EscapedName,
			EscapedDetail = entry.EscapedDetail,
			TextWidth = entry.TextWidth,
			Sidebar = sidebar,
		}
		rowsById[entry.Id] = result
		local function handleRowInput(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and result.Toggle.Value then
				result.Toggle:SetValue(false)
			end
		end
		row.InputBegan:Connect(handleRowInput)
		background.InputBegan:Connect(handleRowInput)
		sidebar.InputBegan:Connect(handleRowInput)
		label.InputBegan:Connect(handleRowInput)

		if animateIn then
			local tweenInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			TweenService:Create(row, tweenInfo, {
				Size = UDim2.new(1, 0, 0, rowHeight),
			}):Play()
			TweenService:Create(background, tweenInfo, {
				BackgroundTransparency = backgroundEnabled and 0.25 or 1,
			}):Play()
			TweenService:Create(sidebar, tweenInfo, { BackgroundTransparency = 0 }):Play()
			TweenService:Create(label, tweenInfo, {
				TextTransparency = 0,
				TextStrokeTransparency = 0.15,
			}):Play()
		end
		return result
	end

	local function animateRemove(entry)
		if entry.Removing then
			return
		end
		entry.Removing = true
		rowsById[entry.Id] = nil
		exitingRows[entry.Id] = entry
		local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tweens = {
			TweenService:Create(entry.Background, tweenInfo, {
				BackgroundTransparency = 1,
			}),
			TweenService:Create(entry.Sidebar, tweenInfo, {
				BackgroundTransparency = 1,
			}),
			TweenService:Create(entry.Label, tweenInfo, {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}),
		}
		tweens[1].Completed:Connect(function()
			if entry.Row.Parent then
				entry.Row:Destroy()
			end
			if exitingRows[entry.Id] == entry then
				exitingRows[entry.Id] = nil
				if visible then
					refresh()
				end
			end
		end)
		for _, tween in ipairs(tweens) do
			tween:Play()
		end
	end

	refresh = function(changedToggle, changedValue)
		local active = {}
		local activeById = {}
		for id, toggle in pairs(aztup_toggles) do
			if toggle.Type == "Toggle" and toggle.Value and toggle.ArrayList ~= false
				and toggle.TabName ~= "Settings" then
				local details = {}
				if toggle.ArrayListKeybindId then
					local keybind = aztup_options[toggle.ArrayListKeybindId]
					if keybind and keybind.Value and keybind.Value ~= "None" then
						table.insert(details, "[" .. tostring(keybind.Value) .. "]")
					end
				end
				local detailText = table.concat(details, "  ")
				local text = toggle.Name .. (detailText ~= "" and "  " .. detailText or "")
				local textWidth = math.ceil(library:GetLexendTextBounds(text, lexend.bold, textSize))
				local entry = {
					Id = id,
					Toggle = toggle,
					Name = toggle.Name,
					DetailText = detailText,
					EscapedName = escapeRichText(toggle.Name),
					EscapedDetail = escapeRichText(detailText),
					TextLength = #text,
					TextWidth = textWidth,
				}
				table.insert(active, entry)
				activeById[id] = entry
			end
		end
		table.sort(active, function(left, right)
			if left.TextWidth ~= right.TextWidth then
				return left.TextWidth > right.TextWidth
			end
			if left.TextLength ~= right.TextLength then
				return left.TextLength > right.TextLength
			end
			local leftName = string.lower(left.Toggle.Name)
			local rightName = string.lower(right.Toggle.Name)
			if leftName == rightName then
				return tostring(left.Id) < tostring(right.Id)
			end
			return leftName < rightName
		end)
		layout.VerticalAlignment = Enum.VerticalAlignment.Top

		local rowHeight = math.ceil(textSize * 1.36)
		for id, row in pairs(rowsById) do
			if not activeById[id] then
				if changedToggle == row.Toggle and changedValue == false then
					animateRemove(row)
				else
					rowsById[id] = nil
					row.Row:Destroy()
				end
			end
		end

		table.clear(labels)
		local width = 0
		local exitingCount = 0
		local reservedOrders = {}
		for _, row in pairs(exitingRows) do
			exitingCount += 1
			reservedOrders[row.Row.LayoutOrder] = true
			width = math.max(width, row.TextWidth + 12)
		end
		local layoutOrder = 0
		for index, entry in ipairs(active) do
			width = math.max(width, entry.TextWidth + 12)
			layoutOrder += 1
			while reservedOrders[layoutOrder] do
				layoutOrder += 1
			end
			local row = rowsById[entry.Id]
			if row then
				row.Toggle = entry.Toggle
				row.Row.LayoutOrder = layoutOrder
				row.Row.Size = UDim2.new(1, 0, 0, rowHeight)
				row.Background.Size = UDim2.fromOffset(entry.TextWidth + 12, rowHeight)
				row.Background.BackgroundTransparency = backgroundEnabled and 0.25 or 1
				row.Label.Size = UDim2.fromOffset(entry.TextWidth + 2, rowHeight)
				row.TextWidth = entry.TextWidth
				row.EscapedName = entry.EscapedName
				row.EscapedDetail = entry.EscapedDetail
			else
				row = createRow(entry, layoutOrder, changedToggle == entry.Toggle and changedValue == true)
			end
			table.insert(labels, row)
		end

		panel.Size = UDim2.fromOffset(
			math.max(100, width + 4),
			16 + (#labels + exitingCount) * rowHeight
		)
		panel.Visible = visible and (#labels + exitingCount) > 0
		refreshColors()
	end

	local controller = {}
	function controller:SetVisible(value)
		visible = not not value
		refresh()
	end

	function controller:SetBackgroundEnabled(enabled)
		backgroundEnabled = not not enabled
		for _, entry in ipairs(labels) do
			entry.Background.BackgroundTransparency = backgroundEnabled and 0.25 or 1
		end
	end

	function controller:Refresh()
		refresh()
	end

	function controller:SetGradient(enabled, duration)
		gradientEnabled = not not enabled
		gradientDuration = math.clamp(tonumber(duration) or gradientDuration, 1, 12)
		refreshColors()
	end

	function controller:SyncPlacement()
		leftSide = panel.AnchorPoint.X < 0.5
		bottomSide = panel.AnchorPoint.Y > 0.5
		library.ArrayListAnchorPoint = panel.AnchorPoint
		refresh()
	end

	library.ArrayListAnchorPoint = panel.AnchorPoint
	library.ArrayListController = controller

	library:GiveSignal(library.ToggleChanged.Event:Connect(function(value, toggleId)
		if visible then
			local toggle = aztup_toggles[toggleId]
			refresh(toggle, value)
		end
	end))
	library:GiveSignal(RunService.RenderStepped:Connect(function()
		if not visible or not gradientEnabled or #labels == 0 then
			lastColorRefresh = 0
			return
		end
		local now = os.clock()
		if now - lastColorRefresh >= 1 / 15 then
			lastColorRefresh = now
			refreshColors()
		end
	end))
	library:GiveSignal(library.ScreenGui.Destroying:Connect(function()
		panel.Visible = false
	end))

	return controller
end
	end,
