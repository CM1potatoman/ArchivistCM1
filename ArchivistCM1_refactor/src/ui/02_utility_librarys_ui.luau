	["@src/utility/librarys/ui"] = function()



local cloneref = cloneref or function(a) return a end;
local InputService =  cloneref(game:GetService('UserInputService'));
local TextService =   cloneref(game:GetService('TextService'));
local CoreGui =       cloneref(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
local Players =       cloneref(game:GetService('Players'));
local RunService =    cloneref(game:GetService('RunService'));
local TweenService =  cloneref(game:GetService('TweenService'));
local RenderStepped = RunService.RenderStepped;
local LocalPlayer =   cloneref(Players.LocalPlayer);
local Mouse =         cloneref(LocalPlayer:GetMouse());
local fallbackEnvironment = {};
local getgenv = getgenv or function() return fallbackEnvironment end;
local uiOpen = false;

for _, previousScreen in ipairs(CoreGui:GetChildren()) do
	if previousScreen:IsA("ScreenGui") and (previousScreen.Name == "WigginsHub"
		or previousScreen.Name == "YSLMethod" or previousScreen.Name == "YSLMethodSideImages") then
		previousScreen:Destroy()
	end
end

local ScreenGui = Instance.new('ScreenGui');
ScreenGui.Name = "YSLMethod"
ScreenGui.DisplayOrder = 1;
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ScreenGui.ResetOnSpawn = false;
ScreenGui.Parent = CoreGui;

aztup_toggles = {};
aztup_options = {};
getgenv().aztup_toggles = aztup_toggles;
getgenv().aztup_options = aztup_options;

local Library: {[string]: any} = {
	OnToggledChanged = Instance.new("BindableEvent");
	ToggleChanged = Instance.new("BindableEvent");
	WindowDraggingChanged = Instance.new("BindableEvent");
	WindowDragging = false;
	Registry = {};
	RegistryMap = {};
	WindowOuterCorner = nil;
	WindowOuterCornerDefault = UDim.new(0, 0);
	WindowTitleColorOverride = nil;

	HudRegistry = {};

	FontColor = Color3.fromHex("d7dff2");
	MainColor = Color3.fromHex("171a2a");
	BackgroundColor = Color3.fromHex("0c0e18");
	AccentColor = Color3.fromHex("7896d4");
	OutlineColor = Color3.fromHex("303b5e");
	RiskColor = Color3.fromRGB(255, 50, 50),

	Black = Color3.new(0, 0, 0);
	Font = lexend.regular,

	OpenedFrames = {};
	DependencyBoxes = {};
	DependencyGroupboxes = {};

	Signals = {};
	UnloadCallbacks = {};
	Unloaded = false;
	ScreenGui = ScreenGui;
	ThemeStyle = "Default";
	ThemeCornerDefaults = setmetatable({}, { __mode = "k" });
	WindowCornerRadius = nil;
	CornerRadiusConnection = nil;
};

function Library:ApplyThemeCorner(corner)
	if self.ThemeCornerDefaults[corner] == nil then
		self.ThemeCornerDefaults[corner] = corner.CornerRadius
	end
	local defaultRadius = self.ThemeCornerDefaults[corner]
	if self.WindowCornerRadius ~= nil and defaultRadius.Scale == 0 then
		corner.CornerRadius = UDim.new(0, self.WindowCornerRadius)
	else
		corner.CornerRadius = defaultRadius
	end
end

function Library:SetThemeStyle()
	self.ThemeStyle = "Default"
	for _, descendant in ipairs(ScreenGui:GetDescendants()) do
		if descendant:IsA("UICorner") then
			self:ApplyThemeCorner(descendant)
		end
	end
	if self.SetUIFont then
		self:SetUIFont("Gotham")
	end
	for _, toggle in pairs(aztup_toggles or {}) do
		if toggle.Type == "Toggle" and toggle.RefreshThemeAppearance then
			toggle:RefreshThemeAppearance()
		end
	end
	return true
end

local function GetPlayersString()
	local PlayerList = Players:GetPlayers();

	for i = 1, #PlayerList do
		PlayerList[i] = PlayerList[i].Name;
	end;

	table.sort(PlayerList, function(str1, str2) return str1 < str2 end);

	return PlayerList
end;

function Library:SafeCallback(f, ...)
	if (not f) then
		return	
end;
	local success, event = pcall(f, ...);

	if not success then
		

		
		
		

		if Library.ConfigLoading then
			local label = Library.ConfigLoadingOption or "config callback"
			local message = string.format("%s: %s", tostring(label), tostring(event))
			table.insert(Library.ConfigLoadErrors, message)
			warn("[YSL Method] Config load callback failed: " .. message)
			return
		end
		if aztup and aztup.silent_mode then return end
		return Library:Notify(event)	
end;
end;

function Library:AttemptSave()
	if Library.SaveManager then
		Library.SaveManager:Save();
	end;
end;

function Library:Create(Class, Properties)
	local _Instance = Class;

	if type(Class) == 'string' then
		_Instance = Instance.new(Class);
	end;

	for Property, Value in next, Properties do
		if Property ~= 'Parent' then
			_Instance[Property] = Value;
		end;
	end;

	if _Instance:IsA("UICorner") then
		Library:ApplyThemeCorner(_Instance)
	end

	if Properties.Parent ~= nil then
		_Instance.Parent = Properties.Parent;
	end;

	return _Instance
end;

function Library:SetWindowCornerRadius(radius)
	if radius ~= nil then
		radius = tonumber(radius)
		if not radius then
			return false
		end
		radius = math.clamp(math.floor(radius + 0.5), 0, 16)
	end
	if not Library.WindowOuterCorner then
		return false
	end

	Library.WindowCornerRadius = radius
	for _, descendant in ipairs(Library.ScreenGui:GetDescendants()) do
		if descendant:IsA("UICorner") then
			Library:ApplyThemeCorner(descendant)
		end
	end
	if Library.CornerRadiusConnection then
		Library.CornerRadiusConnection:Disconnect()
		Library.CornerRadiusConnection = nil
	end
	if radius ~= nil then
		Library.CornerRadiusConnection = Library.ScreenGui.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("UICorner") then
				Library:ApplyThemeCorner(descendant)
			end
		end)
		Library.WindowOuterCorner.CornerRadius = UDim.new(0, radius)
		if Library.WindowInnerCorner then
			Library.WindowInnerCorner.CornerRadius = UDim.new(0, math.max(0, radius - 1))
		end
		if Library.ESPPreviewCorner then
			Library.ESPPreviewCorner.CornerRadius = UDim.new(0, radius)
		end
		if Library.ESPPreviewHeader then
			Library.ESPPreviewHeader.Position = UDim2.fromOffset(radius, 0)
			Library.ESPPreviewHeader.Size = UDim2.new(1, -radius * 2, 0, 30)
		end
	elseif Library.ESPPreviewHeader then
		Library.ESPPreviewHeader.Position = UDim2.fromOffset(0, 0)
		Library.ESPPreviewHeader.Size = UDim2.new(1, 0, 0, 30)
	end
	return true
end

Library.UIScale = 1;

Library.ScaledObjects = {};


function Library:AddUIScale(Inst)
	local Scale = Instance.new('UIScale');
	Scale.Scale = Library.UIScale;
	Scale.Parent = Inst;

	Library.ScaledObjects[Scale] = true;

	return Scale
end;

function Library:GetUIScale()
	return Library.UIScale
end;


function Library:GetInstanceScale(Inst)
	local Scale = Inst:FindFirstChildOfClass('UIScale');
	return Scale and Scale.Scale or 1
end;

function Library:SetUIScale(Value)
	Value = math.clamp(tonumber(Value) or 1, 0.25, 4);
	Library.UIScale = Value;

	for Scale in next, Library.ScaledObjects do
		if Scale.Parent then
			Scale.Scale = Value;
		else
			Library.ScaledObjects[Scale] = nil;
		end;
	end;
end;

function Library:ApplyTextStroke(Inst)
	Inst.TextStrokeTransparency = 1;

	return Library:Create('UIStroke', {
		Color = Color3.new(0, 0, 0);
		Thickness = 1;
		LineJoinMode = Enum.LineJoinMode.Miter;
		Parent = Inst;
	})
end;

function Library:CreateLabelNoStroke(Properties, IsHud, Font)
	local _Instance = Library:Create('TextLabel', {
		BackgroundTransparency = 1;
		FontFace = Font or Library.Font;
		TextColor3 = Library.FontColor;
		AutoLocalize = false;
		TextSize = 16;
		TextStrokeTransparency = 1;
	});

	Library:AddToRegistry(_Instance, {
		TextColor3 = 'FontColor';
	}, IsHud);

	return Library:Create(_Instance, Properties)
end;

function Library:CreateLabel(Properties, IsHud, Font)
	local _Instance = Library:Create('TextLabel', {
		BackgroundTransparency = 1;
		FontFace = Font or Library.Font;
		TextColor3 = Library.FontColor;
		AutoLocalize = false;
		TextSize = 16;
		TextStrokeTransparency = 0;
	});

	local Stroke = Library:ApplyTextStroke(_Instance);

	Library:AddToRegistry(_Instance, {
		TextColor3 = 'FontColor';
	}, IsHud);

	return Library:Create(_Instance, Properties), Stroke
end;

function Library:MakeUIDraggable(inst, Cutoff, Limit)
	
	
	

	local M = inst
	M.Active = true

	local X = Instance.new("Frame")
	X.BackgroundColor3 = Library.MainColor
	X.BackgroundTransparency = 0.3
	X.BorderSizePixel = 1
	X.BorderColor3 = Color3.fromRGB(0,0,0);
	X.ZIndex = 9999
	X.Visible = false
	X.Active = false
	X.Parent = ScreenGui

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Library.AccentColor
	Stroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner;
	Stroke.Thickness = 1;
	Stroke.Parent = X;

	Library:AddToRegistry(X, {
		BackgroundColor3 = 'MainColor';
	});

	Library:AddToRegistry(Stroke, {
		Color = 'AccentColor';
	});

	
	
	
	
	
	

	M.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local clickPos = Vector2.new(
			Mouse.X - M.AbsolutePosition.X,
			Mouse.Y - M.AbsolutePosition.Y
		)

		if clickPos.Y > (Cutoff or 40) * Library:GetInstanceScale(M) then
			return
		end
		if Library.WindowDragging then
			return
		end
		Library.WindowDragging = true
		Library.WindowDraggingChanged:Fire(true)

		
		local absPos = inst.AbsolutePosition
		local absSize = inst.AbsoluteSize

		X.Size = UDim2.fromOffset(absSize.X - 2, absSize.Y - 1)
		X.Position = UDim2.fromOffset(absPos.X, absPos.Y)
		X.Visible = true

		
		inst.Visible = false

		
		while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
			RenderStepped:Wait()
			local newX = Mouse.X - clickPos.X
			local newY = Mouse.Y - clickPos.Y

			X.Position = UDim2.fromOffset(
				newX,
				newY
			)

		end

		

		local finalPosX = X.Position.X.Offset
		local finalPosY = X.Position.Y.Offset

		local anchor = inst.AnchorPoint
		local size   = inst.AbsoluteSize
		local parent = inst.Parent
		local parentPos = parent and parent.AbsolutePosition or Vector2.zero

		inst.Position = UDim2.fromOffset(
			(finalPosX - parentPos.X) + anchor.X * size.X,
			(finalPosY - parentPos.Y) + anchor.Y * size.Y
		)

		X.Visible = false
		if Library.Toggled then
			inst.Visible = true
		end
		Library.WindowDragging = false
		Library.WindowDraggingChanged:Fire(false)
	end)
end

function Library:MakeDraggable(Instance, Cutoff, Limit)
	Instance.Active = true;

	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local ObjPos = Vector2.new(
				Mouse.X - Instance.AbsolutePosition.X,
				Mouse.Y - Instance.AbsolutePosition.Y
			);

			if ObjPos.Y > (Cutoff or 40) * Library:GetInstanceScale(Instance) then
				return			
end;

			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				Instance.Position = UDim2.new(
					0,
					Mouse.X - ObjPos.X + (Instance.AbsoluteSize.X * Instance.AnchorPoint.X),
					0,
					Mouse.Y - ObjPos.Y + (Instance.AbsoluteSize.Y * Instance.AnchorPoint.Y)
				);

				if Limit then
					task.wait(1/20);
				end;
				RenderStepped:Wait();
			end;
		end;
	end)
end;

function Library:MakeDraggableScale(Instance, Cutoff, O)
	Instance.Active = true

	Instance.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local absPos = Instance.AbsolutePosition
			local absSize = Instance.AbsoluteSize
			local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

			local ObjPos = Vector2.new(
				Mouse.X - absPos.X,
				Mouse.Y - absPos.Y
			)

			if ObjPos.Y > (Cutoff or 40) * Library:GetInstanceScale(Instance) then
				return
			end

			while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				local newX = (Mouse.X - ObjPos.X + (absSize.X * Instance.AnchorPoint.X)) / viewportSize.X
				local newY = (Mouse.Y - ObjPos.Y + (absSize.Y * Instance.AnchorPoint.Y))
				if O then
					newY -= Instance.Position.Y.Offset;
				end;

				newY /= viewportSize.Y;
				Instance.Position = UDim2.new(
					newX,
					O and Instance.Position.X.Offset or 0,
					newY,
					O and Instance.Position.Y.Offset or 0
				)

				RenderStepped:Wait()
			end
		end
	end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
	local X, Y = Library:GetLexendTextBounds(InfoStr, Library.Font, 14);
	local Tooltip = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		BackgroundTransparency = 1,

		Size = UDim2.fromOffset(X + 5, Y + 4),
		ZIndex = 100,
		Parent = Library.ScreenGui,

		Visible = false,
	})

	Library:AddUIScale(Tooltip);

	local Label, Stroke = Library:CreateLabel({
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.fromOffset(X, Y);
		TextSize = 14;
		Text = InfoStr,
		TextColor3 = Library.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = Tooltip.ZIndex + 1,

		Parent = Tooltip;
	});

	Tooltip.Visible = false
	Label.TextTransparency = 1
	Label.TextStrokeTransparency = 1 
	if Stroke then
		Stroke.Transparency = 1
	end

	Library:AddToRegistry(Tooltip, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	Library:AddToRegistry(Label, {
		TextColor3 = 'FontColor',
	});

	local IsHovering = false
	local HoverToken = 0
	local PositionTween
	local FadeTweens = {}

	local function CancelTween(Tween)
		if Tween then
			Tween:Cancel()
		end
	end

	local function TweenTooltipTransparency(TargetTransparency)
		CancelTween(FadeTweens.Background)
		CancelTween(FadeTweens.Text)
		CancelTween(FadeTweens.Stroke)

		local FadeInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		FadeTweens.Background = TweenService:Create(Tooltip, FadeInfo, {
			BackgroundTransparency = TargetTransparency,
		})
		FadeTweens.Text = TweenService:Create(Label, FadeInfo, {
			TextTransparency = TargetTransparency,
			TextStrokeTransparency = TargetTransparency,
		})

		if Stroke then
			FadeTweens.Stroke = TweenService:Create(Stroke, FadeInfo, {
				Transparency = TargetTransparency,
			})
		end

		FadeTweens.Background:Play()
		FadeTweens.Text:Play()
		if FadeTweens.Stroke then
			FadeTweens.Stroke:Play()
		end
	end

	local function TweenTooltipPosition(TargetPosition)
		CancelTween(PositionTween)
		PositionTween = TweenService:Create(Tooltip, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = TargetPosition,
		})
		PositionTween:Play()
	end

	local me, ml;
	me = HoverInstance.MouseEnter:Connect(function()
		if Library:MouseIsOverOpenedFrame() then
			return
		end

		HoverToken += 1
		local CurrentToken = HoverToken
		IsHovering = true

		Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		Tooltip.Visible = true
		TweenTooltipTransparency(0)

		while IsHovering and uiOpen and HoverToken == CurrentToken do
			TweenTooltipPosition(UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12))
			task.wait(1 / 30)
		end
		IsHovering = false;
		TweenTooltipTransparency(1)
		task.delay(0.12, function()
			if HoverToken == CurrentToken and not IsHovering then
				Tooltip.Visible = false
			end
		end)
	end)

	ml = HoverInstance.MouseLeave:Connect(function()
		IsHovering = false
		HoverToken += 1
		TweenTooltipTransparency(1)
		task.delay(0.12, function()
			if not IsHovering then
				Tooltip.Visible = false
			end
		end)
	end)

	return {
		Destroy = function()
			Tooltip:Destroy();
			Label:Destroy();

			me:Disconnect();
			ml:Disconnect();
		end;
	}
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
	HighlightInstance.MouseEnter:Connect(function()
		local Reg = Library.RegistryMap[Instance];

		for Property, ColorIdx in next, Properties do
			services.TweenService:Create(Instance, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				[Property] = Library[ColorIdx] or typeof(ColorIdx) == "function" and ColorIdx() or ColorIdx;
			}):Play();

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx;
			end;
		end;
	end)

	HighlightInstance.MouseLeave:Connect(function()
		local Reg = Library.RegistryMap[Instance];

		for Property, ColorIdx in next, PropertiesDefault do
			services.TweenService:Create(Instance, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				[Property] = Library[ColorIdx] or typeof(ColorIdx) == "function" and ColorIdx() or ColorIdx;
			}):Play(); 

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx;
			end;
		end;
	end)
end;

function Library:MouseIsOverOpenedFrame()
	for Frame, _ in next, Library.OpenedFrames do
		local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

		if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
			and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

			return true		
end;
	end;
end;

function Library:CloseAllDropdowns()
	for _, Option in aztup_options do
		if Option.Type == "Dropdown" then
			Option:CloseDropdown();
		end;
	end;
end;

function Library:IsMouseOverFrame(Frame)
	local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

	if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
		and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

		return true	
end;
end;

local function flush_dependency_boxes()
	for _, Depbox in next, Library.DependencyBoxes do
		Depbox:Update();
	end;
end;



local dependency_flush_queued = false;
function Library:UpdateDependencyBoxes()
	if dependency_flush_queued then return end;
	dependency_flush_queued = true;

	task.defer(function()
		dependency_flush_queued = false;
		flush_dependency_boxes();
	end);
end;

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
	return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
	local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
	return Bounds.X, Bounds.Y
end;


function Library:GetLexendTextBounds(Text, Font, Size, Resolution)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = Text
	params.Font = Font
	params.Size = Size
	local res = TextService:GetTextBoundsAsync(params);
	params:Destroy()
	return res.X, res.Y
end;

function Library:GetDarkerColor(Color)
	local H, S, V = Color3.toHSV(Color);
	return Color3.fromHSV(H, S, V / 1.5)
end;
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

local accentGlowRecords = {}
local function refreshAccentGlow(record)
	local color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Library.AccentColorDark),
		ColorSequenceKeypoint.new(0.5, Library.AccentColor),
		ColorSequenceKeypoint.new(1, Library.FontColor),
	})
	record.gradient.Color = color
	record.strokeGradient.Color = color
	record.stroke.Color = Library.AccentColor
end

function Library:AddAccentGlow(target, enabled, animated, strokeTransparency, strokeThickness)
	local gradient = Instance.new('UIGradient')
	gradient.Enabled = enabled ~= false
	gradient.Rotation = 0
	gradient.Parent = target

	local stroke = Instance.new('UIStroke')
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = math.clamp(tonumber(strokeThickness) or 2, 1, 6)
	stroke.Transparency = math.clamp(tonumber(strokeTransparency) or 0.72, 0, 1)
	stroke.Enabled = enabled ~= false
	stroke.Parent = target

	local strokeGradient = Instance.new('UIGradient')
	strokeGradient.Rotation = 0
	strokeGradient.Parent = stroke

	local record = {
		gradient = gradient,
		stroke = stroke,
		strokeGradient = strokeGradient,
	}
	refreshAccentGlow(record)
	table.insert(accentGlowRecords, record)

	if animated ~= false then
		gradient.Offset = Vector2.new(-1, 0)
		strokeGradient.Offset = Vector2.new(-1, 0)
		local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(gradient, tweenInfo, { Offset = Vector2.new(1, 0) }):Play()
		TweenService:Create(strokeGradient, tweenInfo, { Offset = Vector2.new(1, 0) }):Play()
	end

	local cleaned = false
	local function cleanup()
		if cleaned then
			return
		end
		cleaned = true
		for index = #accentGlowRecords, 1, -1 do
			if accentGlowRecords[index] == record then
				table.remove(accentGlowRecords, index)
				break
			end
		end
		gradient:Destroy()
		stroke:Destroy()
	end
	target.Destroying:Connect(cleanup)

	return function(isEnabled)
		if not cleaned then
			gradient.Enabled = isEnabled == true
			stroke.Enabled = isEnabled
		end
	end
end

function Library:AddToRegistry(Instance, Properties, IsHud)
	local Idx = #Library.Registry + 1;
	local Data = {
		Instance = Instance;
		Properties = Properties;
		Idx = Idx;
	};

	table.insert(Library.Registry, Data);
	Library.RegistryMap[Instance] = Data;

	if IsHud then
		table.insert(Library.HudRegistry, Data);
	end;
end;

function Library:RegisterSearchEntry(Source, Data)
	local WindowRef = Source and (Source.Window or (Source.Tab and Source.Tab.Window))
	if not WindowRef or not Data or not Data.Text or Data.Text == '' then
		return
	end

	local TabOwner = Data.Tab
	if not TabOwner and Source then
		if Source.ShowTab or Source.Show then
			TabOwner = Source
		elseif Source.Tab and (Source.Tab.ShowTab or Source.Tab.Show) then
			TabOwner = Source.Tab
		end
	end

	if not TabOwner then
		return
	end

	while TabOwner and TabOwner.ParentTab do
		TabOwner = TabOwner.ParentTab
	end

	table.insert(WindowRef.SearchEntries, {
		Kind = Data.Kind or 'Feature';
		Text = Data.Text;
		Tab = TabOwner;
		Target = Data.Target;
		Focus = Data.Focus;
	})
end

function Library:RemoveFromRegistry(Instance)
	local Data = Library.RegistryMap[Instance];

	if Data then
		for Idx = #Library.Registry, 1, -1 do
			if Library.Registry[Idx] == Data then
				table.remove(Library.Registry, Idx);
			end;
		end;

		for Idx = #Library.HudRegistry, 1, -1 do
			if Library.HudRegistry[Idx] == Data then
				table.remove(Library.HudRegistry, Idx);
			end;
		end;

		Library.RegistryMap[Instance] = nil;
	end;
end;

function Library:UpdateColorsUsingRegistry()
	
	

	
	
	
	

	

	for Idx, Object in next, Library.Registry do
		for Property, ColorIdx in next, Object.Properties do
			if type(ColorIdx) == 'string' then
				Object.Instance[Property] = Library[ColorIdx];
			elseif type(ColorIdx) == 'function' then
				Object.Instance[Property] = ColorIdx()
			end
		end;
	end;
	for index = #accentGlowRecords, 1, -1 do
		local record = accentGlowRecords[index]
		if record.gradient.Parent and record.stroke.Parent then
			refreshAccentGlow(record)
		else
			table.remove(accentGlowRecords, index)
		end
	end
	for _, toggle in pairs(aztup_toggles or {}) do
		if toggle.Type == "Toggle" and toggle.RefreshThemeAppearance then
			toggle:RefreshThemeAppearance()
		end
	end
end;

function Library:GiveSignal(Signal)
	
	table.insert(Library.Signals, Signal)
end

Library.WindowGradientStrokes = {}
function Library:AddWindowGradientStroke(stroke)
	if not stroke or not stroke:IsA("UIStroke") then
		return
	end
	if Library.WindowGradientStrokes[stroke] then
		return
	end

	local gradient = stroke:FindFirstChildOfClass("UIGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Rotation = 0
		gradient.Parent = stroke
	end
	Library.WindowGradientStrokes[stroke] = gradient

	if not Library.WindowGradientSyncConnection then
		Library.WindowGradientSyncConnection = RenderStepped:Connect(function()
			local source = Library.WindowOutlineGradient
			for registeredStroke, registeredGradient in pairs(Library.WindowGradientStrokes) do
				if not registeredStroke.Parent or not registeredGradient.Parent then
					Library.WindowGradientStrokes[registeredStroke] = nil
				elseif Library.WindowOutlineGradientEnabled and source and source.Parent then
					registeredStroke.Color = Color3.new(1, 1, 1)
					registeredGradient.Color = source.Color
					registeredGradient.Offset = source.Offset
				else
					registeredStroke.Color = Library.AccentColor
					registeredGradient.Color = ColorSequence.new(Library.AccentColor)
					registeredGradient.Offset = Vector2.zero
				end
			end
		end)
		Library:GiveSignal(Library.WindowGradientSyncConnection)
	end
end

function Library:Unload(screenAlreadyDestroying)
	if Library.Unloaded then
		return
	end
	Library.Unloaded = true

	for Idx = #Library.Signals, 1, -1 do
		local Connection = table.remove(Library.Signals, Idx)
		Connection:Disconnect()
	end

	while #Library.UnloadCallbacks > 0 do
		local callback = table.remove(Library.UnloadCallbacks)
		local success, err = pcall(callback)
		if not success then
			warn("[YSL Method] Unload cleanup failed: " .. tostring(err))
		end
	end

	if not screenAlreadyDestroying then
		ScreenGui:Destroy()
	end

	table.clear(Library.Registry)
	table.clear(Library.RegistryMap)
	table.clear(Library.HudRegistry)
	table.clear(Library.ScaledObjects)
	table.clear(Library.OpenedFrames)
	table.clear(Library.DependencyBoxes)
	table.clear(Library.DependencyGroupboxes)
	Library.VisualsController = nil
	Library.ArrayListFrame = nil
	Library.HoneyPerHourCard = nil
	Library.Console = nil
	Library.InfoLoggerFrame = nil
	Library.InfoLoggerContainer = nil
	Library.InfoLoggerData = nil
	Library.KeybindFrame = nil
	Library.KeybindContainer = nil
	Library.WindowOuterCorner = nil
	Library.WindowLabel = nil
	Library.WindowAccentLabel = nil
	Library.WindowHolder = nil
	Library.OnToggledChanged:Destroy()
	Library.ToggleChanged:Destroy()
	Library.WindowDraggingChanged:Destroy()

	local environment = getgenv()
	if environment.Library == Library then
		environment.Library = nil
	end
	if environment.aztup_toggles == aztup_toggles then
		table.clear(aztup_toggles)
		environment.aztup_toggles = nil
	end
	if environment.aztup_options == aztup_options then
		table.clear(aztup_options)
		environment.aztup_options = nil
	end
end

function Library:OnUnload(Callback)
	assert(type(Callback) == "function", "OnUnload expects a function")
	table.insert(Library.UnloadCallbacks, Callback)
end

ScreenGui.Destroying:Connect(function()
	Library:Unload(true)
end)

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
	if Library.RegistryMap[Instance] then
		Library:RemoveFromRegistry(Instance);
	end;
end))

local BaseAddons = {};
	local TabboxTabMap = {};

local SliderComponent = require(("@src/utility/librarys/components/slider"))(Library, {
	InputService = InputService,
	Mouse = Mouse,
	RenderStepped = RenderStepped,
})

local ToggleComponent = require(("@src/utility/librarys/components/toggle"))(Library, {
	InputService = InputService,
	Mouse = Mouse,
	RenderStepped = RenderStepped,
	BaseAddons = BaseAddons,
})

local DropdownComponent = require(("@src/utility/librarys/components/dropdown"))(Library, {
	InputService = InputService,
	Mouse = Mouse,
	ScreenGui = ScreenGui,
})

local ColorPickerComponent = require(("@src/utility/librarys/components/colorpicker"))(Library, {
	InputService = InputService,
	Mouse = Mouse,
	RenderStepped = RenderStepped,
	ScreenGui = ScreenGui,
})

local ButtonComponent = require(("@src/utility/librarys/components/button"))(Library, {
})

local InputComponent = require(("@src/utility/librarys/components/input"))(Library, {
	TextService = TextService,
})

local LabelComponent = require(("@src/utility/librarys/components/label"))(Library, {
	BaseAddons = BaseAddons,
})

local PanelComponent = require(("@src/utility/librarys/components/panel"))(Library, {
	ScreenGui = ScreenGui,
})

require(("@src/utility/librarys/components/hud"))(Library, {
	ScreenGui = ScreenGui,
	Mouse = Mouse,
	TweenService = TweenService,
})

do
	local Funcs = {};

	function Funcs:AddColorPicker(Idx, Info) 
		return ColorPickerComponent.AddColorPicker(self, Idx, Info)
	end;

	function Funcs:AddKeyPicker(Idx, Info)
		return ToggleComponent.AddKeyPicker(self, Idx, Info)
	end;

	BaseAddons.__index = Funcs;
	BaseAddons.__namecall = function(Table, Key, ...)
		return Funcs[Key](...)	
end;
end;

local BaseGroupbox = {};
local Funcs = {};
do
	function Funcs:AddBlank(Size)
		local Groupbox = self;
		local Container = Groupbox.Container;

		return Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, Size);
			ZIndex = 1;
			Parent = Container;
		})	
end;

	function Funcs:AddLabel(Text, DoesWrap, RichText)
		return LabelComponent.AddLabel(self, Text, DoesWrap, RichText)
	end;
	function Funcs:AddButton(...)
		return ButtonComponent.AddButton(self, ...)
	end;

	function Funcs:AddDivider()
		return ButtonComponent.AddDivider(self)
	end

	function Funcs:AddInput(Idx, Info)
		return InputComponent.AddInput(self, Idx, Info)
	end;

	function Funcs:AddToggle(Idx, Info)
		return ToggleComponent.AddToggle(self, Idx, Info)
	end;

	function Funcs:AddSlider(Idx, Info)
		return SliderComponent.AddSlider(self, Idx, Info)
	end

	function Funcs:AddMinMaxSlider(Idx, Info)
		return SliderComponent.AddMinMaxSlider(self, Idx, Info)
	end

	function Funcs:AddDropdown(Idx, Info)
		return DropdownComponent.AddDropdown(self, Idx, Info)
	end;

	function Funcs:AddKeyPicker(Idx, Info)
		return ToggleComponent.AddKeyPicker(self, Idx, Info)
	end;

	function Funcs:AddDependencyBox(dont_make_indicator)
		local Depbox = { Dependencies = {}, Objects = {}, Type = "Dependency" }

		local Groupbox = self
		local Container = Groupbox.Container

		local Holder = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 0);
			Visible = false;
			Parent = Container;
		})

		local Frame = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			Visible = true;
			Parent = Holder;
		})

		Frame:AddTag("DependencyBox")

		local Layout = Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Frame;
		})

		function Depbox:Resize()
			Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y / Library:GetUIScale())
			Groupbox:Resize()
		end

		Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			Depbox:Resize()
		end)

		Holder:GetPropertyChangedSignal('Visible'):Connect(function()
			Depbox:Resize()
		end)

		function Depbox:Update()
			for _, dep in next, Depbox.Dependencies do
				local Elem, Expected = dep[1], dep[2]

				if not Elem then continue end

				local matches
				if Elem.Multi then
					matches = table.find(Elem:GetActiveValues(), Expected) ~= nil
				else
					matches = (Elem.Value == Expected)
				end

				if not matches then
					Holder.Visible = false
					Depbox:Resize()
					return
				end
			end

			Holder.Visible = true
			Depbox:Resize()
		end

		local tooltip;
		function Depbox:SetupDependencies(deps)
			local dependency_title = {};
			for _, d in next, deps do
				assert(typeof(d) == 'table', 'SetupDependencies: dependency must be a table')
				assert(d[1], 'SetupDependencies: missing element')
				assert(d[2] ~= nil, 'SetupDependencies: missing expected value')

				if d[1] and d[1].Name then
					table.insert(dependency_title, d[1].Name)
				end;
			end

			if tooltip then
				tooltip:Destroy();
			end;

			Depbox.Dependencies = deps
			Depbox:Update()
		end

		Depbox.Container = Frame
		table.insert(Groupbox.Objects, Depbox)
		setmetatable(Depbox, BaseGroupbox)

		table.insert(Library.DependencyBoxes, Depbox)

		return Depbox
	end

	function Funcs:AddDependencyGroupbox()
		local ParentGroupbox = self
		local Tab = ParentGroupbox.Tab

		local DepGroupbox = { Dependencies = {} }

		Tab.DependencyGroupboxes = Tab.DependencyGroupboxes or {}
		Library.DependencyGroupboxes = Library.DependencyGroupboxes or {}

		local parentFrame = (ParentGroupbox.Side == 1) and Tab.LeftSideFrame or Tab.RightSideFrame

		local BoxOuter = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 0, 509);
			ZIndex = 2;
			Parent = parentFrame;
		})

		Library:AddToRegistry(BoxOuter, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		})

		local BoxInner = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -2, 1, -2);
			Position = UDim2.new(0, 1, 0, 1);
			ZIndex = 4;
			Parent = BoxOuter;
		})

		Library:AddToRegistry(BoxInner, { BackgroundColor3 = 'BackgroundColor' })

		local Highlight = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 0, 2);
			ZIndex = 5;
			Parent = BoxInner;
		})

		Library:AddToRegistry(Highlight, { BackgroundColor3 = 'AccentColor' })
		Library:AddAccentGlow(Highlight)

		local Container = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 4, 0, 10);
			Size = UDim2.new(1, -4, 1, -10);
			ZIndex = 1;
			Parent = BoxInner;
		})

		Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Container;
		})

		function DepGroupbox:Resize()
			local y = 0
			for _, c in next, DepGroupbox.Container:GetChildren() do
				if not c:IsA('UIListLayout') and c.Visible then
					y += c.Size.Y.Offset
				end
			end
			local scaleValue = rawget(_G, 'DPIScale')
			local scale = (type(scaleValue) == 'number' and scaleValue) or 1
			BoxOuter.Size = UDim2.new(1, 0, 0, (10 * scale + y) + 4)
		end

		function DepGroupbox:Update()
			for _, dep in next, DepGroupbox.Dependencies do
				local Elem, Expected = dep[1], dep[2]
				if not Elem then continue end

				local matches
				if Elem.Multi then
					matches = table.find(Elem:GetActiveValues(), Expected) ~= nil
				else
					matches = (Elem.Value == Expected)
				end

				if not matches then
					BoxOuter.Visible = false
					DepGroupbox:Resize()
					return
				end
			end

			BoxOuter.Visible = true
			DepGroupbox:Resize()
		end

		function DepGroupbox:SetupDependencies(deps)
			for _, d in pairs(deps) do
				assert(typeof(d) == 'table', 'Dependency should be a table.')
				assert(d[1] ~= nil, 'Dependency is missing element.')
				assert(d[2] ~= nil, 'Dependency is missing expected value.')
			end
			DepGroupbox.Dependencies = deps
			DepGroupbox:Update()
		end

		DepGroupbox.Container = Container
		setmetatable(DepGroupbox, BaseGroupbox)

		DepGroupbox:Resize()

		table.insert(Tab.DependencyGroupboxes, DepGroupbox)
		table.insert(Library.DependencyGroupboxes, DepGroupbox)

		return DepGroupbox
	end

	local KeybindOuter, KeybindContainer = PanelComponent.CreatePanel(
		'Keybinds',
		UDim2.new(0, 220, 0, 60),
		UDim2.new(0, 10, 0, workspace.CurrentCamera.ViewportSize.Y / 2),
		Vector2.new(0, 0.5)
	);

	Library:Create('UIListLayout', {
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = KeybindContainer;
	});

	Library:Create('UIPadding', {
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		PaddingTop = UDim.new(0, 2),
		Parent = KeybindContainer,
	})











function Library:CreateInfoLogger(Title, Size, Position, Anchor)
	local Outer, Container = PanelComponent.CreatePanel(Title, Size, Position, Anchor);

	Library:Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Container,
	})

	Library:Create("UIPadding", {
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		PaddingTop = UDim.new(0, 2),
		Parent = Container,
	})

	Library:MakeDraggable(Outer, 22);

	local InfoLogger = {
		Frame = Outer,
		Container = Container,
		Data = {
			ContainerLabels = {},
		},
	};

	function InfoLogger:SetVisibility(Value)
		InfoLogger.Frame.Visible = Value;
	end

	function InfoLogger:UpdateSize()
		if not InfoLogger.Frame.Visible then
			return		
end

		local YSize, XSize, items = 0, 0, 0;

		for _, Label in next, InfoLogger.Container:GetChildren() do
			if Label:IsA('TextLabel') and Label.Visible then
				YSize += 18;
				local LabelWidth = Label.TextBounds.X / Library:GetUIScale();
				if LabelWidth > XSize then
					XSize = LabelWidth;
				end
				items += 1;
			end;
		end;

		local NewHeight = items == 0 and 24 or YSize + 32;
		local NewWidth = math.max(XSize + 34, 220);

		InfoLogger.Frame.Size = UDim2.new(0, NewWidth, 0, NewHeight);
	end

	function InfoLogger:AddText(Text, CopyText, CopyFunc, Expiry)
		local InfoContainerLabel = Library:CreateLabel({
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 18),
			TextSize = 16,
			Visible = false,
			ZIndex = 110,
			Parent = InfoLogger.Container,
		}, true)

		task.spawn(function()
			InfoContainerLabel.FontFace = lexend.regular;
		end);

		if (#InfoLogger.Data.ContainerLabels + 1) > 15 then
			local FirstElement = InfoLogger.Data.ContainerLabels[1]
			if FirstElement then
				FirstElement:Destroy()
				table.remove(InfoLogger.Data.ContainerLabels, 1)
			end
		end

		InfoContainerLabel.Text = Text;

		if CopyText then
			InfoContainerLabel.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					Library:Notify("Set your clipboard to designated copyable text.");
					setclipboard(CopyText);
				end;
			end);
		end;

		if CopyFunc then
			InfoContainerLabel.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					pcall(CopyFunc)
				end;
			end);
		end;

		InfoContainerLabel.Visible = true
		InfoContainerLabel.TextColor3 = Library.FontColor

		InfoLogger.Data.ContainerLabels[#InfoLogger.Data.ContainerLabels + 1] = InfoContainerLabel
		Library.RegistryMap[InfoContainerLabel].Properties.TextColor3 = "FontColor"
		InfoLogger:UpdateSize();

		if Expiry and type(Expiry) == "number" and Expiry > 0 then
			task.delay(Expiry, function()
				if not InfoContainerLabel or not InfoContainerLabel.Parent then
					return
				end

				local LabelIndex = table.find(InfoLogger.Data.ContainerLabels, InfoContainerLabel)
				if LabelIndex then
					table.remove(InfoLogger.Data.ContainerLabels, LabelIndex)
				end

				local FadeTime = 0.25
				local FadeTween = TweenService:Create(InfoContainerLabel, TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 1,
					TextStrokeTransparency = 1,
				})

				local TextStroke = InfoContainerLabel:FindFirstChildOfClass("UIStroke")
				if TextStroke then
					TweenService:Create(TextStroke, TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = 1,
					}):Play()
				end

				FadeTween:Play()

				task.delay(FadeTime, function()
					if InfoContainerLabel and InfoContainerLabel.Parent then
						InfoContainerLabel:Destroy()
						InfoLogger:UpdateSize()
					end
				end)
			end)
		end

		return InfoContainerLabel	
end

	return InfoLogger
end
	
	
	
	
	
	
	Library.Console = Library:CreateInfoLogger(
		'Console',
		UDim2.new(0, 220, 0, 60),
		UDim2.new(0, 10, 0.5, 0),
		Vector2.new(0, 0.5)
	);

	Library.InfoLoggerFrame = Library.Console.Frame
	Library.InfoLoggerContainer = Library.Console.Container
	Library.InfoLoggerData = Library.Console.Data

	Library.KeybindFrame = KeybindOuter;
	Library.KeybindContainer = KeybindContainer;
	if Library.SetHudTransparency then
		Library:SetHudTransparency(Library.HudTransparency)
	end
	Library:MakeDraggable(KeybindOuter, 22);
	end;

BaseGroupbox.__index = Funcs;
BaseGroupbox.__namecall = function(Table, Key, ...)
	return Funcs[Key](...)
end;

function Library:CreateWindow(...)
	local Arguments = { ... }
	local Config: {[string]: any} = { AnchorPoint = Vector2.zero }

	if type(...) == 'table' then
		Config = ...;
	else
		Config.Title = Arguments[1]
		Config.AutoShow = Arguments[2] or false;
	end

	if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
	if Config.TitleAccent == nil then
		local title, accent = Config.Title:match('^(%S+)%s+(.+)$')
		if title then
			Config.Title = title
			Config.TitleAccent = accent
		else
			Config.TitleAccent = ''
		end
	elseif type(Config.TitleAccent) ~= 'string' then
		Config.TitleAccent = ''
	end
	if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 3 end
	if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

	if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
	if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 550) end

	if Config.Center then
		Config.AnchorPoint = Vector2.new(0.5, 0.5)
		Config.Position = UDim2.fromScale(0.5, 0.5)
	end

	local Window: {[string]: any} = {
		Tabs = {};
		TabOrder = {};
		SearchEntries = {};
	};

	local Outer = Library:Create('Frame', {
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor3 = Color3.new(0, 0, 0);
		BorderSizePixel = 0;
		Position = Config.Position,
		Size = Config.Size,
		Visible = false;
		ZIndex = 1;
		Parent = ScreenGui;
	});
	Outer.ClipsDescendants = false
	Library.WindowOuterCorner = Library:Create('UICorner', {
		CornerRadius = UDim.new(0, 0);
		Parent = Outer;
	})
	Library.WindowOuterCornerDefault = Library.WindowOuterCorner.CornerRadius
	local OuterStroke = Library:Create('UIStroke', {
		Color = Library.AccentColor;
		Thickness = 2.5;
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
		Parent = Outer;
	})
	local OutlineGradient
	local OutlineGradientTween
	local OutlineGradientDuration
	local UpdateWindowTitleLayout
	local WindowTitleContent
	local WindowLabel
	local WindowAccentLabel
	local WindowSearchBox
	local BrandGradient
	local BrandGradientTween
	local BrandGradientDuration
	Library:AddToRegistry(OuterStroke, {
		Color = function()
			return Library.WindowOutlineGradientEnabled and Color3.new(1, 1, 1) or Library.AccentColor
		end;
	})
	function Library:SetWindowOutlineGradient(Enabled, StartColor, EndColor, Duration)
		Enabled = not not Enabled
		Duration = math.clamp(tonumber(Duration) or 5, 1, 12)
		Library.WindowOutlineGradientEnabled = Enabled

		if not Enabled then
			if OutlineGradientTween then
				OutlineGradientTween:Cancel()
				OutlineGradientTween = nil
			end
			if OutlineGradient then
				OutlineGradient:Destroy()
				OutlineGradient = nil
			end
			Library.WindowOutlineGradient = nil
			OutlineGradientDuration = nil
			OuterStroke.Color = Library.AccentColor
			if Library.KeybindOutlineStroke then
				Library.KeybindOutlineStroke.Color = Library.AccentColor
			end
			if BrandGradientTween then
				BrandGradientTween:Cancel()
				BrandGradientTween = nil
			end
			if BrandGradient then
				BrandGradient:Destroy()
				BrandGradient = nil
			end
			BrandGradientDuration = nil
			WindowLabel.TextColor3 = Color3.new(1, 1, 1)
			WindowAccentLabel.TextColor3 = Library.WindowTitleColorOverride or Library.AccentColor
			Library.WatermarkText.TextColor3 = Library.FontColor
			if Library.SetWatermarkGradient then
				Library:SetWatermarkGradient(false)
			end
			return
		end

		StartColor = typeof(StartColor) == 'Color3' and StartColor or Library.AccentColor
		EndColor = typeof(EndColor) == 'Color3' and EndColor or Library.AccentColorDark
		if not OutlineGradient or OutlineGradient.Parent ~= OuterStroke then
			OutlineGradient = Library:Create('UIGradient', {
				Rotation = 0;
				Parent = OuterStroke;
			})
		end
		OutlineGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, StartColor);
			ColorSequenceKeypoint.new(0.5, EndColor);
			ColorSequenceKeypoint.new(1, StartColor);
		})
		Library.WindowOutlineGradient = OutlineGradient
		OuterStroke.Color = Color3.new(1, 1, 1)
		if Library.KeybindOutlineStroke then
			Library:AddWindowGradientStroke(Library.KeybindOutlineStroke)
			Library.KeybindOutlineStroke.Color = Color3.new(1, 1, 1)
		end
		WindowLabel.TextColor3 = Color3.new(1, 1, 1)
		if Library.WindowTitleColorOverride then
			if BrandGradientTween then
				BrandGradientTween:Cancel()
				BrandGradientTween = nil
			end
			if BrandGradient then
				BrandGradient:Destroy()
				BrandGradient = nil
			end
			BrandGradientDuration = nil
			WindowAccentLabel.TextColor3 = Library.WindowTitleColorOverride
		else
			WindowAccentLabel.TextColor3 = Color3.new(1, 1, 1)
			if not BrandGradient or BrandGradient.Parent ~= WindowAccentLabel then
				BrandGradient = Library:Create('UIGradient', {
					Rotation = 0;
					Parent = WindowAccentLabel;
				})
			end
			BrandGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, StartColor);
				ColorSequenceKeypoint.new(0.5, EndColor);
				ColorSequenceKeypoint.new(1, StartColor);
			})
		end
		Library.WatermarkText.TextColor3 = Library.FontColor
		if Library.SetWatermarkGradient then
			Library:SetWatermarkGradient(true, StartColor, EndColor, Duration)
		end

		if not OutlineGradientTween or OutlineGradientDuration ~= Duration then
			if OutlineGradientTween then
				OutlineGradientTween:Cancel()
			end
			OutlineGradientDuration = Duration
			OutlineGradient.Offset = Vector2.new(-1, 0)
			OutlineGradientTween = TweenService:Create(OutlineGradient, TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
				Offset = Vector2.new(1, 0);
			})
			OutlineGradientTween:Play()
		end
		if not Library.WindowTitleColorOverride and (not BrandGradientTween or BrandGradientDuration ~= Duration) then
			if BrandGradientTween then
				BrandGradientTween:Cancel()
			end
			BrandGradientDuration = Duration
			BrandGradient.Offset = Vector2.new(-1, 0)
			BrandGradientTween = TweenService:Create(BrandGradient, TweenInfo.new(Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
				Offset = Vector2.new(1, 0);
			})
			BrandGradientTween:Play()
		end
	end
	function Library:SetWindowTitleColor(color)
		if color ~= nil and typeof(color) ~= 'Color3' then
			return false
		end
		Library.WindowTitleColorOverride = color
		Library:SetWindowOutlineGradient(
			Library.WindowOutlineGradientEnabled,
			Library.AccentColor,
			Library.AccentColorDark,
			Library.WindowOutlineGradientDuration
		)
		return true
	end
	Outer.Destroying:Connect(function()
		if OutlineGradientTween then
			OutlineGradientTween:Cancel()
		end
		if BrandGradientTween then
			BrandGradientTween:Cancel()
		end
	end)

	Library:AddUIScale(Outer);
	Library:MakeUIDraggable(Outer, 21, true);

	local Inner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.AccentColor;
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 1;
		Parent = Outer;
	});
	Library.WindowInnerCorner = Library:Create('UICorner', {
		CornerRadius = UDim.new(0, 2);
		Parent = Inner;
	})
	Library.WindowInnerCornerDefault = Library.WindowInnerCorner.CornerRadius

	Library:AddToRegistry(Inner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'AccentColor';
	});

	local WindowTitlePlate = Library:Create('Frame', {
		AnchorPoint = Vector2.new(0.5, 0);
		Position = UDim2.new(0.5, 0, 0, 0);
		Size = UDim2.fromOffset(150, 24);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ZIndex = 2;
		Parent = Inner;
	})
	WindowTitleContent = Library:Create('Frame', {
		AnchorPoint = Vector2.new(0.5, 0);
		Position = UDim2.new(0.5, 0, 0, 0);
		Size = UDim2.fromOffset(0, 24);
		BackgroundTransparency = 1;
		ClipsDescendants = true;
		ZIndex = 3;
		Parent = WindowTitlePlate;
	})

	WindowLabel = Library:CreateLabel({
		Position = UDim2.fromOffset(0, 0);
		Size = UDim2.fromOffset(80, 24);
		Text = Config.Title or '';
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		TextTruncate = Enum.TextTruncate.AtEnd;
		ZIndex = 4;
		TextSize = 18;
		FontFace = lexend.bold;
		Parent = WindowTitleContent;
	}, false);
	WindowLabel.RichText = false;
	Library.WindowLabel = WindowLabel;
	WindowAccentLabel = Library:CreateLabel({
		Position = UDim2.fromOffset(84, 0);
		Size = UDim2.fromOffset(100, 24);
		Text = Config.TitleAccent or '';
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		TextTruncate = Enum.TextTruncate.AtEnd;
		ZIndex = 4;
		TextSize = 18;
		FontFace = lexend.bold;
		Parent = WindowTitleContent;
	}, false);
	WindowAccentLabel.RichText = false;
	Library.WindowAccentLabel = WindowAccentLabel;
	local WindowTitleLogo = Library:Create('ImageLabel', {
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Image = 'rbxassetid://129868188377055';
		ScaleType = Enum.ScaleType.Fit;
		Size = UDim2.fromOffset(16, 16);
		ZIndex = 4;
		Parent = WindowTitleContent;
	})
	Library.WindowTitleFontName = "GothamBold"
	Library.UIFontName = "Gotham"
	function Library:SetUIFont(fontName)
		if type(fontName) ~= "string" then
			return false
		end
		local font = Enum.Font[fontName]
		if not font then
			return false
		end
		local success, fontFace = pcall(Font.fromEnum, font)
		if not success then
			return false
		end
		Library.UIFontName = fontName
		Library.WindowTitleFontName = fontName
		Library.Font = fontFace
		lexend.regular = fontFace
		lexend.medium = fontFace
		lexend.bold = fontFace
		for _, descendant in ipairs(ScreenGui:GetDescendants()) do
			if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
				descendant.FontFace = descendant:GetAttribute("YSLBoldKeybind") == true
					and Font.fromEnum(Enum.Font.GothamBold)
					or fontFace
			end
		end
		if WindowSearchBox then
			WindowSearchBox.Font = font
			WindowSearchBox.FontFace = fontFace
		end
		if UpdateWindowTitleLayout then
			UpdateWindowTitleLayout()
		end
		return true
	end
	Library:SetUIFont("Gotham")
	Library.RegistryMap[WindowLabel].Properties.TextColor3 = function()
		return Color3.new(1, 1, 1)
	end
	Library.RegistryMap[WindowAccentLabel].Properties.TextColor3 = function()
		return Library.WindowTitleColorOverride
			or (Library.WindowOutlineGradientEnabled and Color3.new(1, 1, 1) or Library.AccentColor)
	end
	local WindowSubtitle = Library:CreateLabel({
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 24);
		Size = UDim2.new(1, 0, 0, 13);
		Text = Config.TitleSubtitle or '';
		TextColor3 = Library.FontColor;
		TextTransparency = 0.2;
		TextSize = 10;
		FontFace = lexend.medium;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		Visible = type(Config.TitleSubtitle) == 'string' and Config.TitleSubtitle ~= '';
		ZIndex = 1;
		Parent = Inner;
	}, false);
	Library:AddToRegistry(WindowSubtitle, { TextColor3 = 'FontColor' });
	UpdateWindowTitleLayout = function()
		local scale = Library:GetUIScale()
		local availableWidth = math.max(1, math.floor(Inner.AbsoluteSize.X / scale * 0.48))
		local baseWidth = WindowLabel.Text ~= ''
			and math.ceil(Library:GetLexendTextBounds(WindowLabel.Text, WindowLabel.FontFace, WindowLabel.TextSize) / scale)
			or 0
		local accentWidth = WindowAccentLabel.Text ~= ''
			and math.ceil(Library:GetLexendTextBounds(WindowAccentLabel.Text, WindowAccentLabel.FontFace, WindowAccentLabel.TextSize) / scale)
			or 0
		local gap = accentWidth > 0 and 4 or 0
		local maximumContentWidth = math.max(1, availableWidth - 24)
		local totalTextWidth = baseWidth + accentWidth
		local logoWidth = 16
		local logoGap = totalTextWidth > 0 and 5 or 0
		if totalTextWidth + gap + logoGap + logoWidth > maximumContentWidth and totalTextWidth > 0 then
			local textWidthBudget = math.max(2, maximumContentWidth - gap - logoGap - logoWidth)
			baseWidth = math.max(1, math.floor(textWidthBudget * baseWidth / totalTextWidth))
			accentWidth = math.max(1, textWidthBudget - baseWidth)
		end

		local textWidth = baseWidth + gap + accentWidth
		local contentWidth = textWidth + (textWidth > 0 and 5 or 0) + logoWidth
		WindowLabel.Position = UDim2.fromOffset(0, 0)
		WindowLabel.Size = UDim2.fromOffset(baseWidth, 24)
		WindowAccentLabel.Position = UDim2.fromOffset(baseWidth + gap, 0)
		WindowAccentLabel.Size = UDim2.fromOffset(accentWidth, 24)
		WindowTitleLogo.Position = UDim2.fromOffset(textWidth + (textWidth > 0 and 5 or 0), 4)
		WindowTitleLogo.Size = UDim2.fromOffset(logoWidth, logoWidth)
		WindowTitleContent.Size = UDim2.fromOffset(contentWidth, 24)
		WindowTitleContent.Position = UDim2.new(0.5, 0, 0, 0)
		WindowTitlePlate.Size = UDim2.fromOffset(math.min(availableWidth, contentWidth + 24), 24)
		WindowLabel.TextYAlignment = Enum.TextYAlignment.Center
		WindowLabel.TextXAlignment = Enum.TextXAlignment.Left
		WindowAccentLabel.TextYAlignment = Enum.TextYAlignment.Center
		WindowAccentLabel.TextXAlignment = Enum.TextXAlignment.Left
	end
	Inner:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateWindowTitleLayout)
	UpdateWindowTitleLayout()

	WindowSearchBox = Library:Create('TextBox', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		BackgroundTransparency = 0.05;		
		Visible = true;

		Position = UDim2.new(0.75, -1, 0, 1);
		Size = UDim2.new(0.25, 0, 0, 21);

		FontFace = Library.Font;
		PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
		PlaceholderText = 'search...';
		TextSize = WindowLabel.TextSize;

		Text = '';
		TextColor3 = Library.FontColor;
		TextStrokeTransparency = 0;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;

		ClearTextOnFocus = false;

		ZIndex = 1;
		Parent = Inner;
	})
	local SearchResults = Library:Create('ScrollingFrame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BackgroundTransparency = 0.05;
		Visible = false;
		ClipsDescendants = true;
		Position = UDim2.new(0.5, 0, 0, 23);
		Size = UDim2.new(0.5, 0, 0, 0);
		ScrollBarThickness = 4;
		BottomImage = '';
		TopImage = '';
		ZIndex = 40;
		Parent = Inner;
	})

	Library:AddToRegistry(WindowSearchBox, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	})

	Library:AddToRegistry(SearchResults, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	})

	Library:Create('UIPadding', {
		PaddingTop = UDim.new(0, 3);
		PaddingBottom = UDim.new(0, 3);
		PaddingLeft = UDim.new(0, 3);
		PaddingRight = UDim.new(0, 3);
		Parent = SearchResults;
	})

	local SearchResultsLayout = Library:Create('UIListLayout', {
		Padding = UDim.new(0, 2);
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = SearchResults;
	})

	local function ResizeSearchResults()
		local contentHeight = SearchResultsLayout.AbsoluteContentSize.Y / Library:GetUIScale() + 6
		SearchResults.Size = UDim2.new(0.5, 0, 0, math.clamp(contentHeight, 0, 180))
		SearchResults.CanvasSize = UDim2.fromOffset(0, contentHeight)
	end

	SearchResultsLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(ResizeSearchResults)

	local function ClearSearchResults()
		for _, child in next, SearchResults:GetChildren() do
			if not child:IsA('UIListLayout') and not child:IsA('UIPadding') then
				child:Destroy()
			end
		end
	end

	local function ScrollToInstance(TargetInstance)
		local parent = TargetInstance and TargetInstance.Parent
		while parent and not parent:IsA('ScrollingFrame') do
			parent = parent.Parent
		end
		if not parent then
			return
		end

		local layout = parent:FindFirstChildOfClass('UIListLayout')
		if layout and layout.AbsoluteContentSize.Y > parent.AbsoluteWindowSize.Y then
			
			local scale = Library:GetUIScale()
			local maxScroll = (layout.AbsoluteContentSize.Y - parent.AbsoluteWindowSize.Y) / scale
			local relativeY = (TargetInstance.AbsolutePosition.Y - parent.AbsolutePosition.Y) / scale + parent.CanvasPosition.Y
			parent.CanvasPosition = Vector2.new(parent.CanvasPosition.X, math.clamp(relativeY, 0, maxScroll))
		end

		local overlay = Instance.new('Frame')
		overlay.BackgroundTransparency = 1
		overlay.Size = UDim2.fromScale(0, 0)
		overlay.Parent = TargetInstance

		local highlight = Instance.new('Frame')
		highlight.BackgroundColor3 = Library.AccentColor
		highlight.BackgroundTransparency = 0.5
		highlight.BorderSizePixel = 0
		highlight.ZIndex = 9999
		highlight.Size = UDim2.new(1, TargetInstance.AbsoluteSize.X / Library:GetUIScale(), 1, TargetInstance.AbsoluteSize.Y / Library:GetUIScale())
		highlight.Parent = overlay

		services.Debris:AddItem(overlay, 2.5)
		
		services.TweenService:Create(highlight, TweenInfo.new(2.5), { BackgroundTransparency = 1 }):Play()
	end

	function Library:FocusSearchTarget(TargetInstance)
		if not TargetInstance then
			return
		end

		local tabsToShow = {}
		local seenTabs = {}
		local function addTabAndParents(tab)
			while tab and not seenTabs[tab] do
				seenTabs[tab] = true
				table.insert(tabsToShow, tab)
				tab = tab.ParentTab
			end
		end

		local parent = TargetInstance.Parent
		while parent do
			local tab = TabboxTabMap[parent]
			if tab then
				addTabAndParents(tab)
			end
			parent = parent.Parent
		end

		for index = #tabsToShow, 1, -1 do
			local tab = tabsToShow[index]
			if tab and tab.Show then
				tab:Show()
			end
		end

		ScrollToInstance(TargetInstance)
	end

	local function FocusSearchResult(Result)
		if Result.Tab and Window.ActiveTab ~= Result.Tab then
			if Result.Tab.ShowTab then 
				Result.Tab:ShowTab()
			elseif Result.Tab.Show then
				Result.Tab:Show()
			end
		end

		if Result.Focus then
			Result.Focus()
		end

		local target = Result.Instance or Result.Target
		if target then 
			Library:FocusSearchTarget(target)
		end
		WindowSearchBox.Text = "";
	end

	function Window:RefreshSearchResults()
		ClearSearchResults()

		local query = WindowSearchBox.Text:lower()
		if query == '' then
			SearchResults.Visible = false
			SearchResults.Size = UDim2.new(0.5, -7, 0, 0)
			SearchResults.CanvasPosition = Vector2.zero
			return
		end

		local results = {}
		for _, entry in next, Window.SearchEntries do
			local text = string.lower(entry.Text or '')
			if text:find(query, 1, true) then
				table.insert(results, entry)
			end
		end

		if #results == 0 then
			SearchResults.Visible = true
			Library:ApplyTextStroke(Library:CreateLabel({
				BackgroundTransparency = 1;
				Size = UDim2.new(1, 0, 0, 18);
				Text = 'No results';
				TextSize = 14;
				FontFace = Library.Font;
				TextColor3 = Library.FontColor;
				TextXAlignment = Enum.TextXAlignment.Left;
				ZIndex = SearchResults.ZIndex + 1;
				Parent = SearchResults;
			}))
			ResizeSearchResults()
			return
		end

		for index, result in next, results do
			local CapturedResult = result
			local ResultButton = Library:Create('TextButton', {
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				AutoButtonColor = false;
				Size = UDim2.new(1, 0, 0, 18);
				Text = '';
				ZIndex = SearchResults.ZIndex + 1;
				LayoutOrder = index;
				Parent = SearchResults;
			})

			local result_label = Library:Create('TextLabel', {
				BackgroundTransparency = 1;
				Size = UDim2.new(1, 0, 1, 0);
				Text = string.format('%s', result.Text);
				TextSize = 14;
				FontFace = Library.Font;
				TextColor3 = Library.FontColor;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextTruncate = Enum.TextTruncate.AtEnd;
				ZIndex = ResultButton.ZIndex + 1;
				Parent = ResultButton;
			});
			
			Library:ApplyTextStroke(result_label) 

			Library:OnHighlight(ResultButton, result_label, {
				TextColor3 = "AccentColor"
			}, {
				TextColor3 = "FontColor"
			})

			ResultButton.MouseButton1Click:Connect(function()
				FocusSearchResult(CapturedResult)
			end)
		end

		SearchResults.Visible = true
		ResizeSearchResults()
	end

	Library:GiveSignal(WindowSearchBox:GetPropertyChangedSignal('Text'):Connect(function()
		Window:RefreshSearchResults()
	end))

	Library:Create('TextLabel', {
		BackgroundTransparency = 1;
		Visible = true;
		TextTransparency = 0.96,
		FontFace = lexend.regular,
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		Text = LRM_LinkedDiscordID or "dev_build",
	
		Position = UDim2.new(0, -50, 0, 34),
		Size = UDim2.new(1, 0, 1, 20),
		Parent = WindowSearchBox,
		ZIndex = 999999
	})

	Library:ApplyTextStroke(WindowSearchBox)

	Library:AddToRegistry(WindowSearchBox, {
		TextColor3 = 'FontColor';
	})

	local MainSectionOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 0, 24);
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, -24);
		ZIndex = 1;
		Parent = Inner;
	});

	Library:AddToRegistry(MainSectionOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	local MainSectionInner = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BackgroundTransparency = 1;
		BorderColor3 = Library.OutlineColor;
		BorderSizePixel = 0;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 1;
		Parent = MainSectionOuter;
	});

	Library:AddToRegistry(MainSectionInner, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = "OutlineColor";
	});

	local MainSectionInnerBorder = Library:Create('Frame', {
		BackgroundColor3 = Library.OutlineColor;
		Position = UDim2.new(0, 0, 0, 0);
		BorderSizePixel = 0;
		BackgroundTransparency = 0;
		Size = UDim2.new(1, 0, 0, 2);
		ZIndex = 1;
		Parent = MainSectionInner;
	});

	Library:AddToRegistry(MainSectionInnerBorder, {
		BackgroundColor3 = 'OutlineColor';
	});

	local TabArea = Library:Create('Frame', {
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ClipsDescendants = true;
		Position = UDim2.new(0, 0, 0, 2);
		Size = UDim2.new(1, 0, 0, 22);
		ZIndex = 1;
		Parent = MainSectionInner;
	});

	local TabListLayout = Library:Create('UIListLayout', {
		Padding = UDim.new(0, Config.TabPadding);
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = TabArea;
	});

	local TabContainer = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
        BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 22);
		Size = UDim2.new(1, 0, 1, 0);
		BorderSizePixel = 0;
		ZIndex = 2;
		Parent = MainSectionInner;
	});

	Library:AddToRegistry(TabContainer, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	function Window:SetWindowTitle(Title, AccentTitle)
		WindowLabel.Text = type(Title) == 'string' and Title or ''
		WindowAccentLabel.Text = type(AccentTitle) == 'string' and AccentTitle or ''
		UpdateWindowTitleLayout()
	end;

	function Window:ResizeTabs()
		local TabCount = #Window.TabOrder;
		if TabCount == 0 then return end;

		local TotalWidth = TabArea.AbsoluteSize.X / Library:GetUIScale();
		local TotalPadding = Config.TabPadding * (TabCount - 1);
		local AvailableWidth = TotalWidth - TotalPadding;
		local BaseWidth = math.floor(AvailableWidth / TabCount);
		local Remainder = AvailableWidth - (BaseWidth * TabCount);

		for index, OtherTab in ipairs(Window.TabOrder) do
			local Width = BaseWidth + (index <= Remainder and 1 or 0);
			OtherTab.Button.Size = UDim2.new(0, Width, 1, 0);
		end;
	end;

	function Window:AddTab(Name)
		local Tab = {
			Groupboxes = {};
			Tabboxes = {};
			Objects = {};
			Name = Name;
			Window = Window;
		};

		local TabButton = Library:Create('Frame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 1;
			Parent = TabArea;
		});

		Tab.Button = TabButton;

		local TabButtonLabel = Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			TextSize = 17;
			Text = Name;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 1; 
			Parent = TabButton;
		});

		local TabHighlight = Library:Create('Frame', {
			BackgroundColor3 = Library.AccentColor;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 2;
			Parent = TabButton;
		});

		Library:AddToRegistry(TabHighlight, {
			BackgroundColor3 = 'AccentColor';
		});

		local function SetTabHighlightTransparency(Transparency)
			services.TweenService:Create(TabHighlight, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				BackgroundTransparency = Transparency;
			}):Play();
		end;

		local TabButtonUnderline = Library:Create('Frame', {
			BackgroundColor3 = Library.OutlineColor;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 1, 0, 2);
			Position = UDim2.new(0, 0, 1, -2);
			ZIndex = 3;
			Parent = TabButton;
		});

		Library:AddToRegistry(TabButtonUnderline, {
			BackgroundColor3 = 'OutlineColor';
		});
		local setUnderlineGlow = Library:AddAccentGlow(TabButtonUnderline, false)

		local UnderlineTween;

		local function SetTabUnderlineColor(ColorKey, ShowGlow)
			setUnderlineGlow(ShowGlow == true)
			if UnderlineTween then
				UnderlineTween:Cancel();
				UnderlineTween = nil;
			end;

			UnderlineTween = services.TweenService:Create(TabButtonUnderline, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				BackgroundColor3 = Library[ColorKey];
			});
			UnderlineTween:Play();

			Library.RegistryMap[TabButtonUnderline].Properties.BackgroundColor3 = function()
				if UnderlineTween then
					UnderlineTween:Cancel();
					UnderlineTween = nil;
				end;
				return Library[ColorKey]			
end;
		end;

		TabButton.MouseEnter:Connect(function()
			if Window.ActiveTab == Tab then return end;
			SetTabUnderlineColor('AccentColor', false);
			SetTabHighlightTransparency(0.85);
		end);

		TabButton.MouseLeave:Connect(function()
			if Window.ActiveTab == Tab then return end;
			SetTabUnderlineColor('OutlineColor', false);
			SetTabHighlightTransparency(1);
		end);

		local Blocker = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 0, 1, 0);
			Size = UDim2.new(1, 0, 0, 1);
			ZIndex = 3;
			Parent = TabButton; 
		});

		Library:AddToRegistry(Blocker, {
			BackgroundColor3 = 'MainColor';
		});

		local TabFrame = Library:Create('Frame', {
			Name = 'TabFrame',
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			Visible = false;
			ZIndex = 2;
			Parent = TabContainer;
		});

		Tab.Frame = TabFrame;
		Tab.LeftSide = LeftSide;
		Tab.RightSide = RightSide;

		local LeftSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 6 - 1, 0, 4 - 1);
			Size = UDim2.new(0.5, -7.5, 1, -25);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			MidImage = '';
			
			ScrollBarImageTransparency = 1;
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		local RightSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0.5, 2.5, 0, 4 - 1);
			Size = UDim2.new(0.5, -7.5, 1, -25);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			MidImage = '';
			
			ScrollBarImageTransparency = 1;
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = LeftSide;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = RightSide;
		});

		for _, Side in next, { LeftSide, RightSide } do
			Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				
				Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y / Library:GetUIScale());
			end);
		end;

		function Tab:ShowTab()
			Library:CloseAllDropdowns();

			for _, OtherTab in next, Window.Tabs do
				if OtherTab ~= Tab then
					OtherTab:HideTab();
				end;
			end;

			local tween = services.TweenService:Create(TabButtonLabel, TweenInfo.new(0.18), {
				TextColor3 = Library.AccentColor;
			});

			Window.ActiveTab = Tab;

			Blocker.BackgroundTransparency = 1;

			SetTabUnderlineColor('AccentColor', true);
			SetTabHighlightTransparency(0.9);
			Library.RegistryMap[TabButtonLabel].Properties.TextColor3 = function()
				if tween then
					tween:Cancel();
					tween = nil;
				end
				return Library.AccentColor			
end;

			tween:Play()

			TabFrame.Visible = true;

			Window:RefreshSearchResults()
		end;

		function Tab:HideTab()
			Blocker.BackgroundTransparency = 1;

			SetTabUnderlineColor('OutlineColor', false);
			SetTabHighlightTransparency(1);

			services.TweenService:Create(TabButtonLabel, TweenInfo.new(0.18), {
				TextColor3 = Library.FontColor;
			}):Play()

			Library.RegistryMap[TabButtonLabel].Properties.TextColor3 = 'FontColor';
			TabFrame.Visible = false;
		end;

		function Tab:SetLayoutOrder(Position)
			TabButton.LayoutOrder = Position;
			TabListLayout:ApplyLayout();
		end;

		function Tab:AddGroupbox(Info)
			local Groupbox = {};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BackgroundTransparency = 0;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 507 + 2);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});
			Library:Create('UICorner', {
				CornerRadius = UDim.new(0, 2);
				Parent = BoxOuter;
			})

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 0;

				
				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});
			Library:Create('UICorner', {
				CornerRadius = UDim.new(0, 1);
				Parent = BoxInner;
			})

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			local Highlight = Library:Create('Frame', {
				BackgroundColor3 = Library.AccentColor;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 0, 2);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = 'AccentColor';
			});
			Library:AddAccentGlow(Highlight)

			local GroupboxLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 18);
				Position = UDim2.new(0, 4, 0, 2);
				TextSize = 14;
				Text = Info.Name;
				TextXAlignment = Enum.TextXAlignment.Left;
				ZIndex = 5;
				Parent = BoxInner;
			});

			local Container = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 4, 0, 20);
				Size = UDim2.new(1, -4, 1, -20);
				ZIndex = 1;
				Parent = BoxInner;
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = Container;
			});

			function Groupbox:Resize()
				local Size = 0;

				for _, Element in next, Groupbox.Container:GetChildren() do
					if (not Element:IsA('UIListLayout')) and Element.Visible then
						Size = Size + Element.Size.Y.Offset;
					end;
				end;

				BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
			end;

			Groupbox.Container = Container;
			Groupbox.Tab = Tab;
			Groupbox.Objects = {};
			setmetatable(Groupbox, BaseGroupbox);

			Groupbox:AddBlank(3);
			Groupbox:Resize();

			Tab.Groupboxes[Info.Name] = Groupbox;

			return Groupbox		
end;

		function Tab:AddLeftGroupbox(Name)
			return Tab:AddGroupbox({ Side = 1; Name = Name; })		
end;

		function Tab:AddRightGroupbox(Name)
			return Tab:AddGroupbox({ Side = 2; Name = Name; })		
end;

		function Tab:AddTabbox(Info)
			local Tabbox = {
				Tabs = {};
			};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BackgroundTransparency = 0.75;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 0);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 0.75;
				
				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			local Highlight = Library:Create('Frame', {
				BackgroundColor3 = Library.AccentColor;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 0, 2);
				ZIndex = 10;
				Parent = BoxInner;
			});

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = 'AccentColor';
			});

			local TabboxButtons = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 0, 0, 1);
				Size = UDim2.new(1, 0, 0, 18);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Left;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = TabboxButtons;
			});

			function Tabbox:AddTab(Name)
				local Tab = {};
				Tab.Window = Window;
				Tab.ParentTab = Tabbox.OwnerTab;

				local Button = Library:Create('Frame', {
					BackgroundColor3 = Library.MainColor;
					BorderColor3 = Color3.new(0, 0, 0);
					Size = UDim2.new(0.5, 0, 1, 0);
					ZIndex = 6;
					Parent = TabboxButtons;
				});

				Library:AddToRegistry(Button, {
					BackgroundColor3 = 'MainColor';
				});

				local ButtonLabel = Library:CreateLabel({
					Size = UDim2.new(1, 0, 1, 0);
					TextSize = 14;
					Text = Name;
					TextXAlignment = Enum.TextXAlignment.Center;
					ZIndex = 7;
					Parent = Button;
				});

				local Block = Library:Create('Frame', {
					BackgroundColor3 = Library.BackgroundColor;
					BorderSizePixel = 0;
					Position = UDim2.new(0, 0, 1, 0);
					Size = UDim2.new(1, 0, 0, 1);
					Visible = false;
					ZIndex = 9;
					Parent = Button;
				});

				Library:AddToRegistry(Block, {
					BackgroundColor3 = 'BackgroundColor';
				});

				local Container = Library:Create('Frame', {
					BackgroundTransparency = 1;
					Position = UDim2.new(0, 4, 0, 20);
					Size = UDim2.new(1, -4, 1, -20);
					ZIndex = 1;
					Visible = false;
					Parent = BoxInner;
				});

				Library:Create('UIListLayout', {
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Parent = Container;
				});

				local highlight;
				Button.MouseEnter:Connect(function()
					if Container.Visible then
						return					
end

					highlight = Instance.new('Frame')
					highlight.BackgroundColor3 = Library.AccentColor
					highlight.BackgroundTransparency = 1
					highlight.BorderSizePixel = 0
					highlight.ZIndex = 9999
					highlight.Size = UDim2.new(1, 0, 1, 0)
					highlight.Parent = Button

					services.TweenService:Create(highlight, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.75 }):Play()
				end)

				
				Button.MouseLeave:Connect(function()
					if highlight then
						services.TweenService:Create(highlight, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
						services.Debris:AddItem(highlight, 0.18)
						highlight = nil
					end
				end)
				function Tab:Show()
					Library:CloseAllDropdowns();

					for _, Tab in next, Tabbox.Tabs do
						Tab:Hide();
					end;

					if highlight then
						services.TweenService:Create(highlight, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
						services.Debris:AddItem(highlight, 0.18)
						highlight = nil
					end

					Container.Visible = true;
					Block.Visible = true;

					Button.BackgroundColor3 = Library.BackgroundColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

					Tab:Resize();
				end;

				function Tab:Hide()
					Container.Visible = false;
					Block.Visible = false;

					Button.BackgroundColor3 = Library.MainColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
				end;

				function Tab:Resize()
					local TabCount = 0;

					for _, Tab in next, Tabbox.Tabs do
						TabCount = TabCount + 1;
					end;

					for _, Button in next, TabboxButtons:GetChildren() do
						if not Button:IsA('UIListLayout') then
							Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
						end;
					end;

					if (not Container.Visible) then
						return					
end;

					local Size = 0;

					for _, Element in next, Tab.Container:GetChildren() do
						if (not Element:IsA('UIListLayout')) and Element.Visible then
							Size = Size + Element.Size.Y.Offset;
						end;
					end;

					BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
				end;

				Button.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
						Tab:Show();
						Tab:Resize();
					end;
				end);

				Tab.Container = Container;
				Tab.Tabbox = Tabbox;
				TabboxTabMap[Container] = Tab;
				Tabbox.Tabs[Name] = Tab;
				Tab.Objects = {};

				setmetatable(Tab, BaseGroupbox);

				Tab:AddBlank(3);
				Tab:Resize();

				
				if #TabboxButtons:GetChildren() == 2 then
					Tab:Show();
				end;

				return Tab			
end;

			Tab.Tabboxes[Info.Name or ''] = Tabbox;
			Tabbox.OwnerTab = Tab;

			return Tabbox		
end; 

		function Tab:AddLeftTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 1; })		
end;

		function Tab:AddRightTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 2; })		
end;

		TabButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Tab:ShowTab();
			end;
		end);

		
		if #TabContainer:GetChildren() == 1 then
			Tab:ShowTab();
		end;

		Window.Tabs[Name] = Tab;
		table.insert(Window.TabOrder, Tab);
		Window:ResizeTabs();
		return Tab	
end;

	
	
	
	
	
	
	
	

	local TransparencyCache = {};
	local Toggled = false;
	local Fading = false;

	function Library:Toggle()
		if Fading then
			return		
end;

		local FadeTime = Config.MenuFadeTime;
		Fading = true;
		Toggled = (not Toggled);
		uiOpen = Toggled;
		if Toggled then
			Outer.Visible = true
		else
			Library:CloseAllDropdowns()
		end

		if FadeTime > 0 then
			local FadeTargets = { Outer }
			for _, Desc in next, Outer:GetDescendants() do
				table.insert(FadeTargets, Desc)
			end
			for _, Desc in ipairs(FadeTargets) do
				local Properties = {};

				if Desc:IsA('ImageLabel') or Desc:IsA('ImageButton') then
					table.insert(Properties, 'ImageTransparency');
					table.insert(Properties, 'BackgroundTransparency');
				elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') or Desc:IsA('TextButton') then
					table.insert(Properties, 'TextTransparency');
					table.insert(Properties, 'BackgroundTransparency');
				elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
					table.insert(Properties, 'BackgroundTransparency');
				elseif Desc:IsA('UIStroke') then
					table.insert(Properties, 'Transparency');
				end;

				local Cache = TransparencyCache[Desc];

				if (not Cache) then
					Cache = {};
					TransparencyCache[Desc] = Cache;
				end;

				for _, Prop in next, Properties do
					if not Cache[Prop] then
						Cache[Prop] = Desc[Prop];
					end;

					local TargetTransparency = Toggled and Cache[Prop] or 1
					if Toggled then
						Desc[Prop] = 1
					end
					if Desc[Prop] ~= TargetTransparency then
						local EasingDirection = Toggled and Enum.EasingDirection.Out or Enum.EasingDirection.In
						TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, EasingDirection), {
							[Prop] = TargetTransparency;
						}):Play()
					end
				end;
			end;
		end;

		if FadeTime > 0 then
			task.wait(FadeTime);
		end;

		Outer.Visible = Toggled;
		Library.Toggled = Toggled;
		Library.OnToggledChanged:Fire(Toggled);

		Fading = false;
	end

	Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
		if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
			if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
				task.spawn(Library.Toggle)
			end
		elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
			task.spawn(Library.Toggle)
		end
	end))

	if Config.AutoShow then task.spawn(Library.Toggle) end

	Window.Holder = Outer;
	Library.WindowHolder = Outer;

	return Window
end;

local function OnPlayerChange()
	local PlayerList = GetPlayersString();

	for _, Value in aztup_options do
		if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
			Value:SetValues(PlayerList);
		end;
	end;
end;

function Library:SetInfoLoggerVisibility(Value)
	if not Library.InfoLoggerFrame then
		return false
	end
	Library.InfoLoggerFrame.Visible = not not Value
	Library:UpdateInfoLoggerSize()
	return true
end

function Library:SetKeybindVisibility(Value)
	if not Library.KeybindFrame then
		return false
	end
	Library.KeybindFrame.Visible = not not Value
	return true
end

local function getLayoutPosition(instance, positionOverride)
	if not instance then
		return nil
	end
	local position = positionOverride or instance.Position
	return {
		xScale = position.X.Scale,
		xOffset = position.X.Offset,
		yScale = position.Y.Scale,
		yOffset = position.Y.Offset,
	}
end

local function setLayoutPosition(instance, position)
	if not instance or type(position) ~= 'table' then
		return nil
	end
	local value = UDim2.new(
		type(position.xScale) == 'number' and position.xScale or 0,
		type(position.xOffset) == 'number' and position.xOffset or 0,
		type(position.yScale) == 'number' and position.yScale or 0,
		type(position.yOffset) == 'number' and position.yOffset or 0
	)
	instance.Position = value
	return value
end

function Library:GetLayoutSnapshot()
	return {
		window = getLayoutPosition(Library.WindowHolder),
		console = getLayoutPosition(Library.InfoLoggerFrame),
		keybinds = getLayoutPosition(Library.KeybindFrame),
		watermark = getLayoutPosition(Library.Watermark),
		honeyPerHour = getLayoutPosition(Library.HoneyPerHourCard),
		arrayList = getLayoutPosition(Library.ArrayListFrame),
		arrayListAnchor = Library.ArrayListFrame and {
			x = Library.ArrayListFrame.AnchorPoint.X,
			y = Library.ArrayListFrame.AnchorPoint.Y,
		} or nil,
		targetHUD = getLayoutPosition(Library.TargetHUDFrame, Library.TargetHUDManualPosition),
	}
end

function Library:SetLayoutSnapshot(layout)
	if type(layout) ~= 'table' then
		return false
	end
	setLayoutPosition(Library.WindowHolder, layout.window)
	setLayoutPosition(Library.InfoLoggerFrame, layout.console)
	setLayoutPosition(Library.KeybindFrame, layout.keybinds)
	setLayoutPosition(Library.Watermark, layout.watermark)
	setLayoutPosition(Library.HoneyPerHourCard, layout.honeyPerHour)
	local arrayListAnchor = layout.arrayListAnchor
	if Library.ArrayListFrame and type(arrayListAnchor) == "table"
		and type(arrayListAnchor.x) == "number" and type(arrayListAnchor.y) == "number" then
		Library.ArrayListFrame.AnchorPoint = Vector2.new(
			math.clamp(arrayListAnchor.x, 0, 1),
			math.clamp(arrayListAnchor.y, 0, 1)
		)
	end
	setLayoutPosition(Library.ArrayListFrame, layout.arrayList)
	if Library.ArrayListController and type(Library.ArrayListController.SyncPlacement) == "function" then
		Library.ArrayListController:SyncPlacement()
	end
	local targetHUDPosition = setLayoutPosition(Library.TargetHUDFrame, layout.targetHUD)
	if targetHUDPosition then
		Library.TargetHUDManualPosition = targetHUDPosition
	end
	return true
end


function Library:UpdateInfoLoggerSize()
	if Library.InfoLoggerFrame.Visible then
		local YSize = 0
		local XSize = 0
		local items = 0;

		for _, Label in next, Library.InfoLoggerContainer:GetChildren() do
			if Label:IsA('TextLabel') and Label.Visible then
				YSize = YSize + 18;
				local LabelWidth = Label.TextBounds.X / Library:GetUIScale()
				if (LabelWidth > XSize) then
					XSize = LabelWidth
				end

				items += 1;
			end;
		end;
		
		local NewHeight = items == 0 and 24 or YSize + 32;
		local NewWidth = math.max(XSize + 34, 220);

		Library.InfoLoggerFrame.Size = UDim2.new(0, NewWidth, 0, NewHeight)
	end;
end


function Library:AddTextToInfoLogger(Text, CopyText, CopyFunc, Expiry)
	local InfoContainerLabel = Library:CreateLabel({
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
		TextSize = 16,
		Visible = false,
		ZIndex = 110,
		Parent = Library.InfoLoggerContainer,
	}, true)

	task.spawn(function()
		InfoContainerLabel.FontFace = lexend.regular;
	end);

	if (#Library.InfoLoggerData.ContainerLabels + 1) > 15 then
		
		local FirstElement = Library.InfoLoggerData.ContainerLabels[1]
		if FirstElement then
			
			FirstElement:Destroy()

			
			table.remove(Library.InfoLoggerData.ContainerLabels, 1)
		end
	end

	InfoContainerLabel.Text = Text;

	if CopyText then
		InfoContainerLabel.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				Library:Notify("Set your clipboard to designated copyable text.");
				setclipboard(CopyText);
			end;
		end);   
	end;

	if CopyFunc then
		InfoContainerLabel.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				pcall(CopyFunc)
			end;
		end);   
	end;

	InfoContainerLabel.Visible = true
	InfoContainerLabel.TextColor3 = Library.FontColor

	Library.InfoLoggerData.ContainerLabels[#Library.InfoLoggerData.ContainerLabels + 1] = InfoContainerLabel
	Library.RegistryMap[InfoContainerLabel].Properties.TextColor3 = "FontColor"
	Library:UpdateInfoLoggerSize();

	if Expiry and type(Expiry) == "number" and Expiry > 0 then
		task.delay(Expiry, function()
			if not InfoContainerLabel or not InfoContainerLabel.Parent then
				return
			end

			local LabelIndex = table.find(Library.InfoLoggerData.ContainerLabels, InfoContainerLabel)
			if LabelIndex then
				table.remove(Library.InfoLoggerData.ContainerLabels, LabelIndex)
			end

			local FadeTime = 0.25
			local FadeTween = TweenService:Create(InfoContainerLabel, TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			})

			local TextStroke = InfoContainerLabel:FindFirstChildOfClass("UIStroke")
			if TextStroke then
				TweenService:Create(TextStroke, TweenInfo.new(FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 1,
				}):Play()
			end

			FadeTween:Play()

			task.delay(FadeTime, function()
				if InfoContainerLabel and InfoContainerLabel.Parent then
					InfoContainerLabel:Destroy()
					Library:UpdateInfoLoggerSize()
				end
			end)
		end)
	end
end 


Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange));
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange));
getgenv().Library = Library;
return Library
	end,
