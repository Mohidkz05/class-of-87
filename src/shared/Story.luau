--!strict
-- All story text in one place. Rule: no line over 5 words. The tests enforce this.
-- The threat is deliberately never named.
return {
	INTRO = { "CLOSED SINCE 1987.", "31 STUDENTS NEVER LEFT.", "THE DOORS JUST LOCKED." },
	DISCLAIMER = "A work of fiction",
	GOAL = "FIND 3 FUSES. STAY QUIET.",
	AWAKE = "IT HEARD YOU.",
	FUSE = { "ONE FUSE.", "IT'S FOLLOWING YOU.", "POWER'S BACK. RUN!" },
	GATE = "GET TO THE GATE.",
	CAUGHT = "MARKED ABSENT.",
	ESCAPED = "YOU GOT OUT.",
	ESCAPED_HOOK = "31 STILL INSIDE.",
	CHASE = "RUN!",
	-- Caught in co-op: watching a teammate. The player's username follows WATCHING.
	WATCHING = "WATCHING",
	NEXT_HINT = "CLICK OR TAP: NEXT",
	-- Staged scares
	DESKS = "SIT DOWN",
	MIRROR = "LOOK BEHIND",
	-- Written on chalkboards during a run
	CHALK = { "I HEAR YOU", "DON'T RUN", "BEHIND YOU", "STAY QUIET", "YOU'RE LATE", "SIT DOWN", "NO ONE LEAVES", "ROLL CALL" },
}
