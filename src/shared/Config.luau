-- Every number you are likely to want to tune lives here.
return {
	-- Level
	CELL_SIZE = 40, -- width of one room, in studs
	WALL_HEIGHT = 16,
	DOOR_WIDTH = 10,
	DOOR_HEIGHT = 11,
	MIDDLE_ROOMS = 7, -- shuffled rooms between the start and the lift
	FUSES_NEEDED = 3,

	-- Player speed and noise
	WALK_SPEED = 10,
	SPRINT_SPEED = 19,
	STAMINA_SECONDS = 5,
	STAMINA_RECOVERY_SECONDS = 9,
	WALK_NOISE_RADIUS = 14,
	SPRINT_NOISE_RADIUS = 70,
	FUSE_NOISE_RADIUS = 45,

	-- Monster
	MONSTER_GRACE_SECONDS = 8,
	PATROL_SPEED = 7,
	INVESTIGATE_SPEED = 12,
	CHASE_SPEED = 16,
	SIGHT_RANGE = 32,
	LOSE_TARGET_SECONDS = 3, -- keeps chasing this long after losing sight
	CATCH_DISTANCE = 5,
	STAGE_SPEED_BONUS = 0.06, -- gets faster with each fuse
	FINALE_SPEED = 15,
	FINALE_STAMINA_SECONDS = 10,
	FINALE_HEAD_START = 3,

	-- Doors players can slam to hold it back
	DOOR_HOLD_SECONDS = 5,
	DOOR_COOLDOWN_SECONDS = 9,

	-- Cues that give away the unseen presence
	CUE_RANGE = 60, -- lights and ambience start reacting at this distance
	FOOTPRINT_SPACING = 5,
	FOOTPRINT_LIFETIME = 9,
	FIGURE_REVEAL_RANGE = 24, -- the headless figure can be glimpsed in a chase within this distance

	FIRST_SCARE_SECONDS = 4,

	-- Staged scares
	SET_PIECE_RADIUS = 13, -- how far into a room you get before its big moment starts
	SET_PIECE_MIN_GAP = 20, -- seconds between big moments
	SET_PIECE_CLEAR = 30, -- the presence is moved away if it's closer than this when one starts
	BLACKOUT_DELAY = 1.2, -- after the first fuse is taken
	TRAP_SECONDS = 3, -- how long the doors stay shut in the desk scene
	RESTART_SECONDS = 6,
}
