"""Extract axes/colorbar rectangles and compare relative Legacy/M2.3 geometry."""
import json
import sys
import pdfplumber


def rectangles(path):
    with pdfplumber.open(path) as document:
        page = document.pages[0]
        result = []
        for item in page.rects:
            box = (item["x0"], item["y0"], item["width"], item["height"])
            if box[2] <= 5 or box[3] <= 5:
                continue
            if any(max(abs(box[i] - old[i]) for i in range(4)) < 0.2 for old in result):
                continue
            result.append(box)
        return result, (float(page.width), float(page.height))


def kind(box):
    ratio = box[2] / box[3]
    if ratio < 0.25:
        return "colorbar_vertical"
    if ratio > 4:
        return "colorbar_horizontal"
    return "axes"


def normalize(boxes):
    left = min(b[0] for b in boxes)
    bottom = min(b[1] for b in boxes)
    right = max(b[0] + b[2] for b in boxes)
    top = max(b[1] + b[3] for b in boxes)
    width, height = right - left, top - bottom
    return [((b[0] - left) / width, (b[1] - bottom) / height,
             b[2] / width, b[3] / height) for b in boxes]


def overlap(first, second):
    width = min(first[0] + first[2], second[0] + second[2]) - max(first[0], second[0])
    height = min(first[1] + first[3], second[1] + second[3]) - max(first[1], second[1])
    return max(0.0, width) * max(0.0, height)


legacy, legacy_page = rectangles(sys.argv[1])
m23, m23_page = rectangles(sys.argv[2])
sort_key = lambda b: (kind(b), b[0], b[1])
legacy_sorted = sorted(zip(legacy, normalize(legacy)), key=lambda pair: sort_key(pair[0]))
m23_sorted = sorted(zip(m23, normalize(m23)), key=lambda pair: sort_key(pair[0]))
delta = None
if len(legacy_sorted) == len(m23_sorted):
    delta = max(abs(a - b) for (_, first), (_, second) in zip(legacy_sorted, m23_sorted)
                for a, b in zip(first, second))
axes = [b for b in m23 if kind(b) == "axes"]
bars = [b for b in m23 if kind(b).startswith("colorbar")]
bar_axes_overlap = max([overlap(bar, axis) for bar in bars for axis in axes] or [0.0])
inside = all(b[0] >= -0.01 and b[1] >= -0.01 and
             b[0] + b[2] <= m23_page[0] + 0.01 and
             b[1] + b[3] <= m23_page[1] + 0.01 for b in m23)
print(json.dumps({
    "legacy_rectangles": len(legacy), "m23_rectangles": len(m23),
    "axes": len(axes), "colorbars": len(bars),
    "max_relative_geometry_delta": delta,
    "max_colorbar_axes_overlap_points2": bar_axes_overlap,
    "all_rectangles_inside_page": inside,
    "legacy_boxes": legacy, "m23_boxes": m23,
}, separators=(",", ":")))
