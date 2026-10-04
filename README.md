# Motocross Maniacs (Game Boy) - gbbolt disassembly

**Open it: <https://gbbolt.lingora.org/motocross/>**

A complete, matching disassembly of *Motocross Maniacs* for the Game Boy (Konami; this is
the 1991 European release, published by Palcom), with pseudo-code written next to every
function and checked against the original code in an emulator. It is read with
[gbbolt](https://github.com/AlexanderStebner/gbbolt): code and pseudo-code side by side,
linked line by line.

- **311 of 311 functions** have pseudo-code. 227 are verified by differential testing:
  the pseudo-code and the original code give identical results on 64 random machine
  states. The other 84 are checked: they wait for VRAM, VBlank or the link cable, read
  whole sound streams or never return, so they can't run in isolation.
- **Every routine and RAM variable is named**, and every function sits in a virtual
  folder (`level/build`, `bike/physics`, `bike/ground`, `race/com`, `sound/engine`, ...).
- **All 8 courses as whole maps**, 4096 pixels long, built by the game's own code, with
  every item marked: hover or click one for what it does. The level format is fully
  decoded: track pieces stamped into a map of metatiles, overlaps turned into new
  metatiles on the fly.
- **The track pieces**: all 100 drawn from the ROM, with where each one is used, and the
  18 that no course uses.
- **Sound**: the sound engine is fully annotated. All 32 sounds are rendered from it
  (the course songs, the menu and results music, the engine, the effects and the drums),
  with a piano roll and mute / solo per channel.
- **Screens and texts**: the Palcom and title screens, the menus, the results texts and
  the status bar, drawn with the tiles the game loads.

Some things the code shows:

- A race is two laps of the same map: the bike's position runs to 8192 pixels and the
  4096-pixel map wraps round. The items come back at the lap line.
- Two of the item kinds are invisible. They only count if the bike passes through them
  upside down.
- The computer's bike has endless nitros and the R power-up (slopes don't slow it), but eases off when it
  gets too far ahead; the level (A, B, C) sets how far.
- The level also picks the time limit; the tracks are the same.
- 18 of the 100 track pieces are in the ROM but no course uses them.

## Building

The disassembly rebuilds the original ROM byte for byte. You need
[RGBDS](https://rgbds.gbdev.io) 1.0.1, Python 3.9+ with numpy, and gbbolt next to this
folder:

```
git clone https://github.com/AlexanderStebner/gbbolt
git clone https://github.com/AlexanderStebner/motocross-gbbolt
cd motocross-gbbolt
python ../gbbolt/tools/audio.py             # render the music (needs ffmpeg)
python ../gbbolt/tools/gbbolt.py            # build, verify, write out/site/index.html
```

The build is checked against the SHA1 of the original ROM
(`956a12a65a1c39948c312303719895bd6f141a61`, *Motocross Maniacs (Europe)*). No ROM is
needed to build it. If you put your own dump next to `game.json` as `motocross.gb`, it is
compared byte by byte.

## Layout

```
game.json           what gbbolt needs to know about the game
src/game.asm        the main file
src/bank_000.asm    the disassembly with its annotations
src/ram.inc         RAM variables: names, types, descriptions
src/hardware.inc    hardware registers
src/folders.txt     the virtual folders
src/sound.json      how to drive the sound engine
src/intro.md        the Book's first chapter: from power-on to the finish line
assets/*.py         asset plugins: course maps, track pieces, the title screen
```

## Legal

Motocross Maniacs and its code, graphics and music are the property of their respective
owners (Konami). This repository contains no ROM. It is a research and documentation
project in the tradition of other community disassemblies; please buy the game.

The annotations, names, pseudo-code, descriptions, plugins and configuration written for
this project are available under the MIT license (see [LICENSE](LICENSE)), as far as
they are separable from the game itself.
