-- Prints a sample school as JSON, for an offline 3D preview: luau tests/dump_preview.luau > level.json
local LevelGen = require("../src/shared/LevelGen")
local Rooms = require("../src/shared/Rooms")
local function n(v) return string.format("%.3f", v or 0) end
local kinds = table.clone(LevelGen.KINDS)
table.insert(kinds, 1, "Foyer")
table.insert(kinds, "Exit")
local out = {}
for i, kind in kinds do
	local list = Rooms.build(kind, { N = true, S = true, E = false, W = false }, i * 977 + 5003, true)
	for _, b in list do
		local c = Rooms.COLORS[b.c]
		table.insert(out, string.format('{"r":"%s","ox":%s,"oz":%s,"s":[%s,%s,%s],"p":[%s,%s,%s],"rot":[%s,%s,%s],"c":[%d,%d,%d],"m":"%s","shape":"%s","alpha":%s,"text":%s,"face":"%s","light":%s}',
			kind, n(i * 70), n(0), n(b.s[1]), n(b.s[2]), n(b.s[3]), n(b.p[1]), n(b.p[2]), n(b.p[3]),
			n(b.rx), n(b.ry), n(b.rz), c[1], c[2], c[3], b.m, b.shape or "Block", n(b.alpha),
			if b.text then '"' .. string.gsub(b.text.value, "\n", "|") .. '"' else "null",
			if b.text then b.text.face else "",
			if b.light then n(b.light.range) else "0"))
	end
end
print("[" .. table.concat(out, ",\n") .. "]")
