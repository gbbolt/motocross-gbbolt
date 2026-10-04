"""The track pieces the courses are built from (TrackPieces), each drawn from its metatiles."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _game import start_course  # noqa: E402

GROUP = 'courses'


def build(ctx):
    m = start_course(ctx, 0)                       # for the game's tiles in VRAM
    mem, rom = m.mem, ctx.rom
    meta = ctx.addr('MetatileTiles')
    signed = not mem[0xFF40] & 0x10
    bgp = mem[0xFF47]
    pal = [(bgp >> (2 * c)) & 3 for c in range(4)]

    def tile(t):
        base = (0x9000 + t * 16 if t < 128 else 0x8800 + (t - 128) * 16) if signed else 0x8000 + t * 16
        return [[pal[((mem[base + 2 * y + 1] >> (7 - x)) & 1) << 1 | ((mem[base + 2 * y] >> (7 - x)) & 1)]
                 for x in range(8)] for y in range(8)]

    # which pieces each course uses
    lists, pieces = ctx.addr('TrackPieceLists'), ctx.addr('TrackPieces')
    used = {}
    for course in range(8):
        p = ctx.word(lists + 2 * course)
        while rom[p] != 0xFF:
            used.setdefault(rom[p + 2], []).append(course + 1)
            p += 3
    rows = []
    count = 1                                         # the word table ends where the first piece starts
    while pieces + 2 * count < min(ctx.word(pieces + 2 * i) for i in range(count)):
        count += 1
    for n in range(count):
        a = ctx.word(pieces + 2 * n)
        h, w = rom[a], rom[a + 1]
        px = [[255] * (16 * w) for _ in range(16 * h)]          # 255: see-through
        for r in range(h):
            for c in range(w):
                mt = rom[a + 2 + r * w + c]
                if mt == 0xFF:
                    continue
                for k in range(4):
                    t = rom[meta + 4 * mt + k]
                    if t == 0x7F:                                   # the see-through tile
                        continue
                    img = tile(t)
                    for y in range(8):
                        px[r * 16 + (k >> 1) * 8 + y][c * 16 + (k & 1) * 8: c * 16 + (k & 1) * 8 + 8] = img[y]
        courses = used.get(n, [])
        rows.append([n, '{} x {}'.format(w, h),
                     {'image': {'width': 16 * w, 'height': 16 * h, 'pixels': ctx.pixels(px)}},
                     ', '.join('{}: {}×'.format(c, courses.count(c)) for c in sorted(set(courses)))
                     or 'never'])
    return [{
        'name': 'track-pieces', 'type': 'table', 'title': 'Track pieces',
        'subtitle': '{} pieces'.format(len(rows)),
        'columns': ['piece', 'size (metatiles)', 'picture', 'course: times placed'],
        'rows': rows,
        'doc': ['Every course is a list of these pieces, each placed at a map row and column '
                '(TrackPieceLists, PlaceTrackPieces). A piece is a rectangle of metatiles (TrackPieces), '
                'each 2 x 2 tiles from MetatileTiles; tile $7F is see-through, so a piece laid over '
                'another lets the one below show (StampMetatile). Drawn here from the ROM, with the '
                'see-through parts left out.',
                'Pieces no course places are still in the ROM: {}.'.format(
                    ', '.join(str(r[0]) for r in rows if r[3] == 'never') or 'none')],
        'users': ['TrackPieces', 'TrackPieceLists', 'PlaceTrackPieces', 'StampMetatile', 'MetatileTiles'],
    }]
