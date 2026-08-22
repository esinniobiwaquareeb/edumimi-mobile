#!/usr/bin/env python3
"""Regenerate iOS/Android launcher icons with a clean white background."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "branding" / "logo-icon.png"
IOS_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
BACKGROUND = (255, 255, 255)


def strip_dark_background(image: Image.Image) -> Image.Image:
    pixels = image.load()
    width, height = image.size
    for y in range(height):
        for x in range(width):
            red, green, blue, alpha = pixels[x, y]
            if red < 45 and green < 45 and blue < 45:
                pixels[x, y] = (255, 255, 255, 0)
    return image


def render_icon(size: int, padding_ratio: float = 0.14) -> Image.Image:
    source = Image.open(SOURCE).convert("RGBA")
    source = strip_dark_background(source)

    canvas = Image.new("RGBA", (size, size), BACKGROUND + (255,))
    padding = int(size * padding_ratio)
    target = max(1, size - (padding * 2))
    scale = min(target / source.width, target / source.height)
    resized = source.resize(
        (max(1, int(source.width * scale)), max(1, int(source.height * scale))),
        Image.Resampling.LANCZOS,
    )
    offset = ((size - resized.width) // 2, (size - resized.height) // 2)
    canvas.paste(resized, offset, resized)
    return canvas.convert("RGB")


def write_ios_icons() -> None:
    contents = json.loads((IOS_DIR / "Contents.json").read_text())
    for entry in contents["images"]:
        filename = entry["filename"]
        if not filename:
            continue
        size_label = entry["size"]
        scale_label = entry.get("scale", "1x")
        base = float(size_label.split("x")[0])
        scale = float(scale_label.replace("x", ""))
        pixel_size = int(round(base * scale))
        render_icon(pixel_size).save(IOS_DIR / filename, format="PNG", optimize=True)


def write_android_icons() -> None:
    for folder, size in ANDROID_SIZES.items():
        target_dir = ROOT / "android" / "app" / "src" / "main" / "res" / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        render_icon(size).save(target_dir / "ic_launcher.png", format="PNG", optimize=True)


def write_clean_logo_asset() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    source = strip_dark_background(source)
    source.save(ROOT / "assets" / "branding" / "logo-icon-transparent.png", format="PNG", optimize=True)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source logo: {SOURCE}")
    write_clean_logo_asset()
    write_ios_icons()
    write_android_icons()
    print("Generated clean launcher icons for iOS and Android.")


if __name__ == "__main__":
    main()
