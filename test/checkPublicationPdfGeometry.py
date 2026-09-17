"""Check real publication PDFs: physical pages, full glyphs, title/data separation.

This is a bounded synthetic regression gate, not a generic visual-quality
detector. PDF font character boxes are checked even when the page crops them.
"""
import argparse
import json
from pathlib import Path
import pdfplumber


def check(folder):
    records = json.loads((folder / "geometry-manifest.json").read_text(encoding="utf-8"))
    rows = []
    for record in records:
        with pdfplumber.open(folder / record["pdf"]) as document:
            assert len(document.pages) == 1, record["case"]
            page = document.pages[0]
            width_mm, height_mm = float(page.width)*25.4/72, float(page.height)*25.4/72
            assert abs(width_mm-record["widthMm"]) < .02, (record["case"], "width", width_mm)
            assert abs(height_mm-record["heightMm"]) < .02, (record["case"], "height", height_mm)
            outside = [c for c in page.chars if c["text"].strip() and
                       (c["x0"] < -.1 or c["top"] < -.1 or
                        c["x1"] > page.width+.1 or c["bottom"] > page.height+.1)]
            assert not outside, (record["case"], "clipped glyphs", [(c["text"], c["top"]) for c in outside])
            words = page.extract_words()
            title_boxes = []
            for title in record["titles"]:
                matches = [w for w in words if w["text"] == title["text"]]
                assert matches, (record["case"], "missing title", title["text"])
                word = matches[0]
                if title["checkAbovePlot"]:
                    assert page.height-word["bottom"] > title["plotTopPt"], (record["case"], "title overlaps plot")
                title_boxes.append({"text": title["text"], "top": word["top"], "bottom": word["bottom"]})
            rows.append({"case": record["case"], "widthMm": width_mm, "heightMm": height_mm,
                         "glyphs": len(page.chars), "titles": title_boxes, "status": "PASS"})
    print(json.dumps(rows, indent=2))
    print(f"PUBLICATION_PDF_GEOMETRY_PASS: {len(rows)} PDFs")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=Path)
    check(parser.parse_args().directory)
