	["@src/utility/librarys/components/toggle"] = function()



local signal = require("@src/utility/signal");
local curr_mode_select;
return function(Library, context)
	local InputService = context.InputService
	local Mouse = context.Mouse
	local RenderStepped = context.RenderStepped
	local BaseAddons = context.BaseAddons

	local Component = {}

	function Component.AddToggle(self, Idx, Info)
		assert(Info.Text, 'AddInput: Missing `Text` string.')
		if self.Objects then
			table.insert(self.Objects, {
				internal_name = Idx, settings = Info
			})
		else
			print(self)
		end;
		
		local Toggle: {[string]: any} = {
			Value = Info.Default or false;
			Type = 'Toggle';
			Flag = Idx,
			Name = Info.Text,
			TabName = self.Tab and self.Tab.Name,
			ArrayList = Info.ArrayList ~= false,
			
			Callback = Info.Callback or function(Value) end;
			Addons = {};
			Risky = Info.Risky;
		}

		local Groupbox = self;
		local Container = Groupbox.Container;

		local ToggleRow = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, -4, 0, 18);
			ZIndex = 5;
			Parent = Container;
		})

		local ToggleLabel = Library:CreateLabel({
			Size = UDim2.new(1, -24, 1, 0);
			Position = UDim2.fromOffset(0, 0);
			TextSize = 14;
			Text = Info.Text;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextTruncate = Enum.TextTruncate.AtEnd;
			ZIndex = 6;
			Parent = ToggleRow;
		})

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 4);
			FillDirection = Enum.FillDirection.Horizontal;
			HorizontalAlignment = Enum.HorizontalAlignment.Right;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ToggleLabel;
		})

		local ToggleOuter = Library:Create('Frame', {
			AnchorPoint = Vector2.new(1, 0.5);
			Position = UDim2.new(1, -2, 0.5, 0);
			Size = UDim2.fromOffset(16, 16);
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderSizePixel = 1;
			Active = true;
			ZIndex = 6;
			Parent = ToggleRow;
		})
		Library:AddToRegistry(ToggleOuter, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		})

		local ToggleMark = Library:CreateLabelNoStroke({
			BackgroundTransparency = 1;
			Size = UDim2.fromScale(1, 1);
			Text = '✓';
			TextColor3 = Library.FontColor;
			TextSize = 13;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			Visible = false;
			ZIndex = 8;
			Parent = ToggleOuter;
		})
		ToggleMark.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		local ToggleGlow = Library:Create('Frame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.fromScale(1, 1);
			ZIndex = 7;
			Parent = ToggleOuter;
		})
		local setToggleGlow = Library:AddAccentGlow(ToggleGlow, false, false, 0.55)

		local ToggleRegion = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.fromScale(1, 1);
			Active = true;
			ZIndex = 9;
			Parent = ToggleOuter;
		})
		ToggleRegion.MouseEnter:Connect(function()
			setToggleGlow(true)
		end)
		ToggleRegion.MouseLeave:Connect(function()
			setToggleGlow(false)
		end)

		Library:OnHighlight(ToggleRegion, ToggleOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = function()
				return Toggle.Value and Library.AccentColor or Library.OutlineColor
			end }
		)

		function Toggle:UpdateColors()
			Toggle:Display();
		end;

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, ToggleRegion)
		end

		function Toggle:Display()
			ToggleRow.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor
			ToggleRow.BackgroundTransparency = 1
			ToggleRow.Size = UDim2.new(1, -4, 0, 18)
			ToggleLabel.Size = UDim2.new(1, -24, 1, 0)
			ToggleLabel.TextSize = 14
			ToggleOuter.Visible = true
			ToggleOuter.BackgroundColor3 = Library.MainColor;
			Library.RegistryMap[ToggleOuter].Properties.BackgroundColor3 = 'MainColor';
			ToggleOuter.BorderColor3 = Toggle.Value and Library.AccentColor or Library.OutlineColor;
			Library.RegistryMap[ToggleOuter].Properties.BorderColor3 = Toggle.Value and 'AccentColor' or 'OutlineColor';
			ToggleMark.Visible = Toggle.Value
			Groupbox:Resize()
		end;
		Toggle.Row = ToggleRow
		Toggle.Groupbox = Groupbox
		Toggle.RefreshThemeAppearance = Toggle.Display
		Toggle.__internal = signal.new();

		local function showModuleSettings(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton2 then
				return
			end
			if Toggle.SettingsPanel then
				Toggle.SettingsPanel:Destroy()
				Toggle.SettingsPanel = nil
			end

			local settings = {}
			local seenSettings = {}
			local function addSetting(flag, metadata)
				local option = aztup_options[flag]
				if not option or not option.Type or seenSettings[flag] then
					return
				end
				seenSettings[flag] = true
				local value = option.Value
				local displayValue
				if typeof(value) == "Color3" then
					displayValue = string.format("#%02X%02X%02X",
						math.floor(value.R * 255 + 0.5),
						math.floor(value.G * 255 + 0.5),
						math.floor(value.B * 255 + 0.5)
					)
				elseif type(value) == "table" then
					local values = {}
					for key, selected in pairs(value) do
						if selected then
							table.insert(values, tostring(key))
						end
					end
					table.sort(values)
					displayValue = #values > 0 and table.concat(values, ", ") or "none"
				else
					displayValue = tostring(value)
				end
				table.insert(settings, {
					Name = option.Name or option.Text or option.Title or (metadata and metadata.Text) or flag,
					Value = displayValue,
				})
			end

			for _, flag in ipairs(Info.SettingsFlags or {}) do
				addSetting(flag)
			end

			local foundToggle = false
			for _, object in ipairs(Groupbox.Objects or {}) do
				if object.internal_name == Idx then
					foundToggle = true
				elseif foundToggle then
					local option = aztup_options[object.internal_name]
					if option and option.Type == "Toggle" then
						break
					end
					addSetting(object.internal_name, object.settings)
				end
			end

			local rowHeight = 18
			local visibleCount = math.min(#settings, 12)
			local extraRowCount = #settings > visibleCount and 1 or 0
			local panelHeight = 32 + math.max(1, visibleCount + extraRowCount) * rowHeight
			local panel = Library:Create("Frame", {
				Name = "ModuleSettings_" .. tostring(Idx),
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Library.AccentColor,
				BorderSizePixel = 1,
				Position = UDim2.fromOffset(Mouse.X + 8, Mouse.Y + 8),
				Size = UDim2.fromOffset(260, panelHeight),
				ZIndex = 200,
				Parent = Library.ScreenGui,
			})
			Toggle.SettingsPanel = panel
			Library:Create("TextLabel", {
				BackgroundColor3 = Library.MainColor,
				BorderSizePixel = 0,
				FontFace = Library.Font,
				Position = UDim2.fromOffset(1, 1),
				Size = UDim2.new(1, -2, 0, 24),
				Text = Toggle.Name .. " settings",
				TextColor3 = Library.AccentColor,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 201,
				Parent = panel,
			})

			if #settings == 0 then
				Library:Create("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Library.Font,
					Position = UDim2.fromOffset(6, 29),
					Size = UDim2.new(1, -12, 0, rowHeight),
					Text = "No module settings in this group.",
					TextColor3 = Library.FontColor,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 201,
					Parent = panel,
				})
			else
				for index = 1, visibleCount do
					local setting = settings[index]
					Library:Create("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Library.Font,
						Position = UDim2.fromOffset(6, 27 + (index - 1) * rowHeight),
						Size = UDim2.new(1, -12, 0, rowHeight),
						Text = string.format("%s: %s", setting.Name, setting.Value),
						TextColor3 = Library.FontColor,
						TextSize = 11,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 201,
						Parent = panel,
					})
				end
				if #settings > visibleCount then
					Library:Create("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Library.Font,
						Position = UDim2.fromOffset(6, 27 + visibleCount * rowHeight),
						Size = UDim2.new(1, -12, 0, rowHeight),
						Text = string.format("+ %d more; use the controls in this group.", #settings - visibleCount),
						TextColor3 = Library.FontColor,
						TextSize = 10,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 201,
						Parent = panel,
					})
				end
			end

			local closeConnection
			closeConnection = InputService.InputBegan:Connect(function(closeInput)
				if closeInput.UserInputType ~= Enum.UserInputType.MouseButton1
					and closeInput.UserInputType ~= Enum.UserInputType.MouseButton2 then
					return
				end
				if panel.Parent then
					panel:Destroy()
				end
				if closeConnection then
					closeConnection:Disconnect()
					closeConnection = nil
				end
				Toggle.SettingsPanel = nil
			end)
			panel.Destroying:Connect(function()
				if closeConnection then
					closeConnection:Disconnect()
					closeConnection = nil
				end
				if Toggle.SettingsPanel == panel then
					Toggle.SettingsPanel = nil
				end
			end)
		end

		function Toggle:OnChanged(Func)
			Toggle.Changed = Func;
			pcall(Func,Toggle.Value);
		end;

		function Toggle:SetValue(Bool)
			Bool = (not not Bool);

			Toggle.Value = Bool;
			Toggle:Display();

			for _, Addon in next, Toggle.Addons do
				if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
					Addon.Toggled = Bool
					Addon:Update()
				end
			end
			Library.ToggleChanged:Fire(Toggle.Value, Toggle.Flag)
			pcall(function()
				Library:SafeCallback(Toggle.Callback, Toggle.Value);
				Library:SafeCallback(Toggle.Changed, Toggle.Value);

				aztup_options.OnlyShowEnabledKeybinds.__internal:fire()
			end)
			Toggle.__internal:fire(Toggle.Value)
			Library:UpdateDependencyBoxes();
		end;

		ToggleRegion.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				Toggle:SetValue(not Toggle.Value)
				Library:AttemptSave();
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
				showModuleSettings(Input)
			end;
		end);
		ToggleLabel.InputBegan:Connect(showModuleSettings)

		if Toggle.Risky then
			Library:RemoveFromRegistry(ToggleLabel)
			ToggleLabel.TextColor3 = Library.RiskColor
			Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
		end

		Toggle:Display();
		if type(Info.Text) == 'string' and Info.Text ~= '' then
			Library:RegisterSearchEntry(Groupbox, {
				Kind = 'Toggle';
				Text = Info.Text;
				Tab = Groupbox.Tab or Groupbox;
				Target = ToggleOuter;
				Focus = function()
					Library:FocusSearchTarget(ToggleOuter)
				end;
			})
		end
		Groupbox:AddBlank(Info.BlankSize or 5 + 2);
		Groupbox:Resize();

		Toggle.TextLabel = ToggleLabel;
		Toggle.Container = Container;
		setmetatable(Toggle, BaseAddons or {})

		aztup_toggles[Idx] = Toggle;

		Library:UpdateDependencyBoxes();

		return Toggle	
end

	function Component.AddKeyPicker(self, Idx, Info)
		local ParentObj = self;
		local ToggleLabel = self.TextLabel;
		local Container = self.Container;
		
		
		

		assert(Info.Default, 'AddKeyPicker: Missing default value.');

		local KeyPicker: {[string]: any} = {
			Value = Info.Default;
			Toggled = false;
			Mode = Info.Mode or 'Toggle'; 
			Type = 'KeyPicker';
			Callback = Info.Callback or function(Value) end;
			ChangedCallback = Info.ChangedCallback or function(New) end;

			SyncToggleState = Info.SyncToggleState or false;
		};
		if ParentObj.Type == "Toggle" then
			ParentObj.ArrayListKeybindId = Idx
		end

		local Modes = Info.Modes or { 'Toggle', 'Hold' };

		self.KeyPicker = {
			Flag = Idx;
			Value = KeyPicker.Value
		}

		if not table.find(Modes, KeyPicker.Mode) then
			KeyPicker.Mode = Modes[1]
		end

		local ContainerLabelTransparencyTween
		local ContainerStrokeTransparencyTween

		local PickOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(0, 28, 0, 15);
			ZIndex = 6;
			Parent = ToggleLabel;
		});

		local PickInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 7;
			Parent = PickOuter;
		});

		Library:AddToRegistry(PickInner, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0);
			TextSize = 13;
			Text = Info.Default;
			TextWrapped = true;
			ZIndex = 8;
			Parent = PickInner;
			Name = "DisplayLabelKeybind";
		});
		DisplayLabel:SetAttribute("YSLBoldKeybind", true)
		DisplayLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold)

		local ModeSelectOuter = Library:Create('Frame', {
			BorderColor3 = Color3.new(0, 0, 0);
			Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
			Size = UDim2.new(0, 60, 0, (((#Modes)+1) * 15) + 2);
			Visible = false;
			ZIndex = 14;
			Parent = Library.ScreenGui;
		});

		Library:AddUIScale(ModeSelectOuter);

		ToggleLabel:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			ModeSelectOuter.Position = UDim2.fromOffset(ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4, ToggleLabel.AbsolutePosition.Y + 1);
		end);

		local ModeSelectInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 15;
			Parent = ModeSelectOuter;
		});

		Library:AddToRegistry(ModeSelectInner, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ModeSelectInner;
		});

		local ContainerLabel, ContainerStroke = Library:CreateLabel({
			Name = "HotkeyRow",
			TextXAlignment = Enum.TextXAlignment.Left;
			Size = UDim2.new(1, 0, 0, 30);
			TextSize = 14;
			TextYAlignment = Enum.TextYAlignment.Center;
			RichText = true;
			TextStrokeTransparency = 1;
			BackgroundColor3 = Library.BackgroundColor;
			BackgroundTransparency = Library.HudTransparency or 0.18;
			Visible = false;
			ZIndex = 110;
			Parent = Library.KeybindContainer;
		}, true);
		Library:Create("UICorner", {
			CornerRadius = UDim.new(0, 6),
			Parent = ContainerLabel,
		})
		local keyBadge = Library:Create("Frame", {
			Name = "HotkeyKeyBadge",
			BackgroundColor3 = Library.MainColor,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(7, 5),
			Size = UDim2.fromOffset(30, 20),
			ZIndex = 111,
			Parent = ContainerLabel,
		})
		Library:AddToRegistry(keyBadge, {
			BackgroundColor3 = "MainColor",
		}, true)
		Library:Create("UICorner", {
			CornerRadius = UDim.new(0, 4),
			Parent = keyBadge,
		})
		local keyBadgeLabel = Library:CreateLabelNoStroke({
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextStrokeTransparency = 1,
			ZIndex = 112,
			Parent = keyBadge,
		}, true, lexend.bold)
		keyBadgeLabel:SetAttribute("YSLBoldKeybind", true)
		keyBadgeLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		local modeBadge = Library:Create("Frame", {
			Name = "HotkeyModeBadge",
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Library.MainColor,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -7, 0.5, 0),
			Size = UDim2.fromOffset(52, 18),
			ZIndex = 111,
			Parent = ContainerLabel,
		})
		Library:AddToRegistry(modeBadge, {
			BackgroundColor3 = "MainColor",
		}, true)
		Library:Create("UICorner", {
			CornerRadius = UDim.new(0, 8),
			Parent = modeBadge,
		})
		local modeBadgeLabel = Library:CreateLabelNoStroke({
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextSize = 9,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextStrokeTransparency = 1,
			ZIndex = 112,
			Parent = modeBadge,
		}, true, lexend.bold)
		modeBadgeLabel.FontFace = Font.fromEnum(Enum.Font.GothamBold)
		Library:AddToRegistry(modeBadgeLabel, {
			TextColor3 = "FontColor",
		}, true)
		local actionLabel = Library:CreateLabel({
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(50, 0),
			Size = UDim2.new(1, -108, 1, 0),
			Text = "",
			TextSize = 14,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextStrokeTransparency = 1,
			ZIndex = 111,
			Parent = ContainerLabel,
		}, true, lexend.regular)
		Library:AddToRegistry(actionLabel, {
			TextColor3 = "FontColor",
		}, true)
		local labelStroke = ContainerStroke
		labelStroke.Color = Library.OutlineColor
		labelStroke.Transparency = 0.4
		Library:AddToRegistry(labelStroke, {
			Color = function()
				return KeyPicker:GetState() and Library.AccentColor or Library.OutlineColor
			end,
		}, true)

		local function escapeRichText(value)
			return tostring(value):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
		end
		
		task.spawn(function()
			ContainerLabel.FontFace = lexend.regular;
		end);

		local ModeButtons = {};

		for Idx, Mode in next, Modes do
			local ModeButton = {};

			local Label = Library:CreateLabel({
				Active = false;
				Size = UDim2.new(1, 0, 0, 15);
				TextSize = 13;
				Text = Mode;
				ZIndex = 16;
				Parent = ModeSelectInner;
			});

			function ModeButton:Select()
				for _, Button in next, ModeButtons do
					Button:Deselect();
				end;

				KeyPicker.Mode = Mode;

				Label.TextColor3 = Library.AccentColor;
				Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';
				curr_mode_select = nil;
				ModeSelectOuter.Visible = false;
			end;

			function ModeButton:Deselect()
				KeyPicker.Mode = nil;

				Label.TextColor3 = Library.FontColor;
				Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
			end;

			Label.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					ModeButton:Select();
					Library:AttemptSave();
				end;
			end);

			if Mode == KeyPicker.Mode then
				ModeButton:Select();
			end;

			ModeButtons[Mode] = ModeButton;
		end;

		(function()

			local ModeButton = {};

			local Label = Library:CreateLabel({
				Active = false;
				Size = UDim2.new(1, 0, 0, 15);
				TextSize = 13;
				Text = "Unbind";
				ZIndex = 16;
				Parent = ModeSelectInner;
			});

			function ModeButton:Deselect() end;

			function ModeButton:Select()
				local Key = "None";
				
				DisplayLabel.Text = Key == "None" and "N/A" or Key;
				KeyPicker.Value = Key;
				Library:SafeCallback(KeyPicker.ChangedCallback, Enum.KeyCode.Unknown)
				if KeyPicker.Changed then
					Library:SafeCallback(KeyPicker.Changed, Enum.KeyCode.Unknown)
				end;
				curr_mode_select = nil;
				ModeSelectOuter.Visible = false;
				Library:AttemptSave();
			end;

			Label.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					ModeButton:Select();
					Library:AttemptSave();
				end;
			end);

			ModeButtons.Unbind = ModeButton;
		end)();

		local function UpdateKeybindFrameSize()
			Library.KeybindFrameResizeQueued = false

			if Info.NoUI or not Library.KeybindContainer or not Library.KeybindFrame then
				return
			end

			local YSize = 0
			local XSize = 0
			for _, Label in next, Library.KeybindContainer:GetChildren() do
				if Label:IsA('TextLabel') then
					if Label.Visible and not Label:GetAttribute('KeybindFadingOut') then
						YSize = YSize + 30
					end

					local scale = Library:GetUIScale()
					local action = Label:FindFirstChildWhichIsA("TextLabel")
					local badge = Label:FindFirstChild("HotkeyKeyBadge")
					local modeBadge = Label:FindFirstChild("HotkeyModeBadge")
					local LabelWidth = action
						and Library:GetLexendTextBounds(action.Text, lexend.regular, 14) / scale
						or 0
					LabelWidth += badge and badge.AbsoluteSize.X / scale or 0
					LabelWidth += modeBadge and modeBadge.AbsoluteSize.X / scale or 0
					LabelWidth += 56
					if Label.Visible and (LabelWidth > XSize) then
						XSize = LabelWidth
					end
				end
			end

			local NewHeight = YSize == 0 and 38 or YSize + 40
			local NewWidth = math.max(XSize + 24, 250)
			local properties = {
				Size = UDim2.new(0, NewWidth, 0, NewHeight);
			}

			if Library.KeybindFrameResizeTween then
				Library.KeybindFrameResizeTween:Cancel()
				Library.KeybindFrameResizeTween = nil
			end

			local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local Tween = services.TweenService:Create(Library.KeybindFrame, tweenInfo, properties)
			Library.KeybindFrameResizeTween = Tween

			Tween.Completed:Connect(function()
				if Library.KeybindFrameResizeTween == Tween then
					Library.KeybindFrameResizeTween = nil
				end
			end)

			Tween:Play()
		end

		local function QueueKeybindFrameSize()
			if Library.KeybindFrameResizeQueued then
				return
			end

			Library.KeybindFrameResizeQueued = true
			task.defer(UpdateKeybindFrameSize)
		end

		function KeyPicker:Update()
		    if Info.NoUI then return end

		    local State = KeyPicker:GetState()
		    local shouldHide = (not State and aztup_toggles.OnlyShowEnabledKeybinds and aztup_toggles.OnlyShowEnabledKeybinds.Value)
		                   or (KeyPicker.Value == "None")

			if Info.KeybindOnly then
				State = false;
				shouldHide = (KeyPicker.Value == "None")
			end;

			if #tostring(KeyPicker.Value) == 0 then
			   	shouldHide = true
			end;

		    
			local actionText = escapeRichText(Info.Text)
			local keyWidth = math.clamp(
				Library:GetLexendTextBounds(KeyPicker.Value, lexend.bold, 11) + 14,
				30,
				72
			)
			keyBadge.Size = UDim2.fromOffset(keyWidth, 18)
			keyBadgeLabel.Text = KeyPicker.Value
			local modeText = State and "ACTIVE" or string.upper(tostring(KeyPicker.Mode or "TOGGLE"))
			modeBadgeLabel.Text = modeText
			modeBadge.BackgroundColor3 = State and Library.AccentColorDark or Library.MainColor
			modeBadgeLabel.TextColor3 = Library.FontColor
			Library.RegistryMap[modeBadge].Properties.BackgroundColor3 = State
				and function()
					return Library.AccentColorDark
				end
				or "MainColor"
			Library.RegistryMap[modeBadgeLabel].Properties.TextColor3 = "FontColor"
			keyBadge.BackgroundColor3 = State and Library.AccentColorDark or Library.MainColor
			keyBadgeLabel.TextColor3 = State and Library.FontColor or Library.AccentColor
			Library.RegistryMap[keyBadge].Properties.BackgroundColor3 = State
				and function()
					return Library.AccentColorDark
				end
				or "MainColor"
			Library.RegistryMap[keyBadgeLabel].Properties.TextColor3 = State and "FontColor" or "AccentColor"
			ContainerLabel.Text = ""
			actionLabel.Text = actionText
			actionLabel.Position = UDim2.fromOffset(keyWidth + 14, 0)
			actionLabel.Size = UDim2.new(1, -(keyWidth + 78), 1, 0)
		    local x, _ = Library:GetLexendTextBounds(string.format('[%s]  %s', KeyPicker.Value, Info.Text), lexend.regular, 14)
		    ContainerLabel.LayoutOrder = -x
		    actionLabel.TextColor3 = State and Library.AccentColor or Library.FontColor
		    Library.RegistryMap[actionLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor'
			ContainerLabel.BackgroundColor3 = Library.BackgroundColor
			ContainerLabel.BackgroundTransparency = Library.HudTransparency or 0.18
			Library.RegistryMap[ContainerLabel].Properties.BackgroundColor3 = "BackgroundColor"

		    if shouldHide then
		        
		        if ContainerLabel.Visible and not ContainerLabel:GetAttribute('KeybindFadingOut') then
		            if ContainerLabelTransparencyTween then
		                ContainerLabelTransparencyTween:Cancel()
		                ContainerLabelTransparencyTween = nil
		            end

		            if ContainerStrokeTransparencyTween then
		                ContainerStrokeTransparencyTween:Cancel()
		                ContainerStrokeTransparencyTween = nil
		            end

		            ContainerLabel:SetAttribute('KeybindFadingOut', true)

		            local fadeOut = services.TweenService:Create(actionLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		                TextTransparency = 1
		            })
		            ContainerLabelTransparencyTween = fadeOut
		            fadeOut:Play()

				local strokeFadeOut = services.TweenService:Create(ContainerStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		                Transparency = 1
				})
				ContainerStrokeTransparencyTween = strokeFadeOut
				strokeFadeOut:Play()
				fadeOut.Completed:Connect(function(playbackState)
					if ContainerLabelTransparencyTween ~= fadeOut then
						return
					end

					ContainerLabelTransparencyTween = nil
					ContainerStrokeTransparencyTween = nil

						if playbackState ~= Enum.PlaybackState.Completed or not ContainerLabel.Visible or KeyPicker:GetState() then
						ContainerLabel:SetAttribute('KeybindFadingOut', nil)
							return
						end

						ContainerLabel.Visible = false
					ContainerLabel:SetAttribute('KeybindFadingOut', nil)
						KeyPicker:Update()
		            end)
		        end
		        
		    else
				if ContainerLabel:GetAttribute('KeybindFadingOut') then
					ContainerLabel:SetAttribute('KeybindFadingOut', nil)
				end

				if ContainerLabelTransparencyTween then
					ContainerLabelTransparencyTween:Cancel()
					ContainerLabelTransparencyTween = nil
				end

				if ContainerStrokeTransparencyTween then
					ContainerStrokeTransparencyTween:Cancel()
					ContainerStrokeTransparencyTween = nil
				end

		        
		        if not ContainerLabel.Visible then
		            ContainerLabel.Visible = true
		            actionLabel.TextTransparency = 1
		            ContainerStroke.Transparency = 1
		            local fadeIn = services.TweenService:Create(actionLabel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		                TextTransparency = 0
		            })
		            ContainerLabelTransparencyTween = fadeIn
		            fadeIn:Play()
					
				local strokeFadeIn = services.TweenService:Create(ContainerStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		                Transparency = 0
				})
				ContainerStrokeTransparencyTween = strokeFadeIn
				strokeFadeIn:Play()
		        else
		            
					ContainerStroke.Transparency = 0
		            actionLabel.TextTransparency = 0
		        end
		    end

			Library.RegistryMap[ContainerLabel].KEYBINDLABEL = true;
			Library.RegistryMap[actionLabel].Properties.TextColor3 = State and 'AccentColor' or 'FontColor';

			QueueKeybindFrameSize()
			if ParentObj.Type == "Toggle" and Library.ArrayListController then
				Library.ArrayListController:Refresh()
			end
		end;

		function KeyPicker:GetState()
			if KeyPicker.Mode == 'Always' then
				return true			
elseif KeyPicker.Mode == 'Hold' then
				if KeyPicker.Value == 'None' then
					return false				
end

				local Key = KeyPicker.Value;

				if Key == 'MB1' or Key == 'MB2' then
					return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
						or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)				
else
					return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])				
end;
			else
				return KeyPicker.Toggled			
end;
		end;

		function KeyPicker:SetValue(Data)
			local Key, Mode = Data[1], Data[2];
			DisplayLabel.Text = Key == "None" and "N/A" or Key;
			KeyPicker.Value = Key;
			ModeButtons[Mode]:Select();
			KeyPicker:Update();
		end;

		function KeyPicker:OnClick(Callback)
			KeyPicker.Clicked = Callback
		end

		function KeyPicker:OnChanged(Callback)
			KeyPicker.Changed = Callback
			Callback(KeyPicker.Value)
		end

		if ParentObj.Addons then
			table.insert(ParentObj.Addons, KeyPicker)
		end

		function KeyPicker:DoClick()
			if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
				if KeyPicker.Mode == 'Hold' then
					ParentObj:SetValue(KeyPicker.Toggled)
				else
					ParentObj:SetValue(not ParentObj.Value)
				end
			end

			Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
			Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
			self:Update()
		end

		local Picking = false;

		PickOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				xpcall(function()
					Picking = true;
					DisplayLabel.Text = '';
					local Break;
					local Text = '';
					task.spawn(function()
						pcall(function()
							while (not Break) do
								if Text == '...' then
									Text = '';
								end;
								Text = Text .. '.';
								DisplayLabel.Text = Text;
								task.wait(0.4);
							end;
						end)
					end);
					task.wait(0.2);
					local Event;
					Event = InputService.InputBegan:Connect(function(Input)
						local Key;
						local kc = Input.KeyCode;
						if Input.UserInputType == Enum.UserInputType.Keyboard then
							Key = Input.KeyCode.Name;
							if kc == Enum.KeyCode.Backspace or kc == Enum.KeyCode.Escape then
								Key = 'None'
								kc = Enum.KeyCode.Unknown;
							end;
						elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
							Key = 'MB1';
						elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
							Key = 'MB2';
						end;
						Break = true;
						Picking = false;

						Event:Disconnect();
						DisplayLabel.Text = Key == "None" and "N/A" or Key;
						KeyPicker.Value = Key;
						Library:SafeCallback(KeyPicker.ChangedCallback, kc or Input.UserInputType)
						Library:SafeCallback(KeyPicker.Changed, kc or Input.UserInputType)
						Library:AttemptSave();
					end);
				end, print);
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
				if curr_mode_select then
					curr_mode_select.Visible = false;
					curr_mode_select = nil;
				end

				curr_mode_select = ModeSelectOuter;
				ModeSelectOuter.Visible = true;
			end;
		end);

		local function IsBoundInput(Input, Processed)
			local Key = KeyPicker.Value;

			if Key == 'None' then
				return false
			end

			if Key == 'MB1' then
				return Input.UserInputType == Enum.UserInputType.MouseButton1
		elseif Key == 'MB2' then
				return Input.UserInputType == Enum.UserInputType.MouseButton2
		end

			return Input.UserInputType == Enum.UserInputType.Keyboard and not Processed and Input.KeyCode.Name == Key
		end

		local function IsBoundInputEnded(Input)
			local Key = KeyPicker.Value;

			if Key == 'None' then
				return false
			end

			if Key == 'MB1' then
				return Input.UserInputType == Enum.UserInputType.MouseButton1
			elseif Key == 'MB2' then
				return Input.UserInputType == Enum.UserInputType.MouseButton2
			end

			return Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key
		end

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input,t)
			if (not Picking) then
				if KeyPicker.Mode == 'Toggle' then
					if IsBoundInput(Input, t) then
						KeyPicker.Toggled = not KeyPicker.Toggled
						KeyPicker:DoClick();
						KeyPicker:Update();
					end;
				elseif KeyPicker.Mode == 'Hold' then
					if IsBoundInput(Input, t) then
						if not KeyPicker.Toggled then
							KeyPicker.Toggled = true
							KeyPicker:DoClick();
						end
						KeyPicker:Update();
					end
				end;
			end;

			if not Library.Toggled then
				return			
end;
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
					curr_mode_select = nil;
					ModeSelectOuter.Visible = false;
				end;
			end;
		end))

		Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
			if (not Picking) then
				if KeyPicker.Mode == 'Hold' and KeyPicker.Toggled and IsBoundInputEnded(Input) then
					KeyPicker.Toggled = false
					KeyPicker:DoClick();
				end
			end;
		end))

		loaded_signal:connect(function()
			KeyPicker:Update()
		end)
		KeyPicker:Update();

		aztup_options[Idx] = KeyPicker;

		return self	
end

	return Component
end
	end,
