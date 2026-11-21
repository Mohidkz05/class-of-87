--!strict
-- Decides what the monster does. Pure logic, so tests can run it outside Studio.
local Brain = {}

export type Input = {
	state: string,
	seesPlayer: boolean,
	heardNoise: boolean,
	secondsSinceSeen: number,
	arrived: boolean,
	loseTargetSeconds: number,
}

function Brain.nextState(i: Input): string
	if i.seesPlayer then
		return "Chase"
	end
	if i.state == "Chase" and i.secondsSinceSeen < i.loseTargetSeconds then
		return "Chase"
	end
	if i.heardNoise then
		return "Investigate"
	end
	if i.state == "Chase" then
		return "Investigate" -- check the place it last saw someone
	end
	if i.state == "Investigate" and not i.arrived then
		return "Investigate"
	end
	return "Patrol"
end

-- How far away a player can be heard at a given speed. 0 means silent.
function Brain.noiseRadius(speed: number, walkRadius: number, sprintRadius: number): number
	if speed > 14 then
		return sprintRadius
	elseif speed > 2 then
		return walkRadius
	end
	return 0
end

-- How strongly nearby cues fire: 1 when the presence is on top of you, 0 at the edge of range.
function Brain.cueIntensity(distance: number, range: number): number
	return math.clamp(1 - distance / range, 0, 1)
end

-- Chance the headless figure is glimpsed on one cue tick: only in a chase, surer as it closes in.
function Brain.revealChance(state: string, distance: number, range: number): number
	if state ~= "Chase" or distance >= range then
		return 0
	end
	return math.clamp(0.3 + (1 - distance / range) * 1.05, 0, 1)
end

-- Time until the next footstep. The uneven gap (roll is 0 to 1) keeps steps from forming a beat.
function Brain.stepDelay(speed: number, roll: number): number
	return (14 / speed) * (0.6 + roll * 0.8)
end

return Brain
