; Named RAM / IO addresses.
; Format: DEF name EQU $addr ;@ type description
;   type: u8 | u16 (little endian) | u8[N] | code[N] | const
; Lines without ";@" are plain constants.

DEF wBikeId EQU $C780 ;@ u8 The current bike: 1 = player one (the camera follows it), 2 = the other bike. The two bike records at $C780 and $C800 ($71 bytes each) are swapped to work on the other one
DEF wBikeSpeed EQU $C781 ;@ u8 The bike's speed along its direction of travel ($00-$90)
DEF wBikeY EQU $C785 ;@ u16 The bike's Y position in 8.8 fixed point (the high byte is the pixel row in the level)
DEF wBikeX EQU $C787 ;@ u8[3] The bike's X position, 24 bits: fraction, then the pixel column in the level (16 bits)
DEF wBikeAngle EQU $C78A ;@ u8 The bike's angle, $00-$1F (32 directions, 0 = level); $30-$32 are the frames of a crash
DEF wBikeMode EQU $C78B ;@ u8 What the bike is doing on the track (values 1-8; in modes 4 and 7 the throttle code does nothing)
DEF wNitro EQU $C792 ;@ u8 Nitro boosts left
DEF wBikeTopSpeed EQU $C795 ;@ u8 The highest throttle the bike reaches without nitro
DEF wBikeVelY EQU $C796 ;@ u16 The bike's Y speed this frame (8.8, signed)
DEF wBikeVelX EQU $C798 ;@ u16 The bike's X speed this frame (8.8, signed)
DEF wBikeMoveAngle EQU $C79B ;@ u8 The direction the bike travels in (an angle like wBikeAngle; its low 3 bits pick the octant)
DEF wBikeSpeedBonus EQU $C79C ;@ u8 A signed amount added to the speed for one frame (slopes)
DEF wNitroFlame EQU $C79D ;@ u8 Set to 8 when a nitro fires in the air
DEF wBikeHeld EQU $C79E ;@ u8 The buttons held for this bike (the player's or the computer's): bit 0 tilts back, bit 1 tilts forward, bit 4 is the throttle
DEF wBikePressed EQU $C79F ;@ u8 The buttons pressed this frame for this bike (bit 5 fires a nitro)
DEF wBikeDriveSpeed EQU $C7A0 ;@ u8 The speed the engine drives the bike at this frame (from wBikeThrottle through the speed curve)
DEF wBikeThrottle EQU $C7A3 ;@ u8 The throttle: rises by 2 a frame while held, up to wBikeTopSpeed; a nitro sets it to $90
DEF wNitroTimer EQU $C7A4 ;@ u8 Frames left of a nitro boost (the throttle is held at $90)
DEF wBikeCrash EQU $C7A9 ;@ u8 The crash state: 0 = riding, 1 = throttle forced on, 2-4 = crash phases (3 spins the bike round)
DEF wMathA EQU $C890 ;@ u8 Scratch for the sine/cosine multiply (a factor, or a saved byte)
DEF wMathB EQU $C891 ;@ u8 Scratch for the sine/cosine multiply: the second factor
DEF wMathCos EQU $C892 ;@ u8 Scratch: the cosine value looked up for the multiply (SineTable from the other end)
DEF wMathNegSin EQU $C893 ;@ u8 Nonzero: SineCosineProducts negates the sine product
DEF wMathNegCos EQU $C894 ;@ u8 Nonzero: SineCosineProducts negates the cosine product
DEF wMathSinProd EQU $C895 ;@ u16 Result of SineCosineProducts: wMathA x sine / 16
DEF wMathCosProd EQU $C897 ;@ u16 Result of SineCosineProducts: wMathA x cosine / 16
DEF wCamY EQU $C900 ;@ u16 The camera's Y position in 8.8 fixed point (the high byte is the pixel row of the screen's top)
DEF wCamX EQU $C902 ;@ u8[3] The camera's X position, 24 bits: fraction, then the pixel column of the screen's left edge (16 bits)
DEF wMapColumn EQU $C908 ;@ u8 The level map column (16-pixel metatile column) being drawn
DEF wColumnVRAM EQU $C909 ;@ u16 Where in BG map 0 that metatile column goes
DEF wColumnMap EQU $C90B ;@ u16 Where in the level map ($CE00) that column starts
DEF wScrollLeft EQU $C90F ;@ u8 1 while the camera moves left (draw the new column at the left edge), 0 while it moves right
DEF wSameTileColumn EQU $C91E ;@ u8 1 when the camera's last move stayed in the same 8-pixel tile column
DEF wShadowOAM EQU $CC00 ;@ u8[160] Shadow OAM, copied to OAM by the DMA routine every frame
DEF wColumnTiles EQU $CB80 ;@ u8[64] Two tile columns of 32 tiles, built from a column of 16 metatiles, ready to go to BG map 0
DEF wLevelMap EQU $CE00 ;@ u8[4096] The level, 16 rows of 256 metatiles (16 x 16 pixels each); a row is 256 bytes
DEF BTN_RIGHT EQU $01 ;@ const Joypad bit (wJoyHeld / wBikeHeld): Right
DEF BTN_LEFT EQU $02 ;@ const Left
DEF BTN_UP EQU $04 ;@ const Up
DEF BTN_DOWN EQU $08 ;@ const Down
DEF BTN_A EQU $10 ;@ const A
DEF BTN_B EQU $20 ;@ const B
DEF BTN_SELECT EQU $40 ;@ const Select
DEF BTN_START EQU $80 ;@ const Start
DEF wCourse EQU $C018 ;@ u8 The course being played, 1-based (picks its track pieces and its items)
DEF wPlayerMask EQU $C008 ;@ u8 Who plays: bit 0 player 1, bit 1 player 2, bit 2 over the link cable (1, 3 or 7)
DEF wLastMetatile EQU $C90E ;@ u8 The highest metatile number in use: $A7 for the ROM's, then the composite ones made while the track is built
DEF wCompMetatiles EQU $CCA0 ;@ u8[352] Composite metatiles ($A8 on, 4 tiles each), made when a track piece is drawn over another
DEF wTileGrid EQU $C7CD ;@ u8[36] The 6 x 6 tiles of the level around the bike (3 x 3 metatiles)
DEF wProbeTiles EQU $C7B7 ;@ u8[11] Tiles at the points around the bike that are tested for the track
DEF wProbeKinds EQU $C7C2 ;@ u8[11] What those tiles are (the tile kind table at $5CA0)
DEF wItems EQU $CA00 ;@ u8[256] The course's items, 8 bytes each: kind, who may still take it (bit 0 player 1, bit 1 player 2), y, x (16 bits), row, column
DEF wItemCount EQU $C917 ;@ u8 How many items wItems holds
DEF wTimeSeconds EQU $C881 ;@ u8 The time left: seconds (BCD)
DEF wTimeMinutes EQU $C882 ;@ u8 The time left: minutes (BCD)
DEF wPowerUpA EQU $C793 ;@ u8 Set by item 5 (the HUD shows it as four tiles from $45)
DEF wPowerUpB EQU $C794 ;@ u8 Set by item 6 (the HUD shows it as three tiles from $26)
DEF wPowerUpLevel EQU $C7AA ;@ u8 Raised by item 7, up to 3
DEF wItemPopup EQU $C7AB ;@ u8 Frames the picked-up item's picture stays above the bike
DEF wItemPopupY EQU $C91A ;@ u8 Where the picked-up item's picture is: y
DEF wItemPopupX EQU $C91B ;@ u8 Where the picked-up item's picture is: x
DEF wGameState EQU $C006 ;@ u8 The main state (title, menus, the race, ...): an index into the state jump table
DEF wGameSubstate EQU $C007 ;@ u8 The step inside the current main state
DEF wJoyHeld EQU $C00C ;@ u8 Buttons held (bit 0 Right, 1 Left, 2 Up, 3 Down, 4 A, 5 B, 6 Select, 7 Start)
DEF wJoyPressed EQU $C00D ;@ u8 Buttons pressed since the last read
DEF wSerialIn EQU $C022 ;@ u8 The last byte received over the link cable (stored by the serial interrupt)
DEF wLinkMaster EQU $C023 ;@ u8 1 = this Game Boy drives the link cable's clock
DEF wTimeLeft EQU $C880 ;@ u8[3] The race clock counting down, BCD: hundredths, seconds, minutes
DEF wOtherBike EQU $C800 ;@ u8[113] The other bike's record (swapped with the one at wBikeId to work on it)
DEF wStatusBar EQU $CBC0 ;@ u8[64] The status bar at the top of the screen, two rows of 32 tiles (copied to the window's map)
DEF wVBlankMode EQU $C001 ;@ u8 What the VBlank handler does this frame (VBlankJobs): 1 = a still screen, 2 = scroll and sprites, 3 = the race (sprites, the next column of the track), 4 = sprites with the DMA, 5 = the GAME OVER screen
DEF wFrameCounter EQU $C009 ;@ u8 Counts up once per frame in RunGameState
DEF wStateTimer EQU $C00A ;@ u8 A countdown for the steps of the game states (title timeout, screen waits)
DEF wSoundUpdating EQU $C00B ;@ u8 Bit 0 is set while the timer interrupt runs the sound engine (so it never runs twice at once)
DEF wTitleCursor EQU $C00E ;@ u8 The title menu choice: 0 = one player, 1 = against the computer, 2 = two players over the link cable
DEF wCourseDone EQU $C011 ;@ u8 Set when the bike crosses the finish line: the race state moves on to the course results
DEF wPause EQU $C012 ;@ u8 Bit 0 = paused (START during the race); bit 1 = pausing not allowed
DEF wNextVBlankMode EQU $C017 ;@ u8 The VBlank mode the main loop hands to wVBlankMode at the start of each frame
DEF wClockRunning EQU $C019 ;@ u8 Nonzero while the race clock has time left; 0 ends the race (GAME OVER)
DEF wVBlankDone EQU $C01A ;@ u8 Set by the VBlank handler: the main loop may start the next frame
DEF wRound EQU $C01B ;@ u8 How many times all eight courses have been cleared (0-2); the third time ends the game
DEF wSelectStep EQU $C01D ;@ u8 The course select screen's step (0 = choose the course, 1 = choose the second setting; one step over the link cable)
DEF wSoundBusy EQU $C01F ;@ u8 Bit 0 is set while a sound is being started (QueueSound); the timer interrupt skips the sound engine then
DEF wSerialPending EQU $C021 ;@ u8 Set when this frame's link-cable byte exchange is due (the main loop does it after the VBlank)
DEF wPartnerHeld EQU $C81E ;@ u8 The link partner's buttons held (received over the link cable)
DEF wPartnerPressed EQU $C81F ;@ u8 The link partner's buttons pressed since the last exchange
DEF wFramePending EQU $C922 ;@ u8 Set when the race logic finished a frame; cleared by the VBlank handler once it has drawn it (the main loop waits)
DEF wLogicRunning EQU $C90D ;@ u8 1 while the race logic runs: the VBlank handler then only updates the sprites
DEF wSfxSquare1 EQU $C080 ;@ u8[36] Sound channel 0, the square 1 effect channel (36 bytes, see wSoundChannel for the layout)
DEF wSfxSquare2 EQU $C180 ;@ u8[36] Sound channel 1, the square 2 effect channel
DEF wSfxNoise EQU $C280 ;@ u8[36] Sound channel 2, the noise effect channel (also plays the music's drums)
DEF wMusicSquare1 EQU $C380 ;@ u8[36] Sound channel 3, music on square 1 (silent while channel 0 plays)
DEF wMusicSquare2 EQU $C480 ;@ u8[36] Sound channel 4, music on square 2 (silent while channel 1 plays)
DEF wMusicWave EQU $C580 ;@ u8[36] Sound channel 5, music on the wave channel
DEF wMusicDrums EQU $C680 ;@ u8[36] Sound channel 6, the music's drum track: its notes start drum sounds on channel 2
DEF wSoundChannel EQU $C100 ;@ u8 The channel being updated (0-6); its record is at $C080 + $100 * channel: +0 sound id, +1 priority, +2 stream pointer, +4 frames left of the note, +5 flags, +6 repeat count, +7 pitch envelope, +8 transpose, +9 volume drop, +$A pitch offset, +$D note length unit, +$E octave, +$F period, +$11 volume / duty, +$13 envelope, +$14 gate, +$15 release frame, +$1C loop point, +$1E return address, +$20 pitch envelope pointer
DEF wSoundRegBase EQU $C101 ;@ u8 The channel's first sound register, as an offset from rNR10 (0 square 1, 5 square 2, 10 wave, 15 noise)
DEF wMusicTempo EQU $C102 ;@ u8 Added to wMusicTempoAcc every update; each carry skips one update of the music, so a higher value plays it slower
DEF wMusicTempoAcc EQU $C103 ;@ u8 The music tempo accumulator
DEF wMusicSkip EQU $C104 ;@ u8 1 = the music channels skip this update (wMusicTempoAcc carried)
DEF wSoundQueued EQU $C105 ;@ u8 A sound to start at the end of the update (the course music after the start signal; drum hits)
DEF wSoundPan EQU $C106 ;@ u8 rNR51's value: which channels sound left and right
DEF wSoundSweep EQU $C107 ;@ u8 The last sweep value a stream set (command $E9)
DEF wSoundId EQU $C108 ;@ u8 The sound StartSound is starting
DEF wSoundPriority EQU $C109 ;@ u8 Its priority: a channel only takes it if that is at least the priority of what plays there
DEF wSoundRegValue EQU $C10A ;@ u8 The value WriteSoundReg writes
DEF wSoundRegIndex EQU $C10B ;@ u8 The register WriteSoundReg writes, 0-4 within the channel's five
DEF wMusicHold EQU $C10C ;@ u8 Nonzero: the music channels stand still
DEF wEnginePitch EQU $C10D ;@ u8 The engine sound's pitch (sound 9): the bike's speed, raises the note by 8 x this period steps
DEF wSoundRegs EQU $C200 ;@ u8[20] A copy of what was written to rNR10-rNR23, restored after the pause
DEF wScreenTimer EQU $C01E ;@ u8 Frames left on the KONAMI screen (counts down from 0, so 256 frames)
DEF wCrashY EQU $C7AD ;@ u16 Where the bike crashed: its Y position (8.8); it is put back there when the crash is over
DEF wCrashX EQU $C7AF ;@ u16 Where the bike crashed: its X pixel column
DEF wCrashMarker EQU $C7B2 ;@ u8 1 while the crash spot is marked on screen (two sprites, DrawCrashMarker)
DEF wJumpKind EQU $C79A ;@ u8 How the bike took off (TakeOff): 0 slow, 2 fast, +1 with Up held, 4 after a crash; picks a row of JumpPhysics
DEF wBikeLives EQU $C7A1 ;@ u8 Falls into a pit left before the race ends ($FF = no limit); 0 ends the course
DEF wCrashTimer EQU $C7A2 ;@ u8 Counts down the frames of a crash (mode 8, from $39): CrashAnimation picks the phase from it
DEF wSlopeBonus EQU $C7A5 ;@ u8 Builds up by 2 a frame on a slope (signed): down to -$20 going up (angles 1-7), up to +$20 going down ($18-$1F)
DEF wLastMoveAngle EQU $C7A6 ;@ u8 The travel angle saved when the bike lands or loses the ground ($20 set: it was turned past upright)
DEF wLandDelay EQU $C7AC ;@ u8 Frames after a landing before the bike may stand on its back wheel again
DEF wCrashSide EQU $C7B1 ;@ u8 Which way the bike tumbles in a crash (0 or 1: different frames and direction)
DEF wTakeOffFrame EQU $C7B6 ;@ u8 1 in the frame the bike takes off (the jump code skips one step of gravity)
DEF wEraseItem EQU $CB30 ;@ u8 Bit 0 set: the VBlank handler blanks the 2 x 2 tiles of a collected item at wEraseItemAddr
DEF wEraseItemAddr EQU $CB31 ;@ u16 Where in BG map 0 the collected item's tiles are
DEF wStartCountdown EQU $C910 ;@ u8 Frames of the start sequence left ($30 at the start; the lights change at $22, $1A, $12 and GO at $0A); $FF once the starter has scrolled away
DEF wStarterY EQU $C911 ;@ u8 The starter's (the flag beside the start line) Y position in the level
DEF wStarterX EQU $C912 ;@ u8 The starter's X position in the level (low byte)
DEF wTrailY EQU $CB40 ;@ u8[16] The bike's last 16 pixel rows (oldest first), recorded while the camera moves; the afterimages are drawn from them
DEF wTrailX EQU $CB50 ;@ u8[32] The bike's last 16 pixel columns (16 bits each, oldest first)
DEF wTrailAngle EQU $CB70 ;@ u8[16] The bike's last 16 angles (oldest first)
DEF hOAMDMA EQU $FF90 ;@ code[10] The sprite DMA routine, copied here by CopyOAMDMARoutine (during a DMA the CPU can only run code from HRAM)
DEF wCamVelY EQU $C80D ;@ u16 How far the camera moves down this frame (8.8, signed; 0 while the bike is in the screen's upper part)
DEF wCamVelX EQU $C80F ;@ u16 How far the camera moves right this frame (8.8, signed): the bike's X speed
DEF wRaceTime EQU $C782 ;@ u8[3] The bike's race time, counting up, BCD: hundredths, seconds, minutes (the second bike's record has its own at $C802)
DEF wBestTimes EQU $C060 ;@ u8[24] The best time of each of the 8 courses, 3 BCD bytes each (hundredths, seconds, minutes)
DEF wLapTimeShow EQU $C920 ;@ u8 1 while the lap time is shown in sprites
DEF wLapTimeTimer EQU $C921 ;@ u8 Frames the lap time stays up ($40 when the bike passes the lap point)
DEF wLapTime EQU $C7B3 ;@ u8[3] The race time when the bike passed the lap point, BCD: hundredths, seconds, minutes
DEF wBoxAddr EQU $C924 ;@ u16 Where in BG map 0 the TIME UP box starts (its top left corner)
DEF wBoxRow EQU $C926 ;@ u8 The TIME UP box's drawing step: rows 1-3 are drawn by the VBlank handler, one per frame
DEF wLapsLeft EQU $C7A8 ;@ u8 Lap points still to pass (1 at the start: a race is two laps of the level map, 2 x 4096 pixels)
DEF wNewRecord EQU $C91C ;@ u8 The bike that set a new best time on the results screen (1 or 2), 0 = none
DEF wLinkResult EQU $C923 ;@ u8 The link race result for this Game Boy: 0 = lost, 1 = draw, 2 = won
DEF wComFarAhead EQU $C91D ;@ u8 1 while the computer bike is far ahead of the player (it then drives slower, without its power-up)
DEF wHurrySound EQU $C91F ;@ u8 Bit 0: the link game's hurry-up sound (18) has played this race
DEF wLapMarker EQU $C913 ;@ u8[4] Set by ResetCamera to $0D $F9 $B0 $0F (the lap line: map row 13, column $F9, x $0FB0) but never read; CheckCoursePoints uses the numbers themselves
DEF wBikeUnused0C EQU $C78C ;@ u8 Byte $0C of the bike record: cleared by ResetBike, never read
