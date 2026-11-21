-- Doors between rooms. Slam one to hold the presence back for a few seconds.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(ReplicatedStorage.Shared.Config)
local Rooms = require(ReplicatedStorage.Shared.Rooms)
local World = require(script.Parent.World)

local Doors = {}
Doors.__index = Doors

local SLAM_SOUND = "rbxasset://sounds/impact_explosion_03.mp3"

function Doors.new(rooms, parent, onSlam)
	local self = setmetatable({ list = {}, onSlam = onSlam }, Doors)
	for i = 1, #rooms - 1 do
		local a, b = rooms[i], rooms[i + 1]
		local at = World.doorBetween(a, b)
		local alongX = a.y ~= b.y -- rooms stacked in Z means the door spans X
		local w = Rooms.DOOR_W
		local size = if alongX then Vector3.new(w, Rooms.DOOR_H, 0.4) else Vector3.new(0.4, Rooms.DOOR_H, w)
		local closed = CFrame.new(at + Vector3.new(0, Rooms.DOOR_H / 2, 0))
		-- Open: swung 90 degrees around the left jamb, into the next room and flat against the side.
		local hinge = if alongX then Vector3.new(-w / 2, 0, 0) else Vector3.new(0, 0, -w / 2)
		local open = closed * CFrame.new(hinge) * CFrame.Angles(0, math.rad(95), 0) * CFrame.new(-hinge)

		local leaf = Instance.new("Part")
		leaf.Name = "Door"
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.CanQuery = false
		leaf.Size = size
		leaf.CFrame = open
		leaf.Color = Color3.fromRGB(70, 48, 30)
		leaf.Material = Enum.Material.WoodPlanks
		leaf.Parent = parent

		local slam = Instance.new("Sound")
		slam.SoundId = SLAM_SOUND
		slam.Volume = 0.7
		slam.PlaybackSpeed = 1.7
		slam.RollOffMaxDistance = 80
		slam.Parent = leaf

		local door = { index = i, position = at, leaf = leaf, open = open, closed = closed, shut = false, readyAt = 0, slam = slam }
		table.insert(self.list, door)

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Slam"
		prompt.ObjectText = "Door"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = leaf
		door.prompt = prompt
		prompt.Triggered:Connect(function()
			if self:slamDoor(door, Config.DOOR_HOLD_SECONDS) and self.onSlam then
				self.onSlam(at)
			end
		end)
	end
	return self
end

function Doors:slamDoor(door, seconds, cooldown)
	cooldown = cooldown or Config.DOOR_COOLDOWN_SECONDS
	local now = os.clock()
	if door.shut or now < door.readyAt then
		return false
	end
	door.shut = true
	door.readyAt = now + seconds + cooldown
	door.prompt.Enabled = false
	door.leaf.CanCollide = true
	door.slam:Play()
	TweenService:Create(door.leaf, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = door.closed }):Play()
	task.delay(seconds, function()
		if not door.leaf.Parent then
			return
		end
		door.shut = false
		door.leaf.CanCollide = false
		TweenService:Create(door.leaf, TweenInfo.new(0.35, Enum.EasingStyle.Back), { CFrame = door.open }):Play()
		task.delay(cooldown, function()
			if door.prompt.Parent then
				door.prompt.Enabled = true
			end
		end)
	end)
	return true
end

-- True when a shut door stands at this point, so the presence has to wait.
function Doors:isBlocked(point)
	for _, door in self.list do
		if door.shut and (door.position - point).Magnitude < 1 then
			return true
		end
	end
	return false
end

function Doors:nearest(position, range)
	local best, bestDistance = nil, range
	for _, door in self.list do
		local d = (door.position - position).Magnitude
		if d < bestDistance then
			best, bestDistance = door, d
		end
	end
	return best
end

return Doors
