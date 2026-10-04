; Disassembly of "motocross.gb"
; This file was created with:
; mgbdis v3.0 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $000", ROM0[$0]

;@ def GetWordA(n: a, table: de) -> (de, hl)
;@ path: lib/math
;@ `rst $00`: reads word number n of the table at de into de (hl ends on its
;@ high byte).
;@ test: table = rand(0x0000, 0x7C00)
;@ sig: 821f3467
GetWordA::
;> return GetWordHL(n, table)   # falls through
	ld l, a
	ld h, $00
	jr GetWordHL

	db $ff, $ff, $ff

;@ def GetWordHL(i: hl, table: de) -> (de, hl)
;@ path: lib/math
;@ `rst $08`: reads word number i of the table at de into de (hl ends on its
;@ high byte).
;@ test: i = rand(0, 0x100); table = rand(0x0000, 0x7C00)
;@ sig: 0f86ac14
GetWordHL::
;> p = u16(2 * i + table)
	add hl, hl
	add hl, de
;> return mem16[p], u16(p + 1)
	ld e, [hl]
	inc hl
	ld d, [hl]
	ret


	db $ff, $ff

;@ def GetWordAtHL(n: a, table: hl) -> (de, hl)
;@ path: lib/math
;@ `rst $10`: reads word number n (0-127) of the table at hl into de (hl ends on
;@ its high byte).
;@ test: table = rand(0x0000, 0x7C00)
;@ sig: b7ef5649
GetWordAtHL::
;> p = u16(table + u8(2 * n))
	add a
	rst $28
;> return mem16[p], u16(p + 1)
	ld e, [hl]
	inc hl
	ld d, [hl]
	ret


	db $ff, $ff

;@ def CompareHLBC(x: hl, y: bc) -> (zero, carry)
;@ path: lib/math
;@ `rst $18`: compares hl with bc: zero when equal, carry when hl < bc.
;@ test: x = rand(0, 0xFFFF); y = rng.choice([x, (x & 0xFF00) | rand(0, 255), rand(0, 0xFFFF)])
;@ sig: ddcfde9b
CompareHLBC::
;> if hi(x) != hi(y): return False, hi(x) < hi(y)
	ld a, h
	cp b
	ret nz

;> return lo(x) == lo(y), lo(x) < lo(y)
	ld a, l
	cp c
	ret


	db $ff, $ff

;@ def CompareHLDE(x: hl, y: de) -> (zero, carry)
;@ path: lib/math
;@ `rst $20`: compares hl with de: zero when equal, carry when hl < de.
;@ test: x = rand(0, 0xFFFF); y = rng.choice([x, (x & 0xFF00) | rand(0, 255), rand(0, 0xFFFF)])
;@ sig: e0590739
CompareHLDE::
;> if hi(x) != hi(y): return False, hi(x) < hi(y)
	ld a, h
	cp d
	ret nz

;> return lo(x) == lo(y), lo(x) < lo(y)
	ld a, l
	cp e
	ret


	db $ff, $ff

;@ def AddAToHL(n: a, p: hl) -> hl
;@ path: lib/math
;@ `rst $28`: adds a to hl.
;@ sig: 2e837aae
AddAToHL::
;> return u16(p + n)
	add l
	ld l, a
	ret nc

	inc h
	ret


	db $ff, $ff, $ff

;@ def AddAToDE(n: a, p: de) -> de
;@ path: lib/math
;@ `rst $30`: adds a to de.
;@ sig: e1ae6efd
AddAToDE::
;> return u16(p + n)
	add e
	ld e, a
	ret nc

	inc d
	ret


	db $ff, $ff, $ff

;@ def RstNegateHL(x: hl) -> hl
;@ path: lib/math
;@ `rst $38`: hl = -hl (NegateHL).
;@ sig: bdffb63d
RstNegateHL::
;> return NegateHL(x)
	jp NegateHL


	db $ff, $ff, $ff, $ff, $ff

;@ def VBlankInterrupt()
;@ path: system/vectors
;@ Interrupt vector $40.
;@ test: skip interrupt vector
;@ sig: a8153f83
VBlankInterrupt::
;> goto(VBlankHandler)
	jp VBlankHandler


	db $ff, $ff, $ff, $ff, $ff

;@ def LCDCInterrupt()
;@ path: system/vectors
;@ Interrupt vector $48. Never enabled: a bare `reti`.
;@ test: skip interrupt vector
;@ sig: 1e5db4cd
LCDCInterrupt::
;> return   # reti
	reti


	db $ff, $ff, $ff, $ff, $ff, $ff, $ff

;@ def TimerOverflowInterrupt()
;@ path: system/vectors
;@ Interrupt vector $50: the timer runs the sound engine.
;@ test: skip interrupt vector
;@ sig: 6fb555f7
TimerOverflowInterrupt::
;> goto(TimerHandler)
	jp TimerHandler


	db $ff, $ff, $ff, $ff, $ff

;@ def SerialTransferCompleteInterrupt()
;@ path: system/vectors
;@ Interrupt vector $58: a byte has gone over the link cable.
;@ test: skip interrupt vector
;@ sig: cf4e750b
SerialTransferCompleteInterrupt::
;> goto(SerialHandler)
	jp SerialHandler


	db $ff, $ff, $ff, $ff, $ff, $d9

;@ def VBlankHandler()
;@ path: system/interrupts
;@ The VBlank interrupt: saves the registers and does this frame's screen work
;@ (VBlankJobs).
;@ test: skip runs the sprite DMA routine in HRAM
;@ sig: 4f2422eb
VBlankHandler::
;> VBlankJobs()
	push af
	push bc
	push de
	push hl
	call VBlankJobs
	pop hl
	pop de
	pop bc
	pop af
;> return   # reti
	reti


;@ def TimerHandler()
;@ path: system/interrupts
;@ The timer interrupt (TAC = 7: 16384 Hz / 256, about 64 times a second) runs
;@ the sound engine, unless a sound is being started right now or the engine
;@ is still busy from the last tick. Interrupts stay on, so VBlank can cut in.
;@ sig: 0df69749
TimerHandler::
;> enable_interrupts()
	ei
	push hl
	push de
	push bc
	push af
;> if not wSoundBusy & 0x01 and not wSoundUpdating & 0x01:
	ld hl, wSoundBusy
	bit 0, [hl]
	jr nz, jr_000_008a

	ld hl, wSoundUpdating
	bit 0, [hl]
	jr nz, jr_000_008a

;>     wSoundUpdating |= 0x01
;>     UpdateSound()
	set 0, [hl]
	call UpdateSound
;>     wSoundUpdating &= 0xFE
	ld hl, wSoundUpdating
	res 0, [hl]

jr_000_008a:
;> return   # reti
	pop af
	pop bc
	pop de
	pop hl
	reti


;@ def SerialHandler()
;@ path: system/interrupts
;@ The serial interrupt: keeps the byte that came in over the link cable and
;@ stops the transfer.
;@ writes: wSerialIn
;@ sig: c6474a32
SerialHandler::
;> wSerialIn = rSB
	push af
	ldh a, [rSB]
	ld [wSerialIn], a
;> rSC = 0
	xor a
	ldh [rSC], a
	pop af
;> return   # reti
	reti


	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff

;@ def Boot()
;@ path: system/boot
;@ The entry point at $0100.
;@ test: skip never returns
;@ sig: 7f119ac7
Boot::
;> return Start()
	nop
	jp Start


HeaderLogo::
	db $ce, $ed, $66, $66, $cc, $0d, $00, $0b, $03, $73, $00, $83, $00, $0c, $00, $0d
	db $00, $08, $11, $1f, $88, $89, $00, $0e, $dc, $cc, $6e, $e6, $dd, $dd, $d9, $99
	db $bb, $bb, $67, $63, $6e, $0e, $ec, $cc, $dd, $dc, $99, $9f, $bb, $b9, $33, $3e

HeaderTitle::
	db "MOTOCROSSMANIACS"

HeaderNewLicenseeCode::
	db $00, $00

HeaderSGBFlag::
	db $00

HeaderCartridgeType::
	db $00

HeaderROMSize::
	db $00

HeaderRAMSize::
	db $00

HeaderDestinationCode::
	db $01

HeaderOldLicenseeCode::
	db $ca

HeaderMaskROMVersion::
	db $00

HeaderComplementCheck::
	db $57

HeaderGlobalChecksum::
	db $54, $63

;@ def Start()
;@ path: system/boot
;@ Power-on: waits for line $94, clears all of work RAM ($C000-$DDFE), copies the
;@ DMA routine to HRAM, starts the sound engine, sets the I/O registers (timer,
;@ LCD, interrupts), clears the screen, sets the palettes, switches the LCD on
;@ and puts the default best times in place, then runs the main loop.
;@ writes: wNextVBlankMode
;@ test: skip never returns
;@ sig: 10b95576
Start::
;> disable_interrupts()
	di
;> WaitForLine94()
	call WaitForLine94
;> reset_stack(0xE000)
	ld sp, $e000
;> fill(0xC000, 0, 0x1DFF)                     # all of work RAM up to $DDFE
	ld hl, $c000
	ld de, wVBlankMode
	ld bc, $1dfe
	ld [hl], $00
	call CopyBytes
;> CopyOAMDMARoutine()
	call CopyOAMDMARoutine
;> InitSound()
	call InitSound
;> InitIORegisters()
	call InitIORegisters
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> InitPalettes()
	call InitPalettes
;> wNextVBlankMode = 1
	ld a, $01
	ld [wNextVBlankMode], a
;> EnableLCD()
	call EnableLCD
;> InitBestTimes()                                # the default best times
	call InitBestTimes
;> enable_interrupts()
	ei
;> return MainLoop()   # falls through

;@ def MainLoop()
;@ path: system/boot
;@ One frame: hands the next VBlank mode over, reads the joypad and runs the game
;@ state (during the race only once the VBlank handler has drawn the last
;@ frame), switches the LCD on, sleeps until the VBlank handler is done, and in
;@ a link game swaps a byte with the other Game Boy.
;@ writes: wVBlankDone, wVBlankMode
;@ reads: wFramePending, wGameState, wLinkMaster, wNextVBlankMode, wPlayerMask, wVBlankDone
;@ test: skip never returns
;@ sig: 6c2c74c9
MainLoop::
;> for _ in forever():
;>     wVBlankDone = 0
	xor a
	ld [wVBlankDone], a
;>     wVBlankMode = wNextVBlankMode
	ld a, [wNextVBlankMode]
	ld [wVBlankMode], a
;>     if wGameState != 5 or not wFramePending:   # the race waits for the VBlank handler
	ld a, [wGameState]
	cp $05
	jr nz, jr_000_0197

	ld a, [wFramePending]
	and a
	jr nz, jr_000_019d

jr_000_0197:
;>         ReadJoypad()
	call ReadJoypad
;>         RunGameState()
	call RunGameState

jr_000_019d:
;>     rLCDC |= 0x80
	ld hl, $ff40
	bit 7, [hl]
	jr nz, jr_000_01a6

	set 7, [hl]

jr_000_01a6:
;>     wait_vblank_flag()                          # until the VBlank handler sets wVBlankDone
	ld a, [wVBlankDone]
	and a
	jr nz, jr_000_01af

	halt
	jr jr_000_01a6

jr_000_01af:
;>     if wSerialPending:
	ld hl, wSerialPending
	ld a, [hl]
	and a
	jr z, MainLoop

;>         wSerialPending = 0
	ld [hl], $00
;>         if wPlayerMask & 0x04:                  # a link game
	ld a, [wPlayerMask]
	and $04
	jr z, MainLoop

;>             if wLinkMaster:
	ld a, [wLinkMaster]
	and a
	jr z, jr_000_01d1

;>                 rIE &= 0xFB                     # the timer interrupt off
	ld hl, $ffff
	res 2, [hl]
;>                 LinkSendSync(1)
	ld b, $01
	call LinkSendSync
	jr MainLoop

jr_000_01d1:
;>             else:
;>                 wait_serial()
	ldh a, [rSC]
	add a
	jr c, jr_000_01d1

;>                 rIE &= 0xFB
	ld hl, $ffff
	res 2, [hl]
	jr MainLoop

;@ def SerialSendJoypad()
;@ path: link/serial
;@ In a link game: waits for the last transfer, then sends this Game Boy's held
;@ buttons (with wLinkMaster = 0 this side drives the clock).
;@ reads: wJoyHeld, wLinkMaster, wPlayerMask
;@ sig: 1e90a813
SerialSendJoypad::
;> if not wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret z

;> wait_serial()
	ld hl, $ff02

jr_000_01e6:
	bit 7, [hl]
	jr nz, jr_000_01e6

;> if not wLinkMaster: rSC |= 0x01             # internal clock
	ld a, [wLinkMaster]
	and a
	jr nz, jr_000_01f2

	set 0, [hl]

jr_000_01f2:
;> rSB = wJoyHeld
	ld a, [wJoyHeld]
	ldh [rSB], a
;> rSC |= 0x80                                 # start the transfer
	set 7, [hl]
	ret


;@ def SerialReceiveJoypad()
;@ path: link/serial
;@ In a link game: waits for the transfer to finish and takes the partner's held
;@ buttons from it, working out which of them are newly pressed.
;@ reads: wPlayerMask, wSerialIn
;@ sig: 681f1a19
SerialReceiveJoypad::
;> if not wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret z

;> wait_serial()
	ld hl, $ff02

jr_000_0203:
	bit 7, [hl]
	jr nz, jr_000_0203

;> held = wSerialIn
	ld a, [wSerialIn]
	ld c, a
;> old = wPartnerHeld
	ld hl, wPartnerHeld
	ld a, [hl]
;> wPartnerHeld = held
	ld [hl], c
;> wPartnerPressed = (old ^ held) & held
	xor c
	and c
	inc hl
	ld [hl], a
	ret


;@ def SubHLBC(x: hl, y: bc) -> (hl, zero, carry)
;@ path: lib/math
;@ hl = hl - bc, with the flags of comparing them first (zero when they were
;@ equal, carry when hl was the smaller).
;@ sig: f0e8cde9
SubHLBC::
;> zero, carry = CompareHLBC(x, y)
	rst $18
	push af
;> return u16(x - y), zero, carry
	ld a, l
	sub c
	ld l, a
	ld a, h
	sbc b
	ld h, a
	pop af
	ret


;@ def SubHLDE(x: hl, y: de) -> (hl, zero, carry)
;@ path: lib/math
;@ hl = hl - de, with the flags of comparing them first (zero when they were
;@ equal, carry when hl was the smaller).
;@ sig: b65ad687
SubHLDE::
;> zero, carry = CompareHLDE(x, y)
	rst $20
	push af
;> return u16(x - y), zero, carry
	ld a, l
	sub e
	ld l, a
	ld a, h
	sbc d
	ld h, a
	pop af
	ret


;@ def JumpTable(n: a)
;@ path: lib/control
;@ Jumps to entry n of the table of addresses that follows the `call JumpTable`
;@ (it takes the table's address off the stack as the return address).
;@ test: skip jumps through the caller's table
;@ sig: 29ecd3cf
JumpTable::
;> table = pop_return_address()
	pop hl
;> goto(mem16[u16(table + u8(2 * n))])
	add a
	rst $28
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl


;@ def NegateDE(x: de) -> de
;@ path: lib/math
;@ de = -de.
;@ sig: aa9aa9a1
NegateDE::
;> return u16(-x)
	call SwapDEHL
	call NegateHL
	jp SwapDEHL


;@ def NegateBC(x: bc) -> bc
;@ path: lib/math
;@ bc = -bc.
;@ sig: a3d54d52
NegateBC::
;> return u16(-x)
	push af
	xor a
	sub c
	ld c, a
	ld a, $00
	sbc b
	ld b, a
	pop af
	ret


;@ def NegateHL(x: hl) -> hl
;@ path: lib/math
;@ hl = -hl.
;@ sig: 5f0dab83
NegateHL::
;> return u16(-x)
	push af
	xor a
	sub l
	ld l, a
	ld a, $00
	sbc h
	ld h, a
	pop af
	ret


;@ def SwapDEHL(x: de, y: hl) -> (de, hl)
;@ path: lib/math
;@ Exchanges de and hl.
;@ sig: 7038ee9e
SwapDEHL::
;> return y, x
	push de
	ld e, l
	ld d, h
	pop hl
	ret


;@ def VBlankJobs()
;@ path: system/interrupts
;@ The VBlank handler's work, by wVBlankMode: 1 = no scrolling, the sprite DMA;
;@ 2 = the camera's scroll, the DMA, then the race's work; 3 = the race: the next
;@ column of the track into BG map 0 (unless the logic is still running or the
;@ camera stayed in the same tile column) and the status bar; 4 = the DMA and
;@ the status bar; 5 = the GAME OVER screen. Then it tells the main loop.
;@ writes: wFramePending, wVBlankDone
;@ reads: wCamX, wCamY, wEraseItem, wLogicRunning, wSameTileColumn, wVBlankMode
;@ test: skip runs the sprite DMA routine in HRAM
;@ sig: 14cba9c0
VBlankJobs::
;> mode = wVBlankMode
	ld a, [wVBlankMode]
;> if mode == 1:
;>@m1a     rSCY = rSCX = 0
;>@m1b     hOAMDMA()
	dec a
	jr z, jr_000_0265

;> elif mode == 2 or mode == 3:
;>     if mode == 2:
;>@m2a         rSCY = hi(wCamY)
;>@m2b         rSCX = wCamX[1]
;>@m2c         hOAMDMA()
;>@m2d         if wEraseItem: EraseItemTile()
;>@m3a     if not wLogicRunning:
;>@m3b         same = wSameTileColumn
;>@m3c         if not same: CopyTileColumn()
;>@m3d         wFramePending = 0
;>@m3e     if wLogicRunning or same: CopyStatusBar()
	dec a
	jr z, jr_000_026f

	dec a
	jr z, jr_000_0283

;> elif mode == 4:
;>@m4a     hOAMDMA()
;>@m4b     CopyStatusBar()
	dec a
	jr z, jr_000_02a1

;> elif mode == 5:
;>@m5     DrawTimeUpBoxRow()
	dec a
	jr z, jr_000_02ad

;> else: return
	ret


jr_000_0265:
;=@m1a
	xor a
	ldh [rSCY], a
	ldh [rSCX], a
;=@m1b
	call hOAMDMA
	jr jr_000_02a7

jr_000_026f:
;=@m2a
	ld a, [wCamY + 1]
	ldh [rSCY], a
;=@m2b
	ld a, [wCamX + 1]
	ldh [rSCX], a
;=@m2c
	call hOAMDMA
;=@m2d
	ld a, [wEraseItem]
	and a
	call nz, EraseItemTile

jr_000_0283:
;=@m3a
	ld a, [wLogicRunning]
	and a
	jr nz, jr_000_029c

;=@m3b
	ld a, [wSameTileColumn]
	and a
	jr nz, jr_000_0298

;=@m3c
	call CopyTileColumn
;=@m3d
	xor a
	ld [wFramePending], a
	jr jr_000_02a7

jr_000_0298:
;=@m3d
	xor a
	ld [wFramePending], a

jr_000_029c:
;=@m3e
	call CopyStatusBar
	jr jr_000_02a7

jr_000_02a1:
;=@m4a
	call hOAMDMA
;=@m4b
	call CopyStatusBar

jr_000_02a7:
;> wVBlankDone = 1
	ld a, $01
	ld [wVBlankDone], a
	ret


jr_000_02ad:
;=@m5
	call DrawTimeUpBoxRow
	jr jr_000_02a7

;@ def ChannelPage() -> h
;@ path: sound/engine
;@ The high byte of the current sound channel's RAM page: $C0 | wSoundChannel.
;@ reads: wSoundChannel
;@ sig: 73b123cd
ChannelPage::
;> return 0xC0 | wSoundChannel
	ld a, [wSoundChannel]
	or $c0
	ld h, a
	ret


;@ def CopyBytes(src: hl, dest: de, count: bc) -> (hl, de)
;@ path: lib/memory
;@ Copies `count` bytes from src to dest, front to back (0 = 64 KiB).
;@ test: count = rand(1, 0x100)
;@ test: src = rand(0x0000, 0xDE00)
;@ test: dest = rand_ram(count)
;@ sig: 994589e5
CopyBytes::
;> for i in range(count or 0x10000):
;>     mem[u16(dest + i)] = mem[u16(src + i)]
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, CopyBytes

;> return u16(src + (count or 0x10000)), u16(dest + (count or 0x10000))
	ret


;@ def SwapHLBC(x: hl, y: bc) -> (hl, bc)
;@ path: lib/math
;@ Exchanges hl and bc.
;@ sig: 70d36cd5
SwapHLBC::
;> return y, x
	push af
	ld a, l
	ld l, c
	ld c, a
	ld a, h
	ld h, b
	ld b, a
	pop af
	ret


;@ def GetPointer(n: a, table: hl) -> hl
;@ path: lib/math
;@ Reads word number n (0-127) of the table at hl into hl.
;@ test: table = rand(0x0000, 0x7C00)
;@ sig: 9bfb2079
GetPointer::
;> return mem16[u16(table + u8(2 * n))]
	add a
	rst $28
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret


;@ def InitIORegisters()
;@ path: system/boot
;@ Writes the table of (I/O register, value) pairs after it: the timer
;@ (TMA = 0, TAC = 7: on, 16384 Hz), LCDC = $C3, STAT = $10, LY, the palettes
;@ black, and last IE = $0D (VBlank, timer and serial) at $FFFF, where the
;@ register number wraps to 0 and ends the loop.
;@ sig: 3cc5b6e3
InitIORegisters::
;> p = IORegisterInit
	ld hl, IORegisterInit

jr_000_02d4:
;> while True:
;>     reg = mem[p]
;>     mem[0xFF00 + reg] = mem[u16(p + 1)]
;>     p = u16(p + 2)
;>     if reg == 0xFF: return
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ldh [c], a
	inc c
	jr nz, jr_000_02d4

	ret


;@ Pairs of (I/O register, value) for InitIORegisters: TMA, TAC, LCDC, STAT, LY, the three palettes, and IE ($FF) last.
IORegisterInit::
	db $06, $00, $07, $07, $40, $c3, $41, $10, $44, $00, $47, $00, $48, $00, $49, $00
	db $ff, $0d

;@ def InitPalettes()
;@ path: system/lcd
;@ The normal palettes: BG and sprite palette 0 = $E4, sprite palette 1 = $A8.
;@ sig: ad310ca1
InitPalettes::
;> rBGP = 0xE4
	ld c, $47
	ld a, $e4
	ldh [c], a
;> rOBP0 = 0xE4
	inc c
	ldh [c], a
;> rOBP1 = 0xA8
	inc c
	ld a, $a8
	ldh [c], a
	ret


;@ def ReadJoypad()
;@ path: system/input
;@ Reads all eight buttons into wJoyHeld (d-pad in the low nibble: Right, Left,
;@ Up, Down; then A, B, Select, Start) and which of them are newly pressed into
;@ wJoyPressed.
;@ writes: wJoyHeld, wJoyPressed
;@ reads: wJoyHeld
;@ sig: 3fc4524d
ReadJoypad::
;> rP1 = 0x20                                  # select the d-pad
	ld a, $20
	ldh [rP1], a
;> pins = rP1                                  # read twice to let the lines settle
	ldh a, [rP1]
	ldh a, [rP1]
;> dpad = ~pins & 0x0F
	cpl
	and $0f
	ld b, a
;> rP1 = 0x10                                  # select A, B, Select, Start
	ld a, $10
	ldh [rP1], a
;> pins = rP1                                  # read 6 times
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
;> held = swap(~pins & 0x0F) | dpad
	cpl
	and $0f
	swap a
	or b
	ld c, a
;> wJoyPressed = (wJoyHeld ^ held) & held
	ld a, [wJoyHeld]
	xor c
	and c
	ld [wJoyPressed], a
;> wJoyHeld = held
	ld a, c
	ld [wJoyHeld], a
;> rP1 = 0x30                                  # deselect both groups
	ld a, $30
	ldh [rP1], a
	ret


;@ def TitleMenuInput()
;@ path: title
;@ Runs after the state handler on the Palcom and title screens. A START from
;@ the link partner's title screen ($0E over the cable) starts a two-player game
;@ here as well. On the title screen Up / Down / Select move the cursor (SOLO,
;@ VS COMPUTER, VS 2-PLAYER) and START goes on to the course select; on the
;@ Palcom screen any of them skips to the title. Choosing two players sends $0E
;@ to the other Game Boy: if it doesn't answer with $0E, the game falls back to
;@ the Palcom screen.
;@ writes: wLinkMaster, wPlayerMask, wStateTimer, wTitleCursor
;@ reads: wGameState, wJoyPressed, wSerialIn, wTitleCursor
;@ test: wTitleCursor = rand(0, 2); wGameState = rand(0, 2)
;@ test: wSerialIn = rng.choice([0x0E, rand(0, 255), rand(0, 255)])
;@ sig: 20da498b
TitleMenuInput::
;> if wSerialIn == 0x0E:                          # the partner pressed START on its title screen
;>@p1     wTitleCursor = 2
;>@p2     wGameState = 3
;>@p3     wGameSubstate = 0
;>@p4     wLinkMaster = 0
;>@p5     wPlayerMask = 7                          # two players over the link cable
;>@p6     return HideWindow()
	ld a, [wSerialIn]
	cp $0e
	jp z, Jump_000_03d2

;> if wJoyPressed & 0x80:                         # START
;>@s1     PlaySound(0x17)
;>@s2     state = 3                                # title: on to the course select
;>@s3     if wGameState != 1: state = 1            # Palcom screen: to the title
	ld a, [wJoyPressed]
	add a
	jp c, Jump_000_0376

;> else:
;>     b = wJoyPressed & 0x4C                      # Up, Down, Select
;>     if not b: return
	ld a, [wJoyPressed]
	and $4c
	ret z

;>     if wGameState != 1:                         # the Palcom screen: to the title
;>         state = 1
	ld b, a
	ld a, [wGameState]
	dec a
	jp nz, Jump_000_0384

;>     else:
;>         if b & 0x48:                            # Down or Select: the next choice
	ld hl, wTitleCursor
	ld c, $03
	ld a, b
	and $48
	jp z, Jump_000_03ea

;>             cursor = u8(wTitleCursor + 1)
;>             if cursor == 3: cursor = 0
;>@up         else: cursor = (wTitleCursor - 1) % 3      # Up: the one before
	ld a, [hl]
	inc a
	cp c
	jr nz, jr_000_035c

	xor a

Jump_000_035c:
jr_000_035c:
;>         wTitleCursor = cursor
;>         wShadowOAM[0] = 0x88 if cursor == 1 else 0x90 if cursor == 2 else 0x80   # the cursor's y
	ld [hl], a
	dec a
	ld c, $88
	jr z, jr_000_0369

	dec a
	ld c, $90
	jr z, jr_000_0369

	ld c, $80

jr_000_0369:
	ld hl, wShadowOAM
	ld [hl], c
;>         wStateTimer = 0                         # the title's timeout starts again
	xor a
	ld [wStateTimer], a
;>         return PlaySound(0x15)
	ld a, $15
	jp PlaySound


Jump_000_0376:
;=@s1
	ld a, $17
	call PlaySound
;=@s2
	ld de, $0003
;=@s3
	ld a, [wGameState]
	dec a
	jr z, jr_000_0387

Jump_000_0384:
	ld de, $0001

jr_000_0387:
;> wGameState = state
	ld hl, wGameState
	ld [hl], e
;> wGameSubstate = 0
	inc l
	ld [hl], d
;> if state == 1: return
	dec e
	ret z

;> wPlayerMask = 3 if wTitleCursor == 1 else 7 if wTitleCursor == 2 else 1
	ld a, [wTitleCursor]
	dec a
	ld c, $03
	jr z, jr_000_039e

	dec a
	ld c, $07
	jr z, jr_000_039e

	ld c, $01

jr_000_039e:
	ld a, c
	ld [wPlayerMask], a
;> if not wPlayerMask & 0x04: return HideWindow()
	and $04
	jp z, HideWindow

;> wLinkMaster = 1
	ld a, $01
	ld [wLinkMaster], a
;> rSC = 0x01                                     # internal clock
	ld hl, $ff02
	ld [hl], $01
;> rSB = 0x0E
	ld a, $0e
	ldh [rSB], a
;> rSC |= 0x80
	set 7, [hl]

jr_000_03b7:
;> wait_serial()
	bit 7, [hl]
	jr nz, jr_000_03b7

;> if rSB == 0x0E: return HideWindow()            # the partner is there
	ldh a, [rSB]
	cp $0e
	jp z, HideWindow

;> wGameState = 1                                 # no partner: back to the Palcom screen
	ld hl, wGameState
	ld a, $01
	ld [hl], a
;> wGameSubstate = 1
	inc l
	ld [hl], a
;> wStateTimer = 1
	ld [wStateTimer], a
;> wPlayerMask = 0
	dec a
	ld [wPlayerMask], a
	ret


Jump_000_03d2:
;=@p1
	ld a, $02
	ld [wTitleCursor], a
;=@p2
	ld hl, wGameState
	ld [hl], $03
;=@p3
	inc hl
	xor a
	ld [hl], a
;=@p4
	ld [wLinkMaster], a
;=@p5
	ld a, $07
	ld [wPlayerMask], a
;=@p6
	jp HideWindow


Jump_000_03ea:
;=@up
	ld a, [hl]
	dec a
	cp $ff
	jp nz, Jump_000_035c

;=@up
	ld a, c
	dec a
	jp Jump_000_035c


;@ def CopyOAMDMARoutine()
;@ path: system/lcd
;@ Copies the 10-byte sprite DMA routine after it into HRAM (hOAMDMA): during a
;@ DMA the CPU can only run code from HRAM.
;@ sig: 8c2f915d
CopyOAMDMARoutine::
;> copy(addr(hOAMDMA), OAMDMARoutine, 10)
	ld c, $90
	ld b, $0a
	ld hl, OAMDMARoutine

jr_000_03fd:
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, jr_000_03fd

	ret


;@ The sprite DMA routine CopyOAMDMARoutine copies to hOAMDMA: starts a DMA from wShadowOAM ($CC00) and waits 160 cycles for it to finish.
OAMDMARoutine::
	db $3e, $cc, $e0, $46, $3e, $28, $3d, $20, $fd, $c9

;@ def WaitForLine94()
;@ path: system/lcd
;@ Waits until the LCD reaches line $94 (inside VBlank). Then writes 0 to ROM
;@ address $0040, which has no effect.
;@ sig: 22c88e75
WaitForLine94::
;> wait_ly(0x94)
	ldh a, [rLY]
	cp $94
	jr nz, WaitForLine94

;> mem[0x0040] = 0
	xor a
	ld [$0040], a
	ret


;@ def DisableLCD()
;@ path: system/lcd
;@ Switches the LCD off, at a moment when the screen is between lines $90 and
;@ $95 (inside VBlank, as the hardware needs).
;@ test: rLY = rand(0x90, 0x95)
;@ sig: 3138e810
DisableLCD::
;> WaitVRAM()
	call WaitVRAM
;> while rLY >= 0x96: wait_vblank()              # too late in this VBlank: the next one
	ldh a, [rLY]
	cp $96
	jr nc, DisableLCD

;> rLCDC &= 0x7F
	ldh a, [rLCDC]
	and $7f
	ldh [rLCDC], a
	ret


;@ def EnableLCD()
;@ path: system/lcd
;@ Switches the LCD on if it is off.
;@ sig: 511a17cd
EnableLCD::
;> if rLCDC & 0x80: return
	ldh a, [rLCDC]
	add a
	ret c

;> rLCDC |= 0x80
	ldh a, [rLCDC]
	or $80
	ldh [rLCDC], a
	ret


;@ def ClearBGMap1()
;@ path: gfx/tilemaps
;@ Fills BG map 1 with the blank tile $7F, from its end down, one byte per HBlank.
;@ sig: 09dbc176
ClearBGMap1::
;> for i in range(0x400):
;>     PutVRAMByte(0x7F, u16(0x9FFF - i))
	ld hl, $9fff
	jr jr_000_043c

;@ def ClearBGMap0()
;@ path: gfx/tilemaps
;@ Fills BG map 0 with the blank tile $7F, from its end down, one byte per HBlank.
;@ sig: e9d7dd3d
ClearBGMap0::
;> for i in range(0x400):
;>     PutVRAMByte(0x7F, u16(0x9BFF - i))
	ld hl, $9bff

jr_000_043c:
	ld bc, $0400

jr_000_043f:
	ld a, $7f
	call PutVRAMByte
	dec hl
	dec bc
	ld a, b
	or c
	jr nz, jr_000_043f

	ret


;@ def PutVRAMByte(value: a, dest: hl)
;@ path: gfx/tilemaps
;@ Writes a byte to VRAM in HBlank, and writes it again in the next HBlank if
;@ the LCD had already left HBlank (so the write is sure to have happened).
;@ sig: d9bb2358
PutVRAMByte::
;> while True:
;>     wait_hblank()
;>     mem[dest] = value
;>     if rSTAT & 0x03 == 0: return
	push de
	ld e, a

jr_000_044d:
	ldh a, [rSTAT]
	and $03
	jr nz, jr_000_044d

	ld [hl], e
	ldh a, [rSTAT]
	and $03
	jr nz, jr_000_044d

	pop de
	ret


;@ def CheckPause()
;@ path: race/loop
;@ START pauses and unpauses the race (in a link game either player's START, not
;@ while a bike crashes or has finished). While paused the caller is cut short:
;@ two short delays, then straight back to the caller's caller.
;@ reads: wBikeCrash, wBikeMode, wJoyPressed, wPlayerMask
;@ sig: fbcf78ab
CheckPause::
;> if wPlayerMask & 0x04:
	ld a, [wPlayerMask]
	and $04
	jr z, jr_000_047a

;>     if wBikeMode == 7: return
	ld a, [wBikeMode]
	cp $07
	ret z

;>     if wBikeCrash | wOtherBike[0x29]: return       # either bike crashing
	ld a, [wBikeCrash]
	ld hl, $c829
	or [hl]
	ret nz

;>     pressed = wJoyPressed | wPartnerPressed
	ld a, [wJoyPressed]
	ld hl, wPartnerPressed
	or [hl]
	jr jr_000_0488

jr_000_047a:
;> else:
;>     if wBikeMode == 7: return
	ld a, [wBikeMode]
	cp $07
	ret z

;>     if wBikeCrash: return
	ld a, [wBikeCrash]
	and a
	ret nz

;>     pressed = wJoyPressed
	ld a, [wJoyPressed]

jr_000_0488:
;> if pressed & 0x80:                           # START
	add a
	ld hl, wPause
	jr nc, jr_000_04ad

;>     if wPause & 0x02: return
	bit 1, [hl]
	ret nz

;>     if wPause & 0x01:
	bit 0, [hl]
	jr z, jr_000_049b

;>         wPause &= 0xFE
	res 0, [hl]
;>         return RestoreSoundRegs()
	call RestoreSoundRegs
	ret


jr_000_049b:
;>     wPause |= 0x01
	set 0, [hl]
;>     MuteForPause()
	call MuteForPause
;>     PlaySound(0x08)
	ld a, $08
	call PlaySound
;>     Delay4K()
	call Delay4K
;>     Delay4K()
	call Delay4K
;>     return_from_caller()
	pop hl
	ret


jr_000_04ad:
;> if not wPause & 0x01: return
	bit 0, [hl]
	ret z

;> Delay4K()
	call Delay4K
;> Delay4K()
	call Delay4K
;> return_from_caller()
	pop hl
	ret


;@ def RunGameState()
;@ path: game/state
;@ Counts the frame and runs the handler of the current game state (from
;@ GameStateTable through JumpTable). In the states before the course select
;@ the handler returns into TitleMenuInput.
;@ reads: wGameState
;@ test: skip runs a whole game state
;@ sig: 9020442d
RunGameState::
;> wFrameCounter = u8(wFrameCounter + 1)
	ld hl, wFrameCounter
	inc [hl]
;> state = wGameState
;> handler = (StatePalcomLogo, StateTitle, StateCourseSelect, StateCourseSelect,
;>            StateCourseIntro, StateRace, StateGameOver, StateCourseClear)[state]
	ld a, [wGameState]
	cp $03
	jr nc, jr_000_04c7

;> if state < 3:
;>     handler()
;>     return TitleMenuInput()                    # pushed as the handler's return address
	ld hl, TitleMenuInput
	push hl

jr_000_04c7:
;> return handler()
	call JumpTable

GameStateTable::
	dw StatePalcomLogo
	dw StateTitle
	dw StateCourseSelect
	dw StateCourseSelect
	dw StateCourseIntro
	dw StateRace
	dw StateGameOver
	dw StateCourseClear

;@ def StatePalcomLogo()
;@ path: game/state
;@ Game state 0, the Palcom screen: offer the link cable, draw, wait.
;@ reads: wGameSubstate
;@ test: wGameSubstate = rand(0, 2)
;@ sig: f299521e
StatePalcomLogo::
;> return (LogoOfferLink, LogoDraw, LogoWait)[wGameSubstate]()
	ld a, [wGameSubstate]
	call JumpTable

PalcomLogoSteps::
	dw LogoOfferLink
	dw LogoDraw
	dw LogoWait

;@ def LogoOfferLink()
;@ path: title
;@ Puts $0E in the serial register on the other Game Boy's clock, so a partner
;@ that starts a two-player game finds this one.
;@ sig: bf610c1f
LogoOfferLink::
;> rSC = 0
	xor a
	ldh [rSC], a
;> rSB = 0x0E
	ld a, $0e
	ldh [rSB], a
;> rSC = 0x80                                     # wait for the partner's clock
	ld a, $80
	ldh [rSC], a
;> return NextSubstate()
	jp NextSubstate


;@ def LogoDraw()
;@ path: title
;@ Draws the Palcom screen with the LCD off.
;@ sig: c7269d7e
LogoDraw::
;> DisableLCD()
	call DisableLCD
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> ClearBGMap1()
	call ClearBGMap1
;> LoadFont()
	call LoadFont
;> ShowPalcomScreen()
	call ShowPalcomScreen
;> EnableLCD()
	call EnableLCD
;> return NextSubstate()
	jp NextSubstate


;@ def LogoWait()
;@ path: title
;@ Shows the Palcom screen until its timer runs out (TickScreenTimer), then the
;@ title screen.
;@ writes: wStateTimer
;@ sig: f21d3949
LogoWait::
;> a, zero = TickScreenTimer()
;> if not zero: return
	call TickScreenTimer
	ret nz

;> wStateTimer = 0
	ld [wStateTimer], a
;> return NextGameState()   # falls through

;@ def NextGameState()
;@ path: game/state
;@ On to the next game state, at its first step.
;@ sig: 5edd7bd9
NextGameState::
;> wGameState = u8(wGameState + 1)
	ld hl, wGameState
	inc [hl]

Jump_000_0514:
;> wGameSubstate = 0
	inc l
	ld [hl], $00
	ret


;@ def StateTitle()
;@ path: game/state
;@ Game state 1, the title screen: draw it, then wait.
;@ reads: wGameSubstate
;@ test: wGameSubstate = rand(0, 1)
;@ sig: f299521e
StateTitle::
;> return (TitleDraw, TitleWait)[wGameSubstate]()
	ld a, [wGameSubstate]
	call JumpTable

TitleSteps::
	dw TitleDraw
	dw TitleWait

;@ def TitleDraw()
;@ path: title
;@ Draws the title screen with the LCD off (the logo, the copyright lines and
;@ the three choices) and puts the cursor sprite at the current choice.
;@ writes: wShadowOAM
;@ reads: wTitleCursor
;@ sig: c35a7905
TitleDraw::
;> DisableLCD()
	call DisableLCD
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> ClearBGMap1()
	call ClearBGMap1
;> HideWindow()
	call HideWindow
;> LoadFont()
	call LoadFont
;> LoadCursorTile()
	call LoadCursorTile
;> LoadTitleScreen()
	call LoadTitleScreen
;> DrawStrings(TitleScreenText)
	ld de, TitleScreenText
	call DrawStrings
;> DrawStrings(SoloText)
	ld de, SoloText
	call DrawStrings
;> DrawStrings(VsComputerText)
	ld de, VsComputerText
	call DrawStrings
;> DrawStrings(VsPlayerText)
	ld de, VsPlayerText
	call DrawStrings
;> EnableLCD()
	call EnableLCD
;> c = wTitleCursor
;> wShadowOAM[0] = 0x80 if c == 0 else 0x88 if c == 1 else 0x90   # the cursor's y
	ld a, [wTitleCursor]
	and a
	ld c, $80
	jr z, jr_000_0561

	dec a
	ld c, $88
	jr z, jr_000_0561

	ld c, $90

jr_000_0561:
	ld a, c
	ld [wShadowOAM], a
;> copy(addr(wShadowOAM) + 1, TitleCursorSprite, 3)   # its x, tile and attributes
	ld hl, TitleCursorSprite
	ld de, $cc01
	ld bc, $0003
	call CopyBytes
;> return StartStateTimer(0)                      # 256 frames until the timeout
	xor a
	jp StartStateTimer


;@ The title cursor sprite's x, tile and attributes (its y is set by the choice).
TitleCursorSprite::
	db $28, $00, $00

;@ def TitleWait()
;@ path: title
;@ The title screen's timeout: after 256 frames without a cursor move, back to
;@ the Palcom screen.
;@ sig: cc034df5
TitleWait::
;> wStateTimer = u8(wStateTimer - 1)
;> if wStateTimer: return
	ld hl, wStateTimer
	dec [hl]
	ret nz

;> wGameState = 0
	xor a
	ld hl, wGameState
	ld [hl], a
;> wGameSubstate = 1                              # LogoDraw
	inc l
	ld [hl], $01
	ret


;@ def StateCourseSelect()
;@ path: game/state
;@ Game states 2 and 3, the course select: draw it, then run it.
;@ reads: wGameSubstate
;@ test: wGameSubstate = rand(0, 1)
;@ sig: f299521e
StateCourseSelect::
;> return (CourseSelectDraw, CourseSelectRun)[wGameSubstate]()
	ld a, [wGameSubstate]
	call JumpTable

CourseSelectSteps::
	dw CourseSelectDraw
	dw CourseSelectRun

;@ def CourseSelectDraw()
;@ path: game/select
;@ Draws the course select screen (a different frame for a link game), resets
;@ the race data and starts its music.
;@ writes: wPartnerHeld, wSelectStep
;@ reads: wPlayerMask
;@ sig: 39aeec07
CourseSelectDraw::
;> DisableLCD()
	call DisableLCD
;> ResetRaceData()
	call ResetRaceData
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> InitMenuCursors()
	call InitMenuCursors
;> DrawStrings(0x3435 if wPlayerMask & 0x04 else CourseSelectText)   # $3435: the link game's frame
	ld a, [wPlayerMask]
	and $04
	ld de, $3435
	jr nz, jr_000_05a9

	ld de, CourseSelectText

jr_000_05a9:
	call DrawStrings
;> LinkStartSync()
	call LinkStartSync
;> wSelectStep = 0
	xor a
	ld [wSelectStep], a
;> wPartnerHeld = 0xFF
	dec a
	ld [wPartnerHeld], a
;> PlaySound(0x19)
	ld a, $19
	call PlaySound
;> return NextSubstate()
	jp NextSubstate


;@ def CourseSelectRun()
;@ path: game/select
;@ One frame of the course select. In a link game the two Game Boys swap their
;@ buttons first, and the one without wLinkMaster plays with the master's. When
;@ the choices are made (two steps, one over the link cable), on to the race.
;@ writes: wJoyHeld, wJoyPressed, wSerialPending
;@ reads: wLinkMaster, wPartnerHeld, wPartnerPressed, wPlayerMask, wSelectStep
;@ test: wSelectStep = rand(0, 1); wPlayerMask = rng.choice([1, 3])
;@ sig: 2f16c78e
CourseSelectRun::
;> if wPlayerMask & 0x04:
	ld a, [wPlayerMask]
	and $04
	jr z, jr_000_0608

;>     if wLinkMaster: SerialSendJoypad()
	ld a, [wLinkMaster]
	and a
	call nz, SerialSendJoypad
;>     rIE |= 0x04                                 # the timer interrupt on
	ld hl, $ffff
	set 2, [hl]
;>     Delay(0x0800)
	ld bc, $0800
	call Delay
;>     if not wLinkMaster: SerialSendJoypad()
	ld a, [wLinkMaster]
	and a
	call z, SerialSendJoypad
;>     SerialReceiveJoypad()
	call SerialReceiveJoypad
;>     if not wLinkMaster: LinkSendSync(0)
	ld b, $00
	ld a, [wLinkMaster]
	and a
	call z, LinkSendSync
;>     wSerialPending = 1
	ld a, $01
	ld [wSerialPending], a
;>     Delay(0x0800)
	ld bc, $0800
	call Delay
;>     if not wLinkMaster:
	ld a, [wLinkMaster]
	and a
	jr nz, jr_000_0608

;>         wJoyHeld = wPartnerHeld                 # the menus follow the master's buttons
	ld a, [wPartnerHeld]
	ld [wJoyHeld], a
;>         wJoyPressed = wPartnerPressed
	ld a, [wPartnerPressed]
	ld [wJoyPressed], a

jr_000_0608:
;> CourseSelectInput()
	call CourseSelectInput
;> if wSelectStep != (1 if wPlayerMask & 0x04 else 2): return
	ld a, [wPlayerMask]
	and $04
	ld c, $02
	jr z, jr_000_0615

	dec c

jr_000_0615:
	ld a, [wSelectStep]
	cp c
	ret nz

;> PlaySound(0x00)
	ld a, $00
	call PlaySound
;> PlaySound(0x17)
	ld a, $17
	call PlaySound
;> return NextGameState()
	jp NextGameState


;@ def StateCourseIntro()
;@ path: game/state
;@ Game state 4, the screen before a course: draw it, then wait and build the
;@ race.
;@ reads: wGameSubstate
;@ test: wGameSubstate = rand(0, 1)
;@ sig: f299521e
StateCourseIntro::
;> return (CourseIntroDraw, CourseIntroWait)[wGameSubstate]()
	ld a, [wGameSubstate]
	call JumpTable

CourseIntroSteps::
	dw CourseIntroDraw
	dw CourseIntroWait

;@ def CourseIntroDraw()
;@ path: game/intro
;@ Draws the course's intro screen (the course number, the time to beat) with
;@ the timer interrupt on, and shows it for 128 frames.
;@ sig: d1757621
CourseIntroDraw::
;> rIE |= 0x04                                    # the timer interrupt on
	ld hl, $ffff
	set 2, [hl]
;> DisableLCD()
	call DisableLCD
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> DrawCourseIntro()
	call DrawCourseIntro
;> EnableLCD()
	call EnableLCD
;> return StartStateTimer(0x80)
	ld a, $80
	jp StartStateTimer


;@ def CourseIntroWait()
;@ path: game/intro
;@ When the intro's time is up: clears the screen, puts the window (the status
;@ bar) at the bottom, builds the course and starts the race.
;@ sig: 42258a58
CourseIntroWait::
;> wStateTimer = u8(wStateTimer - 1)
;> if wStateTimer: return
	ld hl, wStateTimer
	dec [hl]
	ret nz

;> DisableLCD()
	call DisableLCD
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> ClearBGMap1()
	call ClearBGMap1
;> ShowWindow(0x0780)                             # WY = $80, WX = 7: the status bar
	ld de, $0780
	call ShowWindow
;> StartRace()
	call StartRace
;> return NextGameState()
	jp NextGameState


;@ def StateRace()
;@ path: game/state
;@ Game state 5, the race: one frame of it. When the clock runs out, on to TIME
;@ UP (state 6); when the bike crosses the finish line, to the course results
;@ (state 7).
;@ reads: wClockRunning, wCourseDone
;@ sig: deb0183c
StateRace::
;> RaceFrame()
	call RaceFrame
;> if not wClockRunning: return NextGameState()
	ld a, [wClockRunning]
	and a
	jp z, NextGameState

;> if not wCourseDone: return
	ld a, [wCourseDone]
	and a
	ret z

;> return SetGameState(7)   # falls through
	ld a, $07

;@ def SetGameState(state: a)
;@ path: game/state
;@ Switches to a game state, at its first step.
;@ sig: f02f7576
SetGameState::
;> wGameState = state
	ld hl, wGameState
	ld [hl], a
;> wGameSubstate = 0
	jp Jump_000_0514


;@ def StateGameOver()
;@ path: game/state
;@ Game state 6: TIME UP (the clock ran out), then the GAME OVER screen, then
;@ back to the Palcom screen. The end of a link game and of the third round
;@ of courses join it at the GAME OVER screen.
;@ reads: wGameSubstate
;@ test: wGameSubstate = rand(0, 4)
;@ sig: f299521e
StateGameOver::
;> return (GameOverStart, GameOverBlink, GameOverFade, GameOverShowText, GameOverEnd)[wGameSubstate]()
	ld a, [wGameSubstate]
	call JumpTable

GameOverSteps::
	dw GameOverStart
	dw GameOverBlink
	dw GameOverFade
	dw GameOverShowText
	dw GameOverEnd

;@ def GameOverStart()
;@ path: game/gameover
;@ The clock has run out: opens the TIME UP box (the VBlank handler draws it,
;@ mode 5), stops the music and plays the time-up tune.
;@ writes: wNextVBlankMode
;@ sig: 87b05fed
GameOverStart::
;> rIE |= 0x04                                    # the timer interrupt on
	ld hl, $ffff
	set 2, [hl]
;> OpenTimeUpBox()
	call OpenTimeUpBox
;> wNextVBlankMode = 5
	ld a, $05
	ld [wNextVBlankMode], a
;> PlaySound(0x00)
	ld a, $00
	call PlaySound
;> PlaySound(0x1C)
	ld a, $1c
	call PlaySound
;> return StartStateTimer(0xC0)                   # 192 frames
	ld a, $c0
	jr jr_000_06f9

;@ def GameOverBlink()
;@ path: game/gameover
;@ Blinks TIME UP until the timer runs out.
;@ sig: 3264123d
GameOverBlink::
;> wStateTimer = u8(wStateTimer - 1)
;> if not wStateTimer: return NextSubstate()
	ld hl, wStateTimer
	dec [hl]
	jp z, NextSubstate

;> return BlinkTimeUp()
	jp BlinkTimeUp


;@ def GameOverFade()
;@ path: game/gameover
;@ Fades all three palettes to white, one step every 16 frames.
;@ writes: wNextVBlankMode
;@ reads: wFrameCounter
;@ sig: e7321ea6
GameOverFade::
;> wNextVBlankMode = 4
	ld a, $04
	ld [wNextVBlankMode], a
;> if wFrameCounter & 0x0F: return
	ld a, [wFrameCounter]
	and $0f
	ret nz

;> FadePaletteStep(addr(rBGP))
	ld hl, $ff47
	call FadePaletteStep
;> FadePaletteStep(addr(rOBP0))
	ld hl, $ff48
	call FadePaletteStep
;> FadePaletteStep(addr(rOBP1))
	ld hl, $ff49
	call FadePaletteStep
;> if rBGP & 0xC0: return
	ldh a, [rBGP]
	and $c0
	ret nz

;> return NextSubstate()
	jr jr_000_06fc

;@ def GameOverShowText()
;@ path: game/gameover
;@ The GAME OVER screen: the normal palettes again and the text, shown for 128
;@ frames.
;@ writes: wNextVBlankMode
;@ sig: d2cbdcc9
GameOverShowText::
;> wNextVBlankMode = 1
	ld a, $01
	ld [wNextVBlankMode], a
;> DisableLCD()
	call DisableLCD
;> rBGP = 0xE4
	ld hl, $ff47
	ld [hl], $e4
;> rOBP0 = 0xE4
	inc hl
	ld [hl], $e4
;> rOBP1 = 0xA8
	inc hl
	ld [hl], $a8
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> HideWindow()
	call HideWindow
;> LoadFont()
	call LoadFont
;> DrawStrings(GameOverText)
	ld de, $0ee9
	call DrawStrings
;> EnableLCD()
	call EnableLCD
;> return StartStateTimer(0x80)   # falls through
	ld a, $80

;@ def StartStateTimer(frames: a)
;@ path: game/state
;@ Sets wStateTimer and goes on to the next step of the state.
;@ writes: wStateTimer
;@ sig: 3abfa65e
StartStateTimer::
jr_000_06f9:
;> wStateTimer = frames
;> return NextSubstate()   # falls through
	ld [wStateTimer], a

;@ def NextSubstate()
;@ path: game/state
;@ On to the next step of the current game state.
;@ sig: 6f69d6b3
NextSubstate::
jr_000_06fc:
;> wGameSubstate = u8(wGameSubstate + 1)
	ld hl, wGameSubstate
	inc [hl]
	ret


;@ def GameOverEnd()
;@ path: game/gameover
;@ After the GAME OVER screen: the link game is over, back to the Palcom
;@ screen.
;@ writes: wLinkMaster, wPlayerMask, wSerialIn
;@ sig: b523a416
GameOverEnd::
;> wStateTimer = u8(wStateTimer - 1)
;> if wStateTimer: return
	ld hl, wStateTimer
	dec [hl]
	ret nz

;> wLinkMaster = wSerialIn = wPlayerMask = 0
	xor a
	ld [wLinkMaster], a
	ld [wSerialIn], a
	ld [wPlayerMask], a
;> return SetGameState(0)
	xor a
	jp SetGameState


;@ def StateCourseClear()
;@ path: game/state
;@ Game state 7, a course finished: the results, then the next course.
;@ reads: wGameSubstate
;@ test: wGameSubstate = rand(0, 2)
;@ sig: f299521e
StateCourseClear::
;> return (CourseClearDraw, CourseClearBlink, CourseClearNext)[wGameSubstate]()
	ld a, [wGameSubstate]
	call JumpTable

CourseClearSteps::
	dw CourseClearDraw
	dw CourseClearBlink
	dw CourseClearNext

;@ def CourseClearDraw()
;@ path: game/results
;@ Draws the course results and plays the finish tune (another one for a new
;@ best time).
;@ writes: wCourseDone, wNextVBlankMode
;@ reads: wNewRecord
;@ sig: cb650050
CourseClearDraw::
;> rIE |= 0x04                                    # the timer interrupt on
	ld hl, $ffff
	set 2, [hl]
;> wCourseDone = 0
	xor a
	ld [wCourseDone], a
;> wNextVBlankMode = 1
	inc a
	ld [wNextVBlankMode], a
;> DisableLCD()
	call DisableLCD
;> ClearScreenAndOAM()
	call ClearScreenAndOAM
;> HideWindow()
	call HideWindow
;> LoadFont()
	call LoadFont
;> DrawResults()
	call DrawResults
;> EnableLCD()
	call EnableLCD
;> PlaySound(0x00)
	ld a, $00
	call PlaySound
;> PlaySound(0x1B if wNewRecord else 0x1A)
	ld a, [wNewRecord]
	and a
	ld a, $1a
	jr z, jr_000_074e

	ld a, $1b

jr_000_074e:
	call PlaySound
;> return StartStateTimer(0)                      # 256 steps of 2 frames
	xor a
	jp StartStateTimer


;@ def CourseClearBlink()
;@ path: game/results
;@ Shows the results for 512 frames; a new best time blinks.
;@ reads: wFrameCounter, wNewRecord
;@ sig: 269b7ab4
CourseClearBlink::
;> if wFrameCounter & 0x01: return
	ld a, [wFrameCounter]
	and $01
	ret nz

;> wStateTimer = u8(wStateTimer - 1)
;> if not wStateTimer: return NextSubstate()
	ld hl, wStateTimer
	dec [hl]
	jp z, NextSubstate

;> if not wNewRecord: return
	ld a, [wNewRecord]
	and a
	ret z

;> return BlinkRecord()
	jp BlinkRecord


;@ def CourseClearNext()
;@ path: game/results
;@ On to the next course (its intro screen). After the eighth course it starts
;@ again at the first, one round further; after the third round, and after any
;@ link game, the GAME OVER screen.
;@ writes: wGameState, wGameSubstate, wRound, wStateTimer
;@ reads: wPlayerMask, wRound
;@ test: wCourse = rand(1, 8); wRound = rand(0, 2)
;@ sig: bd5e89a8
CourseClearNext::
;> over = wPlayerMask & 0x04                       # a link game ends after one course
;> if not over:
	ld a, [wPlayerMask]
	and $04
	jr nz, jr_000_0787

;>     wCourse = u8(wCourse + 1)
	ld hl, wCourse
	inc [hl]
	ld a, [hl]
;>     if wCourse == 9:
	cp $09
	jr nz, jr_000_0794

;>         wCourse = 1
	ld [hl], $01
;>         wRound = u8(wRound + 1)
	ld a, [wRound]
	inc a
	ld [wRound], a
;>         over = wRound == 3
	cp $03
	jr nz, jr_000_0792

jr_000_0787:
;> if over:
;>     wGameState = 6                             # the GAME OVER screen
	ld a, $06
	ld [wGameState], a
;>     wGameSubstate = 3
;>     return
	ld a, $03
	ld [wGameSubstate], a
	ret


jr_000_0792:
;> wCourse = wCourse                              # (written back unchanged)
	ld a, $01

jr_000_0794:
	ld [hl], a
;> wStateTimer = 0x80
	ld a, $80
	ld [wStateTimer], a
;> return SetGameState(4)                         # the next course's intro
	ld a, $04
	jp SetGameState


;@ def DrawCourseIntro()
;@ path: race/setup
;@ The screen before a race: QUALIFYING TIME (in a link game only the course
;@ name box and COURSE RECORD), the course number, the course's best time and,
;@ outside a link game, the round's mark and the qualifying time.
;@ reads: wCourse, wPlayerMask, wRound
;@ sig: db54d95d
DrawCourseIntro::
;> text = CourseRecordText if wPlayerMask & 0x04 else QualifyingTimeText
	ld a, [wPlayerMask]
	and $04
	ld de, QualifyingTimeText
	jr z, jr_000_07ac

	ld de, CourseRecordText

jr_000_07ac:
;> DrawStrings(text)
	call DrawStrings
;> PutTile(wCourse | 0xA0, 0x988D)                 # the course number
	ld hl, $988d
	ld a, [wCourse]
	or $a0
	call PutTile
;> LoadTimeLimit()
	call LoadTimeLimit
;> PrintTimeDigits(u16(wBestTimes + 2 + u8(3 * (wCourse - 1))), 0x9967, 3)   # the course's best time
	ld de, $c062
	ld a, [wCourse]
	dec a
	ld c, a
	add a
	add c
	rst $30
	ld hl, $9967
	ld b, $03
	call PrintTimeDigits
;> if wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret nz

;> tile = 0x95 if wRound == 1 else 0x94 if wRound == 2 else 0x8F
	ld hl, $988e
	ld a, [wRound]
	dec a
	ld c, $95
	jr z, jr_000_07e8

	dec a
	ld c, $94
	jr z, jr_000_07e8

	ld c, $8f

jr_000_07e8:
;> PutTile(tile, 0x988E)
	ld a, c
	call PutTile
;> return PrintTimeDigits(addr(wTimeMinutes), 0x99E7, 3)   # the time to beat
	ld de, wTimeMinutes
	ld hl, $99e7
	ld b, $03
	jp PrintTimeDigits


;@ def StartRace()
;@ path: race/setup
;@ Sets up a race: the camera and both bikes on the start line, the race
;@ graphics, the level map (filled with $FF, then the course's track pieces and
;@ item metatiles placed into it), the items, the first screen, the status bar,
;@ the clock and the sprites. Then (falling through) the link game's start sync.
;@ writes: wFrameCounter, wHurrySound, wLapTimeShow, wLastMetatile, wNextVBlankMode, wStartCountdown, wStarterX, wStarterY
;@ reads: wBikeX, wBikeY, wCamX, wCamY, wPlayerMask
;@ test: skip builds the whole level: far more steps than a test trial runs
;@ sig: 8ede3b8f
StartRace::
;> wFrameCounter = wHurrySound = wLapTimeShow = 0
	xor a
	ld [wFrameCounter], a
	ld [wHurrySound], a
	ld [wLapTimeShow], a
;> ResetCamera()
	call ResetCamera
;> wStartCountdown = 0x30
	ld a, $30
	ld [wStartCountdown], a
;> ResetBike()
	call ResetBike
;> SwapBikes()
	call SwapBikes
;> ResetBike()
	call ResetBike
;> SwapBikes()
	call SwapBikes
;> wStarterY = u8(mem[addr(wBikeY) + 1] + 8)
	ld a, [wBikeY + 1]
	add $08
	ld [wStarterY], a
;> wStarterX = u8(wBikeX[1] + 0x10)
	ld a, [wBikeX + 1]
	add $10
	ld [wStarterX], a
;> LoadTileList(RaceGfxList)                          # the race graphics
	ld hl, $3811
	call LoadTileList
;> fill(wLevelMap, 0xFF, 0x1000)
	ld hl, wLevelMap
	ld de, $ce01
	ld bc, $0fff
	ld [hl], $ff
	call CopyBytes
;> fill(wCompMetatiles, 0x42, 0x160)
	ld hl, wCompMetatiles
	ld [hl], $42
	ld de, $cca1
	ld bc, $015f
	call CopyBytes
;> wLastMetatile = 0xA8
	ld a, $a8
	ld [wLastMetatile], a
;> PlaceTrackPieces(0x4771)
	ld hl, $4771
	call PlaceTrackPieces
;> PlaceItemMetatiles(0x5F0C)
	ld hl, $5f0c
	call PlaceItemMetatiles
;> SetColumnTargets()
	call SetColumnTargets
;> BuildMapColumn()
	call BuildMapColumn
;> fill(wItems, 0, 0x100)
	ld hl, wItems
	ld [hl], $00
	ld de, $ca01
	ld bc, $00ff
	call CopyBytes
;> BuildItemList()
	call BuildItemList
;> wNextVBlankMode = 2
	ld a, $02
	ld [wNextVBlankMode], a
;> DrawFirstScreen()
	call DrawFirstScreen
;> SetScroll(hi(wCamY), wCamX[1])
	ld a, [wCamY + 1]
	ld l, a
	ld a, [wCamX + 1]
	ld h, a
	call SetScroll
;> fill(wStatusBar, 0x42, 0x40)
	ld hl, wStatusBar
	ld a, $42
	ld b, $40

jr_000_0889:
	ld [hli], a
	dec b
	jr nz, jr_000_0889

;> InitStatusBar()
	call InitStatusBar
;> if not wPlayerMask & 0x04:
	ld a, [wPlayerMask]
	and $04
	jr nz, jr_000_089f

;>     DrawTimeGauge(addr(wTimeLeft))                  # the time left
	ld de, wTimeLeft
	call DrawTimeGauge
	jr jr_000_08a5

;> else:
;>     DrawTimeDigits(addr(wRaceTime))                  # a link race shows the time taken
jr_000_089f:
	ld de, wRaceTime
	call DrawTimeDigits

jr_000_08a5:
;> InitSpriteTiles()
	call InitSpriteTiles
;> InitStartLights()
	call InitStartLights
;> DrawBike()
	call DrawBike
;> if wPlayerMask & 0x02: DrawBike2()
	ld a, [wPlayerMask]
	and $02
	call nz, DrawBike2
;> PlaceBikeMarker()
	call PlaceBikeMarker
;> DrawStarter()
	call DrawStarter
;> PlaySound(9)
	ld a, $09
	call PlaySound
;> return LinkStartSync()   # falls through

;@ def LinkStartSync()
;@ path: link/serial
;@ In a link game, before the race: both Game Boys wait for each other. The
;@ master keeps clocking $0E across (with the timer interrupt off during each
;@ try) until the partner answers $0E; the other side listens until it gets $0E
;@ and then waits a little longer. The LCD goes on and wSerialPending is set.
;@ writes: wSerialPending
;@ reads: wLinkMaster, wPlayerMask
;@ test: wPlayerMask = rand(0, 255) & 0xFB
;@ sig: 6ffcb69d
LinkStartSync::
;> if not wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret z

;> if wLinkMaster:
	ld a, [wLinkMaster]
	and a
	jr z, jr_000_08fb

jr_000_08cd:
;>     while True:
;>         rIE &= 0xFB                                 # no timer interrupt meanwhile
	ld hl, $ffff
	res 2, [hl]
;>         if LinkHandshake(1) == 0x0E: break
	ld b, $01
	call LinkHandshake
	cp $0e
	jr z, jr_000_08ef

;>         rIE |= 0x04
	ld hl, $ffff
	set 2, [hl]
;>         rSC = 0x01
	ld a, $01
	ldh [rSC], a
;>         Delay4K()
	call Delay4K
;>         rSC = 0
	xor a
	ldh [rSC], a
;>         Delay4K()
	call Delay4K
	jr jr_000_08cd

jr_000_08ef:
;>     rSC = 0
	xor a
	ldh [rSC], a
;>     EnableLCD()
	call EnableLCD
;>     wSerialPending = 1
	ld a, $01
	ld [wSerialPending], a
;>     return
	ret


jr_000_08fb:
;> while True:
;>     rIE &= 0xFB
	ld hl, $ffff
	res 2, [hl]
;>     if LinkHandshake(0) == 0x0E: break
	ld b, $00
	call LinkHandshake
	cp $0e
	jr z, jr_000_0913

;>     rIE |= 0x04
	ld hl, $ffff
	set 2, [hl]
;>     Delay4K()
	call Delay4K
	jr jr_000_08fb

jr_000_0913:
;> rSC = 0
	xor a
	ldh [rSC], a
;> EnableLCD()
	call EnableLCD
;> LinkSendSync(0)
	ld b, $00
	call LinkSendSync
;> wSerialPending = 1
	ld a, $01
	ld [wSerialPending], a
;> return Delay(0x3000)
	ld bc, $3000
	jr Delay

;@ def LinkHandshake(clock: b) -> a
;@ path: link/serial
;@ In a link game: sends $0E over the link cable (clock 1 = this Game Boy drives
;@ the clock, 0 = the partner does), waits until the byte is through and returns
;@ the partner's byte. Without the link cable it returns 0 at once.
;@ reads: wPlayerMask
;@ test: wPlayerMask = rand(0, 255) & 0xFB
;@ sig: afc90508
LinkHandshake::
;> if not wPlayerMask & 0x04: return 0
	ld a, [wPlayerMask]
	and $04
	ret z

;> rSC = clock
	ld hl, $ff02
	ld [hl], b
;> rSB = 0x0E
	ld a, $0e
	ldh [rSB], a
;> rSC = clock | 0x80                          # start the transfer
	set 7, [hl]

jr_000_0938:
;> wait_serial()
	bit 7, [hl]
	jr nz, jr_000_0938

;> return rSB
	ldh a, [rSB]
	ret


;@ def LinkSendSync(clock: b)
;@ path: link/serial
;@ In a link game: starts sending $0E over the link cable; when this Game Boy
;@ drives the clock (bit 0 of clock) it also waits until the byte is out.
;@ reads: wPlayerMask
;@ test: wPlayerMask = rand(0, 255) & 0xFB
;@ sig: b9bcd8b1
LinkSendSync::
;> if not wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret z

;> rSC = clock
	ld hl, $ff02
	ld [hl], b
;> rSB = 0x0E
	ld a, $0e
	ldh [rSB], a
;> rSC = clock | 0x80                          # start the transfer
	set 7, [hl]
;> if not clock & 0x01: return
	bit 0, b
	ret z

jr_000_0952:
;> wait_serial()
	bit 7, [hl]
	jr nz, jr_000_0952

	ret


;@ def Delay4K()
;@ path: lib/timing
;@ Busy-waits 4096 rounds of Delay's loop.
;@ sig: e334a341
Delay4K::
;> return Delay(0x1000)   # falls through
	ld bc, $1000

;@ def Delay(count: bc)
;@ path: lib/timing
;@ Busy-waits count rounds of a 24-cycle loop (a count of 0 means 65536).
;@ test: count = rand(1, 0x3000)
;@ sig: 1f0899c6
Delay::
;> pass                                        # dec bc until it is 0
	dec bc
	ld a, c
	or b
	jr nz, Delay

	ret


;@ def ResetCamera()
;@ path: race/camera
;@ Puts the camera at the start of the level (Y $80.00, X 0) and sets $C913-$C916
;@ to their starting values.
;@ writes: wCamX, wCamY, wLapMarker
;@ sig: c4bc8bb9
ResetCamera::
;> wCamY = 0x8000
	ld a, $80
	ld [wCamY + 1], a
	xor a
	ld [wCamY], a
;> wCamX[0] = wCamX[1] = wCamX[2] = 0
	ld [wCamX], a
	ld [wCamX + 1], a
	ld [wCamX + 2], a
;> wLapMarker[0], wLapMarker[1], wLapMarker[2], wLapMarker[3] = 0x0D, 0xF9, 0xB0, 0x0F
	ld a, $0d
	ld [wLapMarker], a
	ld a, $f9
	ld [wLapMarker + 1], a
	ld a, $b0
	ld [wLapMarker + 2], a
	ld a, $0f
	ld [wLapMarker + 3], a
	ret


;@ def ResetBike()
;@ path: race/bikes
;@ Puts the bike at wBikeId on the start line: standing still, level, 4 nitros,
;@ top speed $4F, 104 pixel rows below the camera's top and at column $20. The
;@ computer's bike (bike 2 against the computer) gets endless nitros, the first
;@ power-up and top speed $77.
;@ writes: wBikeAngle, wBikeCrash, wBikeLives, wBikeMode, wBikeMoveAngle, wBikeSpeed, wBikeTopSpeed, wBikeUnused0C, wBikeVelX, wBikeVelY, wBikeX, wBikeY, wLapsLeft, wNitro, wPowerUpA, wPowerUpB, wPowerUpLevel, wRaceTime
;@ reads: wBikeId, wCamY
;@ sig: f624b9f9
ResetBike::
;> wBikeMode = 7
	ld a, $07
	ld [wBikeMode], a
;> wBikeAngle = wBikeSpeed = wBikeUnused0C = wBikeMoveAngle = 0
	xor a
	ld [wBikeAngle], a
	ld [wBikeSpeed], a
	ld [wBikeUnused0C], a
	ld [wBikeMoveAngle], a
;> mem[addr(wBikeY)] = wBikeX[0] = wBikeX[2] = 0
	ld [wBikeY], a
	ld [wBikeX], a
	ld [wBikeX + 2], a
;> wBikeVelY = wBikeVelX = 0
	ld [wBikeVelY], a
	ld [wBikeVelY + 1], a
	ld [wBikeVelX], a
	ld [wBikeVelX + 1], a
;> wRaceTime[0] = wRaceTime[1] = wRaceTime[2] = 0
	ld [wRaceTime], a
	ld [wRaceTime + 1], a
	ld [wRaceTime + 2], a
;> wBikeCrash = wPowerUpLevel = wPowerUpB = wPowerUpA = 0
	ld [wBikeCrash], a
	ld [wPowerUpLevel], a
	ld [wPowerUpB], a
	ld [wPowerUpA], a
;> wOtherBike[0x0D] = wOtherBike[0x0E] = 0
	ld hl, wCamVelY
	ld [hli], a
	ld [hl], a
;> wBikeTopSpeed = 0x4F
	ld a, $4f
	ld [wBikeTopSpeed], a
;> wBikeLives = 0xFF
	ld a, $ff
	ld [wBikeLives], a
;> wLapsLeft = 1
	ld a, $01
	ld [wLapsLeft], a
;> wNitro = 4
	ld a, $04
	ld [wNitro], a
;> mem[addr(wBikeY) + 1] = u8(hi(wCamY) + 0x68)
	ld a, [wCamY + 1]
	add $68
	ld [wBikeY + 1], a
;> wBikeX[1] = 0x20
	ld a, $20
	ld [wBikeX + 1], a
;> if wBikeId == 1: return
	ld a, [wBikeId]
	dec a
	ret z

;> if (wPlayerMask & 0x06) != 0x02: return         # (IsComRace) only against the computer:
	call IsComRace
	ret nz

;> wPowerUpA = 1
	ld a, $01
	ld [wPowerUpA], a
;> wNitro = 0xFF                                   # endless nitros
	ld a, $ff
	ld [wNitro], a
;> wBikeTopSpeed = 0x77
	ld a, $77
	ld [wBikeTopSpeed], a
	ret


;@ def InitSpriteTiles()
;@ path: race/hud
;@ Sets the tiles (and for sprites 15-17 the x positions) of fixed sprites in the
;@ shadow OAM before a race.
;@ writes: wShadowOAM
;@ sig: 9b4228df
InitSpriteTiles::
;> wShadowOAM[0x16] = wShadowOAM[0x32] = 0xEB      # sprites 5 and 12
	ld a, $eb
	ld [wShadowOAM + 22], a
	ld [wShadowOAM + 50], a
;> wShadowOAM[0x1A] = wShadowOAM[0x36] = 0xE5      # sprites 6 and 13
	ld a, $e5
	ld [wShadowOAM + 26], a
	ld [wShadowOAM + 54], a
;> wShadowOAM[0x8E], wShadowOAM[0x92], wShadowOAM[0x96] = 0xEC, 0xED, 0xFD   # sprites 35-37
	ld a, $ec
	ld [wShadowOAM + 142], a
	inc a
	ld [wShadowOAM + 146], a
	ld a, $fd
	ld [wShadowOAM + 150], a
;> wShadowOAM[0x3E], wShadowOAM[0x42], wShadowOAM[0x46] = 0xE0, 0xDF, 0x99   # sprites 15-17
	ld a, $e0
	ld [wShadowOAM + 62], a
	ld a, $df
	ld [wShadowOAM + 66], a
	ld a, $99
	ld [wShadowOAM + 70], a
;> wShadowOAM[0x3D], wShadowOAM[0x41], wShadowOAM[0x45] = 0x60, 0x68, 0x70   # their x
	ld a, $60
	ld [wShadowOAM + 61], a
	ld a, $68
	ld [wShadowOAM + 65], a
	ld a, $70
	ld [wShadowOAM + 69], a
	ret


;@ def RaceFrame()
;@ path: race/loop
;@ One frame of the race (main state 5). The level's logic and the status bar
;@ (skipped while paused), the sprites, the link cable's joypad exchange, the
;@ pause check, then both bikes: the player's bike from the joypad, the other one
;@ after SwapBikes (from the computer or the link partner). Last the clock: it
;@ ticks down, the music hurries below 10 seconds, and at 0 the race ends.
;@ writes: wBikeHeld, wBikePressed, wClockRunning, wCourseDone, wEnginePitch, wFramePending, wLogicRunning, wSerialPending
;@ reads: wBikeCrash, wBikeDriveSpeed, wBikeLives, wBikeMode, wJoyHeld, wJoyPressed, wLinkMaster, wOtherBike, wPause, wPlayerMask, wStartCountdown, wTimeMinutes, wTimeSeconds
;@ test: wBikeMode = rand(0, 8); wJumpKind = rand(0, 4); mem[0xC80B] = rand(0, 8); mem[0xC81A] = rand(0, 4)
;@ sig: c54eb976
RaceFrame::
;> if wLinkMaster: SerialSendJoypad()
	ld a, [wLinkMaster]
	and a
	call nz, SerialSendJoypad
;> if wPause & 0x01:
	ld a, [wPause]
	bit 0, a
	jr z, jr_000_0a55

;>     Delay(0x1000)
	ld bc, $1000
	call Delay
	jr jr_000_0a72

jr_000_0a55:
;> else:
;>     wLogicRunning = 1
	ld a, $01
	ld [wLogicRunning], a
;>     MoveCamera()
	call MoveCamera
;>     SetColumnTargets()
	call SetColumnTargets
;>     BuildMapColumn()
	call BuildMapColumn
;>     wFramePending = 1
	ld a, $01
	ld [wFramePending], a
;>     wLogicRunning = 0
	xor a
	ld [wLogicRunning], a
;>     DrawSpeedometer()
	call DrawSpeedometer
;>     DrawNitroGauge()
	call DrawNitroGauge

jr_000_0a72:
;> if not wLinkMaster: SerialSendJoypad()
	ld a, [wLinkMaster]
	and a
	call z, SerialSendJoypad
;> if not wPause & 0x01:
	ld a, [wPause]
	bit 0, a
	jr nz, jr_000_0aaa

;>     wEnginePitch = wBikeDriveSpeed
	ld a, [wBikeDriveSpeed]
	ld [wEnginePitch], a
;>     RecordTrail()
	call RecordTrail
;>     DrawPowerUpA()
	call DrawPowerUpA
;>     DrawPowerUpB()
	call DrawPowerUpB
;>     DrawBike()
	call DrawBike
;>     DrawWheelSpray()
	call DrawWheelSpray
;>     DrawThrottleFlame()
	call DrawThrottleFlame
;>     PlaceBikeMarker()
	call PlaceBikeMarker
;>     DrawItemPopup()
	call DrawItemPopup
;>     DrawTrail()
	call DrawTrail
;>     StartCountdown()
	call StartCountdown
;>     DrawStarter()
	call DrawStarter
;>     ShowLapTime()
	call ShowLapTime

jr_000_0aaa:
;> SerialReceiveJoypad()
	call SerialReceiveJoypad
;> if not wLinkMaster: LinkSendSync(0)
	ld b, $00
	ld a, [wLinkMaster]
	and a
	call z, LinkSendSync
;> wSerialPending = 1
	ld a, $01
	ld [wSerialPending], a
;> rIE |= 0x04                                     # the timer interrupt on again
	ld hl, $ffff
	set 2, [hl]
;> CheckPause()
	call CheckPause
;> if wStartCountdown not in (0, 0xFF):
	ld a, [wStartCountdown]
	and a
	jr z, jr_000_0ad2

	inc a
	jr z, jr_000_0ad2

;>     Delay(0x1000)
	ld bc, $1000
	call Delay

jr_000_0ad2:
;> wBikeHeld = wJoyHeld
	ld a, [wJoyHeld]
	ld [wBikeHeld], a
;> wBikePressed = wJoyPressed
	ld a, [wJoyPressed]
	ld [wBikePressed], a
;> UpdateBike()
	call UpdateBike
;> SetCameraSpeed()
	call SetCameraSpeed
;> SwapBikes()
	call SwapBikes
;> if (wPlayerMask & 0x06) == 0x02: ComDrive()    # (IsComRace) the computer steers the other bike
	call IsComRace
	call z, ComDrive
;> UpdateBike()
	call UpdateBike
;> if wPlayerMask & 0x02:
	ld a, [wPlayerMask]
	and $02
	jr z, jr_000_0afd

;>     DrawBike2()
	call DrawBike2
;>     DrawCrashMarker()
	call DrawCrashMarker

jr_000_0afd:
;> SwapBikes()
	call SwapBikes
;> if not wBikeLives:
;>@over     wCourseDone = 1                       # no lives left: the race ends
;>@over2     return
	ld a, [wBikeLives]
	and a
	jp z, Jump_000_0b75

;> if wPlayerMask & 0x02 and not wOtherBike[0x21]: HideSprites7To13()
	ld a, [wPlayerMask]
	and $02
	jr z, jr_000_0b15

	ld a, [wOtherBike + 33]
	and a
	call z, HideSprites7To13

jr_000_0b15:
;> if wBikeMode == 7: return
	ld a, [wBikeMode]
	cp $07
	ret z

;> if wBikeCrash >= 2: return
	ld a, [wBikeCrash]
	cp $02
	ret nc

;> CountDownTime(addr(wTimeLeft))                      # the clock ticks down
	ld hl, wTimeLeft
	call CountDownTime
;> if not wTimeMinutes and wTimeSeconds < 0x10:
	ld a, [wTimeMinutes]
	and a
	jr nz, jr_000_0b50

	ld a, [wTimeSeconds]
	cp $10
	jr nc, jr_000_0b50

;>     if wPlayerMask & 0x04:
	ld a, [wPlayerMask]
	and $04
	jr z, jr_000_0b4b

;>         if not wHurrySound & 0x01:
	ld hl, wHurrySound
	bit 0, [hl]
	jr nz, jr_000_0b53

;>             wHurrySound |= 0x01
	set 0, [hl]
;>             PlaySound(0x12)                     # once, in a link game
	ld a, $12
	call PlaySound
	jr jr_000_0b53

jr_000_0b4b:
;>     else:
;>         SetMusicTempoHurry()
	call SetMusicTempoHurry
	jr jr_000_0b53

jr_000_0b50:
;> else:
;>     SetMusicTempoNormal()
	call SetMusicTempoNormal

jr_000_0b53:
;> if not wPlayerMask & 0x04:
	ld a, [wPlayerMask]
	and $04
	jr nz, jr_000_0b62

;>     DrawTimeGauge(addr(wTimeLeft))
	ld de, wTimeLeft
	call DrawTimeGauge
	jr jr_000_0b68

;> else:
;>     DrawTimeDigits(addr(wRaceTime))
jr_000_0b62:
	ld de, wRaceTime
	call DrawTimeDigits

jr_000_0b68:
;> if wTimeLeft[0] or wTimeSeconds or wTimeMinutes: return
	ld hl, wTimeLeft
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	ret nz

;> wClockRunning = 0                               # time is up
	xor a
	ld [wClockRunning], a
	ret


Jump_000_0b75:
;=@over
	ld a, $01
	ld [wCourseDone], a
;=@over2
	ret


;@ def UpdateBike()
;@ path: race/bikes
;@ Moves the bike at wBikeId one frame: throttle, angle and velocity, its mode on
;@ the track, the tiles around it, landing and moving. Items are collected by
;@ every bike but the computer's. A bike still racing (not in mode 7, not deep in
;@ a crash) has its race time counted up.
;@ reads: wBikeCrash, wBikeId, wBikeMode
;@ test: wBikeMode = rand(0, 8); wJumpKind = rand(0, 4); wItemCount = rand(1, 32); wBikeCrash = rand(0, 5)
;@ test: mem[0xC782] = rng.choice([0x00, 0x48, 0x98]); mem[0xC783] = rng.choice([0x00, 0x30, 0x59]); mem[0xC784] = rand(0, 9)
;@ sig: 8a7ce642
UpdateBike::
;> UpdateThrottle()
	call UpdateThrottle
;> LevelOffAtTop()
	call LevelOffAtTop
;> UpdateVelocity()
	call UpdateVelocity
;> UpdateBikeMode()
	call UpdateBikeMode
;> ReadTilesAroundBike()
	call ReadTilesAroundBike
;> ProbeTrackTiles()
	call ProbeTrackTiles
;> CheckBikeGround()
	call CheckBikeGround
;> MoveBike()
	call MoveBike
;> CheckCoursePoints()
	call CheckCoursePoints
;> if (wPlayerMask & 0x06) != 0x02 or wBikeId == 1:   # (IsComRace) not the computer's bike:
	call IsComRace
	jr nz, jr_000_0ba1

	ld a, [wBikeId]
	dec a
	jr nz, jr_000_0ba4

jr_000_0ba1:
;>     CollectItems()
	call CollectItems

jr_000_0ba4:
;> if wBikeMode == 7: return
	ld a, [wBikeMode]
	cp $07
	ret z

;> if wBikeCrash >= 2: return
	ld a, [wBikeCrash]
	cp $02
	ret nc

;> return AddTime(addr(wRaceTime))
	ld hl, wRaceTime
	jp AddTime


;@ def SwapBikes()
;@ path: race/bikes
;@ Swaps the two bike records ($71 bytes at wBikeId and wOtherBike): the code that
;@ moves and draws a bike always works on the one at wBikeId, so this switches
;@ between the two bikes.
;@ sig: b1e22eb3
SwapBikes::
;> for i in range(0x71):
;>     mem[addr(wBikeId) + i], wOtherBike[i] = wOtherBike[i], mem[addr(wBikeId) + i]
	ld hl, wBikeId
	ld de, wOtherBike
	ld b, $71

jr_000_0bbe:
	ld a, [de]
	ld c, [hl]
	ld [hli], a
	ld a, c
	ld [de], a
	inc de
	dec b
	jr nz, jr_000_0bbe

	ret


;@ def HideSprites7To13()
;@ path: race/bikes
;@ Clears sprites 7-13 of the shadow OAM. In a link game the frame's work ends
;@ here: the caller's return address is dropped and the race step's exit runs.
;@ reads: wPlayerMask
;@ test: wPlayerMask = rand(0, 255) & 0xFB
;@ sig: 89c893b4
HideSprites7To13::
;> fill(wShadowOAM + 0x1C, 0, 0x1C)            # 7 sprites, 4 bytes each
	ld hl, $cc1c
	ld b, $1c
	xor a

jr_000_0bce:
	ld [hli], a
	dec b
	jr nz, jr_000_0bce

;> if not wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret z

;> wCourseDone = 1; return_from_caller()        # pop hl, jp to the exit of RaceStep
	pop hl
	jp Jump_000_0b75


;@ def ClearScreenAndOAM()
;@ path: gfx/tilemaps
;@ Blanks BG map 0 and clears the shadow OAM (all but its last byte), each byte
;@ written when VRAM may be written.
;@ sig: 8da5b5d4
ClearScreenAndOAM::
;> GotoClearBGMap0()
	call GotoClearBGMap0
;> for i in range(0x9F):
;>     WaitVRAM()
;>     wShadowOAM[i] = 0
	ld hl, wShadowOAM
	xor a
	ld b, $9f

jr_000_0be5:
	call WaitVRAM
	ld [hli], a
	dec b
	jr nz, jr_000_0be5

	ret


;@ def GotoClearBGMap0()
;@ path: gfx/tilemaps
;@ A jump to ClearBGMap0.
;@ sig: 6541b8a8
GotoClearBGMap0::
;> return ClearBGMap0()
	jp ClearBGMap0


;@ def WaitVRAM()
;@ path: system/lcd
;@ When the LCD is on, waits for VBlank (rSTAT mode 1), so VRAM can be written.
;@ Called before almost every VRAM write outside the VBlank handler. Keeps every
;@ register.
;@ test: rLCDC = rand(0, 0x7F)
;@ sig: 57c4a4ed
WaitVRAM::
;> if rLCDC & 0x80:
	push af
	ldh a, [rLCDC]
	bit 7, a
	jr z, jr_000_0bfe

jr_000_0bf7:
;>     wait_vblank()
	ldh a, [rSTAT]
	and $03
	dec a
	jr nz, jr_000_0bf7

jr_000_0bfe:
;> return
	pop af
	ret


;@ def WaitHBlank()
;@ path: system/lcd
;@ Waits for HBlank (rSTAT mode 0). Keeps every register.
;@ sig: 88faf69c
WaitHBlank::
;> wait_hblank()
	push af

jr_000_0c01:
	ldh a, [rSTAT]
	and $03
	cp $01
	jr nc, jr_000_0c01

;> return
	pop af
	ret


;@ def PutTile(tile: a, at: hl)
;@ path: gfx/tilemaps
;@ Writes one tile (or any byte) to VRAM, waiting for VBlank first if the LCD is
;@ on. The 5 bytes after it are an unused twin that writes to [de].
;@ test: rLCDC = rand(0, 0x7F); at = 0x9800 + rand(0, 0x3FF)
;@ sig: bb854c99
PutTile::
;> WaitVRAM()
	call WaitVRAM
;> mem[at] = tile
	ld [hl], a
	ret


	db $cd, $f0, $0b, $12, $c9

;@ def PutTileBC(tile: a, at: bc)
;@ path: gfx/tilemaps
;@ Like PutTile, at the address in bc.
;@ test: rLCDC = rand(0, 0x7F); at = 0x9800 + rand(0, 0x3FF)
;@ sig: 8d1a3aa7
PutTileBC::
;> WaitVRAM()
	call WaitVRAM
;> mem[at] = tile
	ld [bc], a
	ret


;@ def ShowWindow(pos: de)
;@ path: system/lcd
;@ Moves the window to pos (e = rWY, d = rWX) and switches it on.
;@ test: rLCDC = rand(0, 0x7F)
;@ sig: 6bee3a4f
ShowWindow::
;> WaitVRAM()
	ld hl, $ff4a
	ld a, e
	call WaitVRAM
;> rWY = lo(pos)
	ld [hli], a
;> rWX = hi(pos)
	ld a, d
	ld [hli], a
;> rLCDC |= 0x20                               # window on
	ldh a, [rLCDC]
	set 5, a
	ldh [rLCDC], a
	ret


;@ def HideWindow()
;@ path: system/lcd
;@ Switches the window off (in VBlank when the LCD is on).
;@ test: rLCDC = rand(0, 0x7F)
;@ sig: 321b2089
HideWindow::
;> lcdc = rLCDC & 0xDF
	ldh a, [rLCDC]
	res 5, a
;> WaitVRAM()
	call WaitVRAM
;> rLCDC = lcdc
	ldh [rLCDC], a
	ret


;@ def DrawStrings(src: de) -> de
;@ path: gfx/text
;@ Draws a list of strings to VRAM: a BG map address, the tiles, then $FE and the
;@ next address, or $FF at the end. Returns the address after the $FF.
;@ test: rLCDC = rand(0, 0x7F); src = 0xD000; mem[0xD000] = rand(0, 0x3F); mem[0xD001] = 0xD1
;@ test: for i in range(5): mem[0xD002 + i] = rand(0, 0xFD)
;@ test: mem[0xD007] = 0xFE; mem[0xD008] = rand(0xC0, 0xFF); mem[0xD009] = 0xD1
;@ test: for i in range(3): mem[0xD00A + i] = rand(0, 0xFD)
;@ test: mem[0xD00D] = 0xFF
;@ sig: f258d0fc
DrawStrings::
;> return DrawStringsMode(src, 0xFF)   # falls through
	ld c, $ff

;@ def DrawStringsMode(src: de, mode: c) -> de
;@ path: gfx/text
;@ DrawStrings with a mode: with bit 7 of mode clear every tile is drawn as a
;@ blank ($7F), which erases the strings. A string that reaches the end of a BG
;@ map row goes on at the start of the same row. (The 4 bytes after this routine
;@ are an unused entry that erases: ld c, 0, then a jump here.)
;@ test: rLCDC = rand(0, 0x7F); src = 0xD000; mem[0xD000] = rand(0, 0x3F); mem[0xD001] = 0xD1
;@ test: for i in range(5): mem[0xD002 + i] = rand(0, 0xFD)
;@ test: mem[0xD007] = 0xFE; mem[0xD008] = rand(0xC0, 0xFF); mem[0xD009] = 0xD1
;@ test: for i in range(3): mem[0xD00A + i] = rand(0, 0xFD)
;@ test: mem[0xD00D] = 0xFF
;@ sig: 416c4e93
DrawStringsMode::
;> while True:
;>     at = mem16[src]
;>     src = u16(src + 2)
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	inc de

Jump_000_0c3d:
jr_000_0c3d:
;>     while True:
;>         t = mem[src]
;>         src = u16(src + 1)
;>         if t == 0xFF: return src
	ld a, [de]
	inc de
	ld b, a
	inc b
	ret z

;>         if t == 0xFE: break
	inc b
	jr z, DrawStringsMode

;>         if not mode & 0x80: t = 0x7F             # erase instead
	bit 7, c
	jr nz, jr_000_0c4b

	ld a, $7f

jr_000_0c4b:
;>         WaitVRAM()
	call WaitVRAM
;>         mem[at] = t
	ld [hl], a
;>         at = at & 0xFFE0 if (at & 0x1F) == 0x1F else u16(at + 1)
	ld a, l
	and $1f
	cp $1f
	jr nz, jr_000_0c5c

	ld a, l
	and $e0
	ld l, a
	jr jr_000_0c3d

jr_000_0c5c:
	inc hl
	jr jr_000_0c3d

	db $0e, $00, $18, $d4

;@ def SetScroll(y: l, x: h)
;@ path: system/lcd
;@ Sets the background's scroll position.
;@ sig: 9543d768
SetScroll::
;> rSCY = y
	ld a, l
	ldh [rSCY], a
;> rSCX = x
	ld a, h
	ldh [rSCX], a
	ret


;@ def DrawPackedTiles(src: de)
;@ path: gfx/tilemaps
;@ Switches the LCD off and unpacks a run-length packed block of bytes to VRAM: a
;@ start address, then commands until a 0. A command n below $80 writes the next
;@ byte n times; $80 is followed by a first byte and a count and writes counting
;@ bytes (first, first + 1, ...); n above $80 copies the next n - $80 bytes.
;@ sig: c2c6e49c
DrawPackedTiles::
;> DisableLCD()
	call DisableLCD
	jr jr_000_0c6f

jr_000_0c6f:
;> at = mem16[src]
;> src = u16(src + 2)
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	inc de

jr_000_0c75:
;> while mem[src]:
	ld a, [de]
	or a
	ret z

;>     n = mem[src]
;>     src = u16(src + 1)
	inc de
	ld b, a
;>     if n & 0x80 and n != 0x80:                    # n - $80 bytes as they are
	and $7f
	cp b
	jr z, jr_000_0c8e

	or a
	jr z, jr_000_0c99

	ld b, a

;>         for _ in range(n & 0x7F):
;>             WaitVRAM()
;>             mem[at] = mem[src]
;>             at = u16(at + 1)
;>             src = u16(src + 1)
jr_000_0c83:
	ld a, [de]
	inc de
	call WaitVRAM
	ld [hli], a
	dec b
	jr nz, jr_000_0c83

	jr jr_000_0c75

;>     elif not n & 0x80:                            # n copies of one byte
;>         t = mem[src]
;>         src = u16(src + 1)
jr_000_0c8e:
	ld a, [de]
	inc de

jr_000_0c90:
;>         for _ in range(n):
;>             WaitVRAM()
;>             mem[at] = t
;>             at = u16(at + 1)
	call WaitVRAM
	ld [hli], a
	dec b
	jr nz, jr_000_0c90

	jr jr_000_0c75

jr_000_0c99:
;>     else:                                         # $80: counting bytes (first, count)
;>         t = mem[src]
;>         k = mem[u16(src + 1)]
;>         src = u16(src + 2)
	ld a, [de]
	inc de
	push af
	ld a, [de]
	ld b, a
	inc de
	pop af

jr_000_0ca0:
;>         for i in range(k or 256):
;>             WaitVRAM()
;>             mem[at] = u8(t + i)
;>             at = u16(at + 1)
	call WaitVRAM
	ld [hli], a
	inc a
	dec b
	jr nz, jr_000_0ca0

	jr jr_000_0c75

;@ def FadePaletteStep(p: hl) -> (a, e)
;@ path: gfx/palette
;@ One step of a fade to white: each of the four 2-bit shades of the palette
;@ register at p that is not 0 goes down by 1. Returns the new value.
;@ test: p = rand_ram(1)
;@ sig: 40adc121
FadePaletteStep::
;> v = mem[p]
;> r = 0
;> for shift in (6, 4, 2, 0):
;>     f = (v >> shift) & 3
;>     if f: f -= 1
;>     r |= f << shift
	ld a, [hl]
	and $c0
	jr z, jr_000_0cb1

	sub $40

jr_000_0cb1:
	ld e, a
	ld a, [hl]
	and $30
	jr z, jr_000_0cb9

	sub $10

jr_000_0cb9:
	or e
	ld e, a
	ld a, [hl]
	and $0c
	jr z, jr_000_0cc2

	sub $04

jr_000_0cc2:
	or e
	ld e, a
	ld a, [hl]
	and $03
	jr z, jr_000_0ccb

	sub $01

jr_000_0ccb:
	or e
	ld e, a
;> mem[p] = r
	ld [hl], a
;> return r, r
	ret


;@ def ResetRaceData()
;@ path: race/setup
;@ A new game: clears both bike records and everything up to $CBFF, then starts
;@ at round 0 of course 1 with the clock running. The second bike (if there is
;@ one) gets top speed $6F, or $77 when the computer rides it.
;@ writes: wBikeId, wBikeTopSpeed, wClockRunning, wCourse, wOtherBike, wRound
;@ reads: wPlayerMask
;@ sig: 48a1db86
ResetRaceData::
;> fill(addr(wBikeId), 0, 0x480)
	ld hl, wBikeId
	ld de, wBikeSpeed
	ld bc, $047f
	ld [hl], $00
	call CopyBytes
;> wRound = 0
	xor a
	ld [wRound], a
;> wCourse = wClockRunning = 1
	ld a, $01
	ld [wCourse], a
	ld [wClockRunning], a
;> wBikeId = 1
	ld a, $01
	ld [wBikeId], a
;> wBikeTopSpeed = 0x4F
	ld a, $4f
	ld [wBikeTopSpeed], a
;> if not wPlayerMask & 0x02: return
	ld a, [wPlayerMask]
	and $02
	ret z

;> wOtherBike[0] = 2
	ld a, $02
	ld [wOtherBike], a
;> wOtherBike[0x15] = 0x6F                         # its top speed
	ld a, $6f
	ld [wOtherBike + 21], a
;> if (wPlayerMask & 0x06) != 0x02: return         # (IsComRace) only against the computer:
	call IsComRace
	ret nz

;> wOtherBike[0x15] = 0x77                         # the computer's bike is faster
	ld a, $77
	ld [wOtherBike + 21], a
	ret


;@ def InitStatusBar()
;@ path: race/hud
;@ Writes the status bar's fixed tiles (StatusBarLayout) into wStatusBar; in a link
;@ game also the two marker sprites at the bottom of the screen.
;@ reads: wPlayerMask
;@ test: rLCDC = rand(0, 0x7F)
;@ sig: dfa12634
InitStatusBar::
;> DrawStrings(StatusBarLayout)
	ld de, StatusBarLayout
	call DrawStrings
;> if not wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret z

;> copy(wShadowOAM + 0x98, LinkMarkerSprites, 8)   # sprites 38 and 39
	ld de, $cc98
	ld hl, LinkMarkerSprites
	ld bc, $0008
	jp CopyBytes


;@ Two shadow OAM entries for a link game (tile $EE at the bottom of the screen), copied to sprites 38 and 39 by InitStatusBar.
LinkMarkerSprites::
	db $90, $78, $ee, $00, $90, $90, $ee, $00


;@ Unused code: draws b BCD bytes from [de] backwards as digit tiles ($F0 + digit) with PutTile.
UnusedDrawBCD::
	db $1a, $1f, $1f, $1f, $1f, $e6, $0f, $c6, $f0, $cd, $0b, $0c, $23, $1a, $e6, $0f
	db $c6, $f0, $cd, $0b, $0c, $23, $1b, $05, $20, $e6, $c9

;@ def LoadCursorTile()
;@ path: gfx/tiles
;@ Loads the menu cursor (CursorTile) as tile 0.
;@ sig: 7ff54564
LoadCursorTile::
;> copy(0x8000, CursorTile, 16)
	ld hl, CursorTile
	ld de, $8000
	ld bc, $0010
	jp CopyBytes


;@ def DrawNitroGauge() -> hl
;@ path: race/hud
;@ Draws the nitros left into the status bar's second row: one bottle (tile $49)
;@ for each, up to 8, then blanks.
;@ reads: wNitro
;@ sig: dba248d8
DrawNitroGauge::
;> n = min(wNitro, 8)
	ld hl, $cbec
	ld a, [wNitro]
	cp $09
	jr c, jr_000_0d60

	ld a, $08

jr_000_0d60:
;> p = FillRow(n, 0x49, wStatusBar + 0x2C)
	ld b, a
	ld a, $08
	sub b
	ld c, a
	ld e, $49
	call FillRow
;> return FillRow(8 - n, 0x7F, p)   # falls through
	ld b, c
	ld e, $7f

;@ def FillRow(n: b, tile: e, dest: hl) -> hl
;@ path: lib/memory
;@ Writes tile n times from dest on; returns the address after the last one.
;@ test: n = rand(0, 20); dest = rand_ram(20)
;@ sig: 7dcea90b
FillRow::
;> if not n: return dest
	ld a, b
	and a
	ret z

;> for i in range(n):
;>     mem[dest + i] = tile
	ld a, e

jr_000_0d71:
	ld [hli], a
	dec b
	jr nz, jr_000_0d71

;> return u16(dest + n)
	ret


;@ def DrawPowerUpA()
;@ path: race/hud
;@ Shows the first power-up in the status bar's second row (tiles $45-$48), or
;@ blanks when the bike doesn't have it.
;@ reads: wPowerUpA
;@ sig: 74af93a0
DrawPowerUpA::
;> for i in range(4):
;>     wStatusBar[0x21 + i] = 0x45 + i if wPowerUpA else 0x7F
	ld hl, $cbe1
	ld b, $04
	ld a, [wPowerUpA]
	and a
	jr z, jr_000_0d98

	ld a, $45
	jr jr_000_0d92

;@ def DrawPowerUpB()
;@ path: race/hud
;@ Shows the second power-up in the status bar's second row (tiles $26-$28), or
;@ blanks when the bike doesn't have it.
;@ reads: wPowerUpB
;@ sig: 603c5d97
DrawPowerUpB::
;> for i in range(3):
;>     wStatusBar[0x26 + i] = 0x26 + i if wPowerUpB else 0x7F
	ld hl, $cbe6
	ld b, $03
	ld a, [wPowerUpB]
	and a
	jr z, jr_000_0d98

	ld a, $26

jr_000_0d92:
	ld [hli], a
	inc a
	dec b
	jr nz, jr_000_0d92

	ret


jr_000_0d98:
	ld a, $7f

jr_000_0d9a:
	ld [hli], a
	dec b
	jr nz, jr_000_0d9a

	ret


;@ def DrawSpeedometer()
;@ path: race/hud
;@ Draws the speedometer into the status bar from the bike's speed: an icon at the
;@ left (two rows), six bar tiles (SpeedBarLow below speed $30, SpeedBarHigh from
;@ there) and one or two end tiles, which depend on the bike's top speed.
;@ writes: wStatusBar
;@ reads: wBikeSpeed, wBikeTopSpeed
;@ sig: 9628f9a8
DrawSpeedometer::
;> speed = wBikeSpeed
;> icon = 0x57FA if not speed else 0x57FB if speed < 4 else 0x57FC if speed < 8 else 0x58FC if speed < 0x0C else 0x59FC
	ld a, [wBikeSpeed]
	ld c, a
	and a
	ld de, $57fa
	jr z, jr_000_0dba

	inc e
	cp $04
	jr c, jr_000_0dba

	inc e
	cp $08
	jr c, jr_000_0dba

	ld d, $58
	cp $0c
	jr c, jr_000_0dba

	inc d

jr_000_0dba:
;> wStatusBar[0x20] = lo(icon)
	ld a, e
	ld [wStatusBar + 32], a
;> wStatusBar[0] = hi(icon)
	ld a, d
	ld hl, wStatusBar
	ld [hli], a
;> if speed >= 0x30:
	ld a, c
	cp $30
	jr c, jr_000_0ddb

;>     bar = SpeedBarHigh + ((min(speed, 0x4F) & 0x78) - 0x30) // 8 * 6
	cp $50
	jr c, jr_000_0dce

	ld a, $4f

jr_000_0dce:
	and $78
	sub $30
	rrca
	ld b, a
	rrca
	add b
	ld de, SpeedBarHigh
	jr jr_000_0deb

jr_000_0ddb:
;> else:
;>     bar = SpeedBarLow + ((max(speed, 0x0C) & 0x3C) - 0x0C) // 4 * 6
	cp $0c
	jr nc, jr_000_0de1

	ld a, $0c

jr_000_0de1:
	and $3c
	sub $0c
	ld b, a
	rrca
	add b
	ld de, SpeedBarLow

jr_000_0deb:
;> copy(wStatusBar + 1, bar, 6)
	rst $30
	ld b, $06

jr_000_0dee:
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, jr_000_0dee

;> tail = SpeedBarTail + ((min(max(speed, 0x50) & 0xF8, 0x70) - 0x50) >> 2)
	ld a, c
	cp $50
	jr nc, jr_000_0dfb

	ld a, $50

jr_000_0dfb:
	and $f8
	cp $70
	jr c, jr_000_0e03

	ld a, $70

jr_000_0e03:
	sub $50
	rra
	rra
	ld de, SpeedBarTail
	rst $30
;> if wBikeTopSpeed < 0x50:
	ld a, [wBikeTopSpeed]
	cp $50
	jr nc, jr_000_0e19

;>     tail, n = SpeedBarTailBlank, 2
	ld de, SpeedBarTailBlank
	ld b, $02
	jr jr_000_0e20

jr_000_0e19:
;> else:
;>     n = 1 if wBikeTopSpeed < 0x60 else 2
	ld b, $01
	cp $60
	jr c, jr_000_0e20

	inc b

jr_000_0e20:
;> copy(wStatusBar + 7, tail, n)
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, jr_000_0e20

	ret


;@ The speedometer bar below speed $30: 8 steps of 6 tiles.
SpeedBarLow::
	db $63, $63, $63, $63, $63, $63, $65, $63, $63, $63, $63, $63, $64, $63, $63, $63
	db $63, $63, $64, $65, $63, $63, $63, $63, $64, $64, $63, $63, $63, $63, $64, $64
	db $65, $63, $63, $63, $64, $64, $64, $63, $63, $63, $64, $64, $64, $65, $63, $63
	db $64, $64, $64, $64, $63, $63


;@ The speedometer bar from speed $30: 4 steps of 6 tiles.
SpeedBarHigh::
	db $64, $64, $64, $64, $65, $63, $64, $64, $64, $64, $64, $63, $64, $64, $64, $64
	db $64, $65, $64, $64, $64, $64, $64, $64


;@ The speedometer's last tiles from speed $50: 5 steps, 1 or 2 tiles each.
SpeedBarTail::
	db $63, $63, $66, $63, $67, $63, $67, $66, $67, $67


;@ Two blank tiles: the speedometer's end for a bike whose top speed is below $50.
SpeedBarTailBlank::
	db $7f, $7f

;@ def CopyStatusBar()
;@ path: race/hud
;@ Copies the status bar (two rows of 20 tiles from wStatusBar) to the window's
;@ map at $9C00 (run in VBlank).
;@ sig: 4c564fcf
CopyStatusBar::
;> copy(0x9C00, wStatusBar, 20)
	ld hl, $9c00
	ld de, wStatusBar
	ld b, $14

jr_000_0e89:
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, jr_000_0e89

;> copy(0x9C20, wStatusBar + 0x20, 20)
	ld hl, $9c20
	ld de, $cbe0
	ld b, $14

jr_000_0e97:
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, jr_000_0e97

	ret


;@ asset: strings tiles=LoadFont+LoadTileList(hl=RaceGfxList)|LoadFont
;@ The status bar's fixed tiles, written into wStatusBar (DrawStrings format: an address, tiles, $FE and the next address, $FF at the end).
StatusBarLayout::
	db $ca, $cb, $75, $76, $77, $fe, $ea, $cb, $60, $61, $fe, $c0, $cb, $57, $63, $63
	db $63, $63, $fe, $e0, $cb, $fa, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ The title screen's small print: TM, then TM AND (C) 1991 KONAMI and LICENSED BY NINTENDO (DrawStrings format; the font is not in ASCII order).
TitleScreenText::
	db $0f, $99, $ea, $ec, $fe, $40, $99, $ea, $ec, $7f, $df, $e8, $e6, $7f, $d1, $7f
	db $f1, $f9, $f9, $f1, $7f, $e7, $de, $e8, $df, $ec, $eb, $fe, $80, $99, $e0, $eb
	db $e4, $ed, $e8, $e3, $ed, $e6, $7f, $e5, $d7, $7f, $e8, $eb, $e8, $ea, $ed, $e8
	db $e6, $de, $7f, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ GAME OVER (DrawStrings format).
GameOverText::
	db $e6, $98, $dd, $df, $ec, $ed, $7f, $de, $da, $ed, $e2, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ SOLO, the first choice of the title menu (DrawStrings format).
SoloText::
	db $c6, $99, $e3, $de, $e0, $de, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ VS COMPUTER, the second choice of the title menu (DrawStrings format).
VsComputerText::
	db $e6, $99, $da, $e3, $7f, $e4, $de, $ec, $ef, $ee, $ea, $ed, $e2, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ VS 2-PLAYER, the third choice of the title menu (DrawStrings format).
VsPlayerText::
	db $06, $9a, $da, $e3, $7f, $f2, $d0, $ef, $e0, $df, $d7, $ed, $e2, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ The race screen's texts: QUALIFYING TIME with its 0'00" marks, then (CourseRecordText) the course name box and COURSE RECORD (DrawStrings format).
QualifyingTimeText::
	db $a3, $99, $e9, $ee, $df, $e0, $eb, $dc, $d7, $eb, $e8, $dd, $7f, $ea, $eb, $ec
	db $ed, $fe, $e8, $99, $d5, $7f, $7f, $d5, $fe


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ The part of QualifyingTimeText a link game starts at: the course name box and COURSE RECORD.
CourseRecordText::
	db $65, $98, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $fe, $85, $98
	db $aa, $94, $8e, $9e, $92, $93, $9d, $aa, $aa, $aa, $aa, $fe, $a5, $98, $aa, $aa
	db $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $fe, $24, $99, $e4, $de, $ee, $e2
	db $e3, $ed, $7f, $e2, $ed, $e4, $de, $e2, $e6, $fe, $68, $99, $d5, $7f, $7f, $d5
	db $ff


;@ asset: tiles bpp=2 length=$10
;@ The menu cursor, a small triangle (one 2bpp tile, loaded as tile 0).
CursorTile::
	db $c0, $c0, $f0, $f0, $fc, $fc, $ff, $ff, $fc, $fc, $f0, $f0, $c0, $c0, $00, $00

;@ def LoadTileList(lst: hl)
;@ path: gfx/tiles
;@ Loads graphics into VRAM from a list of 6-byte entries until a zero word: the
;@ tile number (9 bits, $80 = $8000) with the copy mode in the top 3 bits of the
;@ second byte, the length, then the source (CopyTilesMode does the copying).
;@ test: rLCDC = rand(0, 0x7F); lst = rand_ram(8); mem[lst] = rand(0x80, 0xFF); mem[lst + 1] = rand(0, 7) << 5; mem[lst + 2] = rand(1, 0x40); mem[lst + 3] = 0; mem[lst + 4] = rand(0, 255); mem[lst + 5] = rand(0x40, 0x6F); mem[lst + 6] = mem[lst + 7] = 0
;@ sig: 36931c17
LoadTileList::
;> while mem16[lst]:                               # (the rst $18 before the loop changes nothing)
	rst $18

jr_000_0f83:
	ld e, [hl]
	ld a, [hli]
	or [hl]
	ret z

;>     tile = mem[lst] | (mem[lst + 1] & 1) << 8
;>     mode = mem[lst + 1] >> 5
	push hl
	ld a, [hl]
	rlca
	rlca
	rlca
	and $07
	push af
	push hl
	ld a, [hl]
	and $01
	ld h, a
	ld l, e
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld de, $8000
	add hl, de
	ld de, $f800
	add hl, de
	ld e, l
	ld d, h
;>     CopyTilesMode(mode, mem16[lst + 4], u16(0x7800 + 16 * tile), mem16[lst + 2])
	pop hl
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	call CopyTilesMode
;>     lst = u16(lst + 6)
	pop hl
	ld de, $0005
	add hl, de
	jr jr_000_0f83

;@ def CopyTilesMode(mode: a, src: hl, dest: de, count: bc)
;@ path: gfx/tiles
;@ Copies `count` tiles into VRAM, waiting for VRAM access before every byte, drawn
;@ the way `mode` says: 1 inverted, 2 upside down, 3 from 1 bit per pixel (the
;@ bits 8-10 of `count` pick the colour), 4 mirrored, 6 upside down and mirrored;
;@ any other mode copies them as they are. LoadTileList's entries hold the mode.
;@ test: mem[0xFF40] &= 0x7F; mode = rand(0, 7); count = rand(1, 3) | (rng.choice([0, 0x100, 0x200, 0x300, 0x400, 0x600]) if mode == 3 else 0); src = 0xC100 + rand(0, 0x3F); dest = 0xC800 + 2 * rand(0, 0x3F)   # long 1bpp copies stay below echo RAM
;@ sig: 9808e0d6
CopyTilesMode::
;> if mode == 1:                                    # inverted
;>@i1     for i in range(TilesToBytes(count) or 0x10000):
;>@i2         WaitVRAM()
;>@i3         mem[u16(dest + i)] = ~mem[u16(src + i)] & 0xFF
	dec a
	jr z, jr_000_0fd8

;> elif mode == 2:                                  # upside down: rows from the last one up
;>@v1     for t in range(count or 0x10000):
;>@v2         CopyTileFlipV(u16(src + 16 * t + 17), u16(dest + 16 * t))
	dec a
	jr z, jr_000_0fe8

;> elif mode == 3:                                  # 1 bit per pixel, 8 bytes a tile
;>@p1     n = TilesToBytes(count) >> 1              # bits 12-14 now choose the planes
;>@p2     while True:
;>@p3         WaitVRAM()                          # plane 0: $FF (bit 14), the byte (bit 12) or 0
;>@p4         mem[dest] = 0xFF if n & 0x4000 else mem[src] if n & 0x1000 else 0
;>@p5         WaitVRAM()                          # plane 1: the byte (bit 13) or 0
;>@p6         mem[u16(dest + 1)] = mem[src] if n & 0x2000 else 0
;>@p7         src, dest, n = u16(src + 1), u16(dest + 2), u16(n - 1)
;>@p8         if not n & 0x0FFF: break
	dec a
	jp z, Jump_000_100f

;> elif mode == 4:                                  # mirrored left to right
;>@h1     for i in range(TilesToBytes(count) or 0x10000):
;>@h2         b = ReverseBits(mem[u16(src + i)])
;>@h3         WaitVRAM()
;>@h4         mem[u16(dest + i)] = b
	dec a
	jr z, jr_000_0ffb

;> elif mode == 6:                                  # upside down and mirrored
;>@b1     for t in range(count or 0x10000):
;>@b2         CopyTileFlipHV(u16(src + 16 * t + 17), u16(dest + 16 * t))
	dec a
	dec a
	jr z, jr_000_103c

;> else:                                            # as they are
;>     for i in range(TilesToBytes(count) or 0x10000):
	dec a
	call TilesToBytes

jr_000_0fcc:
;>         b = mem[u16(src + i)]
;>         WaitVRAM()
	ld a, [hli]
	call WaitVRAM
;>         mem[u16(dest + i)] = b
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, jr_000_0fcc

;> return
	ret


jr_000_0fd8:
;=@i1
	call TilesToBytes

jr_000_0fdb:
;=@i2
	ld a, [hli]
	call WaitVRAM
;=@i3
	cpl
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, jr_000_0fdb

	ret


;=@v1
jr_000_0fe8:
	push bc
;=@v2
	ld bc, $0011
	add hl, bc
	call CopyTileFlipV
;=@v1
	ld bc, $000f
	add hl, bc
	pop bc
	dec bc
	ld a, b
	or c
	jr nz, jr_000_0fe8

	ret


jr_000_0ffb:
;=@h1
	call TilesToBytes

jr_000_0ffe:
;=@h2
	ld a, [hli]
	push bc
	call ReverseBits
	pop bc
;=@h3
	call WaitVRAM
;=@h4
	ld [de], a
;=@h1
	inc de
	dec bc
	ld a, b
	or c
	jr nz, jr_000_0ffe

	ret


Jump_000_100f:
;=@p1
	call TilesToBytes
	srl b
	rr c

;=@p2
jr_000_1016:
;=@p4
	ld a, [hl]
	bit 6, b
	jr z, jr_000_101f

	ld a, $ff
	jr jr_000_1024

jr_000_101f:
	bit 4, b
	jr nz, jr_000_1024

	xor a

jr_000_1024:
;=@p3
	call WaitVRAM
;=@p4
	ld [de], a
;=@p7
	inc de
;=@p6
	ld a, [hli]
	bit 5, b
	jr nz, jr_000_102f

	xor a

jr_000_102f:
;=@p5
	call WaitVRAM
;=@p6
	ld [de], a
	inc de
;=@p8
	dec bc
	ld a, b
	and $0f
	or c
	jr nz, jr_000_1016

	ret


jr_000_103c:
;=@b1
	push bc
;=@b2
	ld bc, $0011
	add hl, bc
	call CopyTileFlipHV
;=@b1
	ld bc, $000f
	add hl, bc
	pop bc
	dec bc
	ld a, b
	or c
	jr nz, jr_000_103c

	ret


;@ def CopyTileFlipV(end: hl, dest: de)
;@ path: gfx/tiles
;@ Copies one tile upside down: its rows from the last one up, `end` being the
;@ tile's address + 17 (CopyTilesMode, mode 2).
;@ test: mem[0xFF40] &= 0x7F; end = rand_ram(0x20) + 17; dest = rand_ram(0x20)
;@ sig: 219eaa21
CopyTileFlipV::
;> for row in range(8):
	ld b, $08

jr_000_1051:
;>     p = u16(end - 3 - 2 * row)
	dec hl
	dec hl
	dec hl
;>     WaitVRAM()
;>     mem[u16(dest + 2 * row)] = mem[p]                # the low plane
	ld a, [hl]
	call WaitVRAM
	ld [de], a
	inc de
;>     WaitVRAM()
;>     mem[u16(dest + 2 * row + 1)] = mem[u16(p + 1)]   # the high plane
	inc hl
	ld a, [hl]
	call WaitVRAM
	ld [de], a
	inc de
	dec b
	jr nz, jr_000_1051

;> return
	ret


;@ def ReverseBits(value: a) -> a
;@ path: gfx/tiles
;@ Reverses the order of the 8 bits of `value`: a mirrored row of pixels.
;@ sig: 609b7c8a
ReverseBits::
;> out = 0
	ld b, $08
	ld c, $00

;> for i in range(8):
;>     out |= ((value >> i) & 1) << (7 - i)
jr_000_1069:
	rla
	rr c
	dec b
	jr nz, jr_000_1069

;> return out
	ld a, c
	ret


;@ def CopyTileFlipHV(end: hl, dest: de)
;@ path: gfx/tiles
;@ Copies one tile upside down and mirrored, `end` being the tile's address + 17
;@ (CopyTilesMode, mode 6).
;@ test: mem[0xFF40] &= 0x7F; end = rand_ram(0x20) + 17; dest = rand_ram(0x20)
;@ sig: f62fdf65
CopyTileFlipHV::
;> for row in range(8):
	ld b, $08

jr_000_1073:
;>     p = u16(end - 3 - 2 * row)
	dec hl
	dec hl
	dec hl
;>     b = ReverseBits(mem[p])
	ld a, [hl]
	push bc
	call ReverseBits
	pop bc
;>     WaitVRAM()
;>     mem[u16(dest + 2 * row)] = b
	call WaitVRAM
	ld [de], a
	inc de
;>     b = ReverseBits(mem[u16(p + 1)])
	inc hl
	ld a, [hl]
	push bc
	call ReverseBits
	pop bc
;>     WaitVRAM()
;>     mem[u16(dest + 2 * row + 1)] = b
	call WaitVRAM
	ld [de], a
	inc de
	dec b
	jr nz, jr_000_1073

;> return
	ret


;@ def TilesToBytes(count: bc) -> bc
;@ path: gfx/tiles
;@ The size of `count` tiles in bytes (16 a tile).
;@ sig: a72a11eb
TilesToBytes::
;> return u16(count * 16)
	push hl
	ld l, c
	ld h, b
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld c, l
	ld b, h
	pop hl
	ret


;@ def ShowPalcomScreen()
;@ path: title/palcom
;@ The first screen: the KONAMI logo and the licence lines, scrolled to the top
;@ left; wScreenTimer counts its 256 frames.
;@ writes: wScreenTimer
;@ sig: feb53437
ShowPalcomScreen::
;> rSCY = rSCX = 0
	ld hl, $ff42
	ld [hl], $00
	inc hl
	ld [hl], $00
;> wScreenTimer = 0
	xor a
	ld [wScreenTimer], a
;> CopyBytes(PalcomLogoTiles, 0x9400, 0x1D0)       # 29 tiles from BG tile $40
	ld hl, PalcomLogoTiles
	ld de, $9400
	ld bc, $01d0
	call CopyBytes
;> DrawPackedTiles(PalcomScreenMap)
	ld de, PalcomScreenMap
	call DrawPackedTiles
;> return DrawStrings(LicenseText)
	ld de, LicenseText
	jp DrawStrings


;@ def TickScreenTimer() -> (a, zero)
;@ path: title/palcom
;@ Counts wScreenTimer down by one; zero when the KONAMI screen's time is up.
;@ writes: wScreenTimer
;@ reads: wScreenTimer
;@ sig: f209d087
TickScreenTimer::
;> wScreenTimer = u8(wScreenTimer - 1)
	ld a, [wScreenTimer]
	dec a
	ld [wScreenTimer], a
;> return wScreenTimer, wScreenTimer == 0
	ret


;@ asset: tiles bpp=2 length=$1D0
;@ The KONAMI logo of the first screen: 29 tiles, copied to $9400 by ShowPalcomScreen.
PalcomLogoTiles::
	db $03, $00, $0f, $0c, $0f, $0c, $0f, $0c, $1f, $18, $1f, $18, $1f, $18, $1f, $18
	db $fc, $00, $ff, $00, $ff, $00, $ff, $30, $ff, $78, $ff, $78, $9f, $10, $ff, $00
	db $07, $00, $1f, $10, $bf, $30, $bf, $20, $ff, $60, $ff, $44, $ff, $84, $ff, $8c
	db $81, $00, $87, $06, $87, $06, $87, $06, $cf, $0c, $cf, $0c, $cf, $0c, $cf, $0c
	db $f0, $00, $e0, $00, $e0, $00, $e0, $00, $c1, $01, $c1, $01, $c3, $03, $c3, $03
	db $07, $00, $3f, $20, $7f, $40, $ff, $83, $ff, $87, $f9, $01, $f1, $01, $f0, $00
	db $c0, $00, $f0, $00, $f8, $00, $fb, $82, $fb, $82, $ff, $fc, $ff, $fc, $0f, $0c
	db $1f, $00, $7f, $00, $ff, $00, $ff, $0e, $ff, $1f, $e3, $03, $c1, $01, $c1, $01
	db $81, $00, $c7, $06, $e7, $04, $e7, $04, $f7, $04, $ff, $0c, $ff, $08, $ff, $08
	db $f0, $00, $f3, $03, $f7, $06, $f7, $06, $ff, $0c, $ff, $0c, $ff, $48, $ff, $48
	db $fc, $00, $fc, $00, $fc, $00, $f8, $00, $f8, $00, $f8, $00, $f8, $80, $f0, $80
	db $e9, $e9, $4f, $4f, $49, $49, $49, $49, $00, $00, $00, $00, $00, $00, $00, $00
	db $3f, $30, $3f, $30, $3f, $30, $3f, $30, $7e, $60, $7e, $60, $7c, $7c, $7c, $7c
	db $ff, $01, $fb, $03, $f7, $f6, $07, $04, $0f, $0c, $1f, $18, $1f, $1f, $3e, $3e
	db $ff, $0c, $ff, $00, $ff, $00, $ff, $00, $ff, $3e, $ff, $7e, $07, $07, $07, $07
	db $df, $18, $ff, $18, $ff, $18, $ff, $18, $ff, $10, $ff, $10, $bf, $bf, $bf, $bf
	db $83, $03, $83, $03, $83, $03, $ff, $01, $fd, $01, $fd, $01, $f8, $f8, $f8, $f8
	db $f0, $00, $f0, $00, $f8, $00, $ff, $80, $ff, $80, $ff, $e0, $ff, $ff, $3e, $3e
	db $0f, $0c, $7f, $0c, $ff, $0c, $ff, $0e, $e7, $06, $c7, $47, $83, $83, $00, $00
	db $c1, $01, $c3, $02, $e7, $04, $ff, $00, $ff, $00, $ff, $81, $fe, $fe, $f8, $f8
	db $ff, $08, $ff, $18, $ff, $10, $df, $11, $bf, $31, $3f, $21, $79, $79, $79, $79
	db $ff, $c1, $ff, $c1, $ff, $c3, $ff, $c3, $ff, $c2, $ff, $c6, $e7, $e7, $c7, $c7
	db $f0, $00, $f0, $00, $f0, $00, $e0, $00, $e0, $00, $e0, $00, $80, $80, $80, $80
	db $00, $00, $38, $38, $41, $41, $32, $32, $8a, $8a, $71, $71, $00, $00, $00, $00
	db $00, $00, $c7, $c7, $24, $24, $2f, $2f, $48, $48, $88, $88, $00, $00, $00, $00
	db $00, $00, $bd, $bd, $11, $11, $11, $11, $21, $21, $21, $21, $00, $00, $00, $00
	db $00, $00, $24, $24, $29, $29, $52, $52, $e7, $e7, $48, $48, $00, $00, $00, $00
	db $00, $00, $9e, $9e, $92, $92, $bc, $bc, $a2, $a2, $a2, $a2, $00, $00, $00, $00
	db $00, $00, $78, $78, $40, $40, $f0, $f0, $80, $80, $f0, $f0, $00, $00, $00, $00


;@ asset: rlemap tiles=LoadFont+ShowPalcomScreen screen=1
;@ The KONAMI logo's tiles in BG map 0 (DrawTilemap format: an address, then runs).
PalcomScreenMap::
	db $c4, $98, $80, $40, $0c, $14, $7f, $80, $4c, $0b, $1a, $7f, $80, $57, $06, $00


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ The licence lines under the logo (PrintStrings format: an address, then characters; $FE takes a new address, $FF ends).
LicenseText::
	db $60, $99, $ef, $df, $e0, $e4, $de, $ec, $7f, $e3, $de, $dc, $ea, $d9, $df, $e2
	db $ed, $7f, $eb, $e3, $7f, $df, $fe, $80, $99, $ea, $e2, $df, $e6, $ed, $ec, $df
	db $e2, $e7, $7f, $de, $dc, $7f, $ef, $df, $e0, $e4, $de, $ec, $fe, $a0, $99, $e3
	db $de, $dc, $ea, $d9, $df, $e2, $ed, $7f, $e0, $eb, $ec, $eb, $ea, $ed, $e6, $cf
	db $ff

;@ def LoadFont()
;@ path: gfx/tiles
;@ Loads the font into VRAM (FontGfxList): the characters in two colours and a blank tile.
;@ sig: 2745776b
LoadFont::
;> return LoadTileList(FontGfxList)
	ld hl, FontGfxList
	jp LoadTileList


;@ LoadTileList entries for the font: the 1bpp characters as tiles $CE-$FA and again from $80 in another colour, and a blank tile $FF.
FontGfxList::
	db $4e, $61, $2d, $06, $03, $13, $ff, $61, $01, $06, $63, $14, $00, $61, $2c, $0e
	db $13, $13, $00, $00


;@ asset: tiles bpp=1 length=$168
;@ The font: 45 characters at 1 bit per pixel (expanded to 2bpp by CopyTilesMode, mode 3).
FontTiles::
	db $00, $00, $00, $00, $66, $66, $02, $04, $00, $00, $00, $00, $60, $60, $00, $00
	db $00, $00, $00, $00, $7f, $00, $00, $00, $3c, $66, $db, $a1, $a1, $db, $66, $3c
	db $30, $30, $60, $c0, $00, $00, $00, $00, $ff, $81, $81, $81, $81, $81, $81, $ff
	db $00, $1f, $06, $06, $06, $06, $66, $3c, $00, $00, $18, $18, $00, $18, $18, $00
	db $00, $7f, $07, $0e, $1c, $38, $70, $7f, $00, $66, $66, $7e, $3c, $18, $18, $18
	db $00, $63, $76, $3c, $1c, $1e, $37, $63, $00, $63, $63, $6b, $6b, $7f, $77, $22
	db $00, $63, $63, $63, $63, $36, $1c, $08, $00, $63, $63, $63, $7f, $63, $63, $63
	db $00, $7f, $60, $60, $7e, $60, $60, $60, $00, $3e, $63, $60, $67, $63, $63, $3f
	db $00, $3e, $63, $63, $63, $63, $63, $3e, $00, $1c, $36, $63, $63, $7f, $63, $63
	db $00, $60, $60, $60, $60, $60, $60, $7f, $00, $18, $18, $18, $18, $00, $18, $18
	db $00, $7e, $63, $63, $62, $7c, $66, $63, $00, $3e, $63, $60, $3e, $03, $63, $3e
	db $00, $3e, $63, $60, $60, $60, $63, $3e, $00, $7e, $63, $63, $7e, $63, $63, $7e
	db $00, $7c, $66, $63, $63, $63, $66, $7c, $00, $63, $66, $6c, $78, $7c, $6e, $67
	db $00, $73, $73, $7b, $7f, $6f, $67, $63, $00, $3e, $63, $63, $63, $7f, $63, $3d
	db $00, $7e, $18, $18, $18, $18, $18, $18, $00, $3c, $18, $18, $18, $18, $18, $3c
	db $00, $63, $77, $7f, $7f, $6b, $63, $63, $00, $7f, $60, $60, $7e, $60, $60, $7f
	db $00, $63, $63, $63, $63, $63, $63, $3e, $00, $7e, $63, $63, $63, $7e, $60, $60
	db $00, $1c, $22, $63, $63, $63, $22, $1c, $00, $18, $38, $18, $18, $18, $18, $7e
	db $00, $3e, $63, $03, $0e, $3c, $70, $7f, $00, $3e, $63, $03, $0e, $03, $63, $3e
	db $00, $0e, $1e, $36, $66, $66, $7f, $06, $00, $7f, $60, $7e, $63, $03, $63, $3e
	db $00, $3e, $63, $60, $7e, $63, $63, $3e, $00, $7f, $63, $06, $0c, $18, $18, $18
	db $00, $3e, $63, $63, $3e, $63, $63, $3e, $00, $3e, $63, $63, $3f, $03, $63, $3e
	db $00, $00, $00, $00, $00, $00, $00, $00

;@ def LoadTitleScreen()
;@ path: title
;@ Loads the title graphics and draws the title screen into BG map 0.
;@ sig: c479e840
LoadTitleScreen::
;> LoadTileList(TitleGfxList)
	ld hl, TitleGfxList
	call LoadTileList
;> return DrawPackedTiles(TitleScreenMap)
	ld de, TitleScreenMap
	jp DrawPackedTiles


;@ LoadTileList entries for the title screen: TitleLogoTiles from tile $80 at $9000, TitleExtraTiles as tiles $30-$34 at $8B00.
TitleGfxList::
	db $80, $61, $7f, $06, $dd, $14, $30, $61, $05, $06, $d5, $18, $00, $00


;@ asset: rlemap tiles=LoadFont+LoadTitleScreen screen=1
;@ The title screen in BG map 0 (DrawTilemap format).
TitleScreenMap::
	db $01, $98, $03, $7f, $80, $00, $0d, $81, $00, $10, $7f, $80, $0d, $10, $0f, $7f
	db $80, $1d, $0c, $80, $24, $02, $80, $29, $03, $0f, $7f, $80, $2c, $0c, $81, $33
	db $80, $38, $04, $0f, $7f, $81, $2c, $80, $3c, $05, $82, $32, $45, $80, $41, $09
	db $0f, $7f, $81, $2c, $80, $4a, $10, $0f, $7f, $83, $5a, $5b, $7f, $80, $5c, $0d
	db $14, $7f, $80, $69, $0a, $16, $7f, $80, $73, $0a, $16, $7f, $80, $7d, $02, $80
	db $b0, $04, $84, $5b, $b0, $b4, $7e, $00


;@ asset: tiles bpp=1 length=$3F8
;@ The MOTOCROSS MANIACS title graphics: 127 tiles at 1 bit per pixel.
TitleLogoTiles::
	db $00, $00, $00, $00, $03, $0d, $31, $c1, $00, $00, $00, $00, $00, $00, $01, $06
	db $00, $00, $00, $00, $18, $68, $88, $08, $00, $00, $00, $00, $00, $03, $0c, $30
	db $00, $00, $00, $00, $c0, $40, $40, $41, $00, $00, $00, $00, $06, $1a, $62, $82
	db $00, $00, $00, $00, $00, $00, $03, $0c, $00, $00, $00, $00, $30, $d0, $10, $10
	db $00, $00, $00, $00, $01, $06, $18, $60, $00, $00, $00, $00, $80, $80, $80, $83
	db $00, $00, $00, $00, $0c, $34, $c4, $04, $00, $00, $00, $00, $00, $01, $06, $18
	db $00, $00, $00, $00, $60, $a0, $20, $20, $00, $00, $00, $00, $03, $0c, $30, $c0
	db $03, $0c, $30, $c0, $00, $03, $0f, $0f, $01, $01, $01, $30, $f0, $f0, $f0, $f1
	db $18, $60, $80, $00, $0e, $3f, $ff, $ff, $08, $0b, $0c, $00, $00, $00, $01, $87
	db $c0, $00, $00, $06, $1e, $7e, $fe, $fe, $46, $58, $60, $00, $03, $0f, $3f, $7f
	db $02, $02, $03, $00, $80, $c0, $c1, $e3, $30, $c0, $00, $00, $1c, $7e, $fe, $ff
	db $11, $16, $18, $00, $00, $07, $1f, $7f, $80, $00, $00, $00, $c0, $f0, $f0, $f8
	db $8c, $b0, $c0, $00, $03, $0f, $3f, $7f, $04, $05, $06, $00, $80, $c0, $c1, $e3
	db $60, $80, $00, $00, $1c, $7e, $fe, $ff, $23, $2c, $30, $00, $00, $03, $0f, $1f
	db $01, $01, $01, $01, $e1, $f1, $f1, $f9, $03, $04, $04, $04, $04, $04, $04, $04
	db $00, $02, $0e, $3e, $ff, $ff, $ff, $ff, $0f, $1f, $1f, $1f, $1f, $1f, $1f, $3f
	db $f1, $f3, $f3, $f3, $f7, $f7, $f7, $f7, $ff, $ff, $ff, $ff, $ef, $cf, $cf, $cf
	db $9f, $bf, $bf, $bf, $bf, $bf, $bb, $a3, $fe, $fe, $f8, $e0, $e1, $e1, $e1, $e1
	db $7f, $ff, $ff, $ff, $fb, $f3, $f3, $f3, $e3, $e7, $e7, $e7, $ef, $ef, $ef, $ef
	db $ff, $ff, $ff, $ff, $df, $9f, $9f, $9c, $7f, $7f, $7e, $7c, $7c, $7c, $7c, $7c
	db $f8, $f8, $f8, $f8, $f9, $f9, $f9, $f9, $ff, $ff, $ff, $ff, $df, $9c, $90, $80
	db $1f, $3f, $3f, $3f, $7e, $7c, $7c, $7c, $f9, $f9, $f9, $f9, $f9, $e1, $81, $01
	db $04, $04, $04, $04, $04, $04, $04, $04, $ff, $ff, $ff, $ff, $ff, $ff, $fb, $fb
	db $bf, $bd, $bd, $bd, $bd, $fd, $f9, $f9, $f7, $f7, $f7, $f7, $f7, $f7, $f7, $f7
	db $cf, $cf, $cf, $cf, $cf, $cf, $cf, $cf, $83, $83, $83, $83, $83, $83, $83, $83
	db $e1, $e1, $e1, $e1, $e1, $e1, $e1, $e1, $f3, $f3, $f3, $f3, $f3, $f3, $f3, $f3
	db $ef, $ef, $ef, $ef, $ef, $ef, $ef, $ef, $90, $80, $80, $80, $81, $87, $9f, $9f
	db $7d, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $f9, $f1, $f1, $e1, $e1, $f1, $f1, $f1
	db $ef, $ef, $ef, $ef, $ef, $e7, $e7, $e3, $80, $bc, $fe, $fe, $ff, $ff, $ff, $df
	db $7c, $7d, $7f, $7f, $7f, $3f, $3f, $1e, $01, $e1, $f1, $f1, $f9, $f9, $f9, $f9
	db $fb, $fb, $f9, $f9, $f9, $f9, $f8, $f8, $f9, $f9, $f9, $f9, $f1, $f1, $f1, $f1
	db $f7, $f7, $f7, $f7, $f7, $f7, $f7, $c7, $cf, $cf, $cf, $cf, $df, $ff, $ff, $ff
	db $83, $83, $83, $83, $83, $83, $03, $03, $ef, $ef, $ef, $ef, $ef, $ef, $cf, $cf
	db $9f, $9f, $9f, $9f, $bf, $ff, $fe, $fe, $7d, $7d, $7d, $7d, $7c, $7c, $7c, $7c
	db $f9, $f9, $f9, $fd, $fd, $f9, $e1, $81, $f3, $f3, $f3, $f3, $f7, $ff, $ff, $ff
	db $e0, $e0, $e0, $e3, $ef, $ef, $cf, $cf, $1f, $1f, $9f, $9f, $bf, $ff, $fe, $fe
	db $00, $00, $04, $1c, $7d, $7f, $7f, $7f, $f9, $f9, $f9, $f9, $f9, $f9, $f1, $f1
	db $f8, $f8, $f8, $f8, $f8, $e0, $80, $01, $f1, $f0, $c0, $01, $06, $18, $60, $80
	db $07, $03, $63, $a1, $20, $20, $20, $20, $fe, $fe, $fc, $f0, $00, $00, $00, $00
	db $03, $03, $03, $02, $00, $00, $00, $00, $e1, $e0, $80, $00, $00, $00, $00, $c0
	db $ff, $ff, $ff, $7c, $00, $00, $00, $c0, $8f, $87, $07, $03, $00, $00, $00, $01
	db $fc, $fc, $f8, $e0, $00, $00, $00, $08, $7c, $7c, $70, $40, $00, $00, $00, $0c
	db $01, $00, $00, $00, $00, $00, $00, $07, $ff, $ff, $ff, $7c, $00, $00, $00, $03
	db $8f, $87, $07, $03, $00, $00, $00, $80, $fc, $fc, $f8, $e0, $00, $03, $0d, $31
	db $7f, $3f, $3f, $1f, $00, $00, $00, $00, $e1, $e1, $c1, $01, $03, $0c, $30, $c0
	db $04, $04, $04, $05, $06, $00, $00, $00, $06, $18, $60, $80, $00, $00, $00, $00
	db $20, $20, $23, $2c, $30, $00, $00, $00, $00, $c0, $40, $40, $43, $47, $47, $47
	db $03, $07, $07, $c7, $c7, $c7, $cf, $cf, $c3, $c7, $c7, $c7, $c7, $c7, $cf, $ce
	db $c0, $c0, $c3, $e3, $e3, $e3, $e3, $e3, $07, $c7, $c7, $c7, $e7, $e7, $e7, $f7
	db $38, $38, $38, $38, $38, $38, $38, $38, $3c, $7c, $7c, $7e, $7e, $7e, $fe, $ee
	db $1f, $1f, $3f, $3d, $39, $39, $39, $39, $8f, $8f, $df, $de, $dc, $dc, $dc, $1c
	db $c0, $c3, $e2, $e2, $e2, $82, $02, $02, $c1, $01, $01, $01, $01, $00, $00, $00
	db $03, $0c, $30, $c0, $00, $00, $00, $00, $47, $47, $47, $47, $47, $47, $47, $47
	db $ef, $ef, $ed, $ed, $fd, $7d, $7d, $7d, $ce, $ce, $ce, $ce, $ce, $cf, $df, $df
	db $f3, $f3, $73, $73, $f3, $fb, $fb, $bb, $f7, $f7, $ff, $bf, $bf, $bf, $9f, $9f
	db $38, $38, $38, $38, $38, $38, $39, $39, $ef, $ef, $e7, $e7, $ef, $ff, $ff, $fb
	db $38, $38, $38, $38, $39, $b9, $b9, $b9, $1d, $1f, $1f, $5f, $ce, $c0, $c0, $c4
	db $c2, $e2, $e2, $e2, $e2, $e2, $e2, $e2, $47, $47, $47, $47, $47, $47, $47, $44
	db $79, $79, $39, $38, $38, $21, $06, $18, $de, $dc, $1c, $1c, $1c, $98, $80, $80
	db $3b, $3b, $33, $03, $03, $03, $00, $30, $9f, $8f, $8e, $88, $80, $00, $00, $06
	db $39, $39, $39, $39, $39, $31, $00, $00, $e3, $c3, $c3, $c0, $c0, $80, $00, $01
	db $b9, $bb, $3f, $1f, $1f, $0e, $00, $80, $dc, $dd, $df, $8f, $8f, $07, $00, $00
	db $e2, $e2, $e2, $c2, $c2, $02, $06, $18, $40, $41, $46, $58, $60, $00, $00, $00
	db $60, $80, $00, $00, $00, $00, $00, $00


;@ asset: tiles bpp=1 length=$28
;@ Five more 1bpp title tiles (loaded as tiles $30-$34).
TitleExtraTiles::
	db $80, $83, $8c, $b0, $c0, $00, $00, $00, $d0, $10, $11, $16, $18, $00, $00, $00
	db $1a, $62, $82, $02, $03, $00, $00, $00, $00, $0c, $34, $c5, $06, $00, $00, $00
	db $c0, $41, $46, $58, $60, $00, $00, $00

;@ def UpdateBikeMode()
;@ path: bike/modes
;@ Runs the bike's behaviour for its mode (wBikeMode) once a frame: 0 standing,
;@ 1 riding, 2 in the air, 3 on the back wheel, 4 falling, 5 going over backwards,
;@ 6 in a pit, 7 waiting at the start, 8 crashed. CheckBikeGround then looks at the
;@ ground for the same mode.
;@ reads: wBikeMode
;@ test: wBikeMode = rand(0, 8); wJumpKind = rand(0, 4)
;@ sig: 1b583734
UpdateBikeMode::
;> return BikeModeHandlers[wBikeMode]()
	ld a, [wBikeMode]
	call JumpTable

BikeModeHandlers::
	dw BikeStanding
	dw BikeRiding
	dw BikeInAir
	dw BikeWheelie
	dw BikeFalling
	dw BikeFlipping
	dw BikeInPit
	dw BikeAtStart
	dw BikeCrashed

;@ def BikeStanding()
;@ path: bike/modes
;@ Mode 0: the bike stands still until it has some speed, then it rides (mode 1).
;@ writes: wBikeMode, wBikeSpeedBonus
;@ reads: wBikeSpeed, wProbeKinds
;@ sig: 5cc14fd0
BikeStanding::
;> if wProbeKinds[1] & 0x40: wBikeSpeedBonus = 0xC8    # ground that holds the bike back
	ld a, [wProbeKinds + 1]
	bit 6, a
	jr z, jr_000_1921

	ld a, $c8
	ld [wBikeSpeedBonus], a

;> if not wBikeSpeed: return
jr_000_1921:
	ld a, [wBikeSpeed]
	and a
	ret z

;> wBikeMode = 1
;> return
	ld a, $01
	ld [wBikeMode], a
	ret


;@ def BikeRiding()
;@ path: bike/modes
;@ Mode 1, on the ground: on level ground Left lifts the front wheel (mode 3) when
;@ nothing is above it; then the slope speeds the bike up or slows it down.
;@ writes: wBikeMode, wBikeSpeedBonus
;@ reads: wBikeHeld, wBikeMoveAngle, wProbeKinds
;@ sig: f37eadd2
BikeRiding::
;> if wBikeMoveAngle or wProbeKinds[1] & 0x20: return UpdateSlopeBonus()
	ld a, [wBikeMoveAngle]
	and a
	jr nz, jr_000_195f

	ld a, [wProbeKinds + 1]
	bit 5, a
	jr nz, jr_000_195f

;> if wBikeHeld & BTN_LEFT and not wProbeKinds[8] & 0x80 and not wProbeKinds[10] & 0x80:
	ld a, [wBikeHeld]
	and $02
	jr z, jr_000_1953

	ld a, [wProbeKinds + 8]
	bit 7, a
	jr nz, jr_000_1953

	ld a, [wProbeKinds + 10]
	bit 7, a
	jr nz, jr_000_1953

;>     wBikeMode = 3                               # up on the back wheel
	ld a, $03
	ld [wBikeMode], a

jr_000_1953:
;> if wProbeKinds[1] & 0x40: wBikeSpeedBonus = 0xC8    # ground that holds the bike back
	ld a, [wProbeKinds + 1]
	bit 6, a
	jr z, jr_000_195f

	ld a, $c8
	ld [wBikeSpeedBonus], a

;> return UpdateSlopeBonus()
jr_000_195f:
	jp UpdateSlopeBonus


;@ def BikeInAir()
;@ path: bike/modes
;@ Mode 2, in the air: the buttons tilt the bike, the throttle runs down and the
;@ path bends towards straight down ($18), how fast set by JumpPhysics for the way
;@ the bike took off.
;@ writes: wBikeMoveAngle, wBikeThrottle, wNitroFlame, wTakeOffFrame
;@ reads: wBikeCrash, wBikeMoveAngle, wBikeThrottle, wFrameCounter, wJumpKind, wNitroFlame, wTakeOffFrame
;@ test: wJumpKind = rand(0, 4)
;@ sig: 02f46aee
BikeInAir::
;> if not wBikeCrash: TiltFromButtons()
	ld a, [wBikeCrash]
	and a
	call z, TiltFromButtons
;> if wNitroFlame:
	ld a, [wNitroFlame]
	and a
	jr z, jr_000_1974

;>     wNitroFlame -= 1
;>     return
	dec a
	ld [wNitroFlame], a
	ret


jr_000_1974:
;> if wTakeOffFrame:
	ld a, [wTakeOffFrame]
	and a
	jr z, jr_000_197e

;>     wTakeOffFrame -= 1
	dec a
	ld [wTakeOffFrame], a

jr_000_197e:
;> if wBikeCrash >= 2: CrashSpin()
	ld a, [wBikeCrash]
	cp $02
	call nc, CrashSpin
;> row = u16(JumpPhysics + u8(3 * wJumpKind))
	ld a, [wJumpKind]
	ld hl, JumpPhysics
	ld c, a
	add a
	add c
	rst $28
;> throttle = wBikeThrottle if wBikeThrottle >= 0x20 else 0x22
	ld a, [wBikeThrottle]
	cp $20
	jr nc, jr_000_1999

	ld a, $22

;> wBikeThrottle = u8(throttle - mem[row])
jr_000_1999:
	sub [hl]
	ld [wBikeThrottle], a
;> if wFrameCounter & mem[u16(row + 1)]: return
	inc hl
	ld a, [wFrameCounter]
	and [hl]
	ret nz

;> a = wBikeMoveAngle
;> if 9 <= a < 0x19:                                # pointing down: turn on to straight down
	inc hl
	ld a, [wBikeMoveAngle]
	cp $09
	jr c, jr_000_19bc

	cp $19
	jr nc, jr_000_19bc

;>     a = wBikeMoveAngle = u8(a + mem[u16(row + 2)])
;>     if a < 0x18: return
	add [hl]
	ld [wBikeMoveAngle], a
	cp $18
	ret c

;>     wBikeMoveAngle = 0x18
;>     return
	ld a, $18
	ld [wBikeMoveAngle], a
	ret


;> if 9 <= a < 0x1B: return
jr_000_19bc:
	cp $09
	jr c, jr_000_19c3

	cp $1b
	ret c

;> a = wBikeMoveAngle = u8(a - mem[u16(row + 2)])  # pointing up: turn the other way round
;> if not a & 0x80: return
jr_000_19c3:
	sub [hl]
	ld [wBikeMoveAngle], a
	ld c, a
	rla
	ret nc

;> wBikeMoveAngle = u8(a + 0x20)
;> return
	ld a, $20
	add c
	ld [wBikeMoveAngle], a
	ret


;@ For each wJumpKind, 3 bytes: how much throttle the bike loses a frame in the air, the frame mask for turning its path down (0 = every frame), and how far it turns.
JumpPhysics::
	db $08, $00, $02, $04, $01, $01, $04, $01, $01, $04, $01, $01, $02, $03, $01

;@ def BikeWheelie()
;@ path: bike/modes
;@ Mode 3, on the back wheel: while Left is held on level ground the front rises one
;@ step every other frame; past upright (8) the bike goes over (mode 5). Without
;@ Left it comes back down to the ground's angle and rides on (mode 1).
;@ writes: wBikeAngle, wBikeMode, wBikeSpeedBonus
;@ reads: wBikeAngle, wBikeCrash, wBikeHeld, wBikeMoveAngle, wFrameCounter, wProbeKinds
;@ sig: 66ae69fa
BikeWheelie::
;> if wProbeKinds[1] & 0x40: wBikeSpeedBonus = 0xC8    # ground that holds the bike back
	ld a, [wProbeKinds + 1]
	bit 6, a
	jr z, jr_000_19ec

	ld a, $c8
	ld [wBikeSpeedBonus], a

;> if wBikeHeld & BTN_LEFT and not wBikeCrash:
jr_000_19ec:
	ld a, [wBikeHeld]
	and $02
	jr z, jr_000_1a13

	ld a, [wBikeCrash]
	and a
	jr nz, jr_000_1a13

;>     if wBikeMoveAngle: return
	ld a, [wBikeMoveAngle]
	and a
	ret nz

;>     if wFrameCounter & 1: return
	ld a, [wFrameCounter]
	rra
	ret c

;>     wBikeAngle = u8(wBikeAngle + 1)
;>     if wBikeAngle < 8: return
	ld a, [wBikeAngle]
	inc a
	ld [wBikeAngle], a
	cp $08
	ret c

;>     wBikeMode = 5                               # past upright: over it goes
;>     return
	ld a, $05
	ld [wBikeMode], a
	ret


;> if wBikeAngle != wBikeMoveAngle:
jr_000_1a13:
	ld a, [wBikeMoveAngle]
	ld c, a
	ld a, [wBikeAngle]
	cp c
	jr z, jr_000_1a23

;>     wBikeAngle = u8(wBikeAngle - 1)
;>     if wBikeAngle != wBikeMoveAngle: return
	dec a
	ld [wBikeAngle], a
	cp c
	ret nz

;> wBikeMode = 1
;> return
jr_000_1a23:
	ld a, $01
	ld [wBikeMode], a
	ret


;@ def BikeFalling()
;@ path: bike/modes
;@ Mode 4, falling: nothing to do here (the movement code lets the bike drop).
;@ sig: 30ba9599
BikeFalling::
;> return
	ret


;@ def BikeFlipping()
;@ path: bike/modes
;@ Mode 5, going over backwards: the bike turns two steps a frame, with a sound
;@ every 8 frames.
;@ reads: wFrameCounter
;@ sig: 7d0aea18
BikeFlipping::
;> TiltForward()
;> TiltForward()
	call TiltForward
	call TiltForward
;> if wFrameCounter & 7: return
	ld a, [wFrameCounter]
	and $07
	ret nz

;> return PlayBikeSound(0x14)
	ld a, $14
	jp PlayBikeSound


;@ def BikeInPit()
;@ path: bike/modes
;@ Mode 6, fallen into a pit: the crash code takes over and a life is lost.
;@ writes: wBikeAngle, wBikeCrash, wBikeLives
;@ reads: wBikeLives
;@ sig: 1638d1b4
BikeInPit::
;> wBikeCrash = 4
	ld a, $04
	ld [wBikeCrash], a
;> wBikeLives = u8(wBikeLives - 1)
	ld a, [wBikeLives]
	dec a
	ld [wBikeLives], a
;> wBikeAngle = 4
;> return
	ld a, $04
	ld [wBikeAngle], a
	ret


;@ def BikeAtStart()
;@ path: bike/modes
;@ Mode 7, on the start line: the idling engine shakes the bike up and down a pixel.
;@ writes: wBikeY
;@ reads: wBikeY
;@ sig: 5268de43
BikeAtStart::
;> wBikeY ^= 0x0100
;> return
	ld a, [wBikeY + 1]
	xor $01
	ld [wBikeY + 1], a
	ret


;@ def BikeCrashed()
;@ path: bike/modes
;@ Mode 8, crashed: CrashAnimation plays the crash from wCrashTimer; when it runs out
;@ the bike stands again, still, on a tile row.
;@ writes: wBikeAngle, wBikeMode, wBikeMoveAngle, wBikeSpeed, wBikeY
;@ reads: wBikeY
;@ sig: ffeea8a8
BikeCrashed::
;> wCrashTimer = u8(wCrashTimer - 1)
	ld hl, wCrashTimer
	dec [hl]
;>@ca if wCrashTimer: return CrashAnimation()
	jp nz, Jump_000_1a73

;> wBikeSpeed = wBikeMode = wBikeMoveAngle = wBikeAngle = 0
	xor a
	ld [wBikeSpeed], a
	ld [wBikeMode], a
	ld [wBikeMoveAngle], a
	ld [wBikeAngle], a
;> wBikeY &= 0xF8FF
;> return
	ld a, [wBikeY + 1]
	and $f8
	ld [wBikeY + 1], a
	ret


Jump_000_1a73:
;=@ca
	jp CrashAnimation


;@ def CheckBikeGround()
;@ path: bike/ground
;@ Checks the ground around the bike for its mode (wProbeKinds: bit 7 = ground at
;@ that test point, bits 0-4 its angle): whether it takes off, lands, falls or
;@ crashes.
;@ reads: wBikeMode
;@ test: wBikeMode = rand(0, 8)
;@ sig: 1b583734
CheckBikeGround::
;> return BikeGroundHandlers[wBikeMode]()
	ld a, [wBikeMode]
	call JumpTable

BikeGroundHandlers::
	dw GroundStanding
	dw GroundRiding
	dw GroundInAir
	dw GroundWheelie
	dw GroundFalling
	dw GroundFlipping
	dw GroundInPit
	dw GroundAtStart
	dw GroundCrashed

;@ def GroundStanding()
;@ path: bike/ground
;@ Mode 0: a bike standing on a slope steeper than upright falls.
;@ reads: wBikeMoveAngle
;@ sig: 578d842d
GroundStanding::
;> if 9 <= wBikeMoveAngle < 0x18: return FallOrCrash()
;> return
	ld a, [wBikeMoveAngle]
	cp $09
	ret c

	cp $18
	ret nc

	jp FallOrCrash


;@ def GroundRiding()
;@ path: bike/ground
;@ Mode 1: a crashing bike low enough in the level drops into a pit (mode 6). Else
;@ the bike follows the ground under it, or takes off when the ground ends.
;@ writes: wBikeAngle, wBikeMode, wBikeMoveAngle
;@ reads: wBikeCrash, wBikeMoveAngle, wBikeX, wBikeY, wProbeKinds
;@ sig: 6094b73e
GroundRiding::
;> if wBikeCrash >= 2 and hi(wBikeY) >= 0xE0 and not wBikeX[2] & 0x0F:
	ld a, [wBikeCrash]
	cp $02
	jr c, jr_000_1ab5

	ld a, [wBikeY + 1]
	cp $e0
	jr c, jr_000_1ab5

	ld a, [wBikeX + 2]
	and $0f
	jr nz, jr_000_1ab5

;>     wBikeMode = 6                               # down a pit
;>     return
	ld a, $06
	ld [wBikeMode], a
	ret


jr_000_1ab5:
;> CheckTileEF()                                   # may leave GroundRiding at once
	call CheckTileEF
;> k = wProbeKinds[2]
;> if k & 0x80:                                    # ground under the bike: follow its angle
	ld a, [wProbeKinds + 2]
	bit 7, a
	jr z, jr_000_1adc

;>     k &= 0x1F
;>     if not (8 <= wBikeMoveAngle < 0x10 and k < 8):
	and $1f
	ld c, a
	ld a, [wBikeMoveAngle]
	cp $08
	jr c, jr_000_1ad2

	cp $10
	jr nc, jr_000_1ad2

	ld a, c
	cp $08
	jr c, jr_000_1adc

jr_000_1ad2:
;>         wBikeAngle = wBikeMoveAngle = k
;>         return SnapToGrid(k)
	ld a, c
	ld [wBikeAngle], a
	ld [wBikeMoveAngle], a
	jp SnapToGrid


jr_000_1adc:
;> if wBikeMoveAngle == 0:
	ld a, [wBikeMoveAngle]
	and a
	jr nz, jr_000_1aeb

;>     if wProbeKinds[1] & 0x80: return
;>     return TakeOff()
	ld a, [wProbeKinds + 1]
	bit 7, a
	ret nz

	jp TakeOff


jr_000_1aeb:
;> if wBikeMoveAngle == 4 and wProbeKinds[3] & 0x80: return
	cp $04
	jr nz, jr_000_1af5

	ld a, [wProbeKinds + 3]
	bit 7, a
	ret nz

jr_000_1af5:
;> if wProbeKinds[0] & 0x80 or wProbeKinds[1] & 0x80: return
	ld a, [wProbeKinds]
	bit 7, a
	ret nz

	ld a, [wProbeKinds + 1]
	bit 7, a
	ret nz

;> return TakeOff()
	jp TakeOff


;@ def GroundInAir()
;@ path: bike/ground
;@ Mode 2: level ground or a $1C slope at the top test points means the bike hit
;@ something (FallOrCrash). Ground at the wheels lands it, if CheckLandingAngle
;@ accepts the bike's angle for that ground; then it rides on (mode 1).
;@ writes: wBikeAngle, wBikeMode, wBikeMoveAngle
;@ reads: wProbeKinds
;@ sig: b4940537
GroundInAir::
;> for k in (wProbeKinds[8], wProbeKinds[9]):
;>     if k & 0x80 and k & 0x1F in (0, 0x1C): return FallOrCrash()
	ld a, [wProbeKinds + 8]
	bit 7, a
	jr z, jr_000_1b13

	and $1f
	jr z, jr_000_1b22

	cp $1c
	jr z, jr_000_1b22

jr_000_1b13:
	ld a, [wProbeKinds + 9]
	bit 7, a
	jr z, jr_000_1b25

	and $1f
	jr z, jr_000_1b22

	cp $1c
	jr nz, jr_000_1b25

jr_000_1b22:
	jp FallOrCrash


jr_000_1b25:
;> if wProbeKinds[7] & 0x80: k = wProbeKinds[7]
;> elif wProbeKinds[6] & 0x80: k = wProbeKinds[6]
;> elif wProbeKinds[2] & 0x80: k = wProbeKinds[2]
;> else: return
	ld a, [wProbeKinds + 7]
	bit 7, a
	jr nz, jr_000_1b39

	ld a, [wProbeKinds + 6]
	bit 7, a
	jr nz, jr_000_1b39

	ld a, [wProbeKinds + 2]
	bit 7, a
	ret z

jr_000_1b39:
;> angle, bad = CheckLandingAngle(k & 0x1F)
;> if bad: return FallOrCrash()
	and $1f
	call CheckLandingAngle
	jp c, FallOrCrash

;> wBikeMoveAngle = wBikeAngle = angle & 0x1F
	and $1f
	ld [wBikeMoveAngle], a
	ld [wBikeAngle], a
;> SnapToGrid(angle & 0x1F)
	call SnapToGrid
;> wBikeMode = 1
;> return
	ld a, $01
	ld [wBikeMode], a
	ret


;@ def GroundWheelie()
;@ path: bike/ground
;@ Mode 3: when the ground under the bike (or under its back wheel, once the front
;@ is up 3 steps) is found, the bike rides on at that angle; with no ground at all
;@ it takes off.
;@ writes: wBikeAngle, wBikeMode, wBikeMoveAngle
;@ reads: wBikeAngle, wProbeKinds
;@ sig: f49f1c3f
GroundWheelie::
;> k = wProbeKinds[2]
;> if k & 0x80:
	ld a, [wProbeKinds + 2]
	bit 7, a
	jr z, jr_000_1b67

;>     wBikeMoveAngle = wBikeAngle = k & 0x1F
	and $1f
	ld [wBikeMoveAngle], a
	ld [wBikeAngle], a
;>     wBikeMode = 1
;>     return
	ld a, $01
	ld [wBikeMode], a
	ret


jr_000_1b67:
;> if not wProbeKinds[1] & 0x80: return TakeOff()
	ld a, [wProbeKinds + 1]
	bit 7, a
	jp z, TakeOff

;> if wBikeAngle < 3: return
	ld a, [wBikeAngle]
	cp $03
	ret c

;> k = wProbeKinds[6]
;> if not k & 0x80: return
	ld a, [wProbeKinds + 6]
	bit 7, a
	ret z

;> wBikeMoveAngle = wBikeAngle = k & 0x1F
	and $1f
	ld [wBikeMoveAngle], a
	ld [wBikeAngle], a
;> wBikeMode = 1
;> return
	ld a, $01
	ld [wBikeMode], a
	ret


;@ def GroundFalling()
;@ path: bike/ground
;@ Mode 4: when a wheel finds ground the bike is set on it (mode 5).
;@ writes: wBikeMode
;@ reads: wProbeKinds
;@ sig: 2586ec2d
GroundFalling::
;> if wProbeKinds[4] & 0x80: k = wProbeKinds[4]
;> elif wProbeKinds[5] & 0x80: k = wProbeKinds[5]
;> else: return
	ld a, [wProbeKinds + 4]
	bit 7, a
	jr nz, jr_000_1b96

	ld a, [wProbeKinds + 5]
	bit 7, a
	ret z

jr_000_1b96:
;> SnapToGrid(k & 0x1F)
	and $1f
	call SnapToGrid
;> wBikeMode = 5
;> return
	ld a, $05
	ld [wBikeMode], a
	ret


;@ def GroundFlipping()
;@ path: bike/ground
;@ Mode 5: without ground at either wheel the bike falls or crashes. Ground under it
;@ turns it to that angle; on level ground with both wheels down, upright or
;@ upside down, it crashes (mode 8).
;@ writes: wBikeMode, wBikeMoveAngle, wCrashSide, wCrashTimer, wLandDelay, wLastMoveAngle
;@ reads: wBikeMoveAngle, wLandDelay, wLastMoveAngle, wProbeKinds
;@ sig: 95b286c6
GroundFlipping::
;> if not (wProbeKinds[4] & 0x80 or wProbeKinds[5] & 0x80): return FallOrCrash()
	ld a, [wProbeKinds + 4]
	bit 7, a
	jr nz, jr_000_1bb2

	ld a, [wProbeKinds + 5]
	bit 7, a
	jr nz, jr_000_1bb2

	jp FallOrCrash


jr_000_1bb2:
;> k = wProbeKinds[2]
;> if k & 0x80:
	ld a, [wProbeKinds + 2]
	bit 7, a
	jr z, jr_000_1bef

;>     c = k & 0x1F
;>     if c < 9: c += 0x20                         # (so never 0)
	and $1f
	cp $09
	jr nc, jr_000_1bc1

	add $20

jr_000_1bc1:
;>     if wBikeMoveAngle & 0x1F:
	ld c, a
	ld a, [wBikeMoveAngle]
	and $1f
	jr nz, jr_000_1bd2

	ld a, c
	and a
	jr z, jr_000_1bd8

	ld a, [wBikeMoveAngle]
	jr jr_000_1bfa

jr_000_1bd2:
;>         wLastMoveAngle = wBikeMoveAngle
	ld a, [wBikeMoveAngle]
	ld [wLastMoveAngle], a

jr_000_1bd8:
;>         if c & 0x1F == 0 and not wLastMoveAngle & 0x20: c = 0
	ld a, c
	and $1f
	jr nz, jr_000_1be6

	ld a, [wLastMoveAngle]
	and $20
	jr nz, jr_000_1be6

	ld c, $00

jr_000_1be6:
;>         wBikeMoveAngle = c
;>         return SnapToGrid(c & 0x1F)
	ld a, c
	ld [wBikeMoveAngle], a
	and $1f
	jp SnapToGrid


jr_000_1bef:
;> elif wLandDelay:
	ld a, [wLandDelay]
	and a
	jr z, jr_000_1bfa

;>     wLandDelay -= 1
;>     return
	dec a
	ld [wLandDelay], a
	ret


jr_000_1bfa:
;> if not wProbeKinds[4] & 0x80 or wProbeKinds[4] & 0x1F: return
	ld a, [wProbeKinds + 4]
	bit 7, a
	ret z

	and $1f
	ret nz

;> if not wProbeKinds[5] & 0x80 or wProbeKinds[5] & 0x1F: return
	ld a, [wProbeKinds + 5]
	bit 7, a
	ret z

	and $1f
	ret nz

;> a = wBikeMoveAngle
;> if a not in (0, 0x20): return
	ld a, [wBikeMoveAngle]
	and a
	jr z, jr_000_1c15

	cp $20
	ret nz

jr_000_1c15:
;> wCrashSide = 1 if a & 0x20 else 0
	ld c, a
	and $20
	ld a, $00
	jr z, jr_000_1c1d

	inc a

jr_000_1c1d:
	ld [wCrashSide], a
;> SnapToGrid(a & 0x1F)
	ld a, c
	and $1f
	call SnapToGrid
;> wBikeMode = 8
	ld a, $08
	ld [wBikeMode], a
;> wCrashTimer = 0x39
	ld a, $39
	ld [wCrashTimer], a
;> return PlayBikeSound(0x16)
	ld a, $16
	jp PlayBikeSound


;@ def GroundInPit()
;@ path: bike/ground
;@ Mode 6: nothing to check.
;@ sig: 30ba9599
GroundInPit::
;> return
	ret


;@ def GroundAtStart()
;@ path: bike/ground
;@ Mode 7: nothing to check.
;@ sig: 30ba9599
GroundAtStart::
;> return
	ret


;@ def GroundCrashed()
;@ path: bike/ground
;@ Mode 8: nothing to check.
;@ sig: 30ba9599
GroundCrashed::
;> return
	ret


;@ def CheckTileEF()
;@ path: bike/ground
;@ On level ground, over tile $EF at test point 9: the bike is turned to $20
;@ (LandAtAngle) and may not lift its front for 8 frames, or, for the computer's
;@ bike in some modes, pointed slightly up (4). Either way its caller ends too.
;@ writes: wBikeMoveAngle, wLandDelay
;@ reads: wBikeId, wBikeMoveAngle, wProbeTiles
;@ test: skip drops its caller's return address
;@ sig: ef21a897
CheckTileEF::
;> if wBikeMoveAngle: return
	ld a, [wBikeMoveAngle]
	and a
	ret nz

;> if wProbeTiles[9] != 0xEF: return
	ld a, [wProbeTiles + 9]
	cp $ef
	ret nz

;> if not IsComRace() or wBikeId == 1:
	call IsComRace
	jr nz, jr_000_1c4e

	ld a, [wBikeId]
	dec a
	jr nz, jr_000_1c59

jr_000_1c4e:
;>     wLandDelay = 8
	ld a, $08
	ld [wLandDelay], a
;>     pop_return_address()                        # the caller ends here too
;>     return LandAtAngle(0x20)
	pop hl
	ld a, $20
	jp LandAtAngle


jr_000_1c59:
;> wBikeMoveAngle = 4
	ld a, $04
	ld [wBikeMoveAngle], a
;> pop_return_address()
;> return
	pop hl
	ret


;@ def UpdateSlopeBonus()
;@ path: bike/physics
;@ On a slope the speed bonus builds up by 2 a frame: down to -$20 going up
;@ (angles 1-7), up to +$20 going down ($18-$1F); level ground clears it. With
;@ wPowerUpA the slopes don't matter.
;@ writes: wBikeSpeedBonus, wSlopeBonus
;@ reads: wBikeMoveAngle, wPowerUpA, wSlopeBonus
;@ sig: 83028dbe
UpdateSlopeBonus::
;> if wPowerUpA: return
	ld a, [wPowerUpA]
	and a
	ret nz

;> a = wBikeMoveAngle
;> if a == 0:
;>@z1     wSlopeBonus = 0
;>@z2     return
	ld a, [wBikeMoveAngle]
	and a
	jr z, jr_000_1c74

;> if a < 8:
;>@up     if not (wSlopeBonus & 0x80 and wSlopeBonus < 0xE0): wSlopeBonus = u8(wSlopeBonus - 2)
;>@up2     wBikeSpeedBonus = wSlopeBonus
;>@up3     return
	cp $08
	jr c, jr_000_1c79

;> if a >= 0x18:
;>@dn     if wSlopeBonus & 0x80 or wSlopeBonus < 0x20: wSlopeBonus = u8(wSlopeBonus + 2)
;>@dn2     wBikeSpeedBonus = wSlopeBonus
;>@dn3     return
	cp $18
	jr nc, jr_000_1c8d

;> return
	ret


jr_000_1c74:
;=@z1
	xor a
	ld [wSlopeBonus], a
;=@z2
	ret


jr_000_1c79:
;=@up
	ld a, [wSlopeBonus]
	bit 7, a
	jr z, jr_000_1c84

	cp $e0
	jr c, jr_000_1c89

jr_000_1c84:
	sub $02
	ld [wSlopeBonus], a

jr_000_1c89:
;=@up2
	ld [wBikeSpeedBonus], a
;=@up3
	ret


jr_000_1c8d:
;=@dn
	ld a, [wSlopeBonus]
	bit 7, a
	jr nz, jr_000_1c98

	cp $20
	jr nc, jr_000_1c9d

jr_000_1c98:
	add $02
	ld [wSlopeBonus], a

jr_000_1c9d:
;=@dn2
	ld [wBikeSpeedBonus], a
;=@dn3
	ret


;@ def TakeOff()
;@ path: bike/physics
;@ The ground has ended: the bike is in the air (mode 2). wJumpKind is 0 or 2 from
;@ the throttle, +1 with Up held, 4 when crashing.
;@ writes: wBikeMode, wJumpKind, wNitroFlame, wNitroTimer, wTakeOffFrame
;@ reads: wBikeCrash, wBikeHeld, wBikeThrottle
;@ sig: 1b980bb2
TakeOff::
;> wBikeMode = 2
	ld a, $02
	ld [wBikeMode], a
;> kind = 2 if wBikeThrottle >= 0x70 else 0
	ld a, [wBikeThrottle]
	cp $70
	ld c, $00
	jr c, jr_000_1cb1

	ld c, $02

jr_000_1cb1:
;> if wBikeHeld & BTN_UP: kind += 1
	ld a, [wBikeHeld]
	and $04
	jr z, jr_000_1cb9

	inc c

jr_000_1cb9:
;> if wBikeCrash >= 2: kind = 4
	ld a, [wBikeCrash]
	cp $02
	jr c, jr_000_1cc2

	ld c, $04

jr_000_1cc2:
;> wJumpKind = kind
	ld a, c
	ld [wJumpKind], a
;> wNitroFlame = 2 * kind                          # frames before the path starts to bend
	add a
	ld [wNitroFlame], a
;> wNitroTimer = 0
	xor a
	ld [wNitroTimer], a
;> wTakeOffFrame = 1
;> return
	ld a, $01
	ld [wTakeOffFrame], a
	ret


;@ def FallOrCrash()
;@ path: bike/physics
;@ The bike has lost its footing. With ground at a wheel at a usable angle it is
;@ set down on it (LandAtAngle); with level ground at the front wheel it crashes
;@ (mode 8); with no ground it falls straight down (mode 4).
;@ writes: wBikeMode, wBikeMoveAngle, wBikeVelX, wBikeVelY, wCrashSide, wCrashTimer
;@ reads: wProbeKinds
;@ sig: 5e5005b7
FallOrCrash::
;> k = wProbeKinds[4]
;> if k & 0x80:
	ld a, [wProbeKinds + 4]
	bit 7, a
	jr z, jr_000_1cf8

;>     if k & 0x1F != 0x1F and k & 0x1E: return LandAtAngle(k & 0x1E)
	and $1f
	cp $1f
	jr z, jr_000_1ce5

	and $1e
	jr nz, jr_000_1d30

jr_000_1ce5:
;>     k = wProbeKinds[5]
;>     if k & 0x80:
	ld a, [wProbeKinds + 5]
	bit 7, a
	jr z, jr_000_1cf8

;>         if k & 0x1F == 0x1F or not k & 0x1E:
;>@crash1             wBikeMode = 8
;>@crash2             wCrashTimer = 0x39
;>@crash3             wCrashSide = 0
;>@crash4             return PlayBikeSound(0x16)
	and $1f
	cp $1f
	jr z, jr_000_1d1d

	and $1e
	jr z, jr_000_1d1d

;>         return LandAtAngle(k & 0x1E)
	jr jr_000_1d30

jr_000_1cf8:
;> wBikeMode = 4                                   # nothing below: straight down
	ld a, $04
	ld [wBikeMode], a
;> wBikeMoveAngle = 0x18
	ld a, $18
	ld [wBikeMoveAngle], a
;> wBikeVelY = 0x0400
	ld hl, $0400
	ld a, l
	ld [wBikeVelY], a
	ld a, h
	ld [wBikeVelY + 1], a
;> wBikeVelX = 0
	ld hl, $0000
	ld a, l
	ld [wBikeVelX], a
	ld a, h
	ld [wBikeVelX + 1], a
;> return PlayBikeSound(0x16)
	ld a, $16
	jp PlayBikeSound


jr_000_1d1d:
;=@crash1
	ld a, $08
	ld [wBikeMode], a
;=@crash2
	ld a, $39
	ld [wCrashTimer], a
;=@crash3
	xor a
	ld [wCrashSide], a
;=@crash4
	ld a, $16
	jp PlayBikeSound


;@ def LandAtAngle(angle: a)
;@ path: bike/physics
;@ Sets the bike down on the ground at `angle` (angles 1-8 count as turned past
;@ upright, +$20) and turns it to the ground under a wheel (mode 5).
;@ writes: wBikeMode, wBikeMoveAngle, wLastMoveAngle
;@ reads: wProbeKinds
;@ sig: cb4fca10
LandAtAngle::
jr_000_1d30:
;> if angle != 0x20:
	cp $20
	jr z, jr_000_1d3e

;>     angle &= 0x1F
;>     if angle and angle < 9: angle += 0x20
	and $1f
	jr z, jr_000_1d3e

	cp $09
	jr nc, jr_000_1d3e

	add $20

jr_000_1d3e:
;> wBikeMoveAngle = wLastMoveAngle = angle
	ld [wBikeMoveAngle], a
	ld [wLastMoveAngle], a
;> k = wProbeKinds[4] if wProbeKinds[4] & 0x80 else wProbeKinds[5]
	ld a, [wProbeKinds + 4]
	bit 7, a
	jr nz, jr_000_1d4e

	ld a, [wProbeKinds + 5]

jr_000_1d4e:
;> SnapToGrid(k & 0x1F)
	and $1f
	call SnapToGrid
;> wBikeMode = 5
;> return
	ld a, $05
	ld [wBikeMode], a
	ret


;@ def CheckLandingAngle(ground: a) -> (a, carry)
;@ path: bike/physics
;@ Whether the bike may land on ground of this angle: a table at $5E88 gives, for
;@ each ground angle, the range of bike angles that are fine (from, below); outside
;@ it the carry is set and the bike crashes. A crashing bike, and the computer's
;@ bike in some modes, always land.
;@ reads: wBikeAngle, wBikeCrash, wBikeId, wComFarAhead
;@ test: ground = rand(0, 0x1F)
;@ sig: d63a21a2
CheckLandingAngle::
;> if IsComRace() and wBikeId != 1 and not wComFarAhead: return ground, False
	ld c, a
	call IsComRace
	jr nz, jr_000_1d6e

	ld a, [wBikeId]
	dec a
	jr z, jr_000_1d6e

	ld a, [wComFarAhead]
	and a
	jr nz, jr_000_1d6e

	ld a, c
	and a
	ret


jr_000_1d6e:
;> if wBikeCrash: return ground, False
	ld a, [wBikeCrash]
	and a
	jr z, jr_000_1d77

	ld a, c
	and a
	ret


jr_000_1d77:
;> p = u16(0x5E88 + u8(2 * ground))
;> low, high = mem[p], mem[u16(p + 1)]
	ld a, c
	ld hl, $5e88
	add a
	rst $28
	ld b, [hl]
	inc hl
	ld a, [hld]
;> if high >= low:
	cp b
	jr c, jr_000_1d90

;>     ok = low <= wBikeAngle < high
	ld a, [wBikeAngle]
	cp [hl]
	jr c, jr_000_1d8d

	inc hl
	cp [hl]
	jr c, jr_000_1d9d

jr_000_1d8d:
;>     if not ok: return ground, True
	ld a, c
	scf
	ret


jr_000_1d90:
;> else:                                           # the range wraps past $1F
;>     ok = wBikeAngle >= low or wBikeAngle < high
	ld a, [wBikeAngle]
	cp [hl]
	jr nc, jr_000_1d9d

	inc hl
	cp [hl]
	jr c, jr_000_1d9d

;>     if not ok: return ground, True
	ld a, c
	scf
	ret


jr_000_1d9d:
;> return ground, False
	ld a, c
	and a
	ret


;@ def CrashAnimation()
;@ path: bike/crash
;@ Plays a crash by wCrashTimer (from $39 down): the start saves where it happened
;@ (and loses the power-ups), then the bike flies along the steps at $5EE8, tumbles
;@ through frames $29-$36 (wCrashSide picks the set), slides, and is put back where
;@ it crashed.
;@ writes: wBikeAngle, wBikeTopSpeed, wBikeX, wBikeY, wCrashMarker, wCrashX, wCrashY, wPowerUpA, wPowerUpB, wPowerUpLevel
;@ reads: wBikeId, wBikeX, wBikeY, wCrashSide, wCrashTimer, wCrashX, wCrashY
;@ sig: 6e7f9b11
CrashAnimation::
;> t = wCrashTimer
;> if t >= 0x36:
;>@s1     wCrashMarker = 1
;>@s2     if wBikeId == 1 or not IsComRace():
;>@s3         wPowerUpB = wPowerUpLevel = wPowerUpA = 0
;>@s4         wBikeTopSpeed = 0x4F
;>@s5     wBikeAngle = 0x2A if wCrashSide else 0x34
;>@s6     wCrashY = wBikeY
;>@s7     wCrashX = wBikeX[1] | wBikeX[2] << 8
;>@s8     return
	ld a, [wCrashTimer]
	cp $36
	jp nc, Jump_000_1dc7

;> elif t >= 0x2D:                                 # flying off
;>@f1     p = u16(0x5EE8 + u8(4 * (t - 0x2D)))
;>@f2     wBikeY = u16(wBikeY + mem16[p])
;>@f3     dx = mem16[u16(p + 2)] if wCrashSide else NegateBC(mem16[u16(p + 2)])
;>@f4     x = u16((wBikeX[1] | wBikeX[2] << 8) + dx)
;>@f5     wBikeX[1], wBikeX[2] = lo(x), hi(x)
;>@f6     wBikeAngle = 0x29 if wCrashSide else 0x33
;>@f7     return
	cp $2d
	jp nc, Jump_000_1e0c

;> elif t >= 0x1D:
;>@a1     wBikeAngle = 0x29 if wCrashSide else 0x33
;>@a2     return
	cp $1d
	jp nc, Jump_000_1e52

;> elif t >= 0x1A:
;>@b1     wBikeAngle = 0x2B if wCrashSide else 0x35
;>@b2     return
	cp $1a
	jp nc, Jump_000_1e60

;> elif t >= 9:                                    # sliding a pixel a frame
;>@c1     frame = 0x2C if wCrashSide else 0x36
;>@c2     wBikeAngle = frame + 1 if t & 4 else frame
;>@c3     x = u16((wBikeX[1] | wBikeX[2] << 8) + (1 if wCrashSide else -1))
;>@c4     wBikeX[1], wBikeX[2] = lo(x), hi(x)
;>@c5     return
	cp $09
	jp nc, Jump_000_1e6e

;> elif t >= 6:                                    # back where it crashed
;>@d1     wBikeAngle = 0x2E
;>@d2     wCrashMarker = 0
;>@d3     wBikeY = wCrashY
;>@d4     wBikeX[1], wBikeX[2] = lo(wCrashX), hi(wCrashX)
;>@d5     return
	cp $06
	jp nc, Jump_000_1e9c

;> elif t >= 3:
;>@e1     wBikeAngle = 0x2F
;>@e2     return
	cp $03
	jp nc, Jump_000_1ebe

;> return
	ret


Jump_000_1dc7:
;=@s1
	ld a, $01
	ld [wCrashMarker], a
;=@s2
	ld a, [wBikeId]
	dec a
	jr z, jr_000_1dd7

	call IsComRace
	jr z, jr_000_1de6

jr_000_1dd7:
;=@s3
	xor a
	ld [wPowerUpB], a
	ld [wPowerUpLevel], a
	ld [wPowerUpA], a
;=@s4
	ld a, $4f
	ld [wBikeTopSpeed], a

jr_000_1de6:
;=@s5
	ld a, [wCrashSide]
	and a
	ld a, $2a
	jr nz, jr_000_1df0

	ld a, $34

jr_000_1df0:
	ld [wBikeAngle], a
;=@s6
	ld a, [wBikeY]
	ld [wCrashY], a
	ld a, [wBikeY + 1]
	ld [wCrashY + 1], a
;=@s7
	ld a, [wBikeX + 1]
	ld [wCrashX], a
	ld a, [wBikeX + 2]
	ld [wCrashX + 1], a
;=@s8
	ret


Jump_000_1e0c:
;=@f1
	ld a, [wCrashTimer]
	sub $2d
	ld hl, $5ee8
	add a
	add a
	rst $28
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
;=@f2
	ld a, [wBikeY]
	ld l, a
	ld a, [wBikeY + 1]
	ld h, a
	add hl, de
	ld a, l
	ld [wBikeY], a
	ld a, h
	ld [wBikeY + 1], a
;=@f3
	ld a, [wCrashSide]
	and a
	ld e, $29
	jr nz, jr_000_1e3c

	ld e, $33
	call NegateBC

jr_000_1e3c:
;=@f4
	ld a, [wBikeX + 1]
	ld l, a
	ld a, [wBikeX + 2]
	ld h, a
	add hl, bc
;=@f5
	ld a, l
	ld [wBikeX + 1], a
	ld a, h
	ld [wBikeX + 2], a
;=@f6
	ld a, e
	ld [wBikeAngle], a
;=@f7
	ret


Jump_000_1e52:
;=@a1
	ld a, [wCrashSide]
	and a
	ld a, $29
	jr nz, jr_000_1e5c

	ld a, $33

jr_000_1e5c:
	ld [wBikeAngle], a
;=@a2
	ret


Jump_000_1e60:
;=@b1
	ld a, [wCrashSide]
	and a
	ld a, $2b
	jr nz, jr_000_1e6a

	ld a, $35

jr_000_1e6a:
	ld [wBikeAngle], a
;=@b2
	ret


Jump_000_1e6e:
;=@c1
	ld a, [wCrashSide]
	and a
	ld de, $0001
	ld c, $2c
	jr nz, jr_000_1e7e

	ld de, $ffff
	ld c, $36

jr_000_1e7e:
;=@c2
	ld a, [wCrashTimer]
	bit 2, a
	jr z, jr_000_1e86

	inc c

jr_000_1e86:
	ld a, c
	ld [wBikeAngle], a
;=@c3
	ld a, [wBikeX + 1]
	ld l, a
	ld a, [wBikeX + 2]
	ld h, a
	add hl, de
;=@c4
	ld a, l
	ld [wBikeX + 1], a
	ld a, h
	ld [wBikeX + 2], a
;=@c5
	ret


Jump_000_1e9c:
;=@d1
	ld a, $2e
	ld [wBikeAngle], a
;=@d2
	xor a
	ld [wCrashMarker], a
;=@d3
	ld a, [wCrashY]
	ld [wBikeY], a
	ld a, [wCrashY + 1]
	ld [wBikeY + 1], a
;=@d4
	ld a, [wCrashX]
	ld [wBikeX + 1], a
	ld a, [wCrashX + 1]
	ld [wBikeX + 2], a
;=@d5
	ret


Jump_000_1ebe:
;=@e1
	ld a, $2f
	ld [wBikeAngle], a
;=@e2
	ret


;@ def SnapToGrid(kind: a)
;@ path: bike/physics
;@ Lines the bike up with the 8-pixel grid after it hit something. Kind 0, 1 or $10
;@ puts it on a tile row (8 pixels further down for $10) and stops its Y speed; kind 8
;@ puts it on a tile column and stops its X speed (bike 1 takes the camera along).
;@ Other kinds change nothing.
;@ writes: wBikeVelX, wBikeVelY, wBikeX, wBikeY, wCamX
;@ reads: wBikeId, wBikeX, wBikeY, wCamX
;@ test: kind = rng.choice([0, 1, 2, 8, 0x10, 0x20, rand(0, 255)])
;@ sig: e05be069
SnapToGrid::
;> if kind < 0x02: offset, row = 0, True
	cp $02
	ld de, $0000
	ld bc, $ff00
	jr c, jr_000_1ee1

;> elif kind == 0x08: offset, row = 0, False
	cp $08
	ld de, $0000
	ld bc, $00ff
	jr z, jr_000_1ee1

;> elif kind == 0x10: offset, row = 8, True
	cp $10
	ld de, $0008
	ld bc, $ff00
;> else: return
	ret nz

jr_000_1ee1:
;> if row:
	inc c
	jr z, jr_000_1ef6

	dec c
;>     wBikeY = (wBikeY & 0xFF) | ((hi(wBikeY) + offset) & 0xF8) << 8
	ld a, [wBikeY + 1]
	add e
	and $f8
	or c
	ld [wBikeY + 1], a
;>     wBikeVelY = 0
	xor a
	ld [wBikeVelY], a
	ld [wBikeVelY + 1], a

jr_000_1ef6:
;>     return
	inc b
	ret z

	dec b
;> wBikeX[1] &= 0xF8                           # onto a tile column
	ld a, [wBikeX + 1]
	add d
	and $f8
	or b
	ld [wBikeX + 1], a
;> wBikeVelX = 0
	xor a
	ld [wBikeVelX], a
	ld [wBikeVelX + 1], a
;> if wBikeId != 1: return
	ld a, [wBikeId]
	dec a
	ret nz

;> wCamX[1] &= 0xF8
	ld a, [wCamX + 1]
	add d
	and $f8
	or b
	ld [wCamX + 1], a
;> return
	ret


;@ def TiltFromButtons()
;@ path: bike/physics
;@ Turns the bike by one step of 32 while the tilt buttons are held: bit 0 of
;@ wBikeHeld leans it back, bit 1 forward.
;@ reads: wBikeHeld
;@ sig: 1e25d505
TiltFromButtons::
;> if wBikeHeld & 0x01:
;>@dn1     angle = u8(wBikeAngle - 1)
;>@dn2     wBikeAngle = 0x1F if angle == 0xFF else angle
;>@dn3     return
	ld a, [wBikeHeld]
	rra
	jr c, jr_000_1f24

;> elif wBikeHeld & 0x02: return TiltForward()
	rra
	jr c, TiltForward

;> return
	ret


jr_000_1f24:
;=@dn1
	ld hl, wBikeAngle
	dec [hl]
	ld a, [hl]
;=@dn2
	cp $ff
	ret nz

	ld [hl], $1f
;=@dn3
	ret


;@ def TiltForward()
;@ path: bike/physics
;@ Turns the bike one step forward (wBikeAngle + 1, from $1F round to 0).
;@ sig: e68eba1e
TiltForward::
;> angle = u8(wBikeAngle + 1)
	ld hl, wBikeAngle
	inc [hl]
	ld a, [hl]
	cp $20
	ret nz

;> wBikeAngle = 0 if angle == 0x20 else angle
;> return
	ld [hl], $00
	ret


;@ def CrashSpin()
;@ path: bike/physics
;@ After a crash: the bike turns forward until it reaches angle 3; then
;@ (wBikeCrash = 3) it shows the crash frames $30, $31 and $32, one every 4 frames, and stays
;@ on the last one.
;@ writes: wBikeAngle, wBikeCrash
;@ reads: wBikeAngle, wBikeCrash, wFrameCounter
;@ test: wBikeCrash = rng.choice([3, rand(0, 5)]); wBikeAngle = rng.choice([3, 0x1F, 0x30, 0x31, 0x32, rand(0, 0x40)])
;@ sig: afae0fba
CrashSpin::
;> if wBikeCrash != 3:
	ld a, [wBikeCrash]
	cp $03
	jr z, jr_000_1f5d

;>     if wBikeAngle == 3:
	ld a, [wBikeAngle]
	cp $03
	jr nz, jr_000_1f4e

;>         wBikeCrash = 3
;>         return
	ld a, $03
	ld [wBikeCrash], a
	ret


jr_000_1f4e:
;>     angle = u8(wBikeAngle + 1)
	ld a, [wBikeAngle]
	inc a
	ld [wBikeAngle], a
	cp $20
	ret nz

;>     wBikeAngle = 0 if angle == 0x20 else angle
;>     return
	xor a
	ld [wBikeAngle], a
	ret


jr_000_1f5d:
;> if wFrameCounter & 0x03: return               # every 4 frames
	ld a, [wFrameCounter]
	and $03
	ret nz

;> angle = wBikeAngle
;> if angle == 0x32: return
;> wBikeAngle = {0x03: 0x30, 0x30: 0x31, 0x31: 0x32}.get(angle, 0x03)
;> return
	ld a, [wBikeAngle]
	cp $03
	ld c, $30
	jr z, jr_000_1f7d

	cp $30
	ld c, $31
	jr z, jr_000_1f7d

	cp $31
	ld c, $32
	jr z, jr_000_1f7d

	cp $32
	ret z

	ld c, $03

jr_000_1f7d:
	ld a, c
	ld [wBikeAngle], a
	ret


;@ def MoveBike()
;@ path: bike/physics
;@ Moves the bike by its speed: wBikeY (8.8) by wBikeVelY, the 24-bit wBikeX by
;@ the sign-extended wBikeVelX.
;@ reads: wBikeVelX, wBikeVelY
;@ sig: bff64cca
MoveBike::
;> wBikeY = u16(wBikeY + wBikeVelY)
	ld hl, wBikeY
	ld a, [wBikeVelY]
	add [hl]
	ld [hli], a
	ld a, [wBikeVelY + 1]
	adc [hl]
	ld [hli], a
;> vx = wBikeVelX - 0x10000 if wBikeVelX & 0x8000 else wBikeVelX
	ld a, [wBikeVelX + 1]
	ld b, a
	rla
	ld c, $00
	jr nc, jr_000_1f99

	dec c

jr_000_1f99:
;> x = (wBikeX[0] | wBikeX[1] << 8 | wBikeX[2] << 16) + vx
;> wBikeX[0] = x & 0xFF
;> wBikeX[1] = (x >> 8) & 0xFF
;> wBikeX[2] = (x >> 16) & 0xFF
;> return
	ld a, [wBikeVelX]
	add [hl]
	ld [hli], a
	ld a, b
	adc [hl]
	ld [hli], a
	ld a, c
	adc [hl]
	ld [hl], a
	ret


;@ def LevelOffAtTop()
;@ path: bike/physics
;@ Close to the top of the level (Y below 16) a bike in mode 2 stops climbing: a
;@ travel direction of 1-8 becomes 0, one of 9-15 becomes $10.
;@ writes: wBikeMoveAngle
;@ reads: wBikeMode, wBikeMoveAngle, wBikeY
;@ test: wBikeMode = rng.choice([2, rand(0, 9)]); wBikeY = rand(0, 0x20) << 8 | rand(0, 255)
;@ sig: 8f75b724
LevelOffAtTop::
;> if wBikeMode != 2: return
	ld a, [wBikeMode]
	cp $02
	ret nz

;> if hi(wBikeY) >= 0x10: return
	ld a, [wBikeY + 1]
	cp $10
	ret nc

;> direction = wBikeMoveAngle
;> if direction == 0: return
	ld a, [wBikeMoveAngle]
	and a
	ret z

;> if direction < 0x09: wBikeMoveAngle = 0x00
	cp $09
	ld c, $00
	jr c, jr_000_1fc1

;> elif direction < 0x10: wBikeMoveAngle = 0x10
	cp $10
	ret nc

	ld c, $10

jr_000_1fc1:
;> return
	ld a, c
	ld [wBikeMoveAngle], a
	ret


;@ def UpdateThrottle()
;@ path: bike/engine
;@ The engine, once a frame: the throttle rises by 2 while the throttle button is
;@ held (up to wBikeTopSpeed) and falls by 2 otherwise; a pressed nitro button
;@ spends a nitro (throttle $90 for 16 frames). Some modes set the throttle
;@ outright, a crashed bike is left alone. The result goes to wBikeDriveSpeed.
;@ writes: wBikeDriveSpeed, wBikeMoveAngle, wBikeThrottle, wNitro, wNitroFlame, wNitroTimer
;@ reads: $C7B6, wBikeAngle, wBikeCrash, wBikeHeld, wBikeMode, wBikePressed, wBikeThrottle, wBikeTopSpeed, wNitro, wNitroTimer, wPowerUpB, wTakeOffFrame
;@ test: wBikeMode = rand(0, 9); wBikeCrash = rand(0, 5); wNitroTimer = rng.choice([0, rand(0, 20)])
;@ sig: fa6c45fc
UpdateThrottle::
;> if wBikeMode == 6: action, value = 'set', 0x20
	ld a, [wBikeMode]
	cp $06
	ld c, $20
	jp z, Jump_000_20a2

;> elif wBikeCrash == 1: action = 'accel'
	ld a, [wBikeCrash]
	cp $01
	jr z, jr_000_200b

;> elif wBikeCrash >= 2: action = 'crashed'
	cp $02
	jp nc, Jump_000_20ad

;> elif wBikeMode == 2: action = 'air'
	ld a, [wBikeMode]
	cp $02
	jp z, Jump_000_2058

;> elif wBikeMode == 5: action, value = 'set', 0x08
	cp $05
	ld c, $08
	jp z, Jump_000_20a2

;> elif wBikeMode == 8: action, value = 'set', 0x00
	cp $08
	ld c, $00
	jp z, Jump_000_20a2

;> elif wNitroTimer:
	ld a, [wNitroTimer]
	and a
	jr z, jr_000_1ffd

;>     wNitroTimer -= 1
;>     return
	dec a
	ld [wNitroTimer], a
	ret


jr_000_1ffd:
;> elif wBikePressed & 0x20: action = 'nitro'
	ld a, [wBikePressed]
	and $20
	jr nz, jr_000_203c

;> elif wBikeHeld & 0x10: action = 'accel'
;> else: action = 'brake'
	ld a, [wBikeHeld]
	and $10
	jr z, jr_000_2025

jr_000_200b:
;> if action == 'accel':
;>     if wBikeThrottle > wBikeTopSpeed: action = 'brake'     # faster than its top speed: slow down
	ld a, [wBikeThrottle]
	ld hl, wBikeTopSpeed
	cp [hl]
	jp z, Jump_000_20a6

	jr nc, jr_000_2025

;>     elif wBikeThrottle < wBikeTopSpeed:
;>         t = u8(wBikeThrottle + 2)
;>         wBikeThrottle = t if t <= wBikeTopSpeed else wBikeTopSpeed
	add $02
	cp [hl]
	jr z, jr_000_201f

	jr c, jr_000_201f

	ld a, [hl]

jr_000_201f:
	ld [wBikeThrottle], a
	jp Jump_000_20a6


jr_000_2025:
;> if action == 'brake' and wBikeThrottle:
	ld c, $02
	ld a, [wBikeThrottle]
	and a
	jp z, Jump_000_20a6

;>     t = u8(wBikeThrottle - 2)
;>     wBikeThrottle = 0 if t == 0xFF else t
	sub c
	ld [wBikeThrottle], a
	inc a
	jp nz, Jump_000_20a6

	ld [wBikeThrottle], a
	jp Jump_000_20a6


jr_000_203c:
;> if action == 'nitro':
;>     if not wNitro: return NitroEmpty()
	ld a, [wNitro]
	or a
	jp z, NitroEmpty

;>     wNitro -= 1
;>     wNitroTimer = 0x10
;>     wBikeThrottle = 0x90
;>     PlayBikeSound(0x0A)                          # the nitro sound
	dec a
	ld [wNitro], a
	ld a, $10
	ld [wNitroTimer], a
	ld a, $90
	ld [wBikeThrottle], a
	ld a, $0a
	call PlayBikeSound
	jr jr_000_20a6

Jump_000_2058:
;> if action == 'air':
;>     if wTakeOffFrame: sound = 0x0A
	ld a, [wTakeOffFrame]
	and a
	ld b, $0a
	jr nz, jr_000_206f

;>     elif not wPowerUpB or wBikeAngle >= 0x07: sound = None
	ld a, [wPowerUpB]
	and a
	jr z, jr_000_20a6

	ld a, [wBikeAngle]
	cp $07
	jr nc, jr_000_20a6

;>     else: sound = 0x0B
	ld b, $0b

jr_000_206f:
;>     if sound is not None and wBikePressed & 0x20:
	ld a, [wBikePressed]
	and $20
	jr z, jr_000_20a6

;>         if wNitro:
	ld a, [wNitro]
	or a
	jr z, jr_000_209d

;>             wNitroFlame = 8
;>             wBikeMoveAngle = wBikeAngle             # a nitro in the air flies the way the bike points
;>             wNitro -= 1
;>             wNitroTimer = 0x10
;>             wBikeThrottle = 0x90
;>             PlayBikeSound(sound)
	ld c, a
	ld a, $08
	ld [wNitroFlame], a
	ld a, [wBikeAngle]
	ld [wBikeMoveAngle], a
	ld a, c
	dec a
	ld [wNitro], a
	ld a, $10
	ld [wNitroTimer], a
	ld a, $90
	ld [wBikeThrottle], a
	ld a, b
	call PlayBikeSound
	jr jr_000_20a6

jr_000_209d:
;>         else: NitroEmpty()
	call NitroEmpty
	jr jr_000_20a6

Jump_000_20a2:
;> if action == 'set': wBikeThrottle = value
	ld a, c
	ld [wBikeThrottle], a

Jump_000_20a6:
jr_000_20a6:
;> if action != 'crashed' or wBikeMode == 2:
;>     wBikeDriveSpeed = wBikeThrottle
;>     return
	ld a, [wBikeThrottle]
	ld [wBikeDriveSpeed], a
	ret


Jump_000_20ad:
	ld a, [wBikeMode]
	cp $02
	jr z, jr_000_20a6

;> if wBikeCrash == 4: return
	ld a, [wBikeCrash]
	cp $04
	ret z

;> if wBikeTopSpeed >= wBikeThrottle: wBikeThrottle = wBikeTopSpeed
;> return
	ld a, [wBikeTopSpeed]
	ld hl, wBikeThrottle
	cp [hl]
	ret c

	ld [wBikeThrottle], a
	ret


;@ def NitroEmpty()
;@ path: bike/engine
;@ The sound of pressing the nitro button with no nitro left.
;@ sig: badd41e0
NitroEmpty::
;> return PlayBikeSound(0x0C)
	ld a, $0c
	jp PlayBikeSound


;@ def UpdateVelocity()
;@ path: bike/physics
;@ Turns the engine's speed into an X and a Y speed for this frame: the throttle
;@ goes through SpeedCurve, wBikeSpeedBonus is added (clamped to $00-$90), and
;@ half the result is split along wBikeMoveAngle with the sine table: the step
;@ inside a quarter turn from VelocitySteps, the quarter's signs from VelocitySigns.
;@ writes: wBikeDriveSpeed, wBikeMode, wBikeSpeed, wBikeSpeedBonus, wBikeVelX, wBikeVelY, wMathNegCos, wMathNegSin
;@ reads: wBikeMode, wBikeMoveAngle, wBikeSpeedBonus, wBikeThrottle
;@ test: wBikeMode = rand(0, 9); wBikeThrottle = rng.choice([0, rand(0, 0x90), rand(0, 255)])
;@ sig: 987443bf
UpdateVelocity::
;> if wBikeMode in (0x04, 0x07): return
	ld a, [wBikeMode]
	cp $04
	ret z

	cp $07
	ret z

;> if wBikeThrottle == 0 and wBikeMode == 1: wBikeMode = 0
	ld a, [wBikeThrottle]
	and a
	jr nz, jr_000_20e3

	ld a, [wBikeMode]
	dec a
	jr nz, jr_000_20e3

	ld [wBikeMode], a

jr_000_20e3:
;> speed = wBikeThrottle if wBikeThrottle >= 0x70 else mem[SpeedCurve + wBikeThrottle]
	ld a, [wBikeThrottle]
	cp $70
	jr nc, jr_000_20ef

	ld hl, SpeedCurve
	rst $28
	ld a, [hl]

jr_000_20ef:
;> wBikeDriveSpeed = speed
	ld [wBikeDriveSpeed], a
	ld b, a
;> speed = u8(wBikeSpeedBonus + speed)
;> if speed >= 0x91: speed = 0x00 if wBikeSpeedBonus & 0x80 else 0x90
	ld a, [wBikeSpeedBonus]
	bit 7, a
	jr nz, jr_000_2103

	add b
	cp $91
	jr c, jr_000_2109

	ld a, $90
	jr jr_000_2109

jr_000_2103:
	add b
	cp $91
	jr c, jr_000_2109

	xor a

jr_000_2109:
;> wBikeSpeed = speed
	ld [wBikeSpeed], a
	ld b, a
;> wBikeSpeedBonus = 0
	xor a
	ld [wBikeSpeedBonus], a
;> step = mem[VelocitySteps + (wBikeMoveAngle & 0x07)]
	ld a, b
	rra
	and $7f
	ld d, a
	ld a, [wBikeMoveAngle]
	and $07
	ld hl, VelocitySteps
	rst $28
	ld e, [hl]
;> wMathNegSin = wMathNegCos = 0
	xor a
	ld [wMathNegSin], a
	ld [wMathNegCos], a
;> y, x = SpeedComponents(speed >> 1, step)
	call SpeedComponents
;> signs = mem[VelocitySigns + wBikeMoveAngle]
	push hl
	ld a, [wBikeMoveAngle]
	ld hl, VelocitySigns
	rst $28
	ld c, [hl]
	pop hl
;> if signs & 0x01: y, x = x, y
	rr c
	call c, SwapDEHL
;> if signs & 0x02: y = u16(-y)
	rr c
	call c, NegateHL
;> if signs & 0x04: x = u16(-x)
	rr c
	call c, NegateDE
;> wBikeVelY = y
	ld a, l
	ld [wBikeVelY], a
	ld a, h
	ld [wBikeVelY + 1], a
;> wBikeVelX = x
	ld a, e
	ld [wBikeVelX], a
	ld a, d
	ld [wBikeVelX + 1], a
;> return
	ret


;@ The sine table step (0-56) for each of the 8 directions inside a quarter turn (wBikeMoveAngle & 7).
VelocitySteps::
	db $00, $08, $10, $18, $20, $28, $30, $38


;@ For each travel direction (wBikeMoveAngle): bit 0 swaps the X and Y parts, bit 1 negates Y, bit 2 negates X.
VelocitySigns::
	db $00, $02, $02, $02, $02, $02, $02, $02, $03, $07, $07, $07, $07, $07, $07, $07
	db $04, $04, $04, $04, $04, $04, $04, $04, $01, $01, $01, $01, $01, $01, $01, $01
	db $04, $04, $04, $04, $04, $04, $04, $04, $01


;@ The engine's speed for each throttle value below $70 (from $70 on the throttle is the speed).
SpeedCurve::
	db $00, $08, $10, $10, $20, $20, $30, $30, $34, $36, $38, $3a, $3c, $3e, $40, $42
	db $44, $44, $44, $44, $46, $46, $46, $46, $48, $48, $48, $48, $4a, $4a, $4a, $4a
	db $4c, $4c, $4c, $4c, $4e, $4e, $4e, $4e, $50, $50, $50, $50, $52, $52, $52, $52
	db $54, $54, $54, $54, $56, $56, $56, $56, $58, $58, $58, $58, $5a, $5a, $5a, $5a
	db $5c, $5c, $5c, $5c, $5e, $5e, $5e, $5e, $60, $60, $60, $60, $62, $62, $62, $62
	db $64, $64, $64, $64, $66, $66, $66, $66, $68, $68, $68, $68, $6a, $6a, $6a, $6a
	db $6c, $6c, $6c, $6c, $6e, $6e, $6e, $6e, $70, $70, $70, $70, $70, $70, $70, $70

;@ def SpeedComponents(length: d, step: e) -> (hl, de)
;@ path: lib/math
;@ length x sine and length x cosine of a step of SineTable (each / 16).
;@ writes: wMathA, wMathB
;@ sig: 2bdc0fdb
SpeedComponents::
;> wMathA = length
	ld a, d
	ld [wMathA], a
;> wMathB = step
	ld a, e
	ld [wMathB], a
;> return SineCosineProducts(step)
	call SineCosineProducts
	ret


;@ def SineCosineProducts(step: a) -> (hl, de)
;@ path: lib/math
;@ wMathA x sin(step) / 16 and wMathA x cos(step) / 16, for a step of the quarter
;@ wave in SineTable (64 steps to 90 degrees; the cosine is the table read from
;@ the other end). wMathNegSin / wMathNegCos negate either product.
;@ writes: wMathCos, wMathCosProd, wMathSinProd
;@ reads: wMathCos, wMathNegCos, wMathNegSin
;@ sig: 101a1789
SineCosineProducts::
;> sine = mem[SineTable + step]
;> wMathCos = mem[SineTable + u8(0x3F - step)]
	ld d, $00
	ld e, a
	sub $3f
	cpl
	inc a
	ld hl, SineTable
	push hl
	add hl, de
	ld c, [hl]
	pop hl
	ld e, a
	add hl, de
	ld a, [hl]
	ld [wMathCos], a
;> s = ScaleBy(sine)
	ld e, c
	call ScaleBy
;> if wMathNegSin: s = u16(-s)
	ld a, [wMathNegSin]
	and a
	call nz, NegateDE
;> c = ScaleBy(wMathCos)
	push de
	ld a, [wMathCos]
	ld e, a
	call ScaleBy
;> if wMathNegCos: c = u16(-c)
	ld a, [wMathNegCos]
	and a
	call nz, NegateDE
;> wMathCosProd = c
	pop hl
	ld a, e
	ld [wMathCosProd], a
	ld a, d
	ld [wMathCosProd + 1], a
;> wMathSinProd = s
	ld a, l
	ld [wMathSinProd], a
	ld a, h
	ld [wMathSinProd + 1], a
;> return s, c
	ret


;@ def ScaleBy(value: e) -> de
;@ path: lib/math
;@ wMathA x value / 16.
;@ reads: wMathA
;@ sig: 7b31308f
ScaleBy::
;> return Multiply8(wMathA, value) >> 4
	ld a, [wMathA]
	ld h, a
	call Multiply8
	xor a
	ld b, $04

jr_000_224b:
	add hl, hl
	adc a
	dec b
	jr nz, jr_000_224b

	ld l, h
	ld h, a
	call SwapDEHL
	ret


;@ def Multiply8(x: h, y: e) -> hl
;@ path: lib/math
;@ x x y, the 16-bit product of two bytes (shift and add, 8 rounds).
;@ sig: 85112302
Multiply8::
;> return x * y
	ld b, $08
	ld l, $00
	ld d, l

jr_000_225b:
	add hl, hl
	jr nc, jr_000_225f

	add hl, de

jr_000_225f:
	dec b
	jr nz, jr_000_225b

	ret


;@ A quarter sine wave in 65 steps: 255 x sin(i x 90 / 64), for i = 0..64.
SineTable::
	db $00, $06, $0c, $12, $19, $1f, $26, $2c, $32, $38, $3e, $44, $4a, $50, $56, $5c
	db $62, $68, $6d, $73, $79, $7e, $84, $89, $8e, $93, $99, $9e, $a2, $a7, $ac, $b1
	db $b5, $b9, $be, $c2, $c6, $ca, $ce, $d1, $d5, $d8, $dc, $df, $e2, $e5, $e7, $ea
	db $ed, $ef, $f1, $f3, $f5, $f7, $f8, $fa, $fb, $fc, $fd, $fe, $fe, $ff, $ff, $ff
	db $ff

;@ def DrawBike()
;@ path: bike/draw
;@ Puts the current bike's sprites at its place on the screen.
;@ sig: a8e60355
DrawBike::
;> y, x, left = BikeScreenPos()
	call BikeScreenPos
;> return DrawBikeSprites(y, lo(x))
	ld b, l
	jp DrawBikeSprites


;@ def DrawBike2()
;@ path: bike/draw
;@ The other bike's sprites, or none while it is off the screen to the left or
;@ more than 192 pixels to the right; then the mark at its crash spot.
;@ sig: cc0c7c82
DrawBike2::
;> y, x, left = BikeScreenPos()
	call BikeScreenPos
	jr c, jr_000_22c0

;> if left or x >= 0xC0: return HideBike2Sprites()
	ld a, h
	and a
	jr nz, jr_000_22c0

	ld a, l
	cp $c0
	jr nc, jr_000_22c0

;> DrawBikeSprites(y, x)
	ld b, l
	call DrawBikeSprites
;> return DrawCrashMarker()
	jp DrawCrashMarker


Jump_000_22c0:
jr_000_22c0:
	jp HideBike2Sprites


;@ def BikeScreenPos() -> (c, hl, carry)
;@ path: bike/draw
;@ The bike's place on the screen: its pixel row minus the camera's, its pixel
;@ column minus the camera's (16 bits), and carry when it is left of the camera.
;@ reads: wBikeX, wBikeY, wCamX, wCamY
;@ sig: ba0f5dba
BikeScreenPos::
;> y = u8(hi(wBikeY) - hi(wCamY))
	ld a, [wCamY + 1]
	ld e, a
	ld a, [wBikeY + 1]
	sub e
	ld c, a
;> bike = wBikeX[1] | wBikeX[2] << 8
	ld a, [wBikeX + 1]
	ld l, a
	ld a, [wBikeX + 2]
	ld h, a
;> camera = wCamX[1] | wCamX[2] << 8
	ld a, [wCamX + 1]
	ld e, a
	ld a, [wCamX + 2]
	ld d, a
;> return y, u16(bike - camera), bike < camera
	call SubHLDE
	ret


;@ def DrawBikeSprites(y: c, x: b)
;@ path: bike/draw
;@ Copies the sprite layout for the bike's angle into the shadow OAM at screen
;@ position (x, y): bike 1 into sprites 0-6, bike 2 into sprites 7-13 with the
;@ second palette. A layout is a count, then per sprite y and x offsets, tile and
;@ attributes; $80 instead of the y offset leaves a slot empty.
;@ reads: wBikeAngle, wBikeId
;@ test: wBikeAngle = rand(0, 0x34); wBikeId = rand(1, 2)
;@ sig: 1857e634
DrawBikeSprites::
;> layout = mem16[0x3492 + u8(2 * wBikeAngle)]     # the layouts by angle
	push bc
	ld hl, $3492
	ld a, [wBikeAngle]
	rst $10
	ld l, e
	ld h, d
;> dest, palette = (addr(wShadowOAM), 0x00) if wBikeId == 1 else (addr(wShadowOAM) + 0x1C, 0x10)
;>@two pass                                     # (bike 2 runs its own copy of the loop)
	ld a, [wBikeId]
	dec a
	jr nz, jr_000_2320

;> p = layout + 1
	pop bc
	ld de, wShadowOAM
	ld a, [hli]

jr_000_22f5:
;> for _ in range(mem[layout] or 256):
;>     if mem[p] != 0x80:
	push af
	ld a, [hl]
	cp $80
	jr z, jr_000_2314

;>         mem[dest] = u8(y + mem[p] + 0x10)
	ld a, c
	add [hl]
	add $10
	ld [de], a
	inc hl
	inc de
;>         mem[dest + 1] = u8(x + mem[p + 1] + 0x08)
	ld a, b
	add [hl]
	add $08
	ld [de], a
	inc hl
	inc de
;>         mem[dest + 2] = mem[p + 2]
	ld a, [hli]
	ld [de], a
	inc de
;>         mem[dest + 3] = mem[p + 3] | palette
;>         p += 4
;>@hid1     else:
;>@hid1         fill(dest, 0, 4)                 # an empty slot
;>@hid2         p += 1
	ld a, [hli]
	ld [de], a
	inc de

jr_000_230f:
;>     dest += 4
	pop af
	dec a
	jr nz, jr_000_22f5

;> return
	ret


jr_000_2314:
;=@hid1
	xor a
	ld [de], a
	inc de
	ld [de], a
	inc de
	ld [de], a
	inc de
	ld [de], a
	inc de
;=@hid2
	inc hl
	jr jr_000_230f

;=@two
jr_000_2320:
	pop bc
	ld de, $cc1c
	ld a, [hli]

jr_000_2325:
	push af
	ld a, [hl]
	cp $80
	jr z, jr_000_2346

	ld a, c
	add [hl]
	add $10
	ld [de], a
	inc hl
	inc de
	ld a, b
	add [hl]
	add $08
	ld [de], a
	inc hl
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	or $10
	ld [de], a
	inc de

jr_000_2341:
	pop af
	dec a
	jr nz, jr_000_2325

	ret


jr_000_2346:
	xor a
	ld [de], a
	inc de
	ld [de], a
	inc de
	ld [de], a
	inc de
	ld [de], a
	inc de
	inc hl
	jr jr_000_2341

;@ def DrawCrashMarker()
;@ path: bike/draw
;@ While wCrashMarker is set, sprites 10 and 11 mark the spot where the bike
;@ crashed; off the screen, bike 2's sprites are hidden instead.
;@ writes: wShadowOAM
;@ reads: wCamX, wCamY, wCrashMarker, wCrashX, wCrashY
;@ test: wCrashMarker = rand(0, 1)
;@ sig: 6595033b
DrawCrashMarker::
;> if not wCrashMarker: return
	ld a, [wCrashMarker]
	and a
	ret z

;> y = u8(hi(wCrashY) - hi(wCamY))
	ld a, [wCamY + 1]
	ld e, a
	ld a, [wCrashY + 1]
	sub e
	ld c, a
;> x = wCrashX - (wCamX[1] | wCamX[2] << 8)
	ld a, [wCrashX]
	ld l, a
	ld a, [wCrashX + 1]
	ld h, a
	ld a, [wCamX + 1]
	ld e, a
	ld a, [wCamX + 2]
	ld d, a
	call SubHLDE
;> if x < 0 or x >= 0xF0: return HideBike2Sprites()
	jp c, Jump_000_22c0

	ld a, h
	and a
	jp nz, Jump_000_22c0

	ld a, l
	cp $f0
	jp nc, Jump_000_22c0

;> wShadowOAM[0x28] = wShadowOAM[0x2C] = u8(y + 0x18)
	ld b, l
	ld a, c
	add $18
	ld [wShadowOAM + 40], a
	ld [wShadowOAM + 44], a
;> wShadowOAM[0x29] = u8(x + 0x08)
	ld a, b
	add $08
	ld [wShadowOAM + 41], a
;> wShadowOAM[0x2D] = u8(x + 0x10)
	add $08
	ld [wShadowOAM + 45], a
;> return
	ret


;@ def HideBike2Sprites()
;@ path: bike/draw
;@ Moves sprites 7-11 (bike 2) off the screen (y = 0).
;@ sig: a548d4b7
HideBike2Sprites::
;> for i in range(5):
	ld hl, $cc1c
	ld b, $05
	xor a

jr_000_239d:
;>     wShadowOAM[0x1C + 4 * i] = 0
	ld [hli], a
	inc hl
	inc hl
	inc hl
	dec b
	jr nz, jr_000_239d

;> return
	ret


;@ def DrawWheelSpray()
;@ path: bike/draw
;@ Sprite 6 behind the back wheel while bit 6 of wProbeKinds[1] is set and the bike moves:
;@ it cycles through tiles $E5-$E7, with sound $13 at each new round.
;@ reads: wBikeSpeed, wProbeKinds
;@ test: mem[0xCC1A] = rng.choice([0xE5, 0xE6, 0xE7, rand(0, 255)])
;@ sig: f15a6796
DrawWheelSpray::
;> if wProbeKinds[1] & 0x40 and wBikeSpeed:
	ld hl, $cc18
	ld de, wShadowOAM
	ld a, [wProbeKinds + 1]
	bit 6, a
	jr z, jr_000_23d0

	ld a, [wBikeSpeed]
	and a
	jr z, jr_000_23d0

;>     wShadowOAM[0x18] = u8(wShadowOAM[0x00] + 0x08)
	ld a, [de]
	add $08
	ld [hli], a
	inc de
;>     wShadowOAM[0x19] = u8(wShadowOAM[0x01] - 0x08)
	ld a, [de]
	add $f8
	ld [hli], a
;>     tile = u8(wShadowOAM[0x1A] + 1)
	ld a, [hl]
	inc a
;>     if tile >= 0xE8:
	cp $e8
	jr c, jr_000_23ce

;>         PlayBikeSound(0x13)
	ld a, $13
	call PlayBikeSound
;>         tile = 0xE5
	ld a, $e5

jr_000_23ce:
;>     wShadowOAM[0x1A] = tile
;>     return
	ld [hl], a
	ret


jr_000_23d0:
;> wShadowOAM[0x18] = 0
;> return
	xor a
	ld [hl], a
	ret


;@ def DrawThrottleFlame()
;@ path: bike/draw
;@ Sprite 5: the exhaust flame at a throttle of $88 and more, bigger as the
;@ throttle rises (tiles $EB, $EA, $E9, $E8 from $88, $8C, $8E, $90), placed
;@ behind the bike by an offset table indexed by its angle.
;@ writes: wMathA
;@ reads: wBikeAngle, wBikeThrottle, wMathA
;@ test: wBikeThrottle = rng.choice([rand(0x80, 0x95), rand(0, 255)]); wBikeAngle = rand(0, 0x34)
;@ sig: 526cbddf
DrawThrottleFlame::
;> if wBikeThrottle < 0x88:
;>@off     wShadowOAM[0x14] = 0; return
	ld hl, $cc14
	ld bc, wShadowOAM
	ld a, [wBikeThrottle]
	cp $88
	jr c, jr_000_240f

;> throttle = wBikeThrottle
;> tile = 0xE8 if throttle >= 0x90 else 0xE9 if throttle >= 0x8E else 0xEA if throttle >= 0x8C else 0xEB
	push bc
	cp $90
	ld c, $e8
	jr nc, jr_000_23f5

	cp $8e
	ld c, $e9
	jr nc, jr_000_23f5

	cp $8c
	ld c, $ea
	jr nc, jr_000_23f5

	ld c, $eb

jr_000_23f5:
;> wMathA = tile
	ld a, c
	ld [wMathA], a
;> offset = mem16[0x5E48 + u8(2 * wBikeAngle)]  # by angle: y offset, x offset
	pop bc
	push hl
	ld hl, $5e48
	ld a, [wBikeAngle]
	rst $10
	pop hl
;> wShadowOAM[0x14] = u8(wShadowOAM[0x00] + lo(offset))
	ld a, [bc]
	add e
	ld [hli], a
	inc bc
;> wShadowOAM[0x15] = u8(wShadowOAM[0x01] + hi(offset))
	ld a, [bc]
	add d
	ld [hli], a
;> wShadowOAM[0x16] = tile
;> return
	ld a, [wMathA]
	ld [hl], a
	ret


jr_000_240f:
;=@off
	xor a
	ld [hl], a
	ret


;@ def DrawTrail()
;@ path: bike/draw
;@ The afterimages that follow the bike with the power-up of item 7: one per
;@ wPowerUpLevel (up to 3), drawn where the bike was 5, 7 and 9 camera moves ago
;@ (wTrailY, wTrailX, wTrailAngle), into sprites 32-34; unused ones are hidden.
;@ writes: wShadowOAM
;@ reads: wPowerUpLevel, wTrailAngle, wTrailX, wTrailY
;@ test: wPowerUpLevel = rand(0, 4)
;@ sig: 3d42f09b
DrawTrail::
;> n = wPowerUpLevel
	ld a, [wPowerUpLevel]
	and a
	jp z, Jump_000_249c

;> if n >= 1: DrawTrailSprite(wTrailY[10], wTrailX[20] | wTrailX[21] << 8, wTrailAngle[10], addr(wShadowOAM) + 0x80)
	push af
	ld a, [wTrailY + 10]
	ld c, a
	ld a, [wTrailX + 20]
	ld l, a
	ld a, [wTrailX + 21]
	ld h, a
	ld a, [wTrailAngle + 10]
	ld b, a
	ld de, $cc80
	call DrawTrailSprite
;> if n >= 2: DrawTrailSprite(wTrailY[8], wTrailX[16] | wTrailX[17] << 8, wTrailAngle[8], addr(wShadowOAM) + 0x84)
	pop af
	dec a
	jp z, Jump_000_24a0

	push af
	ld a, [wTrailY + 8]
	ld c, a
	ld a, [wTrailX + 16]
	ld l, a
	ld a, [wTrailX + 17]
	ld h, a
	ld a, [wTrailAngle + 8]
	ld b, a
	ld de, $cc84
	call DrawTrailSprite
;> if n >= 3: return DrawTrailSprite(wTrailY[6], wTrailX[12] | wTrailX[13] << 8, wTrailAngle[6], addr(wShadowOAM) + 0x88)
;>@h0 if n < 1: wShadowOAM[0x80] = 0
;>@h1 if n < 2: wShadowOAM[0x84] = 0
;>@h2 if n < 3: wShadowOAM[0x88] = 0
;>@h3 return
	pop af
	dec a
	jp z, Jump_000_24a4

	ld a, [wTrailY + 6]
	ld c, a
	ld a, [wTrailX + 12]
	ld l, a
	ld a, [wTrailX + 13]
	ld h, a
	ld a, [wTrailAngle + 6]
	ld b, a
	ld de, $cc88

;@ def DrawTrailSprite(y: c, x: hl, angle: b, dest: de)
;@ path: bike/draw
;@ One afterimage: a single sprite at the screen position of level position
;@ (x, y), with the tile for that angle from the table at $5EC8 (bit 7 flips it).
;@ reads: wCamX, wCamY
;@ test: angle = rng.choice([rand(0, 0x1F), rand(0, 255)]); dest = 0xCC80 + 4 * rand(0, 2)
;@ sig: ca834481
DrawTrailSprite::
;> y = u8(y - hi(wCamY))
	push de
	ld a, [wCamY + 1]
	ld e, a
	ld a, c
	sub e
	ld c, a
;> x = u16(x - (wCamX[1] | wCamX[2] << 8))
	ld a, [wCamX + 1]
	ld e, a
	ld a, [wCamX + 2]
	ld d, a
	call SubHLDE
	pop de
;> mem[dest] = u8(y + 0x14)
	ld a, c
	add $14
	ld [de], a
	inc de
;> mem[dest + 1] = u8(x + 0x0C)
	ld a, l
	add $0c
	ld [de], a
	inc de
;> tile = mem[0x5EC8 + (angle if angle < 0x20 else 0x04)]
	ld a, b
	cp $20
	jr c, jr_000_2489

	ld a, $04

jr_000_2489:
	ld hl, $5ec8
	rst $28
	ld a, [hl]
;> mem[dest + 2] = tile & 0x7F
	bit 7, a
	res 7, a
	ld [de], a
	inc de
;> mem[dest + 3] = 0x60 if tile & 0x80 else 0x00
	ld a, $00
	jr z, jr_000_249a

	ld a, $60

jr_000_249a:
	ld [de], a
;> return
	ret


Jump_000_249c:
;=@DrawTrail.h0
	xor a
	ld [wShadowOAM + 128], a

Jump_000_24a0:
;=@DrawTrail.h1
	xor a
	ld [wShadowOAM + 132], a

Jump_000_24a4:
;=@DrawTrail.h2
	xor a
	ld [wShadowOAM + 136], a
;=@DrawTrail.h3
	ret


;@ def PlaceBikeMarker()
;@ path: bike/draw
;@ Sprites 35 and 36 above bike 1: 16 and 8 pixels higher than its first sprite,
;@ 4 pixels further right (only the positions; the tiles are set elsewhere).
;@ reads: wShadowOAM
;@ sig: 78318e97
PlaceBikeMarker::
;> y = u8(wShadowOAM[0x00] - 0x10)
	ld hl, $cc8c
	ld a, [wShadowOAM]
	sub $10
	ld [hli], a
	ld c, a
;> x = u8(wShadowOAM[0x01] + 0x04)
	ld a, [wShadowOAM + 1]
	add $04
	ld [hli], a
	ld b, a
;> wShadowOAM[0x8C], wShadowOAM[0x8D] = y, x
;> wShadowOAM[0x90], wShadowOAM[0x91] = u8(y + 0x08), x
	inc hl
	inc hl
	ld a, $08
	add c
	ld [hli], a
	ld [hl], b
;> return
	ret


;@ def DrawItemPopup()
;@ path: bike/draw
;@ The picture of a picked-up item (sprites 28-31, 2 x 2) rises one pixel a frame
;@ for wItemPopup frames; it goes away early when it leaves the screen.
;@ writes: wItemPopup, wItemPopupY, wShadowOAM
;@ reads: wCamX, wCamY, wItemPopup, wItemPopupX, wItemPopupY
;@ test: wItemPopup = rng.choice([0, 1, rand(0, 40)])
;@ sig: 05cc4650
DrawItemPopup::
;> if wItemPopup:
	ld a, [wItemPopup]
	and a
	jr z, jr_000_2518

;>     wItemPopup -= 1
	dec a
	ld [wItemPopup], a
;>     wItemPopupY = u8(wItemPopupY - 1)        # it rises
	ld a, [wItemPopupY]
	dec a
	ld [wItemPopupY], a
;>     y = u8(wItemPopupY - hi(wCamY))
	ld a, [wCamY + 1]
	ld c, a
	ld a, [wItemPopupY]
	sub c
	ld c, a
;>     x = u8(wItemPopupX - wCamX[1])
	ld a, [wCamX + 1]
	ld b, a
	ld a, [wItemPopupX]
	sub b
	ld b, a
;>     if x & 0x80:
	rla
	jr nc, jr_000_24ee

;>         wItemPopup = 0
	xor a
	ld [wItemPopup], a
	jr jr_000_2518

jr_000_24ee:
;>     else:
;>         for i, (dy, dx) in enumerate(((0x10, 0x08), (0x10, 0x10), (0x18, 0x08), (0x18, 0x10))):
;>             wShadowOAM[0x70 + 4 * i] = u8(y + dy)
;>             wShadowOAM[0x71 + 4 * i] = u8(x + dx)
	ld hl, $cc70
	ld a, c
	add $10
	ld [hli], a
	ld a, b
	add $08
	ld [hli], a
	inc l
	inc l
	ld a, c
	add $10
	ld [hli], a
	ld a, b
	add $10
	ld [hli], a
	inc l
	inc l
	ld a, c
	add $18
	ld [hli], a
	ld a, b
	add $08
	ld [hli], a
	inc l
	inc l
	ld a, c
	add $18
	ld [hli], a
	ld a, b
	add $10
	ld [hl], a
;>         return
	ret


jr_000_2518:
;> wShadowOAM[0x70] = wShadowOAM[0x74] = wShadowOAM[0x78] = wShadowOAM[0x7C] = 0
;> return
	xor a
	ld [wShadowOAM + 112], a
	ld [wShadowOAM + 116], a
	ld [wShadowOAM + 120], a
	ld [wShadowOAM + 124], a
	ret


;@ def SetCameraSpeed()
;@ path: race/camera
;@ The camera moves with the bike: always sideways, up or down only while the bike
;@ heads away from the screen's upper part (its first sprite at or below y $40
;@ moving down, above it moving up).
;@ writes: wCamVelX, wCamVelY
;@ reads: wBikeVelX, wBikeVelY, wShadowOAM
;@ sig: 8bc67f2b
SetCameraSpeed::
;> wCamVelX = wBikeVelX
	ld a, [wBikeVelX]
	ld [wCamVelX], a
	ld a, [wBikeVelX + 1]
	ld [wCamVelX + 1], a
;> wCamVelY = 0
	xor a
	ld [wCamVelY], a
	ld [wCamVelY + 1], a
;> up = wBikeVelY & 0x8000
	ld a, [wBikeVelY + 1]
	bit 7, a
	jr nz, jr_000_2548

;> if not up and wShadowOAM[0x00] < 0x40: return
	ld a, [wShadowOAM]
	cp $40
	ret c

	jr jr_000_254e

jr_000_2548:
;> if up and wShadowOAM[0x00] >= 0x40: return
	ld a, [wShadowOAM]
	cp $40
	ret nc

jr_000_254e:
;> wCamVelY = wBikeVelY
;> return
	ld a, [wBikeVelY]
	ld [wCamVelY], a
	ld a, [wBikeVelY + 1]
	ld [wCamVelY + 1], a
	ret


;@ def MoveCamera()
;@ path: race/camera
;@ Moves the camera by wCamVelY (kept between 0 and $80 rows) and wCamVelX, and
;@ notes the direction (wScrollLeft) and whether it crossed into another tile
;@ column (wSameTileColumn). A finished crash (wBikeCrash = 4) freezes it.
;@ writes: wCamX, wCamY, wMathA, wSameTileColumn, wScrollLeft
;@ reads: wBikeCrash, wCamVelX, wCamVelY, wMathA
;@ test: wBikeCrash = rng.choice([4, rand(0, 3)])
;@ sig: 4c0a81f8
MoveCamera::
;> if wBikeCrash == 4: return
	ld a, [wBikeCrash]
	cp $04
	ret z

;> y = u16(wCamY + wCamVelY)
	ld hl, wCamY
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, [wCamVelY]
	ld l, a
	ld a, [wCamVelY + 1]
	ld h, a
	add hl, de
;> if (y & 0xC000) == 0xC000: y = 0                # above the top of the level
	ld a, h
	and $c0
	cp $c0
	jr nz, jr_000_257c

	ld hl, $0000
	jr jr_000_2585

jr_000_257c:
;> elif y >= 0x8000: y = 0x8000
	ld de, $8000
	rst $20
	jr c, jr_000_2585

	call SwapDEHL

jr_000_2585:
;> wCamY = y
	ld a, l
	ld [wCamY], a
	ld a, h
	ld [wCamY + 1], a
;> old = wCamX[1]
	ld hl, wCamX
	ld c, [hl]
	inc hl
	ld b, [hl]
;> wMathA = old
	ld a, b
	ld [wMathA], a
;> x = (wCamX[0] | old << 8 | wCamX[2] << 16) + (wCamVelX - 0x10000 if wCamVelX & 0x8000 else wCamVelX)
	inc hl
	ld e, [hl]
	ld a, [wCamVelX]
	ld l, a
	ld a, [wCamVelX + 1]
	ld h, a
	rla
	ld a, $00
	ld d, a
	jr nc, jr_000_25a9

	dec a
	inc d

jr_000_25a9:
	add hl, bc
	adc e
	ld e, a
;> wCamX[0] = x & 0xFF
	ld a, l
	ld [wCamX], a
;> wCamX[1] = (x >> 8) & 0xFF
	ld a, h
	ld [wCamX + 1], a
;> wCamX[2] = (x >> 16) & 0xFF
	ld a, e
	ld [wCamX + 2], a
;> wScrollLeft = 1 if wCamVelX & 0x8000 else 0
	ld a, d
	ld [wScrollLeft], a
;> wSameTileColumn = 0 if (old ^ wCamX[1]) & 0x08 else 1
	ld a, [wMathA]
	xor h
	bit 3, a
	ld a, $00
	jr nz, jr_000_25c7

	inc a

jr_000_25c7:
	ld [wSameTileColumn], a
;> return
	ret


;@ def SetColumnTargets()
;@ path: level/scroll
;@ Which metatile column to draw next: 3 columns left of the camera, in the level
;@ map (wColumnMap) and in BG map 0 (wColumnVRAM, 2 tiles per metatile, 16 to a
;@ row; moving right it is one metatile further left, wrapping round the row).
;@ writes: wColumnMap, wColumnVRAM, wMapColumn
;@ reads: wMapColumn, wScrollLeft
;@ sig: 372b709f
SetColumnTargets::
;> col = u8(((wCamX[2] & 0x0F) << 4 | wCamX[1] >> 4) - 3)
	ld hl, $c903
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, c
	and $f0
	ld c, a
	swap c
	swap b
	ld a, b
	and $f0
	or c
	sub $03
;> wMapColumn = col
	ld [wMapColumn], a
;> wColumnMap = addr(wLevelMap) + col
	ld l, a
	ld h, $00
	ld bc, wLevelMap
	add hl, bc
	ld e, l
	ld d, h
	ld a, e
	ld [wColumnMap], a
	ld a, d
	ld [wColumnMap + 1], a
;> vram = 0x9800 + 2 * (col & 0x0F)
	ld a, [wMapColumn]
	and $0f
	ld l, a
	ld h, $00
	add hl, hl
	ld bc, $9800
	add hl, bc
;> if not wScrollLeft:
	ld a, [wScrollLeft]
	and a
	jr nz, jr_000_2611

;>     vram -= 2
	dec hl
	dec hl
;>     if hi(vram) == 0x97: vram += 0x20         # round to the end of the row
	ld a, h
	cp $97
	jr nz, jr_000_2611

	ld bc, $0020
	add hl, bc

jr_000_2611:
;> wColumnVRAM = vram
	ld a, l
	ld [wColumnVRAM], a
	ld a, h
	ld [wColumnVRAM + 1], a
;> return
	ret


;@ def BuildMapColumn()
;@ path: level/scroll
;@ Turns one column of the level map (16 metatiles, top to bottom) into the two
;@ tile columns of wColumnTiles: the column at wColumnMap when scrolling left,
;@ 15 further on when scrolling right.
;@ reads: wColumnMap, wScrollLeft
;@ test: wColumnMap = 0xCE00 + rand(0, 255)
;@ sig: 95664051
BuildMapColumn::
;> p = wColumnMap
	ld a, [wColumnMap + 1]
	ld b, a
	ld a, [wColumnMap]
	ld c, a
;> if not wScrollLeft: p = (p & 0xFF00) | u8(p + 0x0F)
	ld a, [wScrollLeft]
	and a
	jr nz, jr_000_262c

	ld a, $0f
	add c
	ld c, a

jr_000_262c:
;> dest = addr(wColumnTiles)
;> for _ in range(16):
	ld de, wColumnTiles
	ld a, $10

jr_000_2631:
;>     dest = MetatileToColumn(mem[p], dest)
	push af
	ld a, [bc]
	push bc
	call MetatileToColumn
	pop bc
;>     p = u16(p + 0x100)                       # the next row of the map
	inc b
	pop af
	dec a
	jr nz, jr_000_2631

;> return
	ret


;@ def MetatileToColumn(n: a, dest: de) -> de
;@ path: level/scroll
;@ The four tiles of metatile n (top left, top right, bottom left, bottom right)
;@ into two tile columns 32 bytes apart: the ROM's metatiles at $5A30 below $A8,
;@ the composite ones in wCompMetatiles from $A8 on.
;@ test: dest = 0xCB80 + 2 * rand(0, 15)
;@ sig: 0feb6f75
MetatileToColumn::
;> src = 0x5A30 + 4 * n if n < 0xA8 else addr(wCompMetatiles) + 4 * (n - 0xA8)
	cp $a8
	ld bc, $5a30
	jr c, jr_000_264a

	ld bc, wCompMetatiles
	sub $a8

jr_000_264a:
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, bc
	call SwapDEHL
;> mem[dest] = mem[src]
	ld bc, $0020
	ld a, [de]
	ld [hl], a
;> mem[dest + 0x20] = mem[src + 1]
	inc de
	add hl, bc
	ld a, [de]
	ld [hli], a
;> mem[dest + 0x01] = mem[src + 2]
	inc de
	call SubHLBC
	ld a, [de]
	ld [hl], a
;> mem[dest + 0x21] = mem[src + 3]
	inc de
	add hl, bc
	ld a, [de]
	ld [hli], a
;> return dest + 2
	call SubHLBC
	jp SwapDEHL


;@ def DrawFirstScreen()
;@ path: level/draw
;@ The screen at the start of a race, drawn in one go: 16 rows of 16 metatiles of
;@ the level map, from 3 columns left of the camera (SetColumnTargets, with
;@ wScrollLeft set so the column is not moved one further), into BG map 0.
;@ writes: wScrollLeft
;@ reads: wColumnVRAM
;@ test: mem[0xC903] = rand(0, 255); mem[0xC904] = rand(0, 15)   # wCamX
;@ sig: d4ed3e72
DrawFirstScreen::
;> wScrollLeft = 1
	ld a, $01
	ld [wScrollLeft], a
;> SetColumnTargets()
	call SetColumnTargets
;> at = wColumnVRAM
	ld a, [wColumnVRAM]
	ld c, a
	ld a, [wColumnVRAM + 1]
	ld b, a
;> p = wColumnMap
;> for _ in range(16):                       # the rows
	ld h, $10

jr_000_267e:
	push hl
	push de
;>     q = p
;>     for _ in range(16):                   # 16 metatiles of the row
	ld a, $10

jr_000_2682:
	push af
;>         at = NextMetatileVRAM(DrawMetatile(mem[q], at))
	ld a, [de]
	push de
	call DrawMetatile
	pop de
	call NextMetatileVRAM
;>         q = MapColumnRight(q)
	call MapColumnRight
	pop af
	dec a
	jr nz, jr_000_2682

;>     at = u16(at + 0x40)                   # two tile rows down
	ld hl, $0040
	add hl, bc
	ld c, l
	ld b, h
;>     p = u16(p + 0x100)                    # the next map row
	pop de
	inc d
	pop hl
	dec h
	jr nz, jr_000_267e

;> return
	ret


;@ def DrawMetatile(n: a, at: bc) -> bc
;@ path: level/draw
;@ Draws metatile n (2 x 2 tiles) into the BG map with its top left tile at `at`: the
;@ ROM's metatiles at $5A30 for n < $A8, the composite ones in wCompMetatiles from $A8 on.
;@ Returns the address of its bottom right tile.
;@ test: at = rand(0x9800, 0x9BDE)
;@ sig: 91398c22
DrawMetatile::
;> if n < 0xA8:
;>     p = 0x5A30 + 4 * n
;> else:
;>     p = addr(wCompMetatiles) + 4 * (n - 0xA8)
	cp $a8
	ld de, $5a30
	jr c, jr_000_26ac

	ld de, wCompMetatiles
	sub $a8

jr_000_26ac:
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, de
;> PutTileBC(mem[p], at)                      # top left
	ld a, [hli]
	call PutTileBC
;> at = u16(at + 1)
;> PutTileBC(mem[p + 1], at)                  # top right
	inc bc
	ld a, [hli]
	call PutTileBC
;> at = u16(at + 0x1F)                        # a row down, a column back
;> PutTileBC(mem[p + 2], at)                  # bottom left
	ld a, $1f
	add c
	ld c, a
	jr nc, jr_000_26c2

	inc b

jr_000_26c2:
	ld a, [hli]
	call PutTileBC
;> at = u16(at + 1)
;> PutTileBC(mem[p + 3], at)                  # bottom right
;> return at
	inc bc
	ld a, [hl]
	call PutTileBC
	ret


;@ def NextMetatileVRAM(at: bc) -> bc
;@ path: level/draw
;@ From a metatile's bottom right tile (what DrawMetatile returns) to the top left tile
;@ of the next metatile to the right, wrapping round the 32-tile row of the BG map.
;@ sig: a0be068b
NextMetatileVRAM::
;> at = u16(at - 0x1F)                        # a row up, a column on
;> if at & 0x1F: return at
	ld hl, $ffe1
	add hl, bc
	ld c, l
	ld b, h
	ld a, c
	and $1f
	ret nz

;> return u16(at - 0x20)                      # past the row's end: back to its start
	ld hl, $ffe0
	add hl, bc
	ld c, l
	ld b, h
	ret


;@ def MapColumnRight(p: de) -> de
;@ path: level/map
;@ One metatile to the right in the level map, wrapping round its 256-column row.
;@ sig: 2e9c2bb4
MapColumnRight::
;> p = u16(p + 1)
;> if lo(p): return p
	inc de
	ld a, e
	and a
	ret nz

;> return u16(p - 0x100)
	dec d
	ret


;@ def CopyTileColumn()
;@ path: level/scroll
;@ VBlank: copies one tile column of wColumnTiles into BG map 0 at wColumnVRAM, top to
;@ bottom. With bit 3 of the camera's x set it is the metatile column's left tiles,
;@ otherwise its right tiles, one BG column further on (wrapping round the 32 columns).
;@ reads: wCamX, wColumnVRAM
;@ test: wColumnVRAM = rand(0x9800, 0x981F)
;@ sig: 8d435fbf
CopyTileColumn::
;> vram = wColumnVRAM
;> src = addr(wColumnTiles)
;> if not wCamX[1] & 0x08:
;>     src += 32                              # the right half of the metatiles
;>     vram = u16(vram + 1) & 0xFFDF
	ld a, [wColumnVRAM]
	ld l, a
	ld a, [wColumnVRAM + 1]
	ld h, a
	ld de, wColumnTiles
	ld a, [wCamX + 1]
	bit 3, a
	jr nz, jr_000_26fb

	ld de, $cba0
	inc hl
	res 5, l

jr_000_26fb:
;> while True:
;>     mem[vram] = mem[src]
;>     src += 1
;>     vram = u16(vram + 32)
;>     if vram & 0x0400: return               # past the bottom of BG map 0
	ld bc, $0020

jr_000_26fe:
	ld a, [de]
	ld [hl], a
	inc de
	add hl, bc
	bit 2, h
	jr z, jr_000_26fe

	ret


;@ def PlaceTrackPieces(lists: hl)
;@ path: level/build
;@ Builds the course's track in wLevelMap. `lists` is a word table with one list per
;@ course; a list holds row, column and piece number for each piece, and ends with $FF.
;@ A piece (the word table at $56DD) is its height, its width and then its metatiles,
;@ which are stamped onto the map row by row (StampMetatile). A piece's rows wrap round
;@ the map's 256 columns, and whatever would fall below the map's 16th row is left out.
;@ reads: wCourse
;@ test: lists = rand_ram(2); l = rand_ram(7); mem[lists] = l & 0xFF; mem[lists + 1] = l >> 8; wCourse = 1
;@ test: mem[l] = rand(0, 15); mem[l + 1] = rand(0, 255); mem[l + 2] = rand(0, 12); mem[l + 3] = rand(0, 15)
;@ test: mem[l + 4] = rand(0, 255); mem[l + 5] = rand(0, 12); mem[l + 6] = 0xFF; wLastMetatile = rand(0xA8, 0xC0)
;@ sig: 7c00664f
PlaceTrackPieces::
;> p = mem16[u16(lists + u8(2 * u8(wCourse - 1)))]
	ld a, [wCourse]
	dec a
	add a
	rst $28
	ld e, [hl]
	inc hl
	ld d, [hl]

jr_000_2710:
;> while True:
;>     row = mem[p]
;>     if row == 0xFF: return
	ld a, [de]
	inc de
	ld c, a
	inc a
	ret z

;>     cell = u16(addr(wLevelMap) + (row << 8) + mem[p + 1])
;>     piece = mem16[0x56DD + 2 * mem[p + 2]]
;>     p = u16(p + 3)
;>     height, width = mem[piece], mem[piece + 1]
;>     src = u16(piece + 2)
	ld a, [de]
	inc de
	ld b, a
	ld h, c
	ld l, b
	ld bc, wLevelMap
	add hl, bc
	ld a, [de]
	inc de
	push de
	push hl
	ld de, $56dd
	rst $00
	pop hl
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	inc de

jr_000_272d:
;>     for _ in range(height or 256):
;>         at = cell
	push bc
	push hl

jr_000_272f:
;>         for _ in range(width or 256):
;>             StampMetatile(at, src)
	call StampMetatile
;>             at = u16(at + 1)
;>             if not lo(at): at = u16(at - 0x100)    # round the row
	inc hl
	ld a, l
	and a
	jr nz, jr_000_2738

	dec h

jr_000_2738:
;>             src = u16(src + 1)
	inc de
	dec b
	jr nz, jr_000_272f

;>         cell = u16(cell + 0x100)               # the next map row
;>         if hi(cell) >= 0xDE: break            # below the map
	pop hl
	inc h
	ld a, h
	cp $de
	jr nc, jr_000_274a

	pop bc
	dec c
	jr nz, jr_000_272d

	pop de
	jr jr_000_2710

jr_000_274a:
	pop bc
	pop de
	jr jr_000_2710

;@ def PlaceItemMetatiles(lists: hl)
;@ path: level/build
;@ Draws the course's items into wLevelMap. The lists have the same layout as the
;@ track's (row, column, kind; the word table at $5F0C): an item's kind is also the
;@ number of the metatile that shows it, stamped onto its cell. Kinds 6 and 7 are not drawn.
;@ reads: wCourse
;@ test: lists = 0x5F0C; wCourse = rand(1, 8); wLastMetatile = rand(0xA8, 0xC0)
;@ sig: 6d545915
PlaceItemMetatiles::
;> p = mem16[u16(lists + u8(2 * u8(wCourse - 1)))]
	ld a, [wCourse]
	dec a
	add a
	rst $28
	ld e, [hl]
	inc hl
	ld d, [hl]

jr_000_2757:
;> while True:
;>     row = mem[p]
;>     if row == 0xFF: return
	ld a, [de]
	inc de
	ld c, a
	inc a
	ret z

;>     cell = u16(addr(wLevelMap) + (row << 8) + mem[p + 1])
;>     kind = mem[p + 2]
;>     if kind != 6 and kind != 7: StampMetatile(cell, u16(p + 2))
	ld a, [de]
	inc de
	ld b, a
	ld h, c
	ld l, b
	ld bc, wLevelMap
	add hl, bc
	ld a, [de]
	cp $06
	jr z, jr_000_2771

	cp $07
	jr z, jr_000_2771

	call StampMetatile

jr_000_2771:
;>     p = u16(p + 3)
	inc de
	jr jr_000_2757

;@ def StampMetatile(cell: hl, src: de)
;@ path: level/build
;@ Puts the metatile at src onto a cell of the level map. An empty cell ($FF) simply
;@ takes it, and $FF in a piece clears the cell. Otherwise the two are combined: the
;@ piece's tiles over the cell's (OverlayPieceTiles), and the result is an existing
;@ metatile with these 4 tiles or a new composite one (AddMetatile). In a link game
;@ item 3 (a clock) becomes item 4.
;@ reads: wPlayerMask
;@ test: cell = rand_ram(1); src = rand_ram(1); wLastMetatile = rand(0xA8, 0xC0)
;@ sig: a91e8310
StampMetatile::
;> old = mem[cell]
;> new = mem[src]
;> if wPlayerMask & 0x04 and new == 0x03: new = 0x04
	push de
	push hl
	push bc
	ld b, [hl]
	ld a, [de]
	ld c, a
	ld a, [wPlayerMask]
	and $04
	jr z, jr_000_2788

	ld a, c
	cp $03
	jr nz, jr_000_2788

	ld c, $04

jr_000_2788:
;> if old == 0xFF: result = new               # an empty cell
	inc b
	ld a, c
	jr z, jr_000_27af

;> elif new == 0xFF: result = 0xFF            # the piece clears the cell
	inc a
	jr z, jr_000_27ae

;> else:
;>     GetMetatileTiles(old, 0xC890)
	push bc
	push de
	ld a, [hl]
	ld bc, wMathA
	call GetMetatileTiles
	pop de
	pop bc
;>     GetMetatileTiles(new, 0xC894)
;>     OverlayPieceTiles()
;>     found, n = FindMetatile()
;>     result = n if found else AddMetatile()
	ld a, c
	ld bc, wMathNegCos
	call GetMetatileTiles
	call OverlayPieceTiles
	call FindMetatile
	jr c, jr_000_27af

	call AddMetatile
	jr jr_000_27af

jr_000_27ae:
	dec a

;> mem[cell] = result
jr_000_27af:
	pop bc
	pop hl
	pop de
	ld [hl], a
	ret


;@ def GetMetatileTiles(n: a, dest: bc)
;@ path: level/map
;@ Copies the 4 tiles of metatile n (top left, top right, bottom left, bottom right)
;@ to dest: from the ROM's table at $5A30, or from wCompMetatiles for n >= $A8.
;@ test: dest = rand_ram(4)
;@ sig: 16bf55dc
GetMetatileTiles::
;> if n < 0xA8:
;>     p = 0x5A30 + 4 * n
;> else:
;>     p = addr(wCompMetatiles) + 4 * (n - 0xA8)
	cp $a8
	ld de, $5a30
	jr c, jr_000_27c0

	ld de, wCompMetatiles
	sub $a8

jr_000_27c0:
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, de
;> copy(dest, p, 4)
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a
	ret


;@ def OverlayPieceTiles()
;@ path: level/build
;@ Lays the piece's 4 tiles ($C894) over the cell's ($C890): every tile but $7F, which
;@ is see-through, replaces the one below it.
;@ sig: b3349a53
OverlayPieceTiles::
;> for i in range(4):
;>     t = mem[0xC894 + i]
;>     if t != 0x7F: mem[0xC890 + i] = t
	ld hl, wMathA
	ld de, wMathNegCos
	ld b, $04

jr_000_27da:
	ld a, [de]
	cp $7f
	jr z, jr_000_27e0

	ld [hl], a

jr_000_27e0:
	inc hl
	inc de
	dec b
	jr nz, jr_000_27da

	ret


;@ def FindMetatile() -> (carry, c)
;@ path: level/build
;@ Looks for a metatile made of the 4 tiles at $C890: among the ROM's 168, then among
;@ the composite ones. Returns carry and its number when there is one. The second
;@ search counts wLastMetatile entries (not wLastMetatile - $A7), so it also looks at
;@ entries past the composites made so far.
;@ reads: wLastMetatile
;@ sig: 95412456
FindMetatile::
;> found, n = SearchMetatiles(0x5A30, 0x00, 0xA8)
;> if found: return True, n
	ld hl, $5a30
	ld c, $00
	ld b, $a8
	call SearchMetatiles
	ret c

;> return SearchMetatiles(addr(wCompMetatiles), 0xA8, wLastMetatile)
	ld hl, wCompMetatiles
	ld c, $a8
	ld a, [wLastMetatile]
	ld b, a

;@ def SearchMetatiles(table: hl, n: c, count: b) -> (carry, c)
;@ path: level/build
;@ Compares the 4 tiles at $C890 with `count` metatiles from table (numbered from n
;@ on). Returns carry and the number of the first one with the same tiles; without one
;@ no carry and the number after the last one compared.
;@ test: table = rand(0x0000, 0x7000)
;@ sig: d8d47037
SearchMetatiles::
;> for _ in range(count or 256):
;>     if [mem[0xC890 + i] for i in range(4)] == [mem[u16(table + i)] for i in range(4)]:
;>         return True, n
	ld de, wMathA
	ld a, [de]
	cp [hl]
	jr nz, jr_000_2815

	inc hl
	inc de
	ld a, [de]
	cp [hl]
	jr nz, jr_000_2816

	inc hl
	inc de
	ld a, [de]
	cp [hl]
	jr nz, jr_000_2817

	inc hl
	inc de
	ld a, [de]
	cp [hl]
	jr nz, jr_000_2818

	jr jr_000_281f

;>     table = u16(table + 4)
;>     n = u8(n + 1)
jr_000_2815:
	inc hl

jr_000_2816:
	inc hl

jr_000_2817:
	inc hl

jr_000_2818:
	inc hl
	inc c
	dec b
	jr nz, SearchMetatiles

;> return False, n
	and a
	ret


jr_000_281f:
	ld a, c
	scf
	ret


;@ def AddMetatile() -> a
;@ path: level/build
;@ Makes the 4 tiles at $C890 a new composite metatile: the next number after
;@ wLastMetatile, its tiles in wCompMetatiles. Returns its number.
;@ writes: wLastMetatile
;@ reads: wLastMetatile
;@ test: wLastMetatile = rand(0xA7, 0xFE)
;@ sig: 565eb87f
AddMetatile::
;> wLastMetatile = u8(wLastMetatile + 1)
;> n = wLastMetatile
	ld a, [wLastMetatile]
	inc a
	ld [wLastMetatile], a
	push af
;> CopyBytes(0xC890, u16(addr(wCompMetatiles) + 4 * u8(n - 0xA8)), 4)
;> return n
	sub $a8
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	ld de, wCompMetatiles
	add hl, de
	ld e, l
	ld d, h
	ld hl, wMathA
	ld bc, $0004
	call CopyBytes
	pop af
	ret


;@ def ReadTilesAroundBike()
;@ path: bike/track
;@ Copies the 3 x 3 metatiles of the level around the bike, as 6 x 6 tiles, into
;@ wTileGrid (the metatile one row above the bike's is the grid's top left).
;@ sig: b30c14a6
ReadTilesAroundBike::
;> CopyTileGrid(MapAddrAt(hi(wBikeY), wBikeX[1] | wBikeX[2] << 8), addr(wTileGrid))
	ld hl, $c786
	ld a, [hli]
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	call MapAddrAt
	ld bc, wTileGrid
	call CopyTileGrid
	ret


;@ def MapAddrAt(y: a, x: bc) -> hl
;@ path: level/map
;@ The level map cell one metatile row above the point (x, y) in level pixels: map
;@ row y / 16 - 1, column x / 16 (mod 256). For y < 16 that is the row above the map.
;@ sig: e71c4ca9
MapAddrAt::
;> row = y >> 4
;> col = (x >> 4) & 0xFF
	and $f0
	swap a
	ld e, a
	ld a, c
	and $f0
	ld c, a
	swap c
	swap b
	ld a, b
	and $f0
	or c
	ld d, a
;> p = u16(addr(wLevelMap) + (((row + 15) % 16) << 8) + col)
	ld a, e
	add $0f

jr_000_2869:
	cp $10
	jr c, jr_000_2871

	sub $10
	jr jr_000_2869

jr_000_2871:
	ld h, a
	ld l, d
	ld bc, wLevelMap
	add hl, bc
;> if row: return p
	ld a, e
	and a
	ret nz

;> return u16(p - 0x1000)                      # the row above the map
	ld a, h
	sub $10
	ld h, a
	ret


;@ def CopyTileGrid(p: hl, dest: bc)
;@ path: level/map
;@ Copies 3 x 3 metatiles of the level map, from cell p to the right and down, as their
;@ 6 x 6 tiles to dest (6 bytes a row). The columns wrap round the map's row.
;@ test: dest = rand_ram(36)
;@ sig: efd9a388
CopyTileGrid::
;> start = p
	ld e, l
	ld d, h
	ld a, $03

jr_000_2883:
;> for _ in range(3):
;>     q = start
	push af
	ld a, $03
	push de

jr_000_2887:
;>     for _ in range(3):
;>         dest = MetatileToGrid(mem[q], dest)
	push af
	ld a, [de]
	push de
	call MetatileToGrid
;>         dest = GridNextMetatile(dest)
;>         q = GridMapColumnRight(q)
	pop de
	call GridNextMetatile
	call GridMapColumnRight
	pop af
	dec a
	jr nz, jr_000_2887

;>     dest = GridNextRow(dest)
;>     start = GridMapRowDown(start)
	pop de
	call GridNextRow
	call GridMapRowDown
	pop af
	dec a
	jr nz, jr_000_2883

	ret


;@ def MetatileToGrid(n: a, dest: bc) -> bc
;@ path: level/map
;@ Writes the 4 tiles of metatile n into a grid 6 tiles wide: the top two at dest, the
;@ bottom two a grid row (6 bytes) below. Returns dest + 7.
;@ test: dest = rand_ram(8)
;@ sig: 70da1341
MetatileToGrid::
;> if n < 0xA8:
;>     p = 0x5A30 + 4 * n
;> else:
;>     p = addr(wCompMetatiles) + 4 * (n - 0xA8)
	cp $a8
	ld de, $5a30
	jr c, jr_000_28b0

	ld de, wCompMetatiles
	sub $a8

jr_000_28b0:
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, de
;> mem[dest], mem[u16(dest + 1)] = mem[p], mem[p + 1]
;> mem[u16(dest + 6)], mem[u16(dest + 7)] = mem[p + 2], mem[p + 3]
;> return u16(dest + 7)
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hli]
	ld [bc], a
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a
	ret


;@ def GridNextMetatile(dest: bc) -> bc
;@ path: level/map
;@ From MetatileToGrid's result to the next metatile's place in the grid (2 tiles on).
;@ sig: 76cdab4e
GridNextMetatile::
;> return u16(dest - 5)
	dec bc
	dec bc
	dec bc
	dec bc
	dec bc
	ret


;@ def GridMapColumnRight(p: de) -> de
;@ path: level/map
;@ One metatile to the right in the level map, wrapping round its 256-column row
;@ (the same as MapColumnRight).
;@ sig: 2e9c2bb4
GridMapColumnRight::
;> p = u16(p + 1)
;> if lo(p): return p
	inc de
	ld a, e
	and a
	ret nz

;> return u16(p - 0x100)
	dec d
	ret


;@ def GridNextRow(dest: bc) -> bc
;@ path: level/map
;@ From the end of a row of 3 metatiles to the start of the next one in the grid
;@ (2 tile rows of 6 down).
;@ sig: b4d6f5fd
GridNextRow::
;> return u16(dest + 6)
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	inc bc
	ret


;@ def GridMapRowDown(p: de) -> de
;@ path: level/map
;@ One row down in the level map, wrapping from the bottom row to the top. A cell in
;@ column 0 of the bottom row goes to $DE00 instead, past the map (the test is <=).
;@ sig: b5281d5a
GridMapRowDown::
;> p = u16(p + 0x100)
;> if p <= 0xDE00: return p
	inc d
	ld hl, $de00
	rst $20
	ret nc

;> return u16(p - 0x1000)                      # round to the top row
	ld hl, $f000
	add hl, de
	ld e, l
	ld d, h
	ret


;@ def ProbeTrackTiles()
;@ path: bike/track
;@ Reads the tiles at the points around the bike that the physics test, out of
;@ wTileGrid: three points for the direction the bike moves in and two for the way it
;@ leans (the table at $5DA0, 3 bytes per angle), the tile right of the third point,
;@ and five fixed points. Then looks up what the first 10 are (the tile kinds at
;@ $5CA0) into wProbeKinds.
;@ writes: wProbeTiles
;@ reads: wBikeAngle, wBikeMode, wBikeMoveAngle
;@ sig: 01205a84
ProbeTrackTiles::
;> p = u16(0x5DA0 + u8(3 * wBikeMoveAngle))
;> first = mem[p]
	ld a, [wBikeMoveAngle]
	ld hl, $5da0
	ld c, a
	add a
	add c
	rst $28
	ld e, [hl]
;> if wBikeMoveAngle == 4 and wBikeMode == 1: first = 0x16
	ld a, [wBikeMoveAngle]
	cp $04
	jr nz, jr_000_2900

	ld a, [wBikeMode]
	dec a
	jr nz, jr_000_2900

	ld e, $16

jr_000_2900:
;> second, third = mem[p + 1], mem[p + 2]
	inc hl
	ld d, [hl]
	inc hl
	ld c, [hl]
;> wProbeTiles[0] = GridTileAt(first)[0]
	ld b, e
	call GridTileAt
	ld [wProbeTiles], a
;> wProbeTiles[1] = GridTileAt(second)[0]
	ld b, d
	call GridTileAt
	ld [wProbeTiles + 1], a
;> wProbeTiles[2], at = GridTileAt(third)
	ld b, c
	call GridTileAt
	ld [wProbeTiles + 2], a
;> wProbeTiles[3] = mem[u16(at + 1)]           # the tile right of the third point
	inc hl
	ld a, [hl]
	ld [wProbeTiles + 3], a
;> wProbeTiles[4] = GridTileAt(0x1A)[0]
	ld b, $1a
	call GridTileAt
	ld [wProbeTiles + 4], a
;> wProbeTiles[5] = GridTileAt(0x1B)[0]
	ld b, $1b
	call GridTileAt
	ld [wProbeTiles + 5], a
;> wProbeTiles[8] = GridTileAt(0x0F)[0]
	ld b, $0f
	call GridTileAt
	ld [wProbeTiles + 8], a
;> wProbeTiles[9] = GridTileAt(0x15)[0]
	ld b, $15
	call GridTileAt
	ld [wProbeTiles + 9], a
;> wProbeTiles[10] = GridTileAt(0x0E)[0]
	ld b, $0e
	call GridTileAt
	ld [wProbeTiles + 10], a
;> q = u16(0x5DA0 + u8(3 * wBikeAngle))        # the way the bike leans
	ld a, [wBikeAngle]
	ld hl, $5da0
	ld c, a
	add a
	add c
	rst $28
	ld e, [hl]
	inc hl
	ld d, [hl]
;> wProbeTiles[6] = GridTileAt(mem[q])[0]
	ld b, e
	call GridTileAt
	ld [wProbeTiles + 6], a
;> wProbeTiles[7] = GridTileAt(mem[q + 1])[0]
	ld b, d
	call GridTileAt
	ld [wProbeTiles + 7], a
;> for i in range(10):
;>     wProbeKinds[i] = mem[u16(0x5CA0 + wProbeTiles[i])]
	ld de, wProbeTiles
	ld bc, wProbeKinds
	ld a, $0a

jr_000_2969:
	push af
	ld a, [de]
	ld hl, $5ca0
	rst $28
	ld a, [hl]
	ld [bc], a
	inc bc
	inc de
	pop af
	dec a
	jr nz, jr_000_2969

	ret


;@ def GridTileAt(i: b) -> (a, hl)
;@ path: bike/track
;@ The tile of wTileGrid at index i, counted from the bike: i is moved a tile row down
;@ (+6) when the bike is in the lower half of its metatile and a tile left (-1) when it
;@ is in the left half. Returns the tile and its address.
;@ reads: wBikeX, wBikeY
;@ sig: accd44e9
GridTileAt::
;> if hi(wBikeY) & 0x08: i = u8(i + 6)
	ld hl, wTileGrid
	ld a, [wBikeY + 1]
	bit 3, a
	ld a, b
	jr z, jr_000_2985

	add $06

jr_000_2985:
	ld b, a
;> if not wBikeX[1] & 0x08: i = u8(i - 1)
	ld a, [wBikeX + 1]
	bit 3, a
	ld a, b
	jr nz, jr_000_298f

	dec a

jr_000_298f:
;> at = u16(addr(wTileGrid) + i)
;> return mem[at], at
	rst $28
	ld a, [hl]
	ret


;@ def BuildItemList()
;@ path: items
;@ Fills wItems from the course's item list (the word table at $5F0C: row, column and
;@ kind per item, ending with $FF): kind, both players may take it ($03), y and x in
;@ pixels, row and column. In a link game clocks (kind 3) become kind 4 and kind 7 is
;@ left out.
;@ writes: wItemCount
;@ reads: wCourse, wItemCount, wPlayerMask
;@ test: wCourse = rand(1, 8)
;@ sig: 08af0eeb
BuildItemList::
;> wItemCount = 0
;> p = mem16[0x5F0C + 2 * u8(wCourse - 1)]
;> rec = addr(wItems)
	xor a
	ld [wItemCount], a
	ld de, $5f0c
	ld a, [wCourse]
	dec a
	rst $00
	ld bc, wItems

jr_000_29a1:
;> while True:
;>     row = mem[p]
;>     if row == 0xFF: return
	ld a, [de]
	inc a
	ret z

;>     wItemCount = u8(wItemCount + 1)
;>     col, kind = mem[p + 1], mem[p + 2]
	dec a
	ld l, a
	ld a, [wItemCount]
	inc a
	ld [wItemCount], a
	inc de
	inc de
;>     if wPlayerMask & 0x04:                    # a link game
;>         if kind == 3: kind = 4
;>         elif kind == 7:
;>             wItemCount = u8(wItemCount - 1)
;>             p = u16(p + 3)
;>             continue
	ld a, [wPlayerMask]
	and $04
	ld a, [de]
	jr nz, jr_000_29e0

jr_000_29b7:
;>     mem[rec] = kind
;>     mem[rec + 1] = 0x03                       # both players may take it
;>     mem[rec + 2] = u8(row << 4)
;>     mem[rec + 3], mem[rec + 4] = lo(col << 4), hi(col << 4)
;>     mem[rec + 5], mem[rec + 6] = row, col
;>     rec = (rec & 0xFF00) | u8(rec + 8)
	ld [bc], a
	dec de
	inc c
	ld a, $03
	ld [bc], a
	inc c
	ld a, l
	add a
	add a
	add a
	add a
	ld [bc], a
	inc c
	ld a, [de]
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	ld a, l
	ld [bc], a
	inc c
	ld a, h
	ld [bc], a
	inc c
	dec de
	ld a, [de]
	ld [bc], a
	inc c
	inc de
	ld a, [de]
	ld [bc], a
	inc c
	inc c
	inc de

jr_000_29dd:
;>     p = u16(p + 3)
	inc de
	jr jr_000_29a1

jr_000_29e0:
	ld a, [de]
	cp $03
	jr z, jr_000_29eb

	cp $07
	jr z, jr_000_29ef

	jr jr_000_29b7

jr_000_29eb:
	ld a, $04
	jr jr_000_29b7

jr_000_29ef:
	ld a, [wItemCount]
	dec a
	ld [wItemCount], a
	jr jr_000_29dd

;@ def CollectItems()
;@ path: items
;@ Checks every item of wItems against the bike and collects the ones it touches.
;@ The first player's bike also clears wEraseItem first.
;@ writes: wEraseItem
;@ reads: wBikeId, wBikeX, wBikeY, wItemCount
;@ test: wItemCount = rand(1, 32)
;@ sig: f4d8687d
CollectItems::
;> who = wBikeId
;> if who == 1: wEraseItem = 0
	ld a, [wBikeId]
	ld b, a
	dec a
	jr nz, jr_000_2a03

	xor a
	ld [wEraseItem], a

jr_000_2a03:
;> y = hi(wBikeY)
;> x = wBikeX[1] | (wBikeX[2] & 0x0F) << 8
	ld a, [wBikeY + 1]
	ld c, a
	ld a, [wBikeX + 1]
	ld l, a
	ld a, [wBikeX + 2]
	and $0f
	ld h, a
	call SwapDEHL
;> rec = addr(wItems)
;> for _ in range(wItemCount or 256):
;>     if ItemTouched(rec, who, y, x): CollectItem(rec, who)
;>     rec = u16(rec + 8)
	ld hl, wItems
	ld a, [wItemCount]

jr_000_2a1a:
	push af
	push de
	push bc
	push hl
	call ItemTouched
	pop hl
	pop bc
	push bc
	push hl
	call c, CollectItem
	pop hl
	pop bc
	ld a, $08
	rst $28
	pop de
	pop af
	dec a
	jr nz, jr_000_2a1a

	ret


;@ def ItemTouched(rec: hl, who: b, y: c, x: de) -> carry
;@ path: items
;@ Whether the bike at (x, y) touches the item at rec: less than 15 pixels from it
;@ both ways, and the item still there for this bike (who: bit 0 the first player,
;@ bit 1 the second). Items 6 and 7 count only while the bike is upside down
;@ (wBikeAngle $10).
;@ reads: wBikeAngle
;@ sig: c0c9f2bb
ItemTouched::
;> kind = mem[rec]
;> if kind >= 6 and wBikeAngle != 0x10: return False
	ld a, [hli]
	cp $06
	jr c, jr_000_2a3f

	ld a, [wBikeAngle]
	cp $10
	jr nz, jr_000_2a5e

jr_000_2a3f:
;> if not mem[rec + 1] & who: return False      # taken already
	ld a, [hli]
	and b
	jr z, jr_000_2a5e

;> dy = u8(mem[rec + 2] + 0x0F)
;> if dy < y or dy - y >= 0x1E: return False
	ld a, [hli]
	add $0f
	sub c
	jr c, jr_000_2a5e

	cp $1e
	jr nc, jr_000_2a5e

;> ix = u16(mem[rec + 3] + (mem[rec + 4] << 8) + 0x0F)
;> if ix < x: return False
;> return u16(ix - x) < 0x1E
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, $000f
	add hl, bc
	call SubHLDE
	jr c, jr_000_2a5e

	ld de, $001e
	rst $20
	ret


jr_000_2a5e:
	xor a
	ret


;@ def CollectItem(rec: hl, who: b)
;@ path: items
;@ The bike takes the item at rec (MarkItemTaken marks it taken), then the item does its
;@ thing: entry kind - 2 of ItemEffects.
;@ test: rec = rand_ram(8); mem[rec] = rand(2, 7); wTimeSeconds = to_bcd(rand(0, 59)); wTimeMinutes = to_bcd(rand(0, 98))
;@ sig: b0fba738
CollectItem::
;> MarkItemTaken(rec, who)
	push hl
	push bc
	call MarkItemTaken
	pop bc
	pop hl
;> kind = mem[rec]
;> if kind == 2: return ItemTopSpeed()
;> if kind == 3: return ItemClock()
;> if kind == 4: return ItemNitro()
;> if kind == 5: return ItemPowerUpA()
;> if kind == 6: return ItemPowerUpB(who)
;> return ItemPowerUpLevel(who)
	ld a, [hl]
	sub $02
	call JumpTable

ItemEffects::
	dw ItemTopSpeed
	dw ItemClock
	dw ItemNitro
	dw ItemPowerUpA
	dw ItemPowerUpB
	dw ItemPowerUpLevel

;@ def ItemTopSpeed()
;@ path: items
;@ Item 2: the bike's top speed goes up from $4F to $6F.
;@ writes: wBikeTopSpeed
;@ sig: 71240b2e
ItemTopSpeed::
;> wBikeTopSpeed = 0x6F
;> PlayBikeSound(0x0D)
	ld a, $6f
	ld [wBikeTopSpeed], a
	ld a, $0d
	jp PlayBikeSound


;@ def ItemClock()
;@ path: items
;@ Item 3, the clock: 10 more seconds.
;@ writes: wTimeMinutes, wTimeSeconds
;@ reads: wTimeMinutes, wTimeSeconds
;@ test: wTimeSeconds = to_bcd(rand(0, 59)); wTimeMinutes = to_bcd(rand(0, 98))
;@ sig: 11fd5458
ItemClock::
;> PlaySound(0x0E)
	ld a, $0e
	call PlaySound
;> s = bcd_to_int(wTimeSeconds) + 10
;> wTimeSeconds = to_bcd(s)
;> if s < 60: return
	ld a, [wTimeSeconds]
	add $10
	daa
	ld [wTimeSeconds], a
	cp $60
	ret c

;> wTimeSeconds = to_bcd(s - 60)
;> wTimeMinutes = to_bcd(bcd_to_int(wTimeMinutes) + 1)
	sub $60
	ld [wTimeSeconds], a
	ld a, [wTimeMinutes]
	add $01
	daa
	ld [wTimeMinutes], a
	ret


;@ def ItemNitro()
;@ path: items
;@ Item 4: four more nitro boosts.
;@ writes: wNitro
;@ reads: wNitro
;@ sig: ad67d285
ItemNitro::
;> wNitro = u8(wNitro + 4)
;> PlayBikeSound(0x0D)
	ld a, [wNitro]
	add $04
	ld [wNitro], a
	ld a, $0d
	jp PlayBikeSound


;@ def ItemPowerUpA()
;@ path: items
;@ Item 5: sets wPowerUpA.
;@ writes: wPowerUpA
;@ sig: 86556422
ItemPowerUpA::
;> wPowerUpA = 1
;> PlayBikeSound(0x0D)
	ld a, $01
	ld [wPowerUpA], a
	ld a, $0d
	jp PlayBikeSound


;@ def ItemPowerUpB(who: b)
;@ path: items
;@ Item 6 (found upside down): sets wPowerUpB and shows its picture above the bike.
;@ writes: wPowerUpB
;@ sig: 82285a22
ItemPowerUpB::
;> wPowerUpB = 1
;> return ShowItemPopup(who, PowerUpBPopupTiles)
	ld a, $01
	ld [wPowerUpB], a
	ld de, PowerUpBPopupTiles
	jp ShowItemPopup


;@ The 4 sprite tiles of the picture shown above the bike when it takes item 6 (ShowItemPopup).
PowerUpBPopupTiles::
	db $c5, $c6, $c7, $c8

;@ def ItemPowerUpLevel(who: b)
;@ path: items
;@ Item 7 (found upside down): wPowerUpLevel goes up by one, to at most 3, and its
;@ picture shows above the bike.
;@ writes: wPowerUpLevel
;@ reads: wPowerUpLevel
;@ sig: 4817fb2b
ItemPowerUpLevel::
;> if wPowerUpLevel != 3: wPowerUpLevel += 1
	ld a, [wPowerUpLevel]
	cp $03
	jr z, jr_000_2ad4

	inc a
	ld [wPowerUpLevel], a

jr_000_2ad4:
;> return ShowItemPopup(who, PowerUpLevelPopupTiles)
	ld de, PowerUpLevelPopupTiles
	jp ShowItemPopup


;@ The 4 sprite tiles of the picture shown above the bike when it takes item 7 (ShowItemPopup).
PowerUpLevelPopupTiles::
	db $d8, $d9, $da, $db

;@ def ShowItemPopup(who: b, tiles: de)
;@ path: items
;@ For the first player's bike only: a sound, and the item's 4 tiles go into sprites
;@ 28-31, shown 8 pixels above the bike for 16 frames (wItemPopup).
;@ writes: wItemPopup, wItemPopupX, wItemPopupY
;@ reads: wBikeX, wBikeY
;@ sig: bf002040
ShowItemPopup::
;> if who != 1: return
	dec b
	ret nz

;> PlayBikeSound(0x0F)
;> wItemPopup = 0x10
;> wItemPopupY = u8(hi(wBikeY) - 8)
;> wItemPopupX = wBikeX[1]
	ld a, $0f
	call PlayBikeSound
	ld a, $10
	ld [wItemPopup], a
	ld a, [wBikeY + 1]
	sub $08
	ld [wItemPopupY], a
	ld a, [wBikeX + 1]
	ld [wItemPopupX], a
;> for i in range(4):
;>     wShadowOAM[0x72 + 4 * i] = mem[u16(tiles + i)]
	ld hl, $cc72
	ld b, $04

jr_000_2afd:
	ld a, [de]
	ld [hli], a
	inc de
	inc a
	inc l
	inc l
	inc l
	dec b
	jr nz, jr_000_2afd

	ret


;@ def MarkItemTaken(item: hl, bike: b)
;@ path: items
;@ A bike takes an item: its bit in the item's mask is flipped off. For kinds 0-5,
;@ when player one's bike takes it, the item also leaves the screen and the map:
;@ its 2 x 2 tiles are queued for blanking in the next VBlank (wEraseItem) and its
;@ level map cell becomes $FF.
;@ writes: wEraseItem, wEraseItemAddr
;@ reads: wBikeId
;@ test: item = rand_ram(8); bike = rng.choice([1, 2])
;@ sig: 62f14430
MarkItemTaken::
;> mem[item & 0xFF00 | lo(item + 1)] ^= bike  # the bike's "may still take it" bit
	inc l
	ld a, [hl]
	xor b
	ld [hl], a
;> if mem[item] >= 6: return                  # the kind
	dec l
	ld a, [hli]
	cp $06
	ret nc

;> if wBikeId != 1: return
	ld a, [wBikeId]
	dec a
	ret nz

;> base = u16(item + 1) & 0xFF00
;> row, col = mem[base | lo(item + 5)], mem[base | lo(item + 6)]
	call SwapDEHL
	inc e
	inc e
	inc e
	inc e
	ld a, [de]
	ld c, a
;> wEraseItemAddr = 0x9800 + 64 * row + 2 * (col & 0x0F)   # its 2 x 2 tiles in BG map 0
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	inc e
	ld a, [de]
	ld b, a
	and $0f
	add a
	rst $28
	ld de, $9800
	add hl, de
	ld a, l
	ld [wEraseItemAddr], a
	ld a, h
	ld [wEraseItemAddr + 1], a
;> wEraseItem = 1
	ld a, $01
	ld [wEraseItem], a
;> mem[u16(addr(wLevelMap) + (row << 8 | col))] = 0xFF   # gone from the level map
	ld h, c
	ld l, b
	ld de, wLevelMap
	add hl, de
	ld [hl], $ff
;> return
	ret


;@ def RestoreItems()
;@ path: items
;@ A new lap: every item may be taken again by this bike (its bit in each item's
;@ mask is set). Player one's bike also puts the items back into the level map:
;@ kinds 0-5 as themselves, the others as $FF.
;@ (The pointer steps through the list with 8-bit increments after the mask, so
;@ a list longer than 32 items would wrap round within one 256-byte page.)
;@ reads: wBikeId, wItemCount
;@ test: wItemCount = rand(1, 40); wBikeId = rng.choice([1, 2])
;@ test: for i in range(40): mem[0xCA05 + 8 * i] = rand(0, 15)
;@ sig: e3f3ae70
RestoreItems::
;> p = addr(wItems)
;> for _ in range(wItemCount or 256):
	ld hl, wItems
	ld a, [wItemCount]
	ld b, a
	ld a, [wBikeId]
	ld c, a

jr_000_2b54:
;>     kind = mem[p] if mem[p] < 6 else 0xFF
	push bc
	ld a, [hli]
	cp $06
	ld b, a
	jr c, jr_000_2b5d

	ld b, $ff

jr_000_2b5d:
;>     q = u16(p + 1)
;>     mem[q] |= wBikeId
	ld a, [hl]
	or c
	ld [hli], a
;>     page, q = u16(q + 1) & 0xFF00, u16(q + 1)
;>     cell = u16(addr(wLevelMap) + (mem[page | lo(q + 3)] << 8 | mem[page | lo(q + 4)]))
	inc l
	inc l
	inc l
	ld d, [hl]
	inc l
	ld e, [hl]
	ld a, $ce
	add d
	ld d, a
;>     if wBikeId == 1: mem[cell] = kind
	ld a, b
	dec c
	jr nz, jr_000_2b6f

	ld [de], a

jr_000_2b6f:
;>     p = page | lo(q + 6)
	inc l
	inc l
	pop bc
	dec b
	jr nz, jr_000_2b54

;> return
	ret


;@ def EraseItemTile()
;@ path: items
;@ VBlank job: blanks the 2 x 2 tiles of the collected item at wEraseItemAddr
;@ (tile $42) and clears the request.
;@ test: wEraseItemAddr = 0x9800 + rand(0, 0x3DE)
;@ sig: ce58dbb8
EraseItemTile::
;> wEraseItem &= ~0x01
	ld hl, wEraseItem
	res 0, [hl]
;> vram = wEraseItemAddr
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
;> mem[vram] = mem[u16(vram + 1)] = 0x42
	ld a, $42
	ld [hli], a
	ld [hl], a
;> mem[u16(vram + 32)] = mem[u16(vram + 33)] = 0x42
	ld de, $001f
	add hl, de
	ld [hli], a
	ld [hl], a
;> return
	ret


;@ def CheckCoursePoints()
;@ path: race/laps
;@ What happens at three points along the course. A race is two laps of the
;@ 4096-pixel level map, so the bike's X runs from 0 to $1FFF:
;@ - at X $0FB0 (the end of the first lap) wLapsLeft goes down, the items come
;@ back (RestoreItems), and for player one two cells of the level map (row 13,
;@ columns $F9-$FA) become 0 and 1 and the lap time is put up for 64 frames;
;@ - at X $1F80 the throttle is forced on for the run to the line (wBikeCrash 1);
;@ - at X $1FB0, the finish, the bike stops (wBikeCrash 2, or 3 in the air, which
;@ spins it), sound $18 plays, and for player one the start area of the map (the
;@ first 48 columns) is replaced by flat ground: empty rows 8-14 over a row of
;@ tile 9.
;@ writes: wBikeCrash, wBikeLives, wLapTime, wLapTimeShow, wLapTimeTimer, wLapsLeft
;@ reads: wBikeCrash, wBikeId, wBikeMode, wBikeX, wLapsLeft, wPlayerMask, wRaceTime
;@ test: x = rng.choice([0x0FB0, 0x1F80, 0x1FB0, rand(0, 0xFFFF)]) + rand(0, 15); mem[0xC788] = x & 0xFF; mem[0xC789] = (x >> 8) & 0xFF
;@ test: wLapsLeft = rand(0, 2); wBikeCrash = rand(0, 3); wBikeId = rng.choice([1, 2]); wBikeMode = rand(0, 2); wPlayerMask = rng.choice([1, 3, 7])
;@ sig: 26b13b35
CheckCoursePoints::
;> x = wBikeX[2] << 8 | (wBikeX[1] & 0xF0)
	ld a, [wBikeX + 1]
	and $f0
	ld l, a
	ld a, [wBikeX + 2]
	ld h, a
;> if x == 0x0FB0:                            # the end of the first lap
;>@lap1     if not wLapsLeft: return
;>@lap2     wLapsLeft -= 1; RestoreItems()
;>@lap3     if wBikeId != 1: return
;>@lap4     wLevelMap[0xDF9] = 0; wLevelMap[0xDFA] = 1
;>@lap5     wLapTimeShow = 1; wLapTimeTimer = 0x40
;>@lap6     copy(addr(wLapTime), addr(wRaceTime), 3)
	ld de, $0fb0
	rst $20
	jr z, jr_000_2ba7

;> elif x == 0x1F80:                          # the run to the line
;>@auto     if not wBikeCrash: wBikeCrash = 1
	ld de, $1f80
	rst $20
	jr z, jr_000_2bdc

;> elif x == 0x1FB0:                          # the finish
;>@fin1     if wBikeCrash >= 2: return
;>@fin2     wBikeCrash = 2 if wBikeMode == 1 else 3
;>@fin3     wBikeLives = 0x40
;>@fin4     if wBikeId == 1:
;>@fin5         PlaySound(0); PlaySound(0x18)
;>@fin6         for r in range(8, 15): fill(addr(wLevelMap) + 256 * r, 0xFF, 0x30)
;>@fin7         fill(addr(wLevelMap) + 0xF00, 0x09, 0x30)
;>@fin8     elif wPlayerMask & 0x04: PlaySound(0); PlaySound(0x18)
	ld de, $1fb0
	rst $20
	jr z, jr_000_2be6

;> return
	ret


;=@lap1
jr_000_2ba7:
	ld a, [wLapsLeft]
	and a
	ret z

;=@lap2
	dec a
	ld [wLapsLeft], a
	call RestoreItems
;=@lap3
	ld a, [wBikeId]
	dec a
	ret nz

;=@lap4
	ld hl, $dbf9
	xor a
	ld [hli], a
	inc a
	ld [hl], a
;=@lap5
	ld a, $01
	ld [wLapTimeShow], a
	ld a, $40
	ld [wLapTimeTimer], a
;=@lap6
	ld a, [wRaceTime]
	ld [wLapTime], a
	ld a, [wRaceTime + 1]
	ld [wLapTime + 1], a
	ld a, [wRaceTime + 2]
	ld [wLapTime + 2], a
	ret


;=@auto
jr_000_2bdc:
	ld a, [wBikeCrash]
	and a
	ret nz

	inc a
	ld [wBikeCrash], a
	ret


;=@fin1
jr_000_2be6:
	ld a, [wBikeCrash]
	cp $02
	ret nc

;=@fin2
	ld a, [wBikeMode]
	cp $01
	ld a, $02
	jr z, jr_000_2bf6

	inc a

jr_000_2bf6:
	ld [wBikeCrash], a
;=@fin3
	ld a, $40
	ld [wBikeLives], a
;=@fin4
	ld a, [wBikeId]
	dec a
	jr nz, jr_000_2c2b

;=@fin5
	ld a, $00
	call PlaySound
	ld a, $18
	call PlaySound
;=@fin6
	ld hl, $d600
	ld de, $00d0
	ld a, $ff
	ld c, $07

jr_000_2c18:
	ld b, $30

jr_000_2c1a:
	ld [hli], a
	dec b
	jr nz, jr_000_2c1a

	add hl, de
	dec c
	jr nz, jr_000_2c18

;=@fin7
	ld a, $09
	ld b, $30

jr_000_2c26:
	ld [hli], a
	dec b
	jr nz, jr_000_2c26

	ret


;=@fin8
jr_000_2c2b:
	ld a, [wPlayerMask]
	and $04
	ret z

	ld a, $00
	call PlaySound
	ld a, $18
	jp PlaySound


;@ def InitStartLights()
;@ path: race/start
;@ Puts the three start lights into OAM slots 25-27 (StartLightSprites).
;@ sig: 966500f5
InitStartLights::
;> copy(addr(wShadowOAM) + 0x64, StartLightSprites, 12)
;> return
	ld de, $cc64
	ld hl, StartLightSprites
	ld bc, $000c
	jp CopyBytes


;@ The three sprites of the start lights (y, x, tile, attributes): copied to OAM slots 25-27 by InitStartLights.
StartLightSprites::
	db $40, $60, $9a, $00, $40, $68, $9a, $00, $40, $70, $9a, $00

;@ def StartCountdown()
;@ path: race/start
;@ One frame of the start sequence while wStartCountdown runs: the three lights
;@ come on at $22, $1A and $12 (a beep each), GO at $0A. The starter's flag sprite
;@ (slot 37) shows tile $FD, then $FE in the last frame but one. When it reaches 0
;@ the race begins: both bikes' modes are cleared, their Y rows made even and the
;@ lights taken off the screen.
;@ writes: wBikeMode, wBikeY, wOtherBike, wShadowOAM, wStartCountdown
;@ reads: wBikeY, wOtherBike, wStartCountdown
;@ test: wStartCountdown = rng.choice([0, 0xFF, 1, 2, 3, 0x23, 0x1B, 0x13, 0x0B, rand(0, 255)])
;@ sig: c96ae1be
StartCountdown::
;> n = wStartCountdown
;> if n == 0: return
	ld a, [wStartCountdown]
	and a
	ret z

;> if n == 0xFF: return
	cp $ff
	ret z

;> n -= 1
;> wStartCountdown = n
	dec a
	ld [wStartCountdown], a
	ld c, a
;> if n == 0x22: StartLight1()
	cp $22
	call z, StartLight1
;> if n == 0x1A: StartLight2()
	ld a, c
	cp $1a
	call z, StartLight2
;> if n == 0x12: StartLight3()
	ld a, c
	cp $12
	call z, StartLight3
;> if n == 0x0A: StartLightGo()
	ld a, c
	cp $0a
	call z, StartLightGo
;> tile = 0xFD
;> if n < 2:
	cp $02
	ld c, $fd
	jr nc, jr_000_2ca9

;>     tile = 0xFE
;>     if n < 1:
	inc c
	cp $01
	jr nc, jr_000_2ca9

;>         wShadowOAM[0x96] = 0xFF
	inc c
	ld a, c
	ld [wShadowOAM + 150], a
;>         wBikeMode = mem[addr(wBikeMode) + 0x80] = 0                # both bikes
	xor a
	ld [wBikeMode], a
	ld [wOtherBike + 11], a
;>         mem[addr(wBikeY) + 1] &= 0xFE                             # both bikes' pixel rows even
;>         mem[addr(wBikeY) + 0x81] &= 0xFE
	ld a, [wBikeY + 1]
	and $fe
	ld [wBikeY + 1], a
	ld a, [wOtherBike + 6]
	and $fe
	ld [wOtherBike + 6], a
;>         wShadowOAM[0x64] = wShadowOAM[0x68] = wShadowOAM[0x6C] = 0   # the lights off the screen
	xor a
	ld [wShadowOAM + 100], a
	ld [wShadowOAM + 104], a
	ld [wShadowOAM + 108], a
;>         return
	ret


jr_000_2ca9:
;> wShadowOAM[0x96] = tile                                     # the starter's flag
	ld a, c
	ld [wShadowOAM + 150], a
;> return
	ret


;@ def StartLightGo()
;@ path: race/start
;@ GO: all three start lights change (tiles $DD, $DE, $E1) and sound $11 plays.
;@ writes: wShadowOAM
;@ sig: eed2d6e9
StartLightGo::
;> wShadowOAM[0x66] = 0xDD
;> wShadowOAM[0x6A] = 0xDE
;> wShadowOAM[0x6E] = 0xE1
	ld a, $dd
	ld [wShadowOAM + 102], a
	ld a, $de
	ld [wShadowOAM + 106], a
	ld a, $e1
	ld [wShadowOAM + 110], a
;> PlaySound(0x11)
;> return
	ld a, $11
	jp PlaySound


;@ def StartLight3()
;@ path: race/start
;@ The third start light: the middle sprite becomes tile $F1, sound $10.
;@ writes: wShadowOAM
;@ sig: 1b7ea365
StartLight3::
;> wShadowOAM[0x6A] = 0xF1
	ld a, $f1
	ld [wShadowOAM + 106], a
;> PlaySound(0x10)
;> return
	ld a, $10
	jp PlaySound


;@ def StartLight2()
;@ path: race/start
;@ The second start light: the middle sprite becomes tile $F2, sound $10.
;@ writes: wShadowOAM
;@ sig: 22f39fa0
StartLight2::
;> wShadowOAM[0x6A] = 0xF2
	ld a, $f2
	ld [wShadowOAM + 106], a
;> PlaySound(0x10)
;> return
	ld a, $10
	jp PlaySound


;@ def StartLight1()
;@ path: race/start
;@ The first start light: the middle sprite becomes tile $F3, sound $10.
;@ writes: wShadowOAM
;@ sig: 35888be3
StartLight1::
;> wShadowOAM[0x6A] = 0xF3
	ld a, $f3
	ld [wShadowOAM + 106], a
;> PlaySound(0x10)
;> return
	ld a, $10
	jp PlaySound


;@ def DrawStarter()
;@ path: race/start
;@ Places the starter's flag (sprite 37) at wStarterY, wStarterX relative to the
;@ camera. Once it has scrolled off to the left it is hidden for good
;@ (wStartCountdown = $FF).
;@ writes: wStartCountdown
;@ reads: wCamX, wCamY, wStartCountdown, wStarterX, wStarterY
;@ test: wStartCountdown = rng.choice([0xFF, rand(0, 0xFE)])
;@ sig: 17727f25
DrawStarter::
;> off = wStartCountdown == 0xFF
	ld a, [wStartCountdown]
	inc a
	jr z, jr_000_2d00

;> if not off:
;>     y = u8(wStarterY - hi(wCamY))
	ld a, [wCamY + 1]
	ld c, a
	ld a, [wStarterY]
	sub c
	ld c, a
;>     x = u8(wStarterX - wCamX[1])
	ld a, [wCamX + 1]
	ld b, a
	ld a, [wStarterX]
	sub b
	ld b, a
;>     off = bool(x & 0x80)                      # off the left edge
	rla
	jr nc, jr_000_2d03

;>     if off: wStartCountdown = 0xFF
	ld a, $ff
	ld [wStartCountdown], a

jr_000_2d00:
;> if off: y, x = 0xF0, 0x00
	ld bc, $00f0

jr_000_2d03:
;> wShadowOAM[0x94] = u8(y + 0x10)
	ld hl, $cc94
	ld a, c
	add $10
	ld [hl], a
;> wShadowOAM[0x95] = u8(x + 8)
	inc hl
	ld a, b
	add $08
	ld [hl], a
;> return
	ret


;@ def AddTime(time: hl)
;@ path: race/clock
;@ Adds 2 hundredths to a BCD time (hundredths, seconds, minutes), carrying into
;@ the seconds and the minutes at 60. The race clock (wRaceTime) gets this every
;@ frame, so it runs 2 hundredths a frame.
;@ test: time = rand_ram(3); mem[time] = rng.choice([0x98, 0x99, 0x00, 0x50, 0x97])
;@ test: mem[time + 1] = rng.choice([0x59, 0x00, 0x30]); mem[time + 2] = rng.choice([0x59, 0x00, 0x09])
;@ sig: 9e9e0e6a
AddTime::
;> v = bcd_to_int(mem[time]) + 2
;> mem[time] = to_bcd(v % 100)
;> if v < 100: return
	ld a, [hl]
	add $02
	daa
	ld [hl], a
	ret nc

;> for _ in range(2):                         # the seconds, then the minutes
	inc hl
	ld b, $02

jr_000_2d19:
;>     time = u16(time + 1)
;>     v = bcd_to_int(mem[time]) + 1
;>     if v < 60:
;>         mem[time] = to_bcd(v)
;>         return
	ld a, [hl]
	add $01
	daa
	ld [hl], a
	cp $60
	ret c

;>     mem[time] = 0
	ld [hl], $00
	inc hl
	dec b
	jr nz, jr_000_2d19

;> return
	ret


;@ def CountDownTime(time: hl)
;@ path: race/clock
;@ Takes 2 hundredths off a BCD time (hundredths, seconds, minutes), stopping at
;@ 0:00.00. The time left (wTimeLeft) gets this every frame of the race. When the
;@ hundredths go below zero they become 99, not 98.
;@ test: time = rand_ram(3); mem[time] = rng.choice([0x00, 0x01, 0x02, 0x50])
;@ test: mem[time + 1] = rng.choice([0x00, 0x01, 0x30]); mem[time + 2] = rng.choice([0x00, 0x01, 0x02])
;@ sig: e049e3c6
CountDownTime::
;> v = bcd_to_int(mem[time]) - 2
;> if v >= 0:
;>     mem[time] = to_bcd(v)
;>     return
	ld a, [hl]
	sub $02
	daa
	ld [hl], a
	ret nc

;> mem[time] = 0x99
	ld [hl], $99
;> v = bcd_to_int(mem[u16(time + 1)]) - 1
;> if v >= 0:
;>     mem[u16(time + 1)] = to_bcd(v)
;>     return
	inc hl
	ld a, [hl]
	sub $01
	daa
	ld [hl], a
	ret nc

;> mem[u16(time + 1)] = 0x59
	ld [hl], $59
;> v = bcd_to_int(mem[u16(time + 2)]) - 1
;> if v >= 0:
;>     mem[u16(time + 2)] = to_bcd(v)
;>     return
	inc hl
	ld a, [hl]
	sub $01
	daa
	ld [hl], a
	ret nc

;> mem[time] = mem[u16(time + 1)] = mem[u16(time + 2)] = 0   # time is up
	xor a
	ld [hld], a
	ld [hld], a
	ld [hl], a
;> return
	ret


;@ def DrawTimeGauge(time: de)
;@ path: race/hud
;@ Draws the time left as a gauge of 8 tiles in the status bar (wStatusBar + $0D),
;@ one pixel column per second: full tiles ($A8), one partial tile ($A0 + the
;@ seconds left over) and empty ones ($A0). It shows at most 55 seconds. (The time
;@ passed in de is not used; it reads wTimeLeft.)
;@ reads: wTimeMinutes, wTimeSeconds
;@ test: wTimeMinutes = rng.choice([0, 0, 1]); wTimeSeconds = rand(0, 0x60)
;@ sig: 00c27f10
DrawTimeGauge::
;> s = wTimeSeconds
;> if wTimeMinutes or s >= 0x56:
;>@max     s = 0x55
	ld a, [wTimeMinutes]
	and a
	jr nz, jr_000_2d8f

	ld a, [wTimeSeconds]
	cp $56
	jr nc, jr_000_2d8f

jr_000_2d52:
;> v = u8(10 * (s >> 4) + (s & 0x0F))
	ld b, a
	and $0f
	ld c, a
	ld a, b
	rra
	rra
	rra
	rra
	and $0f
	ld b, a
	xor a

jr_000_2d5f:
	add $0a
	dec b
	jr nz, jr_000_2d5f

	add c
;> full, part = (v >> 3) & 7, v & 7
	ld b, a
	and $07
	ld c, a
	ld a, b
	rra
	rra
	rra
	and $07
	ld d, a
;> p = addr(wStatusBar) + 0x0D
;> for _ in range(full):
;>     mem[p] = 0xA8
;>     p += 1
	ld hl, $cbcd
	and a
	jr z, jr_000_2d7d

	ld b, a
	ld a, $a8

jr_000_2d79:
	ld [hli], a
	dec b
	jr nz, jr_000_2d79

jr_000_2d7d:
;> mem[p] = 0xA0 + part
;> p += 1
	ld a, c
	add $a0
	ld [hli], a
;> for _ in range(7 - full):
;>     mem[p] = 0xA0
;>     p += 1
	inc d
	ld a, $08
	sub d
	and a
	ret z

	ld b, a
	ld a, $a0

jr_000_2d8a:
	ld [hli], a
	dec b
	jr nz, jr_000_2d8a

;> return
	ret


;=@max
jr_000_2d8f:
	ld a, $55
	jr jr_000_2d52

;@ def DrawTimeDigits(time: de)
;@ path: race/hud
;@ Writes a BCD time (hundredths, seconds, minutes) as digits into the status bar
;@ at wStatusBar + $0D: one digit of minutes, a gap, two of seconds, a gap, two of
;@ hundredths. A link game shows the race time this way instead of the gauge.
;@ test: time = rand_ram(3)
;@ sig: 429a7b84
DrawTimeDigits::
;> p, src = addr(wStatusBar) + 0x0D, u16(time + 2)
;> for i in range(3):                         # minutes, seconds, hundredths
	ld hl, $cbcd
	inc de
	inc de
	ld b, $03
	jp Jump_000_2da7


;>     if i:
;>         mem[p] = 0xF0 + (mem[src] >> 4)
;>         p += 1
jr_000_2d9d:
	ld a, [de]
	rra
	rra
	rra
	rra
	and $0f
	add $f0
	ld [hli], a

;>     mem[p] = 0xF0 + (mem[src] & 0x0F)
Jump_000_2da7:
	ld a, [de]
	and $0f
	add $f0
	ld [hli], a
;>     src, p = u16(src - 1), p + 2
	dec de
	inc hl
	dec b
	jr nz, jr_000_2d9d

;> return
	ret


;@ def LoadTimeLimit()
;@ path: race/clock
;@ Sets the time left (wTimeLeft) for the course from the level's table:
;@ TimeLimitsA, TimeLimitsB or TimeLimitsC by wRound. A link game always gets
;@ the ninth entry of TimeLimitsA, 3:00.
;@ reads: wCourse, wRound, wTitleCursor
;@ test: wTitleCursor = rand(0, 2); wRound = rand(0, 3); wCourse = rand(1, 8)
;@ sig: 2456ee2b
LoadTimeLimit::
;> if wTitleCursor == 2: table, n = TimeLimitsA, 9
	ld a, [wTitleCursor]
	cp $02
	ld a, $09
	ld hl, TimeLimitsA
	jr z, jr_000_2dd4

;> elif wRound == 1: table, n = TimeLimitsB, wCourse
	ld a, [wRound]
	dec a
	ld hl, TimeLimitsB
	jr z, jr_000_2dd1

;> elif wRound == 2: table, n = TimeLimitsC, wCourse
	dec a
	ld hl, TimeLimitsC
	jr z, jr_000_2dd1

;> else: table, n = TimeLimitsA, wCourse
	ld hl, TimeLimitsA

jr_000_2dd1:
	ld a, [wCourse]

jr_000_2dd4:
;> copy(addr(wTimeLeft), u16(table + u8(3 * u8(n - 1))), 3)
;> return
	dec a
	ld c, a
	add a
	add c
	rst $28
	ld de, wTimeLeft
	ld bc, $0003
	jp CopyBytes


;@ The time limit per course at level A (wRound 0), 3 BCD bytes each (hundredths, seconds, minutes): 1:20, 1:25, 1:19, 1:12, 1:44, 1:28, 1:29, 1:18; the ninth entry, 3:00, is for a link game.
TimeLimitsA::
	db $00, $20, $01, $00, $25, $01, $00, $19, $01, $00, $12, $01, $00, $44, $01, $00
	db $28, $01, $00, $29, $01, $00, $18, $01, $00, $00, $03


;@ The time limit per course at level B (wRound 1): 0:35 to 1:05.
TimeLimitsB::
	db $00, $45, $00, $00, $50, $00, $00, $59, $00, $00, $35, $00, $00, $05, $01, $00
	db $50, $00, $00, $45, $00, $00, $05, $01


;@ The time limit per course at level C (wRound 2): 0:14 to 0:45.
TimeLimitsC::
	db $00, $16, $00, $00, $26, $00, $00, $32, $00, $00, $14, $00, $00, $45, $00, $00
	db $30, $00, $00, $25, $00, $00, $35, $00

;@ def InitBestTimes()
;@ path: race/clock
;@ Sets the best times of the 8 courses to their power-on values (DefaultBestTimes).
;@ sig: 8e932d22
InitBestTimes::
;> copy(addr(wBestTimes), DefaultBestTimes, 24)
;> return
	ld hl, DefaultBestTimes
	ld de, wBestTimes
	ld bc, $0018
	jp CopyBytes


;@ The best time of each of the 8 courses at power-on, 3 BCD bytes each (hundredths, seconds, minutes): 2:02, 1:56, 1:52, 1:58, 2:04, 1:57, 1:54, 2:03.
DefaultBestTimes::
	db $00, $02, $02, $00, $56, $01, $00, $52, $01, $00, $58, $01, $00, $04, $02, $00
	db $57, $01, $00, $54, $01, $00, $03, $02

;@ def ShowLapTime()
;@ path: race/hud
;@ While wLapTimeShow is set: counts wLapTimeTimer down. In its first frame
;@ ($3F) the lap time is put up in sprites: sprites 15-17 (already set up) at
;@ y $28, and the time M'SS'cc in digit sprites 18-24 at y $30. When the timer
;@ runs out all ten sprites go.
;@ writes: wLapTimeShow, wLapTimeTimer
;@ reads: wLapTime, wLapTimeShow, wLapTimeTimer
;@ test: wLapTimeShow = rand(0, 1); wLapTimeTimer = rng.choice([1, 0x40, rand(0, 255)])
;@ sig: 7a715212
ShowLapTime::
;> if not wLapTimeShow: return
	ld a, [wLapTimeShow]
	and a
	ret z

;> wLapTimeTimer = n = u8(wLapTimeTimer - 1)
;> if n == 0:
;>@off     wLapTimeShow = 0
;>@off2     for i in range(10): wShadowOAM[0x3C + 4 * i] = 0
;>@off3     return
	ld a, [wLapTimeTimer]
	dec a
	ld [wLapTimeTimer], a
	jr z, jr_000_2ed1

;> if n != 0x3F: return
	cp $3f
	ret nz

;> for i in range(3): wShadowOAM[0x3C + 4 * i] = 0x28
	ld hl, $cc3c
	ld b, $03
	ld a, $28

jr_000_2e69:
	ld [hli], a
	inc l
	inc l
	inc l
	dec b
	jr nz, jr_000_2e69

;> m, s, c = wLapTime[2], wLapTime[1], wLapTime[0]
;> tiles = (0xF0 | m & 0x0F, 0xEE, 0xF0 | s >> 4, 0xF0 | s & 0x0F, 0xEE, 0xF0 | c >> 4, 0xF0 | c & 0x0F)
;> for i, t in enumerate(tiles):              # sprites 18-24
;>     wShadowOAM[0x48 + 4 * i] = 0x30
;>     wShadowOAM[0x49 + 4 * i] = 0x60 + 8 * i
;>     wShadowOAM[0x4A + 4 * i] = t
	ld b, $30
	ld a, b
	ld [hli], a
	ld a, $60
	ld [hli], a
	ld a, [wLapTime + 2]
	and $0f
	or $f0
	ld [hli], a
	inc l
	ld a, b
	ld [hli], a
	ld a, $68
	ld [hli], a
	ld a, $ee
	ld [hli], a
	inc l
	ld a, b
	ld [hli], a
	ld a, $70
	ld [hli], a
	ld a, [wLapTime + 1]
	ld c, a
	and $f0
	rra
	rra
	rra
	rra
	or $f0
	ld [hli], a
	inc l
	ld a, b
	ld [hli], a
	ld a, $78
	ld [hli], a
	ld a, c
	and $0f
	or $f0
	ld [hli], a
	inc l
	ld a, b
	ld [hli], a
	ld a, $80
	ld [hli], a
	ld a, $ee
	ld [hli], a
	inc l
	ld a, b
	ld [hli], a
	ld a, $88
	ld [hli], a
	ld a, [wLapTime]
	ld c, a
	and $f0
	rra
	rra
	rra
	rra
	or $f0
	ld [hli], a
	inc l
	ld a, b
	ld [hli], a
	ld a, $90
	ld [hli], a
	ld a, c
	and $0f
	or $f0
	ld [hli], a
	inc l
;> return
	ret


jr_000_2ed1:
;=@off
	xor a
	ld [wLapTimeShow], a
;=@off2
	ld hl, $cc3c
	ld b, $0a

jr_000_2eda:
	ld [hli], a
	inc l
	inc l
	inc l
	dec b
	jr nz, jr_000_2eda

;=@off3
	ret


;@ def OpenTimeUpBox()
;@ path: game/gameover
;@ Starts the TIME UP box at the middle of the screen: its BG map address
;@ (TimeUpBoxAddr) into wBoxAddr, and wBoxRow = 0 for the VBlank handler.
;@ writes: wBoxAddr, wBoxRow
;@ sig: 6d6415d4
OpenTimeUpBox::
;> wBoxAddr = TimeUpBoxAddr()
	call TimeUpBoxAddr
	ld a, l
	ld [wBoxAddr], a
	ld a, h
	ld [wBoxAddr + 1], a
;> wBoxRow = 0
;> return
	xor a
	ld [wBoxRow], a
	ret


;@ def DrawTimeUpBoxRow()
;@ path: game/gameover
;@ VBlank job: one row of the TIME UP box per frame. Steps 1-3 of wBoxRow fill a
;@ row of 9 box tiles ($98) starting at wBoxAddr (wrapping round within the BG
;@ map row); every call moves wBoxRow on.
;@ writes: wBoxRow
;@ reads: wBoxAddr, wBoxRow
;@ test: wBoxAddr = 0x9800 + rand(0, 0x3BF); wBoxRow = rand(0, 5)
;@ sig: 434ce641
DrawTimeUpBoxRow::
;> p, k = wBoxAddr, wBoxRow
;> if k in (1, 2, 3):
;>     p = u16(p + 32 * (k - 1))
	ld a, [wBoxAddr]
	ld l, a
	ld a, [wBoxAddr + 1]
	ld h, a
	ld a, [wBoxRow]
	dec a
	jr z, jr_000_2f0b

	ld de, $0020
	add hl, de
	dec a
	jr z, jr_000_2f0b

	add hl, de
	dec a
	jr nz, jr_000_2f21

jr_000_2f0b:
;>     for _ in range(9):
;>         mem[p] = 0x98
	ld b, $09
	ld c, $98

jr_000_2f0f:
	ld [hl], c
;>         p = p & 0xFFE0 if (p & 0x1F) == 0x1F else u16(p + 1)
	ld a, l
	and $1f
	cp $1f
	jr nz, jr_000_2f1d

	ld a, l
	and $e0
	ld l, a
	jr jr_000_2f1e

jr_000_2f1d:
	inc hl

jr_000_2f1e:
	dec b
	jr nz, jr_000_2f0f

jr_000_2f21:
;> wBoxRow = u8(k + 1)
;> return
	ld a, [wBoxRow]
	inc a
	ld [wBoxRow], a
	ret


;@ def BlinkTimeUp()
;@ path: game/gameover
;@ The TIME UP message in the box's middle row (one tile in): TimeUpText while
;@ bit 3 of wStateTimer is set, else the blank tiles, so it blinks every 8 frames.
;@ reads: wBoxAddr, wStateTimer
;@ test: wBoxAddr = 0x9800 + rand(0, 0x39F); wStateTimer = rand(0, 255)
;@ sig: 694cf2af
BlinkTimeUp::
;> p = u16(wBoxAddr + 32)
	ld a, [wBoxAddr]
	ld l, a
	ld a, [wBoxAddr + 1]
	ld h, a
	ld de, $0020
	add hl, de
;> p = p & 0xFFE0 if (p & 0x1F) == 0x1F else u16(p + 1)
	ld a, l
	and $1f
	cp $1f
	jr nz, jr_000_2f42

	ld a, l
	and $e0
	ld l, a
	jr jr_000_2f43

jr_000_2f42:
	inc hl

jr_000_2f43:
;> s = TimeUpText if wStateTimer & 0x08 else TimeUpBlank
;> while mem[s] != 0xFF:                      # (the tile loop of DrawStringsMode)
;>     WaitVRAM()
;>     mem[p] = mem[s]
;>     s += 1
;>     p = p & 0xFFE0 if (p & 0x1F) == 0x1F else u16(p + 1)
;> return
	ld a, [wStateTimer]
	bit 3, a
	ld de, TimeUpText
	ld c, $ff
	jp nz, Jump_000_0c3d

	ld de, TimeUpBlank
	jp Jump_000_0c3d


;@ def TimeUpBoxAddr() -> hl
;@ path: game/gameover
;@ The BG map address of the TIME UP box: 5 tile rows below the screen's top and
;@ 8 columns right of its left edge, from the camera position.
;@ reads: wCamX, wCamY
;@ sig: 9b08c099
TimeUpBoxAddr::
;> row = hi(wCamY) & 0xF8
	ld a, [wCamY + 1]
	and $f8
	ld l, a
;> p = u16(row * 4 + 0xA0 + 0x9800)
	ld h, $00
	add hl, hl
	add hl, hl
	ld de, $00a0
	add hl, de
	ld de, $9800
	add hl, de
;> col = u8(((wCamX[1] & 0xF8) >> 3) + 8) & 0x1F
	ld a, [wCamX + 1]
	and $f8
	rra
	rra
	rra
	add $08
	and $1f
;> return p | col
	or l
	ld l, a
	ret


;@ asset: rows tiles=LoadFont+LoadTileList(hl=RaceGfxList)|LoadFont end=$FF blank=$7F
;@ The 7 tiles of the message in the box that pops up when the time runs out, up to $FF (printed at hl, blinking every 8 frames).
TimeUpText::
	db $92, $93, $94, $95, $98, $96, $97, $ff


;@ Seven box tiles ($98): the message blinked off.
TimeUpBlank::
	db $98, $98, $98, $98, $98, $98, $98, $ff


;@ Unused: a text list that would put tile $A0 at $9C0D.
UnusedText_2F87::
	db $0d, $9c, $a0, $ff

;@ def BlinkRecord()
;@ path: game/results
;@ A new best time blinks on the results screen, on and off every 8 steps of
;@ wStateTimer: IT'S A RECORD! and the record time (in a link game the winner's
;@ time; nothing blinks after a draw).
;@ reads: wLinkResult, wPlayerMask, wStateTimer
;@ test: wStateTimer = rand(0, 255); wPlayerMask = rng.choice([1, 3, 7]); wLinkResult = rand(0, 2)
;@ sig: f574a070
BlinkRecord::
;> on = wStateTimer & 0x08
;> DrawStringsMode(RecordText, 0xFF if on else 0x00)   # mode 0 erases it
	ld a, [wStateTimer]
	bit 3, a
	ld c, $00
	jr z, jr_000_2f95

	dec c

jr_000_2f95:
	ld de, RecordText
	call DrawStringsMode
;> if wPlayerMask & 0x04:
	ld a, [wPlayerMask]
	and $04
	jr z, jr_000_2fc1

;>     if wLinkResult == 1: return            # a draw
	ld a, [wLinkResult]
	dec a
	ret z

;>     if wLinkResult == 2: time, at = 0xC784, 0x992A   # won: this Game Boy's time
	dec a
	ld de, $c784
	ld hl, $992a
	jr z, jr_000_2fb6

;>     else: time, at = 0xC804, 0x996A        # the other bike's time
	ld de, $c804
	ld hl, $996a

jr_000_2fb6:
;>     if not on: return BlankTime(at)
	ld a, [wStateTimer]
	bit 3, a
	jp z, BlankTime

;>     return PrintBikeTime(wStateTimer, time, at)
	jp PrintBikeTime


jr_000_2fc1:
;> if not on: return BlankTime(0x992A)
	ld de, $c784
	ld hl, $992a
	ld a, [wStateTimer]
	bit 3, a
	jp z, BlankTime

;> return PrintBikeTime(wStateTimer, 0xC784, 0x992A)
	jp PrintBikeTime


;@ def DrawResults()
;@ path: game/results
;@ The results screen: the texts (YOU QUALIFIED!, or the link version with 1P or
;@ 2P), the bikes' race times, a check for new best times (IT'S A RECORD! when
;@ there is one) and, in a link game, LOST, DRAW or WON! from comparing the two
;@ times (wLinkResult).
;@ writes: wLinkResult, wNewRecord
;@ reads: wBikeCrash, wLinkMaster, wNewRecord, wOtherBike, wPlayerMask
;@ test: wPlayerMask = rng.choice([1, 3, 7]); wLinkMaster = rand(0, 1); wCourse = rand(1, 8)
;@ sig: 1f97fb1a
DrawResults::
;> if wPlayerMask & 0x04:
	ld a, [wPlayerMask]
	and $04
	jr z, jr_000_2ff0

;>     DrawStrings(ResultsTextLink)
	ld de, ResultsTextLink
	call DrawStrings
;>     DrawStrings(Link2PText if wLinkMaster else Link1PText)
	ld a, [wLinkMaster]
	and a
	ld de, Link2PText
	jr nz, jr_000_2feb

	ld de, Link1PText

jr_000_2feb:
	call DrawStrings
	jr jr_000_3003

;> else:
;>     DrawStrings(ResultsText1P)
jr_000_2ff0:
	ld de, ResultsText1P
	call DrawStrings
;>     if wPlayerMask & 0x02: DrawStrings(ResultsTextCOM)
	ld a, [wPlayerMask]
	and $02
	jr z, jr_000_3003

	ld de, ResultsTextCOM
	call DrawStrings

jr_000_3003:
;> PrintBikeTime(wBikeCrash, 0xC784, 0x992A)  # this bike's time (or LOST)
	ld de, $c784
	ld hl, $992a
	ld a, [wBikeCrash]
	call PrintBikeTime
;> if wPlayerMask & 0x02: PrintBikeTime(wOtherBike[0x29], 0xC804, 0x996A)   # the other bike's
	ld a, [wPlayerMask]
	and $02
	jr z, jr_000_3022

	ld de, $c804
	ld hl, $996a
	ld a, [wOtherBike + 41]
	call PrintBikeTime

jr_000_3022:
;> wNewRecord = 0
	xor a
	ld [wNewRecord], a
;> CheckRecord(wBikeCrash, addr(wRaceTime), 1)
	ld hl, wRaceTime
	ld b, $01
	ld a, [wBikeCrash]
	call CheckRecord
;> if wPlayerMask & 0x04: CheckRecord(wOtherBike[0x29], 0xC802, 2)
	ld a, [wPlayerMask]
	and $04
	jr z, jr_000_3043

	ld hl, $c802
	ld b, $02
	ld a, [wOtherBike + 41]
	call CheckRecord

jr_000_3043:
;> if wNewRecord: DrawStrings(RecordText)
	ld a, [wNewRecord]
	and a
	jr z, jr_000_304f

	ld de, RecordText
	call DrawStrings

jr_000_304f:
;> if not wPlayerMask & 0x04: return
	ld a, [wPlayerMask]
	and $04
	ret z

;> mine = wRaceTime[2] << 16 | wRaceTime[1] << 8 | wRaceTime[0]
;> other = wOtherBike[0x04] << 16 | wOtherBike[0x03] << 8 | wOtherBike[0x02]
	ld hl, $c784
	ld de, $c804
	ld a, [de]
	cp [hl]
	jr z, jr_000_3061

	jr jr_000_306d

jr_000_3061:
	dec de
	dec hl
	ld a, [de]
	cp [hl]
	jr z, jr_000_3069

	jr jr_000_306d

jr_000_3069:
	dec de
	dec hl
	ld a, [de]
	cp [hl]

jr_000_306d:
;> if other < mine: text = LostText; wLinkResult = 0
	ld de, LostText
	ld a, $00
	jr c, jr_000_3080

;> elif other == mine: text = DrawText; wLinkResult = 1
	ld de, DrawText
	ld a, $01
	jr z, jr_000_3080

;> else: text = WonText; wLinkResult = 2
	ld de, WonText
	ld a, $02

jr_000_3080:
;> return DrawStrings(text)
	ld [wLinkResult], a
	jp DrawStrings


;@ def PrintBikeTime(finished: a, time: de, at: hl)
;@ path: game/results
;@ A bike's time on the results screen at BG map address at: the digits of the
;@ BCD time whose minutes byte is at time (PrintTimeDigits), or LOST one tile
;@ further on when finished is 0.
;@ test: finished = rng.choice([0, rand(1, 255)]); time = rand_ram(3) + 2; at = 0x9800 + rand(0, 0x3E0)
;@ sig: 50678d18
PrintBikeTime::
;> if finished: return PrintTimeDigits(3, time, at)
	and a
	jr z, jr_000_30aa

	ld b, $03
	jp PrintTimeDigits


;=@PrintTimeDigits.hi
jr_000_308e:
	ld a, [de]
	rra
	rra
	rra
	rra
	and $0f
	add $f0
	call PutTile
	inc hl

;@ def PrintTimeDigits(count: b, time: de, at: hl)
;@ path: game/results
;@ Writes count BCD bytes as digits (tiles $F0-$F9) to the BG map, from the byte
;@ at time downwards, with a gap after each byte: for a time, M SS cc from the
;@ minutes byte. The first byte shows only its low digit.
;@ test: count = rand(1, 3); time = rand_ram(3) + 2; at = 0x9800 + rand(0, 0x3E0)
;@ sig: 75c1145a
PrintTimeDigits::
;> for i in range(count or 256):
;>     if i:
;>@hi         PutTile(0xF0 + (mem[time] >> 4), at); at = u16(at + 1)
;>     PutTile(0xF0 + (mem[time] & 0x0F), at)
	ld a, [de]
	and $0f
	add $f0
	call PutTile
;>     at, time = u16(at + 2), u16(time - 1)
	inc hl
	dec de
	inc hl
	dec b
	jr nz, jr_000_308e

;> return
	ret


;> at = u16(at + 1)
;> s = LostTimeText
;> while mem[s] != 0xFF:                      # (the tile loop of DrawStringsMode)
;>     WaitVRAM()
;>     mem[at] = mem[s]
;>     s += 1
;>     at = at & 0xFFE0 if (at & 0x1F) == 0x1F else u16(at + 1)
;> return
jr_000_30aa:
	ld de, LostTimeText
	inc hl
	ld c, $ff
	jp Jump_000_0c3d


;@ def BlankTime(at: hl)
;@ path: game/results
;@ Clears a time on the results screen: NoTimeText (the separators without the
;@ digits) at BG map address at.
;@ test: at = 0x9800 + rand(0, 0x3E0)
;@ sig: 57b09693
BlankTime::
;> s = NoTimeText
;> while mem[s] != 0xFF:                      # (the tile loop of DrawStringsMode)
;>     WaitVRAM()
;>     mem[at] = mem[s]
;>     s += 1
;>     at = at & 0xFFE0 if (at & 0x1F) == 0x1F else u16(at + 1)
;> return
	ld de, NoTimeText
	ld c, $ff
	jp Jump_000_0c3d


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list (BG address, tiles, $FE next / $FF end) of the results screen: YOU QUALIFIED! in a box, RESULTS, YOU and the time template.
ResultsText1P::
	db $42, $98, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	db $aa, $aa, $fe, $62, $98, $aa, $87, $8e, $9e, $aa, $99, $9e, $8f, $90, $9b, $8c
	db $9b, $9d, $96, $91, $aa, $fe, $82, $98, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	db $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $fe, $e6, $98, $e2, $ed, $e3, $ee, $e0
	db $ea, $e3, $fe, $23, $99, $d7, $de, $ee, $fe, $2b, $99, $d5, $7f, $7f, $d5, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list: COM and its time template (the computer bike of a two-bike race).
ResultsTextCOM::
	db $63, $99, $e4, $de, $ec, $fe, $6b, $99, $d5, $7f, $7f, $d5, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list of the link results screen: YOU in a box, RESULTS, YOU and both time templates.
ResultsTextLink::
	db $45, $98, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $fe, $65, $98, $aa
	db $87, $8e, $9e, $aa, $aa, $aa, $aa, $aa, $aa, $fe, $85, $98, $aa, $aa, $aa, $aa
	db $aa, $aa, $aa, $aa, $aa, $aa, $fe, $e6, $98, $e2, $ed, $e3, $ee, $e0, $ea, $e3
	db $fe, $23, $99, $d7, $de, $ee, $fe, $2b, $99, $d5, $7f, $7f, $d5, $fe, $6b, $99
	db $d5, $7f, $7f, $d5, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list: IT'S A RECORD! at the bottom of the results screen.
RecordText::
	db $c3, $99, $eb, $ea, $d2, $e3, $7f, $df, $7f, $e2, $ed, $e4, $de, $e2, $e6, $e1
	db $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list: LOST in the box at the top (link game).
LostText::
	db $6a, $98, $90, $8e, $93, $9a, $ff


;@ asset: rows tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList) end=$FF blank=$7F
;@ Tiles up to $FF printed at hl: LOST in place of the time of a bike that did not finish.
LostTimeText::
	db $e0, $de, $e3, $ea, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list: WON! in the box at the top (link game).
WonText::
	db $6a, $98, $89, $8e, $98, $91, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list: DRAW in the box at the top (link game).
DrawText::
	db $66, $98, $aa, $aa, $96, $92, $8f, $89, $aa, $aa, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list: 1P beside the second time (link game, this Game Boy is the follower).
Link1PText::
	db $63, $99, $f1, $7f, $ef, $ff


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list: 2P beside the second time (link game, this Game Boy is the master).
Link2PText::
	db $63, $99, $f2, $7f, $ef, $ff


;@ asset: rows tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList) end=$FF blank=$7F
;@ Tiles up to $FF printed at hl: the time template without digits.
NoTimeText::
	db $7f, $d5, $7f, $7f, $d5, $7f, $7f, $ff

;@ def CheckRecord(finished: a, time: hl, bike: b)
;@ path: game/results
;@ If the bike finished and its race time is at most the course's best time
;@ (wBestTimes), the time becomes the new best time and wNewRecord = bike.
;@ writes: wNewRecord
;@ reads: wCourse
;@ test: finished = rng.choice([0, 1, 2]); time = rand_ram(3); wCourse = rand(1, 8); bike = rand(1, 2)
;@ sig: 330afecf
CheckRecord::
;> if not finished: return
	and a
	ret z

;> rec = u16(addr(wBestTimes) + u8(3 * u8(wCourse - 1)))
	push bc
	ld de, wBestTimes
	ld a, [wCourse]
	dec a
	ld c, a
	add a
	add c
	rst $30
;> best = mem[rec] | mem[u16(rec + 1)] << 8 | mem[u16(rec + 2)] << 16
;> t = mem[time] | mem[u16(time + 1)] << 8 | mem[u16(time + 2)] << 16
;> if best < t: return
	ld a, [de]
	sub [hl]
	inc de
	inc hl
	ld a, [de]
	sbc [hl]
	inc de
	inc hl
	ld a, [de]
	sbc [hl]
	pop bc
	ret c

;> for i in (2, 1, 0): mem[u16(rec + i)] = mem[u16(time + i)]
	push bc
	ld a, [hld]
	ld [de], a
	dec de
	ld a, [hld]
	ld [de], a
	dec de
	ld a, [hld]
	ld [de], a
;> wNewRecord = bike
;> return
	pop af
	ld [wNewRecord], a
	ret


;@ def RecordTrail()
;@ path: bike/draw
;@ While the camera moves (wCamVelY or wCamVelX not 0): pushes the bike's position
;@ and angle onto the 16-entry history the afterimages are drawn from (wTrailY,
;@ wTrailX, wTrailAngle), dropping the oldest.
;@ reads: wBikeAngle, wBikeX, wBikeY
;@ sig: 969a8d19
RecordTrail::
;> if not (wCamVelY | wCamVelX): return
	ld hl, wCamVelY
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	or [hl]
	ret z

;> copy(addr(wTrailY), addr(wTrailY) + 1, 15)
	ld hl, $cb41
	ld de, wTrailY
	ld bc, $000f
	call CopyBytes
;> wTrailY[15] = hi(wBikeY)
	ld a, [wBikeY + 1]
	ld [de], a
;> copy(addr(wTrailX), addr(wTrailX) + 2, 30)
	ld hl, $cb52
	ld de, wTrailX
	ld bc, $001e
	call CopyBytes
;> wTrailX[30] = wBikeX[1]
;> wTrailX[31] = wBikeX[2]
	ld a, [wBikeX + 1]
	ld [de], a
	inc de
	ld a, [wBikeX + 2]
	ld [de], a
;> copy(addr(wTrailAngle), addr(wTrailAngle) + 1, 15)
	ld hl, $cb71
	ld de, wTrailAngle
	ld bc, $000f
	call CopyBytes
;> wTrailAngle[15] = wBikeAngle
;> return
	ld a, [wBikeAngle]
	ld [de], a
	ret


;@ def ComDrive()
;@ path: race/com
;@ The computer bike's controls for this frame (ComButtons), then its rubber
;@ band (ComCatchUp).
;@ sig: 19b2a8ec
ComDrive::
;> ComButtons()
	call ComButtons
;> return ComCatchUp()
	jp ComCatchUp


;@ def ComButtons()
;@ path: race/com
;@ The computer's buttons: the throttle (A) and Up always; in the air (mode 2),
;@ while it flies downwards (a travel angle of 9-$17) and the bike is not level,
;@ it also tilts forward (Left).
;@ writes: wBikeHeld
;@ reads: wBikeAngle, wBikeHeld, wBikeMode, wBikeMoveAngle
;@ test: wBikeMode = rng.choice([2, rand(0, 8)]); wBikeMoveAngle = rand(0, 0x20); wBikeAngle = rng.choice([0, rand(0, 0x1F)])
;@ sig: 55a1e1fa
ComButtons::
;> wBikeHeld = BTN_A | BTN_UP
	ld a, $14
	ld [wBikeHeld], a
;> if wBikeMode != 2: return
	ld a, [wBikeMode]
	cp $02
	ret nz

;> if 0x09 <= wBikeMoveAngle < 0x18 and wBikeAngle != 0:
	ld a, [wBikeMoveAngle]
	cp $09
	jr c, jr_000_3233

	cp $18
	jr nc, jr_000_3233

	ld a, [wBikeAngle]
	cp $00
	jr z, jr_000_3233

;>     wBikeHeld |= BTN_LEFT
	ld a, [wBikeHeld]
	or $02
	ld [wBikeHeld], a

;> return
jr_000_3233:
	ret


;@ def ComCatchUp()
;@ path: race/com
;@ The rubber band between the computer bike (this record) and the player
;@ (wOtherBike). Ahead of the player, the computer drives slower once its lead
;@ reaches 64 pixels ($80 at level B, $F0 at level C): top speed $4F instead of
;@ $77, no power-up, Up released (wComFarAhead). More than 48 pixels behind,
;@ it is put back on the track just left of the screen (PlaceBehindCamera).
;@ writes: wBikeHeld, wBikeTopSpeed, wComFarAhead, wPowerUpA
;@ reads: wBikeHeld, wBikeX, wOtherBike, wRound
;@ test: com = rand(0x100, 0x1F00); mem[0xC788] = com & 0xFF; mem[0xC789] = com >> 8
;@ test: other = com + rng.choice([rand(-0x100, 0x100), rand(-0x40, 0x40)]); mem[0xC808] = other & 0xFF; mem[0xC809] = other >> 8
;@ test: wRound = rand(0, 3); wCourse = rand(1, 8); cam = rand(0x20, 0x1FF0); mem[0xC903] = cam & 0xFF; mem[0xC904] = cam >> 8
;@ sig: fa7696d0
ComCatchUp::
;> com = wBikeX[2] << 8 | wBikeX[1]
	ld a, [wBikeX + 1]
	ld e, a
	ld a, [wBikeX + 2]
	ld d, a
;> other = wOtherBike[0x09] << 8 | wOtherBike[0x08]    # the player's X (the other record)
	ld a, [wOtherBike + 8]
	ld l, a
	ld a, [wOtherBike + 9]
	ld h, a
;> if other < com:
;>@ahead1     lead = u16(com - other)
;>@ahead2     limit = {1: 0x80, 2: 0xF0}.get(wRound, 0x40)
;>@ahead3     if lead < limit: far, top, power, mask = 0, 0x77, 1, 0xFF
;>@ahead4     else: far, top, power, mask = 1, 0x4F, 0, 0xFB
;>@ahead5     wComFarAhead = far; wBikeTopSpeed = top; wPowerUpA = power
;>@ahead6     wBikeHeld &= mask; return
	call SubHLDE
	jr c, jr_000_32b8

;> if u16(other - com) < 0x30: return
	ld de, $0030
	rst $20
	ret c

;> PlaceBehindCamera()
;> return
	call PlaceBehindCamera
	ret


;@ def PlaceBehindCamera()
;@ path: race/com
;@ Puts the computer bike back on the track just off the left edge of the screen
;@ (16 pixels left of the camera): the course's list of flat ground stretches
;@ (pointers at $60FB: from X, to X, ground Y; highest first) gives the stretch
;@ that starts before that point, and the bike lands on it there, or at the
;@ stretch's end if it ends earlier (unless the bike is already past it). The
;@ bike is set upright on the ground (mode 1).
;@ writes: wBikeAngle, wBikeMode, wBikeMoveAngle, wBikeX, wBikeY, wCrashMarker, wCrashTimer, wJumpKind, wNitroFlame
;@ reads: wBikeX, wCamX, wCourse
;@ test: wCourse = rand(1, 8); cam = rand(0x20, 0x1FF0); mem[0xC903] = cam & 0xFF; mem[0xC904] = cam >> 8
;@ test: x = rand(0, 0x1FFF); mem[0xC788] = x & 0xFF; mem[0xC789] = x >> 8
;@ sig: ac902fe2
PlaceBehindCamera::
;> p = mem16[u16(0x60FB + u8(2 * u8(wCourse - 1)))]   # the course's ground stretches
	ld hl, $60fb
	ld a, [wCourse]
	dec a
	rst $10
;> pos = u16((wCamX[2] << 8 | wCamX[1]) - 16)
	ld a, [wCamX + 1]
	ld l, a
	ld a, [wCamX + 2]
	ld h, a
	ld bc, $0010
	call SubHLBC
	ld c, l
	ld b, h

jr_000_326a:
;> while mem16[p] >= pos: p = u16(p + 5)
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	inc de
	call SubHLBC
	jr c, jr_000_327a

	inc de
	inc de
	inc de
	jr jr_000_326a

jr_000_327a:
;> end = mem16[u16(p + 2)]
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
;> if end >= pos: x = pos
	push hl
	call SubHLBC
	pop hl
	jr nc, jr_000_3292

;> else:
;>     if end < (wBikeX[2] << 8 | wBikeX[1]): return
	ld a, [wBikeX + 1]
	ld c, a
	ld a, [wBikeX + 2]
	ld b, a
	rst $18
	ret c

;>     x = end
	ld c, l
	ld b, h

jr_000_3292:
;> wBikeX[1] = lo(x)
;> wBikeX[2] = hi(x)
	ld a, c
	ld [wBikeX + 1], a
	ld a, b
	ld [wBikeX + 2], a
;> mem[addr(wBikeY) + 1] = mem[u16(p + 4)]     # the ground's pixel row
	inc de
	ld a, [de]
	ld [wBikeY + 1], a
;> wBikeAngle = wBikeMoveAngle = wNitroFlame = wJumpKind = wCrashTimer = wCrashMarker = 0
	xor a
	ld [wBikeAngle], a
	ld [wBikeMoveAngle], a
	ld [wNitroFlame], a
	ld [wJumpKind], a
	ld [wCrashTimer], a
	ld [wCrashMarker], a
;> wBikeMode = 1
;> return
	ld a, $01
	ld [wBikeMode], a
	ret


;=@ComCatchUp.ahead1
jr_000_32b8:
	rst $38
;=@ComCatchUp.ahead2
	ld a, [wRound]
	dec a
	ld de, $0080
	jr z, jr_000_32cb

	dec a
	ld de, $00f0
	jr z, jr_000_32cb

	ld de, $0040

jr_000_32cb:
;=@ComCatchUp.ahead3
	rst $20
	ld b, $00
	ld d, $77
	ld e, $01
	ld c, $ff
	jr c, jr_000_32dc

;=@ComCatchUp.ahead4
	inc b
	ld d, $4f
	dec e
	ld c, $fb

jr_000_32dc:
;=@ComCatchUp.ahead5
	ld a, b
	ld [wComFarAhead], a
	ld a, d
	ld [wBikeTopSpeed], a
	ld a, e
	ld [wPowerUpA], a
;=@ComCatchUp.ahead6
	ld a, [wBikeHeld]
	and c
	ld [wBikeHeld], a
	ret


;@ def IsComRace() -> zero
;@ path: race/com
;@ True (zero set) in a race against the computer: two bikes on one Game Boy.
;@ reads: wPlayerMask
;@ test: wPlayerMask = rand(0, 7)
;@ sig: c4a5acd7
IsComRace::
;> return (wPlayerMask & 0x06) == 0x02
	ld a, [wPlayerMask]
	and $06
	cp $02
	ret


;@ def InitMenuCursors()
;@ path: game/select
;@ The course select screen starts on course 1, level A: wCourse = 1, wRound = 0,
;@ and the cursor sprites (MenuCursorSprites; one in a link game, where the
;@ level is not chosen).
;@ writes: wCourse, wRound
;@ reads: wPlayerMask
;@ test: wPlayerMask = rng.choice([1, 3, 7])
;@ sig: f0c6f993
InitMenuCursors::
;> wRound = 0
	xor a
	ld [wRound], a
;> wCourse = 1
	ld a, $01
	ld [wCourse], a
;> copy(addr(wShadowOAM), MenuCursorSprites, 4 if wPlayerMask & 0x04 else 8)
;> return
	ld de, wShadowOAM
	ld hl, MenuCursorSprites
	ld a, [wPlayerMask]
	and $04
	ld bc, $0008
	jr z, jr_000_3314

	ld bc, $0004

jr_000_3314:
	jp CopyBytes


;@ Two cursor sprites (y, x, tile, attributes) for the course and level menus; a link game uses only the first.
MenuCursorSprites::
	db $48, $18, $d3, $00, $88, $40, $d3, $00

;@ def CourseSelectInput()
;@ path: game/select
;@ The course select screen's input: one step per wSelectStep (choose the
;@ course, then the level).
;@ reads: wSelectStep
;@ test: skip jumps through a table
;@ sig: d8c9dd3d
CourseSelectInput::
;> return (ChooseCourse, ChooseLevel)[wSelectStep]()
	ld a, [wSelectStep]
	call JumpTable

JumpTable_3325::
	dw ChooseCourse
	dw ChooseLevel

;@ def SelectConfirm()
;@ path: game/select
;@ A or START on the course select screen: the next step. When it is not the
;@ last one (the level, which a link game skips), sound $17 plays, the course
;@ digits are cleared except for the chosen one and the course cursor goes.
;@ writes: wShadowOAM
;@ reads: wCourse, wPlayerMask
;@ test: wSelectStep = rand(0, 1); wPlayerMask = rng.choice([1, 3, 7]); wCourse = rand(1, 8)
;@ sig: 304205db
SelectConfirm::
jr_000_3329:
;> wSelectStep = u8(wSelectStep + 1)
	ld hl, wSelectStep
	inc [hl]
;> last = 1 if wPlayerMask & 0x04 else 2
	ld a, [wPlayerMask]
	and $04
	ld c, $02
	jr z, jr_000_3337

	dec c

jr_000_3337:
;> if wSelectStep == last: return
	ld a, [hl]
	cp c
	ret z

;> PlaySound(0x17)
	ld a, $17
	call PlaySound
;> DrawStrings(CourseDigitsBlank)
	ld de, CourseDigitsBlank
	call DrawStrings
;> col = ((mem[u16(CourseCursorX + u8(wCourse - 1))] - 8) >> 3) & 0x1F
	ld a, [wCourse]
	ld c, a
	ld hl, CourseCursorX
	dec a
	rst $28
	ld a, [hl]
	sub $08
	rra
	rra
	rra
	and $1f
;> PutTile(0xF0 | wCourse, u16(0x98E0 + col))   # the chosen course's digit back
	ld hl, $98e0
	rst $28
	ld a, c
	or $f0
	call PutTile
;> wShadowOAM[0] = 0                          # the course cursor off
;> return
	xor a
	ld [wShadowOAM], a
	ret


;@ def ChooseCourse()
;@ path: game/select
;@ Step 0 of the course select screen: Left and Right pick the course (1-8,
;@ wrapping round), with sound $15; A or START goes on (SelectConfirm).
;@ writes: wCourse, wShadowOAM
;@ reads: wCourse, wJoyPressed
;@ test: wJoyPressed = rand(0, 255); wCourse = rand(0, 9); wSelectStep = 0; wPlayerMask = rng.choice([1, 3, 7])
;@ sig: 33d569f7
ChooseCourse::
;> if wJoyPressed & (BTN_A | BTN_START): return SelectConfirm()
	ld a, [wJoyPressed]
	and $90
	jr nz, jr_000_3329

;> if not wJoyPressed & (BTN_RIGHT | BTN_LEFT): return
	ld a, [wJoyPressed]
	and $03
	ret z

;> if wJoyPressed & BTN_RIGHT:
;>@up     c = u8(wCourse + 1)
;>@up2     wCourse = c if c != 9 else 1
	and $01
	jr nz, jr_000_3387

;> else:
;>     c = u8(wCourse - 1)
;>     wCourse = c if c else 8
	ld a, [wCourse]
	dec a
	ld [wCourse], a
	and a
	jr nz, jr_000_3397

	ld a, $08
	ld [wCourse], a
	jr jr_000_3397

jr_000_3387:
;=@up
	ld a, [wCourse]
	inc a
	ld [wCourse], a
;=@up2
	cp $09
	jr nz, jr_000_3397

	ld a, $01
	ld [wCourse], a

jr_000_3397:
;> PlaySound(0x15)
	ld a, $15
	call PlaySound
;> wShadowOAM[1] = mem[u16(CourseCursorX + u8(wCourse - 1))]   # the cursor's X
	ld a, [wCourse]
	ld hl, CourseCursorX
	dec a
	rst $28
	ld a, [hl]
	ld [wShadowOAM + 1], a
;> return
	ret


;@ def ChooseLevel()
;@ path: game/select
;@ Step 1 of the course select screen: Left and Right pick the level A-C
;@ (wRound, wrapping round), with sound $15; A or START goes on (SelectConfirm).
;@ writes: wRound, wShadowOAM
;@ reads: wJoyPressed, wRound
;@ test: wJoyPressed = rand(0, 255); wRound = rand(0, 3); wSelectStep = 1; wPlayerMask = rng.choice([1, 3])
;@ sig: bc909eee
ChooseLevel::
;> if wJoyPressed & (BTN_A | BTN_START): return SelectConfirm()
	ld a, [wJoyPressed]
	and $90
	jp nz, SelectConfirm

;> if not wJoyPressed & (BTN_RIGHT | BTN_LEFT): return
	ld a, [wJoyPressed]
	and $03
	ret z

;> if wJoyPressed & BTN_RIGHT:
;>@up     r = u8(wRound + 1)
;>@up2     wRound = r if r != 3 else 0
	and $01
	jr nz, jr_000_33cd

;> else:
;>     r = u8(wRound - 1)
;>     wRound = r if r != 0xFF else 2
	ld a, [wRound]
	dec a
	ld [wRound], a
	cp $ff
	jr nz, jr_000_33dc

	ld a, $02
	ld [wRound], a
	jr jr_000_33dc

jr_000_33cd:
;=@up
	ld a, [wRound]
	inc a
	ld [wRound], a
;=@up2
	cp $03
	jr nz, jr_000_33dc

	xor a
	ld [wRound], a

jr_000_33dc:
;> PlaySound(0x15)
	ld a, $15
	call PlaySound
;> wShadowOAM[5] = mem[u16(ModeCursorX + wRound)]   # the second cursor's X
	ld a, [wRound]
	ld hl, ModeCursorX
	rst $28
	ld a, [hl]
	ld [wShadowOAM + 5], a
;> return
	ret


;@ The cursor sprite's X position for each of the 8 courses on the SELECT COURSE row.
CourseCursorX::
	db $18, $28, $38, $48, $58, $68, $78, $88


;@ The second cursor sprite's X position for levels A, B and C on the SELECT LEVEL row.
ModeCursorX::
	db $40, $58, $70


;@ asset: strings tiles=LoadFont|LoadFont+LoadTileList(hl=RaceGfxList)
;@ Text list (BG address, tiles, $FE next / $FF end): SELECT LEVEL with A B C, then SELECT COURSE with the digits 1-8.
CourseSelectText::
	db $43, $99, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	db $fe, $63, $99, $aa, $93, $9d, $90, $9d, $94, $9a, $aa, $90, $9d, $8a, $9d, $90
	db $aa, $fe, $83, $99, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	db $aa, $aa, $fe, $e7, $99, $df, $7f, $7f, $e5, $7f, $7f, $e4, $fe, $42, $98, $aa
	db $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $fe
	db $62, $98, $aa, $93, $9d, $90, $9d, $94, $9a, $aa, $aa, $94, $8e, $9e, $92, $93
	db $9d, $aa, $fe, $82, $98, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	db $aa, $aa, $aa, $aa, $aa, $fe, $e2, $98, $f1, $7f, $f2, $7f, $f3, $7f, $f4, $7f
	db $f5, $7f, $f6, $7f, $f7, $7f, $f8, $ff


;@ Text list: blanks over the course digits 1-8, before the chosen digit is put back.
CourseDigitsBlank::
	db $e2, $98, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f
	db $7f, $ff


;@ A table of pointers to sprite layouts (each a count, then y, x, tile, attributes per sprite).
MetaspritePointers::
	db $02, $35, $14, $35, $26, $35, $38, $35, $4a, $35, $5c, $35, $6e, $35, $80, $35
	db $92, $35, $a4, $35, $b6, $35, $c8, $35, $da, $35, $ec, $35, $fe, $35, $10, $36
	db $22, $36, $34, $36, $46, $36, $58, $36, $6a, $36, $7c, $36, $8e, $36, $a0, $36
	db $b2, $36, $c4, $36, $d6, $36, $e8, $36, $fa, $36, $0c, $37, $1e, $37, $30, $37
	db $02, $35, $02, $35, $02, $35, $02, $35, $02, $35, $02, $35, $02, $35, $02, $35
	db $02, $35, $42, $37, $4b, $37, $5d, $37, $6a, $37, $74, $37, $7e, $37, $87, $37
	db $96, $37, $ab, $37, $c0, $37, $d5, $37, $de, $37, $f0, $37, $fd, $37, $07, $38
	db $05, $00, $00, $00, $00, $00, $08, $01, $00, $08, $00, $02, $00, $08, $08, $03
	db $00, $80, $05, $00, $00, $04, $00, $00, $08, $05, $00, $08, $00, $06, $00, $08
	db $08, $07, $00, $80, $05, $00, $00, $08, $00, $00, $08, $09, $00, $08, $00, $0a
	db $00, $08, $08, $0b, $00, $80, $05, $00, $00, $0c, $00, $00, $08, $0d, $00, $08
	db $00, $0e, $00, $08, $08, $0f, $00, $80, $05, $00, $00, $10, $00, $00, $08, $11
	db $00, $08, $00, $12, $00, $08, $08, $13, $00, $80, $05, $00, $00, $14, $00, $00
	db $08, $15, $00, $08, $00, $16, $00, $08, $08, $17, $00, $80, $05, $00, $00, $18
	db $00, $00, $08, $19, $00, $08, $00, $1a, $00, $08, $08, $1b, $00, $80, $05, $00
	db $00, $1c, $00, $00, $08, $1d, $00, $08, $00, $1e, $00, $08, $08, $1f, $00, $80
	db $05, $00, $00, $20, $00, $00, $08, $21, $00, $08, $00, $22, $00, $08, $08, $23
	db $00, $80, $05, $00, $00, $24, $00, $00, $08, $25, $00, $08, $00, $26, $00, $08
	db $08, $27, $00, $80, $05, $00, $00, $28, $00, $00, $08, $29, $00, $08, $00, $2a
	db $00, $08, $08, $2b, $00, $80, $05, $00, $00, $2c, $00, $00, $08, $2d, $00, $08
	db $00, $2e, $00, $08, $08, $2f, $00, $80, $05, $00, $00, $30, $00, $00, $08, $31
	db $00, $08, $00, $32, $00, $08, $08, $33, $00, $80, $05, $00, $00, $34, $00, $00
	db $08, $35, $00, $08, $00, $36, $00, $08, $08, $37, $00, $80, $05, $00, $00, $38
	db $00, $00, $08, $39, $00, $08, $00, $3a, $00, $08, $08, $3b, $00, $80, $05, $00
	db $00, $3c, $00, $00, $08, $3d, $00, $08, $00, $3e, $00, $08, $08, $3f, $00, $80
	db $05, $00, $00, $03, $60, $00, $08, $02, $60, $08, $00, $01, $60, $08, $08, $00
	db $60, $80, $05, $00, $00, $07, $60, $00, $08, $06, $60, $08, $00, $05, $60, $08
	db $08, $04, $60, $80, $05, $00, $00, $0b, $60, $00, $08, $0a, $60, $08, $00, $09
	db $60, $08, $08, $08, $60, $80, $05, $00, $00, $0f, $60, $00, $08, $0e, $60, $08
	db $00, $0d, $60, $08, $08, $0c, $60, $80, $05, $00, $00, $13, $60, $00, $08, $12
	db $60, $08, $00, $11, $60, $08, $08, $10, $60, $80, $05, $00, $00, $17, $60, $00
	db $08, $16, $60, $08, $00, $15, $60, $08, $08, $14, $60, $80, $05, $00, $00, $1b
	db $60, $00, $08, $1a, $60, $08, $00, $19, $60, $08, $08, $18, $60, $80, $05, $00
	db $00, $1f, $60, $00, $08, $1e, $60, $08, $00, $1d, $60, $08, $08, $1c, $60, $80
	db $05, $00, $00, $23, $60, $00, $08, $22, $60, $08, $00, $21, $60, $08, $08, $20
	db $60, $80, $05, $00, $00, $27, $60, $00, $08, $26, $60, $08, $00, $25, $60, $08
	db $08, $24, $60, $80, $05, $00, $00, $2b, $60, $00, $08, $2a, $60, $08, $00, $29
	db $60, $08, $08, $28, $60, $80, $05, $00, $00, $2f, $60, $00, $08, $2e, $60, $08
	db $00, $2d, $60, $08, $08, $2c, $60, $80, $05, $00, $00, $33, $60, $00, $08, $32
	db $60, $08, $00, $31, $60, $08, $08, $30, $60, $80, $05, $00, $00, $37, $60, $00
	db $08, $36, $60, $08, $00, $35, $60, $08, $08, $34, $60, $80, $05, $00, $00, $3b
	db $60, $00, $08, $3a, $60, $08, $00, $39, $60, $08, $08, $38, $60, $80, $05, $00
	db $00, $3f, $60, $00, $08, $3e, $60, $08, $00, $3d, $60, $08, $08, $3c, $60, $80
	db $02, $08, $00, $44, $00, $08, $08, $45, $00, $05, $08, $00, $44, $00, $08, $08
	db $45, $00, $80, $08, $00, $46, $00, $08, $08, $47, $00, $03, $00, $08, $48, $00
	db $08, $00, $49, $00, $08, $08, $4a, $00, $03, $00, $04, $4b, $00, $08, $04, $4c
	db $00, $80, $03, $00, $04, $4d, $00, $08, $04, $4e, $00, $80, $02, $00, $04, $4d
	db $00, $08, $04, $4f, $00, $05, $00, $05, $50, $00, $08, $00, $51, $00, $08, $08
	db $52, $00, $80, $80, $05, $f8, $00, $80, $00, $00, $00, $81, $00, $00, $08, $0d
	db $00, $08, $00, $82, $00, $08, $08, $0f, $00, $05, $f8, $00, $80, $00, $00, $00
	db $83, $00, $00, $08, $85, $00, $08, $00, $84, $00, $08, $08, $86, $00, $05, $f8
	db $00, $87, $00, $00, $00, $88, $00, $00, $08, $8a, $00, $08, $00, $89, $00, $08
	db $08, $8b, $00, $02, $08, $08, $44, $20, $08, $00, $45, $20, $05, $08, $08, $44
	db $20, $08, $00, $45, $20, $80, $08, $00, $46, $00, $08, $08, $47, $00, $03, $00
	db $00, $48, $20, $08, $08, $49, $20, $08, $00, $4a, $20, $03, $00, $04, $4b, $20
	db $08, $04, $4c, $20, $80, $03, $00, $04, $4d, $20, $08, $04, $4e, $20, $80


;@ The race's graphics: a LoadTileList list (tile, mode, count, source per entry).
RaceGfxList::
	db $80, $00, $53, $00, $21, $39, $00, $01, $0d, $00, $51, $3e, $20, $01, $09, $00
	db $61, $3f, $0d, $01, $05, $00, $11, $3f, $12, $61, $06, $0e, $e3, $13, $18, $61
	db $01, $0e, $63, $14, $19, $61, $01, $06, $0b, $14, $1a, $61, $01, $06, $63, $14
	db $6f, $01, $01, $00, $11, $3f, $2a, $01, $0f, $00, $f1, $3f, $37, $01, $01, $00
	db $c1, $40, $38, $81, $01, $00, $c1, $40, $3f, $01, $04, $00, $d1, $40, $45, $01
	db $18, $00, $11, $41, $62, $01, $0e, $00, $91, $42, $7a, $01, $06, $00, $71, $43
	db $80, $01, $01, $00, $d1, $43, $81, $01, $01, $00, $e1, $43, $82, $01, $06, $00
	db $f1, $43, $88, $01, $10, $00, $51, $44, $98, $01, $07, $00, $51, $45, $9f, $01
	db $03, $00, $c1, $45, $a6, $01, $04, $00, $f1, $45, $c5, $01, $05, $00, $31, $46
	db $d7, $01, $03, $00, $81, $46, $e0, $01, $02, $00, $b1, $46, $e3, $01, $05, $00
	db $d1, $46, $f5, $01, $03, $00, $21, $47, $fe, $01, $01, $00, $51, $47, $a2, $81
	db $01, $00, $d1, $43, $a3, $81, $01, $00, $e1, $43, $a4, $41, $01, $00, $f1, $43
	db $aa, $81, $10, $00, $51, $44, $ba, $81, $07, $00, $51, $45, $c1, $81, $01, $00
	db $c1, $45, $b8, $41, $01, $00, $c1, $45, $ff, $01, $01, $00, $61, $47, $c2, $01
	db $01, $00, $61, $47, $c3, $41, $01, $00, $e1, $43, $c4, $81, $01, $00, $f1, $43
	db $ca, $41, $0d, $00, $51, $44, $da, $41, $06, $00, $51, $45, $e2, $c1, $01, $00
	db $f1, $43, $e8, $c1, $0d, $00, $51, $44, $f8, $c1, $06, $00, $51, $45, $00, $00
	db $02, $01, $07, $00, $02, $05, $00, $07, $05, $03, $0e, $01, $09, $06, $76, $7b
	db $00, $00, $00, $80, $c0, $c0, $80, $80, $00, $00, $40, $80, $a0, $60, $fc, $fc
	db $1f, $f9, $08, $1f, $7d, $7e, $cd, $ce, $ba, $ff, $83, $bf, $8c, $cc, $78, $78
	db $f0, $fe, $f0, $f0, $de, $dc, $9a, $bb, $2d, $a9, $a1, $ad, $23, $33, $1e, $1e
	db $08, $06, $1f, $03, $0a, $16, $02, $1e, $00, $0e, $1e, $01, $13, $0f, $7d, $73
	db $00, $00, $00, $00, $00, $00, $00, $00, $80, $00, $58, $d8, $e0, $fc, $e0, $e0
	db $1c, $fb, $0d, $1e, $7d, $7e, $cf, $cf, $bb, $ff, $80, $bc, $8c, $cc, $78, $78
	db $fe, $fc, $9a, $bb, $ad, $a9, $21, $ad, $a3, $b3, $1e, $1e, $00, $00, $00, $00
	db $24, $1c, $78, $08, $28, $58, $04, $78, $01, $1e, $3d, $03, $23, $1f, $7d, $63
	db $00, $00, $00, $00, $00, $00, $30, $30, $e0, $f8, $80, $e0, $de, $dc, $f2, $f3
	db $2b, $fd, $09, $9e, $7d, $7f, $cf, $cf, $b0, $fe, $84, $b4, $8c, $cc, $78, $78
	db $bd, $b9, $a5, $ad, $23, $b3, $9e, $9e, $00, $00, $00, $00, $00, $00, $00, $00
	db $48, $38, $f0, $10, $50, $b0, $01, $fd, $03, $3d, $3f, $03, $23, $1f, $3f, $21
	db $00, $00, $20, $20, $40, $70, $80, $c0, $de, $dc, $f2, $f3, $bd, $b9, $a9, $bd
	db $49, $7e, $8e, $df, $3f, $bf, $6a, $6f, $52, $7e, $42, $5a, $46, $66, $3c, $3c
	db $a3, $b3, $1e, $de, $c0, $c0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $10, $30, $60, $b0, $f1, $11, $40, $bb, $05, $7b, $3b, $07, $31, $0f, $1d, $02
	db $40, $60, $80, $c0, $1e, $9c, $c2, $f3, $f9, $fd, $a9, $ad, $a3, $b3, $9e, $de
	db $1a, $1f, $2f, $3f, $4d, $6f, $1d, $5f, $14, $1e, $12, $16, $11, $19, $0f, $0f
	db $40, $e0, $c0, $c0, $00, $80, $80, $80, $80, $80, $80, $80, $80, $80, $00, $00
	db $00, $00, $10, $30, $61, $b1, $f1, $11, $49, $bf, $05, $7b, $3c, $07, $13, $0c
	db $80, $c0, $1e, $9c, $32, $b3, $6d, $fd, $f9, $fd, $a3, $b3, $5e, $de, $e0, $20
	db $07, $0b, $1f, $1f, $12, $1f, $27, $37, $25, $27, $04, $05, $04, $06, $03, $03
	db $f0, $f0, $c0, $e0, $c0, $c0, $e0, $e0, $20, $a0, $a0, $a0, $60, $60, $c0, $c0
	db $00, $00, $01, $01, $21, $21, $42, $63, $73, $b1, $e5, $1b, $4d, $b3, $1b, $66
	db $1e, $9c, $22, $b3, $2d, $ad, $f1, $fd, $23, $f3, $9e, $9e, $c0, $c0, $f0, $30
	db $1e, $05, $05, $0b, $0f, $0f, $09, $0f, $12, $1b, $12, $12, $02, $03, $01, $01
	db $60, $f0, $c0, $e0, $60, $e0, $f0, $f0, $90, $d0, $50, $d0, $30, $30, $e0, $e0
	db $00, $00, $01, $01, $01, $01, $01, $01, $43, $63, $47, $e1, $43, $bd, $e5, $1b
	db $0e, $9e, $33, $93, $29, $a5, $b9, $fd, $f1, $f3, $8e, $de, $c0, $e0, $68, $f8
	db $5c, $23, $19, $06, $0e, $01, $06, $07, $02, $03, $04, $06, $00, $02, $00, $00
	db $f8, $18, $38, $f8, $a8, $f8, $fc, $fc, $a4, $b4, $a4, $b4, $cc, $cc, $78, $78
	db $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $03, $03, $25, $23, $33, $75
	db $0e, $1e, $33, $93, $29, $a5, $39, $bd, $f1, $f3, $ce, $de, $e0, $e0, $f4, $fc
	db $4a, $bd, $e5, $1b, $4d, $32, $06, $01, $01, $01, $01, $01, $01, $01, $00, $00
	db $b4, $cc, $8c, $7c, $b2, $7e, $fb, $ff, $a9, $ed, $29, $ad, $31, $bb, $1e, $9e
	db $00, $00, $00, $00, $00, $02, $04, $06, $04, $06, $03, $03, $07, $07, $0b, $07
	db $38, $78, $cc, $4c, $a4, $94, $e4, $f4, $c4, $cc, $b8, $f8, $80, $80, $e8, $f8
	db $43, $47, $76, $fb, $45, $ba, $e5, $1a, $47, $31, $01, $01, $01, $01, $00, $00
	db $78, $98, $18, $f8, $f2, $7e, $fb, $ff, $a9, $ed, $29, $ad, $31, $bb, $1e, $9e
	db $00, $01, $03, $01, $02, $02, $02, $0a, $13, $1b, $19, $1d, $0b, $0f, $0f, $0f
	db $e0, $e0, $30, $30, $d0, $50, $90, $d0, $90, $b0, $e0, $e0, $00, $00, $d0, $f0
	db $0f, $07, $02, $0f, $95, $8a, $65, $fa, $45, $ba, $e7, $11, $41, $31, $00, $00
	db $f0, $b0, $90, $78, $36, $fe, $f3, $fb, $29, $ed, $a9, $ad, $31, $bb, $1e, $de
	db $03, $07, $0c, $04, $0a, $09, $0b, $0b, $0e, $2f, $47, $67, $2c, $3c, $1f, $1f
	db $80, $80, $c0, $c0, $40, $40, $40, $40, $40, $c0, $80, $80, $20, $60, $a0, $e0
	db $1f, $1f, $0f, $06, $05, $1a, $85, $9a, $65, $fa, $47, $b9, $e0, $10, $40, $30
	db $a0, $70, $7e, $fe, $63, $fb, $f1, $fd, $29, $ed, $31, $bb, $9e, $de, $40, $60
	db $0e, $1e, $33, $13, $21, $2d, $2d, $2d, $29, $3b, $0e, $9e, $98, $d9, $5f, $7f
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $c0, $c0, $5e, $fe
	db $2f, $3e, $04, $1f, $09, $06, $05, $1a, $a7, $f8, $66, $d8, $70, $08, $20, $50
	db $73, $f3, $c5, $fd, $79, $fd, $f1, $fb, $9e, $de, $40, $60, $20, $30, $00, $00
	db $1c, $3c, $66, $26, $52, $5a, $5a, $5a, $6a, $7e, $3d, $3d, $1b, $9a, $8d, $fe
	db $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $9e, $de, $f3, $f3, $f5, $fd
	db $3d, $3e, $01, $0e, $06, $0b, $0a, $0d, $53, $7c, $32, $6c, $38, $04, $10, $28
	db $d9, $fd, $f1, $fb, $de, $7e, $40, $e0, $60, $70, $18, $18, $00, $00, $00, $00
	db $38, $78, $cc, $4c, $a4, $b4, $a4, $b4, $95, $dd, $79, $79, $13, $1a, $17, $fe
	db $00, $00, $00, $00, $00, $00, $00, $00, $1e, $9e, $b3, $f3, $f5, $fd, $59, $fd
	db $6f, $7e, $19, $17, $06, $01, $03, $04, $09, $0e, $2c, $3b, $1e, $11, $04, $0a
	db $71, $fb, $ae, $7e, $e0, $b0, $b0, $78, $8c, $0c, $00, $00, $00, $00, $00, $00
	db $78, $78, $c4, $cc, $84, $b4, $b5, $95, $58, $dd, $79, $3b, $0b, $1f, $1e, $ff
	db $00, $00, $00, $00, $1e, $1e, $f3, $f3, $d1, $fd, $fd, $7d, $93, $73, $be, $7e
	db $7f, $7f, $0e, $09, $05, $02, $00, $03, $00, $03, $01, $0e, $0f, $0c, $01, $06
	db $40, $b8, $38, $de, $b4, $54, $e0, $00, $c0, $00, $00, $80, $80, $00, $00, $00
	db $20, $10, $18, $38, $30, $30, $ae, $78, $5a, $3f, $56, $ee, $f5, $9d, $42, $67
	db $44, $22, $4e, $e7, $d5, $7d, $6a, $7f, $5c, $34, $b0, $68, $58, $68, $20, $30
	db $02, $0b, $1d, $0d, $16, $0f, $58, $5e, $6e, $fa, $b2, $7d, $0f, $15, $12, $06
	db $20, $70, $50, $d0, $e8, $78, $5a, $36, $2e, $39, $15, $ff, $fa, $76, $24, $40
	db $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $33, $2c, $3d, $33, $26, $2f
	db $10, $08, $38, $04, $16, $2e, $c4, $3c, $d8, $38, $b0, $d0, $d0, $e8, $38, $7c
	db $00, $00, $00, $00, $00, $00, $70, $7c, $2f, $7f, $7d, $ff, $a7, $ff, $79, $79
	db $20, $20, $20, $20, $10, $10, $fc, $fc, $fa, $fe, $de, $ff, $ed, $eb, $9e, $be
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $20, $e0, $10
	db $00, $00, $03, $00, $07, $00, $02, $05, $06, $01, $15, $0b, $3a, $37, $19, $1d
	db $58, $b8, $10, $f0, $60, $e0, $80, $40, $80, $40, $40, $80, $80, $e0, $c0, $c0
	db $00, $00, $20, $10, $70, $08, $2c, $5c, $08, $78, $50, $30, $e0, $10, $98, $68
	db $38, $fc, $10, $78, $30, $50, $30, $50, $60, $30, $20, $70, $40, $60, $70, $70
	db $00, $00, $10, $08, $38, $04, $16, $2e, $04, $3c, $28, $18, $32, $0a, $2c, $52
	db $94, $fc, $08, $3c, $18, $2e, $18, $6e, $f0, $96, $c6, $e6, $83, $83, $00, $00
	db $9a, $66, $6c, $bc, $d0, $b0, $30, $50, $30, $50, $60, $a0, $80, $c0, $e0, $e0
	db $00, $00, $20, $10, $70, $08, $2c, $5c, $08, $78, $50, $30, $ec, $18, $9a, $66
	db $03, $05, $7e, $fd, $0d, $7e, $79, $7e, $cb, $cd, $bd, $ff, $c7, $ff, $38, $78
	db $60, $e0, $fc, $fc, $b0, $fe, $de, $dc, $ba, $fb, $2d, $a9, $21, $bd, $1e, $1e
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $30, $00, $68, $18
	db $78, $38, $14, $78, $03, $3c, $19, $07, $37, $09, $2b, $17, $0d, $13, $3a, $3d
	db $4e, $7d, $8e, $df, $3f, $bf, $6a, $6f, $52, $7e, $42, $5a, $46, $66, $3c, $3c
	db $7a, $39, $14, $7a, $00, $3c, $19, $05, $35, $0b, $2b, $17, $0d, $13, $3d, $3b
	db $4f, $7b, $89, $df, $3f, $bf, $6a, $6f, $52, $7e, $42, $5a, $46, $66, $3c, $3c
	db $00, $00, $80, $80, $a0, $e0, $c0, $c0, $9c, $f8, $f4, $f6, $9e, $bb, $95, $fd
	db $8f, $9f, $c2, $cf, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $30, $04, $74, $1a
	db $7c, $3a, $32, $7c, $00, $3c, $15, $0d, $3b, $07, $27, $1f, $0b, $17, $3b, $37
	db $4f, $77, $83, $df, $3f, $bf, $6a, $6f, $52, $7e, $42, $5a, $46, $66, $3c, $3c
	db $40, $40, $40, $c0, $80, $80, $a0, $e0, $e0, $e0, $b0, $e8, $98, $b4, $88, $de
	db $86, $87, $c3, $c3, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $92, $ab, $b7, $7f, $8d, $f6, $76, $df, $fa, $fd, $af, $73, $6e, $ff, $ad, $df
	db $57, $ff, $ea, $f7, $b7, $d9, $7b, $ff, $ad, $f6, $76, $9b, $e9, $fe, $b7, $db
	db $00, $00, $04, $00, $09, $04, $92, $49, $54, $2a, $2c, $14, $48, $5d, $f7, $bd
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $04, $02, $09, $6f
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $74
	db $00, $00, $00, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $00, $00
	db $00, $00, $00, $00, $ff, $80, $ff, $80, $ff, $80, $ff, $80, $ff, $80, $00, $00
	db $00, $00, $00, $00, $ff, $c0, $ff, $c0, $ff, $c0, $ff, $c0, $ff, $c0, $00, $00
	db $00, $00, $00, $00, $ff, $e0, $ff, $e0, $ff, $e0, $ff, $e0, $ff, $e0, $00, $00
	db $00, $00, $00, $00, $ff, $f0, $ff, $f0, $ff, $f0, $ff, $f0, $ff, $f0, $00, $00
	db $00, $00, $00, $00, $ff, $f8, $ff, $f8, $ff, $f8, $ff, $f8, $ff, $f8, $00, $00
	db $00, $00, $00, $00, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $ff, $fc, $00, $00
	db $00, $00, $00, $00, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $fe, $00, $00
	db $00, $00, $00, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00
	db $87, $78, $32, $cd, $3e, $c1, $22, $dd, $32, $cd, $32, $cd, $32, $cd, $83, $7c
	db $0e, $f1, $66, $99, $66, $99, $66, $99, $66, $99, $67, $98, $66, $99, $0e, $f1
	db $ff, $00, $ff, $00, $ff, $00, $e7, $18, $c3, $3c, $81, $7e, $e7, $18, $e7, $18
	db $ff, $00, $ff, $00, $87, $78, $83, $7c, $81, $7e, $f8, $07, $fc, $03, $fe, $01
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $7f, $80, $3f, $c0
	db $1f, $e0, $8f, $70, $c5, $3a, $e1, $1e, $f1, $0e, $e1, $1e, $ff, $00, $ff, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $07, $8e, $bb
	db $00, $00, $00, $00, $00, $00, $08, $0c, $0a, $36, $34, $ce, $99, $7f, $62, $ff
	db $db, $24, $ee, $15, $b5, $6a, $53, $ad, $ac, $d7, $ef, $ff, $bd, $ff, $ee, $ff
	db $bb, $4c, $dc, $23, $89, $7e, $54, $ab, $e7, $5d, $ea, $ff, $dd, $ff, $f7, $ff
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $df, $34, $8b, $5e
	db $db, $04, $6e, $10, $b5, $42, $42, $31, $8c, $4a, $e7, $ff, $3b, $ff, $ee, $ff
	db $b3, $44, $dc, $01, $80, $08, $4c, $b1, $82, $ac, $1a, $ff, $e4, $ff, $ba, $ff
	db $0b, $d0, $8d, $82, $96, $c8, $54, $c0, $a8, $e5, $53, $ff, $a5, $ff, $5b, $ff
	db $bb, $7e, $bd, $7e, $df, $3c, $f7, $1d, $cf, $1f, $c6, $2e, $fe, $1f, $d6, $1f
	db $ff, $40, $ff, $40, $ff, $80, $9f, $a0, $3f, $60, $a7, $e8, $d3, $b4, $a9, $de
	db $96, $1f, $3b, $5f, $7f, $bf, $f2, $67, $c3, $6e, $e7, $5a, $df, $66, $ff, $3c
	db $fe, $87, $ff, $c3, $ff, $80, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
	db $00, $7f, $3f, $ff, $60, $e0, $41, $c1, $40, $c0, $40, $c0, $40, $c0, $40, $c0
	db $00, $fc, $f8, $fe, $0d, $0f, $e5, $e7, $c5, $f7, $c5, $e7, $c5, $e7, $c5, $e7
	db $58, $d8, $5f, $df, $40, $cf, $60, $e0, $3f, $ff, $00, $7f, $3f, $3f, $00, $00
	db $c5, $e7, $85, $e7, $05, $c7, $0d, $0f, $f9, $ff, $02, $fe, $fc, $fc, $00, $00
	db $ff, $00, $80, $7f, $bf, $7f, $bf, $70, $b8, $67, $bb, $67, $af, $70, $b0, $7f
	db $fd, $03, $05, $fb, $fd, $fb, $dd, $3b, $6d, $9b, $8d, $fb, $dd, $3b, $6d, $9b
	db $bf, $67, $af, $70, $b0, $7f, $bf, $7f, $ff, $00, $00, $ff, $ff, $ff, $00, $00
	db $ed, $9b, $cd, $3b, $1d, $fb, $fd, $fb, $fd, $03, $01, $ff, $ff, $ff, $00, $00
	db $00, $00, $ff, $ff, $ff, $80, $ff, $80, $e3, $9c, $cf, $fc, $7f, $7c, $07, $04
	db $00, $00, $fe, $fe, $ff, $03, $fd, $03, $8d, $73, $b9, $7f, $af, $6f, $a0, $60
	db $07, $04, $07, $04, $07, $04, $0f, $0c, $0f, $08, $0f, $08, $0c, $0f, $07, $07
	db $a0, $60, $a0, $60, $a0, $60, $a0, $60, $f0, $30, $d0, $30, $10, $f0, $f0, $f0
	db $ff, $00, $80, $7f, $bf, $7f, $bb, $67, $bd, $63, $be, $61, $bb, $64, $b9, $66
	db $fd, $03, $05, $fb, $fd, $fb, $ed, $9b, $ed, $9b, $ed, $9b, $6d, $9b, $ed, $1b
	db $ba, $67, $bb, $67, $a3, $7f, $bf, $7f, $ff, $00, $00, $ff, $ff, $ff, $00, $00
	db $ed, $1b, $6d, $9b, $8d, $fb, $fd, $fb, $fd, $03, $01, $ff, $ff, $ff, $00, $00
	db $ff, $00, $80, $7f, $bf, $7f, $bf, $60, $b8, $67, $bb, $67, $bf, $60, $b9, $66
	db $fd, $03, $05, $fb, $fd, $fb, $dd, $3b, $6d, $9b, $ed, $9b, $cd, $3b, $9d, $7b
	db $dd, $3b, $6d, $9b, $8d, $fb, $fd, $fb, $fd, $03, $01, $ff, $ff, $ff, $00, $00
	db $7f, $00, $c0, $3f, $9f, $7f, $b0, $70, $a2, $61, $a1, $63, $a3, $63, $aa, $67
	db $f8, $04, $0c, $f2, $f5, $fb, $0d, $0b, $05, $03, $85, $83, $05, $03, $e5, $83
	db $a5, $63, $a5, $6e, $af, $69, $a4, $66, $d0, $30, $7f, $80, $00, $7f, $3f, $3f
	db $a5, $f3, $65, $e3, $55, $d3, $25, $73, $0d, $03, $f9, $07, $03, $ff, $fe, $fe
	db $00, $00, $e0, $e0, $68, $98, $a4, $fc, $dc, $ec, $3e, $c6, $85, $ff, $fe, $ff
	db $fe, $01, $fe, $01, $fe, $01, $fe, $01, $fe, $01, $fe, $01, $fe, $01, $00, $ff
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $00, $ff
	db $00, $3c, $00, $3c, $38, $04, $38, $04, $38, $04, $38, $04, $38, $04, $38, $04
	db $00, $00, $20, $00, $00, $00, $04, $00, $62, $04, $10, $20, $02, $00, $01, $02
	db $00, $00, $0c, $00, $84, $08, $40, $80, $02, $00, $0c, $00, $02, $04, $00, $00
	db $20, $10, $00, $00, $40, $80, $20, $00, $00, $08, $00, $00, $00, $00, $00, $00
	db $00, $00, $10, $00, $2c, $10, $1a, $24, $2a, $14, $14, $18, $00, $00, $00, $00
	db $22, $10, $d0, $08, $ac, $12, $3a, $40, $eb, $44, $2f, $92, $5a, $34, $24, $00
	db $40, $04, $92, $00, $80, $00, $0a, $81, $02, $80, $11, $08, $80, $02, $00, $30
	db $10, $04, $06, $00, $80, $00, $20, $00, $04, $01, $01, $20, $40, $00, $04, $00
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $7e, $7e, $3c, $3c, $18, $18, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $18, $18, $18, $18, $00, $00, $18, $18, $18, $18, $00, $00
	db $38, $38, $6e, $56, $9d, $e3, $8e, $f1, $d7, $e8, $72, $fd, $a8, $df, $7f, $7f
	db $28, $00, $28, $00, $28, $00, $20, $00, $20, $00, $20, $00, $00, $00, $00, $00
	db $08, $20, $08, $20, $08, $20, $00, $20, $00, $20, $00, $20, $00, $00, $00, $00
	db $00, $28, $00, $28, $00, $28, $00, $20, $00, $20, $00, $20, $00, $00, $00, $00
	db $00, $00, $20, $00, $50, $60, $28, $30, $14, $18, $0a, $0c, $05, $06, $02, $03
	db $00, $00, $00, $00, $00, $00, $00, $00, $a0, $c0, $68, $70, $1a, $1c, $06, $07
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $81, $7e, $ff, $ff
	db $fc, $fb, $fc, $fb, $fc, $fb, $fc, $fb, $fc, $fb, $fc, $fb, $fc, $fb, $fc, $fb
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $ff, $00, $ff
	db $ff, $3f, $ff, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $38, $04, $38, $04, $38, $04, $38, $04, $38, $04, $38, $04, $38, $04, $38, $04
	db $ff, $00, $f0, $0f, $e0, $1f, $c7, $38, $8f, $70, $9f, $60, $9e, $61, $9f, $60
	db $ff, $00, $0f, $f0, $07, $f8, $e3, $1c, $f1, $0e, $f9, $06, $19, $e6, $19, $e6
	db $8e, $71, $c0, $3f, $e0, $1f, $ff, $00, $ff, $00, $c0, $3f, $80, $7f, $ff, $00
	db $19, $e6, $59, $a6, $f1, $0e, $f3, $0c, $c3, $3c, $07, $f8, $1f, $e0, $ff, $00
	db $03, $03, $07, $07, $1f, $1f, $7f, $7f, $ff, $ff, $ff, $ff, $ff, $fe, $ff, $fc
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $fe, $fc, $fc, $f0, $f0
	db $0f, $0f, $1f, $1f, $1f, $1f, $3f, $3f, $3f, $3f, $7f, $7f, $ff, $fe, $ff, $fc
	db $ff, $ff, $fe, $fe, $f0, $f0, $c0, $c0, $80, $80, $00, $00, $00, $00, $00, $00
	db $e0, $e0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $e0, $e0, $c0, $c0, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $fe, $fe, $fe, $fc, $fc, $f8, $f8
	db $f8, $f8, $f0, $f0, $e0, $e0, $e0, $e0, $c0, $c0, $c0, $c0, $c0, $c0, $80, $80
	db $80, $80, $80, $80, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0f, $0f, $ff, $ff, $ff, $ff
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1f, $1f
	db $03, $03, $03, $03, $03, $03, $03, $03, $07, $07, $07, $07, $07, $07, $07, $07
	db $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $ff, $3f, $fe, $7e, $fc, $fc, $f8, $f8, $f0, $f0, $e0, $e0, $c0, $c0, $80, $80
	db $98, $ff, $18, $ff, $18, $ff, $18, $ff, $18, $ff, $38, $ff, $70, $ff, $e0, $ff
	db $19, $ff, $19, $ff, $19, $ff, $19, $ff, $19, $ff, $19, $ff, $19, $ff, $19, $ff
	db $19, $ff, $19, $ff, $19, $ff, $39, $ff, $71, $ff, $e1, $ff, $c1, $ff, $81, $ff
	db $00, $ff, $00, $ff, $00, $ff, $ff, $ff, $ff, $ff, $00, $ff, $00, $ff, $ff, $ff
	db $fe, $f9, $fc, $f3, $f8, $e7, $f0, $cf, $e0, $9f, $c0, $3f, $81, $7f, $03, $ff
	db $07, $ff, $0e, $ff, $1c, $ff, $38, $ff, $70, $ff, $e0, $ff, $c0, $ff, $81, $ff
	db $03, $ff, $06, $fe, $0c, $fc, $18, $f8, $30, $f0, $60, $e0, $c0, $c0, $80, $80
	db $07, $ff, $0e, $ff, $1c, $ff, $f8, $ff, $f0, $ff, $00, $ff, $00, $ff, $ff, $ff
	db $01, $01, $03, $03, $07, $07, $0f, $0f, $1f, $1f, $3f, $3f, $7f, $7e, $ff, $fc
	db $00, $ff, $00, $ff, $00, $ff, $3f, $ff, $7f, $ff, $e0, $ff, $c0, $ff, $81, $ff
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $c0, $3f, $80, $7f, $ff, $00
	db $e7, $18, $e7, $18, $c7, $38, $cf, $30, $0f, $f0, $1f, $e0, $7f, $80, $ff, $00
	db $ff, $ff, $ff, $fc, $ff, $fc, $ff, $cc, $ff, $cc, $ff, $e1, $ff, $ff, $00, $7f
	db $ff, $ff, $ff, $81, $ff, $9f, $ff, $83, $ff, $9f, $ff, $81, $ff, $ff, $00, $ff
	db $fe, $fe, $fe, $03, $fe, $cf, $fe, $cf, $fe, $cf, $fe, $cf, $fe, $ff, $00, $ff
	db $fe, $01, $fe, $01, $fe, $01, $fe, $01, $fe, $01, $fe, $01, $fe, $01, $fe, $01
	db $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $00
	db $00, $ff, $fd, $02, $7f, $ce, $39, $ce, $39, $ce, $38, $cf, $18, $ff, $ff, $ff
	db $00, $ff, $be, $41, $ff, $49, $ff, $43, $fe, $49, $db, $ff, $00, $ff, $ff, $ff
	db $00, $fe, $f9, $07, $fd, $3f, $f1, $0f, $f9, $3f, $f9, $07, $7d, $ff, $ff, $ff
	db $00, $00, $14, $2c, $08, $18, $38, $04, $14, $2c, $14, $2c, $14, $2c, $18, $3c
	db $00, $00, $00, $00, $01, $00, $03, $00, $03, $00, $0b, $00, $0b, $00, $0a, $00
	db $00, $00, $00, $00, $01, $00, $03, $00, $03, $00, $03, $08, $03, $08, $02, $08
	db $00, $00, $00, $00, $00, $01, $00, $03, $00, $03, $00, $0b, $00, $0b, $00, $0a
	db $00, $00, $ff, $ff, $c4, $c4, $d6, $d6, $d6, $d6, $d6, $d6, $d6, $d6, $ff, $ff
	db $00, $00, $fe, $fe, $46, $46, $d6, $d6, $ce, $ce, $d6, $d6, $d6, $d6, $fe, $fe
	db $00, $00, $00, $00, $77, $00, $77, $00, $77, $00, $77, $00, $77, $00, $00, $00
	db $00, $00, $00, $00, $00, $77, $00, $77, $00, $77, $00, $77, $00, $77, $00, $00
	db $00, $00, $00, $00, $07, $70, $07, $70, $07, $70, $07, $70, $07, $70, $00, $00
	db $00, $00, $00, $00, $77, $70, $77, $70, $77, $70, $77, $70, $77, $70, $00, $00
	db $00, $00, $00, $00, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $00, $00
	db $00, $00, $ff, $ff, $c5, $c5, $ed, $ed, $ed, $ed, $ed, $ed, $ed, $ed, $ff, $ff
	db $00, $00, $ff, $ff, $04, $04, $55, $55, $54, $54, $55, $55, $54, $54, $ff, $ff
	db $00, $00, $e0, $e0, $70, $70, $f8, $f8, $7c, $7c, $f8, $f8, $70, $70, $e0, $e0
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00


;@ The track of each course: a word table, one list per course of (map row, map column, piece) ending with $FF (PlaceTrackPieces).
TrackPieceLists::
	db $81, $47, $1a, $49, $f5, $4a, $a0, $4c, $ae, $4e, $74, $50, $b2, $52, $d2, $54
	db $0f, $00, $00, $0e, $0a, $01, $0f, $0c, $00, $0e, $12, $01, $0e, $15, $01, $0c
	db $1a, $1b, $0c, $1e, $2f, $0f, $17, $00, $0f, $21, $00, $06, $1c, $39, $09, $20
	db $4d, $09, $21, $41, $05, $1c, $29, $05, $1f, $13, $0e, $29, $1d, $0f, $2b, $03
	db $0f, $2e, $04, $0f, $31, $00, $0e, $33, $1d, $0e, $35, $2d, $0e, $38, $01, $0c
	db $3e, $1b, $0c, $42, $2f, $0f, $3b, $00, $0f, $45, $00, $0e, $49, $01, $0e, $4c
	db $01, $0e, $4f, $01, $06, $40, $39, $08, $44, $4d, $08, $45, $41, $05, $40, $29
	db $05, $43, $13, $0f, $51, $00, $0e, $52, $01, $0f, $59, $10, $0f, $5a, $03, $0f
	db $5c, $04, $0f, $5f, $1c, $0f, $63, $10, $0f, $64, $03, $0f, $67, $04, $0c, $6c
	db $1b, $0f, $6a, $00, $0f, $70, $03, $0f, $73, $04, $0f, $76, $00, $0c, $73, $20
	db $0e, $79, $01, $0e, $7c, $01, $0f, $7c, $00, $0e, $85, $01, $0e, $88, $01, $0f
	db $81, $00, $0c, $8c, $1b, $0f, $8b, $00, $0c, $90, $3e, $0b, $90, $21, $0b, $92
	db $1c, $0c, $97, $26, $0c, $99, $25, $0f, $95, $03, $0f, $98, $04, $0a, $a4, $1b
	db $0a, $a8, $2f, $0c, $aa, $2f, $0f, $a5, $00, $0c, $a2, $1b, $0f, $9b, $00, $04
	db $a6, $39, $07, $aa, $4d, $07, $ab, $41, $03, $a6, $29, $03, $a9, $13, $0f, $af
	db $00, $0e, $b6, $01, $0e, $b9, $01, $0f, $bb, $1c, $0e, $bd, $1d, $0f, $bf, $03
	db $0f, $c1, $34, $0e, $c5, $23, $0f, $c7, $34, $0e, $c8, $1c, $0e, $cb, $10, $0f
	db $cd, $04, $0f, $d0, $00, $0d, $d3, $02, $0d, $d6, $0f, $0d, $da, $02, $0d, $dd
	db $0f, $0c, $e1, $1b, $0f, $e0, $1c, $0a, $e3, $1b, $0a, $e7, $25, $0c, $e9, $4d
	db $0b, $ec, $21, $0b, $ef, $10, $0c, $ec, $3e, $0f, $e4, $03, $0f, $e7, $3a, $07
	db $d4, $39, $0a, $d8, $4d, $0a, $d9, $41, $06, $d4, $29, $06, $d7, $13, $07, $db
	db $39, $0a, $df, $4d, $0a, $e0, $41, $06, $db, $29, $06, $de, $13, $0f, $f1, $04
	db $0d, $f4, $02, $0d, $f7, $3e, $0c, $f7, $3c, $0c, $f9, $17, $0c, $fb, $3d, $0d
	db $fb, $38, $0d, $fd, $0f, $0f, $f7, $00, $0f, $0e, $57, $0d, $18, $4f, $0f, $23
	db $58, $0c, $2c, $51, $0c, $31, $50, $0d, $3b, $4f, $0c, $47, $50, $0f, $60, $57
	db $0c, $77, $50, $0f, $7f, $58, $09, $93, $53, $0f, $9c, $56, $0d, $9f, $4f, $0e
	db $c8, $59, $0d, $d0, $54, $08, $ed, $50, $ff, $0f, $00, $00, $0f, $0a, $00, $0e
	db $0a, $01, $0e, $0d, $01, $0d, $18, $26, $0f, $14, $00, $0f, $1e, $00, $06, $2a
	db $39, $05, $2a, $29, $05, $2d, $13, $07, $2f, $32, $0c, $28, $1b, $0c, $2c, $2f
	db $0f, $28, $00, $0d, $32, $02, $0f, $32, $00, $0d, $35, $3e, $0c, $35, $21, $0c
	db $37, $1c, $0c, $39, $22, $0d, $3b, $2a, $0d, $3e, $2c, $0f, $3b, $00, $0c, $3f
	db $1a, $0d, $40, $1c, $0d, $41, $03, $0d, $44, $22, $0d, $43, $04, $0f, $45, $1c
	db $0e, $45, $38, $0e, $47, $2d, $0f, $49, $00, $08, $52, $39, $07, $52, $29, $07
	db $55, $13, $09, $57, $32, $0e, $52, $1d, $0e, $54, $2d, $0f, $56, $00, $0e, $5a
	db $01, $0e, $5d, $01, $0f, $60, $00, $0e, $68, $01, $0f, $6a, $03, $0f, $6c, $0a
	db $0f, $6f, $04, $09, $72, $25, $0f, $72, $1c, $0f, $73, $10, $0f, $74, $03, $0f
	db $76, $3a, $0a, $63, $42, $0a, $68, $1d, $08, $6a, $13, $08, $6a, $19, $07, $6c
	db $19, $08, $6c, $21, $0c, $6c, $41, $08, $6f, $22, $09, $70, $38, $0a, $71, $42
	db $0b, $76, $00, $09, $78, $26, $0b, $7d, $22, $0c, $7e, $38, $0c, $80, $25, $0f
	db $79, $04, $0f, $80, $04, $0f, $82, $04, $0f, $85, $00, $0e, $89, $01, $0f, $8e
	db $10, $0f, $8f, $03, $0f, $96, $04, $0f, $92, $0a, $0f, $99, $1c, $0e, $9b, $01
	db $0f, $9d, $03, $0f, $a0, $0a, $0f, $a4, $04, $0a, $83, $42, $0a, $88, $1d, $09
	db $8c, $15, $0a, $8c, $32, $07, $8e, $08, $06, $91, $21, $06, $92, $1c, $06, $95
	db $10, $06, $98, $1c, $07, $9f, $1c, $09, $98, $11, $06, $9b, $10, $09, $9b, $13
	db $07, $a2, $10, $0a, $a6, $2f, $0f, $a7, $00, $0f, $b0, $45, $0f, $b8, $45, $0f
	db $b1, $00, $0f, $bb, $00, $0f, $c2, $00, $0d, $be, $26, $0e, $c9, $1e, $0e, $cd
	db $09, $0f, $c9, $00, $0c, $cd, $1e, $0c, $d2, $38, $0c, $d4, $2f, $0c, $d0, $09
	db $0f, $d3, $1c, $0f, $d6, $00, $05, $d6, $11, $09, $d6, $12, $0b, $da, $18, $0a
	db $dd, $15, $0a, $de, $22, $0b, $dd, $32, $0d, $dc, $02, $0d, $dd, $19, $0d, $dd
	db $41, $0f, $e0, $00, $0b, $df, $0e, $0b, $e1, $0f, $0d, $e3, $00, $07, $e4, $12
	db $09, $e8, $18, $08, $eb, $15, $08, $ec, $22, $09, $eb, $32, $0b, $e9, $08, $09
	db $ed, $0e, $09, $ef, $2f, $0f, $ea, $00, $0d, $f4, $02, $0f, $f4, $00, $0c, $f7
	db $3c, $0d, $f7, $3e, $0c, $f9, $17, $0c, $fb, $3d, $0d, $fb, $38, $0d, $fd, $0f
	db $0f, $04, $59, $0c, $10, $50, $0f, $14, $56, $0f, $23, $58, $0d, $26, $4f, $09
	db $36, $50, $0f, $4a, $57, $0d, $4f, $4f, $0f, $57, $58, $0d, $65, $4f, $08, $6d
	db $59, $0d, $86, $4f, $06, $92, $58, $0f, $a9, $57, $0c, $bb, $50, $0f, $c3, $59
	db $0d, $e4, $59, $ff, $0f, $00, $00, $0f, $0c, $00, $0d, $0a, $02, $0d, $0d, $3e
	db $0c, $0d, $21, $0c, $10, $22, $0d, $11, $0e, $0e, $12, $42, $0f, $17, $00, $09
	db $16, $2a, $0a, $19, $3b, $0e, $1a, $01, $0a, $19, $3b, $08, $1d, $15, $09, $1d
	db $32, $08, $20, $00, $08, $26, $00, $07, $23, $1d, $07, $25, $2d, $0f, $1e, $03
	db $0f, $21, $04, $0f, $24, $1c, $0f, $25, $10, $0f, $26, $03, $0f, $29, $3a, $08
	db $2f, $10, $0f, $31, $0a, $0f, $33, $04, $0a, $32, $2f, $0f, $36, $00, $0d, $36
	db $02, $0d, $39, $0e, $0d, $37, $1e, $0d, $3b, $0f, $0f, $3e, $00, $0e, $41, $01
	db $0d, $44, $02, $0d, $47, $0e, $0d, $45, $1e, $0d, $49, $0f, $0f, $48, $00, $0f
	db $50, $1c, $0f, $53, $10, $0f, $54, $03, $0f, $55, $0a, $0e, $58, $33, $0f, $5b
	db $0a, $0f, $5d, $2e, $0e, $60, $33, $0f, $63, $04, $0f, $66, $00, $0f, $69, $45
	db $0f, $6e, $45, $0f, $70, $00, $0f, $72, $45, $0f, $76, $45, $0f, $7a, $1c, $0c
	db $7c, $1b, $0a, $7e, $1b, $0f, $7c, $1c, $0f, $80, $03, $0f, $83, $3a, $0e, $86
	db $21, $0e, $89, $10, $0f, $8b, $2e, $0e, $8d, $33, $0e, $91, $35, $0e, $91, $19
	db $0f, $90, $0a, $0f, $92, $2e, $0e, $97, $35, $0f, $96, $34, $0e, $97, $19, $0f
	db $95, $0a, $0d, $9d, $36, $0f, $9c, $34, $0d, $a3, $35, $0f, $a2, $34, $0d, $a9
	db $35, $0c, $a9, $36, $0f, $ac, $04, $0f, $a8, $34, $0c, $af, $1b, $0c, $b3, $2f
	db $0f, $af, $00, $0f, $b9, $00, $0e, $bc, $01, $0f, $c3, $00, $0f, $c5, $45, $01
	db $c7, $12, $04, $ca, $17, $03, $cc, $23, $05, $c8, $29, $08, $c8, $2a, $0f, $c9
	db $45, $0f, $ca, $03, $05, $cb, $48, $09, $cb, $18, $04, $ce, $32, $09, $ce, $32
	db $0b, $cc, $08, $0d, $cb, $15, $03, $ce, $15, $0f, $cd, $3a, $04, $d5, $2d, $03
	db $cf, $1c, $03, $d2, $10, $05, $d8, $10, $05, $d5, $1c, $07, $de, $2f, $0f, $d7
	db $3a, $0c, $e3, $38, $0c, $e5, $25, $0c, $e1, $09, $0f, $e4, $04, $0f, $e0, $0a
	db $0f, $e7, $1c, $0d, $ea, $08, $0c, $ed, $0d, $0d, $ef, $0e, $0f, $ee, $1c, $0e
	db $f2, $2d, $0d, $f4, $02, $0f, $f4, $00, $0c, $f7, $3c, $0d, $f7, $3e, $0c, $f9
	db $17, $0c, $fb, $3d, $0d, $fb, $38, $0d, $fd, $0f, $0f, $05, $56, $0d, $17, $4f
	db $05, $21, $50, $08, $28, $57, $0c, $3e, $50, $0c, $4c, $50, $0c, $7a, $50, $0f
	db $b7, $59, $0f, $c2, $56, $0c, $c6, $55, $03, $cf, $57, $0c, $e8, $52, $ff, $0f
	db $00, $00, $0f, $0a, $1c, $0d, $0e, $02, $0f, $0c, $00, $0d, $11, $03, $0e, $11
	db $09, $0d, $14, $04, $0e, $15, $09, $0e, $16, $09, $0d, $1a, $0f, $0c, $19, $1a
	db $0d, $17, $22, $0d, $18, $22, $0f, $16, $00, $0d, $1f, $08, $0c, $21, $19, $0b
	db $25, $30, $0b, $27, $09, $0f, $23, $03, $0f, $24, $0a, $0f, $27, $0a, $0f, $28
	db $0a, $0b, $2a, $0b, $0f, $2b, $04, $0f, $2c, $04, $0d, $30, $02, $0c, $33, $0c
	db $0f, $2f, $1c, $0b, $34, $0d, $0c, $36, $0e, $0d, $39, $0f, $0e, $3d, $01, $0e
	db $40, $01, $0e, $45, $01, $0e, $48, $01, $0f, $33, $00, $0f, $3f, $00, $0f, $49
	db $00, $0f, $50, $00, $0f, $52, $45, $0f, $56, $45, $0d, $59, $02, $0c, $5c, $0c
	db $07, $5d, $32, $09, $5c, $19, $0a, $5d, $41, $08, $54, $0f, $08, $57, $08, $07
	db $59, $19, $06, $5d, $15, $06, $60, $00, $05, $64, $01, $06, $69, $22, $0f, $5b
	db $00, $0f, $64, $03, $0f, $67, $04, $07, $6a, $0e, $0d, $6a, $02, $0d, $6d, $3e
	db $09, $6d, $1b, $0f, $6d, $00, $0f, $77, $00, $08, $71, $0c, $07, $72, $0d, $08
	db $74, $38, $08, $76, $2d, $09, $78, $1c, $08, $7c, $1d, $08, $81, $20, $0f, $7e
	db $03, $0f, $81, $3a, $0a, $85, $4d, $0b, $8d, $1b, $09, $8b, $30, $08, $8d, $23
	db $0f, $91, $3a, $0c, $91, $0b, $0b, $91, $25, $0f, $8b, $3a, $09, $93, $1e, $09
	db $95, $09, $0a, $99, $08, $09, $9c, $21, $09, $9d, $00, $0f, $9b, $3a, $08, $a0
	db $01, $09, $a5, $22, $0a, $a6, $38, $0c, $a9, $0b, $0a, $a8, $20, $0f, $a5, $3a
	db $05, $ae, $11, $07, $ae, $39, $05, $b2, $13, $09, $b3, $4d, $09, $b4, $41, $0f
	db $af, $04, $0f, $b2, $00, $0d, $b6, $02, $0c, $b9, $0c, $08, $ba, $1b, $02, $bc
	db $39, $00, $bc, $11, $00, $c0, $13, $04, $c2, $41, $08, $be, $2f, $0c, $c0, $0e
	db $0d, $c3, $0f, $0f, $b9, $00, $0f, $c6, $00, $06, $c6, $11, $0a, $c6, $12, $0c
	db $ca, $18, $0b, $cd, $32, $0d, $cb, $08, $0a, $cd, $15, $0a, $cf, $22, $0b, $d1
	db $2a, $08, $d1, $09, $0d, $d4, $17, $0a, $d5, $14, $08, $d7, $32, $07, $d7, $15
	db $0f, $d0, $00, $0f, $da, $00, $07, $da, $22, $08, $db, $0e, $09, $dc, $0e, $0a
	db $df, $27, $0b, $e0, $38, $0b, $e0, $17, $0b, $e2, $19, $0b, $e2, $2f, $0a, $e1
	db $23, $0d, $e4, $0f, $05, $e1, $39, $03, $e1, $11, $03, $e5, $13, $07, $e8, $43
	db $08, $e7, $41, $0f, $e3, $00, $0e, $e8, $01, $0d, $eb, $21, $0f, $ed, $00, $0d
	db $f4, $02, $0d, $f7, $3e, $0c, $f7, $3c, $0c, $f9, $17, $0c, $fb, $3d, $0d, $fb
	db $38, $0d, $fd, $0f, $0f, $f7, $1c, $0f, $fb, $1c, $0f, $04, $56, $0b, $17, $53
	db $0c, $1d, $52, $0a, $28, $5b, $0d, $4a, $4f, $08, $35, $50, $0c, $4d, $52, $0f
	db $55, $56, $03, $61, $50, $0c, $67, $51, $09, $78, $59, $08, $95, $5c, $09, $9d
	db $59, $07, $a2, $53, $07, $a5, $4f, $0d, $b4, $4f, $08, $ce, $4f, $05, $d9, $4f
	db $0f, $c8, $56, $0f, $d9, $58, $0f, $ec, $57, $0f, $f1, $58, $ff, $0f, $00, $00
	db $0e, $0a, $1d, $0e, $0c, $2d, $0d, $11, $30, $0d, $12, $09, $0f, $0e, $03, $0f
	db $11, $0a, $0f, $13, $04, $0c, $16, $1b, $0f, $16, $00, $0c, $14, $1f, $08, $1a
	db $1b, $08, $1e, $3e, $0c, $1a, $3e, $07, $1e, $0d, $0f, $1b, $03, $0f, $1e, $3a
	db $0b, $25, $4d, $0b, $26, $1e, $0c, $2d, $1d, $0c, $2f, $25, $0d, $2e, $22, $0f
	db $28, $3a, $0f, $2e, $04, $0f, $31, $00, $0e, $36, $01, $0e, $39, $01, $0f, $3b
	db $00, $0e, $3c, $1d, $0e, $3e, $2d, $0e, $40, $01, $0e, $46, $3f, $0f, $45, $00
	db $0e, $48, $09, $0f, $4a, $03, $0f, $4d, $3a, $0e, $4e, $30, $0c, $52, $26, $0e
	db $50, $09, $0f, $52, $04, $0d, $55, $02, $0c, $58, $0c, $0f, $58, $00, $08, $59
	db $1b, $08, $5d, $3e, $07, $5d, $21, $07, $5f, $22, $08, $60, $0e, $09, $63, $25
	db $0f, $62, $03, $0f, $65, $3a, $0b, $66, $26, $0b, $67, $0c, $0a, $68, $21, $0d
	db $67, $19, $0a, $6a, $22, $0b, $6b, $38, $0b, $6d, $25, $0d, $6f, $02, $0c, $72
	db $0d, $0e, $75, $09, $0d, $72, $3e, $0f, $72, $00, $0c, $7c, $38, $0c, $7a, $1e
	db $0e, $79, $09, $0c, $7e, $2f, $0f, $7c, $00, $0d, $82, $08, $0c, $85, $21, $0c
	db $88, $1c, $0b, $8a, $1d, $0f, $86, $00, $0f, $8c, $03, $0b, $90, $25, $0b, $93
	db $26, $0d, $90, $09, $0d, $91, $09, $0f, $8f, $3a, $0f, $99, $0a, $0f, $9c, $04
	db $0f, $9f, $00, $0e, $a2, $01, $0e, $a5, $01, $0b, $b0, $32, $0d, $ae, $08, $06
	db $b5, $32, $08, $b3, $08, $0f, $a9, $00, $0f, $ab, $45, $05, $a8, $11, $09, $a8
	db $12, $0b, $ac, $3b, $0a, $b0, $15, $05, $b5, $15, $05, $b6, $1c, $04, $b9, $01
	db $03, $bd, $25, $0a, $b0, $15, $00, $ae, $11, $06, $b0, $17, $03, $ae, $12, $0f
	db $b3, $03, $0f, $b6, $04, $0c, $b9, $1b, $0b, $bd, $0c, $07, $be, $1b, $05, $c0
	db $1b, $04, $c4, $0c, $03, $c5, $21, $0f, $b9, $00, $0f, $cd, $00, $0f, $c3, $00
	db $03, $c8, $22, $04, $c9, $0e, $06, $cc, $0b, $05, $cc, $25, $00, $d4, $13, $04
	db $d5, $4d, $04, $d6, $41, $0a, $d4, $0b, $07, $d2, $2f, $04, $dc, $13, $08, $de
	db $41, $0b, $da, $2f, $0f, $db, $00, $0d, $dc, $0f, $0f, $d7, $00, $0d, $e3, $02
	db $0f, $e6, $03, $0b, $ee, $4d, $0f, $e9, $3a, $0e, $ec, $09, $0f, $f1, $04, $0d
	db $f4, $02, $0f, $f4, $00, $0c, $f7, $3c, $0d, $f7, $3e, $0c, $f9, $17, $0c, $fb
	db $3d, $0d, $fb, $38, $0d, $fd, $0f, $0f, $00, $57, $0c, $32, $50, $0c, $43, $52
	db $0d, $49, $5c, $0a, $69, $58, $09, $87, $50, $0d, $a7, $54, $00, $c6, $55, $0f
	db $e0, $59, $ff, $0f, $00, $00, $0c, $0c, $17, $09, $0a, $12, $0b, $0e, $23, $0b
	db $11, $32, $0d, $0f, $08, $0a, $11, $15, $07, $15, $1b, $0a, $13, $1c, $07, $19
	db $3e, $06, $19, $21, $06, $1c, $10, $0f, $14, $1c, $0f, $18, $03, $0f, $1b, $3a
	db $0f, $21, $3a, $0f, $0a, $00, $05, $21, $1c, $05, $24, $10, $05, $27, $2f, $09
	db $29, $09, $05, $2e, $11, $05, $2e, $19, $07, $2e, $19, $0b, $2c, $12, $0a, $2c
	db $62, $0f, $2b, $0a, $0e, $2f, $17, $0b, $30, $21, $0f, $2f, $04, $09, $32, $08
	db $05, $32, $13, $0f, $32, $1c, $0f, $38, $03, $0e, $36, $1d, $0f, $3b, $3a, $0d
	db $3d, $21, $0c, $3e, $1d, $0c, $42, $42, $0c, $42, $19, $0f, $45, $04, $0f, $47
	db $04, $0c, $4a, $1b, $08, $4e, $1b, $0b, $47, $02, $0c, $4e, $3e, $08, $54, $1b
	db $08, $5c, $1b, $0f, $4d, $03, $0f, $50, $3a, $0f, $5a, $3a, $0e, $64, $21, $0e
	db $62, $21, $0e, $66, $10, $0f, $64, $3a, $0f, $6e, $3a, $0f, $68, $34, $0d, $69
	db $36, $0e, $6f, $33, $0d, $6d, $35, $0d, $6d, $19, $0f, $4a, $1c, $0d, $73, $30
	db $0f, $77, $04, $04, $75, $11, $08, $75, $62, $09, $75, $62, $0a, $75, $28, $0c
	db $76, $1f, $0d, $74, $09, $04, $79, $13, $08, $79, $14, $0a, $79, $19, $0f, $7a
	db $00, $0f, $7e, $45, $0f, $82, $45, $0f, $80, $1c, $04, $82, $11, $08, $82, $12
	db $0d, $84, $02, $0d, $87, $0f, $0f, $8a, $1c, $04, $86, $48, $04, $88, $13, $08
	db $8b, $43, $09, $8a, $41, $0d, $8e, $02, $06, $90, $11, $06, $94, $13, $0a, $90
	db $2a, $0b, $90, $19, $08, $96, $32, $0b, $91, $19, $0c, $97, $1b, $0f, $91, $00
	db $0a, $9c, $21, $0a, $9f, $1c, $0a, $9f, $45, $0b, $9b, $0c, $0f, $9b, $00, $0a
	db $a0, $1c, $0f, $a2, $03, $0f, $a5, $3a, $0f, $ae, $0a, $0f, $b1, $04, $02, $a4
	db $11, $02, $a7, $13, $04, $a4, $39, $09, $a4, $01, $05, $a8, $4d, $05, $a9, $41
	db $0b, $a7, $1c, $0a, $a9, $1d, $09, $ab, $0c, $07, $ac, $26, $0a, $b3, $26, $0c
	db $b5, $1b, $0f, $b4, $00, $0b, $b9, $0c, $0a, $ba, $21, $0a, $bb, $1c, $0a, $be
	db $10, $0b, $bd, $0e, $0c, $c0, $2f, $0f, $be, $00, $02, $bd, $11, $04, $bd, $39
	db $02, $c1, $13, $04, $c3, $32, $0f, $c7, $45, $08, $c1, $4a, $0e, $cc, $4b, $0f
	db $c8, $00, $0f, $d2, $03, $0f, $d5, $0a, $0f, $d8, $0a, $0f, $db, $04, $0d, $de
	db $02, $09, $e1, $1b, $0d, $e1, $3e, $05, $e5, $1b, $09, $e5, $3e, $00, $e9, $29
	db $00, $ec, $48, $00, $ed, $2b, $0f, $eb, $00, $06, $eb, $17, $03, $ec, $14, $07
	db $e8, $12, $06, $e8, $62, $07, $ec, $11, $07, $ec, $19, $09, $ec, $19, $09, $eb
	db $19, $0c, $ee, $2d, $07, $f0, $13, $0b, $f0, $08, $0f, $e1, $00, $0f, $eb, $00
	db $04, $cb, $11, $08, $cb, $12, $0a, $cf, $24, $09, $d1, $15, $09, $d3, $22, $0a
	db $d1, $32, $0a, $d4, $38, $0a, $d6, $20, $0b, $d9, $4d, $0c, $d1, $19, $0c, $cf
	db $08, $0d, $f4, $02, $0f, $f4, $00, $0c, $f7, $3c, $0d, $f7, $3e, $0c, $f9, $17
	db $0c, $fb, $3d, $0d, $fb, $38, $0d, $fd, $0f, $0f, $03, $56, $0a, $12, $57, $0f
	db $33, $59, $0c, $41, $51, $0e, $63, $56, $0d, $7f, $54, $0f, $8b, $57, $07, $9d
	db $50, $08, $a1, $4f, $08, $bb, $4f, $0d, $c9, $4f, $07, $d2, $53, $0f, $f1, $57
	db $ff, $0f, $00, $00, $0e, $0a, $01, $0f, $0c, $00, $0e, $0d, $01, $0e, $10, $1d
	db $0e, $12, $2d, $0e, $14, $1d, $0e, $16, $2d, $0f, $18, $00, $0d, $1a, $02, $0d
	db $1d, $0f, $06, $18, $11, $06, $1c, $48, $09, $20, $43, $06, $1d, $13, $0a, $18
	db $2a, $0f, $22, $1c, $0f, $22, $45, $0f, $25, $45, $0f, $26, $00, $0d, $2b, $02
	db $0d, $2e, $0f, $0c, $2d, $19, $0d, $2d, $4c, $0d, $31, $02, $0d, $34, $0f, $0c
	db $33, $19, $0d, $33, $4c, $0d, $3b, $02, $0f, $37, $00, $06, $39, $11, $06, $3d
	db $48, $09, $41, $43, $06, $3e, $13, $0f, $41, $00, $0f, $42, $45, $0e, $47, $2d
	db $0f, $46, $45, $0f, $4a, $45, $0e, $4e, $2d, $0f, $4d, $45, $0f, $4b, $00, $0f
	db $55, $00, $0f, $5f, $00, $0f, $53, $45, $0f, $56, $45, $0e, $57, $2d, $0f, $5b
	db $45, $0f, $61, $45, $0f, $5e, $45, $0f, $66, $45, $0d, $67, $02, $08, $6b, $32
	db $0f, $6a, $00, $0f, $70, $45, $0d, $74, $30, $0f, $71, $03, $0f, $74, $3a, $0d
	db $75, $09, $0b, $77, $26, $0f, $7e, $3a, $0f, $88, $3a, $0f, $92, $04, $0f, $95
	db $1c, $0b, $7d, $20, $0e, $7e, $09, $0e, $7f, $09, $0d, $82, $23, $0e, $87, $09
	db $0d, $88, $23, $0d, $8b, $1c, $0d, $8b, $19, $0d, $89, $19, $0d, $8e, $10, $0d
	db $91, $09, $0d, $91, $19, $0c, $94, $23, $0f, $96, $45, $0d, $99, $02, $0d, $9c
	db $03, $0d, $9e, $0a, $0e, $9c, $09, $0f, $9c, $00, $0d, $a2, $04, $0e, $a0, $09
	db $0e, $a3, $09, $0b, $a5, $02, $0b, $a8, $03, $0b, $a9, $0a, $0d, $a7, $1a, $0c
	db $a7, $3e, $0b, $ac, $04, $0f, $a6, $00, $0c, $a8, $09, $0c, $ac, $09, $0c, $ae
	db $09, $0b, $af, $1c, $0b, $b0, $22, $0b, $b2, $25, $0a, $b2, $1a, $0d, $b2, $0e
	db $0e, $b5, $2d, $0f, $b0, $00, $0f, $b9, $45, $0f, $bc, $45, $0f, $ba, $1c, $0b
	db $bb, $17, $08, $b9, $12, $0a, $bd, $23, $0b, $c0, $32, $0d, $be, $08, $04, $bb
	db $63, $04, $c0, $32, $06, $c0, $32, $06, $bf, $19, $06, $c1, $43, $02, $b7, $12
	db $03, $c0, $15, $03, $c2, $1c, $03, $c4, $22, $0f, $bd, $00, $0f, $c7, $00, $04
	db $c5, $0e, $05, $c8, $20, $07, $c9, $17, $06, $c9, $27, $06, $cb, $23, $07, $cb
	db $3d, $08, $cb, $38, $07, $cc, $2f, $09, $cc, $0e, $0b, $d0, $17, $0a, $cf, $27
	db $0a, $cd, $38, $0b, $d3, $3d, $0c, $d3, $0e, $0d, $d6, $0f, $0f, $d1, $00, $00
	db $cc, $11, $00, $cf, $13, $04, $cf, $14, $06, $cf, $19, $06, $d5, $17, $03, $d3
	db $12, $06, $dc, $32, $0b, $d9, $1f, $08, $da, $14, $05, $dc, $15, $05, $dd, $22
	db $06, $de, $0e, $07, $e1, $2f, $0a, $e2, $0e, $0b, $e5, $25, $0f, $db, $03, $0f
	db $de, $0a, $0f, $e2, $04, $0f, $e5, $1c, $0f, $e7, $1c, $0f, $eb, $10, $0f, $ec
	db $03, $0f, $ee, $0a, $0f, $f1, $04, $0d, $f4, $02, $0d, $f7, $3e, $0c, $f7, $3c
	db $0c, $f9, $17, $0c, $fb, $3d, $0d, $fb, $38, $0d, $fd, $0f, $0f, $f4, $00, $0f
	db $02, $59, $0c, $08, $50, $0d, $18, $4f, $0c, $29, $50, $0d, $37, $4f, $0d, $63
	db $4f, $0c, $97, $50, $0a, $a2, $51, $0c, $b7, $55, $00, $c3, $55, $0f, $e7, $58
	db $ff, $0f, $00, $00, $0e, $0a, $1d, $0e, $10, $09, $0d, $13, $23, $0f, $0c, $03
	db $0f, $0f, $3a, $0f, $19, $3a, $0f, $21, $04, $0d, $16, $1c, $0d, $16, $19, $0d
	db $19, $10, $0c, $1c, $36, $0c, $1c, $19, $0c, $24, $1b, $0f, $24, $00, $0c, $28
	db $3e, $09, $28, $4d, $08, $2b, $0d, $09, $2b, $3e, $09, $2d, $38, $09, $2f, $25
	db $0c, $4e, $19, $0c, $50, $19, $0f, $2e, $03, $0f, $31, $3a, $0f, $3b, $3a, $0b
	db $32, $26, $0f, $39, $04, $0f, $3c, $00, $0f, $3d, $45, $05, $41, $11, $0f, $41
	db $45, $0f, $46, $45, $0f, $47, $03, $0f, $4a, $3a, $09, $41, $12, $0b, $45, $18
	db $0b, $49, $32, $0d, $49, $19, $0a, $49, $15, $00, $4b, $11, $0b, $4f, $26, $0f
	db $4d, $03, $06, $4e, $17, $03, $4b, $12, $0f, $50, $04, $0b, $51, $3e, $0f, $53
	db $1c, $0f, $56, $45, $0f, $57, $03, $0f, $5a, $0a, $0f, $5e, $04, $0f, $61, $1c
	db $0f, $63, $45, $06, $53, $32, $08, $51, $08, $0a, $51, $21, $05, $53, $15, $07
	db $57, $2f, $0b, $59, $38, $0b, $5b, $27, $0c, $5c, $17, $0c, $5e, $17, $09, $60
	db $14, $08, $5c, $26, $07, $62, $32, $06, $62, $15, $05, $65, $01, $04, $6c, $0e
	db $04, $6a, $1e, $05, $6f, $20, $0c, $69, $1e, $0c, $6c, $09, $0f, $64, $03, $0f
	db $67, $0a, $0f, $6a, $04, $0f, $6d, $45, $0f, $6e, $1c, $0f, $70, $45, $0f, $72
	db $03, $0f, $73, $04, $0f, $76, $45, $0f, $77, $03, $0f, $78, $04, $0f, $7b, $45
	db $0f, $7c, $1c, $0f, $7e, $45, $0f, $80, $03, $0f, $81, $04, $0f, $84, $45, $0f
	db $85, $03, $0f, $88, $3a, $0f, $8f, $04, $0f, $92, $1c, $0f, $92, $45, $0f, $95
	db $45, $07, $73, $4d, $07, $7a, $26, $0f, $96, $00, $07, $81, $20, $04, $95, $2f
	db $09, $81, $42, $07, $88, $26, $06, $8d, $32, $08, $8b, $08, $05, $8d, $15, $05
	db $90, $22, $06, $91, $0e, $07, $94, $2f, $09, $99, $4d, $0a, $81, $00, $0f, $a0
	db $00, $0f, $aa, $00, $0f, $a2, $45, $0f, $a7, $45, $0f, $ab, $45, $0f, $ae, $45
	db $0f, $b1, $45, $0d, $b4, $02, $0d, $b7, $0f, $0c, $b6, $19, $0d, $b6, $4c, $0d
	db $ba, $02, $0d, $bd, $0f, $0c, $bc, $19, $0d, $bc, $4c, $0d, $c0, $02, $0d, $c3
	db $0f, $0c, $c2, $19, $0d, $c2, $4c, $0d, $c6, $02, $0a, $b9, $26, $0a, $bb, $3e
	db $09, $bb, $21, $09, $bc, $1c, $09, $c0, $10, $0d, $c9, $0f, $0c, $c8, $19, $0d
	db $c8, $4c, $0f, $cc, $00, $09, $de, $2f, $0a, $cf, $12, $0c, $d3, $3b, $0b, $d6
	db $32, $0d, $d4, $08, $0a, $d6, $15, $0a, $d9, $22, $0b, $da, $0e, $0c, $dd, $2f
	db $0f, $d8, $00, $0f, $e2, $1c, $0e, $e4, $01, $0f, $e6, $03, $0d, $ea, $25, $0f
	db $e9, $3a, $0f, $f1, $04, $0d, $f4, $02, $0d, $f7, $3e, $0c, $f7, $3c, $0c, $f9
	db $17, $0c, $fb, $3d, $0d, $fb, $38, $0d, $fd, $0f, $0f, $f4, $00, $0f, $04, $56
	db $0d, $10, $5b, $0d, $42, $4f, $0b, $6c, $5b, $05, $8f, $58, $0f, $a8, $57, $06
	db $be, $50, $0d, $cd, $4f, $0a, $d8, $59, $0c, $f1, $51, $ff


;@ The track pieces: a word table of pieces, each its height, width and height x width metatiles; a metatile $FF clears the cell (StampMetatile).
TrackPieces::
	db $a5, $57, $b1, $57, $b7, $57, $c2, $57, $c7, $57, $cc, $57, $cc, $57, $cc, $57
	db $cc, $57, $da, $57, $e0, $57, $e6, $57, $fa, $57, $05, $58, $0b, $58, $16, $58
	db $21, $58, $24, $58, $36, $58, $48, $58, $5a, $58, $6c, $58, $71, $58, $71, $58
	db $76, $58, $7c, $58, $82, $58, $88, $58, $9a, $58, $a0, $58, $a6, $58, $b0, $58
	db $b4, $58, $bf, $58, $c4, $58, $c9, $58, $cc, $58, $d0, $58, $d6, $58, $dc, $58
	db $e0, $58, $e4, $58, $ef, $58, $fa, $58, $05, $59, $10, $59, $16, $59, $1b, $59
	db $2d, $59, $32, $59, $32, $59, $3c, $59, $44, $59, $4c, $59, $56, $59, $60, $59
	db $60, $59, $66, $59, $70, $59, $7c, $59, $82, $59, $86, $59, $8a, $59, $90, $59
	db $98, $59, $98, $59, $9e, $59, $aa, $59, $ae, $59, $ae, $59, $b1, $59, $b1, $59
	db $b1, $59, $b5, $59, $b5, $59, $bf, $59, $cb, $59, $cf, $59, $da, $59, $da, $59
	db $e2, $59, $ec, $59, $f6, $59, $00, $5a, $08, $5a, $13, $5a, $1d, $5a, $1d, $5a
	db $1d, $5a, $1d, $5a, $22, $5a, $22, $5a, $22, $5a, $27, $5a, $27, $5a, $27, $5a
	db $27, $5a, $27, $5a, $27, $5a, $2a, $5a, $01, $0a, $09, $09, $09, $09, $09, $09
	db $09, $09, $09, $09, $02, $02, $0a, $0b, $0c, $0d, $03, $03, $07, $07, $0e, $07
	db $0e, $0f, $10, $11, $12, $01, $03, $13, $14, $14, $01, $03, $14, $14, $15, $03
	db $04, $07, $07, $50, $19, $07, $07, $51, $52, $56, $55, $11, $12, $01, $04, $4c
	db $4c, $4c, $4c, $01, $04, $14, $14, $14, $14, $03, $06, $57, $43, $07, $07, $07
	db $07, $41, $42, $59, $5a, $5b, $5c, $07, $41, $58, $16, $16, $7d, $03, $03, $0e
	db $0f, $40, $0f, $40, $07, $40, $07, $07, $01, $04, $3e, $09, $09, $3f, $03, $03
	db $41, $42, $43, $07, $41, $42, $07, $07, $41, $03, $03, $43, $07, $07, $42, $43
	db $07, $44, $45, $46, $01, $01, $47, $04, $04, $07, $36, $37, $25, $36, $3a, $3b
	db $3c, $35, $39, $07, $07, $2c, $38, $07, $07, $04, $04, $2c, $30, $07, $07, $2d
	db $31, $07, $07, $2e, $32, $33, $34, $07, $2e, $2f, $21, $04, $04, $25, $26, $24
	db $07, $27, $28, $29, $24, $07, $07, $2a, $23, $07, $07, $2b, $19, $04, $04, $07
	db $07, $1c, $19, $07, $07, $1d, $1a, $20, $1f, $1e, $1b, $21, $22, $1b, $07, $01
	db $03, $0a, $09, $09, $01, $03, $21, $21, $21, $02, $02, $0a, $48, $22, $49, $02
	db $02, $08, $08, $08, $08, $02, $02, $08, $08, $6b, $6b, $04, $04, $07, $07, $07
	db $0e, $07, $07, $0e, $0f, $07, $0e, $0f, $40, $0e, $0f, $40, $07, $01, $04, $09
	db $09, $09, $09, $02, $02, $07, $0e, $10, $11, $02, $04, $07, $0e, $4b, $4c, $0e
	db $0f, $40, $07, $01, $02, $0e, $43, $03, $03, $43, $07, $07, $42, $43, $07, $41
	db $42, $43, $01, $03, $3e, $09, $09, $01, $03, $09, $09, $3f, $01, $01, $4f, $02
	db $01, $0e, $6e, $02, $02, $43, $07, $42, $43, $02, $02, $07, $0e, $0e, $0f, $02
	db $01, $43, $71, $01, $02, $6a, $43, $03, $03, $36, $37, $25, $35, $5d, $5e, $2c
	db $5f, $07, $03, $03, $2c, $61, $07, $2d, $60, $62, $2e, $2f, $21, $03, $03, $25
	db $26, $24, $67, $66, $23, $07, $68, $19, $03, $03, $07, $65, $19, $64, $63, $1a
	db $21, $22, $1b, $02, $02, $43, $07, $45, $46, $01, $03, $14, $69, $69, $04, $04
	db $43, $07, $07, $07, $42, $43, $07, $07, $41, $42, $43, $07, $07, $41, $42, $43
	db $01, $03, $4d, $4c, $4c, $04, $02, $2a, $23, $2b, $19, $1c, $19, $1d, $1a, $02
	db $03, $07, $4f, $07, $69, $69, $14, $01, $06, $14, $69, $69, $69, $69, $14, $02
	db $04, $09, $09, $09, $47, $6c, $6c, $6c, $6c, $02, $04, $07, $07, $07, $4f, $6c
	db $6c, $6c, $6c, $02, $02, $41, $42, $07, $41, $04, $02, $35, $39, $2c, $38, $2c
	db $30, $2d, $31, $01, $0a, $14, $14, $14, $14, $14, $14, $14, $14, $14, $14, $02
	db $02, $07, $0e, $21, $6e, $01, $02, $0e, $6f, $01, $02, $70, $43, $02, $02, $0f
	db $40, $40, $07, $02, $03, $07, $7b, $7c, $78, $79, $7a, $02, $02, $07, $19, $0e
	db $52, $02, $05, $41, $42, $43, $07, $07, $07, $44, $45, $74, $75, $02, $01, $19
	db $19, $01, $01, $82, $01, $02, $25, $25, $02, $04, $07, $0a, $1e, $1b, $0a, $1e
	db $1b, $07, $02, $05, $07, $3e, $09, $09, $09, $0e, $0f, $40, $07, $07, $01, $02
	db $80, $81, $03, $03, $07, $07, $0e, $07, $0e, $0f, $0e, $0f, $40, $03, $02, $83
	db $84, $85, $86, $87, $88, $04, $02, $89, $8a, $8f, $90, $97, $98, $87, $88, $04
	db $02, $8f, $90, $8b, $8c, $8d, $8e, $17, $18, $04, $02, $91, $92, $99, $9a, $93
	db $94, $9b, $3d, $03, $02, $4a, $4e, $53, $54, $87, $88, $03, $03, $83, $6d, $84
	db $85, $72, $86, $87, $73, $88, $04, $02, $83, $84, $95, $96, $85, $86, $87, $88
	db $01, $03, $73, $76, $77, $01, $03, $7e, $ff, $7f, $01, $01, $2c, $02, $02, $20
	db $1f, $21, $22


;@ The 168 metatiles of the ROM, 4 tiles each: top left, top right, bottom left, bottom right (DrawMetatile). Numbers from $A8 up are built in RAM (wCompMetatiles).
MetatileTiles::
	db $7f, $7f, $dd, $de, $7f, $7f, $df, $e0, $c9, $ca, $cb, $cc, $cd, $ce, $cf, $d0
	db $d1, $d2, $d3, $d4, $d5, $d6, $d3, $d7, $c5, $c6, $c7, $c8, $7f, $7f, $7f, $7f
	db $42, $42, $42, $42, $7f, $7f, $8e, $8d, $7f, $7f, $7f, $1e, $7f, $7f, $40, $7f
	db $1e, $1a, $8e, $8e, $3c, $40, $8e, $8e, $7f, $1e, $1e, $1a, $1a, $1b, $1b, $1c
	db $7f, $1e, $8e, $8e, $1a, $1b, $8e, $8e, $1c, $7f, $8e, $8d, $7f, $7f, $b7, $b6
	db $7f, $7f, $b5, $b6, $7f, $7f, $b5, $b8, $3b, $3b, $7f, $7f, $e4, $7f, $b2, $b5
	db $7f, $e4, $b6, $b3, $00, $17, $00, $17, $00, $17, $1a, $18, $1b, $1c, $1c, $7f
	db $7f, $7f, $7f, $14, $7f, $13, $7f, $0a, $1e, $1a, $1a, $1b, $7f, $7f, $11, $08
	db $7f, $7f, $7f, $12, $01, $01, $3b, $3b, $01, $1a, $19, $1d, $5c, $5a, $00, $17
	db $5e, $7f, $5d, $5e, $79, $79, $43, $43, $79, $5f, $43, $5c, $7f, $54, $7f, $7f
	db $53, $4a, $7f, $7f, $5c, $5d, $37, $5c, $7f, $4c, $7f, $55, $7f, $56, $7f, $7f
	db $39, $22, $39, $22, $39, $22, $3a, $3c, $3e, $3d, $7f, $3e, $3c, $01, $3f, $3b
	db $7f, $7f, $36, $7f, $35, $7f, $2c, $7f, $3c, $40, $3d, $3c, $7f, $7f, $2a, $33
	db $7f, $7f, $34, $7f, $78, $7a, $39, $22, $7f, $7c, $7c, $7b, $7d, $79, $7a, $43
	db $74, $7f, $7f, $7f, $6a, $7f, $73, $7f, $7b, $7a, $7a, $15, $68, $71, $7f, $7f
	db $72, $7f, $7f, $7f, $8f, $03, $8e, $8e, $7f, $7f, $1e, $8e, $7f, $7f, $8e, $40
	db $1c, $7f, $7f, $7f, $7f, $3e, $7f, $7f, $3d, $3c, $3e, $3d, $40, $7f, $3c, $40
	db $7f, $3e, $8e, $8e, $3d, $3c, $8e, $8e, $40, $7f, $8e, $8d, $b0, $b1, $8e, $8e
	db $1e, $7f, $1a, $7f, $1b, $7f, $1c, $7f, $7e, $7e, $7e, $ad, $8e, $8d, $1b, $1c
	db $8e, $8e, $7f, $7f, $1e, $8d, $7f, $7f, $7e, $29, $ae, $29, $7f, $7f, $b0, $b1
	db $7f, $14, $7f, $13, $7f, $0a, $1e, $1a, $1a, $18, $1b, $1c, $7e, $7e, $e3, $e3
	db $af, $29, $e3, $e2, $11, $08, $8e, $8e, $7f, $12, $8e, $8e, $8e, $8d, $3e, $3d
	db $3f, $3b, $7f, $7f, $2a, $33, $3c, $23, $34, $7f, $23, $23, $7f, $12, $23, $23
	db $11, $08, $23, $1a, $02, $09, $0e, $0d, $0b, $0c, $7f, $7f, $0f, $7f, $10, $7f
	db $50, $4f, $24, $4b, $52, $7f, $51, $7f, $7f, $7f, $4d, $4e, $6d, $6e, $69, $62
	db $7f, $7f, $6c, $6b, $7f, $70, $7f, $6f, $2b, $44, $2f, $30, $2e, $2d, $7f, $7f
	db $7f, $31, $7f, $32, $8e, $8d, $b2, $b3, $3a, $3c, $3e, $3d, $42, $42, $7f, $7f
	db $8e, $8e, $8e, $8e, $7e, $7e, $05, $04, $1a, $1b, $1d, $1c, $01, $01, $1f, $3b
	db $01, $23, $3b, $41, $3d, $3c, $3e, $3f, $07, $06, $e3, $e3, $90, $91, $8e, $8d
	db $2a, $33, $8e, $8e, $34, $7f, $8e, $8d, $91, $90, $8e, $8e, $91, $7f, $8e, $8d
	db $6c, $6b, $8e, $8e, $69, $62, $8e, $8e, $1a, $18, $8e, $8e, $7f, $6f, $6d, $6e
	db $8e, $8d, $00, $17, $19, $1d, $7f, $7f, $7f, $7f, $90, $91, $7f, $7f, $7f, $91
	db $7f, $7f, $1e, $01, $7f, $7f, $01, $40, $ef, $dc, $8e, $8d, $7e, $7e, $7e, $04
	db $7e, $29, $05, $29, $7e, $06, $e3, $e3, $07, $29, $e3, $e2, $e4, $8f, $8e, $8d
	db $90, $e4, $8e, $8d, $7e, $7e, $7e, $aa, $7e, $29, $ab, $29, $7e, $c1, $7e, $7e
	db $c2, $29, $7e, $29, $7e, $aa, $e3, $e3, $ab, $29, $e3, $e2, $7e, $b4, $7e, $bf
	db $7e, $29, $c0, $29, $7e, $7e, $7e, $7e, $7e, $29, $ac, $29, $e4, $7f, $03, $7f
	db $7f, $e4, $7f, $03, $7e, $06, $7e, $04, $07, $29, $05, $29, $7e, $c1, $e3, $e3
	db $c2, $29, $e3, $e2, $7e, $20, $e3, $e3, $21, $29, $e3, $e2, $03, $90, $8e, $8d


;@ What each tile is to the bike's wheels: one byte per tile number (ProbeTrackTiles).
TileKinds::
	db $88, $80, $94, $00, $00, $00, $00, $00, $83, $93, $85, $92, $91, $94, $95, $96
	db $97, $82, $81, $86, $87, $94, $96, $88, $86, $80, $84, $84, $84, $82, $84, $82
	db $00, $00, $98, $80, $9c, $00, $00, $00, $00, $00, $9d, $8d, $9b, $8e, $8f, $8c
	db $8b, $8a, $89, $9e, $9f, $9a, $99, $8c, $8a, $98, $9a, $80, $9c, $9c, $9c, $9e
	db $9c, $9e, $00, $90, $8c, $00, $00, $00, $00, $00, $8d, $9d, $8b, $9e, $1f, $9c
	db $9b, $9a, $99, $0e, $0f, $8a, $89, $00, $00, $00, $8a, $90, $8c, $8c, $8c, $8a
	db $00, $00, $84, $00, $00, $00, $00, $00, $93, $83, $95, $82, $81, $84, $85, $86
	db $87, $92, $91, $96, $97, $00, $00, $00, $96, $90, $94, $94, $94, $92, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $83, $c0, $c0, $00, $c0, $c0, $c0, $c0, $a3, $a3, $a3, $a3, $a0, $a0, $00
	db $00, $00, $00, $9f, $81, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $84
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00


;@ Where ProbeTrackTiles samples the tiles round the bike: 3 bytes per angle.
ProbePoints::
	db $1b, $1a, $15, $1b, $1a, $15, $15, $1a, $15, $15, $1a, $0f, $15, $1a, $0f, $10
	db $15, $0f, $10, $15, $0f, $10, $16, $0f, $10, $16, $0f, $10, $16, $0f, $0f, $16
	db $0e, $0f, $16, $0e, $09, $10, $0e, $08, $0f, $0e, $08, $0f, $0e, $08, $09, $0e
	db $08, $09, $0d, $08, $09, $13, $0e, $09, $13, $0e, $09, $13, $0d, $08, $13, $13
	db $0e, $19, $13, $0e, $19, $13, $0d, $1a, $13, $0d, $1a, $13, $0d, $1a, $14, $0d
	db $1b, $14, $0d, $1b, $1a, $13, $1b, $1b, $14, $15, $1b, $1a, $1b, $1b, $1a, $1b
	db $1a, $1b, $14, $1a, $1b, $14, $1a, $1b, $19, $1a, $15, $19, $1a, $15, $19, $15
	db $10, $1a, $15, $10, $1a, $16, $10, $1b, $16, $10, $1b, $16, $10, $1b, $16, $10
	db $1b, $16, $10, $1b, $16, $10, $1b, $16, $10, $1b, $1b, $1a, $15, $1b, $1a, $15
	db $1b, $1a, $15, $1b, $1a, $15, $1b, $1a, $15, $1b, $1a, $15, $1b, $1a, $15, $15
	db $1a, $0f, $15, $1a, $0f, $15, $1a, $0f, $05, $f8, $06, $f8, $08, $f8, $09, $f8
	db $0a, $fa, $0d, $fb, $0e, $fe, $0f, $03, $10, $05, $10, $06, $10, $07, $0f, $08
	db $0e, $0a, $0d, $0d, $0b, $0d, $05, $0f, $03, $10, $02, $10, $ff, $10, $fe, $10
	db $fe, $0e, $fd, $0d, $fc, $0c, $f9, $05, $f8, $03, $f8, $02, $f8, $ff, $f9, $fe
	db $fa, $fd, $fb, $fc, $fd, $fb, $03, $fa, $1b, $08, $1c, $09, $1d, $0a, $1e, $0b
	db $1f, $0c, $00, $0d, $01, $0e, $02, $0f, $03, $10, $04, $11, $05, $12, $06, $13
	db $07, $14, $08, $15, $09, $16, $0a, $17, $0b, $18, $0c, $19, $0d, $1a, $0e, $1b
	db $0f, $1c, $10, $1d, $11, $1e, $12, $1f, $13, $00, $14, $01, $15, $02, $16, $03
	db $17, $04, $18, $05, $19, $06, $1a, $07, $40, $40, $40, $41, $41, $41, $41, $42
	db $42, $42, $42, $43, $43, $43, $43, $40, $c0, $c0, $c0, $c1, $c1, $c1, $c1, $c2
	db $c2, $c2, $c2, $c3, $c3, $c3, $c3, $c0, $00, $01, $fd, $ff, $c0, $00, $fe, $ff
	db $80, $00, $fe, $ff, $00, $00, $ff, $ff, $00, $00, $ff, $ff, $00, $00, $ff, $ff
	db $c0, $ff, $fe, $ff, $80, $ff, $fe, $ff, $00, $ff, $fd, $ff


;@ The items of each course: a word table, one list per course of (map row, map column, kind) ending with $FF (PlaceItemMetatiles); the kind is also the metatile that draws it.
ItemLists::
	db $1c, $5f, $65, $5f, $a2, $5f, $d0, $5f, $0a, $60, $4d, $60, $be, $60, $8a, $60
	db $0b, $16, $07, $0c, $0d, $05, $07, $20, $02, $09, $21, $04, $0b, $2f, $06, $0b
	db $39, $07, $06, $43, $03, $0c, $36, $04, $09, $44, $04, $0c, $4d, $07, $0b, $7d
	db $04, $0c, $7d, $07, $0c, $87, $06, $09, $9b, $03, $05, $aa, $05, $08, $aa, $04
	db $0c, $b8, $04, $0d, $c7, $05, $0c, $ce, $04, $07, $d7, $02, $0a, $d9, $03, $07
	db $de, $05, $0a, $e0, $03, $07, $eb, $07, $ff, $0c, $0e, $07, $0b, $1e, $04, $06
	db $2d, $02, $09, $2f, $04, $0a, $39, $06, $0a, $41, $02, $09, $43, $07, $08, $55
	db $03, $0b, $57, $04, $0c, $5c, $05, $0a, $68, $04, $06, $7c, $03, $09, $88, $05
	db $07, $8e, $07, $03, $91, $04, $0c, $99, $04, $0c, $b2, $03, $0b, $c1, $04, $0a
	db $c4, $07, $0c, $e5, $04, $ff, $0a, $19, $04, $07, $1f, $03, $05, $27, $04, $04
	db $29, $07, $0b, $3d, $07, $0a, $4b, $06, $0d, $62, $02, $0d, $56, $04, $07, $86
	db $07, $0d, $93, $05, $0c, $a4, $03, $03, $cb, $03, $0c, $cd, $04, $02, $d0, $04
	db $0a, $ed, $04, $ff, $0a, $13, $04, $0a, $25, $03, $09, $37, $06, $0b, $42, $07
	db $0c, $47, $02, $06, $59, $04, $03, $66, $05, $02, $68, $06, $05, $74, $02, $04
	db $76, $07, $08, $94, $03, $06, $9c, $04, $06, $a3, $04, $06, $b2, $02, $08, $af
	db $03, $0a, $b3, $04, $02, $be, $04, $09, $e6, $04, $0d, $f2, $03, $ff, $0c, $10
	db $02, $08, $18, $07, $04, $20, $04, $05, $20, $06, $09, $33, $07, $0b, $42, $07
	db $0b, $49, $05, $0d, $4f, $04, $0b, $50, $03, $04, $60, $04, $01, $70, $04, $01
	db $72, $04, $01, $74, $04, $01, $76, $04, $01, $78, $04, $01, $7a, $04, $0a, $85
	db $02, $09, $8f, $06, $09, $96, $04, $01, $d3, $04, $03, $bf, $03, $08, $dd, $03
	db $ff, $05, $1a, $05, $04, $22, $04, $09, $44, $07, $0a, $44, $04, $08, $4e, $06
	db $0d, $35, $04, $0a, $30, $02, $05, $5c, $07, $06, $7a, $04, $08, $7b, $03, $09
	db $8a, $02, $08, $95, $04, $07, $a1, $07, $04, $a8, $03, $04, $bf, $02, $0b, $da
	db $04, $08, $e0, $07, $01, $ec, $03, $0c, $f0, $03, $09, $f1, $04, $ff, $0b, $0f
	db $06, $0a, $21, $04, $05, $2d, $04, $08, $36, $02, $0d, $3e, $04, $0b, $4f, $05
	db $04, $54, $03, $04, $8e, $03, $0b, $5d, $04, $03, $6b, $04, $05, $77, $03, $06
	db $81, $04, $0d, $a4, $04, $0d, $eb, $04, $08, $bd, $04, $07, $c4, $07, $09, $fc
	db $07, $ff, $0c, $0c, $04, $0b, $0f, $06, $08, $1a, $04, $0a, $31, $07, $09, $40
	db $03, $0d, $43, $04, $0d, $5c, $04, $08, $65, $04, $08, $67, $03, $07, $7c, $05
	db $0c, $8a, $04, $0a, $9e, $02, $0b, $93, $03, $0a, $a0, $06, $08, $ac, $07, $03
	db $bc, $04, $09, $be, $04, $02, $ce, $03, $05, $d0, $04, $04, $dd, $03, $ff, $0b
	db $61, $bf, $61, $41, $62, $b9, $62, $4f, $63, $e5, $63, $5d, $64, $f3, $64, $70
	db $1e, $20, $1f, $e8, $70, $1c, $10, $1d, $e8, $20, $1c, $40, $1c, $d8, $e0, $1a
	db $40, $1b, $e8, $60, $19, $00, $1a, $e8, $10, $19, $40, $19, $a8, $e0, $17, $30
	db $18, $e8, $10, $17, $70, $17, $e8, $50, $16, $a0, $16, $e8, $b0, $15, $10, $16
	db $e8, $40, $15, $70, $15, $e8, $60, $14, $70, $14, $e8, $a0, $13, $c0, $13, $e8
	db $c0, $12, $10, $13, $e8, $20, $12, $70, $12, $e8, $70, $11, $90, $11, $e8, $c0
	db $10, $00, $11, $e8, $00, $10, $80, $10, $e8, $70, $0e, $20, $0f, $e8, $70, $0c
	db $10, $0d, $e8, $20, $0c, $40, $0c, $d8, $e0, $0a, $40, $0b, $e8, $60, $09, $00
	db $0a, $e8, $10, $09, $40, $09, $a8, $e0, $07, $30, $08, $e8, $10, $07, $70, $07
	db $e8, $50, $06, $a0, $06, $e8, $b0, $05, $10, $06, $e8, $40, $05, $70, $05, $e8
	db $60, $04, $70, $04, $e8, $a0, $03, $c0, $03, $e8, $c0, $02, $10, $03, $e8, $20
	db $02, $70, $02, $e8, $70, $01, $90, $01, $e8, $c0, $00, $00, $01, $e8, $00, $00
	db $80, $00, $e8, $f0, $1c, $20, $1d, $b0, $d0, $19, $70, $1c, $e8, $f0, $18, $90
	db $19, $e8, $20, $18, $70, $18, $e8, $70, $17, $d0, $17, $a8, $d0, $16, $f0, $16
	db $78, $f0, $15, $60, $16, $e8, $60, $15, $80, $15, $e8, $90, $14, $00, $15, $e8
	db $10, $14, $40, $14, $c8, $60, $13, $90, $13, $b8, $f0, $10, $60, $12, $e8, $00
	db $10, $80, $10, $e8, $f0, $0c, $20, $0d, $b0, $d0, $09, $70, $0c, $e8, $f0, $08
	db $90, $09, $e8, $20, $08, $70, $08, $e8, $70, $07, $d0, $07, $a8, $d0, $06, $f0
	db $06, $78, $f0, $05, $60, $06, $e8, $60, $05, $80, $05, $e8, $90, $04, $00, $05
	db $e8, $10, $04, $40, $04, $c8, $60, $03, $90, $03, $b8, $f0, $00, $60, $02, $e8
	db $00, $00, $80, $00, $e8, $00, $1d, $80, $1e, $e8, $10, $1c, $60, $1c, $e8, $70
	db $1b, $a0, $1b, $e8, $20, $18, $d0, $1a, $e8, $50, $15, $a0, $17, $e8, $c0, $14
	db $10, $15, $e8, $e0, $13, $f0, $13, $e8, $00, $13, $40, $13, $e8, $70, $12, $d0
	db $12, $78, $e0, $11, $10, $12, $78, $e0, $10, $00, $11, $b8, $00, $10, $80, $10
	db $e8, $00, $0d, $80, $0e, $e8, $10, $0c, $60, $0c, $e8, $70, $0b, $a0, $0b, $e8
	db $20, $08, $d0, $0a, $e8, $50, $05, $a0, $07, $e8, $c0, $04, $10, $05, $e8, $e0
	db $03, $f0, $03, $e8, $00, $03, $40, $03, $e8, $70, $02, $d0, $02, $78, $e0, $01
	db $10, $02, $78, $e0, $00, $00, $01, $b8, $00, $00, $80, $00, $e8, $a0, $1e, $20
	db $1f, $e8, $80, $1d, $a0, $1d, $68, $f0, $1a, $40, $1b, $e8, $20, $1a, $50, $1a
	db $88, $50, $19, $80, $19, $80, $c0, $18, $e0, $18, $80, $f0, $17, $90, $18, $e8
	db $80, $17, $a0, $17, $88, $60, $16, $90, $16, $58, $e0, $15, $20, $16, $58, $a0
	db $14, $40, $15, $e8, $20, $14, $30, $14, $e8, $b0, $12, $e0, $12, $e8, $20, $11
	db $80, $11, $c8, $00, $10, $c0, $10, $e8, $a0, $0e, $20, $0f, $e8, $80, $0d, $a0
	db $0d, $68, $f0, $0a, $40, $0b, $e8, $20, $0a, $50, $0a, $88, $50, $09, $80, $09
	db $80, $c0, $08, $e0, $08, $80, $f0, $07, $90, $08, $e8, $80, $07, $a0, $07, $88
	db $60, $06, $90, $06, $58, $e0, $05, $20, $06, $58, $a0, $04, $40, $05, $e8, $20
	db $04, $30, $04, $e8, $b0, $02, $e0, $02, $e8, $20, $01, $80, $01, $c8, $00, $00
	db $c0, $00, $e8, $70, $1e, $20, $1f, $e8, $f0, $1d, $10, $1e, $e8, $60, $1c, $80
	db $1c, $28, $60, $1b, $80, $1b, $48, $d0, $18, $00, $1a, $e8, $60, $18, $80, $18
	db $b8, $50, $17, $80, $17, $d0, $30, $16, $d0, $16, $e8, $d0, $14, $30, $15, $e8
	db $80, $14, $a0, $14, $d0, $20, $14, $40, $14, $e8, $d0, $12, $40, $13, $e8, $80
	db $12, $b0, $12, $a0, $f0, $10, $20, $11, $c0, $00, $10, $80, $10, $e8, $70, $0e
	db $20, $0f, $e8, $f0, $0d, $10, $0e, $e8, $60, $0c, $80, $0c, $28, $60, $0b, $80
	db $0b, $48, $d0, $08, $00, $0a, $e8, $60, $08, $80, $08, $b8, $50, $07, $80, $07
	db $d0, $30, $06, $d0, $06, $e8, $d0, $04, $30, $05, $e8, $80, $04, $a0, $04, $d0
	db $20, $04, $40, $04, $e8, $d0, $02, $40, $03, $e8, $80, $02, $b0, $02, $a0, $f0
	db $00, $20, $01, $c0, $00, $00, $80, $00, $e8, $70, $1d, $c0, $1d, $e8, $40, $1c
	db $a0, $1c, $e8, $50, $1a, $30, $1b, $e8, $d0, $19, $20, $1a, $98, $10, $19, $50
	db $19, $e8, $a0, $18, $c0, $18, $e8, $20, $15, $20, $18, $e8, $90, $13, $80, $14
	db $e8, $40, $12, $a0, $12, $e8, $00, $12, $20, $12, $48, $20, $11, $40, $11, $98
	db $00, $10, $80, $10, $e8, $70, $0d, $c0, $0d, $e8, $40, $0c, $a0, $0c, $e8, $50
	db $0a, $30, $0b, $e8, $d0, $09, $20, $0a, $98, $10, $09, $50, $09, $e8, $a0, $08
	db $c0, $08, $e8, $20, $05, $20, $08, $e8, $90, $03, $80, $04, $e8, $40, $02, $a0
	db $02, $e8, $00, $02, $20, $02, $48, $20, $01, $40, $01, $98, $00, $00, $80, $00
	db $e8, $70, $1e, $20, $1f, $e8, $10, $1e, $30, $1e, $e8, $70, $1d, $90, $1d, $98
	db $c0, $1b, $e0, $1b, $88, $50, $1a, $80, $1a, $e8, $20, $19, $e0, $19, $e8, $e0
	db $18, $00, $19, $48, $c0, $17, $40, $18, $e8, $00, $17, $80, $17, $e8, $b0, $16
	db $d0, $16, $b0, $40, $16, $70, $16, $e8, $c0, $14, $e0, $14, $98, $f0, $12, $20
	db $14, $e8, $d0, $10, $20, $12, $e8, $00, $10, $80, $10, $e8, $70, $0e, $20, $0f
	db $e8, $10, $0e, $30, $0e, $e8, $70, $0d, $90, $0d, $98, $c0, $0b, $e0, $0b, $88
	db $50, $0a, $80, $0a, $e8, $20, $09, $e0, $09, $e8, $e0, $08, $00, $09, $48, $c0
	db $07, $40, $08, $e8, $00, $07, $80, $07, $e8, $b0, $06, $d0, $06, $b0, $40, $06
	db $70, $06, $e8, $c0, $04, $e0, $04, $98, $f0, $02, $20, $04, $e8, $d0, $00, $20
	db $02, $e8, $00, $00, $80, $00, $e8, $d0, $1e, $20, $1f, $e8, $d0, $1d, $90, $1e
	db $e8, $10, $1c, $40, $1c, $28, $90, $1a, $00, $1b, $a8, $d0, $19, $30, $1a, $c8
	db $20, $17, $70, $19, $e8, $a0, $16, $c0, $16, $e8, $20, $16, $50, $16, $e8, $e0
	db $13, $20, $14, $e8, $70, $13, $90, $13, $e8, $00, $12, $90, $12, $e8, $00, $10
	db $80, $10, $e8, $d0, $0e, $20, $0f, $e8, $d0, $0d, $90, $0e, $e8, $10, $0c, $40
	db $0c, $28, $90, $0a, $00, $0b, $a8, $d0, $09, $30, $0a, $c8, $20, $07, $70, $09
	db $e8, $a0, $06, $c0, $06, $e8, $20, $06, $50, $06, $e8, $e0, $03, $20, $04, $e8
	db $70, $03, $90, $03, $e8, $00, $02, $90, $02, $e8, $00, $00, $80, $00, $e8

;@ def PlayBikeSound(id: a)
;@ path: sound/api
;@ Plays a sound for the current bike, but only for player one's (wBikeId 1): the
;@ computer's bike makes no noise.
;@ test: wBikeId = rand(1, 2); wSoundBusy = 0; id = rand(8, 24)
;@ sig: 6ca839a9
PlayBikeSound::
;> if wBikeId & 1: PlaySound(id)
	push hl
	ld hl, wBikeId
	bit 0, [hl]
	call nz, PlaySound
;> return
	pop hl
	ret


;@ def InitSound()
;@ path: sound/api
;@ Clears the effect channels' records and the engine's variables (but not the music
;@ channels') and switches the sound on, all channels to both speakers at full volume.
;@ sig: 2beaa86d
InitSound::
;> fill(addr(wSfxSquare1), 0, 0x201)                 # $C080-$C280
	ld hl, wSfxSquare1
	ld de, $c081
	ld bc, $0200
	ld [hl], $00
	call CopyBytes
;> rNR52 = 0xFF
	ld hl, $ff26
	ld a, $ff
	ld [hl], a
;> rNR51 = 0xFF
	dec hl
	ld [hl], a
;> rNR50 = 0x77
	dec hl
	ld a, $77
	ld [hl], a
;> return
	ret


;@ def UpdateSound()
;@ path: sound/engine
;@ One tick of the sound engine, 64 times a second from the timer interrupt: every
;@ channel that plays moves on. The music channels skip a tick whenever the tempo
;@ accumulator carries (that is how wMusicTempo slows them down) or wMusicHold is set;
;@ while paused only the pause jingle on channel 1 runs. Ends by starting a queued sound.
;@ writes: wMusicSkip, wMusicTempoAcc, wSoundChannel, wSoundQueued
;@ reads: wMusicHold, wMusicSkip, wMusicSquare1, wMusicTempo, wMusicTempoAcc, wPause, wSfxSquare2, wSoundChannel, wSoundQueued
;@ test: wMusicTempo = rand(0, 255); wMusicTempoAcc = rand(0, 255); wPause = rng.choice([0, 0, 1]); wMusicHold = rng.choice([0, 0, 1])
;@ test: wSoundQueued = 0
;@ test: for k in range(7): mem[0xC080 + 0x100 * k] = 0
;@ test: mem[0xC380] = rng.choice([0, 9])
;@ sig: cd5b1574
UpdateSound::
;> wMusicSkip = 0
	xor a
	ld [wMusicSkip], a
;> acc = wMusicTempoAcc + wMusicTempo
;> wMusicTempoAcc = u8(acc)
	ld a, [wMusicTempo]
	ld b, a
	ld a, [wMusicTempoAcc]
	add b
	ld [wMusicTempoAcc], a
	jr nc, jr_000_65a7

;> if acc > 0xFF: wMusicSkip = 1                # this tick the music stands still
	ld a, $01
	ld [wMusicSkip], a

jr_000_65a7:
;> for ch in range(7):
	xor a

jr_000_65a8:
;>     wSoundChannel = ch
	ld [wSoundChannel], a
;>     if wPause:
	ld a, [wPause]
	or a
	jr z, jr_000_65c1

;>         if ch != 1: continue
	ld a, [wSoundChannel]
	cp $01
	jr nz, jr_000_65f8

;>         if wSfxSquare2[0] != 8: break              # only the pause jingle (sound 8) plays
	ld a, [wSfxSquare2]
	cp $08
	jr z, jr_000_65ec

	jr jr_000_6600

;>     elif wMusicSquare1[0] != 9:
jr_000_65c1:
	ld a, [wMusicSquare1]
	cp $09
	jr z, jr_000_65db

;>         if ch == 3 and (wMusicHold or wMusicSkip): break
	ld a, [wSoundChannel]
	cp $03
	jr nz, jr_000_65ec

	ld a, [wMusicHold]
	ld b, a
	ld a, [wMusicSkip]
	or b
	jr nz, jr_000_6600

	jr jr_000_65ec

;>     elif ch == 4 and (wMusicHold or wMusicSkip): break   # the engine sound on channel 3 keeps running
jr_000_65db:
	ld a, [wSoundChannel]
	cp $04
	jr nz, jr_000_65ec

	ld a, [wMusicHold]
	ld b, a
	ld a, [wMusicSkip]
	or b
	jr nz, jr_000_6600

;>     if mem[(0xC0 | ch) << 8 | 0x80]: UpdateChannel(0xC0 | ch)
jr_000_65ec:
	call ChannelPage
	ld l, $80
	ld a, [hl]
	or a
	jr z, jr_000_65f8

	call UpdateChannel

jr_000_65f8:
	ld a, [wSoundChannel]
	inc a
	cp $07
	jr nz, jr_000_65a8

;> if not wSoundQueued: return
jr_000_6600:
	ld a, [wSoundQueued]
	or a
	ret z

;> id = wSoundQueued
;> wSoundQueued = 0
;> return PlaySound(id)
	ld b, a
	xor a
	ld [wSoundQueued], a
	ld a, b
	jp PlaySound


;@ def UpdateChannel(ch: h)
;@ path: sound/engine
;@ One tick of a channel (its record is page ch, from $80). When its note is over the
;@ stream is read on; otherwise the release frame sets the release volume envelope
;@ (on the wave channel the volume steps down instead), and the pitch envelope moves on.
;@ writes: wSoundRegBase, wSoundRegIndex, wSoundRegValue
;@ reads: wSoundChannel
;@ test: ch = 0xC0 | rand(0, 6); wSoundChannel = ch & 7; r = ch << 8; wPause = 0
;@ test: mem[r + 0x84] = rand(2, 255); mem[r + 0x85] = rng.choice([0, 1, 8, 0x40, 0x80]); mem[r + 0x87] = 0; mem[r + 0x9B] = rand(0, 3)
;@ test: mem[0xC080] = rng.choice([0, 0, 5]); mem[0xC180] = rng.choice([0, 0, 5])
;@ sig: 685a30f3
UpdateChannel::
;> r = ch << 8
;> wSoundRegBase = ChannelRegOffset()
	call ChannelRegOffset
	ld [wSoundRegBase], a
;> de = mem16[r + 0x82]                       # the stream
	ld l, $82
	ld e, [hl]
	inc l
	ld d, [hl]
;> mem[r + 0x84] = u8(mem[r + 0x84] - 1)
;> if mem[r + 0x84] == 0:                     # the note is over
	ld l, $84
	dec [hl]
	jr nz, jr_000_6638

;>     mem[r + 0x85] &= 0x7E
	ld l, $85
	res 0, [hl]
	res 7, [hl]
;>     if wSoundChannel == 5:                 # the wave channel: its DAC off until the next note
	ld a, [wSoundChannel]
	cp $05
	jp nz, ReadSoundStream

;>         wSoundRegs[10] = 0
;>         rNR30 = 0
	xor a
	ld bc, $c20a
	ld [bc], a
	ld bc, $ff1a
	ld [bc], a
;>     return ReadSoundStream(de, ch)
	jp ReadSoundStream


;> if mem[r + 0x95] >= mem[r + 0x84]: mem[r + 0x85] |= 0x01   # the release frame has come
jr_000_6638:
	ld b, [hl]
	ld l, $95
	ld a, [hl]
	sub b
	jr c, jr_000_6643

	ld l, $85
	set 0, [hl]

;> if mem[r + 0x85] & 0x80: return
jr_000_6643:
	ld l, $85
	bit 7, [hl]
	ret nz

;> if wSoundChannel in (2, 6): return          # noise and drums have no envelopes here
	ld a, [wSoundChannel]
	cp $02
	ret z

	cp $06
	ret z

;> UpdatePitchEnvelope(ch)
	call UpdatePitchEnvelope
;> if wSoundChannel != 5:
	ld a, [wSoundChannel]
	cp $05
	jr z, jr_000_6687

;>     if mem[r + 0x95] != mem[r + 0x84]: return   # only at the release frame
	ld l, $84
	ld b, [hl]
	ld l, $95
	ld a, [hl]
	sub b
	ret nz

;>     env = mem[r + 0x93]
;>     if env:                                # the volume (less the volume drop) with the release envelope
	ld l, $93
	ld a, [hl]
	or a
	jr z, jr_000_6679

;>         env |= swap(u8((mem[r + 0x91] & 0x0F) - mem[r + 0x89]))
	ld l, $89
	ld c, [hl]
	ld l, $91
	ld a, [hl]
	and $0f
	sub c
	swap a
	ld c, a
	ld l, $93
	ld a, [hl]
	or c

;>     wSoundRegValue = env
jr_000_6679:
	ld [wSoundRegValue], a
;>     wSoundRegIndex = 2
	ld a, $02
	ld [wSoundRegIndex], a
;>     WriteSoundReg()
;>     return TriggerChannel()
	call WriteSoundReg
	jp TriggerChannel


jr_000_6687:
;> if not mem[r + 0x85] & 0x01: return        # the wave channel, from the release frame on:
	ld l, $85
	bit 0, [hl]
	ret z

;> level = 0
;> if mem[r + 0x93]:                          # a volume decay, one step every mem[r + $99] ticks
	ld l, $93
	ld a, [hl]
	or a
	jr z, jr_000_66b0

;>     mem[r + 0x98] = u8(mem[r + 0x98] - 1)
;>     if mem[r + 0x98]: return
	ld l, $98
	dec [hl]
	ret nz

;>     mem[r + 0x98] = mem[r + 0x99]
	ld l, $99
	ld a, [hl]
	ld l, $98
	ld [hl], a
;>     v = mem[r + 0x9B]
;>     if v:
	ld l, $9b
	ld a, [hl]
	or a
	jr z, jr_000_66b0

;>         v = (v + 1) & 3
;>         mem[r + 0x9B] = v
;>         if v:
	inc a
	and $03
	ld [hl], a
	jr z, jr_000_66b0

;>             v = u8(v + mem[r + 0x89])
;>             if v < 4: level = (2 * v + 1) << 4     # wave output level (rNR32 bits 5-6)
	ld l, $89
	add [hl]
	cp $04
	jr c, jr_000_66b0

	xor a

jr_000_66b0:
;> wSoundRegValue = level
	rla
	swap a
	ld [wSoundRegValue], a
;> wSoundRegIndex = 2
;> return WriteSoundReg()
	ld a, $02
	ld [wSoundRegIndex], a
	jp WriteSoundReg


;@ def UpdatePitchEnvelope(ch: h)
;@ path: sound/engine
;@ Every mem[ch:$97] ticks the channel's pitch envelope (vibrato, slides) takes a step
;@ and the new pitch is written.
;@ test: ch = 0xC0 | rand(0, 6); wSoundChannel = ch & 7; r = ch << 8; mem[r + 0x96] = rand(1, 3)
;@ sig: 6a03d2c3
UpdatePitchEnvelope::
;> r = ch << 8
;> if not mem[r + 0x87]: return
	ld l, $87
	ld a, [hl]
	or a
	ret z

;> mem[r + 0x96] = u8(mem[r + 0x96] - 1)
;> if mem[r + 0x96]: return
	ld l, $96
	dec [hl]
	ret nz

;> mem[r + 0x96] = mem[r + 0x97]
	ld l, $97
	ld a, [hl]
	ld l, $96
	ld [hl], a
;> StepPitchEnvelope(ch)
;> return WritePitch(ch)
	call StepPitchEnvelope
	jp WritePitch


;@ def NextSoundByte(stream: de, ch: h)
;@ path: sound/engine/stream
;@ Steps over one byte of the stream, then reads on.
;@ test: skip reads a whole stream (covered by SoundStreamByte's test)
;@ sig: 56bcae53
NextSoundByte::
jr_000_66d3:
;> return ReadSoundStream(u16(stream + 1), ch)   # falls through
	inc de

;@ def ReadSoundStream(stream: de, ch: h)
;@ path: sound/engine/stream
;@ Reads the channel's stream: $FB-$FF are flow commands (loop point, return, call,
;@ repeat, end); everything below goes to SoundStreamByte, which reads commands until
;@ a note starts.
;@ test: skip reads a whole stream (covered by SoundStreamByte's test)
;@ sig: eb46b8fc
ReadSoundStream::
jr_000_66d4:
;> a = mem[stream]
;> if a < 0xFB: return SoundStreamByte(stream, ch)
	ld a, [de]
	cp $fb
	jp c, SoundStreamByte

;> return SoundFlowCommands[a - 0xFB](u16(stream + 1), ch)
	inc de
	sub $fb
	push hl
	call JumpTable

;@ The stream's flow commands $FB-$FF: loop point, return, call, repeat / jump, end.
SoundFlowCommands::
	dw SndCmdLoopPoint
	dw SndCmdReturn
	dw SndCmdCall
	dw SndCmdRepeat
	dw SndCmdEnd

;@ def SndCmdLoopPoint(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $FB: remembers this place as the loop point for $FE.
;@ test: skip reads a whole stream (covered by SoundStreamByte's test)
;@ sig: 898b127f
SndCmdLoopPoint::
;> mem16[(ch << 8) + 0x9C] = stream
	pop hl
	ld l, $9c
	ld [hl], e
	inc l
	ld [hl], d
;> return ReadSoundStream(stream, ch)
	jr jr_000_66d4

;@ def SndCmdReturn(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $FC: back from a $FD call.
;@ test: skip reads a whole stream (covered by SoundStreamByte's test)
;@ sig: ea540e63
SndCmdReturn::
;> stream = mem16[(ch << 8) + 0x9E]
	pop hl
	ld l, $9e
	ld e, [hl]
	inc l
	ld d, [hl]
;> return ReadSoundStream(stream, ch)
	jr jr_000_66d4

;@ def SndCmdCall(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $FD addr: plays the part at addr, which ends with $FC (one level only).
;@ test: skip reads a whole stream (covered by SoundStreamByte's test)
;@ sig: 2bf82d94
SndCmdCall::
;> target = mem16[stream]
	pop hl
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	inc de
;> mem16[(ch << 8) + 0x9E] = u16(stream + 2)
	ld l, $9e
	ld [hl], e
	inc l
	ld [hl], d
;> return ReadSoundStream(target, ch)
	ld e, c
	ld d, b
	jr jr_000_66d4

;@ def SndCmdRepeat(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $FE n: back to the loop point until this has been passed n times;
;@ $FE $FF addr jumps to addr (how the music loops forever).
;@ test: skip reads a whole stream (covered by SoundStreamByte's test)
;@ sig: 94895c7e
SndCmdRepeat::
;> r = ch << 8
;> n = mem[stream]
;> if n != 0xFF:
	pop hl
	ld a, [de]
	cp $ff
	jr z, jr_000_671e

;>     mem[r + 0x86] = u8(mem[r + 0x86] + 1)
;>     if mem[r + 0x86] != n: return ReadSoundStream(mem16[r + 0x9C], ch)
;>@done     mem[r + 0x86] = 0
;>@done2     return NextSoundByte(stream, ch)
	ld l, $86
	inc [hl]
	cp [hl]
	jr z, jr_000_6728

	ld l, $9c
	ld e, [hl]
	inc l
	ld d, [hl]
	jr jr_000_66d4

;> return ReadSoundStream(mem16[u16(stream + 1)], ch)
jr_000_671e:
	inc de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld d, b
	ld e, c
	jr jr_000_66d4

;=@done
jr_000_6728:
	ld l, $86
	ld [hl], $00
;=@done2
	jr jr_000_66d3

;@ def SndCmdEnd(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $FF: the sound is over. The channel goes quiet; an effect on a square
;@ channel hands the channel back to the music under it (its duty and pitch are
;@ restored). The start signal (sound 17) queues the course's music here.
;@ writes: wSoundRegIndex, wSoundRegValue
;@ reads: wPlayerMask, wSoundChannel
;@ test: skip pops the hl its dispatcher (ReadSoundStream) pushed
;@ sig: 6274c5ad
SndCmdEnd::
;> QueueCourseMusic(ch)                      # (the link-mode test before it has no effect)
	pop hl
	ld a, [wPlayerMask]
	and $04
	call QueueCourseMusic
;> mem[(ch << 8) + 0x80] = mem[(ch << 8) + 0x81] = 0
	xor a
	ld l, $80
	ld [hli], a
	ld [hl], a
;> wSoundRegValue = 0
	ld a, $00
	ld [wSoundRegValue], a
;> wSoundRegIndex = 2
	ld a, $02
	ld [wSoundRegIndex], a
;> WriteSoundReg()                            # volume 0
;> TriggerChannel()
	call WriteSoundReg
	call TriggerChannel
;> if wSoundChannel not in (0, 1): return
	ld a, [wSoundChannel]
	cp $01
	jr z, jr_000_675f

	cp $00
	ret nz

;> if wSoundChannel == 0:                     # square 1 back to the music
;>     rNR10 = 0
;>     music = 0xC3
	xor a
	ld bc, $ff10
	ld [bc], a
	ld h, $c3
	jr jr_000_6761

;> else: music = 0xC4                         # square 2
jr_000_675f:
	ld h, $c4

jr_000_6761:
;> if not mem[music << 8 | 0x80]: return
	ld l, $80
	ld a, [hl]
	or a
	ret z

;> SetDutyOrWave(music)
	push hl
	call SetDutyOrWave
	pop hl
;> return WriteFrequency(mem16[music << 8 | 0x8F])
	ld l, $8f
	ld c, [hl]
	ld l, $90
	ld b, [hl]
	jp WriteFrequency


;@ def QueueCourseMusic(ch: h)
;@ path: sound/engine
;@ When the start signal (sound 17) ends, the course's music follows: CourseMusic by
;@ wCourse.
;@ writes: wSoundQueued
;@ reads: wCourse
;@ test: ch = 0xC0 | rand(0, 6); mem[(ch << 8) + 0x80] = rng.choice([0x11, 0x10, 0]); wCourse = rand(1, 8)
;@ sig: 71879434
QueueCourseMusic::
;> if mem[(ch << 8) + 0x80] != 0x11: return
	ld l, $80
	ld a, [hl]
	cp $11
	jr z, jr_000_677c

	ret


jr_000_677c:
;> wSoundQueued = mem[u16(CourseMusic + u8(wCourse - 1))]
	ld a, [wCourse]
	dec a
	ld bc, CourseMusic
	add c
	ld c, a
	jr nc, jr_000_6788

	inc b

jr_000_6788:
	ld a, [bc]
	ld [wSoundQueued], a
;> return
	ret


;@ The music each course plays after the start signal (sound 17), by wCourse: songs $1D-$20.
CourseMusic::
	db $20, $1e, $1f, $1d, $20, $1e, $1f, $1d

;@ def SoundStreamByte(stream: de, ch: h)
;@ path: sound/engine/stream
;@ A stream byte below $FB: $00-$DF a note, $E0 the instrument, $E1-$E6 the octave,
;@ $E7-$EF a command with one parameter byte, $F0-$FA the volume drop.
;@ test: ch = 0xC0 | rng.choice([0, 1, 3, 4, 5]); wSoundChannel = ch & 7; wSoundRegBase = (0, 5, 15, 0, 5, 10, 15)[ch & 7]; r = ch << 8; mem[0xC080] = mem[0xC180] = 0
;@ test: s = rand_ram(12); mem[r + 0x8D] = rand(1, 8); mem[r + 0x88] = rand(0, 4); mem[r + 0x8E] = rand(0, 4); mem[r + 0x87] = 0; mem[r + 0x94] = rand(0, 15)
;@ test: for k in range(12): mem[s + k] = rng.choice([rand(0x11, 0x7F), rand(0xE1, 0xE5), rand(0xF0, 0xF3), 0xE7, 0xE8, 0xEB])
;@ test: mem[s + 11] = 0x31
;@ sig: 759c8387
SoundStreamByte::
;> a = mem[stream]
;> if a == 0xE0: return SndCmdInstrument(stream, ch)
	ld a, [de]
	cp $e0
	jp z, SndCmdInstrument

;> if a & 0xF0 < 0xE0: return PlayNote(stream, ch)
	and $f0
	cp $e0
	jp c, PlayNote

;> if a & 0xF0 == 0xF0: return SndCmdVolume(stream, ch)
	cp $f0
	jp z, SndCmdVolume

;> if a < 0xE7: return SndCmdOctave(stream, ch)
	ld a, [de]
	cp $e7
	jp c, SndCmdOctave

;> return SoundCommands[a - 0xE7](u16(stream + 1), ch)
	inc de
	sub $e7
	push hl
	call JumpTable

;@ The stream commands $E7-$EF, each with one parameter byte.
SoundCommands::
	dw SndCmdNoteUnit
	dw SndCmdEnvelope
	dw SndCmdSweep
	dw SndCmdSub
	dw SndCmdNopEB
	dw SndCmdNopEC
	dw SndCmdNopED
	dw SndCmdTempo
	dw SndCmdPan

;@ def SndCmdNoteUnit(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $E7 n: the note length unit (a note lasts its length nibble times n ticks).
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: f6e3cbfe
SndCmdNoteUnit::
;> mem[(ch << 8) + 0x8D] = mem[stream]
	pop hl
	ld a, [de]
	ld l, $8d
	ld [hl], a
;> return NextSoundByte(stream, ch)
	jp NextSoundByte


;@ def SndCmdEnvelope(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $E8 gs: the release envelope s (low nibble, the volume envelope a note gets
;@ at its release frame) and the gate g/16 of the note's length before that frame.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 3effee65
SndCmdEnvelope::
;> r = ch << 8
;> mem[r + 0x93] = mem[stream] & 0x0F
	pop hl
	ld a, [de]
	and $0f
	ld l, $93
	ld [hl], a
;> mem[r + 0x94] = mem[stream] >> 4
	ld a, [de]
	swap a
	and $0f
	ld l, $94
	ld [hl], a
;> return NextSoundByte(stream, ch)
	jp NextSoundByte


;@ def SndCmdSweep(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $E9 n: writes n to the channel's first register (rNR10, the sweep, on square 1).
;@ writes: wSoundRegIndex, wSoundRegValue, wSoundSweep
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 4097e96b
SndCmdSweep::
;> wSoundSweep = wSoundRegValue = mem[stream]
	pop hl
	ld a, [de]
	ld [wSoundSweep], a
	ld [wSoundRegValue], a
;> wSoundRegIndex = 0
	ld a, $00
	ld [wSoundRegIndex], a
;> WriteSoundReg()
;> return NextSoundByte(stream, ch)
	call WriteSoundReg
	jp NextSoundByte


;@ def SndCmdSub(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EA xn: x picks one of SoundSubCommands (transpose up or down, the pitch
;@ envelope, the duty or wave), n is its value.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 993510d6
SndCmdSub::
;> return SoundSubCommands[mem[stream] >> 4](stream, ch)
	pop hl
	ld a, [de]
	and $f0
	swap a
	push hl
	call JumpTable

;@ The sub-commands of $EA, by the parameter's high nibble.
SoundSubCommands::
	dw SndCmdTransposeUp
	dw SndCmdTransposeDown
	dw SndCmdPitchEnvelope
	dw SndCmdDuty
	dw SndCmdSubNop

;@ def SndCmdTransposeUp(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EA $0n: transposes the following notes n semitones up.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 6646e741
SndCmdTransposeUp::
;> mem[(ch << 8) + 0x88] = mem[stream] & 0x0F
	pop hl
	ld a, [de]
	and $0f
	ld l, $88
	ld [hl], a
;> return NextSoundByte(stream, ch)
	jp NextSoundByte


;@ def SndCmdTransposeDown(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EA $1n: transposes the following notes n semitones down.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 99996504
SndCmdTransposeDown::
;> mem[(ch << 8) + 0x88] = u8(-(mem[stream] & 0x0F))
	pop hl
	ld a, [de]
	and $0f
	cpl
	inc a
	ld l, $88
	ld [hl], a
;> return NextSoundByte(stream, ch)
	jp NextSoundByte


;@ def SndCmdPitchEnvelope(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EA $2n: pitch envelope n (PitchEnvelopes) for the following notes; 0 none.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 521a5b1a
SndCmdPitchEnvelope::
;> r = ch << 8
;> n = mem[stream] & 0x0F
;> mem[r + 0x87] = n
	pop hl
	ld a, [de]
	and $0f
	ld l, $87
	ld [hl], a
;> mem16[r + 0xA0] = mem16[u16(PitchEnvelopes + u8(2 * u8(n - 1)))]
	push hl
	dec a
	ld hl, PitchEnvelopes
	call GetPointer
	call SwapHLBC
	pop hl
	ld l, $a0
	ld [hl], c
	inc l
	ld [hl], b
;> mem[r + 0x8C] = 0
	xor a
	ld l, $8c
	ld [hl], a
;> return NextSoundByte(stream, ch)
	jp NextSoundByte


;@ def SndCmdDuty(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EA $3n: the duty n (square channels) or wave pattern n (wave channel).
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: a92a7d81
SndCmdDuty::
;> mem[(ch << 8) + 0x92] = mem[stream] & 0x0F
	pop hl
	ld a, [de]
	and $0f
	ld l, $92
	ld [hl], a
;> SetDutyOrWave(ch)
;> return NextSoundByte(stream, ch)
	call SetDutyOrWave
	jp NextSoundByte


;@ def SndCmdSubNop(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EA $4n: does nothing.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: d2aa83e9
SndCmdSubNop::
;> return NextSoundByte(stream, ch)
	pop hl
	jp NextSoundByte


;@ def SndCmdNopEB(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EB n: does nothing.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: d2aa83e9
SndCmdNopEB::
;> return NextSoundByte(stream, ch)
	pop hl
	jp NextSoundByte


;@ def SndCmdNopEC(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EC n: does nothing.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: d2aa83e9
SndCmdNopEC::
;> return NextSoundByte(stream, ch)
	pop hl
	jp NextSoundByte


;@ def SndCmdNopED(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $ED n: does nothing.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: d2aa83e9
SndCmdNopED::
;> return NextSoundByte(stream, ch)
	pop hl
	jp NextSoundByte


;@ def SndCmdTempo(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EE n: the music tempo (wMusicTempo; higher is slower).
;@ writes: wMusicTempo
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 7735a159
SndCmdTempo::
;> wMusicTempo = mem[stream]
	pop hl
	ld a, [de]
	ld [wMusicTempo], a
;> return NextSoundByte(stream, ch)
	jp NextSoundByte


;@ def SndCmdPan(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $EF n: the channel's panning, the high nibble of n in rNR51's layout (bit 0
;@ square 1 ... bit 3 noise, right; the same + 4 for left). Music on square 1 leaves it
;@ alone while an effect plays there.
;@ writes: wSoundPan
;@ reads: wSfxSquare1, wSoundChannel, wSoundPan
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: e4d4134e
SndCmdPan::
;> if wSoundChannel == 3 and wSfxSquare1[0]: return NextSoundByte(stream, ch)
	pop hl
	ld a, [wSoundChannel]
	cp $03
	jr nz, jr_000_6873

	ld a, [wSfxSquare1]
	or a
	jp nz, NextSoundByte

	ld a, [wSoundChannel]

jr_000_6873:
;> keep = mem[u16(PanMasks + wSoundChannel)]
;> wSoundPan = (wSoundPan & keep) | (swap(mem[stream]) & ~keep & 0xFF)
	push hl
	ld hl, PanMasks
	rst $28
	ld a, [wSoundPan]
	and [hl]
	ld c, a
	ld a, [hl]
	cpl
	ld b, a
	ld a, [de]
	swap a
	and b
	or c
	ld [wSoundPan], a
;> rNR51 = wSoundPan
	ld bc, $ff25
	ld [bc], a
;> return NextSoundByte(stream, ch)
	pop hl
	jp NextSoundByte


;@ For each channel the bits of rNR51 it leaves alone when a stream sets its panning (command $EF); the drum channel's $FF changes nothing.
PanMasks::
	db $ee, $dd, $77, $ee, $dd, $bb, $ff, $c9

;@ def SndCmdOctave(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Commands $E1-$E6: the octave (1-6) of the following notes.
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: d20bdf30
SndCmdOctave::
;> mem[(ch << 8) + 0x8E] = u8((mem[stream] & 0x0F) - 1)
	ld a, [de]
	and $0f
	dec a
	ld l, $8e
	ld [hl], a
;> return NextSoundByte(stream, ch)
	jp NextSoundByte


;@ def SndCmdInstrument(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Command $E0: the note length unit, then (not on the drum channel) the instrument:
;@ volume and duty / wave, then the release envelope and the gate. On the noise channel
;@ one byte, the volume envelope, which is written at once.
;@ writes: wSoundRegIndex, wSoundRegValue
;@ reads: wSoundChannel
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: ab903fd2
SndCmdInstrument::
;> r = ch << 8
;> stream = u16(stream + 1)
;> mem[r + 0x8D] = mem[stream]                # the note length unit
	inc de
	ld a, [de]
	ld l, $8d
	ld [hl], a
;> if wSoundChannel == 6: return NextSoundByte(stream, ch)
	ld a, [wSoundChannel]
	cp $06
	jp z, NextSoundByte

;> stream = u16(stream + 1)
;> if wSoundChannel != 2:
	inc de
	cp $02
	jr z, jr_000_68d7

;>     mem[r + 0x91] = mem[stream] & 0x0F        # the volume
	ld a, [de]
	and $0f
	ld l, $91
	ld [hl], a
;>     mem[r + 0x92] = mem[stream] >> 4          # the duty or wave
	ld a, [de]
	swap a
	and $0f
	ld l, $92
	ld [hl], a
;>     SetDutyOrWave(ch)
	call SetDutyOrWave
;>     stream = u16(stream + 1)
;>     mem[r + 0x93] = mem[stream] & 0x0F        # the release envelope
	inc de
	ld a, [de]
	and $0f
	ld l, $93
	ld [hl], a
;>     mem[r + 0x94] = mem[stream] >> 4          # the gate
	ld a, [de]
	swap a
	and $0f
	ld l, $94
	ld [hl], a
;>     return NextSoundByte(stream, ch)
	jp NextSoundByte


jr_000_68d7:
;> mem[r + 0x93] = mem[stream] & 0x0F            # noise: the envelope, written now
	ld a, [de]
	and $0f
	ld l, $93
	ld [hl], a
;> mem[r + 0x91] = mem[stream] >> 4
	ld a, [de]
	swap a
	and $0f
	ld l, $91
	ld [hl], a
;> wSoundRegValue = mem[stream]
	ld a, [de]
	ld [wSoundRegValue], a
;> wSoundRegIndex = 2
	ld a, $02
	ld [wSoundRegIndex], a
;> WriteSoundReg()
;> TriggerChannel()
;> return NextSoundByte(stream, ch)
	call WriteSoundReg
	call TriggerChannel
	jp NextSoundByte


;@ def SndCmdVolume(stream: de, ch: h)
;@ path: sound/engine/commands
;@ Commands $F0-$FA: a volume drop of n (the low nibble) for the following
;@ notes; on the noise channel the new volume is written at once.
;@ writes: wSoundRegIndex, wSoundRegValue
;@ reads: wSoundChannel
;@ test: skip reads on in the stream (covered by SoundStreamByte's test)
;@ sig: 477be51a
SndCmdVolume::
;> r = ch << 8
;> drop = mem[stream] & 0x0F
;> mem[r + 0x89] = drop
	ld a, [de]
	and $0f
	ld l, $89
	ld [hl], a
	ld b, a
;> if wSoundChannel != 2: return NextSoundByte(stream, ch)
	ld a, [wSoundChannel]
	cp $02
	jp nz, NextSoundByte

;> v = swap(u8((mem[r + 0x91] & 0x0F) - drop))
	ld l, $91
	ld a, [hl]
	and $0f
	sub b
	swap a
;> mem[r + 0x9B] = v
	ld l, $9b
	ld [hl], a
;> wSoundRegValue = v | mem[r + 0x93]
	ld l, $93
	or [hl]
	ld [wSoundRegValue], a
;> wSoundRegIndex = 2
	ld a, $02
	ld [wSoundRegIndex], a
;> WriteSoundReg()
;> TriggerChannel()
;> return NextSoundByte(stream, ch)
	call WriteSoundReg
	call TriggerChannel
	jp NextSoundByte


;@ def PlayNoiseNote(stream: de, ch: h)
;@ path: sound/engine/notes
;@ A note on the noise effect channel: the byte is the noise setting (rNR43) itself,
;@ and every note lasts one note length unit.
;@ test: ch = 0xC2; wSoundChannel = 2; wSoundRegBase = 15; stream = rand_ram(1)
;@ sig: 017f3893
PlayNoiseNote::
;> mem[(ch << 8) + 0x84] = mem[(ch << 8) + 0x8D]
	ld l, $8d
	ld a, [hl]
	ld l, $84
	ld [hl], a
;> return WriteFrequency(mem[stream])
	ld a, [de]
	ld c, a
	ld b, $00
	jp WriteFrequency


;@ def PlayNote(stream: de, ch: h)
;@ path: sound/engine/notes
;@ A note byte: the high nibble is the pitch (1-12 from C, 0 a rest), the low nibble
;@ the length in note length units. The period comes from NotePeriods by pitch, octave
;@ and transpose; the release frame is gate/16 of the length ($F: one tick before the
;@ end). The pitch envelope starts over, and the volume (less the volume drop) is set.
;@ writes: wSoundRegIndex, wSoundRegValue
;@ reads: wSoundChannel
;@ test: ch = 0xC0 | rng.choice([0, 1, 3, 4, 5]); wSoundChannel = ch & 7; wSoundRegBase = (0, 5, 15, 0, 5, 10, 15)[ch & 7]; r = ch << 8
;@ test: stream = rand_ram(2); mem[stream] = rand(0, 12) << 4 | rand(0, 15); mem[r + 0x8E] = rand(0, 5); mem[r + 0x88] = rand(0, 6)
;@ test: mem[r + 0x87] = rng.choice([0, 1]); mem[r + 0xA0] = (0x707F) & 0xFF; mem[r + 0xA0 + 1] = (0x707F) >> 8; mem[r + 0xA3] = 0; mem[r + 0x80] = rng.choice([1, 9])
;@ test: mem[0xC080] = rng.choice([0, 0, 5]); mem[0xC180] = rng.choice([0, 0, 5])
;@ sig: d22beed5
PlayNote::
;> r = ch << 8
;> SaveStreamPtr(stream, ch)                  # the stream goes on after the note
	call SaveStreamPtr
	dec de
;> if wSoundChannel == 2: return PlayNoiseNote(stream, ch)
	ld a, [wSoundChannel]
	cp $02
	jr z, PlayNoiseNote

;> note = mem[stream]
;> length = u8(mem[r + 0x8D] * (note & 0x0F)) # the length nibble times the unit
	ld a, [de]
	and $0f
	or a
	jr nz, jr_000_6943

jr_000_6943:
	ld b, a
	ld l, $8d
	ld a, [hl]
	ld c, a

jr_000_6948:
	dec b
	jr z, jr_000_694e

	add c
	jr jr_000_6948

jr_000_694e:
;> mem[r + 0x84] = length
	ld l, $84
	ld [hl], a
;> if not note & 0xF0: return PlayRest(ch)
	ld a, [de]
	and $f0
	jp z, PlayRest

;> if wSoundChannel == 6: return PlayDrum(stream)
	ld a, [wSoundChannel]
	cp $06
	jp z, PlayDrum

;> gate = mem[r + 0x94]
;> if gate == 0x0F: release = u8(length - 1)
	ld l, $94
	ld a, [hl]
	cp $0f
	jr nz, jr_000_696c

	ld l, $84
	ld a, [hl]
	dec a
	jr jr_000_697e

;> else: release = (length * (gate & 0x0F)) >> 4
jr_000_696c:
	push de
	ld c, a
	ld b, $04
	ld l, $84
	ld d, [hl]
	xor a

jr_000_6974:
	srl c
	jr nc, jr_000_6979

	add d

jr_000_6979:
	rra
	dec b
	jr nz, jr_000_6974

	pop de

jr_000_697e:
;> mem[r + 0x95] = release                    # the frame (counting down) the note is released
	ld l, $95
	ld [hl], a
;> mem[r + 0x8C] = 0
	ld l, $8c
	ld [hl], $00
;> n = u8(12 * mem[r + 0x8E])                 # the octave
	ld c, $00
	ld l, $8e
	ld a, [hl]
	or a
	jr z, jr_000_6996

	ld b, a
	ld c, $0c
	xor a

jr_000_6991:
	add c
	dec b
	jr nz, jr_000_6991

	ld c, a

jr_000_6996:
;> n = u8((note >> 4) - 1 + mem[r + 0x88] + n)   # plus the pitch and the transpose
	ld a, [de]
	and $f0
	swap a
	dec a
	ld b, a
	ld l, $88
	ld a, [hl]
	add b
	add c
	ld c, a
	ld b, $00
	sla c
	rl b
;> period = mem16[NotePeriods + 2 * n]
	push hl
	ld hl, NotePeriods
	add hl, bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	pop hl
;> mem16[r + 0x8F] = period
	ld l, $8f
	ld [hl], c
	inc l
	ld [hl], b
;> if mem[r + 0x87]:                          # its pitch envelope starts over
	ld l, $87
	ld a, [hl]
	or a
	jp z, Jump_000_69c5

;>     mem[r + 0xA2] = 0
;>     StepPitchEnvelope(ch)
	xor a
	ld l, $a2
	ld [hl], a
	call StepPitchEnvelope

Jump_000_69c5:
;> WritePitch(ch)
;> mem[r + 0x85] &= 0xBF
	call WritePitch
	ld l, $85
	res 6, [hl]
;> if wSoundChannel != 5:
	ld a, [wSoundChannel]
	cp $05
	jr z, jr_000_69ef

;>     v = swap(u8((mem[r + 0x91] & 0x0F) - mem[r + 0x89]))   # the volume, in rNRx2's high nibble
	ld l, $89
	ld c, [hl]
	ld l, $91
	ld a, [hl]
	and $0f
	sub c
	swap a
;>     mem[r + 0x9B] = v
;>     wSoundRegValue = v
	ld l, $9b
	ld [hl], a
	ld [wSoundRegValue], a
;>     wSoundRegIndex = 2
	ld a, $02
	ld [wSoundRegIndex], a
;>     WriteSoundReg()
;>     return TriggerChannel()
	call WriteSoundReg
	jp TriggerChannel


jr_000_69ef:
;> wSoundRegs[10] = 0x80                      # the wave channel: its DAC on
;> rNR30 = 0x80
	ld a, $80
	ld bc, $c20a
	ld [bc], a
	ld bc, $ff1a
	ld [bc], a
;> mem[r + 0x98] = mem[r + 0x99] = mem[r + 0x93]
	ld l, $93
	ld a, [hl]
	ld l, $98
	ld [hl], a
	ld l, $99
	ld [hl], a
;> v = ((mem[r + 0x91] & 0x0F) >> 1) & 3      # the output level 0-3
	ld l, $89
	ld c, [hl]
	ld l, $91
	ld a, [hl]
	and $0f
	rra
	and $03
;> mem[r + 0x9B] = v
;> v = u8(v + mem[r + 0x89])
;> level = v << 5 if v < 4 else 0
	ld l, $9b
	ld [hl], a
	add c
	cp $04
	jr c, jr_000_6a16

	xor a

jr_000_6a16:
	swap a
	rla
	and $f0
;> wSoundRegValue = level
	ld [wSoundRegValue], a
;> wSoundRegIndex = 2
	ld a, $02
	ld [wSoundRegIndex], a
;> WriteSoundReg()
;> return TriggerChannel()
	call WriteSoundReg
	jp TriggerChannel


;@ def StepPitchEnvelope(ch: h)
;@ path: sound/engine/notes
;@ The next step of the channel's pitch envelope: a byte with the ticks to the next
;@ step (high nibble), the sign (bit 3) and the offset's high bits, then its low byte.
;@ $FB marks a loop point, $FE n goes back to it n times ($FF forever), $FF stops.
;@ (After a finished $FE loop the reading goes on one byte further than the index;
;@ the game's envelopes only loop forever, with $FE $FF, so it never shows.)
;@ test: ch = 0xC0 | rand(0, 6); r = ch << 8; e = rand_ram(12); mem[r + 0xA0] = (e) & 0xFF; mem[r + 0xA0 + 1] = (e) >> 8; mem[r + 0xA2] = rand(0, 2) * 2; mem[r + 0xA3] = 0
;@ test: mem[e] = rand(0, 0xFA); mem[e + 2] = rand(0, 0xFA); mem[e + 4] = rand(0, 0xFA); mem[e + 9] = rand(0, 0xFA); mem[e + 10] = rand(0, 0xFA)
;@ test: mem[e + 6] = rng.choice([0xFE, 0xFF, 0xFB]); mem[e + 7] = rand(0, 3); mem[e + 8] = 0; mem[r + 0x8C] = rand(0, 3)
;@ sig: 505e85ad
StepPitchEnvelope::
;> r = ch << 8
;> p = u16(mem16[r + 0xA0] + mem[r + 0xA2])
	ld l, $a0
	ld c, [hl]
	inc l
	ld b, [hl]
	inc l
	ld a, [hl]
	add c
	ld c, a
	jr nc, jr_000_6a35

	inc b

jr_000_6a35:
;> while True:
;>     a = mem[p]
;>     if a not in (0xFB, 0xFE, 0xFF):
	ld a, [bc]
	cp $fb
	jr z, jr_000_6a67

	cp $fe
	jr z, jr_000_6a71

	cp $ff
	jr z, jr_000_6a8f

;>         mem[r + 0x96] = mem[r + 0x97] = a >> 4   # ticks to the next step
	swap a
	and $0f
	ld l, $96
	ld [hl], a
	ld l, $97
	ld [hl], a
;>         if a & 0x08: mem[r + 0x85] |= 0x08    # a negative offset
	ld a, [bc]
	bit 3, a
	jr z, jr_000_6a55

	ld l, $85
	set 3, [hl]

jr_000_6a55:
;>         mem[r + 0x8B] = a & 0x07
	ld a, [bc]
	and $07
	ld l, $8b
	ld [hl], a
;>         mem[r + 0xA2] = u8(mem[r + 0xA2] + 1)
	ld l, $a2
	inc [hl]
;>         mem[r + 0x8A] = mem[u16(p + 1)]
	inc bc
	ld a, [bc]
	ld l, $8a
	ld [hl], a
;>         mem[r + 0xA2] = u8(mem[r + 0xA2] + 1)
;>         return
	ld l, $a2
	inc [hl]
	ret


jr_000_6a67:
;>     if a == 0xFB:                            # the loop point
;>         mem[r + 0xA2] = u8(mem[r + 0xA2] + 1)
;>         mem[r + 0xA3] = mem[r + 0xA2]
;>         p = u16(p + 1)
	ld l, $a2
	inc [hl]
	ld a, [hl]
	ld l, $a3
	ld [hl], a
	inc bc
	jr jr_000_6a35

jr_000_6a71:
;>     elif a == 0xFE:
;>         n = mem[u16(p + 1)]
;>         if n != mem[r + 0x8C]:               # again from the loop point
	inc bc
	ld a, [bc]
	ld l, $8c
	cp [hl]
	jr z, jr_000_6a85

;>             if n != 0xFF: mem[r + 0x8C] = u8(mem[r + 0x8C] + 1)
	cp $ff
	jr z, jr_000_6a7d

	inc [hl]

jr_000_6a7d:
;>             mem[r + 0xA2] = mem[r + 0xA3]
;>             return StepPitchEnvelope(ch)
	ld l, $a3
	ld a, [hl]
	ld l, $a2
	ld [hl], a
	jr StepPitchEnvelope

jr_000_6a85:
;>         mem[r + 0x8C] = 0                    # done: on after the loop
	xor a
	ld [hl], a
;>         mem[r + 0xA2] = u8(mem[r + 0xA2] + 2)
;>         p = u16(p + 3)
	ld l, $a2
	inc [hl]
	inc [hl]
	inc bc
	inc bc
	jr jr_000_6a35

;>     else: return
jr_000_6a8f:
	ret


;@ def WritePitch(ch: h)
;@ path: sound/engine/notes
;@ Writes the channel's period plus its pitch offset (minus, with flag bit 3). The
;@ engine sound (9) gets its offset from wEnginePitch instead: it rises with the speed.
;@ reads: wEnginePitch
;@ test: ch = 0xC0 | rand(0, 6); wSoundChannel = ch & 7; wSoundRegBase = (0, 5, 15, 0, 5, 10, 15)[ch & 7]; r = ch << 8; mem[r + 0x80] = rng.choice([1, 9]); mem[0xC080] = mem[0xC180] = 0
;@ sig: c1c1dd3a
WritePitch::
;> r = ch << 8
;> if mem[r + 0x80] == 9:                     # the engine sound: its pitch follows the bike's speed
	ld l, $80
	ld a, [hl]
	cp $09
	jr nz, jr_000_6aae

;>     mem16[r + 0x8A] = u16(wEnginePitch * 8)
	ld a, [wEnginePitch]
	ld c, a
	ld b, $00
	sla c
	rl b
	sla c
	rl b
	sla c
	rl b
	ld l, $8a
	ld [hl], c
	inc l
	ld [hl], b

jr_000_6aae:
;> offset = mem16[r + 0x8A]
	ld l, $8a
	ld c, [hl]
	inc l
	ld b, [hl]
;> period = mem16[r + 0x8F]
	ld l, $8f
	ld e, [hl]
	inc l
	ld d, [hl]
;> if mem[r + 0x85] & 0x08: offset = u16(-offset)
	ld l, $85
	bit 3, [hl]
	push hl
	jr z, jr_000_6ac6

	call SwapHLBC
	rst $38
	call SwapHLBC

jr_000_6ac6:
;> return WriteFrequency(u16(period + offset))   # falls through
	call SwapDEHL
	add hl, bc
	call SwapHLBC
	pop hl

;@ def WriteFrequency(period: bc)
;@ path: sound/engine/registers
;@ Writes a period (or the noise setting) to the channel's registers 3 and 4.
;@ writes: wSoundRegIndex, wSoundRegValue
;@ test: wSoundChannel = rand(0, 6); wSoundRegBase = rand(0, 15); mem[0xC080] = rng.choice([0, 3]); mem[0xC180] = rng.choice([0, 3])
;@ sig: 5a456850
WriteFrequency::
;> wSoundRegValue = lo(period)
	push bc
	ld a, c
	ld [wSoundRegValue], a
;> wSoundRegIndex = 3
	ld a, $03
	ld [wSoundRegIndex], a
;> WriteSoundReg()
	call WriteSoundReg
	pop bc
;> wSoundRegValue = hi(period)
	ld a, b
	ld [wSoundRegValue], a
;> wSoundRegIndex = 4
	ld a, $04
	ld [wSoundRegIndex], a
;> return WriteSoundReg()
	jp WriteSoundReg


;@ def SaveStreamPtr(stream: de, ch: h) -> de
;@ path: sound/engine/stream
;@ The stream goes on after this byte next time.
;@ test: ch = 0xC0 | rand(0, 6); stream = rand(0, 0xFFFF)
;@ sig: 8ab60f0f
SaveStreamPtr::
;> stream = u16(stream + 1)
	inc de
;> mem16[(ch << 8) + 0x82] = stream
	ld l, $82
	ld [hl], e
	inc l
	ld [hl], d
;> return stream
	ret


;@ def PlayRest(ch: h)
;@ path: sound/engine/notes
;@ A rest: the channel is restarted at volume 0, and marked so that the next note
;@ writes all its registers again.
;@ writes: wSoundRegIndex, wSoundRegValue
;@ test: ch = 0xC0 | rand(0, 6); wSoundChannel = ch & 7; wSoundRegBase = (0, 5, 15, 0, 5, 10, 15)[ch & 7]; mem[0xC080] = rng.choice([0, 3]); mem[0xC180] = rng.choice([0, 3])
;@ sig: e63e4af0
PlayRest::
;> mem[(ch << 8) + 0x85] |= 0xC0
	ld l, $85
	ld a, $c0
	or [hl]
	ld [hl], a
;> wSoundRegValue = 0
	ld a, $00
	ld [wSoundRegValue], a
;> wSoundRegIndex = 2
	ld a, $02
	ld [wSoundRegIndex], a
;> WriteSoundReg()                            # volume 0
	call WriteSoundReg
;> wSoundRegValue = 0x80
	ld a, $80
	ld [wSoundRegValue], a
;> wSoundRegIndex = 4
	ld a, $04
	ld [wSoundRegIndex], a
;> WriteSoundReg()                            # restart
	call WriteSoundReg
;> return
	ret


;@ def PlayDrum(stream: de)
;@ path: sound/engine/notes
;@ A note on the drum channel starts drum sound DrumSounds[pitch - 1] on the noise
;@ effect channel.
;@ test: stream = rand_ram(1); mem[stream] = rand(1, 12) << 4 | rand(0, 15); wSoundBusy = 0; wSoundPan = rand(0, 255); mem[0xC280] = 0
;@ sig: 6aa4b635
PlayDrum::
;> return PlaySound(mem[u16(DrumSounds + u8((mem[stream] >> 4) - 1))])
	ld a, [de]
	and $f0
	swap a
	dec a
	ld hl, DrumSounds
	rst $28
	ld a, [hl]
	jp PlaySound


;@ def SetDutyOrWave(ch: h)
;@ path: sound/engine/registers
;@ The channel's duty (square channels, register 1) or, on the wave channel, its wave
;@ pattern: WaveTables[n - 1] is copied to wave RAM.
;@ writes: wSoundRegIndex, wSoundRegValue
;@ reads: wSoundRegBase
;@ test: ch = 0xC0 | rand(0, 6); wSoundChannel = ch & 7; wSoundRegBase = (0, 5, 15, 0, 5, 10, 15)[ch & 7]; mem[0xC080] = rng.choice([0, 3]); mem[0xC180] = rng.choice([0, 3])
;@ sig: 9b39df3f
SetDutyOrWave::
;> v = mem[(ch << 8) + 0x92]
;> if wSoundRegBase != 0x0A:
	ld a, [wSoundRegBase]
	cp $0a
	ld l, $92
	ld a, [hl]
	jr z, jr_000_6b35

;>     wSoundRegValue = swap(v)
	swap a
	ld [wSoundRegValue], a
;>     wSoundRegIndex = 1
	ld a, $01
	ld [wSoundRegIndex], a
;>     return WriteSoundReg()
	jp WriteSoundReg


jr_000_6b35:
;> copy(0xFF30, mem16[u16(WaveTables + u8(2 * u8(v - 1)))], 16)
	dec a
	push de
	push hl
	ld hl, WaveTables
	call GetPointer
	ld b, $10
	ld de, $ff30

jr_000_6b43:
	ld a, [hl]
	ld [de], a
	inc de
	inc hl
	dec b
	jr nz, jr_000_6b43

;> return
	pop hl
	pop de
	ret


;@ def MusicChannelBlocked() -> carry
;@ path: sound/engine/registers
;@ A music channel on square 1 or 2 does not touch the hardware while an effect plays
;@ on that square channel.
;@ reads: wSfxSquare1, wSfxSquare2, wSoundChannel
;@ test: wSoundChannel = rand(0, 6); mem[0xC080] = rng.choice([0, 3]); mem[0xC180] = rng.choice([0, 3])
;@ sig: 54a28fa0
MusicChannelBlocked::
;> if wSoundChannel == 3: return wSfxSquare1[0] != 0
	ld a, [wSoundChannel]
	cp $03
	jr nz, jr_000_6b5b

	ld a, [wSfxSquare1]
	or a
	ret z

	jr jr_000_6b64

;> if wSoundChannel == 4: return wSfxSquare2[0] != 0
jr_000_6b5b:
	cp $04
	jr nz, jr_000_6b66

	ld a, [wSfxSquare2]
	or a
	ret z

jr_000_6b64:
	scf
	ret


;> return False
jr_000_6b66:
	or a
	ret


;@ def WriteSoundReg()
;@ path: sound/engine/registers
;@ Writes wSoundRegValue to the channel's register wSoundRegIndex and to its copy in
;@ wSoundRegs, if the value is new (or flag bit 6 asks for every write).
;@ reads: wSoundRegValue
;@ test: wSoundChannel = rand(0, 6); wSoundRegBase = rand(0, 15); wSoundRegIndex = rand(0, 4); mem[0xC080] = rng.choice([0, 3]); mem[0xC180] = rng.choice([0, 3])
;@ sig: 6fabc9eb
WriteSoundReg::
;> if MusicChannelBlocked(): return
	call MusicChannelBlocked
	ret c

;> shadow, hw = SoundRegAddr()
	push de
	call SoundRegAddr
;> v = wSoundRegValue
	ld a, [wSoundRegValue]
	ld c, a
;> if mem[ChannelPage() << 8 | 0x85] & 0x40 or mem[shadow] != v:
	push hl
	call ChannelPage
	ld l, $85
	bit 6, [hl]
	pop hl
	jr nz, jr_000_6b83

	ld a, [hl]
	cp c
	jr z, jr_000_6b86

jr_000_6b83:
;>     mem[shadow] = v
;>     mem[hw] = v
	ld a, c
	ld [hl], a
	ld [de], a

jr_000_6b86:
;> return
	pop de
	call ChannelPage
	ret


;@ def TriggerChannel()
;@ path: sound/engine/registers
;@ Restarts the channel's note: register 4 again from the copy, with the trigger bit.
;@ writes: wSoundRegIndex
;@ test: wSoundChannel = rand(0, 6); wSoundRegBase = rand(0, 15); mem[0xC080] = rng.choice([0, 3]); mem[0xC180] = rng.choice([0, 3])
;@ sig: f32fcfc9
TriggerChannel::
;> if MusicChannelBlocked(): return
	call MusicChannelBlocked
	ret c

	push de
;> wSoundRegIndex = 4
	ld a, $04
	ld [wSoundRegIndex], a
;> shadow, hw = SoundRegAddr()
;> mem[hw] = mem[shadow] | 0x80
	call SoundRegAddr
	ld a, [hl]
	or $80
	ld [de], a
;> return
	pop de
	call ChannelPage
	ret


;@ def SoundRegAddr() -> (hl, de)
;@ path: sound/engine/registers
;@ The register wSoundRegIndex of the channel: its copy in wSoundRegs and its address.
;@ reads: wSoundRegBase, wSoundRegIndex
;@ test: wSoundRegBase = rand(0, 15); wSoundRegIndex = rand(0, 4)
;@ sig: c5549782
SoundRegAddr::
;> n = u8(wSoundRegIndex + wSoundRegBase)
	ld a, [wSoundRegIndex]
	ld c, a
	ld a, [wSoundRegBase]
	add c
	ld c, a
	ld b, $00
;> return addr(wSoundRegs) + n, 0xFF10 + n
	ld hl, $ff10
	ld de, wSoundRegs
	add hl, bc
	call SwapDEHL
	add hl, bc
	ret


;@ def ChannelRegOffset() -> a
;@ path: sound/engine/registers
;@ The channel's first register (ChannelRegOffsets).
;@ reads: wSoundChannel
;@ test: wSoundChannel = rand(0, 6)
;@ sig: 019d06e9
ChannelRegOffset::
;> return mem[u16(ChannelRegOffsets + wSoundChannel)]
	ld a, [wSoundChannel]
	push hl
	ld hl, ChannelRegOffsets
	rst $28
	ld a, [hl]
	pop hl
	ret


;@ Each channel's first sound register as an offset from rNR10: square 1, square 2, noise for the effects; square 1, square 2, wave, noise for the music.
ChannelRegOffsets::
	db $00, $05, $0f, $00, $05, $0a, $0f

;@ def MuteForPause()
;@ path: sound/api
;@ Pausing: square 1, square 2 and noise restart at volume 0, the wave channel is muted.
;@ sig: 7bfdac91
MuteForPause::
;> rNR12 = rNR22 = rNR42 = 0x08
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
;> rNR14 = rNR24 = rNR44 = 0x80
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
;> rNR32 = 0
	ld a, $00
	ldh [rNR32], a
;> return
	ret


;@ def RestoreSoundRegs()
;@ path: sound/api
;@ After the pause: the registers come back from wSoundRegs (the noise channel's only
;@ when a sound effect plays there, not a drum).
;@ reads: wMusicHold, wPause, wSfxNoise
;@ test: wPause = rng.choice([0, 0, 1]); wMusicHold = rng.choice([0, 0, 1]); mem[0xC280] = rand(0, 20)
;@ sig: 3f61d2a0
RestoreSoundRegs::
;> if wPause or wMusicHold: return
	ld a, [wPause]
	ld b, a
	ld a, [wMusicHold]
	or b
	ret nz

;> CopySoundRegs(addr(wSoundRegs), 0xFF10, 5)          # square 1
	ld hl, wSoundRegs
	ld de, $ff10
	ld b, $05
	call CopySoundRegs
;> CopySoundRegs(addr(wSoundRegs) + 6, 0xFF16, 4)      # square 2
	ld hl, $c206
	ld de, $ff16
	ld b, $04
	call CopySoundRegs
;> CopySoundRegs(addr(wSoundRegs) + 10, 0xFF1A, 5)     # wave
	ld hl, $c20a
	ld de, $ff1a
	ld b, $05
	call CopySoundRegs
;> if wSfxNoise[0] < 8: return
	ld a, [wSfxNoise]
	cp $08
	ret c

;> return CopySoundRegs(addr(wSoundRegs) + 16, 0xFF20, 4)   # noise; falls through
	ld hl, $c210
	ld de, $ff20
	ld b, $04

;@ def CopySoundRegs(src: hl, dest: de, n: b)
;@ path: sound/engine/registers
;@ Copies n bytes (sound registers from their copies).
;@ test: src = rand_ram(8); dest = rand_ram(8); n = rand(1, 8)
;@ sig: a294ddd4
CopySoundRegs::
;> copy(dest, src, n or 256)
	ld a, [hl]
	ld [de], a
	inc hl
	inc de
	dec b
	jr nz, CopySoundRegs

;> return
	ret


;@ def PlaySound(id: a)
;@ path: sound/api
;@ Starts sound id (0 stops everything). The timer interrupt leaves the channels alone
;@ meanwhile (wSoundBusy); all registers are kept.
;@ test: id = rand(0, 32); wSoundBusy = 0; wSoundPan = rand(0, 255)
;@ sig: 35c4377d
PlaySound::
	push hl
;> wSoundBusy |= 0x01
	ld hl, wSoundBusy
	set 0, [hl]
;> StartSound(id)
	push de
	push bc
	push af
	call StartSound
	pop af
	pop bc
	pop de
;> wSoundBusy &= 0xFE
	ld hl, wSoundBusy
	res 0, [hl]
;> return
	pop hl
	ret


;@ def StartSound(id: a)
;@ path: sound/engine/start
;@ Starts sound id from its header in Sounds: its priority, then a channel mask and a
;@ stream for every channel in it. A channel takes the stream only if the sound's
;@ priority is at least that of the sound playing there.
;@ writes: wSoundId, wSoundPriority
;@ reads: wSoundPan
;@ test: id = rand(0, 32); wSoundPan = rand(0, 255)
;@ sig: 93b44c67
StartSound::
;> wSoundId = id
;> if not id: return StopAllSound()
	ld [wSoundId], a
	or a
	jp z, StopAllSound

;> hdr = mem16[u16(Sounds + u8(2 * u8(id - 1)))]
	dec a
	ld hl, Sounds
	add a
	ld e, a
	ld d, $00
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld l, e
	ld h, d
;> wSoundPriority = mem[hdr]
	ld a, [hl]
	ld [wSoundPriority], a
;> pos = u16(hdr + 1)
;> mask = mem[pos]
	inc hl
	ld a, [hl]
;> for bit, start in enumerate((StartSfxSquare1, StartSfxSquare2, StartSfxNoise, StartMusicSquare1, StartMusicSquare2, StartMusicWave, StartMusicDrums)):
;>     if mask >> bit & 1: pos = start(pos)
	srl a
	call c, StartSfxSquare1
	srl a
	call c, StartSfxSquare2
	srl a
	call c, StartSfxNoise
	srl a
	call c, StartMusicSquare1
	srl a
	call c, StartMusicSquare2
	srl a
	call c, StartMusicWave
	srl a
	call c, StartMusicDrums
;> rNR51 = wSoundPan
	ld hl, $ff25
	ld a, [wSoundPan]
	ld [hl], a
;> return
	ret


;@ def StartSfxSquare1(pos: hl) -> hl
;@ path: sound/engine/start
;@ The next stream of the header goes to channel 0 (square 1 effects): the sweep off,
;@ square 1 on both speakers.
;@ writes: wSoundPan
;@ reads: wSoundPan
;@ test: pos = rand_ram(3); wSoundPriority = rand(0, 255); wSoundId = rand(1, 32)
;@ sig: b334a8e7
StartSfxSquare1::
;> rNR10 = 8                                  # no sweep
	push af
	ld a, $08
	ld bc, $ff10
	ld [bc], a
;> wSoundRegs[0] = 8
	ld bc, wSoundRegs
	ld [bc], a
;> wSoundPan = (wSoundPan & 0xEE) | 0x11
	ld a, [wSoundPan]
	and $ee
	or $11
	ld [wSoundPan], a
;> return StartChannel(pos, addr(wSfxSquare1))   # falls through
	ld de, wSfxSquare1

;@ def StartChannel(pos: hl, rec: de) -> hl
;@ path: sound/engine/start
;@ Gives the stream after pos in the header to the channel record rec, if the sound's
;@ priority is high enough: the note counter at 1 reads it on the next tick, and flag
;@ bit 6 makes the first note write every register. Returns the header position.
;@ reads: wSoundId, wSoundPriority
;@ test: skip pops the af its callers (the channel starters) pushed
;@ sig: 5a6b158d
StartChannel::
;> pos = u16(pos + 1)
;> stream = mem16[pos]
;> pos = u16(pos + 1)
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
;> if wSoundPriority >= mem[u16(rec + 1)]:
	push hl
	ld hl, $0001
	add hl, de
	ld a, [wSoundPriority]
	cp [hl]
	jr c, jr_000_6cbd

;>     mem[rec + 1] = wSoundPriority
	ld [hl], a
;>     mem[rec] = wSoundId
	ld a, [wSoundId]
	ld [de], a
;>     mem16[rec + 2] = stream
	inc hl
	ld [hl], c
	inc hl
	ld [hl], b
;>     mem[rec + 4] = 1                           # read on the next tick
	inc hl
	ld [hl], $01
;>     mem[rec + 5] = 0x40                        # and write every register
	inc hl
	ld [hl], $40
;>     fill(rec + 6, 0, 7)
	inc hl
	ld e, l
	inc e
	ld d, h
	ld bc, $0006
	ld [hl], $00
	call CopyBytes

jr_000_6cbd:
;> return pos
	pop hl
	pop af
	ret


;@ def StartSfxSquare2(pos: hl) -> hl
;@ path: sound/engine/start
;@ The next stream goes to channel 1 (square 2 effects), on both speakers.
;@ writes: wSoundPan
;@ reads: wSoundPan
;@ test: pos = rand_ram(3); wSoundPriority = rand(0, 255); wSoundId = rand(1, 32)
;@ sig: 36de1919
StartSfxSquare2::
	push af
;> wSoundPan = (wSoundPan & 0xDD) | 0x22
	ld a, [wSoundPan]
	and $dd
	or $22
	ld [wSoundPan], a
;> return StartChannel(pos, addr(wSfxSquare2))
	ld de, wSfxSquare2
	jp StartChannel


;@ def StartMusicSquare1(pos: hl) -> hl
;@ path: sound/engine/start
;@ The next stream goes to channel 3 (music on square 1); the sweep goes off unless an
;@ effect plays on square 1.
;@ writes: wSoundPan
;@ reads: wSfxSquare1, wSoundPan
;@ test: pos = rand_ram(3); wSoundPriority = rand(0, 255); wSoundId = rand(1, 32); mem[0xC080] = rng.choice([0, 3])
;@ sig: fda9ea3d
StartMusicSquare1::
	push af
;> if not wSfxSquare1[0]:
	ld a, [wSfxSquare1]
	or a
	jr nz, jr_000_6ce2

;>     rNR10 = 8
	ld a, $08
	ld bc, $ff10
	ld [bc], a
;>     wSoundRegs[0] = 8
	ld bc, wSoundRegs
	ld [bc], a

jr_000_6ce2:
;> wSoundPan = (wSoundPan & 0xEE) | 0x11
	ld a, [wSoundPan]
	and $ee
	or $11
	ld [wSoundPan], a
;> return StartChannel(pos, addr(wMusicSquare1))
	ld de, wMusicSquare1
	jp StartChannel


;@ def StartMusicSquare2(pos: hl) -> hl
;@ path: sound/engine/start
;@ The next stream goes to channel 4 (music on square 2).
;@ writes: wSoundPan
;@ reads: wSoundPan
;@ test: pos = rand_ram(3); wSoundPriority = rand(0, 255); wSoundId = rand(1, 32)
;@ sig: 0100e92b
StartMusicSquare2::
	push af
;> wSoundPan = (wSoundPan & 0xDD) | 0x22
	ld a, [wSoundPan]
	and $dd
	or $22
	ld [wSoundPan], a
;> return StartChannel(pos, addr(wMusicSquare2))
	ld de, wMusicSquare2
	jp StartChannel


;@ def StartMusicWave(pos: hl) -> hl
;@ path: sound/engine/start
;@ The next stream goes to channel 5 (music on the wave channel).
;@ writes: wSoundPan
;@ reads: wSoundPan
;@ test: pos = rand_ram(3); wSoundPriority = rand(0, 255); wSoundId = rand(1, 32)
;@ sig: a22a3391
StartMusicWave::
	push af
;> wSoundPan = (wSoundPan & 0xBB) | 0x44
	ld a, [wSoundPan]
	and $bb
	or $44
	ld [wSoundPan], a
;> return StartChannel(pos, addr(wMusicWave))
	ld de, wMusicWave
	jp StartChannel


;@ def StartSfxNoise(pos: hl) -> hl
;@ path: sound/engine/start
;@ The next stream goes to channel 2 (noise effects and drums).
;@ writes: wSoundPan
;@ reads: wSoundPan
;@ test: pos = rand_ram(3); wSoundPriority = rand(0, 255); wSoundId = rand(1, 32)
;@ sig: 08d07096
StartSfxNoise::
	push af
;> wSoundPan = (wSoundPan & 0x77) | 0x88
	ld a, [wSoundPan]
	and $77
	or $88
	ld [wSoundPan], a
;> return StartChannel(pos, addr(wSfxNoise))
	ld de, wSfxNoise
	jp StartChannel


;@ def StartMusicDrums(pos: hl) -> hl
;@ path: sound/engine/start
;@ The next stream goes to channel 6, the music's drum track.
;@ test: pos = rand_ram(3); wSoundPriority = rand(0, 255); wSoundId = rand(1, 32)
;@ sig: 0ce1c6c5
StartMusicDrums::
	push af
;> return StartChannel(pos, addr(wMusicDrums))
	ld de, wMusicDrums
	jp StartChannel


;@ def StopAllSound()
;@ path: sound/engine/start
;@ Sound 0: clears all seven channel records, the register copies and the engine's
;@ variables, and silences the four channels.
;@ sig: 9a035f49
StopAllSound::
;> for rec in (0xC080, 0xC180, 0xC280, 0xC380, 0xC480, 0xC580, 0xC680):
;>     fill(rec, 0, 0x25)
	ld hl, wSfxSquare1
	ld de, $c081
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wSfxSquare2
	ld de, $c181
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wSfxNoise
	ld de, $c281
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wMusicSquare1
	ld de, $c381
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wMusicSquare2
	ld de, $c481
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wMusicWave
	ld de, $c581
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
	ld hl, wMusicDrums
	ld de, $c681
	ld bc, $0024
	ld [hl], $00
	call CopyBytes
;> fill(addr(wSoundRegs), 0, 0x15)
	ld hl, wSoundRegs
	ld de, $c201
	ld bc, $0014
	ld [hl], $00
	call CopyBytes
;> fill(addr(wSoundChannel), 0, 0x0E)           # wSoundChannel ... wEnginePitch
	ld hl, wSoundChannel
	ld de, wSoundRegBase
	ld bc, $000d
	ld [hl], $00
	call CopyBytes
;> rNR12 = 0
;> rNR14 = 0x80
	ld hl, $ff12
	ld [hl], $00
	ld hl, $ff14
	ld [hl], $80
;> rNR22 = 0
;> rNR24 = 0x80
	ld hl, $ff17
	ld [hl], $00
	ld hl, $ff19
	ld [hl], $80
;> rNR32 = 0
	ld hl, $ff1c
	ld [hl], $00
;> rNR42 = 0
;> rNR44 = 0x80
	ld hl, $ff21
	ld [hl], $00
	ld hl, $ff23
	ld [hl], $80
;> return
	ret


;@ The period values of 96 notes (8 octaves of 12), for the square and wave channels' frequency registers.
NotePeriods::
	db $20, $00, $92, $00, $fe, $00, $64, $01, $c4, $01, $1e, $02, $73, $02, $c3, $02
	db $0f, $03, $57, $03, $9a, $03, $d9, $03, $15, $04, $4d, $04, $83, $04, $b5, $04
	db $e4, $04, $11, $05, $3b, $05, $63, $05, $88, $05, $ac, $05, $cd, $05, $ed, $05
	db $0b, $06, $27, $06, $42, $06, $5b, $06, $73, $06, $8a, $06, $9f, $06, $b3, $06
	db $c6, $06, $d8, $06, $e9, $06, $f8, $06, $07, $07, $15, $07, $22, $07, $2f, $07
	db $3a, $07, $45, $07, $50, $07, $5a, $07, $63, $07, $6c, $07, $74, $07, $7c, $07
	db $84, $07, $8b, $07, $91, $07, $97, $07, $9d, $07, $a3, $07, $a9, $07, $ad, $07
	db $b2, $07, $b6, $07, $ba, $07, $be, $07, $c2, $07, $c4, $07, $c8, $07, $cb, $07
	db $ce, $07, $d1, $07, $d3, $07, $d6, $07, $d8, $07, $da, $07, $dc, $07, $de, $07
	db $e0, $07, $e2, $07, $e4, $07, $e5, $07, $e7, $07, $e8, $07, $e9, $07, $eb, $07
	db $ec, $07, $ed, $07, $ee, $07, $ef, $07, $f0, $07, $f1, $07, $f2, $07, $f2, $07
	db $f3, $07, $f4, $07, $f4, $07, $f5, $07, $f6, $07, $f6, $07, $f7, $07, $f7, $07


;@ Pointers to the nine 32-sample wave patterns of the wave channel (command $EA $3n / $E0 picks one).
WaveTables::
	db $a0, $6e, $b0, $6e, $c0, $6e, $d0, $6e, $e0, $6e, $f0, $6e, $00, $6f, $10, $6f
	db $20, $6f


Wave1::
	db $88, $88, $8f, $f8, $80, $00, $88, $88, $ff, $f8, $00, $88, $88, $ff, $88, $00


Wave2::
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $01, $23, $45, $67, $89, $ab, $cd, $ef


Wave3::
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $fe, $dc, $ba, $98, $76, $54, $32, $10


Wave4::
	db $02, $46, $8a, $ce, $fd, $b9, $75, $31, $02, $46, $8a, $ce, $fd, $b9, $75, $31


Wave5::
	db $01, $23, $45, $67, $89, $ab, $cd, $ef, $02, $46, $8a, $ce, $fd, $b9, $75, $31


Wave6::
	db $88, $80, $8f, $ff, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00


Wave7::
	db $bd, $db, $98, $9c, $ef, $eb, $76, $68, $aa, $94, $21, $24, $88, $53, $35, $8b


Wave8::
	db $7e, $c9, $ce, $a7, $cf, $e8, $ab, $72, $8d, $75, $72, $03, $85, $13, $63, $17


Wave9::
	db $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0


;@ The 32 sounds, by id - 1: 1-7 drum hits, 8-24 sound effects, 25-32 music. Each header is a priority, a channel mask (bit n = channel n), then one stream pointer per channel.
Sounds::
	db $0f, $70, $13, $70, $17, $70, $1b, $70, $1f, $70, $23, $70, $27, $70, $70, $6f
	db $74, $6f, $78, $6f, $7e, $6f, $84, $6f, $8a, $6f, $8e, $6f, $92, $6f, $98, $6f
	db $9e, $6f, $a4, $6f, $a8, $6f, $ac, $6f, $b0, $6f, $b4, $6f, $b8, $6f, $be, $6f
	db $c2, $6f, $d6, $6f, $cc, $6f, $e0, $6f, $ea, $6f, $f0, $6f, $f6, $6f, $fc, $6f


;@ Sound 8 ($08): priority $80, on channel 1.
SfxPause::
	db $80, $02, $c8, $70


;@ Sound 9 ($09): priority $08, on channel 3.
SfxEngine::
	db $08, $08, $d3, $70


;@ Sound 10 ($0A): priority $04, on channels 0, 2.
SfxNitro::
	db $04, $05, $0c, $71, $23, $71


;@ Sound 11 ($0B): priority $04, on channels 0, 2.
SfxAirNitro::
	db $04, $05, $e2, $70, $f8, $70


;@ Sound 12 ($0C): priority $04, on channels 0, 2.
SfxNitroEmpty::
	db $04, $05, $3b, $72, $44, $72


;@ Sound 13 ($0D): priority $04, on channel 0.
SfxItem::
	db $04, $01, $32, $71


;@ Sound 14 ($0E): priority $04, on channel 0.
SfxClock::
	db $04, $01, $44, $71


;@ Sound 15 ($0F): priority $04, on channels 0, 1.
SfxPowerUp::
	db $04, $03, $4e, $72, $62, $72


;@ Sound 16 ($10): priority $04, on channels 1, 5.
SfxStartLight::
	db $04, $22, $6c, $71, $80, $71


;@ Sound 17 ($11): priority $04, on channels 1, 5.
SfxStartGo::
	db $04, $22, $72, $71, $86, $71


;@ Sound 18 ($12): priority $08, on channel 0.
SfxHurryUp::
	db $08, $01, $8c, $71


;@ Sound 19 ($13): priority $03, on channel 2.
SfxSpray::
	db $03, $04, $b9, $71


;@ Sound 20 ($14): priority $04, on channel 2.
SfxFlip::
	db $04, $04, $c6, $71


;@ Sound 21 ($15): priority $04, on channel 0.
SfxCursor::
	db $04, $01, $ed, $71


;@ Sound 22 ($16): priority $04, on channel 2.
SfxCrash::
	db $04, $04, $d7, $71


;@ Sound 23 ($17): priority $04, on channels 0, 2.
SfxSelect::
	db $04, $05, $f5, $71, $03, $72


;@ Sound 24 ($18): priority $08, on channel 2.
SfxFinish::
	db $08, $04, $14, $72


;@ Sound 25 ($19): priority $10, on channels 3, 4, 5, 6.
MusicCourseSelect::
	db $10, $78, $be, $72, $79, $72, $06, $73, $57, $73


;@ Sound 27 ($1B): priority $10, on channels 3, 4, 5, 6.
MusicNewRecord::
	db $10, $78, $28, $75, $7d, $75, $b0, $74, $ee, $75


;@ Sound 26 ($1A): priority $10, on channels 3, 4, 5, 6.
MusicFinish::
	db $10, $78, $da, $73, $67, $73, $45, $74, $8b, $74


;@ Sound 28 ($1C): priority $10, on channels 3, 4, 5, 6.
MusicGameOver::
	db $10, $78, $70, $76, $1c, $76, $bf, $76, $ec, $76


;@ Sound 29 ($1D): priority $10, on channels 4, 5.
MusicCourse1::
	db $10, $30, $0c, $77, $09, $78


;@ Sound 30 ($1E): priority $10, on channels 4, 5.
MusicCourse2::
	db $10, $30, $cb, $78, $f3, $79


;@ Sound 31 ($1F): priority $10, on channels 4, 5.
MusicCourse3::
	db $10, $30, $66, $7b, $bd, $7a


;@ Sound 32 ($20): priority $10, on channels 4, 5.
MusicCourse4::
	db $10, $30, $a6, $7c, $24, $7e


;@ The drum channel's notes: note n (high nibble) starts drum sound DrumSounds[n - 1] on the noise channel.
DrumSounds::
	db $01, $02, $01, $03, $03, $03, $03, $04, $05, $06, $07, $07, $07


;@ Sound 1 ($01): priority $01, on channel 2.
Drum1::
	db $01, $04, $2b, $70


;@ Sound 2 ($02): priority $01, on channel 2.
Drum2::
	db $01, $04, $30, $70


;@ Sound 3 ($03): priority $01, on channel 2.
Drum3::
	db $01, $04, $35, $70


;@ Sound 4 ($04): priority $01, on channel 2.
Drum4::
	db $01, $04, $3e, $70


;@ Sound 5 ($05): priority $01, on channel 2.
Drum5::
	db $01, $04, $49, $70


;@ Sound 6 ($06): priority $01, on channel 2.
Drum6::
	db $01, $04, $52, $70


;@ Sound 7 ($07): priority $01, on channel 2.
Drum7::
	db $01, $04, $5b, $70


Drum1Noise::
	db $e0, $01, $42, $31, $ff


Drum2Noise::
	db $e0, $07, $61, $31, $ff


Drum3Noise::
	db $e0, $01, $61, $31, $e0, $40, $f4, $00, $ff


Drum4Noise::
	db $e0, $01, $f1, $44, $44, $e0, $40, $03, $85, $36, $ff


Drum5Noise::
	db $e0, $01, $61, $40, $e0, $08, $63, $10, $ff


Drum6Noise::
	db $e0, $01, $f4, $34, $e0, $40, $63, $43, $ff


Drum7Noise::
	db $e0, $01, $71, $36, $23, $ff


;@ Pointers to the 15 pitch envelopes (command $EA $2n): steps of (speed, offset) that bend a note, for vibrato and slides.
PitchEnvelopes::
	db $7f, $70, $82, $70, $85, $70, $7f, $70, $7f, $70, $7f, $70, $7f, $70, $7f, $70
	db $93, $70, $95, $70, $7f, $70, $a2, $70, $88, $70, $7f, $70, $af, $70


PitchEnvelope1::
	db $10, $01, $ff


PitchEnvelope2::
	db $18, $01, $ff


PitchEnvelope3::
	db $18, $02, $ff


PitchEnvelope13::
	db $f0, $00, $20, $01, $fb, $30, $02, $30, $00, $fe, $ff


PitchEnvelope9::
	db $80, $00


PitchEnvelope10::
	db $e0, $00, $20, $01, $20, $02, $fb, $40, $03, $40, $00, $fe, $ff


PitchEnvelope12::
	db $60, $00, $10, $01, $10, $02, $fb, $20, $03, $20, $00, $fe, $ff


PitchEnvelope15::
	db $10, $01, $10, $02, $10, $03, $10, $04, $10, $05, $10, $06, $10, $07, $10, $08
	db $10, $09, $10, $0a, $10, $0b, $10, $0c, $ff


SfxPauseSq2::
	db $e0, $06, $8f, $f5, $e4, $51, $81, $51, $81, $d3, $ff


SfxEngineSq1::
	db $e0, $01, $38, $00, $e1


SfxEngineSq1_Loop::
	db $ea, $3c, $71, $ea, $34, $81, $fe, $ff, $d8, $70


SfxAirNitroSq1::
	db $e0, $07, $4f, $00, $e9, $1c, $e2, $11, $e3, $f2, $d1, $e0, $06, $86, $f7, $e9
	db $08, $e6, $ea, $2f, $d8, $ff


SfxAirNitroNoise::
	db $e0, $01, $f4, $34, $e0, $09, $f5, $46, $34, $e0, $09, $f6, $27, $26, $25, $14
	db $13, $12, $11, $ff


SfxNitroSq1::
	db $e0, $07, $4f, $00, $e9, $1c, $e2, $11, $e3, $f2, $d1, $f8, $c1, $e0, $07, $44
	db $00, $a1, $f2, $91, $f3, $91, $ff


SfxNitroNoise::
	db $e0, $01, $f4, $34, $e0, $09, $f5, $46, $56, $55, $56, $55, $52, $52, $ff


SfxItemSq1::
	db $e0, $01, $8f, $f1, $e3, $fe, $ff, $4c, $71


SfxItemSq1_Sub1::
	db $11, $31, $51, $61, $81, $a1, $c1, $d1, $fc


SfxClockSq1::
	db $e0, $01, $0f, $f1, $e4, $fd, $3b, $71


SfxItemSq1_Loop::
	db $fb, $fd, $3b, $71, $fe, $02, $ea, $01, $f2, $fd, $3b, $71, $ea, $02, $f4, $fd
	db $3b, $71, $ea, $03, $f8, $fd, $3b, $71, $ff


SfxStartLightSq2_Sub1::
	db $ea, $21, $e0, $09, $4d, $f4, $fc


SfxStartLightSq2::
	db $fd, $65, $71, $e3, $a4, $ff


SfxStartGoSq2::
	db $fd, $65, $71, $e4, $a6, $ff


SfxStartLightWave_Sub1::
	db $e0, $01, $46, $00, $01, $e7, $09, $fc


SfxStartLightWave::
	db $fd, $78, $71, $e3, $a4, $ff


SfxStartGoWave::
	db $fd, $78, $71, $e4, $a6, $ff


SfxHurryUpSq1::
	db $fb, $e0, $01, $0c, $00, $e5, $31, $ea, $38, $41, $51, $61, $71, $71, $71, $71
	db $71, $71, $71, $71, $71, $71, $71, $71, $f5, $41, $41, $f4, $41, $41, $41, $41
	db $41, $41, $f5, $41, $41, $41, $41, $41, $41, $f0, $fe, $04, $ff


SfxSprayNoise::
	db $e0, $01, $61, $06, $e0, $10, $89, $01, $e0, $1f, $84, $00, $ff


SfxFlipNoise::
	db $e0, $01, $f4, $34, $e0, $08, $63, $43, $e0, $01, $61, $31, $e0, $10, $84, $00
	db $ff


SfxCrashNoise::
	db $e0, $03, $86, $41, $47, $41, $46, $41, $45, $41, $44, $41, $45, $41, $46, $41
	db $44, $41, $45, $41, $46, $ff


SfxCursorSq1::
	db $e0, $01, $86, $f1, $e5, $11, $d1, $ff


SfxSelectSq1::
	db $e0, $01, $4f, $00, $e1, $41, $11, $51, $11, $61, $11, $71, $11, $ff


SfxSelectNoise::
	db $e0, $01, $f4, $34, $e0, $08, $63, $46, $e0, $01, $61, $31, $e0, $10, $84, $32
	db $ff


SfxFinishNoise::
	db $e0, $08, $49, $55, $54, $53, $52, $51, $50, $e0, $08, $09, $41, $42, $43, $44
	db $42, $41, $42, $44, $45, $46, $47, $46, $45, $44, $42, $44, $e0, $08, $c7, $45
	db $46, $45, $44, $43, $42, $41, $ff


SfxNitroEmptySq1::
	db $e0, $01, $84, $00, $e6, $a2, $02, $d2, $ff


SfxNitroEmptyNoise::
	db $e0, $01, $f0, $33, $e0, $02, $c1, $13, $14, $ff


SfxPowerUpSq1::
	db $e0, $06, $4d, $f1, $e4, $91, $d1, $e5, $41, $f5, $fb, $e4, $91, $d1, $e5, $41
	db $f9, $fe, $02, $ff


SfxPowerUpSq2::
	db $e0, $06, $4b, $f1, $ea, $22, $e4, $01, $91, $d1, $e5, $41, $f5, $fb, $e4, $91
	db $d1, $e5, $41, $f9, $fe, $02, $ff


MusicCourseSelectSq2::
	db $ee, $18


MusicCourseSelectSq2_Loop::
	db $fb, $fd, $a2, $72, $ef, $f0, $e8, $f1, $e4, $33, $ef, $0f, $e8, $f3, $33, $fd
	db $a2, $72, $ef, $f0, $e8, $f1, $e4, $43, $ef, $0f, $e8, $f3, $33, $ea, $06, $fe
	db $02, $ea, $00, $fe, $ff, $7b, $72


MusicCourseSelectSq2_Sub1::
	db $ef, $ff, $e0, $07, $4a, $f1, $e3, $81, $81, $a2, $b2, $a2, $b2, $a1, $b2, $e8
	db $f2, $83, $b3, $e8, $f1, $b3, $e8, $f3, $d4, $ea, $30, $fc


MusicCourseSelectSq1::
	db $fb, $fd, $e7, $72, $ef, $f0, $e8, $f1, $a3, $ef, $0f, $e7, $04, $e8, $f3, $a5
	db $fd, $e7, $72, $ef, $f0, $e8, $f1, $b3, $ef, $0f, $e7, $04, $e8, $f3, $a5, $ea
	db $06, $fe, $02, $ea, $00, $fe, $ff, $be, $72


MusicCourseSelectSq1_Sub1::
	db $ef, $ff, $e0, $01, $c9, $f1, $01, $e7, $07, $e3, $31, $31, $52, $62, $52, $62
	db $51, $62, $e8, $f2, $33, $63, $e8, $f1, $63, $e8, $f3, $84, $ea, $30, $fc


MusicCourseSelectWave::
	db $fb, $fd, $2f, $73, $ef, $f0, $f0, $82, $f2, $81, $ef, $0f, $f0, $82, $f2, $81
	db $fd, $2f, $73, $ef, $f0, $f0, $92, $f2, $91, $ef, $0f, $f0, $82, $f2, $81, $ea
	db $06, $fe, $02, $ea, $00, $fe, $ff, $06, $73


MusicCourseSelectWave_Sub1::
	db $e0, $07, $72, $a3, $f0, $ef, $ff, $e3, $12, $f2, $11, $f0, $12, $f2, $11, $f0
	db $12, $f2, $11, $f0, $12, $f2, $11, $f0, $12, $f2, $12, $f0, $42, $f2, $41, $f0
	db $42, $f2, $41, $f0, $62, $f2, $62, $fc


MusicCourseSelectDrums::
	db $e0, $07


MusicCourseSelectDrums_Loop::
	db $b1, $11, $11, $b1, $11, $11, $fb, $11, $fe, $1a, $fe, $ff, $59, $73


MusicFinishSq2::
	db $ee, $20, $e0, $01, $8a, $00, $ef, $f0, $e3, $84, $a4, $c4, $ef, $0f, $d4, $e4
	db $34, $54, $64, $84, $a4, $c4, $e5, $14, $34, $e0, $06, $8a, $83, $52, $e0, $06
	db $4a, $f1, $ef, $ff, $e4, $61, $61, $62, $51, $31, $f3, $e3, $81, $f0, $e4, $31
	db $e8, $f2, $53, $e8, $f1, $51, $11, $e3, $81, $fb, $e4, $61, $f1, $31, $e3, $b1
	db $f0, $fe, $02, $e4, $61, $f1, $31, $fb, $f0, $81, $f1, $51, $11, $fe, $02, $f0
	db $81, $f1, $51, $e8, $f2, $b3, $92, $e0, $06, $8a, $f1, $e3, $21, $61, $91, $e4
	db $21, $e3, $91, $61, $21, $e3, $91, $61, $21, $e2, $91, $e8, $f1, $e4, $52, $e3
	db $11, $12, $ff


MusicFinishSq1::
	db $e0, $01, $89, $00, $ef, $f0, $e2, $c4, $d4, $e3, $34, $54, $64, $84, $ef, $0f
	db $a4, $c4, $d4, $e4, $34, $54, $64, $e0, $06, $49, $83, $e4, $82, $e8, $f1, $ef
	db $ff, $e4, $11, $11, $12, $11, $e3, $c1, $f3, $e3, $11, $f0, $c1, $e8, $f2, $d3
	db $e8, $f1, $d1, $81, $51, $e2, $a1, $62, $e3, $32, $61, $e2, $b2, $e3, $51, $12
	db $82, $51, $d2, $e4, $81, $41, $e3, $b1, $e4, $62, $ea, $22, $f1, $ef, $0f, $e8
	db $f1, $e3, $22, $61, $91, $e4, $21, $e3, $91, $61, $21, $91, $61, $21, $ef, $ff
	db $f0, $ea, $20, $e8, $f1, $e3, $82, $e2, $81, $82, $ff


MusicFinishWave::
	db $e0, $01, $72, $00, $e4, $54, $64, $84, $a4, $c4, $d4, $e5, $34, $54, $64, $84
	db $a4, $c4, $e0, $06, $32, $f3, $e3, $11, $11, $fb, $d1, $11, $fe, $05, $11, $d1
	db $81, $11, $e2, $b1, $b2, $b2, $e3, $b1, $61, $e2, $b1, $e3, $11, $12, $12, $d1
	db $81, $11, $e8, $f6, $43, $22, $e8, $f3, $21, $fb, $e4, $21, $e3, $21, $fe, $05
	db $e4, $12, $e3, $11, $12, $ff


MusicFinishDrums::
	db $e0, $06, $08, $fb, $b1, $11, $91, $11, $fe, $02, $b2, $91, $b2, $b1, $92, $fb
	db $11, $11, $11, $11, $fe, $04, $91, $11, $11, $91, $fb, $11, $11, $11, $11, $fe
	db $03, $92, $b1, $b1, $ff


MusicNewRecordWave::
	db $ee, $20, $ef, $f0, $fb, $e0, $06, $82, $f4, $e5, $a1, $11, $a1, $e8, $f8, $83
	db $fe, $02, $e8, $f4, $81, $e4, $b1, $e5, $41, $81, $ef, $0f, $fb, $e8, $f4, $e5
	db $d1, $41, $d1, $e8, $f8, $b3, $fe, $02, $ef, $ff, $ee, $40, $e0, $01, $82, $f3
	db $e4, $b3, $93, $73, $93, $b3, $c3, $e5, $23, $43, $ee, $18, $e0, $06, $22, $f5
	db $e4, $73, $63, $93, $73, $62, $22, $c3, $b2, $e0, $06, $72, $f3, $e5, $21, $e4
	db $c1, $e5, $21, $41, $61, $71, $91, $b1, $c1, $ea, $21, $e6, $21, $41, $ea, $20
	db $e8, $92, $ea, $32, $fb, $e4, $72, $71, $61, $f2, $62, $f0, $ef, $0f, $fe, $02
	db $ef, $ff, $e3, $21, $21, $21, $22, $ff


MusicNewRecordSq1::
	db $e0, $06, $49, $f3, $e3, $63, $43, $63, $43, $e4, $41, $e3, $81, $b1, $e4, $41
	db $e3, $93, $73, $93, $73, $e0, $01, $89, $f3, $73, $53, $33, $53, $73, $93, $b3
	db $c3, $e0, $06, $49, $f2, $e3, $b3, $93, $f1, $e4, $63, $e3, $b3, $e8, $f2, $92
	db $62, $e4, $43, $22, $e8, $f2, $e3, $b1, $91, $b1, $c1, $e4, $21, $41, $61, $71
	db $91, $b1, $c1, $e8, $f1, $fb, $b2, $b1, $93, $ef, $0f, $fe, $02, $ef, $ff, $e2
	db $61, $61, $61, $62, $ff


MusicNewRecordSq2::
	db $e0, $06, $49, $f3, $e2, $d3, $b3, $d3, $b3, $e3, $b1, $41, $81, $b1, $e3, $43
	db $23, $43, $23, $e0, $01, $8a, $f3, $e3, $23, $e2, $c3, $a3, $c3, $e3, $23, $33
	db $53, $73, $e0, $06, $0a, $50, $fb, $ef, $f0, $e2, $21, $91, $e3, $21, $ef, $0f
	db $e2, $21, $91, $e3, $21, $fe, $02, $ef, $f0, $e2, $21, $91, $e3, $21, $e2, $21
	db $fb, $ef, $0f, $e2, $71, $e3, $21, $71, $ef, $f0, $e2, $71, $e3, $21, $71, $fe
	db $02, $ef, $0f, $e2, $71, $e3, $21, $71, $e2, $71, $ef, $ff, $fb, $f0, $e3, $21
	db $f5, $21, $f0, $21, $21, $f5, $21, $21, $fe, $02, $f0, $e2, $21, $21, $21, $22
	db $ff


MusicNewRecordDrums::
	db $e0, $06, $fb, $b1, $b2, $b1, $92, $b1, $b2, $b1, $92, $11, $11, $11, $11, $fe
	db $02, $b2, $92, $b2, $91, $b2, $b1, $92, $b2, $92, $b2, $92, $b2, $91, $b2, $b1
	db $92, $b2, $92, $12, $11, $93, $12, $11, $93, $b1, $b1, $b1, $b2, $ff


MusicGameOverSq2::
	db $ee, $20, $e0, $06, $49, $f1, $e3, $31, $32, $31, $51, $52, $51, $82, $81, $a3
	db $e0, $01, $49, $f8, $e4, $3f, $01, $ef, $f0, $e8, $f1, $64, $b4, $e5, $34, $64
	db $b4, $ef, $0f, $e6, $34, $e5, $b4, $64, $ef, $f0, $34, $e4, $b4, $64, $ef, $ff
	db $f0, $e0, $06, $89, $f2, $e3, $c1, $a1, $81, $51, $e2, $c1, $e3, $31, $81, $52
	db $ee, $50, $01, $ee, $60, $e8, $f2, $e4, $51, $e8, $00, $f4, $51, $f5, $51, $f6
	db $51, $f7, $51, $ff


MusicGameOverSq1::
	db $e0, $06, $48, $f1, $e2, $a1, $a2, $a1, $c1, $c2, $c1, $e3, $32, $31, $53, $e0
	db $01, $48, $f7, $f4, $bf, $ef, $f0, $e8, $00, $e4, $69, $b4, $e5, $34, $64, $ef
	db $0f, $b4, $e6, $34, $e5, $b4, $ef, $f0, $64, $34, $e4, $b4, $ef, $ff, $f0, $e0
	db $06, $88, $f2, $e3, $81, $51, $31, $e2, $c1, $71, $a1, $e3, $31, $e2, $c2, $01
	db $e8, $f2, $e5, $51, $e8, $00, $f4, $51, $f5, $51, $f6, $51, $f7, $51, $ff


MusicGameOverWave::
	db $e0, $06, $72, $f3, $e3, $51, $52, $51, $71, $72, $71, $a2, $a1, $c3, $e8, $88
	db $da, $e8, $f3, $ea, $33, $c1, $a1, $81, $51, $e2, $c1, $e3, $31, $81, $52, $e7
	db $01, $07, $e0, $06, $22, $a8, $e2, $53, $e8, $00, $f2, $52, $ff


MusicGameOverDrums::
	db $e0, $01, $fb, $96, $16, $16, $16, $fe, $03, $16, $16, $44, $14, $14, $14, $14
	db $14, $fb, $16, $fe, $06, $9c, $9c, $96, $96, $96, $96, $06, $06, $01, $96, $ff


MusicCourse1Sq2::
	db $ee, $50


MusicCourse1Sq2_Loop::
	db $fd, $a7, $77, $ea, $38, $e8, $00, $54, $34, $e4, $a4, $84, $54, $34, $e3, $a4
	db $84, $54, $e4, $54, $e0, $05, $48, $f1, $e2, $a1, $e3, $51, $52, $e4, $51, $53
	db $fd, $a7, $77, $e7, $05, $e3, $73, $73, $e8, $f1, $e4, $71, $71, $e0, $01, $88
	db $f2, $74, $54, $e3, $c4, $74, $54, $e4, $c4, $74, $54, $e3, $c4, $74, $fd, $e9
	db $77, $e8, $f3, $93, $51, $04, $fd, $e9, $77, $e8, $f3, $e4, $23, $e3, $c1, $04
	db $ea, $12, $fd, $e9, $77, $e8, $f3, $93, $51, $04, $fd, $e9, $77, $e4, $e8, $f3
	db $23, $e3, $c1, $04, $ea, $00, $fb, $01, $e3, $83, $51, $02, $e2, $31, $e3, $31
	db $12, $31, $e8, $f1, $e4, $51, $52, $e2, $11, $e1, $a1, $e8, $f3, $e3, $13, $e2
	db $a1, $02, $e1, $a1, $e8, $f1, $e3, $a1, $e2, $a1, $e3, $51, $a1, $e2, $a1, $e8
	db $c2, $e3, $73, $fe, $02, $fe, $ff, $0e, $77


MusicCourse1Sq2_Sub1::
	db $fb, $e0, $05, $48, $f2, $e4, $73, $e8, $f4, $53, $ef, $0f, $f3, $e8, $f3, $73
	db $e8, $f4, $53, $ef, $ff, $e8, $f2, $f0, $51, $71, $c1, $b3, $ea, $38, $e8, $f3
	db $e3, $53, $e8, $f4, $23, $e8, $f1, $c2, $c1, $e8, $f4, $b5, $fe, $02, $ea, $34
	db $e8, $f2, $e4, $93, $92, $93, $e7, $01, $77, $e3, $c6, $e4, $57, $77, $c6, $e5
	db $57, $fc


MusicCourse1Sq2_Sub2::
	db $e0, $05, $48, $f2, $fb, $ef, $f0, $e3, $c1, $e4, $31, $51, $ef, $0f, $e3, $c1
	db $e4, $31, $51, $fe, $03, $ef, $ff, $e8, $f1, $e3, $71, $72, $71, $72, $fc, $ff


MusicCourse1Wave::
	db $ea, $23


MusicCourse1Wave_Loop::
	db $fd, $69, $78, $e2, $a2, $e3, $a1, $e2, $a2, $a1, $e3, $a1, $e2, $a1, $a2, $e3
	db $81, $e2, $a2, $a1, $e3, $81, $e2, $a1, $fd, $69, $78, $72, $e3, $71, $e2, $72
	db $71, $e3, $71, $e2, $71, $71, $71, $e3, $51, $e2, $72, $71, $e3, $51, $e2, $71
	db $fd, $b0, $78, $ea, $12, $fd, $b0, $78, $ea, $00, $fb, $e8, $c4, $a3, $94, $e8
	db $c3, $81, $e3, $81, $62, $81, $62, $81, $e2, $61, $33, $34, $32, $31, $e3, $31
	db $e2, $31, $31, $31, $e3, $11, $e2, $31, $fe, $02, $fe, $ff, $0b, $78


MusicCourse1Wave_Sub1::
	db $fb, $e0, $05, $22, $f2, $e2, $72, $e3, $71, $e2, $72, $71, $e3, $71, $e2, $71
	db $72, $e3, $51, $e2, $72, $71, $e3, $51, $e2, $71, $72, $e3, $71, $e2, $72, $71
	db $e3, $71, $e2, $71, $71, $e3, $51, $41, $51, $e2, $71, $71, $e3, $51, $e2, $71
	db $fe, $02, $92, $e3, $91, $e2, $92, $91, $e3, $91, $e2, $91, $92, $e3, $71, $e2
	db $92, $91, $e3, $71, $e2, $91, $fc


MusicCourse1Wave_Sub2::
	db $fb, $e2, $52, $e3, $51, $e2, $52, $51, $e3, $51, $e2, $51, $51, $51, $e3, $31
	db $e2, $52, $51, $e3, $31, $e2, $51, $fe, $04, $fc, $ff


MusicCourse2Sq2::
	db $ee, $34, $ea, $04


MusicCourse2Sq2_Loop::
	db $e0, $04, $c8, $f2, $e3, $12, $fd, $86, $79, $d2, $b2, $a2, $82, $12, $82, $12
	db $d4, $fd, $86, $79, $e8, $a1, $e4, $42, $42, $e3, $42, $42, $e4, $62, $62, $e3
	db $62, $ea, $38, $e8, $f3, $e4, $54, $fd, $ca, $79, $62, $e4, $32, $e3, $62, $e4
	db $32, $52, $32, $12, $e3, $b4, $fd, $ca, $79, $e3, $34, $12, $54, $e4, $52, $62
	db $82, $e8, $a1, $ea, $34, $e2, $a2, $a2, $d2, $d2, $e3, $62, $62, $e2, $a2, $84
	db $82, $e3, $12, $12, $32, $32, $52, $52, $32, $32, $12, $34, $12, $32, $62, $52
	db $52, $62, $62, $72, $72, $82, $82, $62, $62, $82, $82, $a2, $a2, $62, $62, $82
	db $82, $a2, $a2, $c2, $c2, $82, $82, $a2, $a2, $e3, $32, $e4, $d4, $c2, $a2, $82
	db $62, $62, $e3, $62, $62, $e4, $82, $82, $e3, $62, $e4, $62, $fb, $e3, $62, $e4
	db $62, $fe, $02, $82, $82, $e3, $82, $82, $e4, $a2, $a2, $e3, $62, $62, $e4, $c2
	db $c2, $e3, $62, $e4, $a2, $fb, $e3, $62, $e4, $a2, $fe, $02, $c2, $c2, $e3, $82
	db $82, $ea, $3c, $fe, $ff, $cf, $78


MusicCourse2Sq2_Sub1::
	db $d2, $b2, $12, $d2, $12, $b2, $12, $d2, $12, $b2, $e4, $32, $e3, $12, $e4, $52
	db $e3, $12, $d4, $d2, $b2, $12, $a2, $12, $82, $12, $fc, $e3, $82, $62, $e2, $82
	db $e3, $82, $e2, $82, $e3, $62, $e2, $82, $e3, $82, $e2, $82, $e3, $62, $b2, $e2
	db $82, $e3, $d2, $e2, $82, $e3, $a4, $a2, $82, $e2, $82, $e3, $62, $e2, $82, $e3
	db $52, $e2, $82, $fc


MusicCourse2Sq2_Sub2::
	db $e8, $f2, $e2, $82, $e3, $32, $e2, $82, $e3, $52, $e2, $82, $b2, $e3, $52, $e2
	db $82, $e3, $52, $e2, $82, $e3, $52, $52, $e2, $82, $e3, $84, $e8, $81, $e2, $a2
	db $d2, $a2, $d2, $d2, $a2, $d2, $e3, $a2, $fc


MusicCourse2Wave::
	db $e0, $04, $22, $00, $ea, $04, $ea, $22


MusicCourse2Wave_Loop::
	db $fd, $7e, $7a, $d2, $d2, $d2, $e1, $14, $12, $12, $12, $fd, $7e, $7a, $e1, $92
	db $e2, $72, $92, $e1, $92, $b2, $e2, $b4, $e1, $d4, $fd, $9e, $7a, $e2, $32, $12
	db $e1, $b2, $82, $32, $d2, $fd, $9e, $7a, $e2, $12, $52, $32, $12, $e1, $82, $62
	db $62, $82, $62, $82, $62, $82, $d4, $d2, $b2, $82, $e2, $52, $32, $12, $e1, $b4
	db $b2, $a2, $62, $a2, $b2, $62, $d4, $d2, $d2, $e2, $b2, $d2, $12, $e1, $b2, $e2
	db $12, $fb, $e1, $32, $e2, $32, $fe, $04, $fb, $e1, $52, $e2, $52, $fe, $04, $fb
	db $e1, $62, $e2, $62, $fe, $04, $fb, $e1, $82, $e2, $82, $e1, $82, $82, $e2, $82
	db $82, $e1, $82, $82, $82, $82, $82, $e2, $84, $e1, $82, $82, $82, $fe, $02, $fe
	db $ff, $fb, $79


MusicCourse2Wave_Sub1::
	db $e1, $b1, $e8, $f4, $d1, $d2, $d2, $d4, $d2, $d2, $d2, $d2, $d2, $d2, $d4, $82
	db $b2, $82, $e8, $00, $b1, $e8, $f4, $d1, $d2, $d2, $d2, $d2, $d2, $d2, $d2, $fc


MusicCourse2Wave_Sub2::
	db $d2, $b2, $82, $b2, $82, $b2, $d4, $d2, $b2, $82, $b2, $82, $b2, $64, $62, $e2
	db $62, $e1, $62, $e2, $62, $e1, $62, $e2, $62, $e1, $62, $b2, $b2, $82, $fc


MusicCourse3Wave::
	db $ee, $84, $e0, $03, $94, $a8, $ea, $2d, $e1, $4c, $e8, $f4, $23, $55, $ef, $0f
	db $13, $e8, $f7, $59, $ef, $ff, $f0, $e8, $f2, $41, $42, $e8, $a7, $47, $e8, $f3
	db $42, $22, $52, $e8, $f2, $96, $91, $93, $e0, $01, $94, $f7, $5e, $e0, $01, $72
	db $27, $e5, $22, $32


MusicCourse3Wave_Loop::
	db $fd, $53, $7b, $94, $ea, $34, $e4, $24, $94, $54, $74, $54, $e3, $84, $a4, $fd
	db $53, $7b, $ea, $2c, $e8, $64, $98, $e5, $28, $18, $e0, $02, $72, $00, $5a, $e0
	db $02, $24, $00, $e4, $41, $31, $e0, $04, $24, $84, $28, $e8, $82, $42, $52, $e8
	db $85, $76, $96, $58, $e8, $82, $72, $82, $e8, $85, $a6, $c6, $e8, $82, $82, $a2
	db $c2, $a2, $72, $32, $52, $72, $82, $72, $32, $e3, $c2, $e8, $53, $a6, $e4, $16
	db $e7, $02, $e3, $89, $e8, $00, $71, $61, $51, $e8, $67, $4c, $ea, $2d, $fe, $ff
	db $f1, $7a


MusicCourse3Wave_Sub1::
	db $e0, $04, $72, $87, $e5, $48, $e8, $82, $22, $e4, $92, $e7, $03, $c4, $a4, $54
	db $74, $fc, $ff


MusicCourse3Sq2::
	db $e0, $03, $49, $88, $fd, $87, $7c, $fb, $e2, $21, $f1, $e8, $f1, $91, $c1, $e3
	db $21, $f0, $e8, $88, $fe, $04, $e1, $91, $e8, $f1, $f1, $e2, $41, $71, $91, $e3
	db $41, $91, $e4, $11, $e3, $91, $71, $41, $11, $e2, $91, $71, $41, $e1, $c1, $91
	db $f0


MusicCourse3Sq2_Loop::
	db $fd, $87, $7c, $fd, $87, $7c, $fd, $87, $7c, $fb, $e1, $b1, $f2, $e8, $f1, $e2
	db $51, $91, $b1, $f0, $e8, $88, $fe, $04, $fb, $e1, $a1, $f2, $e8, $f1, $e2, $51
	db $81, $a1, $f0, $e8, $88, $fe, $04, $ea, $38, $e2, $71, $f2, $e8, $f1, $a1, $e3
	db $21, $51, $71, $a1, $e4, $21, $51, $71, $51, $21, $e3, $a1, $71, $51, $21, $e2
	db $a1, $f0, $e8, $88, $e2, $91, $f2, $e8, $f1, $c1, $e3, $41, $71, $91, $c1, $e4
	db $41, $71, $91, $71, $41, $e3, $c1, $91, $71, $41, $e2, $c1, $f0, $e8, $88, $a1
	db $f2, $e8, $f1, $e3, $11, $51, $81, $a1, $e4, $11, $51, $81, $a1, $81, $51, $11
	db $e3, $a1, $81, $51, $11, $f0, $e8, $88, $e2, $c1, $f2, $e8, $f1, $e3, $31, $71
	db $a1, $c1, $e4, $31, $71, $a1, $c1, $a1, $71, $31, $e3, $c1, $a1, $71, $31, $f0
	db $e8, $88, $ea, $34, $fb, $e3, $11, $e8, $f1, $f2, $51, $81, $c1, $e8, $88, $f0
	db $fe, $02, $fb, $e2, $c1, $e8, $f1, $f2, $e3, $31, $71, $a1, $e8, $88, $f0, $fe
	db $02, $fb, $e2, $a1, $e8, $f1, $f2, $e3, $11, $51, $81, $e8, $88, $f0, $fe, $02
	db $fb, $e2, $81, $e8, $f1, $f2, $c1, $e3, $31, $71, $e8, $88, $f0, $fe, $02, $fb
	db $e2, $71, $e8, $f1, $f2, $a1, $e3, $11, $51, $e8, $88, $f0, $fe, $04, $e8, $80
	db $e1, $c1, $c2, $c2, $c1, $c2, $c2, $c2, $c1, $c1, $c1, $c1, $fe, $ff, $97, $7b


MusicCourse3Sq2_Sub1::
	db $fb, $e2, $21, $f1, $e8, $f1, $91, $c1, $e3, $21, $f0, $e8, $88, $fe, $04, $fb
	db $e2, $31, $f1, $e8, $f1, $a1, $e3, $11, $31, $f0, $e8, $88, $fe, $04, $fc


MusicCourse4Sq2::
	db $ee, $34, $ea, $29, $e0, $05, $89, $56, $e4, $5a, $e8, $c1, $f3, $e3, $a1, $d1
	db $f0, $61, $e4, $52, $e8, $56, $3b, $e8, $c1, $f3, $e3, $81, $c1, $f0, $51, $e4
	db $32, $e8, $56, $1b, $e8, $c1, $f3, $e3, $61, $a1, $f0, $61, $d1, $01, $e8, $62
	db $d4, $e4, $33, $11, $31


MusicCourse4Sq2_Loop::
	db $e8, $c1, $fb, $e4, $41, $f3, $e3, $81, $f0, $fe, $02, $e4, $61, $62, $e8, $00
	db $81, $fb, $fd, $d3, $7d, $61, $ea, $29, $e8, $a4, $87, $e8, $b2, $52, $12, $e3
	db $82, $e8, $f4, $b4, $94, $84, $64, $fd, $d3, $7d, $31, $12, $f2, $e8, $f2, $e3
	db $51, $a1, $e4, $11, $52, $f0, $e8, $c2, $a2, $c2, $d2, $ea, $20, $e8, $f4, $e5
	db $54, $64, $54, $34, $fd, $ef, $7d, $83, $63, $53, $ea, $34, $f2, $e8, $60, $e3
	db $11, $11, $11, $11, $f0, $ea, $38, $fd, $ef, $7d, $53, $33, $63, $ea, $34, $e8
	db $60, $e3, $51, $e2, $81, $e3, $11, $51, $ea, $03, $ea, $38, $fd, $ef, $7d, $ea
	db $00, $b3, $93, $83, $62, $42, $ea, $34, $e8, $60, $61, $f1, $e3, $a1, $e4, $11
	db $f0, $62, $ea, $38, $e2, $a1, $e3, $11, $61, $a1, $61, $11, $61, $a1, $e4, $11
	db $61, $a1, $e8, $f2, $ea, $34, $e3, $a1, $ea, $38, $f1, $11, $a1, $f0, $ea, $34
	db $c1, $ea, $38, $f1, $31, $51, $f0, $ea, $34, $d1, $ea, $38, $f1, $51, $61, $f0
	db $ea, $34, $e4, $31, $01, $ea, $38, $f1, $e3, $81, $f0, $ea, $34, $e4, $51, $ea
	db $38, $f1, $e3, $81, $f0, $ea, $34, $e4, $61, $ea, $38, $f1, $e3, $81, $f0, $fe
	db $02, $fd, $02, $7e, $fb, $e4, $b1, $f1, $b1, $f0, $fe, $02, $61, $e8, $d2, $63
	db $fd, $02, $7e, $fb, $e3, $a1, $f1, $a1, $f0, $fe, $02, $c1, $e8, $82, $c3, $e8
	db $d3, $e4, $13, $35, $fe, $ff, $db, $7c


MusicCourse4Sq2_Sub1::
	db $ea, $29, $e8, $a4, $e4, $88, $ea, $20, $e8, $f2, $52, $e8, $f1, $61, $82, $e8
	db $f3, $d3, $e8, $f4, $d4, $b4, $84, $64, $e8, $f2, $52, $fc


MusicCourse4Sq2_Sub2::
	db $ea, $2a, $e8, $c3, $e3, $d6, $c1, $d1, $ea, $20, $e4, $34, $e3, $84, $e8, $f3
	db $e4, $63, $fc


MusicCourse4Sq2_Sub3::
	db $e8, $c2, $e4, $83, $82, $e8, $60, $e3, $81, $d1, $e4, $81, $e8, $a3, $63, $e7
	db $01, $83, $a2, $e7, $05, $b4, $e8, $c2, $83, $82, $e8, $60, $e3, $51, $51, $51
	db $fc, $ff


MusicCourse4Wave::
	db $e0, $05, $22, $60, $e2, $fb, $81, $ea, $37, $e4, $61, $a1, $d1, $ea, $32, $e3
	db $fe, $02, $e2, $81, $e3, $51, $61, $71, $81, $ea, $37, $e4, $61, $a1, $61, $ea
	db $32, $e2, $fb, $81, $ea, $37, $e4, $51, $81, $c1, $e3, $ea, $32, $fe, $02, $e2
	db $81, $e3, $51, $61, $71, $81, $ea, $37, $e4, $51, $81, $51, $ea, $32, $e2, $fb
	db $81, $ea, $37, $e4, $31, $61, $a1, $e3, $ea, $32, $fe, $02, $e2, $81, $e3, $31
	db $61, $71, $81, $ea, $37, $e4, $31, $61, $31, $ea, $32, $e2, $61, $e3, $41, $91
	db $e2, $81, $e3, $61, $b1, $e2, $61, $81


MusicCourse4Wave_Loop::
	db $91, $e3, $11, $e2, $91, $e3, $11, $e2, $b1, $b2, $d1, $fb, $fd, $6e, $7f, $c1
	db $d1, $d1, $e4, $31, $e2, $d1, $e4, $51, $e2, $d1, $82, $d2, $d2, $82, $d1, $c1
	db $b1, $b1, $e4, $11, $e2, $b1, $e4, $31, $e2, $b1, $62, $b2, $b2, $b1, $61, $b1
	db $c1, $fd, $6e, $7f, $81, $a1, $a1, $e3, $c1, $e2, $a1, $e3, $a1, $e2, $a1, $82
	db $73, $72, $71, $e3, $31, $e2, $71, $81, $81, $e3, $81, $e2, $81, $e3, $a1, $e2
	db $81, $e3, $81, $e2, $81, $91, $91, $e3, $c1, $e2, $91, $e3, $51, $e2, $91, $51
	db $91, $fd, $91, $7f, $e2, $51, $51, $51, $51, $fd, $91, $7f, $e2, $11, $e3, $51
	db $81, $d1, $ea, $03, $fd, $91, $7f, $ea, $00, $41, $81, $b1, $e3, $41, $e8, $60
	db $e3, $31, $e4, $11, $61, $e3, $32, $ea, $38, $61, $a1, $d1, $e4, $61, $11, $e3
	db $a1, $d1, $e4, $61, $a1, $d1, $e5, $61, $e8, $60, $ea, $32, $e2, $81, $81, $81
	db $81, $e3, $82, $e2, $81, $81, $81, $e3, $81, $e2, $81, $81, $e3, $81, $e2, $81
	db $e3, $81, $e2, $81, $fe, $02, $fd, $c0, $7f, $82, $82, $e3, $b1, $61, $e2, $81
	db $81, $fd, $c0, $7f, $fb, $61, $e2, $81, $e3, $fe, $02, $81, $81, $e2, $81, $81
	db $e3, $a1, $e2, $81, $81, $e3, $c1, $e2, $81, $81, $e3, $81, $e2, $81, $fe, $ff
	db $8c, $7e


MusicCourse4Wave_Sub1::
	db $e8, $80, $d1, $d1, $e4, $31, $e3, $11, $e4, $51, $e2, $d1, $82, $d2, $d2, $82
	db $d1, $c1, $b1, $b1, $e4, $31, $e2, $b1, $e4, $61, $e2, $b1, $62, $b2, $b2, $b1
	db $61, $b1, $fc


MusicCourse4Wave_Sub2::
	db $e2, $a1, $a1, $ea, $22, $e4, $11, $ea, $20, $e2, $a1, $e4, $61, $e2, $a1, $e3
	db $61, $e2, $a1, $c1, $c1, $ea, $22, $e4, $31, $ea, $20, $e2, $c1, $e3, $c1, $e2
	db $c1, $e3, $31, $81, $11, $11, $11, $d2, $d1, $11, $11, $11, $d2, $11, $fc


MusicCourse4Wave_Sub3::
	db $e3, $d1, $81, $11, $12, $e4, $11, $81, $d1, $e2, $81, $81, $e3, $81, $e2, $82
	db $e3, $81, $e2, $81, $81, $e3, $d1, $81, $11, $12, $11, $d1, $11, $fc

;@ def SetMusicTempoNormal()
;@ path: sound/api
;@ The course music's normal tempo (TempoNormal).
;@ test: mem[0xC580] = rand(0x1B, 0x22)
;@ sig: 2f5b8681
SetMusicTempoNormal::
;> return SetCourseTempo(TempoNormal)
	ld hl, TempoNormal
	jr SetCourseTempo

;@ def SetMusicTempoHurry()
;@ path: sound/api
;@ The course music speeds up for the last 10 seconds (TempoHurry).
;@ test: mem[0xC580] = rand(0x1B, 0x22)
;@ sig: 5d89ee12
SetMusicTempoHurry::
;> return SetCourseTempo(TempoHurry)          # falls through
	ld hl, TempoHurry

;@ def SetCourseTempo(table: hl)
;@ path: sound/api
;@ If one of the four course songs ($1D-$20) plays, its tempo from the table.
;@ writes: wMusicTempo
;@ reads: wMusicWave
;@ test: mem[0xC580] = rand(0x1B, 0x22); table = rand_ram(4)
;@ sig: 475886af
SetCourseTempo::
;> song = wMusicWave[0]
;> if not 0x1D <= song < 0x21: return
	ld a, [wMusicWave]
	cp $1d
	ret c

	cp $21
	ret nc

;> wMusicTempo = mem[u16(table + song - 0x1D)]
	sub $1d
	rst $28
	ld a, [hl]
	ld [wMusicTempo], a
;> return
	ret


;@ wMusicTempo for the four course songs ($1D-$20) in the last 10 seconds: lower, so faster.
TempoHurry::
	db $28, $18, $70, $10


;@ wMusicTempo for the four course songs ($1D-$20) otherwise.
TempoNormal::
	db $50, $38, $80, $30, $ff
