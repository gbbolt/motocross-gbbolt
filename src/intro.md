# From power-on to the finish line

What the code does between switching the Game Boy on and the bike crossing the finish
line of course 1, in the order it happens.

## Power on

The CPU starts at `Boot`, which jumps to `Start`: it waits for VBlank, clears all of work
RAM, copies the sprite DMA routine into HRAM (`CopyOAMDMARoutine`), since the CPU can only
run code from HRAM while a DMA is going on, silences the sound engine (`InitSound`) and
sets the I/O registers from a table (`InitIORegisters`).

The low ROM is a toolbox. The eight `rst` vectors are tiny helpers called with a single
byte: `GetWordA` reads entry A of a word table, `AddAToHL` adds A to HL, and so on.
`JumpTable` is the dispatcher everything else is built on: call it with the table of
addresses right behind the `call`, and it jumps to entry A.

## One state per frame

`MainLoop` runs the current game state (`RunGameState`, through `GameStateTable`), then
halts until the `VBlankHandler` says the frame is done. Each state has its own table of
steps (`wGameState`, then a substate), so a screen is a little sequence: draw, wait, go on.

Two interrupts do the work behind the loop:

- **VBlank** copies the sprites, sets the scroll registers and, during a race, draws one
  new column of the track (`VBlankJobs`).
- **The timer** runs the sound engine 64 times a second (`TimerHandler`, `UpdateSound`),
  so the music keeps its tempo whatever the game is doing.

## Palcom, title, course

`StatePalcomLogo` shows the Palcom screen, then `StateTitle` draws the logo. Screens
are stored packed with run lengths (`DrawPackedTiles`) and texts as strings placed at BG
map addresses (`DrawStrings`). `TitleMenuInput` picks SOLO, VS COMPUTER or VS 2-PLAYER.

`StateCourseSelect` lets you choose one of 8 courses (`ChooseCourse`) and a level, A, B
or C (`ChooseLevel`). The level picks the time limits (`TimeLimitsA` and the next two
tables) and how far ahead the computer's bike may get before it eases off (`ComDrive`);
the tracks are the same. `StateCourseIntro` shows the course record and
the qualifying time, then the race starts.

## Building the track

`StartRace` fills `wLevelMap` with empty sky: 16 rows of 256 metatiles, each 16 x 16
pixels, so a course is 4096 pixels long. Then `PlaceTrackPieces` reads the course's list
of track pieces (ramps, loops, bumps, straights) and stamps each one into the map at its
row and column.

Where two pieces overlap, `StampMetatile` lays the new piece's tiles over the old ones,
looks for an existing metatile with that exact mix and, if there isn't one, invents a new
one in RAM (`wCompMetatiles`). That's how a loop can sit on top of a ramp without anyone
drawing that combination by hand.

The items go in the same way: `BuildItemList` turns the course's item list into `wItems`,
and the item boxes are drawn as metatiles too. See every course in
[the course maps](course-1) and every piece in [the track pieces](track-pieces).

## One frame of the race

`RaceFrame` runs every frame of the race:

- The camera follows the bike (`MoveCamera`), and `BuildMapColumn` prepares the next
  column of metatiles for VBlank to draw.
- `UpdateBike` moves the bike: the throttle and nitro (`UpdateThrottle`), then the
  bike's mode (`UpdateBikeMode`): riding, in the air, on the back wheel, falling, crashed.
- `ReadTilesAroundBike` copies the 3 x 3 metatiles round the bike into a small grid, and
  `ProbeTrackTiles` samples it at points that turn with the bike's angle. `TileKinds` says
  what each tile is to a wheel: ground, and at what angle.
- `CheckBikeGround` decides what that ground means for the current mode: keep riding,
  take off, land, or crash if the angle is wrong.
- `SwapBikes` swaps the two bike records, and the same `UpdateBike` runs again for the
  second bike, steered by `ComDrive` against the computer.

`CollectItems` checks the items near the bike, and `ItemEffects` applies them: more top
speed, more time, more nitros. Two kinds are invisible and only count if you ride through
them upside down.

## Two laps and the finish

A race is two laps of the same 4096-pixel map: the bike's position runs to 8192 and the
map wraps round. `CheckCoursePoints` watches for the lap line, where the items come back
(`RestoreItems`) and the lap time shows, and for the finish.

Meanwhile `CountDownTime` runs the clock down. Cross the line in time and
`StateCourseClear` shows the results (`DrawResults`, `CheckRecord`) and moves on to
course 2; run out of time and it's TIME UP, then `StateGameOver`.
