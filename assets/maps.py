"""The eight courses as whole maps, drawn from what the game itself builds: it enters each
course through the menus and reads the level map, its metatiles and the item list from RAM."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _game import start_course  # noqa: E402

GROUP = 'courses'
ITEMS = {                       # wItems kinds (ItemEffects)
    2: ('S', 'raises the top speed (ItemTopSpeed: wBikeTopSpeed $4F to $6F)'),
    3: ('T', 'a clock: 10 more seconds (ItemClock); in a link game it becomes an N'),
    4: ('N', '4 more nitros (ItemNitro)'),
    5: ('R', 'slopes stop slowing the bike down (ItemPowerUpA, UpdateSlopeBonus)'),
    6: ('hidden', 'invisible; taken only by riding through it upside down: '
                  'B fires a nitro in the air too (ItemPowerUpB, UpdateThrottle)'),
    7: ('hidden', 'invisible; taken only by riding through it upside down: '
                  'one more afterimage behind the bike, up to 3 (ItemPowerUpLevel, DrawTrail); '
                  'left out of link games'),
}


def course_map(ctx, course):
    m = start_course(ctx, course)
    mem = m.mem
    level = ctx.addr('wLevelMap')
    meta_rom = ctx.addr('MetatileTiles')                    # 4 tiles per metatile: top left, top right, bottom left, bottom right
    meta_ram = ctx.addr('wCompMetatiles')                  # metatiles $A8 and up are built in RAM
    signed = not mem[0xFF40] & 0x10
    bgp = mem[0xFF47]
    pal = [(bgp >> (2 * c)) & 3 for c in range(4)]

    def tile_rows(t):
        if signed:
            base = 0x9000 + t * 16 if t < 128 else 0x8800 + (t - 128) * 16
        else:
            base = 0x8000 + t * 16
        out = []
        for y in range(8):
            lo, hi = mem[base + 2 * y], mem[base + 2 * y + 1]
            out.append([pal[((hi >> (7 - x)) & 1) << 1 | ((lo >> (7 - x)) & 1)] for x in range(8)])
        return out

    cache = {}
    grid = [mem[level + 256 * r: level + 256 * r + 256] for r in range(16)]
    top = next((r for r in range(16) if any(v != 0xFF for v in grid[r])), 15)
    top = max(0, top - 1)                                    # a row of sky above the highest piece
    rows = [[0] * 4096 for _ in range(16 * (16 - top))]
    for r in range(top, 16):
        for c in range(256):
            a = grid[r][c]
            if a not in cache:
                src = meta_rom + 4 * a if a < 0xA8 else meta_ram + 4 * (a - 0xA8)
                cache[a] = [tile_rows(mem[src + k]) for k in range(4)]
            for k, px in enumerate(cache[a]):
                ox, oy = c * 16 + (k & 1) * 8, (r - top) * 16 + (k >> 1) * 8
                for y in range(8):
                    rows[oy + y][ox:ox + 8] = px[y]
    marks, counts = [], {}
    items = ctx.addr('wItems')
    for i in range(m.get('wItemCount')):
        kind, _, _, _, _, row, col = mem[items + 8 * i: items + 8 * i + 7]
        short, text = ITEMS.get(kind, ('?', 'item kind {}'.format(kind)))
        counts[short] = counts.get(short, 0) + 1
        marks.append({'x': 16 * col, 'y': 16 * (row - top), 'w': 16, 'h': 16,
                      'label': 'Item {} ({})'.format(short, kind), 'text': text})
    n = 'course-{}'.format(course + 1)
    return {
        'name': n, 'type': 'image', 'title': 'Course {}'.format(course + 1),
        'subtitle': '4096 x {} pixels, {} items'.format(len(rows), len(marks)),
        'width': 4096, 'height': len(rows), 'pixels': ctx.packed_pixels(rows), 'packed': 'zlib',
        'scale': 2, 'scroll': True, 'marks': marks,
        'doc': ['The whole of course {}, as the game builds it in wLevelMap before the race: '
                '256 columns and 16 rows of metatiles, 2 x 2 tiles each. PlaceTrackPieces stamps '
                'the track pieces of TrackPieceLists into the empty map; where a piece overlaps '
                'another, StampMetatile lays its tiles over the ones already there and makes a new '
                'metatile out of the mix (wCompMetatiles).'.format(course + 1),
                'The marked squares are the items (ItemLists, then wItems): {}. Hover or click one '
                'for what it does. A bike takes an item when it comes within 15 pixels of it.'.format(
                    ', '.join('{} x {}'.format(v, k) for k, v in sorted(counts.items())))],
        'users': ['PlaceTrackPieces', 'TrackPieceLists', 'TrackPieces', 'MetatileTiles', 'PlaceItemMetatiles',
                  'ItemLists', 'ItemEffects', 'wLevelMap', 'wItems'],
    }


def build(ctx):
    return [course_map(ctx, c) for c in range(8)]
