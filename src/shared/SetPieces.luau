--!strict
-- Staged scares, as plain data and timing so tests can check them outside Studio.
-- Gaps never repeat evenly, so a run of footsteps or bangs can't turn into a beat.
local SetPieces = {}

-- Rooms that have a big moment the first time a player walks in.
SetPieces.BY_ROOM = {
	LockerHall = "Lockers",
	Classroom = "Desks",
	Detention = "Desks",
	Washroom = "Stalls",
} :: { [string]: string }

export type Step = { angle: number, radius: number, wait: number }

-- A gap that always differs from the previous one by at least a fifth of the range.
local function uneven(low: number, high: number, previous: number?, roll: () -> number): number
	local span = high - low
	local gap = low + span * roll()
	if previous and math.abs(gap - previous) < span * 0.2 then
		gap = if previous < low + span / 2 then previous + span * 0.35 else previous - span * 0.35
	end
	return gap
end

-- Footsteps that circle the player in the dark, closing in.
function SetPieces.circle(roll: () -> number): { Step }
	local steps: { Step } = {}
	local count = 7
	local angle = roll() * 360
	local previous = nil
	for i = 1, count do
		angle += 50 + roll() * 70
		previous = uneven(0.35, 0.95, previous, roll)
		table.insert(steps, { angle = angle, radius = 20 - 15 * (i - 1) / (count - 1), wait = previous })
	end
	return steps
end

-- Gaps for bangs that race along a row of doors.
function SetPieces.wave(count: number, low: number, high: number, roll: () -> number): { number }
	local gaps: { number } = {}
	local previous = nil
	for _ = 1, count do
		previous = uneven(low, high, previous, roll)
		table.insert(gaps, previous)
	end
	return gaps
end

return SetPieces
