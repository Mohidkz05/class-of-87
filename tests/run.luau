-- Run with: luau tests/run.luau
local LevelGen = require("../src/shared/LevelGen")
local Brain = require("../src/shared/MonsterBrain")

local checked = 0
for seed = 1, 3000 do
	local rooms = LevelGen.generate(seed * 7919, 8, 3)
	assert(#rooms == 10, "room count")
	assert(rooms[1].kind == "Foyer" and rooms[10].kind == "Exit", "start and end")
	local seen, fuses, kinds = {}, 0, {}
	for i, r in rooms do
		local key = r.x .. "," .. r.y
		assert(not seen[key], "rooms overlap, seed " .. seed)
		seen[key] = true
		if i > 1 then
			local a = rooms[i - 1]
			assert(math.abs(a.x - r.x) + math.abs(a.y - r.y) == 1, "rooms not adjacent")
		end
		if r.hasFuse then
			fuses += 1
			assert(i > 1 and i < 10, "fuse in start or lift room")
		end
		assert(not kinds[r.kind], "repeated room kind")
		kinds[r.kind] = true
	end
	assert(fuses == 3, "expected 3 fuses, got " .. fuses)
	checked += 1
end

local a, b = LevelGen.generate(11, 8, 3), LevelGen.generate(99, 8, 3)
local different = false
for i in a do
	different = different or a[i].kind ~= b[i].kind or a[i].x ~= b[i].x or a[i].y ~= b[i].y
end
assert(different, "seeds should change the level")

local r = LevelGen.route(7, 3)
assert(#r == 5 and r[1] == 7 and r[5] == 3, "route backwards")
assert(#LevelGen.route(4, 4) == 1, "route to same room")

local function nextState(state, o)
	return Brain.nextState({
		state = state, seesPlayer = o.sees or false, heardNoise = o.heard or false,
		secondsSinceSeen = o.since or 100, arrived = o.arrived or false, loseTargetSeconds = 3,
	})
end
assert(nextState("Patrol", { sees = true }) == "Chase")
assert(nextState("Patrol", { heard = true }) == "Investigate")
assert(nextState("Patrol", {}) == "Patrol")
assert(nextState("Chase", { since = 1 }) == "Chase")
assert(nextState("Chase", { since = 5 }) == "Investigate")
assert(nextState("Investigate", { arrived = false }) == "Investigate")
assert(nextState("Investigate", { arrived = true }) == "Patrol")
assert(Brain.noiseRadius(0, 14, 70) == 0)
assert(Brain.noiseRadius(10, 14, 70) == 14)
assert(Brain.noiseRadius(19, 14, 70) == 70)

assert(Brain.cueIntensity(0, 60) == 1)
assert(Brain.cueIntensity(30, 60) == 0.5)
assert(Brain.cueIntensity(90, 60) == 0)
assert(Brain.revealChance("Patrol", 2, 24) == 0, "figure only shows in a chase")
assert(Brain.revealChance("Chase", 30, 24) == 0, "figure hidden beyond range")
assert(Brain.revealChance("Chase", 3, 24) == 1, "figure solid up close")
local midChance = Brain.revealChance("Chase", 18, 24)
assert(midChance > 0.3 and midChance < 1, "figure flickers at mid range")
local shortest, longest = Brain.stepDelay(14, 0), Brain.stepDelay(14, 1)
assert(longest > shortest * 2, "steps should be uneven")

-- Rooms: nothing blocks a route, nothing leaves the room, and every door gap is really open.
local Rooms = require("../src/shared/Rooms")
local Story = require("../src/shared/Story")
local Pacing = require("../src/shared/Pacing")
local LANE = 5.2
local function extent(b)
	local sx, sz = b.s[1], b.s[3]
	if b.ry and b.ry ~= 0 then -- rotated: use the bounding square
		local m = math.sqrt(sx * sx + sz * sz)
		sx, sz = m, m
	end
	return b.p[1] - sx / 2, b.p[1] + sx / 2, b.p[3] - sz / 2, b.p[3] + sz / 2
end
local boxCount, maxBoxes = 0, 0
local allKinds = table.clone(LevelGen.KINDS)
table.insert(allKinds, "Foyer")
table.insert(allKinds, "Exit")
local BANNED = { "person", "people", "face", "skeleton", "statue", "portrait", "jinn", "ghost", "demon" }
local checkWords
for _, kind in allKinds do
	for _, doors in { { N = true, S = true, E = false, W = false }, { N = false, S = false, E = true, W = true }, { N = true, S = false, E = true, W = false } } do
		local list = Rooms.build(kind, doors, 4242, true)
		boxCount = #list
		maxBoxes = math.max(maxBoxes, boxCount)
		local found = {}
		for _, b in list do
			assert(Rooms.COLORS[b.c], kind .. " unknown color " .. b.c)
			if b.solid and not b.wall then
				local x0, x1, z0, z1 = extent(b)
				local bottom = b.p[2] - b.s[2] / 2
				if bottom < 9 then
					local inX = x0 < LANE and x1 > -LANE
					local inZ = z0 < LANE and z1 > -LANE
					assert(not (inX or inZ), kind .. ": solid box blocks a route at " .. b.p[1] .. "," .. b.p[3])
				end
				assert(x0 >= -20 and x1 <= 20 and z0 >= -20 and z1 <= 20, kind .. ": box outside room")
			end
			if b.wall and b.s[2] > 3 and b.p[2] - b.s[2] / 2 < 1 then
				-- a floor-level wall piece must not fill an open doorway
				local x0, x1, z0, z1 = extent(b)
				local narrowX = b.s[1] < b.s[3]
				if not (b.s[1] == 40 and b.s[3] == 40) then
					local wallName = if narrowX then (if b.p[1] > 0 then "E" else "W") else (if b.p[3] > 0 then "S" else "N")
					if doors[wallName] then
						local lo, hi = if narrowX then z0 else x0, if narrowX then z1 else x1
						assert(hi <= -4.4 or lo >= 4.4, kind .. ": wall fills open door " .. wallName)
					end
				end
			end
			if b.tag then
				found[b.tag] = true
			end
			if b.text then
				for line in string.gmatch(b.text.value, "[^\n]+") do
					local words = 0
					for _ in string.gmatch(line, "%S+") do
						words += 1
					end
					assert(words <= 5, kind .. ": sign too wordy: " .. line)
					local low = string.lower(line)
					for _, bad in BANNED do
						assert(not string.find(low, bad, 1, true), kind .. ": banned word " .. bad)
					end
				end
			end
		end
		assert(found.Lamp and found.Tile, kind .. " missing scare anchors")
		if kind == "Exit" then
			assert(found.Panel, "Exit needs a gate panel")
		end
	end
end
local function wordsIn(text)
	local n = 0
	for _ in string.gmatch(text, "%S+") do
		n += 1
	end
	return n
end
for _, key in { "DISCLAIMER", "GOAL", "AWAKE", "GATE", "CAUGHT", "ESCAPED", "ESCAPED_HOOK", "CHASE", "DESKS", "MIRROR", "NEXT_HINT" } do
	assert(wordsIn(Story[key]) <= 5, "story too wordy: " .. key)
end
-- A username is one word, so "WATCHING NAME" stays at 2
assert(wordsIn(Story.WATCHING) == 1, "WATCHING must be one word")
for _, group in { Story.INTRO, Story.FUSE, Story.CHALK } do
	for _, line in group do
		assert(wordsIn(line) <= 5, "story too wordy: " .. line)
	end
end
for stage = 0, 3 do
	assert(Pacing.gap(stage, 1) <= 15, "quiet gap too long at stage " .. stage)
end
assert(Pacing.gap(3, 1) < Pacing.gap(0, 0), "finale should be faster")
assert(Pacing.pick({ "A", "B" }, "A", 0.5) == "B", "should not repeat")
assert(Pacing.pick({ "A" }, "A", 0.5) == "A", "single option still fires")
local level7 = LevelGen.generate(5, 7, 3)
assert(#level7 == 9, "seven middle rooms")

-- Staged scares: footsteps close in, go round the player, and never form a beat.
local SetPieces = require("../src/shared/SetPieces")
math.randomseed(87)
for _ = 1, 2000 do
	local steps = SetPieces.circle(math.random)
	local total = 0
	for i, step in steps do
		total += step.wait
		if i > 1 then
			assert(step.radius < steps[i - 1].radius, "steps should close in")
			assert(math.abs(step.wait - steps[i - 1].wait) >= 0.1, "steps form a beat")
		end
	end
	assert(steps[#steps].angle - steps[1].angle >= 300, "steps should circle the player")
	assert(steps[#steps].radius >= 3, "last step too close")
	assert(total <= 7, "blackout too long")
	local gaps = SetPieces.wave(36, 0.05, 0.17, math.random)
	assert(#gaps == 36, "one gap per door")
	for i = 2, #gaps do
		assert(math.abs(gaps[i] - gaps[i - 1]) >= 0.02, "bangs form a beat")
	end
end
-- Every run has at least one room scene, and each scene's room has what it needs.
for seed = 1, 3000 do
	local any = false
	for _, room in LevelGen.generate(seed * 104729, 7, 3) do
		any = any or SetPieces.BY_ROOM[room.kind] ~= nil
	end
	assert(any, "run with no room scene, seed " .. seed)
end
local NEEDS = { Lockers = "LockerDoor", Desks = "Desk", Stalls = "Stall" }
for kind, piece in SetPieces.BY_ROOM do
	local tags = {}
	for _, b in Rooms.build(kind, { N = true, S = true, E = false, W = false }, 4242, true) do
		if b.tag then
			tags[b.tag] = true
		end
	end
	assert(tags[NEEDS[piece]], kind .. " has nothing for its scene")
	if piece == "Desks" then
		assert(tags.Board, kind .. " needs a board")
	end
	if piece == "Stalls" then
		assert(tags.Mirror, kind .. " needs a mirror")
	end
end

print("Largest room: " .. maxBoxes .. " parts")
print("OK: checked " .. checked .. " levels and the monster rules")
