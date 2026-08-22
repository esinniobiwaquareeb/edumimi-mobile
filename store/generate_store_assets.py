#!/usr/bin/env python3
"""Generate Play Store / App Store marketing assets for mock.edumimi."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE_LOGO = ROOT / "assets" / "branding" / "logo-icon-transparent.png"
OUT_DIR = ROOT / "store" / "assets"

TEAL = (15, 118, 110)
TEAL_DARK = (19, 78, 74)
GOLD = (197, 155, 82)
WHITE = (255, 255, 255)
TEXT = (19, 39, 37)
MUTED = (87, 107, 105)


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def _paste_logo(canvas: Image.Image, box: tuple[int, int, int, int]) -> None:
    logo = Image.open(SOURCE_LOGO).convert("RGBA")
    left, top, right, bottom = box
    target = min(right - left, bottom - top)
    logo.thumbnail((target, target), Image.Resampling.LANCZOS)
    offset = (left + (right - left - logo.width) // 2, top + (bottom - top - logo.height) // 2)
    canvas.paste(logo, offset, logo)


def _draw_grid(draw: ImageDraw.ImageDraw, width: int, height: int, color: tuple[int, int, int, int]) -> None:
    step = 36
    for x in range(0, width, step):
        draw.line([(x, 0), (x, height)], fill=color, width=1)
    for y in range(0, height, step):
        draw.line([(0, y), (width, y)], fill=color, width=1)


def render_play_store_icon() -> None:
    size = 512
    canvas = Image.new("RGBA", (size, size), WHITE + (255,))
    _paste_logo(canvas, (72, 72, size - 72, size - 72))
    canvas.convert("RGB").save(OUT_DIR / "play-store-icon-512.png", optimize=True)


def render_app_store_icon() -> None:
    size = 1024
    canvas = Image.new("RGBA", (size, size), WHITE + (255,))
    _paste_logo(canvas, (140, 140, size - 140, size - 140))
    canvas.convert("RGB").save(OUT_DIR / "app-store-icon-1024.png", optimize=True)


def render_feature_graphic() -> None:
    width, height = 1024, 500
    canvas = Image.new("RGBA", (width, height), TEAL + (255,))
    draw = ImageDraw.Draw(canvas)

    for y in range(height):
        ratio = y / max(1, height - 1)
        color = tuple(int(TEAL[i] * (1 - ratio) + TEAL_DARK[i] * ratio) for i in range(3))
        draw.line([(0, y), (width, y)], fill=color + (255,))

    _draw_grid(draw, width, height, (255, 255, 255, 18))

    glow = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse((680, -80, 1120, 360), fill=(255, 255, 255, 28))
    glow_draw.ellipse((-120, 220, 260, 620), fill=(197, 155, 82, 36))
    canvas = Image.alpha_composite(canvas, glow)
    draw = ImageDraw.Draw(canvas)

    _paste_logo(canvas, (56, 96, 220, 404))

    title_font = _load_font(58, bold=True)
    subtitle_font = _load_font(28, bold=True)
    body_font = _load_font(22)

    draw.text((250, 132), "mock.edumimi", font=title_font, fill=WHITE + (255,))
    draw.text((252, 206), "JAMB · WAEC · NECO practice", font=subtitle_font, fill=(220, 245, 242, 255))
    draw.text((252, 256), "Timed mocks · offline drills · streak reminders", font=body_font, fill=(196, 223, 220, 255))

    pill_y = 330
    pills = ["Full mocks", "Study Squad", "Paystack packs"]
    x = 252
    for label in pills:
        text_bbox = draw.textbbox((0, 0), label, font=body_font)
        pill_w = text_bbox[2] - text_bbox[0] + 28
        pill_h = 38
        draw.rounded_rectangle((x, pill_y, x + pill_w, pill_y + pill_h), radius=19, fill=(255, 255, 255, 34))
        draw.text((x + 14, pill_y + 8), label, font=body_font, fill=WHITE + (255,))
        x += pill_w + 12

    canvas.convert("RGB").save(OUT_DIR / "feature-graphic-1024x500.png", optimize=True)


def render_screenshot_frames() -> None:
    """Marketing frames for manual screenshot insertion."""
    screens = [
        ("01-dashboard", "Your practice hub"),
        ("02-exam-session", "Timed exam sessions"),
        ("03-results", "Detailed score breakdown"),
        ("04-community", "Study Squad chat"),
        ("05-packages", "Unlock full mocks"),
    ]
    frame_dir = OUT_DIR / "screenshot-frames"
    frame_dir.mkdir(parents=True, exist_ok=True)

    width, height = 1080, 1920
    title_font = _load_font(54, bold=True)
    caption_font = _load_font(30)

    for slug, caption in screens:
        canvas = Image.new("RGBA", (width, height), (247, 248, 247, 255))
        draw = ImageDraw.Draw(canvas)

        draw.rounded_rectangle((48, 48, width - 48, height - 220), radius=40, fill=WHITE + (255,), outline=(221, 230, 228, 255), width=2)
        draw.text((96, height - 170), caption, font=title_font, fill=TEXT + (255,))
        draw.text((96, height - 108), "Replace this frame with an in-app screenshot", font=caption_font, fill=MUTED + (255,))

        inner = (96, 96, width - 96, height - 280)
        draw.rounded_rectangle(inner, radius=28, fill=(241, 244, 243, 255))
        draw.text((inner[0] + 36, inner[1] + 36), "Capture from device/simulator", font=caption_font, fill=MUTED + (255,))

        canvas.convert("RGB").save(frame_dir / f"{slug}-1080x1920.png", optimize=True)


def render_promo_tile() -> None:
    size = 180
    canvas = Image.new("RGBA", (size, size), TEAL + (255,))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((8, 8, size - 8, size - 8), radius=28, fill=WHITE + (255,))
    _paste_logo(canvas, (24, 24, size - 24, size - 24))
    canvas.convert("RGB").save(OUT_DIR / "promo-tile-180.png", optimize=True)


def main() -> None:
    if not SOURCE_LOGO.exists():
        raise SystemExit(f"Missing logo asset: {SOURCE_LOGO}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    render_play_store_icon()
    render_app_store_icon()
    render_feature_graphic()
    render_promo_tile()
    render_screenshot_frames()
    print(f"Generated store assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
