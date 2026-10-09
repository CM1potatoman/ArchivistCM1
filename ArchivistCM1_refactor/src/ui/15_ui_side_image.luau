	["@src/ui/side_image"] = function()
local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DEFAULT_ASSETS = {
	["Anime Girl 1"] = "115786328930349",
}
local DEFAULT_IMAGE_NAME = "Anime Girl 1"
local DEFAULT_IMAGE_SIZE = 400

return function(library)
	local sideImageScreenGui = Instance.new("ScreenGui")
	sideImageScreenGui.Name = "YSLMethodSideImages"
	sideImageScreenGui.DisplayOrder = library.ScreenGui.DisplayOrder - 1
	sideImageScreenGui.IgnoreGuiInset = library.ScreenGui.IgnoreGuiInset
	sideImageScreenGui.ResetOnSpawn = false
	sideImageScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	sideImageScreenGui.Parent = library.ScreenGui.Parent
	library:OnUnload(function()
		sideImageScreenGui:Destroy()
	end)

	local container = library:Create("Frame", {
		Name = "YSL_SideImages",
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0),
		ZIndex = 1,
		Parent = sideImageScreenGui,
	})

	local images = {}
	local enabled = true
	local windowDragging = false

	local function getPointerPositions()
		local pointerPosition = UserInputService:GetMouseLocation()
		if library.ScreenGui.IgnoreGuiInset then
			return { pointerPosition }, { Vector2.zero }
		end
		local topLeftInset = GuiService:GetGuiInset()
		return { pointerPosition - topLeftInset, pointerPosition }, { topLeftInset, Vector2.zero }
	end

	local function containsPoint(image, point)
		local position = image.AbsolutePosition
		local size = image.AbsoluteSize
		return image.Visible and point.X >= position.X and point.X <= position.X + size.X
			and point.Y >= position.Y and point.Y <= position.Y + size.Y
	end

	local function updateWindowAnchoredImages()
		local window = library.WindowHolder
		if not window or not window.Parent then
			return
		end
		local scale = library:GetUIScale()
		local windowOrigin = (window.AbsolutePosition - container.AbsolutePosition) / scale
		local imageSize = window.AbsoluteSize.X / scale
		for _, image in pairs(images) do
			if image then
				image.Size = UDim2.fromOffset(imageSize, imageSize)
				image.Position = UDim2.fromOffset(windowOrigin.X, windowOrigin.Y - imageSize * 0.70)
			end
		end
	end

	local function getDefaultPosition(index)
		local window = library.WindowHolder
		if not window or not window.Parent then
			return UDim2.fromOffset(16 + (index - 1) * 36, 80)
		end

		local scale = library:GetUIScale()
		local windowOrigin = (window.AbsolutePosition - container.AbsolutePosition) / scale
		local imageSize = window.AbsoluteSize.X / scale
		return UDim2.fromOffset(windowOrigin.X, windowOrigin.Y - imageSize * 0.70)
	end

	local function preload(image)
		task.spawn(function()
			local success, err = pcall(function()
				ContentProvider:PreloadAsync({ image }, function(assetId, status)
					if status ~= Enum.AssetFetchStatus.Success then
						warn(string.format(
							"[YSL Method] Side image asset %s failed to load (%s).",
							tostring(assetId),
							tostring(status)
						))
					end
				end)
			end)
			if not success then
				warn("[YSL Method] Could not load side image asset: " .. tostring(err))
			end
		end)
	end

	local function ensureImage(name, index)
		local image = images[name]
		if image then
			return image
		end
		image = library:Create("ImageLabel", {
			Name = "YSL_SideImage_" .. name:gsub("%W", ""),
			Active = false,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "rbxthumb://type=Asset&id=" .. DEFAULT_ASSETS[name] .. "&w=420&h=420",
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(DEFAULT_IMAGE_SIZE, DEFAULT_IMAGE_SIZE),
			Position = getDefaultPosition(index),
			Visible = false,
			ZIndex = 1,
			Parent = container,
		})
		image.Rotation = 0
		library:AddUIScale(image)
		images[name] = image
		preload(image)
		return image
	end

	local function refresh()
		if not enabled or library.Toggled ~= true or windowDragging then
			for name, image in pairs(images) do
				image.Visible = false
			end
			return
		end
		for _, image in pairs(images) do
			image.Visible = true
		end
	end

	local controller = {}
	function controller:IsPointerOverImage()
		local pointerPositions = getPointerPositions()
		for _, image in pairs(images) do
			for _, pointerPosition in ipairs(pointerPositions) do
				if containsPoint(image, pointerPosition) then
					return true
				end
			end
		end
		return false
	end

	function controller:SetEnabled(value)
		enabled = value == true
		refresh()
	end

	function controller:SetSelection(value)
		ensureImage(DEFAULT_IMAGE_NAME, 1)
		refresh()
		return true
	end

	function controller:GetConfigState()
		return {
			assets = table.clone(DEFAULT_ASSETS),
		}
	end

	function controller:SetConfigState(state)
		if type(state) ~= "table" then
			return false
		end
		controller:SetSelection({ [DEFAULT_IMAGE_NAME] = true })
		updateWindowAnchoredImages()
		return true
	end

	library:GiveSignal(library.OnToggledChanged.Event:Connect(refresh))
	library:GiveSignal(library.WindowDraggingChanged.Event:Connect(function(isDragging)
		windowDragging = isDragging == true
		refresh()
	end))
	library:GiveSignal(library.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh))
	library:GiveSignal(RunService.RenderStepped:Connect(function()
		updateWindowAnchoredImages()
	end))
	controller:SetSelection({ [DEFAULT_IMAGE_NAME] = true })
	return controller
end
	end,
