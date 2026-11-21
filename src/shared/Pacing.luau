--!strict
-- How often something happens. Short attention spans: never a long quiet stretch.
local Pacing = {}

local GAPS = {
	[0] = { 10, 15 }, -- before the first fuse
	[1] = { 8, 12 },
	[2] = { 6, 10 },
	[3] = { 3, 5 }, -- finale
}

function Pacing.gap(stage: number, roll: number): number
	local range = GAPS[math.clamp(stage, 0, 3)]
	return range[1] + (range[2] - range[1]) * roll
end

-- Pick an event, avoiding an immediate repeat when there's another choice.
function Pacing.pick(available: { string }, last: string?, roll: number): string?
	local options: { string } = {}
	for _, name in available do
		if name ~= last then
			table.insert(options, name)
		end
	end
	if #options == 0 then
		return available[1]
	end
	return options[math.clamp(math.floor(roll * #options) + 1, 1, #options)]
end

return Pacing
