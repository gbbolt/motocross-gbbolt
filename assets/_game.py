"""Shared helpers for Motocross Maniacs' asset plugins: run the whole game from Boot, frame by frame.

The main loop ends every frame with a `halt` that waits for the VBlank interrupt. The machine
here steps the CPU until it reaches a `halt`, then runs the VBlank interrupt and, when it is
enabled, the timer interrupt that drives the sound engine. The LCD registers answer the way
the game's busy-waits want: each read of rLY or rSTAT moves one line further.
"""
from gamerun import GameRunner

FRAME_HZ = 4194304 / 70224
VBLANK, TIMER = 0x0040, 0x0050
SHADOW_OAM = 0xCC00                                        # what the OAM DMA copies


class Machine:
    def __init__(self, ctx):
        self.ctx = ctx
        self.run = GameRunner(ctx.project, stack=0xE000)
        self.mem, self.cpu = self.run.mem, self.run.cpu
        self.cpu.pc, self.cpu.sp = ctx.syms['Boot'], 0xFFFE
        self.buttons = 0                                   # A $01 B $02 Select $04 Start $08, d-pad high nibble
        self.ly = 0x91
        self.frames = 0
        plain = self.cpu.rd

        def rd(a):
            a &= 0xFFFF
            if a == 0xFF44:
                self.ly = (self.ly + 1) % 154
                return self.ly
            if a == 0xFF41:                                # mode 0 inside the screen, 1 in VBlank
                self.ly = (self.ly + 1) % 154
                return 0x80 | (self.mem[0xFF41] & 0x78) | (1 if self.ly >= 144 else 0)
            if a == 0xFF00:
                sel = self.mem[0xFF00]
                v = 0x0F
                if not sel & 0x10:
                    v &= ~(self.buttons >> 4)
                if not sel & 0x20:
                    v &= ~self.buttons
                return 0xC0 | (sel & 0x30) | (v & 0x0F)
            return plain(a)
        self.cpu.rd = rd

    def get(self, name):
        return self.run.get(name)

    def set(self, name, value):
        self.run.set(name, value)

    def frame(self, max_steps=2000000):
        """Run to the main loop's halt, then the interrupts."""
        cpu, mem = self.cpu, self.mem
        for _ in range(max_steps):
            if mem[cpu.pc] == 0x76:
                cpu.pc += 1
                break
            cpu.step()
        else:
            raise RuntimeError('no halt after {} steps (pc=${:04X})'.format(max_steps, cpu.pc))
        self.interrupt(VBLANK)
        if mem[0xFFFF] & 0x04:
            self.interrupt(TIMER)
        self.frames += 1
        self.ly = 0x91

    def interrupt(self, vec):
        cpu = self.cpu
        pc, sp = cpu.pc, cpu.sp
        cpu.call(vec, max_steps=500000)
        cpu.pc, cpu.sp = pc, sp

    def play(self, schedule, frames):
        """Run frames with button presses: schedule = [(first frame, buttons, frames held)]."""
        for f in range(frames):
            self.buttons = 0
            for a, b, h in schedule:
                if a <= f < a + h:
                    self.buttons = b
            self.frame()

    def screen(self):
        return self.run.screen(oam=SHADOW_OAM)


def start_course(ctx, course, level=0):
    """A machine at the start of a course (0-7), level A/B/C (0-2), solo, through the menus."""
    m = Machine(ctx)
    sched = [(330, 0x08, 3)]                               # title: START (SOLO)
    f = 420
    for _ in range(course):                                # SELECT COURSE: right
        sched.append((f, 0x10, 2))
        f += 10
    sched.append((f, 0x08, 3))
    f += 90
    for _ in range(level):                                 # SELECT LEVEL: right
        sched.append((f, 0x10, 2))
        f += 10
    sched.append((f, 0x08, 3))
    f += 90
    sched.append((f, 0x08, 3))                             # the course card
    m.play(sched, f + 300)
    return m
