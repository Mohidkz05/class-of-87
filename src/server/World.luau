-- Turns the room data in shared/Rooms.luau into Roblox parts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Rooms = require(ReplicatedStorage.Shared.Rooms)

local World = {}

local CELL = Config.CELL_SIZE

function World.center(room)
	return Vector3.new(room.x * CELL, 0, room.y * CELL)
end

function World.doorBetween(a, b)
	return (World.center(a) + World.center(b)) / 2
end

function World.roomIndexAt(rooms, position)
	local x, y = math.round(position.X / CELL), math.round(position.Z / CELL)
	for i, room in rooms do
		if room.x == x and room.y == y then
			return i
		end
	end
	return nil
end

local function color(name)
	local c = Rooms.COLORS[name]
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function addText(part, spec)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId[spec.face]
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 1
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.92, 0.88)
	label.Position = UDim2.fromScale(0.04, 0.06)
	label.Font = Enum.Font[spec.font]
	label.Text = spec.value
	label.TextScaled = true
	label.TextWrapped = true
	label.TextColor3 = Color3.fromRGB(spec.color[1], spec.color[2], spec.color[3])
	label.Parent = gui
end

local function makePart(b, origin, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(b.s[1], b.s[2], b.s[3])
	p.Color = color(b.c)
	p.Material = Enum.Material[b.m]
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = b.solid
	p.CanQuery = b.solid or b.wall == true
	p.CanTouch = false
	p.CastShadow = b.c ~= "Moon" and b.m ~= "Neon" and b.m ~= "Glass"
	if b.alpha then
		p.Transparency = b.alpha
	end
	if b.shape then
		p.Shape = Enum.PartType[b.shape]
	end
	p.CFrame = CFrame.new(origin + Vector3.new(b.p[1], b.p[2], b.p[3]))
		* CFrame.Angles(math.rad(b.rx or 0), math.rad(b.ry or 0), math.rad(b.rz or 0))
	if b.text then
		addText(p, b.text)
	end
	if b.light then
		local light = Instance.new("PointLight")
		light.Range = b.light.range
		light.Brightness = b.light.brightness
		light.Color = Color3.fromRGB(b.light.color[1], b.light.color[2], b.light.color[3])
		light.Parent = p
	end
	if b.tag then
		p:SetAttribute("Tag", b.tag)
		if b.tag == "Lamp" then
			p.Name = "Lamp"
		end
	end
	if b.hinge then
		p:SetAttribute("Hinge", b.hinge)
	end
	p.Parent = parent
	return p
end

-- Returns the map folder, fuses, gate panel, per-room scare anchors and door positions.
function World.build(rooms)
	local folder = Instance.new("Folder")
	folder.Name = "Mine"
	local fuses, panel = {}, nil
	local assets = {}

	for i, room in rooms do
		local m = Instance.new("Model")
		m.Name = string.format("Room%02d_%s", i, room.kind)
		local c = World.center(room)
		local doors = Rooms.doorsFor(rooms, i)
		local list = Rooms.build(room.kind, doors, room.x * 131 + room.y * 17 + i * 977 + 5003, i % 2 == 1 or room.kind == "Exit")
		local a = { LockerDoor = {}, Lamp = {}, Board = {}, Tile = {}, Desk = {}, Stall = {}, Mirror = {}, Glow = {} }
		assets[i] = a
		local groups = {}
		for _, b in list do
			local parent = m
			if b.group then
				if not groups[b.group] then
					local g = Instance.new("Model")
					g.Name = b.group
					g.Parent = m
					groups[b.group] = g
					table.insert(a.Desk, g)
				end
				parent = groups[b.group]
			end
			local part = makePart(b, c, parent)
			if b.tag == "Panel" then
				panel = part
			elseif b.tag and b.tag ~= "Desk" and a[b.tag] then
				table.insert(a[b.tag], part)
			end
			if b.light then
				table.insert(a.Glow, part)
			end
		end

		if room.hasFuse then
			-- A glowing fuse on a small stool, near the room's centre so it's hard to miss
			local signX = if i % 2 == 0 then 1 else -1
			local signZ = if i % 4 < 2 then 1 else -1
			local at = c + Vector3.new(signX * 6.6, 0, signZ * 6.6)
			local stool = Instance.new("Part")
			stool.Anchored = true
			stool.Size = Vector3.new(1.6, 2.6, 1.6)
			stool.Position = at + Vector3.new(0, 1.3, 0)
			stool.Color = color("WoodDark")
			stool.Material = Enum.Material.Wood
			stool.Parent = m
			local fuse = Instance.new("Part")
			fuse.Name = "Fuse"
			fuse.Anchored = true
			fuse.CanCollide = false
			fuse.Size = Vector3.new(0.9, 2, 0.9)
			fuse.Position = at + Vector3.new(0, 3.8, 0)
			fuse.Color = Color3.fromRGB(255, 150, 40)
			fuse.Material = Enum.Material.Neon
			local glow = Instance.new("PointLight")
			glow.Color = fuse.Color
			glow.Range = 14
			glow.Brightness = 1.2
			glow.Parent = fuse
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Take"
			prompt.ObjectText = "Fuse"
			prompt.HoldDuration = 0.5
			prompt.RequiresLineOfSight = false
			prompt.Parent = fuse
			fuse.Parent = m
			table.insert(fuses, fuse)
		end

		if room.kind == "Exit" and panel then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Open gate"
			prompt.ObjectText = "Gate"
			prompt.HoldDuration = 1
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false
			prompt.Parent = panel
		end
		m.Parent = folder
	end
	folder.Parent = workspace
	return folder, fuses, panel, assets
end

return World
