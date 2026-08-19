"""Small, non-gating raster-difference proof of concept for M2 PDFs."""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance


def centered_canvas(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    canvas = Image.new("L", size, 255)
    offset = ((size[0] - image.width) // 2, (size[1] - image.height) // 2)
    canvas.paste(image.convert("L"), offset)
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("legacy")
    parser.add_argument("m2")
    parser.add_argument("difference")
    args = parser.parse_args()

    legacy = Image.open(args.legacy)
    m2 = Image.open(args.m2)
    size = (max(legacy.width, m2.width), max(legacy.height, m2.height))
    legacy_gray = centered_canvas(legacy, size)
    m2_gray = centered_canvas(m2, size)
    difference = ImageChops.difference(legacy_gray, m2_gray)
    pixels = list(difference.getdata())
    mae = sum(pixels) / (255.0 * len(pixels)) if pixels else 0.0
    changed = sum(value > 8 for value in pixels) / len(pixels) if pixels else 0.0

    difference_path = Path(args.difference)
    difference_path.parent.mkdir(parents=True, exist_ok=True)
    ImageEnhance.Contrast(difference).enhance(2.0).save(difference_path)
    print(json.dumps({
        "legacy_width": legacy.width,
        "legacy_height": legacy.height,
        "m2_width": m2.width,
        "m2_height": m2.height,
        "normalized_mae": round(mae, 8),
        "changed_fraction": round(changed, 8),
    }))


if __name__ == "__main__":
    main()
