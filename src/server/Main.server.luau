-- Runs each attempt: story intro, school, presence, scares, fuses, finale, ending.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local LevelGen = require(ReplicatedStorage.Shared.LevelGen)
local Brain = require(ReplicatedStorage.Shared.MonsterBrain)
local Story = require(ReplicatedStorage.Shared.Story)
local World = require(script.Parent.World)
local Monster = require(script.Parent.Monster)
local Doors = require(script.Parent.Doors)
local Director = require(script.Parent.Director)

local run = nil -- everything belonging to the current attempt
local startRun

local function setMessage(text)
	workspace:SetAttribute("Message", text)
	workspace:SetAttribute("MessageId", (workspace:GetAttribute("MessageId") or 0) + 1)
end

-- Avatars appear with no visible head, face or accessories. See docs/REQUIREMENTS.md, C7.
local function hideHead(character)
	local function clean(item)
		if item:IsA("Accessory") then
			item:Destroy()
		end
	end
	for _, child in character:GetChildren() do
		clean(child)
	end
	character.ChildAdded:Connect(function(child)
		task.defer(clean, child)
	end)
	local head = character:WaitForChild("Head")
	head.Transparency = 1
	local function cleanHead(item)
		if item:IsA("Decal") then
			item:Destroy()
		end
	end
	for _, item in head:GetDescendants() do
		cleanHead(item)
	end
	head.DescendantAdded:Connect(function(item)
		task.defer(cleanHead, item)
	end)
end

local function spawnPlayer(player)
	if not run or run.ended then
		return
	end
	player:LoadCharacter()
	local character = player.Character
	if character and run then
		hideHead(character)
		local offset = Vector3.new(math.random(-4, 4), 4, math.random(-4, 4))
		character:PivotTo(CFrame.new(World.center(run.rooms[1]) + offset))
		local root = character:WaitForChild("HumanoidRootPart")
		local glow = Instance.new("PointLight") -- lets co-op partners see each other
		glow.Range = 8
		glow.Brightness = 0.35
		glow.Parent = root
		character:WaitForChild("Humanoid").Died:Once(function()
			task.defer(run and run.checkAllDead or function() end)
		end)
	end
end

local function anyoneAlive()
	for _, player in Players:GetPlayers() do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			return true
		end
	end
	return false
end

local function endRun(text, hook)
	if not run or run.ended then
		return
	end
	local ending = run
	ending.ended = true
	setMessage(text)
	if hook then
		task.delay(2.2, function()
			setMessage(hook)
		end)
	end
	if ending.monster then
		ending.monster:destroy()
		ending.monster = nil
	end
	ending.director:destroy()
	task.delay(Config.RESTART_SECONDS, function()
		ending.folder:Destroy()
		for _, player in Players:GetPlayers() do
			if player.Character then
				player.Character:Destroy()
			end
		end
		run = nil
		startRun()
	end)
end

local function startFinale(thisRun, position)
	workspace:SetAttribute("Finale", true)
	setMessage(Story.FUSE[3])
	task.delay(2, function()
		if run == thisRun and not thisRun.ended then
			setMessage(Story.GATE)
		end
	end)
	thisRun.director.stage = 3
	task.delay(Config.FINALE_HEAD_START, function()
		if run == thisRun and not thisRun.ended and thisRun.monster then
			-- Starts two rooms behind the player, so the way out is still ahead
			local index = World.roomIndexAt(thisRun.rooms, position) or 2
			local from = thisRun.rooms[math.max(1, index - 2)]
			thisRun.monster:startFinale(World.center(from))
		end
	end)
end

local function releaseMonster(thisRun)
	if run == thisRun and not thisRun.ended and not thisRun.monster then
		thisRun.monster = Monster.new(thisRun.rooms, function(_, humanoid)
			humanoid.Health = 0
		end, thisRun.doors)
		thisRun.monster:setStage(thisRun.found)
		setMessage(Story.AWAKE)
	end
end

startRun = function()
	local rooms = LevelGen.generate(os.time(), Config.MIDDLE_ROOMS, Config.FUSES_NEEDED)
	local folder, fuses, panel, assets = World.build(rooms)
	local thisRun = { rooms = rooms, folder = folder, ended = false, found = 0 }
	run = thisRun

	thisRun.checkAllDead = function()
		if run == thisRun and not thisRun.ended and not anyoneAlive() then
			endRun(Story.CAUGHT)
		end
	end

	thisRun.doors = Doors.new(rooms, folder, function(position)
		if thisRun.monster then
			thisRun.monster:hear(position, Config.FUSE_NOISE_RADIUS)
		end
	end)
	thisRun.director = Director.new(rooms, assets, thisRun.doors, folder, function()
		return thisRun.monster
	end)

	workspace:SetAttribute("Fuses", 0)
	workspace:SetAttribute("FusesNeeded", Config.FUSES_NEEDED)
	workspace:SetAttribute("Finale", false)

	-- Story in three quick beats while the player is already free to move.
	task.spawn(function()
		workspace:SetAttribute("Disclaimer", true)
		for _, line in Story.INTRO do
			if run ~= thisRun then
				return
			end
			setMessage(line)
			task.wait(1.6)
		end
		workspace:SetAttribute("Disclaimer", false)
		if run == thisRun then
			setMessage(Story.GOAL)
		end
	end)

	local gatePrompt = panel:FindFirstChildOfClass("ProximityPrompt")
	gatePrompt.Triggered:Connect(function()
		endRun(Story.ESCAPED, Story.ESCAPED_HOOK)
	end)

	for _, fuse in fuses do
		fuse:FindFirstChildOfClass("ProximityPrompt").Triggered:Connect(function()
			if thisRun.ended then
				return
			end
			if thisRun.monster then
				thisRun.monster:hear(fuse.Position, Config.FUSE_NOISE_RADIUS)
			end
			local position = fuse.Position
			fuse:Destroy()
			thisRun.found += 1
			workspace:SetAttribute("Fuses", thisRun.found)
			thisRun.director.stage = thisRun.found
			if thisRun.found == 1 then
				thisRun.director:queueBlackout(position)
			end
			if thisRun.monster then
				thisRun.monster:setStage(thisRun.found)
			end
			if thisRun.found >= Config.FUSES_NEEDED then
				gatePrompt.Enabled = true
				releaseMonster(thisRun)
				startFinale(thisRun, position)
			else
				setMessage(Story.FUSE[thisRun.found])
			end
		end)
	end

	for _, player in Players:GetPlayers() do
		task.spawn(spawnPlayer, player)
	end

	task.delay(Config.MONSTER_GRACE_SECONDS, function()
		releaseMonster(thisRun)
	end)
end

Players.PlayerAdded:Connect(spawnPlayer)
Players.PlayerRemoving:Connect(function()
	task.defer(function()
		if run and #Players:GetPlayers() > 0 then
			run.checkAllDead()
		end
	end)
end)

-- Moving players make noise. In the finale it can hear anyone who's moving, anywhere.
-- Reading velocity on the server means clients can't fake silence.
local sinceNoise = 0
RunService.Heartbeat:Connect(function(dt)
	sinceNoise += dt
	if sinceNoise < 0.25 or not run or not run.monster then
		return
	end
	sinceNoise = 0
	local monster = run.monster
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local velocity = root.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			local radius = Brain.noiseRadius(speed, Config.WALK_NOISE_RADIUS, Config.SPRINT_NOISE_RADIUS)
			if monster.finale then
				monster:hear(root.Position, math.huge) -- standing still won't save you now
			elseif radius > 0 then
				monster:hear(root.Position, radius)
			end
		end
	end
end)

startRun()
