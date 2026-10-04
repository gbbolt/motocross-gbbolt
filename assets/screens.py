"""The title screen, as the game draws it after power-on."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _game import Machine  # noqa: E402

GROUP = 'screens'


def build(ctx):
    m = Machine(ctx)
    while m.get('wGameState') != 1:                 # the Palcom screen, then the title
        m.frame()
    for _ in range(60):
        m.frame()
    title = m.screen()
    ctx.poster(title, 'title')                       # gen/screens_title.png: the hub's thumbnail
    return [{
        'name': 'title-screen', 'type': 'image', 'title': 'Title screen',
        'width': 160, 'height': 144, 'pixels': ctx.pixels(title), 'scale': 2,
        'doc': ['The title screen as the game draws it after the Palcom screen (StateTitle): the logo '
                'from TitleScreenMap, packed with run lengths, the copyright lines (TitleScreenText) and '
                'the menu, SOLO, VS COMPUTER and VS 2-PLAYER, with its cursor sprite (TitleMenuInput).'],
        'users': ['StateTitle', 'LoadTitleScreen', 'TitleScreenMap', 'TitleScreenText', 'TitleMenuInput'],
    }]
