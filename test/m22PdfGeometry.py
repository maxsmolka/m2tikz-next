#!/usr/bin/env python3
"""Extract and compare axes plot rectangles from Legacy/M2.2 PDFs."""

import argparse
import itertools
import json

import pdfplumber


def rectangles(path):
    with pdfplumber.open(path) as document:
        if len(document.pages) != 1:
            raise ValueError(f"expected one page: {path}")
        page = document.pages[0]
        candidates = []
        for item in page.rects:
            width = float(item["width"])
            height = float(item["height"])
            linewidth = float(item.get("linewidth") or 0)
            if (width >= page.width * 0.15 and height >= page.height * 0.15
                    and linewidth <= 1.1):
                candidates.append(
                    [float(item["x0"]), float(item["y0"]), width, height]
                )
    unique = []
    for candidate in candidates:
        if not any(max(abs(a - b) for a, b in zip(candidate, old)) < 0.5 for old in unique):
            unique.append(candidate)
    return unique


def normalize(values):
    if not values:
        return []
    left = min(item[0] for item in values)
    bottom = min(item[1] for item in values)
    right = max(item[0] + item[2] for item in values)
    top = max(item[1] + item[3] for item in values)
    width = right - left
    height = top - bottom
    return [
        [(item[0] - left) / width, (item[1] - bottom) / height,
         item[2] / width, item[3] / height]
        for item in values
    ]


def components(first, second):
    center = max(
        abs(first[0] + first[2] / 2 - second[0] - second[2] / 2),
        abs(first[1] + first[3] / 2 - second[1] - second[3] / 2),
    )
    width = abs(first[2] - second[2])
    height = abs(first[3] - second[3])
    return center, width, height


def best_match(reference, candidate):
    if len(reference) != len(candidate):
        raise ValueError(
            f"axes rectangle count differs: {len(reference)} vs {len(candidate)}"
        )
    best = None
    for order in itertools.permutations(range(len(candidate))):
        values = [components(reference[k], candidate[order[k]]) for k in range(len(reference))]
        score = sum(sum(item) for item in values)
        if best is None or score < best[0]:
            best = score, order, values
    return best


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("legacy_pdf")
    parser.add_argument("m22_pdf")
    parser.add_argument("expected_axes", type=int)
    args = parser.parse_args()

    legacy_raw = rectangles(args.legacy_pdf)
    m22_raw = rectangles(args.m22_pdf)
    if len(legacy_raw) != args.expected_axes or len(m22_raw) != args.expected_axes:
        raise ValueError(
            f"expected {args.expected_axes} axes rectangles, "
            f"found legacy={len(legacy_raw)} m22={len(m22_raw)}"
        )
    legacy = normalize(legacy_raw)
    m22 = normalize(m22_raw)
    _, order, values = best_match(legacy, m22)
    default = [[0.0, 0.0, 1.0, 1.0] for _ in legacy]
    _, _, default_values = best_match(legacy, default)

    payload = {
        "legacy_boxes": legacy_raw,
        "m22_boxes": m22_raw,
        "matched_order": order,
        "max_center_delta": max((item[0] for item in values), default=0.0),
        "max_width_delta": max((item[1] for item in values), default=0.0),
        "max_height_delta": max((item[2] for item in values), default=0.0),
        "mean_geometry_delta": (
            sum(sum(item) for item in values) / (3 * len(values)) if values else 0.0
        ),
        "old_default_mean_geometry_delta": (
            sum(sum(item) for item in default_values) / (3 * len(default_values))
            if default_values else 0.0
        ),
    }
    print(json.dumps(payload, separators=(",", ":")))


if __name__ == "__main__":
    main()
