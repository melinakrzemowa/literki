#!/usr/bin/env python3
"""Draws the picture for every concept in the word bank.

Run from the project root:

    python3 tools/generate_images.py

The pictures are deliberately flat and bold — a child has to recognise one of
three at a glance — and every drawing sits on its own rounded pastel tile so
the three cards on screen look like a set. Regenerating is cheap, so tweak a
drawing here rather than hand-editing the SVG it produces.
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from svg_kit import (circle, ellipse, group, line, path, poly, rect, ring, spiral,
                     star_points, svg)

OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "images"

INK = "#3d2b23"
WHITE = "#ffffff"

BACKGROUNDS = {
    "dog": "#ffe8cc", "cat": "#e8e2f7", "fish": "#cfeaff", "bird": "#d9f2e6",
    "cow": "#e9f4da", "frog": "#ddf0c8", "duck": "#cfe8ff", "mouse": "#f5ece2",
    "lion": "#ffedd0", "sun": "#bfe6ff", "moon": "#2f3a6b", "star": "#3b4a8a",
    "cloud": "#a9d9ff", "tree": "#d3e9ff", "flower": "#fdf1d8", "house": "#cfe6ff",
    "car": "#e8e8f4", "boat": "#c3e6fb", "ball": "#ffe1ea", "apple": "#eaf6d8",
    "banana": "#d6ecf7", "cake": "#ffe4f0", "milk": "#e9f3fb", "egg": "#cfe1f5",
    "heart": "#ffe0e6", "key": "#efe7d2", "book": "#e4edf8", "shoe": "#e9e9ef",
    "hat": "#dbe9f7", "clock": "#f3e7d9",
    "horse": "#f2e6d2", "pig": "#ffe6ee", "sheep": "#e7f0df", "rabbit": "#f6eddf",
    "fox": "#ffeadb", "turtle": "#dcf0e7", "snail": "#eff4da", "bread": "#f7ede1",
    "cheese": "#fff4d2", "carrot": "#e9f3de", "pear": "#eff7e1", "lemon": "#e9f4f9",
    "chair": "#efe9f5", "table": "#f3ede3", "bed": "#e7effb", "lamp": "#fdf1da",
    "door": "#eae3d7", "bike": "#e5eff3", "train": "#e9e5f3", "leaf": "#ebf5db",
}

DRAWINGS = {}


def drawing(name):
    def register(func):
        DRAWINGS[name] = func
        return func
    return register


def eyes(left_x, right_x, y, r=8, colour=INK):
    return circle(left_x, y, r, colour) + circle(right_x, y, r, colour)


def smile(d, width=7, colour=INK):
    return path(d, stroke=colour, sw=width)


# ---------------------------------------------------------------- animals ---

@drawing("dog")
def dog():
    return (
        ellipse(72, 122, 26, 46, "#a9703f", rot=(18, 72, 122))
        + ellipse(184, 122, 26, 46, "#a9703f", rot=(-18, 184, 122))
        + circle(128, 126, 64, "#d9a066")
        + ellipse(128, 162, 42, 32, "#f2d4a7")
        + ellipse(128, 146, 14, 11, INK)
        + smile("M128 158 L128 168 M128 168 Q112 180 100 168 M128 168 Q144 180 156 168")
        + eyes(104, 152, 116)
        + circle(100, 112, 3, WHITE) + circle(148, 112, 3, WHITE)
    )


@drawing("cat")
def cat():
    return (
        poly([(66, 118), (72, 44), (124, 86)], "#9aa0a6")
        + poly([(190, 118), (184, 44), (132, 86)], "#9aa0a6")
        + poly([(80, 110), (84, 66), (116, 90)], "#f2b8c6")
        + poly([(176, 110), (172, 66), (140, 90)], "#f2b8c6")
        + circle(128, 136, 64, "#b0b6bc")
        + eyes(102, 154, 128, 11, "#3f7d20")
        + eyes(102, 154, 128, 5)
        + poly([(120, 152), (136, 152), (128, 162)], "#e3708f")
        + smile("M128 162 Q116 176 104 166 M128 162 Q140 176 152 166")
        + line(38, 140, 88, 148, INK, 5) + line(38, 160, 88, 160, INK, 5)
        + line(218, 140, 168, 148, INK, 5) + line(218, 160, 168, 160, INK, 5)
    )


@drawing("fish")
def fish():
    return (
        poly([(60, 128), (18, 90), (26, 166)], "#e07b39")
        + poly([(128, 82), (146, 40), (170, 92)], "#e07b39")
        + ellipse(142, 128, 66, 48, "#f4913e")
        + path("M120 84 Q104 128 120 172", stroke="#d96f2c", sw=7)
        + ellipse(178, 158, 24, 14, "#e07b39", rot=(20, 178, 158))
        + circle(176, 112, 13, WHITE)
        + circle(180, 112, 7, INK)
        + circle(196, 136, 6, WHITE, opacity=0.6)
        + circle(186, 150, 4, WHITE, opacity=0.5)
    )


@drawing("bird")
def bird():
    return (
        poly([(72, 142), (24, 116), (34, 162)], "#3579b5")
        + circle(118, 148, 56, "#4d9de0")
        + circle(164, 96, 34, "#4d9de0")
        + ellipse(112, 152, 32, 21, "#3579b5", rot=(-18, 112, 152))
        + poly([(194, 94), (228, 104), (194, 116)], "#f0a202")
        + circle(174, 88, 6, INK)
        + line(108, 204, 108, 224, "#f0a202", 8)
        + line(140, 204, 140, 224, "#f0a202", 8)
    )


@drawing("cow")
def cow():
    # The horns have to clear the top of the head and the muzzle has to stay
    # small, or the whole thing reads as a pig.
    return (
        poly([(92, 76), (64, 26), (108, 58)], "#efe0c0")
        + poly([(164, 76), (192, 26), (148, 58)], "#efe0c0")
        + ellipse(48, 120, 32, 19, "#f7f3ea", rot=(-18, 48, 120))
        + ellipse(208, 120, 32, 19, "#f7f3ea", rot=(18, 208, 120))
        + ellipse(46, 120, 16, 9, "#f2b8c6", rot=(-18, 46, 120))
        + ellipse(210, 120, 16, 9, "#f2b8c6", rot=(18, 210, 120))
        + ellipse(128, 134, 68, 64, "#f7f3ea")
        + ellipse(92, 98, 28, 23, "#4a3a33", rot=(-15, 92, 98))
        + ellipse(172, 104, 17, 13, "#4a3a33", rot=(22, 172, 104))
        + ellipse(128, 174, 34, 23, "#f7c6d2")
        + ellipse(116, 172, 6, 8, "#dd93a8") + ellipse(140, 172, 6, 8, "#dd93a8")
        + eyes(104, 152, 132)
    )


@drawing("frog")
def frog():
    return (
        ellipse(70, 190, 28, 16, "#4f9d3a", rot=(-20, 70, 190))
        + ellipse(186, 190, 28, 16, "#4f9d3a", rot=(20, 186, 190))
        + ellipse(128, 152, 78, 58, "#5fb241")
        + circle(92, 90, 32, "#5fb241") + circle(164, 90, 32, "#5fb241")
        + circle(92, 86, 21, WHITE) + circle(164, 86, 21, WHITE)
        + circle(92, 88, 11, INK) + circle(164, 88, 11, INK)
        + circle(87, 82, 5, WHITE) + circle(159, 82, 5, WHITE)
        + smile("M84 156 Q128 196 172 156", 8)
        + circle(78, 140, 7, "#4f9d3a") + circle(178, 140, 7, "#4f9d3a")
    )


@drawing("duck")
def duck():
    return (
        poly([(70, 148), (26, 132), (44, 172)], "#f0c419")
        + ellipse(118, 158, 64, 46, "#ffd93d")
        + circle(166, 104, 36, "#ffd93d")
        + ellipse(110, 162, 36, 24, "#f0c419", rot=(-12, 110, 162))
        + path("M196 100 Q230 104 230 114 Q230 124 196 126 Z", "#f08c00")
        + circle(176, 96, 6, INK)
        + line(104, 200, 104, 218, "#f08c00", 8)
        + line(136, 200, 136, 218, "#f08c00", 8)
    )


@drawing("mouse")
def mouse():
    return (
        path("M182 168 Q232 176 226 128", stroke="#b0a49c", sw=9)
        + circle(82, 92, 34, "#b0a49c") + circle(174, 92, 34, "#b0a49c")
        + circle(82, 92, 21, "#f2b8c6") + circle(174, 92, 21, "#f2b8c6")
        + circle(128, 144, 58, "#c4b8b0")
        + ellipse(128, 172, 20, 15, "#f2b8c6")
        + eyes(108, 148, 136, 8)
        + line(40, 166, 96, 172, INK, 4) + line(44, 184, 98, 180, INK, 4)
        + line(216, 166, 160, 172, INK, 4) + line(212, 184, 158, 180, INK, 4)
    )


@drawing("lion")
def lion():
    mane = poly(star_points(128, 128, 100, 76, count=11, rotation=-90), "#c8722f")
    return (
        mane
        + circle(128, 128, 76, "#d4813a")
        + circle(88, 82, 17, "#b8601f") + circle(168, 82, 17, "#b8601f")
        + circle(128, 132, 54, "#f0c087")
        + eyes(108, 148, 118, 8)
        + ellipse(128, 148, 13, 9, "#8b4a2b")
        + ellipse(112, 166, 17, 12, "#f7dcbc") + ellipse(144, 166, 17, 12, "#f7dcbc")
        + smile("M128 156 L128 162 M128 162 Q118 172 110 164 M128 162 Q138 172 146 164", 5)
    )


# ------------------------------------------------------------------- sky ---

@drawing("sun")
def sun():
    return (
        poly(star_points(128, 128, 112, 68, count=12), "#ffc93c")
        + circle(128, 128, 66, "#ffd93d")
        + eyes(108, 148, 116, 8)
        + smile("M100 146 Q128 172 156 146", 8)
        + circle(96, 154, 9, "#ffb3a7", opacity=0.7)
        + circle(160, 154, 9, "#ffb3a7", opacity=0.7)
    )


@drawing("moon")
def moon():
    return (
        circle(116, 130, 84, "#fdf3c9")
        + circle(156, 106, 74, BACKGROUNDS["moon"])
        + poly(star_points(196, 190, 18, 7), "#fdf3c9")
        + poly(star_points(56, 58, 14, 5), "#fdf3c9")
        + circle(84, 148, 14, "#e9dba7", opacity=0.8)
        + circle(72, 104, 9, "#e9dba7", opacity=0.8)
    )


@drawing("star")
def star():
    return (
        poly(star_points(128, 130, 98, 42), "#ffc93c")
        + poly(star_points(128, 130, 72, 31), "#ffd93d")
        + eyes(110, 146, 118, 7)
        + smile("M110 140 Q128 158 146 140", 6)
    )


@drawing("cloud")
def cloud():
    return (
        circle(92, 146, 42, WHITE)
        + circle(132, 118, 52, WHITE)
        + circle(176, 148, 38, WHITE)
        + rect(88, 142, 92, 50, WHITE, r=25)
        + circle(112, 158, 12, "#e4f1ff", opacity=0.9)
        + circle(152, 166, 9, "#e4f1ff", opacity=0.9)
    )


# ----------------------------------------------------------------- nature ---

@drawing("tree")
def tree():
    return (
        rect(116, 140, 24, 82, "#8b5a2b", r=8)
        + path("M128 180 L100 154 M128 200 L156 176", stroke="#7a4d24", sw=7)
        + circle(90, 128, 42, "#43a047")
        + circle(166, 128, 42, "#43a047")
        + circle(128, 98, 54, "#4caf50")
        + circle(108, 86, 12, "#66bb6a", opacity=0.8)
        + circle(150, 142, 9, "#66bb6a", opacity=0.8)
    )


@drawing("flower")
def flower():
    stem = rect(122, 100, 12, 124, "#4caf50", r=6)
    leaf = ellipse(84, 172, 30, 16, "#43a047", rot=(-25, 84, 172))
    leaf_right = ellipse(172, 148, 28, 15, "#43a047", rot=(25, 172, 148))
    petals = ring(128, 96, 42, 6, lambda x, y, a: circle(x, y, 28, "#e8578a"))
    return (
        stem + leaf + leaf_right + petals
        + circle(128, 96, 27, "#ffc93c")
        + ring(128, 96, 14, 6, lambda x, y, a: circle(x, y, 4, "#e8a800"))
    )


# --------------------------------------------------------------- everyday ---

@drawing("house")
def house():
    return (
        rect(64, 118, 128, 106, "#f5d7a3", r=6)
        + poly([(44, 126), (128, 46), (212, 126)], "#c0392b")
        + rect(108, 162, 40, 62, "#8b5a2b", r=4)
        + circle(140, 194, 5, "#ffd93d")
        + rect(78, 136, 34, 34, "#7fc7ea", r=4)
        + rect(144, 136, 34, 34, "#7fc7ea", r=4)
        + line(95, 136, 95, 170, WHITE, 4) + line(78, 153, 112, 153, WHITE, 4)
        + line(161, 136, 161, 170, WHITE, 4) + line(144, 153, 178, 153, WHITE, 4)
    )


@drawing("car")
def car():
    return (
        rect(70, 92, 116, 56, "#e74c3c", r=18)
        + rect(30, 134, 196, 56, "#e74c3c", r=22)
        + rect(82, 102, 42, 36, "#bfe6ff", r=6)
        + rect(132, 102, 42, 36, "#bfe6ff", r=6)
        + circle(216, 156, 9, "#ffd93d")
        + circle(78, 190, 26, INK) + circle(78, 190, 11, "#c9ced4")
        + circle(178, 190, 26, INK) + circle(178, 190, 11, "#c9ced4")
    )


@drawing("boat")
def boat():
    return (
        rect(118, 52, 10, 116, "#8b5a2b", r=4)
        + poly([(132, 62), (196, 156), (132, 156)], WHITE)
        + poly([(114, 68), (56, 156), (114, 156)], "#f5d7a3")
        + poly([(38, 162), (218, 162), (192, 204), (64, 204)], "#c0392b")
        + rect(38, 162, 180, 14, "#e05a4b")
        + path("M20 214 Q56 200 92 214 Q128 228 164 214 Q200 200 236 214",
               stroke="#4d9de0", sw=9)
    )


@drawing("ball")
def ball():
    colours = ["#e74c3c", "#ffd93d", "#4d9de0", "#e74c3c", "#ffd93d", "#4d9de0"]
    wedges = []
    import math
    r = 84
    for i, colour in enumerate(colours):
        a0 = math.radians(i * 60 - 90)
        a1 = math.radians((i + 1) * 60 - 90)
        x0, y0 = 128 + r * math.cos(a0), 128 + r * math.sin(a0)
        x1, y1 = 128 + r * math.cos(a1), 128 + r * math.sin(a1)
        wedges.append(path(
            f"M128 128 L{x0:.1f} {y0:.1f} A {r} {r} 0 0 1 {x1:.1f} {y1:.1f} Z", colour))
    return (
        circle(128, 128, 84, WHITE)
        + "".join(wedges)
        + circle(128, 128, 20, WHITE)
        + ellipse(100, 96, 18, 11, WHITE, rot=(-35, 100, 96), opacity=0.55)
    )


# ------------------------------------------------------------------- food ---

@drawing("apple")
def apple():
    return (
        circle(102, 150, 58, "#e03131")
        + circle(154, 150, 58, "#e03131")
        + rect(100, 108, 56, 60, "#e03131")
        + circle(128, 96, 22, BACKGROUNDS["apple"])
        + rect(124, 62, 10, 44, "#8b5a2b", r=5, rot=(12, 128, 84))
        + ellipse(160, 72, 28, 15, "#4caf50", rot=(-22, 160, 72))
        + ellipse(98, 126, 16, 22, WHITE, rot=(-25, 98, 126), opacity=0.35)
    )


@drawing("banana")
def banana():
    return (
        path("M52 74 C 56 170, 112 208, 200 200 C 216 198, 218 176, 202 174 "
             "C 124 170, 88 142, 82 72 C 80 56, 50 56, 52 74 Z", "#ffd93d")
        + path("M66 86 C 74 158, 116 188, 190 186", stroke="#f0c419", sw=6)
        + ellipse(66, 64, 15, 11, "#8b5a2b", rot=(-12, 66, 64))
        + ellipse(202, 187, 13, 12, "#8b5a2b")
    )


@drawing("cake")
def cake():
    return (
        ellipse(128, 216, 96, 14, WHITE)
        + rect(56, 150, 144, 62, "#d9a066", r=6)
        + rect(56, 132, 144, 20, "#fff5e6")
        + rect(56, 100, 144, 34, "#d9a066", r=6)
        + path("M56 106 Q76 126 96 106 Q116 126 136 106 Q156 126 176 106 "
               "Q192 122 200 108 L200 92 L56 92 Z", "#ff8fab")
        + rect(56, 88, 144, 12, "#ff8fab", r=6)
        + rect(120, 44, 14, 48, WHITE, r=5)
        + rect(120, 56, 14, 10, "#e74c3c")
        + ellipse(127, 34, 9, 14, "#ffb703")
        + circle(84, 176, 9, "#e74c3c") + circle(128, 190, 9, "#e74c3c")
        + circle(172, 176, 9, "#e74c3c")
    )


@drawing("milk")
def milk():
    return (
        path("M96 100 L106 200 Q108 208 116 208 L140 208 Q148 208 150 200 L160 100 Z", WHITE)
        + ellipse(128, 100, 32, 10, "#f2f7fb")
        + path("M90 74 L104 204 Q106 216 118 216 L138 216 Q150 216 152 204 L166 74",
               stroke="#9fc5e8", sw=9)
        + ellipse(128, 74, 38, 11, WHITE)
        + ellipse(128, 74, 38, 11, "none", stroke="#9fc5e8", sw=8)
        + ellipse(114, 140, 8, 20, WHITE, opacity=0.7)
    )


@drawing("egg")
def egg():
    return (
        path("M128 38 C 170 38 198 96 198 140 C 198 182 166 214 128 214 "
             "C 90 214 58 182 58 140 C 58 96 86 38 128 38 Z", "#fff8e7")
        + ellipse(104, 104, 16, 26, WHITE, rot=(-18, 104, 104), opacity=0.85)
        + circle(150, 160, 10, "#f0e4c8") + circle(168, 126, 7, "#f0e4c8")
        + circle(140, 190, 6, "#f0e4c8")
    )


# ----------------------------------------------------------------- things ---

@drawing("heart")
def heart():
    return (
        path("M128 216 C 52 164 26 122 46 88 C 66 52 114 54 128 92 "
             "C 142 54 190 52 210 88 C 230 122 204 164 128 216 Z", "#e03131")
        + ellipse(88, 96, 15, 22, WHITE, rot=(-30, 88, 96), opacity=0.35)
    )


@drawing("key")
def key():
    return (
        circle(84, 128, 48, "#f0b429")
        + circle(84, 128, 20, BACKGROUNDS["key"])
        + rect(120, 114, 110, 28, "#f0b429", r=10)
        + rect(168, 138, 16, 30, "#f0b429", r=5)
        + rect(202, 138, 16, 38, "#f0b429", r=5)
        + circle(84, 104, 7, "#ffd76a", opacity=0.8)
    )


@drawing("book")
def book():
    return (
        rect(52, 54, 156, 148, "#3b6ea5", r=10)
        + rect(76, 64, 126, 128, "#fffdf2", r=4)
        + rect(52, 54, 26, 148, "#2f5d8a", r=10)
        + rect(70, 54, 12, 148, "#2f5d8a")
        + line(94, 96, 186, 96, "#c9d4de", 6)
        + line(94, 120, 186, 120, "#c9d4de", 6)
        + line(94, 144, 158, 144, "#c9d4de", 6)
        + path("M150 54 L150 112 L168 96 L186 112 L186 54 Z", "#e74c3c")
    )


@drawing("shoe")
def shoe():
    # A sneaker in profile: low rounded toe on the left rising to an ankle
    # collar on the right, sitting on a thick white sole.
    return (
        path("M36 172 Q30 140 58 132 L126 112 L148 78 Q164 68 182 78 "
             "L202 92 Q224 110 226 172 Z", "#e0524a")
        + ellipse(168, 82, 24, 13, "#c6443c", rot=(-22, 168, 82))
        + path("M92 170 Q146 138 216 136", stroke=WHITE, sw=11)
        + line(112, 132, 146, 114, WHITE, 8)
        + line(126, 146, 160, 128, WHITE, 8)
        + line(140, 160, 174, 142, WHITE, 8)
        + rect(26, 166, 204, 28, WHITE, r=14)
        + rect(26, 184, 204, 14, "#cfd4da", r=7)
    )


@drawing("hat")
def hat():
    return (
        circle(128, 42, 24, WHITE)
        + path("M52 166 Q52 66 128 66 Q204 66 204 166 Z", "#d64550")
        + path("M52 132 Q128 112 204 132 L204 152 Q128 132 52 152 Z", "#f2f2f2")
        + rect(36, 158, 184, 42, WHITE, r=21)
        + circle(128, 66, 10, "#c23a45")
    )


@drawing("clock")
def clock():
    ticks = ring(128, 130, 74, 12, lambda x, y, a: circle(x, y, 6, "#4d6a8a"))
    return (
        circle(128, 130, 94, "#4d6a8a")
        + circle(128, 130, 80, "#fffdf5")
        + ticks
        + line(128, 130, 128, 78, INK, 10)
        + line(128, 130, 170, 152, INK, 8)
        + circle(128, 130, 10, "#e74c3c")
        + poly([(62, 52), (94, 30), (98, 62)], "#4d6a8a")
        + poly([(194, 52), (162, 30), (158, 62)], "#4d6a8a")
    )


# ------------------------------------------------------- more animals ---

@drawing("horse")
def horse():
    return (
        poly([(96, 62), (88, 22), (122, 52)], "#8b5a2b")
        + poly([(160, 62), (168, 22), (134, 52)], "#8b5a2b")
        + path("M62 60 Q44 130 62 190 L96 180 Q86 120 96 66 Z", "#5c3a1e")
        + ellipse(132, 130, 56, 70, "#a9703f")
        + ellipse(140, 186, 34, 30, "#d9a066")
        + ellipse(128, 182, 7, 9, "#5c3a1e") + ellipse(154, 182, 7, 9, "#5c3a1e")
        + eyes(106, 162, 108)
        + circle(102, 104, 4, WHITE) + circle(158, 104, 4, WHITE)
    )


@drawing("pig")
def pig():
    return (
        poly([(74, 84), (66, 42), (110, 66)], "#f2a0b8")
        + poly([(182, 84), (190, 42), (146, 66)], "#f2a0b8")
        + circle(128, 136, 66, "#f7b3c6")
        + ellipse(128, 162, 40, 30, "#f2a0b8")
        + ellipse(114, 160, 8, 11, "#d97f9c") + ellipse(142, 160, 8, 11, "#d97f9c")
        + eyes(104, 152, 114)
        + circle(100, 110, 3, WHITE) + circle(148, 110, 3, WHITE)
    )


@drawing("sheep")
def sheep():
    # The head has to sit clear of the fleece and read as a face, or the whole
    # thing is a cloud on legs.
    fleece = "".join(
        circle(x, y, 32, "#fbf7f0")
        for x, y in [(112, 116), (156, 108), (192, 130), (196, 166), (116, 170), (158, 176)]
    )
    return (
        line(120, 190, 120, 222, "#6b5a4e", 12) + line(154, 194, 154, 224, "#6b5a4e", 12)
        + line(188, 190, 188, 222, "#6b5a4e", 12)
        + fleece
        + rect(104, 116, 96, 68, "#fbf7f0", r=34)
        + ellipse(46, 130, 22, 15, "#5d4d43", rot=(-30, 46, 130))
        + ellipse(96, 126, 22, 15, "#5d4d43", rot=(30, 96, 126))
        + ellipse(70, 158, 38, 42, "#6b5a4e")
        + path("M40 138 Q70 118 100 138 Q92 150 70 150 Q48 150 40 138 Z", "#fbf7f0")
        + circle(56, 152, 7, INK) + circle(84, 152, 7, INK)
        + ellipse(70, 180, 13, 9, "#4a3d35")
        + line(120, 200, 120, 222, "#6b5a4e", 12)
    )


@drawing("rabbit")
def rabbit():
    return (
        ellipse(100, 64, 19, 52, "#d8d2cc", rot=(-10, 100, 64))
        + ellipse(158, 64, 19, 52, "#d8d2cc", rot=(10, 158, 64))
        + ellipse(100, 68, 10, 36, "#f2b8c6", rot=(-10, 100, 68))
        + ellipse(158, 68, 10, 36, "#f2b8c6", rot=(10, 158, 68))
        + circle(128, 158, 58, "#e4ded8")
        + eyes(106, 150, 150, 9)
        + ellipse(128, 176, 12, 9, "#f2b8c6")
        + smile("M128 185 L128 192 M128 192 Q116 202 106 192 M128 192 Q140 202 150 192", 5)
        + line(38, 176, 92, 180, INK, 4) + line(42, 194, 94, 188, INK, 4)
        + line(218, 176, 164, 180, INK, 4) + line(214, 194, 162, 188, INK, 4)
    )


@drawing("fox")
def fox():
    return (
        poly([(66, 116), (58, 40), (116, 80)], "#e8722c")
        + poly([(190, 116), (198, 40), (140, 80)], "#e8722c")
        + poly([(70, 104), (64, 56), (106, 82)], "#3d2b23")
        + poly([(186, 104), (192, 56), (150, 82)], "#3d2b23")
        + path("M128 82 Q196 92 186 140 Q176 186 128 206 Q80 186 70 140 Q60 92 128 82 Z", "#f0823a")
        + path("M128 124 Q168 132 158 166 Q146 196 128 206 Q110 196 98 166 Q88 132 128 124 Z", "#fbf3ea")
        + eyes(104, 152, 128, 9)
        + ellipse(128, 168, 12, 9, INK)
    )


@drawing("turtle")
def turtle():
    # The plates need real contrast and visible gaps, otherwise the shell just
    # reads as a green circle.
    plates = ring(128, 132, 40, 6, lambda x, y, a: circle(x, y, 17, "#3f7a30"))
    return (
        ellipse(58, 180, 26, 17, "#8fcf72", rot=(-25, 58, 180))
        + ellipse(198, 180, 26, 17, "#8fcf72", rot=(25, 198, 180))
        + ellipse(56, 90, 24, 16, "#8fcf72", rot=(25, 56, 90))
        + ellipse(200, 90, 24, 16, "#8fcf72", rot=(-25, 200, 90))
        + circle(214, 132, 30, "#8fcf72")
        + circle(226, 124, 6, INK)
        + smile("M214 146 Q226 154 236 146", 5)
        + circle(128, 132, 80, "#2f5f24")
        + circle(128, 132, 70, "#7cb85f")
        + plates
        + circle(128, 132, 20, "#3f7a30")
    )


@drawing("snail")
def snail():
    return (
        path("M36 196 Q40 158 84 156 L176 156 Q210 158 210 196 Z", "#e8c9a0")
        + ellipse(124, 196, 96, 16, "#dcb98c")
        + path(spiral(112, 128, 8, 60, 2.4), stroke="#c98b3a", sw=17)
        + path(spiral(112, 128, 8, 60, 2.4), stroke="#f0b429", sw=9)
        + line(190, 156, 206, 108, "#e8c9a0", 9)
        + line(210, 158, 232, 120, "#e8c9a0", 9)
        + circle(206, 102, 9, INK) + circle(234, 114, 9, INK)
    )


# ---------------------------------------------------------- more food ---

@drawing("bread")
def bread():
    return (
        path("M40 196 L40 122 Q40 62 128 62 Q216 62 216 122 L216 196 Z", "#c98b3a")
        + path("M56 190 L56 126 Q56 80 128 80 Q200 80 200 126 L200 190 Z", "#e8b56b")
        + path("M78 108 Q98 88 118 104", stroke="#c98b3a", sw=8)
        + path("M138 104 Q158 88 178 106", stroke="#c98b3a", sw=8)
        + rect(36, 190, 184, 18, "#a9703f", r=9)
    )


@drawing("cheese")
def cheese():
    return (
        poly([(34, 174), (34, 120), (216, 74), (216, 128)], "#e8a800")
        + poly([(34, 120), (216, 74), (216, 128), (34, 174)], "#ffd93d")
        + poly([(34, 120), (216, 74), (196, 62), (54, 106)], "#ffe88a")
        + circle(84, 138, 15, "#e8a800") + circle(140, 118, 11, "#e8a800")
        + circle(184, 110, 13, "#e8a800") + circle(112, 156, 9, "#e8a800")
    )


@drawing("carrot")
def carrot():
    return (
        path("M100 70 Q92 26 64 22 Q66 56 94 74 Z", "#4caf50")
        + path("M128 66 Q128 20 128 14 Q152 34 146 70 Z", "#43a047")
        + path("M156 70 Q166 28 194 24 Q190 58 162 76 Z", "#4caf50")
        + path("M92 78 L164 78 Q152 190 128 224 Q104 190 92 78 Z", "#f4913e")
        + line(104, 108, 148, 104, "#e07b39", 6)
        + line(110, 140, 144, 136, "#e07b39", 6)
        + line(116, 172, 140, 170, "#e07b39", 6)
    )


@drawing("pear")
def pear():
    return (
        rect(124, 34, 9, 40, "#8b5a2b", r=5, rot=(10, 128, 54))
        + ellipse(162, 52, 26, 14, "#4caf50", rot=(-24, 162, 52))
        + circle(128, 162, 60, "#a4c93a")
        + ellipse(128, 96, 34, 40, "#a4c93a")
        + ellipse(106, 140, 15, 22, "#c3de65", rot=(-18, 106, 140), opacity=0.7)
    )


@drawing("lemon")
def lemon():
    return (
        path("M26 128 Q40 68 128 68 Q216 68 230 128 Q216 188 128 188 Q40 188 26 128 Z", "#ffd93d")
        + ellipse(94, 106, 22, 12, "#ffe88a", rot=(-16, 94, 106))
        + ellipse(206, 76, 26, 14, "#4caf50", rot=(-28, 206, 76))
        + circle(26, 128, 8, "#f0c419") + circle(230, 128, 8, "#f0c419")
    )


# ------------------------------------------------------- around a room ---

@drawing("chair")
def chair():
    return (
        rect(74, 30, 110, 116, "#a9703f", r=14)
        + rect(88, 48, 82, 80, "#c98b3a", r=10)
        + rect(58, 132, 142, 26, "#8b5a2b", r=10)
        + rect(70, 152, 18, 76, "#a9703f", r=8)
        + rect(170, 152, 18, 76, "#a9703f", r=8)
        + rect(70, 196, 118, 12, "#8b5a2b", r=6)
    )


@drawing("table")
def table():
    return (
        rect(24, 92, 208, 28, "#c98b3a", r=12)
        + rect(24, 114, 208, 12, "#a9703f", r=6)
        + rect(52, 124, 20, 104, "#a9703f", r=8)
        + rect(184, 124, 20, 104, "#a9703f", r=8)
        + rect(52, 160, 152, 12, "#8b5a2b", r=6)
    )


@drawing("bed")
def bed():
    return (
        rect(24, 70, 40, 150, "#8b5a2b", r=12)
        + rect(200, 124, 32, 96, "#8b5a2b", r=12)
        + rect(36, 148, 190, 44, "#f7f3ea", r=14)
        + path("M108 148 L226 148 Q226 192 210 192 L108 192 Z", "#4d9de0")
        + path("M108 148 L134 148 L134 192 L108 192 Z", "#7fc0ec")
        + rect(54, 118, 62, 38, WHITE, r=16, rot=(-6, 84, 136))
        + rect(36, 186, 190, 14, "#c98b3a", r=7)
    )


@drawing("lamp")
def lamp():
    return (
        poly([(76, 132), (180, 132), (200, 60), (56, 60)], "#f0b429")
        + poly([(76, 132), (180, 132), (170, 148), (86, 148)], "#e8a800")
        + rect(120, 148, 16, 66, "#6b5a4e", r=6)
        + ellipse(128, 220, 54, 14, "#5d4d43")
        + circle(128, 100, 22, "#ffe88a", opacity=0.7)
    )


@drawing("door")
def door():
    return (
        rect(44, 26, 168, 206, "#a9703f", r=10)
        + rect(60, 42, 136, 190, "#c98b3a", r=6)
        + rect(78, 60, 100, 62, "#8b5a2b", r=6)
        + rect(90, 72, 76, 38, "#e8b56b", r=4)
        + rect(78, 140, 100, 76, "#8b5a2b", r=6)
        + rect(90, 152, 76, 52, "#e8b56b", r=4)
        + circle(174, 134, 11, "#f0b429")
    )


# --------------------------------------------------- getting about ---

@drawing("bike")
def bike():
    wheel = lambda cx: (
        circle(cx, 160, 52, "none", stroke="#3d4a5c", sw=10)
        + ring(cx, 160, 40, 8, lambda x, y, a: line(cx, 160, x, y, "#9aa6b4", 4))
        + circle(cx, 160, 9, "#3d4a5c")
    )
    return (
        wheel(66) + wheel(190)
        + path("M66 160 L112 100 L164 100 L190 160 M112 100 L134 160 L190 160",
               stroke="#e74c3c", sw=9)
        + path("M104 92 L126 92", stroke="#3d4a5c", sw=9)
        + path("M164 100 L172 74 L196 74", stroke="#3d4a5c", sw=9)
        + ellipse(112, 86, 24, 10, "#3d4a5c", rot=(-8, 112, 86))
    )


@drawing("train")
def train():
    return (
        circle(84, 116, 13, "#cfd8e3", opacity=0.9)
        + circle(112, 92, 17, "#cfd8e3", opacity=0.8)
        + circle(146, 72, 21, "#cfd8e3", opacity=0.7)
        + rect(36, 128, 184, 68, "#e74c3c", r=14)
        + rect(120, 82, 92, 52, "#c0392b", r=12)
        + rect(136, 94, 60, 32, "#bfe6ff", r=6)
        + rect(56, 100, 30, 32, "#c0392b", r=6)
        + rect(50, 92, 42, 14, "#8b3a2e", r=6)
        + circle(74, 202, 24, INK) + circle(74, 202, 10, "#c9ced4")
        + circle(148, 202, 24, INK) + circle(148, 202, 10, "#c9ced4")
        + circle(204, 160, 12, "#ffd93d")
    )


@drawing("leaf")
def leaf():
    # One leaf, not a sprig: the word is singular in both languages.
    return (
        path("M128 222 Q122 186 126 150", stroke="#6b4a24", sw=10)
        + path("M128 22 C 196 72 202 152 128 216 C 54 152 60 72 128 22 Z", "#4caf50")
        + path("M128 22 C 196 72 202 152 128 216 Z", "#43a047")
        + path("M128 34 L128 210", stroke="#2f7a33", sw=6)
        + path("M128 74 L178 62 M128 112 L190 104 M128 150 L182 152 "
               "M128 74 L78 62 M128 112 L66 104 M128 150 L74 152",
               stroke="#2f7a33", sw=5)
    )


# ------------------------------------------------------------------ main ---

def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    missing = sorted(set(BACKGROUNDS) - set(DRAWINGS))
    extra = sorted(set(DRAWINGS) - set(BACKGROUNDS))
    if missing or extra:
        print(f"background/drawing mismatch: missing={missing} extra={extra}")
        return 1

    for name in sorted(DRAWINGS):
        content = svg(BACKGROUNDS[name], DRAWINGS[name]())
        (OUT / f"{name}.svg").write_text(content + "\n", encoding="utf-8")
    print(f"wrote {len(DRAWINGS)} pictures to {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
