	["@src/utility/librarys/components/panel"] = function()


return function(Library, context)
	local ScreenGui = context.ScreenGui or Library.ScreenGui

	local Component = {}

	function Component.CreatePanel(Title, Size, Position, Anchor)
		local Outer: Frame = Library:Create('Frame', {
			AnchorPoint = Anchor or Vector2.zero;
			Position = Position;
			Size = Size;
			BackgroundColor3 = Library.AccentColor;
			BorderSizePixel = 1;
			Visible = false;
			ZIndex = Title == 'Console' and 100 or 101;
			Parent = ScreenGui;
		});
		Library:Create('UICorner', {
			CornerRadius = UDim.new(0, Title == 'Keybinds' and 10 or 2);
			Parent = Outer;
		})

		Library:AddUIScale(Outer);

		if Title == 'Keybinds' then
			Outer.BorderSizePixel = 0
			local stroke = Library:Create('UIStroke', {
				Color = Library.AccentColor,
				Thickness = 3,
				Transparency = 0.18,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Parent = Outer,
			})
			Library.KeybindOutlineStroke = stroke
			Library:AddWindowGradientStroke(stroke)
			Library:AddToRegistry(stroke, {
				Color = function()
					return Library.WindowOutlineGradientEnabled and Color3.new(1, 1, 1) or Library.AccentColor
				end,
			}, true)
		end

		Outer.MouseEnter:Connect(function()
			Library.RequestingMouse = true;
		end)

		Outer.MouseLeave:Connect(function()
			Library.RequestingMouse = false;
		end)

		Library:AddToRegistry(Outer, {
			BackgroundColor3 = 'AccentColor';
		}, true)

		local Inner = Library:Create('Frame', {
			Size = UDim2.new(1, -2, 1, -2);
			Position = UDim2.new(0, 1, 0, 1);
			BackgroundColor3 = Library.MainColor;
			BackgroundTransparency = Title == 'Keybinds' and 0.18 or 0;
			BorderSizePixel = 0;
			ClipsDescendants = true;
			ZIndex = 101;
			Parent = Outer;
		});
		Library:Create('UICorner', {
			CornerRadius = UDim.new(0, Title == 'Keybinds' and 9 or 1);
			Parent = Inner;
		})

		Library:AddToRegistry(Inner, {
			BackgroundColor3 = 'MainColor';
		}, true)
		if Title == 'Keybinds' then
			Library.KeybindInner = Inner
		end

		local Header = Library:Create('Frame', {
			Size = UDim2.new(1, 0, 0, Title == 'Keybinds' and 28 or 22);
			BackgroundColor3 = Library.BackgroundColor;
			BackgroundTransparency = Title == 'Keybinds' and 0.1 or 0;
			BorderSizePixel = 0;
			ZIndex = 102;
			Parent = Inner;
		});
		Library:Create('UICorner', {
			CornerRadius = UDim.new(0, Title == 'Keybinds' and 9 or 1);
			Parent = Header;
		})

		Library:AddToRegistry(Header, {
			BackgroundColor3 = 'BackgroundColor';
		}, true)
		if Title == 'Keybinds' then
			Library.KeybindHeader = Header
			local accent = Library:Create('Frame', {
				Position = UDim2.fromOffset(9, 9),
				Size = UDim2.new(0, 2, 1, -18),
				BackgroundColor3 = Library.AccentColor,
				BorderSizePixel = 0,
				ZIndex = 103,
				Parent = Header,
			})
			Library:AddToRegistry(accent, { BackgroundColor3 = 'AccentColor' }, true)
		end

		local HeaderLabel = Library:CreateLabel({
			Position = UDim2.new(0, Title == 'Keybinds' and 17 or 5, 0, 0);
			Size = UDim2.new(1, Title == 'Keybinds' and -24 or -16, 1, 0);
			Text = Title == 'Keybinds' and 'Hotkeys' or Title;
			TextSize = Title == 'Keybinds' and 14 or 16;
			TextXAlignment = Title == 'Keybinds' and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center;
			TextStrokeTransparency = 1;
			ZIndex = 103;
			Parent = Header;
		})

		HeaderLabel.FontFace = Title == 'Keybinds' and lexend.bold or lexend.regular

		Library:AddToRegistry(HeaderLabel, {
			TextColor3 = 'FontColor';
		}, true)

		local Divider = Library:Create('Frame', {
			Size = UDim2.new(1, 0, 0, 1);
			Position = UDim2.new(0, 0, 0, Title == 'Keybinds' and 28 or 22);
			BackgroundColor3 = Library.OutlineColor;
			BorderSizePixel = 0;
			ZIndex = 102;
			Parent = Inner;
		});

		Library:AddToRegistry(Divider, {
			BackgroundColor3 = 'OutlineColor';
		}, true)

		local Content = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 1, Title == 'Keybinds' and -29 or -23);
			Position = UDim2.new(0, 0, 0, Title == 'Keybinds' and 29 or 23);
			ZIndex = 101;
			Parent = Inner;
		});

		return Outer, Content	
end

	return Component
end
	end,
