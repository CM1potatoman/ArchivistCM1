	["@src/utility/librarys/components/hud"] = function()


return function(Library, context)
	local ScreenGui = context.ScreenGui or Library.ScreenGui
	local Mouse = context.Mouse
	local TweenService = context.TweenService or game:GetService('TweenService')
	local UserInputService = game:GetService('UserInputService')

	local Component = {}

	local NotificationArea = Library:Create('Frame', {
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Position = UDim2.new(0, 8, 0, 40);
		Size = UDim2.fromOffset(480, 0);
		ZIndex = 90;
		Parent = ScreenGui;
	})

	Library.NotificationArea = NotificationArea
	Library:AddUIScale(NotificationArea)

	local NotificationLayout = Library:Create('UIListLayout', {
		Padding = UDim.new(0, 4);
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = NotificationArea;
	})
	NotificationLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		local scale = math.max(Library:GetUIScale(), 0.01)
		NotificationArea.Size = UDim2.fromOffset(
			NotificationArea.Size.X.Offset,
			NotificationLayout.AbsoluteContentSize.Y / scale
		)
	end)

	local notificationDragConnections = {}
	local function clearNotificationDragConnections()
		for _, connection in ipairs(notificationDragConnections) do
			connection:Disconnect()
		end
		table.clear(notificationDragConnections)
	end

	local function beginNotificationDrag(input, onClick)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		clearNotificationDragConnections()
		local touchInput = input.UserInputType == Enum.UserInputType.Touch and input or nil
		local startPointer = Vector2.new(input.Position.X, input.Position.Y)
		local startPosition = NotificationArea.Position
		local scale = math.max(Library:GetUIScale(), 0.01)
		local moved = false
		local function updatePointer(pointer)
			local delta = (pointer - startPointer) / scale
			if not moved and delta.Magnitude < 4 then
				return
			end
			moved = true
			local camera = workspace.CurrentCamera
			local viewport = camera and camera.ViewportSize / scale or Vector2.new(800, 600)
			local maxX = math.max(0, viewport.X - NotificationArea.AbsoluteSize.X / scale)
			local maxY = math.max(0, viewport.Y - NotificationArea.AbsoluteSize.Y / scale)
			local x = math.clamp(startPosition.X.Offset + delta.X, 0, maxX)
			local y = math.clamp(startPosition.Y.Offset + delta.Y, 0, maxY)
			NotificationArea.Position = UDim2.fromOffset(x, y)
		end
		table.insert(notificationDragConnections, UserInputService.InputChanged:Connect(function(changedInput)
			if touchInput then
				if changedInput == touchInput then
					updatePointer(Vector2.new(changedInput.Position.X, changedInput.Position.Y))
				end
			elseif changedInput.UserInputType == Enum.UserInputType.MouseMovement
				and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				updatePointer(Vector2.new(changedInput.Position.X, changedInput.Position.Y))
			end
		end))
		table.insert(notificationDragConnections, UserInputService.InputEnded:Connect(function(endedInput)
			local ended = touchInput and endedInput == touchInput
				or (not touchInput and endedInput.UserInputType == Enum.UserInputType.MouseButton1)
			if not ended then
				return
			end
			clearNotificationDragConnections()
			if not moved and onClick then
				onClick()
			end
		end))
	end

	ScreenGui.Destroying:Connect(clearNotificationDragConnections)

	local WatermarkOuter = Library:Create('Frame', {
		Position = UDim2.new(0, 24, 1, -56);
		Size = UDim2.new(0, 180, 0, 36);
		BackgroundColor3 = Library.MainColor;
		BackgroundTransparency = 0.18;
		BorderSizePixel = 0;
		ZIndex = 200;
		Visible = false;
		Parent = ScreenGui;
	})
	Library:AddUIScale(WatermarkOuter)
	Library:Create('UICorner', {
		CornerRadius = UDim.new(0, 10);
		Parent = WatermarkOuter;
	})
	local WatermarkStroke = Library:Create("UIStroke", {
		Color = Library.AccentColor;
		Thickness = 3;
		Transparency = 0.18;
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
		Parent = WatermarkOuter;
	})
	Library:AddWindowGradientStroke(WatermarkStroke)
	Library:AddToRegistry(WatermarkStroke, {
		Color = function()
			return Library.WindowOutlineGradientEnabled and Color3.new(1, 1, 1) or Library.AccentColor
		end;
	}, true)

	WatermarkOuter.MouseEnter:Connect(function()
		Library.RequestingMouse = true
	end)

	WatermarkOuter.MouseLeave:Connect(function()
		Library.RequestingMouse = false
	end)

	Library:AddToRegistry(WatermarkOuter, {
		BackgroundColor3 = 'MainColor';
	}, true)

	local WatermarkInner = Library:Create('Frame', {
		Size = UDim2.new(1, -2, 1, -2);
		Position = UDim2.new(0, 1, 0, 1);
		BackgroundColor3 = Library.MainColor;
		BackgroundTransparency = 0.18;
		BorderSizePixel = 0;
		ZIndex = 201;
		Parent = WatermarkOuter;
	})
	Library:Create('UICorner', {
		CornerRadius = UDim.new(0, 9);
		Parent = WatermarkInner;
	})
	Library:AddToRegistry(WatermarkInner, {
		BackgroundColor3 = 'MainColor';
	}, true)
	local WatermarkAccent = Library:Create('Frame', {
		Position = UDim2.fromOffset(8, 8);
		Size = UDim2.new(0, 2, 1, -16);
		BackgroundColor3 = Library.AccentColor;
		BorderSizePixel = 0;
		ZIndex = 202;
		Parent = WatermarkInner;
	})
	Library:AddToRegistry(WatermarkAccent, { BackgroundColor3 = 'AccentColor' }, true)

	local WatermarkText = Library:Create('TextLabel', {
		Position = UDim2.new(0, 19, 0, 3);
		Size = UDim2.new(1, -27, 1, -6);
		BorderSizePixel = 0;
		BackgroundTransparency = 1;
		Text = '';
		TextColor3 = Library.FontColor;
		TextSize = 14;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextStrokeTransparency = 1;
		AutoLocalize = false;
		RichText = true;
		ZIndex = 203;
		Parent = WatermarkInner;
	})
	local sectionSpecs = {
		{ Name = "Brand", Bold = true, Color = Library.FontColor },
		{ Name = "Divider1", Divider = true, Color = Library.AccentColor },
		{ Name = "Player", Color = Library.FontColor },
		{ Name = "Divider2", Divider = true, Color = Library.AccentColor },
		{ Name = "FPS", Color = Library.AccentColor },
		{ Name = "Divider3", Divider = true, Color = Library.AccentColor },
		{ Name = "Ping", Color = Library.AccentColor },
	}
	local watermarkSections = {}
	for _, spec in ipairs(sectionSpecs) do
		local label = Library:Create('TextLabel', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.fromOffset(0, 0);
			Size = UDim2.fromOffset(0, 32);
			FontFace = spec.Bold and lexend.bold or lexend.regular;
			Text = "";
			TextColor3 = spec.Color;
			TextSize = 14;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextStrokeTransparency = 1;
			AutoLocalize = false;
			Visible = false;
			ZIndex = 203;
			Parent = WatermarkInner;
		})
		Library:AddToRegistry(label, {
			TextColor3 = spec.Divider and "AccentColor"
				or (spec.Bold and "FontColor" or (spec.Name == "Player" and Color3.new(1, 1, 1) or "AccentColor")),
		}, true)
		watermarkSections[spec.Name] = label
	end

	task.spawn(function()
		WatermarkText.FontFace = lexend.regular;
	end);

	Library:ApplyTextStroke(WatermarkText)

	Library:AddToRegistry(WatermarkText, {
		TextColor3 = 'FontColor';
	}, true)

	Library.Watermark = WatermarkOuter
	Library.WatermarkText = WatermarkText
	Library.WatermarkSections = watermarkSections
	Library:MakeDraggable(Library.Watermark)
	Library.HudTransparency = 0.18
	function Library:SetHudTransparency(value)
		Library.HudTransparency = math.clamp(tonumber(value) or 0.18, 0, 0.8)
		local backgroundTransparency = Library.HudTransparency
		WatermarkOuter.BackgroundTransparency = backgroundTransparency
		WatermarkInner.BackgroundTransparency = backgroundTransparency
		WatermarkStroke.Transparency = math.clamp(backgroundTransparency + 0.15, 0, 0.95)
		local keybindFrame = Library.KeybindFrame
		if keybindFrame then
			keybindFrame.BackgroundTransparency = backgroundTransparency
		end
		local keybindInner = Library.KeybindInner
		if keybindInner then
			keybindInner.BackgroundTransparency = backgroundTransparency
		end
		local keybindHeader = Library.KeybindHeader
		if keybindHeader then
			keybindHeader.BackgroundTransparency = backgroundTransparency
		end
		for _, row in ipairs(Library.KeybindContainer and Library.KeybindContainer:GetChildren() or {}) do
			if row:IsA("TextLabel") then
				row.BackgroundTransparency = backgroundTransparency
				local badge = row:FindFirstChild("HotkeyKeyBadge")
				if badge then
					badge.BackgroundTransparency = backgroundTransparency
				end
				local modeBadge = row:FindFirstChild("HotkeyModeBadge")
				if modeBadge then
					modeBadge.BackgroundTransparency = backgroundTransparency
				end
			end
		end
		local targetHUD = Library.TargetHUDFrame
		if targetHUD then
			targetHUD.BackgroundTransparency = backgroundTransparency
		end
		local preview = Library.ESPPreviewFrame
		if preview then
			preview.BackgroundTransparency = backgroundTransparency
		end
		local previewHeader = Library.ESPPreviewHeader
		if previewHeader then
			previewHeader.BackgroundTransparency = backgroundTransparency
		end
		local previewViewport = Library.ESPPreviewViewport
		if previewViewport then
			previewViewport.BackgroundTransparency = backgroundTransparency
		end
	end

	local watermarkGradient
	local watermarkGradientTween
	local watermarkGradientDuration
	function Library:SetWatermarkGradient(enabled, startColor, endColor, duration)
		if not enabled then
			if watermarkGradientTween then
				watermarkGradientTween:Cancel()
				watermarkGradientTween = nil
			end
			if watermarkGradient then
				watermarkGradient:Destroy()
				watermarkGradient = nil
			end
			WatermarkStroke.Color = Library.AccentColor
			watermarkGradientDuration = nil
			local brand = watermarkSections.Brand
			if brand then
				brand.TextColor3 = Library.FontColor
			end
			return
		end
		startColor = typeof(startColor) == "Color3" and startColor or Library.AccentColor
		endColor = typeof(endColor) == "Color3" and endColor or Library.AccentColorDark
		local brand = watermarkSections.Brand
		if not watermarkGradient or watermarkGradient.Parent ~= brand then
			watermarkGradient = Library:Create("UIGradient", {
				Rotation = 0;
				Parent = brand;
			})
		end
		watermarkGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, startColor);
			ColorSequenceKeypoint.new(0.5, endColor);
			ColorSequenceKeypoint.new(1, startColor);
		})
		WatermarkStroke.Color = Color3.new(1, 1, 1)
		duration = math.clamp(tonumber(duration) or 5, 1, 12)
		if watermarkGradientDuration ~= duration then
			if watermarkGradientTween then
				watermarkGradientTween:Cancel()
				watermarkGradientTween = nil
			end
			watermarkGradientDuration = duration
			watermarkGradient.Offset = Vector2.new(-1, 0)
			watermarkGradientTween = TweenService:Create(
				watermarkGradient,
				TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
				{ Offset = Vector2.new(1, 0) }
			)
			watermarkGradientTween:Play()
		end
	end

	function Library:SetWatermarkVisibility(Bool)
		Library.Watermark.Visible = Bool
	end

	function Library:SetWatermark(Text, RText, Sections)
		if not Library.Watermark.Visible then
			return
		end

		local Scale = Library:GetUIScale()
		local TextSize = Library.WatermarkText.TextSize
		if type(Sections) == "table" then
			local content = {
				Brand = tostring(Sections.Brand or ""),
				Player = tostring(Sections.Player or ""),
				FPS = tostring(Sections.FPS or ""),
				Ping = tostring(Sections.Ping or ""),
			}
			local order = { "Brand", "Player", "FPS", "Ping" }
			local x = 18
			for index, name in ipairs(order) do
				local label = watermarkSections[name]
				local fontFace = name == "Brand" and lexend.bold or lexend.regular
				local width = Library:GetLexendTextBounds(content[name], fontFace, TextSize * Scale) / Scale
				label.Text = content[name]
				label.Position = UDim2.fromOffset(x, 0)
				label.Size = UDim2.fromOffset(width + 2, 32)
				label.Visible = content[name] ~= ""
				x += width + 2
				if index < #order then
					local divider = watermarkSections["Divider" .. index]
					local dividerWidth = Library:GetLexendTextBounds("│", lexend.regular, TextSize * Scale) / Scale
					divider.Position = UDim2.fromOffset(x + 5, 0)
					divider.Size = UDim2.fromOffset(dividerWidth + 2, 32)
					divider.Text = "│"
					divider.Visible = true
					x += dividerWidth + 15
				end
			end
			WatermarkText.Visible = false
			local totalWidth = x + 8
			Library.Watermark.Size = UDim2.fromOffset(totalWidth, 36)
			local oldPos = Library.Watermark.Position
			if oldPos.X.Scale > 0.4 and oldPos.X.Scale < 0.6 then
				Library.Watermark.Position = UDim2.new(oldPos.X.Scale, -totalWidth / 2, oldPos.Y.Scale, oldPos.Y.Offset)
			end
			return
		end

		for _, label in pairs(watermarkSections) do
			label.Visible = false
		end
		WatermarkText.Visible = true
		local X = Library:GetLexendTextBounds(RText, lexend.regular, TextSize * Scale) / Scale
		Library.Watermark.Size = UDim2.new(0, X + 42, 0, 36)
		Library.WatermarkText.Text = Text
		local oldPos = Library.Watermark.Position
		if oldPos.X.Scale > 0.4 and oldPos.X.Scale < 0.6 then
			Library.Watermark.Position = UDim2.new(oldPos.X.Scale, -((X + 42) / 2), oldPos.Y.Scale, oldPos.Y.Offset)
		end

	end

	function Library:Notify(Text, Time)
		Text = tostring(Text)
		local Scale = Library:GetUIScale()
		local camera = workspace.CurrentCamera
		local viewportWidth = camera and camera.ViewportSize.X / Scale or 800
		local maxWidth = math.max(120, math.min(520, viewportWidth - 16))
		NotificationArea.Size = UDim2.fromOffset(maxWidth, NotificationArea.Size.Y.Offset)
		local textWidth = math.max(40, maxWidth - 28) * Scale
		local bounds = game:GetService("TextService"):GetTextSize(
			Text,
			16 * Scale,
			Enum.Font.Gotham,
			Vector2.new(textWidth, 1000)
		)
		local XSize = math.min(maxWidth, bounds.X / Scale + 28)
		local YSize = math.clamp(bounds.Y / Scale + 20, 42, 108)
		local TweenDuration = 0.4

		local NotifyOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, 10);
			Size = UDim2.new(0, 0, 0, YSize);
			ClipsDescendants = true;
			Active = true;
			ZIndex = 100;
			Parent = NotificationArea;
		})

		local NotifyInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BackgroundTransparency = 1;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 101;
			Parent = NotifyOuter;
		})

		Library:AddToRegistry(NotifyInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		}, true)

		local InnerFrame = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Active = true;
			Position = UDim2.new(0, 1, 0, 1);
			Size = UDim2.new(1, -2, 1, -2);
			ZIndex = 102;
			Parent = NotifyInner;
		})

		Library:AddToRegistry(InnerFrame, {
			BackgroundColor3 = Library.MainColor
		})
		local NotifyLabel, NotifyStroke = Library:CreateLabel({
			Position = UDim2.new(0, 10, 0, 0);
			Size = UDim2.new(1, -18, 1, 0);
			Text = Text;
			TextWrapped = true;
			TextTruncate = Enum.TextTruncate.AtEnd;
			TextTransparency = 1;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextSize = 16;
			ZIndex = 103;
			Parent = InnerFrame;
		})

		task.spawn(function()
			NotifyLabel.FontFace = lexend.regular;
		end);

		local LeftColor = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0, -1, 0, -1);
			Size = UDim2.new(0, 3, 1, 2);
			ZIndex = 104;
			Parent = NotifyOuter;
		})

		Library:AddToRegistry(LeftColor, {
			BackgroundColor3 = 'AccentColor';
		}, true)

		local destroyed = false

		local function destroyObject()
			if destroyed then
				return
			end

			destroyed = true
			pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', TweenDuration, true)
			TweenService:Create(NotifyOuter, TweenInfo.new(TweenDuration), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(NotifyInner, TweenInfo.new(TweenDuration), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(InnerFrame, TweenInfo.new(TweenDuration), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(NotifyLabel, TweenInfo.new(TweenDuration), { TextTransparency = 1 }):Play()
			TweenService:Create(LeftColor, TweenInfo.new(TweenDuration), { BackgroundTransparency = 1 }):Play()

			task.wait(TweenDuration)
			NotifyOuter:Destroy()
		end

		InnerFrame.InputBegan:Connect(function(input)
			beginNotificationDrag(input, destroyObject)
		end)
		pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize, 0, YSize), 'Out', 'Quad', TweenDuration, true)

		TweenService:Create(NotifyOuter, TweenInfo.new(TweenDuration), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(NotifyInner, TweenInfo.new(TweenDuration), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(InnerFrame, TweenInfo.new(TweenDuration), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(NotifyLabel, TweenInfo.new(TweenDuration), { TextTransparency = 0 }):Play()
		TweenService:Create(LeftColor, TweenInfo.new(TweenDuration), { BackgroundTransparency = 0 }):Play()
        TweenService:Create(NotifyStroke, TweenInfo.new(TweenDuration), { Transparency = 0 }):Play()


		task.spawn(function() 
			task.wait(Time or 5) 
			destroyObject()
		end) 
	end

	function Library:NotifyWithSound(Text, Time)
		if aztup and aztup_toggles and aztup_toggles.notification_sound and aztup_toggles.notification_sound.Value and not aztup.silent_mode then
			xpcall(function()
				local sound = Instance.new('Sound', game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui'))
				game:GetService('Debris'):AddItem(sound, 6)
				sound.Volume = aztup_options.NotificationVolume.Value
				sound.SoundId = getcustomasset('Project Rain/assets/notification.mp3')
				sound:Play()
			end, warn)
		end

		Library:Notify(Text, Time)
	end

	return Component
end
	end,
