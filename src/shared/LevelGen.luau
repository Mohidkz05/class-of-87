--!strict
-- Pure level logic with no Roblox dependencies, so tests can run it outside Studio.
local LevelGen = {}

export type Room = { x: number, y: number, kind: string, hasFuse: boolean }

LevelGen.KINDS = {
	"Classroom", "ChemLab", "Library", "Cafeteria", "Gym",
	"LockerHall", "Boiler", "Office", "Washroom", "Detention",
}

local function newRng(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(n: number): number -- whole number from 1 to n
		state = (state * 48271) % 2147483647
		return state % n + 1
	end
end

local function shuffle<T>(list: { T }, rng: (number) -> number)
	for i = #list, 2, -1 do
		local j = rng(i)
		list[i], list[j] = list[j], list[i]
	end
end

local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- Grid path that never crosses itself. Backtracks when it hits a dead end.
local function walk(length: number, rng: (number) -> number): { { x: number, y: number } }
	local path = { { x = 0, y = 0 } }
	local used = { ["0,0"] = true }
	local function step(): boolean
		if #path == length then
			return true
		end
		local here = path[#path]
		local order = table.clone(DIRS)
		shuffle(order, rng)
		for _, d in order do
			local nx, ny = here.x + d[1], here.y + d[2]
			local key = nx .. "," .. ny
			if not used[key] then
				used[key] = true
				table.insert(path, { x = nx, y = ny })
				if step() then
					return true
				end
				table.remove(path)
				used[key] = nil
			end
		end
		return false
	end
	assert(step(), "could not lay out level")
	return path
end

function LevelGen.generate(seed: number, middleRooms: number, fuses: number): { Room }
	assert(fuses <= middleRooms, "more fuses than rooms")
	local rng = newRng(seed)
	local cells = walk(middleRooms + 2, rng)

	local kinds = table.clone(LevelGen.KINDS)
	shuffle(kinds, rng)

	local rooms: { Room } = {}
	for i, cell in cells do
		local kind = if i == 1 then "Foyer"
			elseif i == #cells then "Exit"
			else kinds[(i - 2) % #kinds + 1]
		rooms[i] = { x = cell.x, y = cell.y, kind = kind, hasFuse = false }
	end

	-- One fuse per evenly sized section, so they never bunch up at one end.
	for f = 1, fuses do
		local first = 2 + math.floor((f - 1) * middleRooms / fuses)
		local last = 1 + math.floor(f * middleRooms / fuses)
		rooms[first + rng(last - first + 1) - 1].hasFuse = true
	end
	return rooms
end

-- Rooms connect in a line, so a route is simply the rooms between two indexes.
function LevelGen.route(fromIndex: number, toIndex: number): { number }
	local out = {}
	local dir = if toIndex >= fromIndex then 1 else -1
	for i = fromIndex, toIndex, dir do
		table.insert(out, i)
	end
	return out
end

return LevelGen
