"""Tiny SVG builder shared by the picture generator.

Godot imports SVG through ThorVG, which handles shapes, paths, groups and
transforms but not filters, masks or text. Everything here stays inside that
subset so what renders in a browser also renders in the game.
"""

import math

SIZE = 256
CORNER = 40


def svg(background: str, *body: str) -> str:
    parts = "".join(body)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {SIZE} {SIZE}" '
        f'width="{SIZE}" height="{SIZE}">'
        f'<rect width="{SIZE}" height="{SIZE}" rx="{CORNER}" fill="{background}"/>'
        f"{parts}</svg>"
    )


def _extra(rot=None, opacity=None, stroke=None, sw=0.0):
    out = ""
    if rot is not None:
        angle, cx, cy = rot
        out += f' transform="rotate({_n(angle)} {_n(cx)} {_n(cy)})"'
    if opacity is not None:
        out += f' opacity="{_n(opacity)}"'
    if stroke is not None:
        out += f' stroke="{stroke}" stroke-width="{_n(sw)}" stroke-linecap="round" stroke-linejoin="round"'
    return out


def _n(value) -> str:
    """Trims float noise so the committed files stay readable."""
    text = f"{float(value):.2f}".rstrip("0").rstrip(".")
    return text if text not in ("", "-0") else "0"


def circle(cx, cy, r, fill, **kw) -> str:
    return f'<circle cx="{_n(cx)}" cy="{_n(cy)}" r="{_n(r)}" fill="{fill}"{_extra(**kw)}/>'


def ellipse(cx, cy, rx, ry, fill, **kw) -> str:
    return (
        f'<ellipse cx="{_n(cx)}" cy="{_n(cy)}" rx="{_n(rx)}" ry="{_n(ry)}" '
        f'fill="{fill}"{_extra(**kw)}/>'
    )


def rect(x, y, w, h, fill, r=0, **kw) -> str:
    radius = f' rx="{_n(r)}"' if r else ""
    return (
        f'<rect x="{_n(x)}" y="{_n(y)}" width="{_n(w)}" height="{_n(h)}"'
        f'{radius} fill="{fill}"{_extra(**kw)}/>'
    )


def poly(points, fill, **kw) -> str:
    pts = " ".join(f"{_n(x)},{_n(y)}" for x, y in points)
    return f'<polygon points="{pts}" fill="{fill}"{_extra(**kw)}/>'


def path(d, fill="none", **kw) -> str:
    return f'<path d="{d}" fill="{fill}"{_extra(**kw)}/>'


def line(x1, y1, x2, y2, stroke, sw, **kw) -> str:
    return (
        f'<line x1="{_n(x1)}" y1="{_n(y1)}" x2="{_n(x2)}" y2="{_n(y2)}" '
        f'stroke="{stroke}" stroke-width="{_n(sw)}" stroke-linecap="round"{_extra(**kw)}/>'
    )


def group(*body, **kw) -> str:
    return f'<g{_extra(**kw)}>' + "".join(body) + "</g>"


def star_points(cx, cy, outer, inner, count=5, rotation=-90):
    """Alternating outer/inner vertices, first point straight up by default."""
    points = []
    for i in range(count * 2):
        radius = outer if i % 2 == 0 else inner
        angle = math.radians(rotation + i * 180.0 / count)
        points.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle)))
    return points


def ring(cx, cy, r, count, draw, rotation=0.0):
    """Repeats a drawing callback evenly around a circle."""
    out = []
    for i in range(count):
        angle = math.radians(rotation + i * 360.0 / count)
        out.append(draw(cx + r * math.cos(angle), cy + r * math.sin(angle), math.degrees(angle)))
    return "".join(out)


def spiral(cx, cy, inner, outer, turns=2.4, steps=90):
    """Path data for an outward spiral — a snail shell, mostly."""
    points = []
    for i in range(steps):
        t = i / (steps - 1)
        angle = t * turns * 2 * math.pi
        r = inner + (outer - inner) * t
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    return "M" + " L".join(f"{_n(x)} {_n(y)}" for x, y in points)
