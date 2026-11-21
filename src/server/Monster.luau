-- The presence. Mostly unseen and hunting by sound; clients glimpse a headless figure in a chase.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Brain = require(ReplicatedStorage.Shared.MonsterBrain)
local LevelGen = require(ReplicatedStorage.Shared.LevelGen)
local World = require(script.Parent.World)

local Monster = {}
Monster.__index = Monster

local EYE_HEIGHT = 7
local Debris = game:GetService("Debris")
local SPEEDS = {
	Patrol = Config.PATROL_SPEED,
	Investigate = Config.INVESTIGATE_SPEED,
	Chase = Config.CHASE_SPEED,
}

-- Nothing visible: one invisible point that carries the footstep sound.
-- Players only ever learn where it is through the cues it causes.
local function buildPresence(position)
	local presence = Instance.new("Part")
	presence.Name = "Presence"
	presence.Anchored = true
	presence.CanCollide = false
	presence.CanQuery = false
	presence.CanTouch = false
	presence.Transparency = 1
	presence.CastShadow = false
	presence.Size = Vector3.new(1, 1, 1)
	presence.Position = position + Vector3.new(0, 1, 0)

	local steps = Instance.new("Sound")
	steps.Name = "Steps"
	steps.SoundId = "rbxasset://sounds/action_jump_land.mp3"
	steps.Volume = 1.6
	steps.RollOffMaxDistance = 90
	steps.RollOffMinDistance = 12
	steps.Parent = presence
	presence.Parent = workspace
	return presence, steps
end

function Monster.new(rooms, onCatch, doors)
	local self = setmetatable({}, Monster)
	self.rooms = rooms
	self.onCatch = onCatch
	self.doors = doors
	self.stage = 0
	self.finale = false
	self.state = "Patrol"
	self.position = World.center(rooms[#rooms])
	self.target = self.position
	self.waypoints = {}
	self.lastSeen = -math.huge
	self.noiseAt = nil
	self.nextStep = 0
	self.heldUntil = 0
	self.model, self.steps = buildPresence(self.position)
	self.prints = Instance.new("Folder")
	self.prints.Name = "Footprints"
	self.prints.Parent = workspace
	self.lastPrint = self.position
	self.printSide = 1
	self.sightParams = RaycastParams.new()
	self.sightParams.FilterDescendantsInstances = { self.model }
	self.sightParams.FilterType = Enum.RaycastFilterType.Exclude
	self.connection = RunService.Heartbeat:Connect(function(dt)
		self:update(dt)
	end)
	return self
end

function Monster:destroy()
	self.connection:Disconnect()
	self.model:Destroy()
	self.prints:Destroy()
end

-- Marks appear on the floor as it walks: the main way to see where it has been.
function Monster:leaveFootprint(facing)
	if (self.position - self.lastPrint).Magnitude < Config.FOOTPRINT_SPACING then
		return
	end
	self.lastPrint = self.position
	self.printSide = -self.printSide
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
	local side = facing:Cross(Vector3.yAxis) * self.printSide * 0.9
	mark.CFrame = CFrame.lookAt(self.position, self.position + facing) + side + Vector3.new(0, 0.04, 0)
	mark.Parent = self.prints
	Debris:AddItem(mark, Config.FOOTPRINT_LIFETIME)
end

function Monster:setStage(stage)
	self.stage = stage
end

-- Finale: it moves faster and always knows where the noise is. Starts away from the player.
function Monster:startFinale(position)
	self.finale = true
	self.position = position
	self.waypoints = {}
	self.lastPrint = position
	self.model.Position = position + Vector3.new(0, 1, 0)
end

-- Staged scares pause it, so nobody gets caught in a moment they can't react to.
function Monster:hold(seconds)
	self.heldUntil = os.clock() + seconds
end

function Monster:relocate(position)
	self.position = position
	self.target = position
	self.waypoints = {}
	self.lastPrint = position
	self.model.Position = position + Vector3.new(0, 1, 0)
end

function Monster:currentSpeed()
	if self.finale then
		return Config.FINALE_SPEED
	end
	return SPEEDS[self.state] * (1 + self.stage * Config.STAGE_SPEED_BONUS)
end

function Monster:hear(position, radius)
	if (position - self.position).Magnitude <= radius then
		self.noiseAt = position
	end
end

function Monster:routeTo(target)
	self.target = target
	local from = World.roomIndexAt(self.rooms, self.position)
	local to = World.roomIndexAt(self.rooms, target)
	self.waypoints = {}
	if from and to then
		local path = LevelGen.route(from, to)
		for i = 1, #path - 1 do
			table.insert(self.waypoints, World.doorBetween(self.rooms[path[i]], self.rooms[path[i + 1]]))
		end
	end
	table.insert(self.waypoints, Vector3.new(target.X, 0, target.Z))
end

function Monster:findVisiblePlayer()
	local eye = self.position + Vector3.new(0, EYE_HEIGHT, 0)
	local best, bestDistance = nil, Config.SIGHT_RANGE
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - eye).Magnitude
			if distance < bestDistance then
				local hit = workspace:Raycast(eye, root.Position - eye, self.sightParams)
				if hit and hit.Instance:IsDescendantOf(character) then
					best, bestDistance = character, distance
				end
			end
		end
	end
	return best
end

function Monster:catchNearby()
	local here = Vector3.new(self.position.X, 0, self.position.Z)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
			if (flat - here).Magnitude <= Config.CATCH_DISTANCE then
				self.onCatch(player, humanoid)
			end
		end
	end
end

function Monster:update(dt)
	local now = os.clock()
	if now < self.heldUntil then
		self.noiseAt = nil
		return
	end
	local seen = self:findVisiblePlayer()
	if seen then
		self.lastSeen = now
		self.seenAt = seen:GetPivot().Position
	end

	local arrived = #self.waypoints == 0
	local previous = self.state
	self.state = Brain.nextState({
		state = previous,
		seesPlayer = seen ~= nil,
		heardNoise = self.noiseAt ~= nil,
		secondsSinceSeen = now - self.lastSeen,
		arrived = arrived,
		loseTargetSeconds = Config.LOSE_TARGET_SECONDS,
	})

	if self.state == "Chase" and self.seenAt then
		self:routeTo(self.seenAt)
	elseif self.state == "Investigate" then
		if self.noiseAt then
			self:routeTo(self.noiseAt)
		elseif previous == "Chase" and self.seenAt then
			self:routeTo(self.seenAt)
		end
	elseif #self.waypoints == 0 then
		self:routeTo(World.center(self.rooms[math.random(1, #self.rooms)]))
	end
	self.noiseAt = nil
	workspace:SetAttribute("MonsterState", self.state)

	local speed = self:currentSpeed()
	local remaining = speed * dt
	local facing = nil
	while remaining > 0 and #self.waypoints > 0 do
		local offset = self.waypoints[1] - self.position
		local distance = offset.Magnitude
		if distance < 6.5 and self.doors and self.doors:isBlocked(self.waypoints[1]) then
			break -- a slammed door holds it back
		end
		if distance < 0.01 then
			table.remove(self.waypoints, 1)
		else
			facing = offset.Unit
			local move = math.min(remaining, distance)
			self.position += facing * move
			remaining -= move
			if move >= distance then
				table.remove(self.waypoints, 1)
			end
		end
	end
	if facing then
		self.model.Position = self.position + Vector3.new(0, 1, 0)
		self:leaveFootprint(facing)
		if now >= self.nextStep then
			self.steps.PlaybackSpeed = 0.38 + math.random() * 0.14
			self.steps:Play()
			self.nextStep = now + Brain.stepDelay(speed, math.random())
		end
	end
	self:catchNearby()
end

return Monster
