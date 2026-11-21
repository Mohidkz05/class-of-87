-- Keeps something happening near players. Each event is a short physical cue with a sound.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local Pacing = require(ReplicatedStorage.Shared.Pacing)
local SetPieces = require(ReplicatedStorage.Shared.SetPieces)
local Story = require(ReplicatedStorage.Shared.Story)
local World = require(script.Parent.World)

local Director = {}
Director.__index = Director

-- Tells clients about moments only they can show: darkness and camera shake.
local sceneCue = Instance.new("RemoteEvent")
sceneCue.Name = "SceneCue"
sceneCue.Parent = ReplicatedStorage

local function soundAt(position, id, volume, speed)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Position = position
	holder.Parent = workspace
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = speed
	s.RollOffMaxDistance = 90
	s.RollOffMinDistance = 10
	s.Parent = holder
	s:Play()
	Debris:AddItem(holder, 6)
end

local CLANG = "rbxasset://sounds/action_jump_land.mp3"
local CRASH = "rbxasset://sounds/impact_explosion_03.mp3"
local GLASS = "rbxasset://sounds/impact_water.mp3"
local SCRAPE = "rbxasset://sounds/action_swim.mp3"
local RUSH = "rbxasset://sounds/action_falling.ogg"

-- Writes a line on a board or mirror, letter by letter.
local function write(surface, line)
	local gui = surface:FindFirstChildOfClass("SurfaceGui")
	local label = gui and gui:FindFirstChild("Text")
	if not label then
		return
	end
	label.Text = line
	label.MaxVisibleGraphemes = 0
	TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Linear), { MaxVisibleGraphemes = #line }):Play()
	soundAt(surface.Position, SCRAPE, 1, 1.7)
end

-- Bursts a hinged door open.
local function swing(door)
	local hingeOnX = door:GetAttribute("Hinge") == "X"
	local half = (if hingeOnX then door.Size.X else door.Size.Z) / 2
	local offset = if hingeOnX then Vector3.new(-half, 0, 0) else Vector3.new(0, 0, -half)
	local target = door.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(80), 0) * CFrame.new(-offset)
	TweenService:Create(door, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = target }):Play()
end

function Director.new(rooms, assets, doors, parent, getMonster)
	local self = setmetatable({}, Director)
	self.rooms, self.assets, self.doors, self.parent = rooms, assets, doors, parent
	self.stage, self.active, self.last = 0, true, nil
	self.getMonster = getMonster
	self.busy, self.nextPiece, self.played = false, 0, {}
	self.static = Instance.new("Sound")
	self.static.SoundId = RUSH
	self.static.PlaybackSpeed = 2.4
	self.static.Volume = 0.22
	self.static.Parent = SoundService
	task.spawn(function()
		task.wait(Config.FIRST_SCARE_SECONDS)
		while self.active do
			if not self.busy then
				self:fire()
			end
			task.wait(Pacing.gap(self.stage, math.random()))
		end
	end)
	task.spawn(function()
		task.wait(Config.FIRST_SCARE_SECONDS)
		while self.active do
			self:checkSetPieces()
			task.wait(0.25)
		end
	end)
	return self
end

function Director:destroy()
	self.active = false
	self.static:Destroy()
end

function Director:randomVictim()
	local alive = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			table.insert(alive, root)
		end
	end
	return if #alive > 0 then alive[math.random(1, #alive)] else nil
end

-- Removes and returns the nearest unused item of a kind in rooms around the index.
function Director:take(kind, index, position)
	local best, bestRoom, bestSlot, bestDistance = nil, nil, nil, math.huge
	for r = index - 1, index + 1 do
		local a = self.assets[r]
		for slot, item in (a and a[kind] or {}) do
			local at = if item:IsA("Model") then item:GetPivot().Position else item.Position
			local d = (at - position).Magnitude
			if d < bestDistance and d > 6 then -- keep events in view, not on top of the player
				best, bestRoom, bestSlot, bestDistance = item, a, slot, d
			end
		end
	end
	if best then
		table.remove(bestRoom[kind], bestSlot)
	end
	return best
end

function Director:has(kind, index)
	for r = index - 1, index + 1 do
		local a = self.assets[r]
		if a and a[kind] and #a[kind] > 0 then
			return true
		end
	end
	return false
end

function Director:fire()
	local root = self:randomVictim()
	if not root then
		return
	end
	local here = root.Position
	local index = World.roomIndexAt(self.rooms, here)
	if not index then
		return
	end
	local available = { "Static", "Prints" }
	for _, pair in { { "Locker", "LockerDoor" }, { "Lamp", "Lamp" }, { "Board", "Board" }, { "Tile", "Tile" }, { "Desk", "Desk" } } do
		if self:has(pair[2], index) then
			table.insert(available, pair[1])
		end
	end
	if self.doors:nearest(here, 45) then
		table.insert(available, "Door")
	end
	local name = Pacing.pick(available, self.last, math.random())
	self.last = name
	local handler = self["do" .. name]
	if handler then
		handler(self, here, index, root)
	end
end

function Director:doLocker(here, index)
	local door = self:take("LockerDoor", index, here)
	if not door then
		return
	end
	swing(door)
	soundAt(door.Position, CLANG, 1.4, 1.5)
end

function Director:doLamp(here, index)
	local lamp = self:take("Lamp", index, here)
	if not lamp then
		return
	end
	lamp.Material = Enum.Material.SmoothPlastic
	lamp.Color = Color3.fromRGB(30, 30, 28)
	lamp:SetAttribute("Dead", true)
	local light = lamp:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = false
	end
	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate = 0
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 225, 150))
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(0.15)
	sparks.Lifetime = NumberRange.new(0.4, 0.9)
	sparks.Speed = NumberRange.new(6, 14)
	sparks.SpreadAngle = Vector2.new(60, 60)
	sparks.EmissionDirection = Enum.NormalId.Bottom
	sparks.Acceleration = Vector3.new(0, -40, 0)
	sparks.Parent = lamp
	sparks:Emit(24)
	soundAt(lamp.Position, GLASS, 1.3, 2.6)
end

function Director:doBoard(here, index)
	local board = self:take("Board", index, here)
	if not board then
		return
	end
	write(board, Story.CHALK[math.random(1, #Story.CHALK)])
end

function Director:doTile(here, index)
	local tile = self:take("Tile", index, here)
	if not tile then
		return
	end
	local landing = CFrame.new(tile.Position.X, 0.25, tile.Position.Z) * CFrame.Angles(0, math.rad(math.random(0, 90)), math.rad(math.random(-6, 6)))
	TweenService:Create(tile, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = landing }):Play()
	task.delay(0.42, function()
		soundAt(landing.Position, CRASH, 0.6, 2)
	end)
end

function Director:doDesk(here, index)
	local desk = self:take("Desk", index, here)
	if not desk then
		return
	end
	local start = desk:GetPivot()
	local away = start.Position - here
	local shift = Vector3.new(if away.X >= 0 then 2 else -2, 0, 0)
	local t = Instance.new("NumberValue")
	t.Changed:Connect(function(v)
		desk:PivotTo(start + shift * v)
	end)
	TweenService:Create(t, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 1 }):Play()
	Debris:AddItem(t, 2)
	soundAt(start.Position, SCRAPE, 1.2, 0.55)
end

function Director:doDoor(here)
	local door = self.doors:nearest(here, 45)
	if door and (door.position - here).Magnitude > 8 then
		self.doors:slamDoor(door, 1.5)
	end
end

function Director:doStatic()
	self.static:Play()
	task.delay(1.1, function()
		if self.static.Parent then
			self.static:Stop()
		end
	end)
end

function Director:footprint(at, toward, lifetime)
	local mark = Instance.new("Part")
	mark.Name = "Footprint"
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanQuery = false
	mark.CanTouch = false
	mark.CastShadow = false
	mark.Size = Vector3.new(1.3, 0.06, 2.6)
	mark.Color = Color3.fromRGB(16, 12, 10)
	mark.Material = Enum.Material.SmoothPlastic
	mark.CFrame = CFrame.lookAt(at, toward)
	mark.Parent = self.parent
	Debris:AddItem(mark, lifetime)
end

-- Footprints race toward the player, then stop just short.
function Director:doPrints(here, index, root)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		return
	end
	flat = flat.Unit
	local cell = World.center(self.rooms[index])
	local count = 7
	task.spawn(function()
		for i = count, 1, -1 do
			if not self.active then
				return
			end
			local side = flat:Cross(Vector3.yAxis) * (if i % 2 == 0 then 0.9 else -0.9)
			local at = here + flat * (4 + i * 3) + side
			-- Stay inside this room so prints never appear in the walls
			at = Vector3.new(
				math.clamp(at.X, cell.X - 17, cell.X + 17),
				0.09,
				math.clamp(at.Z, cell.Z - 17, cell.Z + 17)
			)
			self:footprint(at, at - flat, Config.FOOTPRINT_LIFETIME)
			soundAt(at, CLANG, 0.8, 0.45)
			task.wait(0.22)
		end
	end)
end

-- STAGED SCARES ---------------------------------------------------------------------------
-- Each plays once. Random scares wait while one is running.

function Director:queueBlackout(position)
	self.blackoutAt = os.clock() + Config.BLACKOUT_DELAY
	self.blackoutNear = position
end

function Director:isBeingChased()
	local monster = self.getMonster()
	return monster ~= nil and monster.state == "Chase"
end

function Director:checkSetPieces()
	if self.busy or self.stage >= 3 or self:isBeingChased() then
		return
	end
	local now = os.clock()
	if self.blackoutAt and now >= self.blackoutAt then
		local root = self:nearestVictim(self.blackoutNear)
		self.blackoutAt = nil
		if root then
			self:play(self.doBlackout, root)
		end
		return
	end
	if now < self.nextPiece then
		return
	end
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local index = root and humanoid and humanoid.Health > 0 and World.roomIndexAt(self.rooms, root.Position)
		if index and not self.played[index] then
			local room = self.rooms[index]
			local piece = SetPieces.BY_ROOM[room.kind]
			local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
			if piece and (flat - World.center(room)).Magnitude < Config.SET_PIECE_RADIUS then
				self.played[index] = true
				self:play(self["do" .. piece], root, index)
				return
			end
		end
	end
end

function Director:play(scene, root, index)
	self.busy = true
	task.spawn(function()
		local ok, problem = pcall(scene, self, root, index)
		if not ok then
			warn("Staged scare failed: " .. tostring(problem))
		end
		self.busy = false
		self.nextPiece = os.clock() + Config.SET_PIECE_MIN_GAP
	end)
end

function Director:nearestVictim(position)
	local best, bestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 and (root.Position - position).Magnitude < bestDistance then
			best, bestDistance = root, (root.Position - position).Magnitude
		end
	end
	return best
end

-- Pauses the presence, and moves it away if it's close, so the scene ends fairly.
function Director:clearPresence(here, index, seconds)
	local monster = self.getMonster()
	if not monster then
		return
	end
	monster:hold(seconds)
	if (monster.position - here).Magnitude < Config.SET_PIECE_CLEAR then
		local far = if index > 2 then index - 2 else math.min(index + 2, #self.rooms)
		monster:relocate(World.center(self.rooms[far]))
	end
end

function Director:cueNear(position, range, name, value)
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - position).Magnitude <= range then
			sceneCue:FireClient(player, name, value)
		end
	end
end

-- Takes everything of a kind from one room, farthest from the player first.
function Director:takeAll(kind, index, here)
	local list = self.assets[index][kind]
	self.assets[index][kind] = {}
	table.sort(list, function(a, b)
		return (a.Position - here).Magnitude > (b.Position - here).Magnitude
	end)
	return list
end

-- First fuse: the power dies, and footsteps circle the player in the dark, closing in.
-- A slam right behind them, the lights return, and the prints show how close it came.
function Director:doBlackout(root)
	local here = root.Position
	local index = World.roomIndexAt(self.rooms, here)
	if not index then
		return
	end
	local steps = SetPieces.circle(math.random)
	local PAUSE, AFTER = 0.8, 0.3
	local duration = PAUSE + AFTER
	for _, step in steps do
		duration += step.wait
	end
	self:clearPresence(here, index, duration + 1)

	local killed = {}
	for r = index - 1, index + 1 do
		for _, part in (self.assets[r] and self.assets[r].Glow or {}) do
			local light = part:FindFirstChildOfClass("PointLight")
			if light and not part:GetAttribute("Dead") then
				table.insert(killed, { part = part, light = light, material = part.Material, color = part.Color })
				light.Enabled = false
				part.Material = Enum.Material.SmoothPlastic
				part.Color = Color3.fromRGB(30, 30, 28)
			end
		end
	end
	for _, player in Players:GetPlayers() do
		local other = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local at = other and World.roomIndexAt(self.rooms, other.Position)
		if at and math.abs(at - index) <= 1 then
			sceneCue:FireClient(player, "Blackout", duration)
		end
	end

	task.wait(PAUSE)
	local cell = World.center(self.rooms[index])
	for _, step in steps do
		if not self.active then
			break
		end
		if root.Parent then
			here = root.Position
		end
		local rad = math.rad(step.angle)
		local at = here + Vector3.new(math.cos(rad), 0, math.sin(rad)) * step.radius
		at = Vector3.new(math.clamp(at.X, cell.X - 17, cell.X + 17), 0.09, math.clamp(at.Z, cell.Z - 17, cell.Z + 17))
		self:footprint(at, Vector3.new(here.X, 0.09, here.Z), duration + 6)
		soundAt(at, CLANG, 1.6, 0.38 + math.random() * 0.14)
		task.wait(step.wait)
	end

	local behind = if root.Parent then root.Position - root.CFrame.LookVector * 3 else here
	soundAt(behind, CRASH, 1.6, 1.7)
	self:cueNear(behind, 40, "Jolt", 0.5)
	task.wait(AFTER)
	for _, item in killed do
		if not item.part:GetAttribute("Dead") then
			item.light.Enabled = true
			item.part.Material = item.material
			item.part.Color = item.color
		end
	end
end

-- Locker hall: every door bursts open in a wave that races toward the player.
function Director:doLockers(root, index)
	local here = root.Position
	local doors = self:takeAll("LockerDoor", index, here)
	local gaps = SetPieces.wave(#doors, 0.05, 0.17, math.random)
	for i, door in doors do
		swing(door)
		if i % 2 == 0 or i == #doors then
			soundAt(door.Position, CLANG, 1.3, 1.3 + math.random() * 0.5)
		end
		task.wait(gaps[i])
	end
	self:cueNear(here, 40, "Jolt", 0.3)
	task.wait(0.5)
	self:doLamp(here, index)
end

-- Classroom or detention: the doors slam, every desk snaps round to face the player,
-- and the board tells them to sit down.
function Director:doDesks(root, index)
	local here = root.Position
	self:clearPresence(here, index, Config.TRAP_SECONDS + 1)
	for _, door in self.doors.list do
		if door.index == index or door.index == index - 1 then
			self.doors:slamDoor(door, Config.TRAP_SECONDS, 0)
		end
	end
	self:cueNear(here, 40, "Jolt", 0.3)
	task.wait(0.7)
	here = if root.Parent then root.Position else here

	local desks = self.assets[index].Desk
	self.assets[index].Desk = {}
	for _, desk in desks do
		local start = desk:GetPivot()
		-- Skip a desk right beside a player, so it can't shove them
		if (start.Position - here).Magnitude > 6 then
			local facing = CFrame.lookAt(start.Position, Vector3.new(here.X, start.Position.Y, here.Z))
			local t = Instance.new("NumberValue")
			t.Changed:Connect(function(v)
				desk:PivotTo(start:Lerp(facing, v))
			end)
			TweenService:Create(t, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = 1 }):Play()
			Debris:AddItem(t, 2)
			soundAt(start.Position, SCRAPE, 1.1, 0.5 + math.random() * 0.25)
		end
	end
	task.wait(0.8)
	local board = self:take("Board", index, here)
	if board then
		write(board, Story.DESKS)
	end
end

-- Washroom: the taps run, the stalls bang open toward the player, the mirror writes,
-- and something hits the wall right behind them.
function Director:doStalls(root, index)
	local here = root.Position
	local mirror = self.assets[index].Mirror[1]
	self.assets[index].Mirror = {}
	if mirror then
		for _, pause in SetPieces.wave(3, 0.25, 0.6, math.random) do
			soundAt(mirror.Position, GLASS, 0.9, 0.8 + math.random() * 0.3)
			task.wait(pause)
		end
	end
	local stalls = self:takeAll("Stall", index, here)
	local gaps = SetPieces.wave(#stalls, 0.22, 0.5, math.random)
	for i, stall in stalls do
		swing(stall)
		soundAt(stall.Position, CLANG, 1.4, 1 + math.random() * 0.4)
		task.wait(gaps[i])
	end
	task.wait(0.6)
	if mirror then
		write(mirror, Story.MIRROR)
		task.wait(2)
	end
	if root.Parent then
		local behind = root.Position - root.CFrame.LookVector * 3
		soundAt(behind, CRASH, 1.6, 1.9)
		self:cueNear(behind, 40, "Jolt", 0.5)
	end
end

return Director
