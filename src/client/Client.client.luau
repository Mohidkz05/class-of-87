-- Everything only the local player needs: mood, flashlight, sprint, sound, cues and HUD.
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Brain = require(Shared:WaitForChild("MonsterBrain"))
local Story = require(Shared:WaitForChild("Story"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Cold moonlit school at night
Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.Ambient = Color3.fromRGB(22, 25, 32)
Lighting.OutdoorAmbient = Color3.fromRGB(14, 16, 22)
Lighting.FogColor = Color3.fromRGB(4, 5, 8)
Lighting.FogStart = 25
Lighting.FogEnd = 120

local grade = Instance.new("ColorCorrectionEffect")
grade.Contrast = 0.12
grade.Saturation = -0.15
grade.TintColor = Color3.fromRGB(226, 234, 240)
grade.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.5
bloom.Size = 18
bloom.Threshold = 1.5
bloom.Parent = Lighting

-- Sound: effects only, no music.
local function makeSound(id, volume, speed, looped)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = speed
	s.Looped = looped
	s.Parent = SoundService
	return s
end
local AIR_VOLUME = 0.18
local air = makeSound("rbxasset://sounds/action_falling.ogg", AIR_VOLUME, 0.35, true) -- draught through broken windows
air:Play()
local drip = makeSound("rbxasset://sounds/impact_water.mp3", 0.12, 1.5, false)
local rumble = makeSound("rbxasset://sounds/impact_explosion_03.mp3", 0.1, 0.35, false)
local caught = makeSound("rbxasset://sounds/impact_explosion_03.mp3", 0.8, 0.6, false)
local pickup = makeSound("rbxasset://sounds/action_get_up.mp3", 0.7, 0.8, false)
local sting = makeSound("rbxasset://sounds/action_falling.ogg", 0.6, 1.5, false)
local powerDown = makeSound("rbxasset://sounds/impact_explosion_03.mp3", 0.9, 0.4, false)

task.spawn(function()
	while true do
		task.wait(math.random(4, 11))
		drip.PlaybackSpeed = 1.2 + math.random() * 0.6
		if air.Volume > AIR_VOLUME * 0.6 then -- the building falls silent when it's close
			drip:Play()
			if math.random() < 0.15 then
				rumble:Play()
			end
		end
	end
end)

-- Flashlight follows the camera so the beam goes where you look.
local function localPart(name, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size
	p.Parent = workspace
	return p
end
local lightPart = localPart("LocalFlashlight", Vector3.new(0.2, 0.2, 0.2))
local beam = Instance.new("SpotLight")
beam.Angle = 55
beam.Range = 52
beam.Brightness = 2.5
beam.Color = Color3.fromRGB(255, 240, 215)
beam.Shadows = true
beam.Parent = lightPart

local flashlightOn = true
ContextActionService:BindAction("Flashlight", function(_, state)
	if state == Enum.UserInputState.Begin then
		flashlightOn = not flashlightOn
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("Flashlight", "Light")

-- Dust shaken loose from the roof when the presence is close.
local dustPart = localPart("LocalDust", Vector3.new(26, 0.2, 26))
local dust = Instance.new("ParticleEmitter")
dust.Rate = 0
dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
dust.Color = ColorSequence.new(Color3.fromRGB(120, 110, 95))
dust.Size = NumberSequence.new(0.5)
dust.Transparency = NumberSequence.new(0.55)
dust.Lifetime = NumberRange.new(1.5, 2.5)
dust.Speed = NumberRange.new(2, 5)
dust.EmissionDirection = Enum.NormalId.Bottom
dust.Parent = dustPart

-- The headless figure: glimpsed in a chase, and lunging when you're caught.
-- Requirement C7: it has no head at all. Nothing is ever built above the shoulders.
local FIGURE_COLOR = Color3.fromRGB(14, 12, 13)
local SHOULDER_Y = 7.1
local ARM_LENGTH = 4.2
local figure = Instance.new("Model")
figure.Name = "LocalFigure"
local figureParts = {}
local function figurePart(size, place)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Fabric
	p.Color = FIGURE_COLOR
	p.Size = size
	p.Transparency = 1
	p.Parent = figure
	table.insert(figureParts, { part = p, place = place })
	return p
end
local function fixed(offset)
	return function(base)
		return base * offset
	end
end
-- Robe narrowing up to flat shoulders. Forward is -Z.
local hem = figurePart(Vector3.new(4.2, 1.4, 2.6), fixed(CFrame.new(0, 0.7, 0)))
figurePart(Vector3.new(3.6, 2, 2.2), fixed(CFrame.new(0, 2.1, 0)))
figurePart(Vector3.new(3, 2, 1.9), fixed(CFrame.new(0, 4.1, -0.1)))
figurePart(Vector3.new(3.2, 1.8, 1.7), fixed(CFrame.new(0, 5.9, -0.2)))
figurePart(Vector3.new(4, 0.8, 1.6), fixed(CFrame.new(0, SHOULDER_Y, -0.3)))
for i, x in { -1.6, -0.7, 0.4, 1.3 } do -- torn strips trailing from the hem
	figurePart(Vector3.new(0.5, 1.1 + (i % 2) * 0.4, 0.1), fixed(CFrame.new(x, 0.2, -1.35)))
end
-- Long arms that pivot at the shoulder, with thin fingers.
local reach = math.rad(30)
local function armPivot(base, side)
	return base * CFrame.new(side * 2.25, SHOULDER_Y - 0.2, -0.4) * CFrame.Angles(reach, 0, 0)
end
for _, side in { -1, 1 } do
	figurePart(Vector3.new(0.6, ARM_LENGTH, 0.6), function(base)
		return armPivot(base, side) * CFrame.new(0, -ARM_LENGTH / 2, 0)
	end)
	for _, fx in { -0.22, 0, 0.22 } do
		figurePart(Vector3.new(0.13, 1.3, 0.13), function(base)
			return armPivot(base, side) * CFrame.new(fx, -ARM_LENGTH - 0.6, 0)
		end)
	end
end
-- Dark mist pooling at its feet.
local mist = Instance.new("ParticleEmitter")
mist.Enabled = false
mist.Rate = 14
mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
mist.Color = ColorSequence.new(Color3.fromRGB(10, 10, 12))
mist.Size = NumberSequence.new(2.5, 4)
mist.Transparency = NumberSequence.new(0.5, 1)
mist.Lifetime = NumberRange.new(1, 1.6)
mist.Speed = NumberRange.new(0.5, 1.5)
mist.Parent = hem
figure.Parent = workspace

local function placeFigure(base)
	for _, entry in figureParts do
		entry.part.CFrame = entry.place(base)
	end
end
local function showFigure(visible)
	for _, entry in figureParts do
		entry.part.Transparency = if visible then 0 else 1
	end
	mist.Enabled = visible
end
local figureShown = false
local catchStart = nil -- set while the caught lunge plays
local figureRay = RaycastParams.new()
figureRay.FilterType = Enum.RaycastFilterType.Exclude

-- Sprint is fast, loud and limited.
local wantsSprint = false
local stamina = 1
ContextActionService:BindAction("Sprint", function(_, state)
	wantsSprint = state == Enum.UserInputState.Begin
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Sprint", "Run")

-- HUD: as little text as possible.
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local BONE = Color3.fromRGB(235, 225, 205)

local dim = Instance.new("Frame")
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 1
dim.BorderSizePixel = 0
dim.ZIndex = 0
dim.Parent = gui
local blackout = dim:Clone()
blackout.ZIndex = 5
blackout.Parent = gui

local function label(position, size, textSize, font)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = position
	t.Size = size
	t.Font = font
	t.TextSize = textSize
	t.TextColor3 = BONE
	t.TextStrokeTransparency = 0.2
	t.TextWrapped = true
	t.Text = ""
	t.ZIndex = 10
	t.Parent = gui
	return t
end
local messageLabel = label(UDim2.fromScale(0.5, 0.28), UDim2.new(0.86, 0, 0, 90), 44, Enum.Font.Bangers)
local runLabel = label(UDim2.fromScale(0.5, 0.5), UDim2.new(0.8, 0, 0, 140), 110, Enum.Font.Bangers)
runLabel.TextColor3 = Color3.fromRGB(245, 70, 50)
local disclaimer = label(UDim2.new(0.5, 0, 1, -62), UDim2.new(0.8, 0, 0, 24), 16, Enum.Font.SpecialElite)

-- Fuse pips rather than words
local pips = {}
for i = 1, Config.FUSES_NEEDED do
	local pip = Instance.new("Frame")
	pip.Size = UDim2.fromOffset(18, 34)
	pip.Position = UDim2.new(0, 24 + (i - 1) * 26, 0, 54)
	pip.BackgroundColor3 = Color3.fromRGB(40, 36, 32)
	pip.BorderColor3 = BONE
	pip.BorderSizePixel = 2
	pip.ZIndex = 10
	pip.Parent = gui
	pips[i] = pip
end

local track = Instance.new("Frame")
track.AnchorPoint = Vector2.new(0.5, 1)
track.Position = UDim2.new(0.5, 0, 1, -28)
track.Size = UDim2.fromOffset(240, 10)
track.BackgroundColor3 = Color3.fromRGB(35, 32, 30)
track.BorderSizePixel = 0
track.ZIndex = 10
track.Parent = gui
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = BONE
fill.BorderSizePixel = 0
fill.ZIndex = 11
fill.Parent = track
gui.Parent = player:WaitForChild("PlayerGui")

local messageToken = 0
local function showMessage()
	messageToken += 1
	local token = messageToken
	messageLabel.Text = workspace:GetAttribute("Message") or ""
	messageLabel.TextTransparency = 0
	task.delay(2.4, function()
		if token == messageToken then
			TweenService:Create(messageLabel, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		end
	end)
end
local shownFuses = 0
local function showFuses()
	local found = workspace:GetAttribute("Fuses") or 0
	if found > shownFuses then
		pickup:Play()
	end
	shownFuses = found
	for i, pip in pips do
		pip.BackgroundColor3 = if i <= found then Color3.fromRGB(255, 150, 40) else Color3.fromRGB(40, 36, 32)
	end
end
local function showDisclaimer()
	disclaimer.Text = if workspace:GetAttribute("Disclaimer") then Story.DISCLAIMER else ""
end
local function showFinale()
	local finale = workspace:GetAttribute("Finale")
	TweenService:Create(grade, TweenInfo.new(if finale then 0.3 else 0), {
		TintColor = if finale then Color3.fromRGB(255, 150, 135) else Color3.fromRGB(226, 234, 240),
		Saturation = if finale then 0.1 else -0.15,
	}):Play()
	air.PlaybackSpeed = if finale then 0.55 else 0.35
	Lighting.Ambient = if finale then Color3.fromRGB(42, 16, 16) else Color3.fromRGB(22, 25, 32)
end
workspace:GetAttributeChangedSignal("MessageId"):Connect(showMessage)
workspace:GetAttributeChangedSignal("Fuses"):Connect(showFuses)
workspace:GetAttributeChangedSignal("Disclaimer"):Connect(showDisclaimer)
workspace:GetAttributeChangedSignal("Finale"):Connect(showFinale)
showMessage()
showFuses()
showDisclaimer()
showFinale()

local LUNGE_SECONDS = 0.35
local function onCharacter(character)
	blackout.BackgroundTransparency = 1
	catchStart = nil
	figureShown = false
	reach = math.rad(30)
	showFigure(false)
	character:WaitForChild("Humanoid").Died:Once(function()
		caught:Play()
		catchStart = os.clock()
		showFigure(true)
		task.delay(LUNGE_SECONDS + 0.1, function()
			TweenService:Create(blackout, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
		end)
	end)
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then -- the server may spawn us before this script starts
	task.spawn(onCharacter, player.Character)
end

-- "RUN!" slams on screen when a chase begins near you, at most once every 8 seconds.
local lastRunCue = -100
local previousState = nil
local function chaseCue(intensity)
	local state = workspace:GetAttribute("MonsterState")
	if state == "Chase" and previousState ~= "Chase" and os.clock() - lastRunCue > 8 and intensity > 0.2 then
		lastRunCue = os.clock()
		sting:Play()
		runLabel.Text = Story.CHASE
		runLabel.TextTransparency = 0
		runLabel.TextStrokeTransparency = 0.2
		TweenService:Create(runLabel, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
	previousState = state
end

-- Cues update about 3 times a second, which also keeps flicker below flash-risk rates.
local LAMP_BRIGHTNESS = 0.9
local CUE_INTERVAL = 0.35
local sinceCue = 0
local sinceDust = 0
local darkUntil = 0 -- during a blackout: no flashlight, no ambience, nearly black
local joltUntil, joltSize = 0, 0

local function updateCues()
	local presence = workspace:FindFirstChild("Presence")
	local here = camera.CFrame.Position
	local intensity = if presence then Brain.cueIntensity((presence.Position - here).Magnitude, Config.CUE_RANGE) else 0

	local dark = os.clock() < darkUntil
	air.Volume = if dark then 0 else AIR_VOLUME * (1 - intensity * 0.85)
	dim.BackgroundTransparency = if dark then 0.15 else 1 - intensity * 0.3
	beam.Brightness = if math.random() < intensity * 0.7 then 0.5 + math.random() else 2.5
	chaseCue(intensity)

	-- Glimpses of the figure, decided at this same slow rate so they never strobe.
	if not catchStart then
		local show = false
		if presence then
			local chance = Brain.revealChance(
				workspace:GetAttribute("MonsterState") or "Patrol",
				(presence.Position - here).Magnitude,
				Config.FIGURE_REVEAL_RANGE
			)
			if math.random() < chance then
				figureRay.FilterDescendantsInstances = { figure, player.Character, lightPart, dustPart }
				local chest = presence.Position + Vector3.new(0, 4, 0)
				show = workspace:Raycast(here, chest - here, figureRay) == nil
			end
		end
		figureShown = show
		showFigure(show)
	end

	local mine = workspace:FindFirstChild("Mine")
	if mine then
		for _, item in mine:GetDescendants() do
			if item.Name == "Lamp" and not item:GetAttribute("Dead") then
				local light = item:FindFirstChildOfClass("PointLight")
				local near = if presence then Brain.cueIntensity((presence.Position - item.Position).Magnitude, 35) else 0
				if light then
					light.Brightness = if math.random() < near then 0.08 else LAMP_BRIGHTNESS
				end
			end
		end
	end

	dustPart.CFrame = CFrame.new(here + Vector3.new(0, 5, 0))
	sinceDust += CUE_INTERVAL
	if intensity > 0.45 and sinceDust > 2.5 then
		sinceDust = 0
		dust:Emit(10)
	end
end

-- Moments the server stages: a blackout, and a short camera shake.
local reducedMotion = false
pcall(function()
	reducedMotion = GuiService.ReducedMotionEnabled
end)
ReplicatedStorage:WaitForChild("SceneCue").OnClientEvent:Connect(function(name, value)
	if name == "Blackout" then
		darkUntil = os.clock() + value
		powerDown:Play()
		updateCues()
	elseif name == "Jolt" and not reducedMotion then
		joltUntil = os.clock() + 0.3
		joltSize = value
	end
end)

RunService.RenderStepped:Connect(function(dt)
	lightPart.CFrame = camera.CFrame
	local now = os.clock()
	beam.Enabled = flashlightOn and now >= darkUntil
	sinceCue += dt
	if sinceCue >= CUE_INTERVAL then
		sinceCue = 0
		updateCues()
	end

	if catchStart then
		-- Caught: it rushes in from a few steps away, arms rising, then the screen cuts to black.
		local t = if reducedMotion then 1 else math.clamp((now - catchStart) / LUNGE_SECONDS, 0, 1)
		local eased = 1 - (1 - t) ^ 3
		local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
		local eye = camera.CFrame.Position
		local base = Vector3.new(eye.X, eye.Y - 5.5, eye.Z) + look * (7 - eased * 4.6)
		reach = math.rad(30 + eased * 55)
		placeFigure(CFrame.lookAt(base, base - look))
	elseif figureShown then
		local presence = workspace:FindFirstChild("Presence")
		if presence then
			local here = camera.CFrame.Position
			local base = presence.Position - Vector3.new(0, 1, 0)
			local toward = Vector3.new(here.X, base.Y, here.Z)
			if (toward - base).Magnitude > 0.1 then
				placeFigure(CFrame.lookAt(base, toward))
			end
		end
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local moving = humanoid and humanoid.MoveDirection.Magnitude > 0
	local sprinting = wantsSprint and moving and stamina > 0
	local capacity = if workspace:GetAttribute("Finale") then Config.FINALE_STAMINA_SECONDS else Config.STAMINA_SECONDS
	if sprinting then
		stamina = math.max(0, stamina - dt / capacity)
	else
		stamina = math.min(1, stamina + dt / Config.STAMINA_RECOVERY_SECONDS)
	end
	if stamina == 0 then
		wantsSprint = false -- must let go and recover before sprinting again
	end
	if humanoid then
		humanoid.WalkSpeed = if sprinting then Config.SPRINT_SPEED else Config.WALK_SPEED
		humanoid.CameraOffset = if now < joltUntil
			then Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * joltSize * 2
			else Vector3.zero
	end
	fill.Size = UDim2.fromScale(stamina, 1)
end)
