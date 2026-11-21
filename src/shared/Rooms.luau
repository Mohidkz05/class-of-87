--!nonstrict
-- Every room as plain data, so tests can check it and a preview can draw it outside Studio.
-- World.luau turns these boxes into Roblox parts.
-- Art rule: no people, animals, faces or figures anywhere. See docs/REQUIREMENTS.md, R4.
local Rooms = {}

Rooms.COLORS = {
	Plaster = { 112, 116, 96 }, Paint = { 74, 94, 82 }, Wainscot = { 58, 70, 62 }, Trim = { 44, 36, 28 },
	Ceiling = { 70, 68, 60 }, Stain = { 36, 34, 26 }, TileA = { 94, 90, 78 }, TileB = { 34, 36, 34 },
	TileGreen = { 62, 84, 74 }, Wood = { 104, 72, 42 }, WoodDark = { 62, 42, 26 }, GymWood = { 138, 96, 52 },
	Steel = { 86, 90, 94 }, Locker = { 58, 88, 92 }, LockerRed = { 112, 44, 36 }, Rust = { 110, 62, 38 },
	Black = { 18, 18, 18 }, Chalkboard = { 28, 54, 42 }, Paper = { 196, 186, 150 }, Glass = { 160, 190, 190 },
	Moon = { 130, 160, 210 }, Lamp = { 214, 232, 190 }, Chem = { 90, 230, 130 }, Warn = { 214, 170, 40 },
	Red = { 220, 40, 30 }, Gold = { 190, 150, 60 }, Blue = { 44, 62, 104 }, White = { 208, 204, 190 },
	Book1 = { 110, 40, 36 }, Book2 = { 40, 70, 96 }, Book3 = { 50, 84, 50 }, Book4 = { 120, 96, 50 }, Brick = { 96, 54, 42 }, Cork = { 112, 84, 54 }, Concrete = { 74, 74, 70 },
}

export type Box = {
	s: { number }, p: { number }, c: string, m: string, solid: boolean,
	rx: number?, ry: number?, rz: number?, shape: string?, tag: string?, group: string?,
	wall: boolean?, alpha: number?, text: { [string]: any }?, light: { [string]: any }?,
}
export type Doors = { N: boolean, S: boolean, E: boolean, W: boolean }

Rooms.CELL = 40
Rooms.HEIGHT = 16
Rooms.DOOR_W = 10
Rooms.DOOR_H = 11

type Rng = () -> number -- returns 0 to 1

local function box(list: { Box }, sx: number, sy: number, sz: number, x: number, y: number, z: number, c: string, m: string, o: { [string]: any }?): Box
	local b: any = { s = { sx, sy, sz }, p = { x, y + sy / 2, z }, c = c, m = m, solid = true }
	if o then
		for k, v in o do
			b[k] = v
		end
	end
	table.insert(list, b)
	return b
end

local function deco(list, sx, sy, sz, x, y, z, c, m, o: { [string]: any }?)
	local b = box(list, sx, sy, sz, x, y, z, c, m, o)
	b.solid = false
	return b
end

-- Place something flat on a wall. s is the position along the wall; it must keep off door gaps.
local function onWall(list, wall: string, s: number, y: number, w: number, h: number, d: number, c: string, m: string, o: { [string]: any }?)
	local at = 19 - d / 2
	local b
	if wall == "N" then
		b = box(list, w, h, d, s, y, -at, c, m, o)
	elseif wall == "S" then
		b = box(list, w, h, d, s, y, at, c, m, o)
	elseif wall == "E" then
		b = box(list, d, h, w, at, y, s, c, m, o)
	else
		b = box(list, d, h, w, -at, y, s, c, m, o)
	end
	b.solid = false
	return b
end
local FACE = { N = "Back", S = "Front", E = "Left", W = "Right" }

local function sign(list, wall, s, y, w, h, words: string, opts: { [string]: any }?)
	local o = opts or {}
	onWall(list, wall, s, y, w, h, 0.25, o.bg or "Paper", "SmoothPlastic", {
		tag = o.tag,
		text = { face = FACE[wall], value = words, font = o.font or "SpecialElite", color = o.color or { 24, 22, 18 } },
	})
end

local function chalkboard(list, wall, s, y, w, h, words: string)
	onWall(list, wall, s, y - 0.3, w + 0.6, h + 0.6, 0.2, "WoodDark", "Wood")
	onWall(list, wall, s, y, w, h, 0.32, "Chalkboard", "Slate", {
		tag = "Board",
		text = { face = FACE[wall], value = words, font = "PermanentMarker", color = { 225, 225, 210 } },
	})
end

local function boardedWindow(list, wall, s, y)
	onWall(list, wall, s, y, 9, 6.5, 0.1, "Moon", "Neon", { alpha = 0.25 })
	onWall(list, wall, s, y - 0.3, 10, 0.4, 0.3, "WoodDark", "Wood")
	onWall(list, wall, s, y + 6.5, 10, 0.4, 0.3, "WoodDark", "Wood")
	for i = 0, 2 do
		onWall(list, wall, s, y + 0.8 + i * 2, 10.5, 0.8, 0.4, "Wood", "WoodPlanks", { rz = if wall == "N" or wall == "S" then (i - 1) * 3 else 0 })
	end
end

local function fluorescent(list, x, z, on: boolean)
	local H = Rooms.HEIGHT
	deco(list, 7, 0.3, 1.6, x, H - 0.75, z, "Steel", "Metal")
	deco(list, 6.4, 0.2, 1, x, H - 0.95, z, if on then "Lamp" else "Stain", if on then "Neon" else "SmoothPlastic", {
		tag = if on then "Lamp" else nil,
		light = if on then { range = 24, brightness = 0.9, color = { 214, 232, 190 } } else nil,
	})
end

local function clock(list, wall, s, y, hour: number)
	onWall(list, wall, s, y, 2.4, 2.4, 0.2, "White", "SmoothPlastic", {
		text = { face = FACE[wall], value = tostring(hour) .. ":17", font = "SpecialElite", color = { 30, 30, 30 } },
	})
end

local function desk(list, group: string, x, z, ry: number?, tilt: number?)
	local o = { group = group, tag = "Desk", ry = ry, rz = tilt }
	box(list, 3.4, 0.25, 2.4, x, 2.6, z, "Wood", "WoodPlanks", o)
	for _, l in { { 1.5, 1 }, { -1.5, 1 }, { 1.5, -1 }, { -1.5, -1 } } do
		box(list, 0.2, 2.6, 0.2, x + l[1], 0, z + l[2], "Steel", "Metal", o)
	end
	box(list, 2.2, 0.2, 1.8, x, 1.6, z + 2.1, "WoodDark", "Wood", o)
	box(list, 2.2, 1.6, 0.2, x, 1.8, z + 3, "WoodDark", "Wood", o)
end

local function lockers(list, wall: string, from: number, count: number, color: string, tagged: boolean)
	local at = 19 - 1.25
	for i = 0, count - 1 do
		local s = from + i * 2.2
		local bodyX, bodyZ = s, -at
		local door: { number } = { s, 0, -at + 1.33 }
		local size = { 2, 8, 2.5 }
		local doorSize = { 1.9, 7.6, 0.16 }
		if wall == "S" then
			bodyZ, door = at, { s, 0, at - 1.33 }
		elseif wall == "E" then
			bodyX, bodyZ, door, size, doorSize = at, s, { at - 1.33, 0, s }, { 2.5, 8, 2 }, { 0.16, 7.6, 1.9 }
		elseif wall == "W" then
			bodyX, bodyZ, door, size, doorSize = -at, s, { -at + 1.33, 0, s }, { 2.5, 8, 2 }, { 0.16, 7.6, 1.9 }
		end
		box(list, size[1], size[2], size[3], bodyX, 0, bodyZ, "Black", "Metal")
		deco(list, doorSize[1], doorSize[2], doorSize[3], door[1], 0.2, door[3], color, "Metal", {
			tag = if tagged then "LockerDoor" else nil,
			hinge = if wall == "N" or wall == "S" then "X" else "Z",
		})
	end
end

local function shelf(list, x, z, along: string, seed: Rng)
	local long, deep = 11, 2
	local w, d = if along == "X" then long else deep, if along == "X" then deep else long
	box(list, w, 10, d, x, 0, z, "WoodDark", "Wood")
	local colors = { "Book1", "Book2", "Book3", "Book4" }
	for row = 0, 3 do
		for i = 0, 4 do
			local c = colors[math.floor(seed() * 4) + 1]
			local off = -4 + i * 2
			local h = 1.3 + seed() * 0.6
			local sx = if along == "X" then 1.7 else 0.14
			local sz = if along == "X" then 0.14 else 1.7
			for _, face in { 1, -1 } do -- both sides, since players walk all round
				local bx = if along == "X" then x + off else x + face * (d / 2 + 0.05)
				local bz = if along == "X" then z + face * (d / 2 + 0.05) else z + off
				deco(list, sx, h, sz, bx, 0.8 + row * 2.3, bz, c, "Fabric")
			end
		end
	end
end

local function benchTable(list, x, z, along: string)
	local w, d = if along == "X" then 11 else 3.5, if along == "X" then 3.5 else 11
	box(list, w, 0.3, d, x, 2.8, z, "White", "SmoothPlastic")
	box(list, if along == "X" then 9 else 0.5, 2.8, if along == "X" then 0.5 else 9, x, 0, z, "Steel", "Metal")
	for _, side in { -1, 1 } do
		local bx = if along == "X" then x else x + side * 3
		local bz = if along == "X" then z + side * 3 else z
		box(list, if along == "X" then 10 else 1.2, 0.3, if along == "X" then 1.2 else 10, bx, 1.5, bz, "Steel", "Metal")
	end
end

local function trophy(list, x, y, z)
	deco(list, 0.9, 0.3, 0.9, x, y, z, "WoodDark", "Wood")
	deco(list, 0.7, 1, 0.7, x, y + 0.3, z, "Gold", "Metal", { shape = "Ball" })
	deco(list, 0.2, 0.5, 0.9, x, y + 0.9, z, "Gold", "Metal")
end

-- Roblox cylinders run along X, so an upright one is sized (height, d, d) and tilted 90 degrees.
local function upright(list, d, h, x, y, z, c, m, o: { [string]: any }?, solid: boolean?)
	local b = box(list, h, d, d, x, y, z, c, m, o)
	b.shape = "Cylinder"
	b.rz = 90
	b.p[2] = y + h / 2
	b.solid = solid == true
	return b
end

-- Decay that makes every room feel abandoned: exposed brick, hanging cable and rubble.
local function decay(l, r)
	for _, wall in { "N", "S", "E", "W" } do
		local s = (if r() > 0.5 then 1 else -1) * (9 + r() * 7)
		local w, h = 3 + r() * 4, 2 + r() * 3
		local y = 5 + r() * 6
		onWall(l, wall, s, y, w, h, 0.06, "Brick", "Brick")
		onWall(l, wall, s + w * 0.3, y + h * 0.5, w * 0.7, h * 0.9, 0.1, "Brick", "Brick")
	end
	-- Dead cable dangling from the ceiling
	local cx, cz = (if r() > 0.5 then 1 else -1) * (8 + r() * 8), (if r() > 0.5 then 1 else -1) * (8 + r() * 8)
	deco(l, 0.12, 5 + r() * 3, 0.12, cx, 8, cz, "Black", "SmoothPlastic", { rz = 3 })
	-- Rubble heaps along the floor, kept to the corners
	for i = 1, 8 do
		local sx = if i % 2 == 0 then 1 else -1
		local sz = if i % 4 < 2 then 1 else -1
		local size = 0.3 + r() * 0.9
		deco(l, size, size * 0.6, size, sx * (13 + r() * 5), 0.06, sz * (13 + r() * 5), if i % 3 == 0 then "Brick" else "Plaster", "Slate", { ry = r() * 90 })
	end
	-- Pipe run along one wall near the ceiling
	onWall(l, "N", 0, Rooms.HEIGHT - 2, 40, 0.5, 0.5, "Rust", "CorrodedMetal")
end

local PROPS: { [string]: (list: { Box }, r: Rng) -> () } = {}

function PROPS.Foyer(l, r)
	sign(l, "N", -12.5, 10, 12, 2.4, "CLOSED 1987", { bg = "Red", font = "Bangers", color = { 245, 240, 225 } })
	-- Chained front doors
	onWall(l, "S", 12.5, 0, 12, 10.5, 0.5, "WoodDark", "WoodPlanks")
	onWall(l, "S", 12.5, 4.5, 12.5, 0.5, 0.7, "Steel", "CorrodedMetal", { rz = 8 })
	onWall(l, "S", 12.5, 5, 12.5, 0.5, 0.7, "Steel", "CorrodedMetal", { rz = -8 })
	onWall(l, "S", 12.5, 3.8, 1.6, 1.6, 0.9, "Rust", "CorrodedMetal")
	-- Trophy case: cups only
	box(l, 11, 3, 2.4, -12.5, 0, 16.5, "WoodDark", "Wood")
	deco(l, 11, 5.5, 2.4, -12.5, 3, 16.5, "Glass", "Glass", { alpha = 0.7 })
	for i = 0, 4 do
		trophy(l, -16.5 + i * 2, 3.1, 16.5)
	end
	deco(l, 8, 0.05, 5, 0, 0.06, 13, "Trim", "Fabric")
	sign(l, "E", -12.5, 7, 8, 1.6, "PLEASE WALK", {})
	box(l, 2, 3, 2, 13, 0, -13, "Wood", "Wood", { rx = 75 })
end

function PROPS.Classroom(l, r)
	chalkboard(l, "N", -12.5, 5, 13, 5.5, "MATH QUIZ")
	chalkboard(l, "N", 12.5, 5, 13, 5.5, "SEE ME")
	boardedWindow(l, "E", 12.5, 6)
	boardedWindow(l, "E", -12.5, 6)
	clock(l, "S", 12.5, 11, 3)
	onWall(l, "S", -12.5, 6, 11, 5, 0.15, "Cork", "Fabric")
	for i = 0, 5 do
		onWall(l, "S", -16.5 + (i % 3) * 3.6, 6.7 + (i // 3) * 2.2, 2.4, 1.7, 0.22, if i % 2 == 0 then "Paper" else "White", "SmoothPlastic", { ry = 0 })
	end
	onWall(l, "W", 12.5, 6.5, 8, 5, 0.2, "Paper", "SmoothPlastic", {
		text = { face = "Right", value = "CLASS OF 87", font = "SpecialElite", color = { 40, 30, 24 } },
	})
	local n = 0
	for _, q in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		n += 1
		desk(l, "desk" .. n, q[1] * 10, q[2] * 9, 0, if n == 3 then 18 else nil)
		n += 1
		desk(l, "desk" .. n, q[1] * 15, q[2] * 9, 0)
	end
end

function PROPS.ChemLab(l, r)
	chalkboard(l, "N", 12.5, 5, 12, 5, "DO NOT MIX")
	sign(l, "W", 12.5, 5, 9, 6, "H  He  Li\nBe  B  C\nN  O  F", { font = "SpecialElite" })
	for _, q in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		local x, z = q[1] * 12.5, q[2] * 11
		box(l, 10, 3, 3.6, x, 0, z, "WoodDark", "Wood")
		box(l, 10.4, 0.3, 4, x, 3, z, "Black", "Slate")
		for i = -1, 1 do
			deco(l, 0.8, 1.6, 0.8, x + i * 3, 3.3, z, "Chem", "Neon", {
				shape = if i == 0 then "Ball" else "Block", alpha = 0.35,
			})
		end
		deco(l, 1.2, 1.4, 0.3, x, 3.3, z + 1.2, "Steel", "Metal")
	end
	deco(l, 0.6, 0.2, 0.6, 12.5, 3.2, 12.5, "Chem", "Neon", { light = { range = 18, brightness = 0.7, color = { 90, 230, 130 } } })
	deco(l, 3, 0.05, 2, -8, 0.07, 8, "Chem", "SmoothPlastic", { alpha = 0.5 })
end

function PROPS.Library(l, r)
	sign(l, "N", -12.5, 10, 10, 2, "SILENCE", { bg = "Black", color = { 230, 225, 205 }, font = "Bangers" })
	shelf(l, 12.5, 16, "X", r)
	shelf(l, -12.5, 16, "X", r)
	shelf(l, 12.5, 9, "X", r)
	shelf(l, -12.5, 9, "X", r)
	shelf(l, 12.5, -11, "X", r)
	shelf(l, -12.5, -11, "X", r)
	box(l, 7, 0.3, 3.5, 12, 2.8, -16, "Wood", "WoodPlanks")
	box(l, 0.5, 2.8, 3, 12, 0, -16, "WoodDark", "Wood")
	for i = 1, 10 do
		deco(l, 1.6, 0.3, 1.1, -14 + r() * 8, 0.05 + (i % 3) * 0.3, -14 + r() * 6, ({ "Book1", "Book2", "Book3", "Book4" })[i % 4 + 1], "Fabric", { ry = r() * 90 })
	end
end

function PROPS.Cafeteria(l, r)
	sign(l, "N", -12.5, 8, 11, 4, "TODAY:\nNOTHING", { bg = "Black", font = "PermanentMarker", color = { 230, 225, 205 } })
	benchTable(l, 12.5, 12.5, "X")
	benchTable(l, -12.5, 12.5, "X")
	benchTable(l, 12.5, -12.5, "X")
	box(l, 12, 3.6, 3, -12.5, 0, -15, "Steel", "Metal")
	deco(l, 12, 0.3, 3, -12.5, 7, -15, "Steel", "Metal")
	for i = 1, 8 do
		deco(l, 1.8, 0.1, 1.2, 12.5 + (r() - 0.5) * 8, 3.12, 12.5 + (r() - 0.5) * 2, "Book4", "SmoothPlastic", { ry = r() * 40 })
	end
	for i = 1, 3 do
		deco(l, 1.4, 0.1, 1.4, -8 - i, 0.09, 8 + i, "Book4", "SmoothPlastic", { ry = i * 30 })
	end
	-- Serving hatch with a shutter half down
	onWall(l, "E", -12.5, 3.6, 12, 5, 0.25, "Black", "SmoothPlastic")
	onWall(l, "E", -12.5, 6, 12, 2.6, 0.4, "Steel", "CorrodedMetal")
	deco(l, 5, 3, 0.4, -14, 3.6, -13.4, "White", "SmoothPlastic", { alpha = 0.2 })
end

function PROPS.Gym(l, r)
	upright(l, 18, 0.06, 0, 0.06, 0, "Warn", "SmoothPlastic", { alpha = 0.45 })
	upright(l, 15, 0.07, 0, 0.07, 0, "GymWood", "WoodPlanks")
	for _, x in { -11, 11 } do -- court lines
		deco(l, 0.5, 0.06, 40, x, 0.06, 0, "Warn", "SmoothPlastic", { alpha = 0.45 })
	end
	for row = 0, 3 do
		box(l, 12, 1.2 + row * 1.5, 2.4, 12.5, 0, 17.4 - row * 2.4, "Wood", "WoodPlanks")
		box(l, 12, 1.2 + row * 1.5, 2.4, -12.5, 0, 17.4 - row * 2.4, "Wood", "WoodPlanks")
	end
	sign(l, "N", -12.5, 11, 13, 2.4, "GO EAGLES", { bg = "Blue", font = "Bangers", color = { 235, 225, 200 } })
	onWall(l, "N", 12.5, 9, 7, 4.5, 0.25, "White", "SmoothPlastic")
	upright(l, 3, 0.15, 12.5, 9.2, -16.3, "Red", "Metal")
	deco(l, 0.4, 0.4, 2.4, 12.5, 9.1, -17.6, "Steel", "Metal")
	deco(l, 1.6, 1.6, 1.6, 8, 0.05, -11, "Rust", "Fabric", { shape = "Ball" })
end

function PROPS.LockerHall(l, r)
	lockers(l, "N", -18, 6, "Locker", true)
	lockers(l, "N", 7, 6, "Locker", true)
	lockers(l, "S", -18, 6, "LockerRed", true)
	lockers(l, "S", 7, 6, "LockerRed", true)
	lockers(l, "E", 7, 6, "Locker", true)
	lockers(l, "W", -18, 6, "LockerRed", true)
	sign(l, "N", 12.5, 10, 7, 1.6, "NO RUNNING", {})
	sign(l, "S", -12.5, 10, 7, 1.6, "HALL PASS?", {})
	onWall(l, "W", 12.5, 2, 7, 6, 0.15, "Cork", "Fabric")
	onWall(l, "W", 12.5, 3.6, 2.4, 2.4, 0.25, "Paper", "SmoothPlastic", { ry = 6 })
	for i = 1, 8 do
		deco(l, 0.9, 0.03, 1.2, (r() - 0.5) * 28, 0.08, (r() - 0.5) * 24, "Paper", "SmoothPlastic", { ry = r() * 180 })
	end
end

function PROPS.Boiler(l, r)
	box(l, 11, 7, 7, 13, 1, 14, "Rust", "CorrodedMetal", { shape = "Cylinder" })
	box(l, 11, 1, 7, 13, 0, 14, "Steel", "DiamondPlate")
	upright(l, 1.4, 7.5, 15, 7.5, 14, "Rust", "CorrodedMetal")
	for i = 0, 3 do
		upright(l, 1, 16, -9 - i * 2.4, 0, -17.8, if i % 2 == 0 then "Rust" else "Steel", "CorrodedMetal")
		deco(l, 11, 0.8, 0.8, -12.5, 3 + i * 1.8, 18.1, "Steel", "Metal", { shape = "Cylinder" })
	end
	box(l, 4, 7, 4, -14, 0, 14, "Rust", "CorrodedMetal")
	box(l, 4, 5, 4, -14, 0, 8.6, "Steel", "Metal")
	sign(l, "E", -12.5, 8, 6, 2.2, "DANGER", { bg = "Warn", font = "Bangers" })
	deco(l, 0.3, 1.8, 1.8, 13, 3.3, 10.2, "Red", "Metal", { shape = "Cylinder", ry = 90 })
	deco(l, 0.3, 0.3, 0.3, 13, 9, 10, "Red", "Neon", { light = { range = 18, brightness = 0.9, color = { 255, 90, 40 } } })
	deco(l, 5, 0.05, 3, 11, 0.08, 8, "Black", "SmoothPlastic", { alpha = 0.4 })
end

function PROPS.Office(l, r)
	sign(l, "N", 12.5, 10.5, 9, 1.8, "PRINCIPAL", { bg = "WoodDark", color = { 225, 200, 140 } })
	box(l, 8, 3, 3.6, 12.5, 0, -11, "WoodDark", "WoodPlanks")
	deco(l, 1.4, 0.7, 1, 11, 3, -11, "Black", "SmoothPlastic")
	for i = 1, 6 do
		deco(l, 1, 0.03, 1.3, 13 + (r() - 0.5) * 6, 3.03, -11 + (r() - 0.5) * 2, "Paper", "SmoothPlastic", { ry = r() * 60 })
	end
	for i = 0, 3 do
		box(l, 2.3, 6, 2.5, -18 + i * 2.5, 0, -16.6, "Steel", "Metal")
		deco(l, 1.6, 0.2, 0.1, -18 + i * 2.5, 4.4, -15.3, "Black", "Metal")
		deco(l, 1.6, 0.2, 0.1, -18 + i * 2.5, 2, -15.3, "Black", "Metal")
	end
	sign(l, "S", 12.5, 4.5, 8, 6.5, "ROLL CALL\nABSENT\nABSENT\nABSENT\nABSENT", {})
	box(l, 10, 3, 3, -12.5, 0, 15, "Wood", "Wood")
	boardedWindow(l, "E", 12.5, 6)
	clock(l, "S", -12.5, 11, 3)
	for i = 1, 8 do
		deco(l, 1.2, 0.03, 1.5, -14 + r() * 10, 0.08, 7 + r() * 8, "Paper", "SmoothPlastic", { ry = r() * 180 })
	end
end

function PROPS.Washroom(l, r)
	deco(l, 0, 0, 0, 0, 0, 0, "Black", "Metal", { alpha = 1 })
	for i = 0, 2 do
		local x = 8 + i * 4
		box(l, 0.25, 7.5, 6, x, 0.8, 15.5, "TileGreen", "Metal")
		box(l, 3.7, 7.2, 0.2, x + 2, 0.8, 12.6, "Paint", "Metal", { ry = if i == 1 then 35 else 0, tag = "Stall", hinge = "X" })
		box(l, 0.25, 7.5, 6, -x, 0.8, 15.5, "TileGreen", "Metal")
		box(l, 3.7, 7.2, 0.2, -x - 2, 0.8, 12.6, "Paint", "Metal", { ry = if i == 2 then -40 else 0, tag = "Stall", hinge = "X" })
	end
	for i = 0, 3 do
		box(l, 2.6, 1.2, 2.2, 8 + i * 3, 2.6, -17.7, "White", "Marble")
		deco(l, 0.5, 2.6, 0.5, 8 + i * 3, 0, -17.7, "Steel", "Metal")
		box(l, 2.6, 1.2, 2.2, -8 - i * 3, 2.6, -17.7, "White", "Marble")
		deco(l, 0.5, 2.6, 0.5, -8 - i * 3, 0, -17.7, "Steel", "Metal")
	end
	onWall(l, "N", 12.5, 5, 13, 3.6, 0.1, "Glass", "Glass")
	sign(l, "N", -12.5, 5, 12, 3.6, "", { bg = "Glass", font = "PermanentMarker", color = { 130, 20, 15 }, tag = "Mirror" }) -- written during the scene
	deco(l, 4, 0.04, 3, 11, 0.08, -9, "Glass", "Glass", { alpha = 0.4 })
end

function PROPS.Detention(l, r)
	chalkboard(l, "N", 12.5, 4, 13, 8, "I WILL NOT RUN\nI WILL NOT RUN\nI WILL NOT RUN\nI WILL NOT RUN")
	chalkboard(l, "N", -12.5, 4, 13, 8, "I WILL STAY\nI WILL STAY\nI WILL STAY")
	boardedWindow(l, "W", 12.5, 6)
	sign(l, "E", -12.5, 8, 8, 2, "DETENTION", { bg = "Black", font = "Bangers", color = { 230, 225, 205 } })
	desk(l, "desk1", 11, 9, 0)
	desk(l, "desk2", -11, 9, 0)
	desk(l, "desk3", 15, -12, 12)
	desk(l, "desk4", -15, -12, -14, -24)
	desk(l, "desk5", 15, 14, 0)
	desk(l, "desk6", -15, 14, 0)
	clock(l, "S", 12.5, 11, 3)
end

function PROPS.Exit(l, r)
	-- Roller gate on a solid wall section
	onWall(l, "N", 12.5, 0, 13, 10.5, 0.5, "Steel", "CorrodedMetal", { tag = "Gate" })
	for i = 0, 8 do
		onWall(l, "N", 12.5, 0.6 + i * 1.15, 13, 0.25, 0.7, "Black", "Metal")
	end
	onWall(l, "N", 12.5, 10.5, 13, 1.4, 0.8, "Warn", "SmoothPlastic", {
		text = { face = "Back", value = "SERVICE GATE", font = "Bangers", color = { 20, 18, 14 } },
	})
	sign(l, "N", -12.5, 10.5, 7, 2, "EXIT", { bg = "Red", font = "Bangers", color = { 255, 245, 230 } })
	deco(l, 0.3, 0.3, 0.3, -12.5, 9.6, -17.8, "Red", "Neon", { light = { range = 26, brightness = 1.1, color = { 255, 60, 45 } } })
	box(l, 2, 5, 1.2, 8, 0, -15.5, "Steel", "Metal", { tag = "Panel" })
	deco(l, 1.4, 1, 0.1, 8, 3.2, -14.86, "Warn", "Neon", { alpha = 0.2 })
	for i = 0, 5 do
		deco(l, 2.2, 0.05, 1, 7.5 + i * 2.2, 0.08, -13.5, if i % 2 == 0 then "Warn" else "Black", "SmoothPlastic")
	end
	box(l, 4, 3.5, 4, -14, 0, 14, "WoodDark", "WoodPlanks")
	box(l, 3, 3, 3, -14.5, 3.5, 14, "Wood", "WoodPlanks", { ry = 22 })
	box(l, 3, 7, 3, 15, 0, 15, "Rust", "CorrodedMetal", { shape = "Block" })
end

Rooms.FLOORS = {
	Foyer = "Checker", Classroom = "Wood", ChemLab = "Green", Library = "Wood", Cafeteria = "Checker",
	Gym = "Gym", LockerHall = "Green", Boiler = "Concrete", Office = "Wood", Washroom = "Checker",
	Detention = "Wood", Exit = "Concrete",
}

local function floor(l: { Box }, style: string)
	local C = Rooms.CELL
	box(l, C, 2, C, 0, -2, 0, "Trim", "Concrete", { wall = true })
	if style == "Checker" or style == "Green" then
		for i = 0, 7 do
			for j = 0, 7 do
				local a = (i + j) % 2 == 0
				local c = if style == "Checker" then (if a then "TileA" else "TileB") else (if a then "TileGreen" else "Paint")
				deco(l, 5, 0.05, 5, -17.5 + i * 5, 0, -17.5 + j * 5, c, "Marble")
			end
		end
	elseif style == "Wood" or style == "Gym" then
		for i = 0, 9 do
			local shade = if style == "Gym" then "GymWood" else (if i % 2 == 0 then "Wood" else "WoodDark")
			deco(l, C, 0.05, 4, 0, 0, -18 + i * 4, shade, "WoodPlanks")
		end
	else
		deco(l, C, 0.05, C, 0, 0, 0, "Concrete", "Concrete")
	end
end

-- Four walls with door gaps, wainscot panels, door frames, and a stained ceiling.
local function shell(l: { Box }, doors: Doors, r: Rng)
	local C, H, DW, DH = Rooms.CELL, Rooms.HEIGHT, Rooms.DOOR_W, Rooms.DOOR_H
	local at = C / 2 - 0.5
	local side = (C - DW) / 2
	local sideOffset = (C + DW) / 4
	for _, w in { { "N", 0, -1 }, { "S", 0, 1 }, { "E", 1, 0 }, { "W", -1, 0 } } do
		local name: any, dx: number, dz: number = w[1], w[2], w[3]
		local alongX = dz ~= 0
		local function put(len, s, height, baseY, c, m, thick, inset)
			local t = thick or 1
			local off = (at - (inset or 0))
			local sx, sz = if alongX then len else t, if alongX then t else len
			local px, pz = if alongX then s else dx * off, if alongX then dz * off else s
			box(l, sx, height, sz, px, baseY, pz, c, m, { wall = true })
		end
		local hasDoor = doors[name]
		local segments = if hasDoor then { { -sideOffset, side }, { sideOffset, side } } else { { 0, C } }
		for _, seg in segments do
			put(seg[2], seg[1], H, 0, "Plaster", "Concrete")
			put(seg[2], seg[1], 4, 0, "Wainscot", "Marble", 0.15, 0.55)
			put(seg[2], seg[1], 0.4, 4, "Trim", "Wood", 0.25, 0.6)
		end
		if hasDoor then
			put(DW, 0, H - DH, DH, "Plaster", "Concrete")
			put(DW + 1.2, 0, 0.8, DH - 0.4, "Trim", "Wood", 1.4)
			put(0.7, -DW / 2 + 0.2, DH, 0, "Trim", "Wood", 1.4)
			put(0.7, DW / 2 - 0.2, DH, 0, "Trim", "Wood", 1.4)
		end
	end
	box(l, C, 2, C, 0, H, 0, "Ceiling", "Concrete", { wall = true })
	-- Loose ceiling tiles that the director can drop, plus water stains and damage
	for i = 1, 5 do
		local x, z = 6 + r() * 10, 6 + r() * 10
		local sx = if i % 2 == 0 then 1 else -1
		local sz = if i % 3 == 0 then 1 else -1
		deco(l, 4, 0.2, 4, sx * x, H - 0.2, sz * z, "Ceiling", "Concrete", { tag = "Tile" })
	end
	for i = 1, 4 do
		local w = ({ "N", "S", "E", "W" })[i]
		onWall(l, w, (if r() > 0.5 then 1 else -1) * (8 + r() * 8), 7 + r() * 6, 2 + r() * 4, 1 + r() * 2, 0.04, "Stain", "SmoothPlastic", { alpha = 0.45 })
	end
	for i = 1, 6 do
		deco(l, 0.5 + r() * 1.2, 0.05, 0.5 + r() * 1.2, (r() - 0.5) * 34, 0.07, (r() - 0.5) * 34, "Stain", "SmoothPlastic", { ry = r() * 90, alpha = 0.3 })
	end
end

function Rooms.doorsFor(rooms: { any }, i: number): Doors
	local d: any = { N = false, S = false, E = false, W = false }
	local me = rooms[i]
	for _, j in { i - 1, i + 1 } do
		local o = rooms[j]
		if o then
			if o.y == me.y - 1 then d.N = true end
			if o.y == me.y + 1 then d.S = true end
			if o.x == me.x + 1 then d.E = true end
			if o.x == me.x - 1 then d.W = true end
		end
	end
	return d
end

function Rooms.build(kind: string, doors: Doors, seed: number, lit: boolean): { Box }
	local state = (seed % 2147483646) + 1
	local function r(): number
		state = (state * 48271) % 2147483647
		return (state % 100000) / 100000
	end
	local list: { Box } = {}
	floor(list, Rooms.FLOORS[kind] or "Concrete")
	shell(list, doors, r)
	decay(list, r)
	fluorescent(list, 0, -8, lit)
	fluorescent(list, 0, 8, kind == "Foyer" or kind == "Exit")
	assert(PROPS[kind], "unknown room kind " .. kind)(list, r)
	-- Remove zero-size helpers
	local out = {}
	for _, b in list do
		if b.s[1] > 0 and b.s[2] > 0 and b.s[3] > 0 then
			table.insert(out, b)
		end
	end
	return out
end

return Rooms
