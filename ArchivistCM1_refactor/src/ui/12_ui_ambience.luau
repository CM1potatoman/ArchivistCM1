	["@src/ui/ambience"] = function()
local RunService = game:GetService("RunService")
local Random = Random.new()

return function(library)
	local particles = {}
	local layer = library:Create("Frame", {
		Name = "InterfaceAmbience",
		Active = false,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 0,
		Parent = library.ScreenGui,
	})

	local mode = "Off"
	local intensity = 36

	for index = 1, 48 do
		local particle = library:Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = library.FontColor,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 0,
			Parent = layer,
		})
		library:AddToRegistry(particle, {
			BackgroundColor3 = function()
				return mode == "Rain" and library.AccentColor or library.FontColor
			end,
		})
		local corner = library:Create("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = particle,
		})

		particles[index] = {
			Instance = particle,
			Corner = corner,
			X = 0,
			Y = 0,
			Speed = 0,
			Drift = 0,
			Phase = Random:NextNumber(0, math.pi * 2),
			Size = 0,
		}
	end

	local function configureParticle(state, width, height, initial)
		local isRain = mode == "Rain"
		state.Size = isRain and 2 or Random:NextNumber(4, 8)
		state.X = Random:NextNumber(0, math.max(1, width))
		state.Y = initial and Random:NextNumber(0, math.max(1, height)) or -state.Size
		state.Speed = isRain and Random:NextNumber(420, 620) or Random:NextNumber(24, 58)
		state.Drift = isRain and -state.Speed * math.tan(math.rad(12))
			or Random:NextNumber(-12, 12)

		local particle = state.Instance
		particle.Size = isRain and UDim2.fromOffset(2, Random:NextNumber(18, 30)) or UDim2.fromOffset(state.Size, state.Size)
		particle.Rotation = isRain and 12 or 0
		particle.BackgroundTransparency = isRain and 0.18 or 0.08
		particle.Visible = true
	end

	local function refreshVisibility()
		local visible = mode ~= "Off" and library.Toggled == true
		layer.Visible = visible
		local width, height = layer.AbsoluteSize.X, layer.AbsoluteSize.Y
		local precipitation = mode == "Rain" or mode == "Snow"
		for index, state in ipairs(particles) do
			local particleVisible = visible and precipitation and index <= intensity
			state.Instance.Visible = particleVisible
			if particleVisible and (state.Instance.Size.X.Offset == 0 or state.Y == 0) then
				configureParticle(state, width, height, true)
			end
		end
	end

	local controller = {}
	function controller:SetMode(value)
		if value ~= "Off" and value ~= "Rain" and value ~= "Snow" then
			return false
		end
		mode = value
		for _, state in ipairs(particles) do
			state.Y = 0
			state.Instance.Visible = false
		end
		refreshVisibility()
		library:UpdateColorsUsingRegistry()
		return true
	end

	function controller:SetIntensity(value)
		intensity = math.clamp(math.floor(tonumber(value) or intensity), 8, #particles)
		refreshVisibility()
	end

	library:GiveSignal(library.OnToggledChanged.Event:Connect(refreshVisibility))
	library:GiveSignal(layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshVisibility))
	library:GiveSignal(RunService.RenderStepped:Connect(function(deltaTime)
		if not layer.Visible then
			return
		end

		local width, height = layer.AbsoluteSize.X, layer.AbsoluteSize.Y
		for index = 1, intensity do
			local state = particles[index]
			state.Y += state.Speed * deltaTime
			state.X += state.Drift * deltaTime
			if mode == "Snow" then
				state.X += math.sin(os.clock() + state.Phase) * 9 * deltaTime
			end
			if state.Y > height + state.Size or state.X < -8 or state.X > width + 8 then
				configureParticle(state, width, height, false)
			else
				state.Instance.Position = UDim2.fromOffset(state.X, state.Y)
			end
		end
	end))
	library:GiveSignal(library.ScreenGui.DescendantRemoving:Connect(function(instance)
		if instance == layer then
			layer.Visible = false
		end
	end))

	return controller
end
	end,
