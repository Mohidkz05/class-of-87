# Class of '87: Requirements

Last updated: 2026-11-21

Status key:
- **Built:** code exists, but nobody has played it in Studio yet
- **Tested:** covered by the automated logic tests in `tests/run.luau`
- **Planned:** not built

The automated tests cover level generation, room layout, story length, pacing rules and the
threat's decision rules. Nothing has run in Roblox yet, so all gameplay, lighting, sound, co-op and
the HUD still need a real playtest.

## Hard constraints
| ID | Requirement |
|---|---|
| C1 | No music anywhere in the game, its menus, or its promotion |
| C2 | Every sound effect must not resemble music: no melodies, jingles, chimes, tonal drones, instrument sounds or steady drum-like beats. Natural sounds such as wind, water, creaks and footsteps are fine. The owner has the final say on edge cases |
| C3 | No required spending: no paid art, audio, tools or ads unless the owner decides otherwise |
| C4 | Nothing that lets players add their own audio, such as boomboxes, because it would break C1 |
| C5 | No pay-to-win items |
| C6 | No random-reward purchases |
| C7 | No animate figures with a visible head or face. The threat is only glimpsed as a headless robed figure (close in a chase, and when catching you), and avatars have heads, faces and accessories hidden. Built, not playtested |
| C8 | The threat stays unnamed. Any change to its theme waits for the owner's decision |

## Gameplay
| ID | Requirement | Status |
|---|---|---|
| G1 | Each run has a foyer, 7 shuffled middle rooms and an exit room | Tested |
| G2 | Rooms come from 10 school types, with no repeat within a run | Tested |
| G3 | 3 fuses, spread across the level, never in the first or last rooms | Tested |
| G4 | Taking all fuses starts the finale and powers the gate; opening it wins | Built |
| G5 | The run restarts automatically after a win or when all players are dead | Built |
| G6 | Walking is quiet, and running is fast, loud and limited by stamina | Built |
| G7 | Flashlight can be toggled | Built |
| G8 | 1 to 4 players per server | Built; server size must be set when publishing |
| G9 | Runs last about 5 to 8 minutes | Unverified; check in playtest |
| G10 | Players can slam doors to hold the threat for 5 seconds, then wait 9 seconds to reuse them | Built |
| G11 | Props never block a doorway or route | Tested |

## Story and pacing
| ID | Requirement | Status |
|---|---|---|
| S1 | No story or sign line over 5 words | Tested |
| S2 | First scare within 4 seconds of the director starting; threat active at 8 seconds | Built |
| S3 | Gap between scares never over 15 seconds, and 3 to 5 seconds in the finale | Tested (timing rule); Built (events) |
| S4 | The same scare type doesn't fire twice in a row when another is available | Tested |
| S5 | Scare types: locker burst, lamp burst, chalk writing, falling tile, sliding desk, door slam, static, racing footprints | Built |
| S6 | Each fuse raises the threat's speed and the scare rate | Built |
| S7 | Third fuse starts a red-lit finale in which the threat hears all players, starting two rooms behind | Built |
| S8 | A "RUN!" cue appears when a chase starts nearby, at most every 8 seconds | Built |
| S9 | The intro states the story is fiction | Built |
| S10 | The first fuse triggers a blackout: lights and flashlight die, footsteps circle and close in, a slam lands behind the player, then lights return and show the prints | Tested (timing); Built (effects) |
| S11 | Locker hall, on entry: every door bursts open in a wave racing toward the player | Tested (timing); Built (effects) |
| S12 | Classroom and detention, on entry: doors slam for 3 seconds, desks snap round to face the player, the board writes "SIT DOWN" | Built |
| S13 | Washroom, on entry: taps run, stalls bang open toward the player, the mirror writes "LOOK BEHIND", then a slam behind them | Built |
| S14 | Every run contains at least one room scene | Tested |
| S15 | Staged scares play once, 20 seconds apart, not during a chase or the finale. The threat is paused and moved away if close, so nobody is caught during one | Built |
| S16 | Camera shake is skipped when the player's Roblox reduced-motion setting is on | Built; setting name unverified in Roblox |

## Unseen presence
| ID | Requirement | Status |
|---|---|---|
| M1 | Wakes 8 seconds after the run starts, or earlier if all fuses are taken | Built |
| M2 | Patrols, investigates noises, and chases players it sees | Tested (decision rules); Built (movement) |
| M3 | Can hear running from 70 studs, walking from 14, and fuse pickups from 45; standing still is silent | Tested (running and walking); Built (fuse) |
| M4 | Sight is limited to 32 studs and blocked by walls and props | Built |
| M5 | Its speed sits between walking and running, so running escapes it but makes noise | Built |
| M6 | Mostly unseen: the only visible form is the brief headless figure in C7, never a face | Built |
| M7 | Uneven heavy footsteps show where it is | Tested (uneven timing); Built (sound) |
| M8 | Dark footprints appear along its path and fade | Built |
| M9 | When it's near, flashlight and lamps flicker, ambience drops out, dust falls, the screen dims | Tested (intensity rule); Built (effects) |
| M10 | Being caught cuts to black with a sound | Built |
| M11 | Flicker stays under about 3 changes a second, to limit flash risk | Built; check in playtest |

## Controls and interface
| ID | Requirement | Status |
|---|---|---|
| U1 | Desktop: WASD, mouse, Shift to run, F for flashlight, E to interact | Built |
| U2 | Mobile: on-screen run and light buttons, at least 44×44 px | Built; size and placement unverified |
| U3 | HUD shows fuse count, stamina and short messages | Built |
| U4 | HUD text stays readable, with at least 4.5:1 contrast | Built; check in playtest |

## Audio
| ID | Requirement | Status |
|---|---|---|
| A1 | Ambience from wind, drips and rumbles, with no music | Built; owner must listen |
| A2 | Footsteps must not sound like a drum beat | Timing and pitch vary; **owner must listen** |
| A5 | No heartbeat sounds, because they form a steady beat | Ongoing rule |
| A3 | Pickups and menus use no chimes or jingles | Built; owner must listen |
| A6 | No school bell, because it may read as a chime or tone. Not researched | Ongoing rule |
| A4 | Any new sound is checked by ear before it's added | Ongoing rule |

## Art
| ID | Requirement | Status |
|---|---|---|
| R1 | 12 school room types, with signs, decay and scare objects | Built; checked in an offline preview, not in Roblox |
| R2 | Icon of 512×512 that still reads at small sizes | Done, `art/output/icon.png` |
| R3 | Thumbnail of 1920×1080 at 16:9 | Done, `art/output/thumbnail.png` |
| R4 | No people, animals, faces or figures in any art, apart from the headless threat (C7) | Partly tested (banned words in signs); check by eye |

## Monetization
| ID | Requirement | Status |
|---|---|---|
| E1 | Revive purchase | Planned, after milestone 6 |
| E2 | Cosmetic flashlight skins | Planned, after milestone 6 |
| E3 | The owner approves each monetization feature before it's built | Planned |

## Publishing
| ID | Requirement | Status |
|---|---|---|
| P1 | Complete Roblox's content questionnaires and pick a suitable maturity rating for horror (check current rules) | Planned |
| P2 | Set the server size to 4 and check that the game runs on phones | Planned |
| P3 | Promotional clips carry no music, including trending sounds | Planned |
