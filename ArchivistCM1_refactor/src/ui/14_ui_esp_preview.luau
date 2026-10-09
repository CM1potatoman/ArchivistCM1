	["@src/ui/esp_preview"] = function()
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

return function(library)
	local screenGui = library.ScreenGui
	local frame = library:Create("Frame", {
		Name = "YSL_ESPPreview",
		AnchorPoint = Vector2.zero,
		BackgroundColor3 = library.MainColor,
		BackgroundTransparency = library.HudTransparency or 0.18,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(270, 230),
		Visible = true,
		ZIndex = 500,
		Parent = screenGui,
	})
	library.ESPPreviewFrame = frame
	library:AddUIScale(frame)
	library.ESPPreviewCorner = library:Create("UICorner", {
		CornerRadius = UDim.new(0, 0),
		Parent = frame,
	})
	library.ESPPreviewCornerDefault = library.ESPPreviewCorner.CornerRadius
	local previewStroke = library:Create("UIStroke", {
		Color = library.AccentColor,
		Thickness = 3,
		Transparency = 0.25,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame,
	})
	library:AddWindowGradientStroke(previewStroke)
	library:AddToRegistry(frame, {
		BackgroundColor3 = "MainColor",
	}, true)

	local header = library:Create("Frame", {
		BackgroundColor3 = library.BackgroundColor,
		BackgroundTransparency = math.clamp((library.HudTransparency or 0.18) - 0.08, 0, 0.8),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		ZIndex = 501,
		Parent = frame,
	})
	library.ESPPreviewHeader = header
	library:AddToRegistry(header, {
		BackgroundColor3 = "BackgroundColor",
	}, true)
	local title = library:CreateLabel({
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(11, 0),
		Size = UDim2.new(1, -22, 1, 0),
		Text = "ESP Preview",
		TextColor3 = library.FontColor,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 1,
		ZIndex = 502,
		Parent = header,
	})
	title.FontFace = lexend.bold
	library:AddToRegistry(title, {
		TextColor3 = "FontColor",
	}, true)

	local viewport = library:Create("ViewportFrame", {
		BackgroundColor3 = library.BackgroundColor,
		BackgroundTransparency = math.clamp((library.HudTransparency or 0.18) + 0.1, 0, 0.9),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 38),
		Size = UDim2.new(1, -20, 1, -48),
		Ambient = Color3.fromRGB(170, 170, 170),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
		ZIndex = 501,
		Parent = frame,
	})
	library.ESPPreviewViewport = viewport
	library:AddToRegistry(viewport, {
		BackgroundColor3 = "BackgroundColor",
	}, true)

	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 34
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local previewCharacter
	local previewBoundsSize
	local characterGeneration = 0
	local function showCharacter(character)
		characterGeneration += 1
		local generation = characterGeneration
		if previewCharacter then
			previewCharacter:Destroy()
			previewCharacter = nil
		end
		if not character or not character.Parent then
			return
		end

		local archivableStates = {}
		local function makeArchivable(instance)
			archivableStates[instance] = instance.Archivable
			instance.Archivable = true
		end
		makeArchivable(character)
		for _, descendant in ipairs(character:GetDescendants()) do
			makeArchivable(descendant)
		end
		local cloneSuccess, characterClone = pcall(function()
			return character:Clone()
		end)
		for instance, wasArchivable in pairs(archivableStates) do
			if instance.Parent then
				instance.Archivable = wasArchivable
			end
		end
		if not cloneSuccess then
			warn("[YSL Method] ESP preview character clone failed: " .. tostring(characterClone))
			return
		end
		if not characterClone then
			warn("[YSL Method] ESP preview character clone returned no model")
			return
		end

		characterClone.Name = "YSL_ESPPreviewCharacter"
		for _, descendant in ipairs(characterClone:GetDescendants()) do
			if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
				descendant:Destroy()
			elseif descendant:IsA("BasePart") then
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
			elseif descendant:IsA("Humanoid") then
				descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			elseif descendant:IsA("BillboardGui") or descendant:IsA("ProximityPrompt") then
				descendant:Destroy()
			end
		end

		characterClone.Parent = world
		local boundsCFrame, boundsSize = characterClone:GetBoundingBox()
		if boundsSize.Y <= 0 then
			characterClone:Destroy()
			return
		end
		local rootPart = characterClone:FindFirstChild("HumanoidRootPart")
		local lookVector = rootPart and rootPart.CFrame.LookVector or boundsCFrame.LookVector
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		local yawCorrection = flatLook.Magnitude > 0.001
			and -math.atan2(flatLook.X, flatLook.Z)
			or math.pi
		local targetBounds = CFrame.new(0, boundsSize.Y / 2, 0)
			* CFrame.Angles(0, yawCorrection, 0)
			* boundsCFrame.Rotation
		local pivotDelta = targetBounds * boundsCFrame:Inverse()
		characterClone:PivotTo(pivotDelta * characterClone:GetPivot())

		if generation ~= characterGeneration then
			characterClone:Destroy()
			return
		end
		previewCharacter = characterClone
		previewBoundsSize = boundsSize
		local distance = boundsSize.Y / (2 * math.tan(math.rad(camera.FieldOfView / 2))) * 1.2
		camera.CFrame = CFrame.lookAt(
			Vector3.new(0, boundsSize.Y / 2, distance),
			Vector3.new(0, boundsSize.Y / 2, 0)
		)
	end

	local localPlayer = game:GetService("Players").LocalPlayer
	if localPlayer then
		library:GiveSignal(localPlayer.CharacterAdded:Connect(function(character)
			showCharacter(character)
			localPlayer.CharacterAppearanceLoaded:Once(function(loadedCharacter)
				if loadedCharacter == character and localPlayer.Character == character then
					showCharacter(character)
				end
			end)
		end))
		if localPlayer.Character then
			showCharacter(localPlayer.Character)
		end
	end

	local boxOutline = library:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.42, 4, 0.78, 4),
		Visible = false,
		ZIndex = 502,
		Parent = viewport,
	})
	local boxOutlineStroke = library:Create("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Transparency = 0.15,
		Thickness = 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter,
		Parent = boxOutline,
	})
	local box = library:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = library.AccentColor,
		BackgroundTransparency = 0.97,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.42, 0, 0.78, 0),
		Visible = false,
		ZIndex = 503,
		Parent = viewport,
	})
	local boxStroke = library:Create("UIStroke", {
		Color = library.AccentColor,
		Thickness = 1.5,
		Transparency = 0.08,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Miter,
		Parent = box,
	})

	local healthTrack = library:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(8, 12, 14),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.25, 0, 0.5, 0),
		Size = UDim2.new(0, 8, 0.72, 0),
		Visible = false,
		ZIndex = 504,
		Parent = viewport,
	})
	library:Create("UIStroke", {
		Color = Color3.new(0, 0, 0),
		Transparency = 0.08,
		Thickness = 1.5,
		Parent = healthTrack,
	})
	local healthFill = library:Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(187, 255, 181),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 505,
		Parent = healthTrack,
	})
	local healthGradient = library:Create("UIGradient", {
		Color = ColorSequence.new(
			Color3.fromRGB(187, 255, 181),
			Color3.fromRGB(187, 255, 181):Lerp(Color3.new(1, 1, 1), 0.2)
		),
		Rotation = -90,
		Parent = healthFill,
	})
	local healthDividers = {}
	for _, fraction in ipairs({ 0.2, 0.4, 0.6, 0.8 }) do
		local divider = library:Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(8, 12, 14),
			BackgroundTransparency = 0.18,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1 - fraction, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 506,
			Parent = healthTrack,
		})
		table.insert(healthDividers, divider)
	end

	local nameTag, nameTagStroke = library:CreateLabel({
		BackgroundColor3 = library.BackgroundColor,
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.1, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.9, 0, 0, 20),
		Text = "",
		TextColor3 = library.FontColor,
		TextSize = 11,
		TextStrokeTransparency = 0.2,
		ZIndex = 504,
		Parent = viewport,
	})
	nameTag.Visible = false
	nameTag.FontFace = lexend.regular
	nameTag.TextTransparency = 0.2
	nameTagStroke.Transparency = 0.2
	library:AddToRegistry(nameTag, {
		TextColor3 = "FontColor",
		BackgroundColor3 = "BackgroundColor",
	}, true)
	local bottomTag, bottomTagStroke = library:CreateLabel({
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.88, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.9, 0, 0, 18),
		Text = "",
		TextColor3 = library.FontColor,
		TextSize = 11,
		TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 504,
		Parent = viewport,
	})
	bottomTag.Visible = false
	bottomTag.FontFace = library.Font
	bottomTag.TextTransparency = 0.2
	bottomTagStroke.Transparency = 0.2
	library:AddToRegistry(bottomTag, {
		TextColor3 = "FontColor",
	}, true)

	local ultimateTrack = library:Create("Frame", {
		BackgroundColor3 = library.BackgroundColor,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.24, 0, 0.92, 0),
		Size = UDim2.new(0.52, 0, 0, 5),
		Visible = false,
		ZIndex = 504,
		Parent = viewport,
	})
	local ultimateFill = library:Create("Frame", {
		BackgroundColor3 = library.AccentColorDark or library:GetDarkerColor(library.AccentColor),
		BorderSizePixel = 0,
		Size = UDim2.new(0.72, 0, 1, 0),
		ZIndex = 505,
		Parent = ultimateTrack,
	})
	library:AddToRegistry(ultimateFill, {
		BackgroundColor3 = function()
			return library.AccentColorDark or library:GetDarkerColor(library.AccentColor)
		end,
	}, true)

	local secondUltimateFill = library:Create("Frame", {
		BackgroundColor3 = library.FontColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 2),
		Size = UDim2.new(0.38, 0, 0, 3),
		Visible = false,
		ZIndex = 505,
		Parent = ultimateTrack,
	})
	library:AddToRegistry(secondUltimateFill, {
		BackgroundColor3 = "FontColor",
	}, true)

	local moveCards = {}
	for index = 1, 4 do
		local card = library:Create("Frame", {
			BackgroundColor3 = library.BackgroundColor,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			Position = UDim2.new(0.79, 0, 0.16, (index - 1) * 35),
			Size = UDim2.fromOffset(30, 30),
			Visible = false,
			ZIndex = 504,
			Parent = viewport,
		})
		local cardStroke = library:Create("UIStroke", {
			Color = library.AccentColor,
			Thickness = 1,
			Transparency = 0.2,
			Parent = card,
		})
		library:AddWindowGradientStroke(cardStroke)
		library:AddToRegistry(cardStroke, {
			Color = "AccentColor",
		}, true)
		library:AddToRegistry(card, {
			BackgroundColor3 = "BackgroundColor",
		}, true)
		local cardLabel = library:CreateLabel({
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = tostring(index),
			TextColor3 = library.FontColor,
			TextSize = 12,
			TextStrokeTransparency = 1,
			ZIndex = 505,
			Parent = card,
		})
		library:AddToRegistry(cardLabel, {
			TextColor3 = "FontColor",
		}, true)
		moveCards[index] = card
	end

	local infoTag = library:CreateLabel({
		BackgroundColor3 = library.BackgroundColor,
		BackgroundTransparency = 0.18,
		Position = UDim2.new(0.5, 0, 0.83, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(118, 18),
		Text = "INFO / STATUS",
		TextColor3 = library.AccentColor,
		TextSize = 9,
		TextStrokeTransparency = 1,
		Visible = false,
		ZIndex = 504,
		Parent = viewport,
	})
	library:AddToRegistry(infoTag, {
		TextColor3 = "AccentColor",
		BackgroundColor3 = "BackgroundColor",
	}, true)

	local options = {
		Boxes = false,
		Health = false,
		Ultimate = false,
		Moves = false,
		Info = false,
		Names = true,
	}
	local playerESP
	local healthFractions = { 0.2, 0.4, 0.6, 0.8 }
	local appliedBoundsSize
	local function refreshOptions()
		if playerESP then
			local settings = playerESP:GetPreviewSettings()
			local enabled = settings.Enabled == true
			box.Visible = enabled and settings.Boxes == true
			boxOutline.Visible = box.Visible
			healthTrack.Visible = enabled and settings.Healthbar == true
			nameTag.Visible = enabled and settings.Names == true
			bottomTag.Visible = nameTag.Visible
		else
			box.Visible = options.Boxes
			boxOutline.Visible = options.Boxes
			healthTrack.Visible = options.Health
			nameTag.Visible = options.Names
			bottomTag.Visible = options.Names
		end
		ultimateTrack.Visible = options.Ultimate
		secondUltimateFill.Visible = options.Ultimate and options.SecondUltimate
		for _, card in ipairs(moveCards) do
			card.Visible = options.Moves
		end
		infoTag.Visible = options.Info
	end

	local function updatePlayerEspPreview()
		if not playerESP then
			return
		end
		local settings = playerESP:GetPreviewSettings()
		local enabled = settings.Enabled == true
		local tags = settings.Tags or {}
		box.Visible = enabled and settings.Boxes == true
		boxOutline.Visible = box.Visible
		healthTrack.Visible = enabled and settings.Healthbar == true
		nameTag.Visible = enabled and settings.Names == true
		bottomTag.Visible = nameTag.Visible
		if not enabled or not previewCharacter then
			return
		end

		local character = game:GetService("Players").LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid then
			nameTag.Text = ""
			bottomTag.Text = ""
			return
		end

		local boxColor = settings.BoxColor or library.AccentColor
		boxStroke.Color = boxColor
		box.BackgroundColor3 = library.AccentColor
		boxOutline.Size = UDim2.new(box.Size.X.Scale, 4, box.Size.Y.Scale, 4)
		local textTransparency = 0.2
		if settings.Fadeout and root then
			local cameraObject = workspace.CurrentCamera
			local distance = cameraObject and (cameraObject.CFrame.Position - root.Position).Magnitude or 0
			if distance > settings.FadeoutDistance then
				local fadeDistance = math.max(settings.FadeoutDistance, 1)
				textTransparency = math.clamp(
					0.2 + math.min(1, (distance - fadeDistance) / fadeDistance) * 0.8,
					0.2,
					1
				)
			end
		end
		nameTag.TextTransparency = textTransparency
		nameTagStroke.Transparency = textTransparency
		bottomTag.TextTransparency = textTransparency
		bottomTagStroke.Transparency = textTransparency
		local healthRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		local healthColor = Color3.fromHSV(healthRatio * 0.33, 0.82, 1)
		healthFill.Size = UDim2.new(1, 0, healthRatio, 0)
		healthFill.BackgroundColor3 = healthColor
		healthGradient.Color = ColorSequence.new(
			healthColor:Lerp(Color3.new(1, 1, 1), 0.2),
			healthColor
		)
		for index, divider in ipairs(healthDividers) do
			divider.Visible = healthRatio > healthFractions[index]
		end

		nameTag.TextColor3 = settings.NameColor
		nameTagStroke.Color = settings.NameOutlineColor
		bottomTag.TextColor3 = settings.NameColor
		bottomTagStroke.Color = settings.NameOutlineColor
		nameTag.TextSize = math.clamp(settings.TextSize or 12, 6, 18)
		bottomTag.TextSize = nameTag.TextSize
		local topParts = {}
		if tags["Roblox Display Name"] then
			table.insert(topParts, game:GetService("Players").LocalPlayer.DisplayName)
		end
		if tags["Roblox Player Name"] then
			table.insert(topParts, game:GetService("Players").LocalPlayer.Name)
		end
		if tags["Health %"] then
			table.insert(topParts, string.format("(%d%%)", math.floor(healthRatio * 100)))
		end
		if tags["HP/Max"] then
			table.insert(topParts, string.format(
				"(%d/%dhp)",
				math.floor(humanoid.Health + 0.5),
				math.floor(math.max(humanoid.MaxHealth, 1) + 0.5)
			))
		end
		if tags.Distance and root then
			local cameraObject = workspace.CurrentCamera
			if cameraObject then
				local distance = (cameraObject.CFrame.Position - root.Position).Magnitude
				local formattedDistance = settings.DistanceInStuds
						and string.format("%ds", math.floor(distance + 0.5))
					or (distance > 1000 and string.format("%.1fkm", distance / 1000)
						or string.format("%dm", math.floor(distance + 0.5)))
				table.insert(topParts, string.format("[%s]", formattedDistance))
			end
		end
		nameTag.Text = table.concat(topParts, " ")

		local bottomParts = {}
		if tags.Ping and character then
			local ping = character:GetAttribute("AveragePing")
			if type(ping) == "number" then
				table.insert(bottomParts, ping > 1000
					and string.format("[%ds]", math.floor(ping / 1000 + 0.5))
					or string.format("[%dms]", math.floor(ping + 0.5)))
			end
		end
		if tags.Agility and character then
			local agility = character:FindFirstChild("PassiveAgility")
			if agility and (agility:IsA("NumberValue") or agility:IsA("IntValue")) and agility.Value > 0 then
				table.insert(bottomParts, string.format("[%i agil]", agility.Value))
			end
		end
		bottomTag.Text = table.concat(bottomParts, " ")
	end

	local function updatePlacement()
		local window = library.WindowHolder
		local cameraObject = workspace.CurrentCamera
		if not window or not window.Parent or not cameraObject then
			return
		end
		local topLeftInset, bottomRightInset = Vector2.zero, Vector2.zero
		if not screenGui.IgnoreGuiInset then
			topLeftInset, bottomRightInset = GuiService:GetGuiInset()
		end
		local viewportSize = cameraObject.ViewportSize - topLeftInset - bottomRightInset
		local windowPosition = window.AbsolutePosition - topLeftInset
		local windowSize = window.AbsoluteSize
		local previewSize = frame.AbsoluteSize
		local gap = 10
		local rightX = windowPosition.X + windowSize.X + gap
		local leftX = windowPosition.X - previewSize.X - gap
		local x = rightX
		if rightX + previewSize.X > viewportSize.X - 8
			and (leftX >= 8 or windowPosition.X > viewportSize.X / 2) then
			x = leftX
		end
		x = math.clamp(x, 8, math.max(8, viewportSize.X - previewSize.X - 8))
		local y = math.clamp(
			windowPosition.Y + 58,
			8,
			math.max(8, viewportSize.Y - previewSize.Y - 8)
		)
		local uiScale = library:GetUIScale()
		frame.Position = UDim2.fromOffset(
			x / uiScale,
			y / uiScale
		)
	end

	local function updateVisibility()
		frame.Visible = library.Toggled == true and library.WindowDragging ~= true
		updatePlacement()
	end
	local function updatePreview()
		if not frame.Visible then
			return
		end
		updatePlacement()
		if previewBoundsSize and previewBoundsSize ~= appliedBoundsSize then
			appliedBoundsSize = previewBoundsSize
			local boxHeight = 0.76
			local boxWidth = math.clamp(
				boxHeight * (previewBoundsSize.X + 0.8) / math.max(previewBoundsSize.Y + 0.4, 0.1),
				0.24,
				0.68
			)
			box.Size = UDim2.new(boxWidth, 0, boxHeight, 0)
			boxOutline.Size = UDim2.new(boxWidth, 4, boxHeight, 4)
			box.Position = UDim2.new(0.5, 0, 0.5, 0)
			boxOutline.Position = box.Position
			healthTrack.Position = UDim2.new(0.5 - boxWidth / 2, -9, 0.5, 0)
			healthTrack.Size = UDim2.new(0, 8, boxHeight * 0.92, 0)
			nameTag.Position = UDim2.new(0.5, 0, 0.5 - boxHeight / 2 - 0.09, 0)
			bottomTag.Position = UDim2.new(0.5, 0, 0.5 + boxHeight / 2 + 0.015, 0)
		end
		updatePlayerEspPreview()
	end
	if library.WindowHolder then
		library:GiveSignal(library.WindowHolder:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePlacement))
		library:GiveSignal(library.WindowHolder:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePlacement))
	end
	library:GiveSignal(screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePlacement))
	library:GiveSignal(library.OnToggledChanged.Event:Connect(updateVisibility))
	library:GiveSignal(library.WindowDraggingChanged.Event:Connect(updateVisibility))
	local viewportSizeConnection
	local function updateCameraBinding()
		if viewportSizeConnection then
			viewportSizeConnection:Disconnect()
			viewportSizeConnection = nil
		end
		local currentCamera = workspace.CurrentCamera
		if currentCamera then
			viewportSizeConnection = currentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updatePlacement)
			library:GiveSignal(viewportSizeConnection)
		end
		updatePlacement()
	end
	library:GiveSignal(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateCameraBinding))
	updateCameraBinding()
	library:GiveSignal(RunService.RenderStepped:Connect(updatePreview))
	updateVisibility()
	refreshOptions()

	return {
		SetPlayerESP = function(_, controller)
			playerESP = controller
			refreshOptions()
		end,
		SetOptions = function(_, newOptions)
			for key, value in pairs(newOptions) do
				options[key] = value
			end
			refreshOptions()
		end,
	}
end
	end,
