"""Verify actual legend glyph bounds, rows/order, plot separation and page size."""
import json
import sys
from pathlib import Path
import pdfplumber

folder = Path(sys.argv[1])
records = json.loads((folder / 'legend-manifest.json').read_text(encoding='utf-8'))
for r in records:
    with pdfplumber.open(folder / r['pdf']) as doc:
        assert len(doc.pages) == 1
        p = doc.pages[0]
        assert abs(float(p.width)*25.4/72-r['widthMm']) < .02, (r['case'], 'width')
        assert abs(float(p.height)*25.4/72-r['heightMm']) < .02, (r['case'], 'height')
        assert all(c['x0'] >= -.1 and c['top'] >= -.1 and c['x1'] <= p.width+.1 and
                   c['bottom'] <= p.height+.1 for c in p.chars), (r['case'], 'cropped glyph')
        words = p.extract_words()
        labels = []
        side = r.get('outsideSide', 'north')
        for label in r['labels']:
            matches = [w for w in words if w['text'] == label]
            assert len(matches) == 1, (r['case'], label)
            labels.append(matches[0])
        for i, w in enumerate(labels):
            if r.get('outside', True):
                if side == 'south':
                    assert w['top'] > p.height-r['plotBottomPt']-r['borderPt'], (r['case'], 'legend overlaps plot')
                else:
                    assert w['bottom'] < p.height-r['plotTopPt']-r['borderPt'], (r['case'], 'legend overlaps plot')
            if i % r['columns']:
                assert w['x0'] > labels[i-1]['x0'] and abs(w['top']-labels[i-1]['top']) < .5, (r['case'], 'column order')
            elif i:
                assert w['top'] > labels[i-r['columns']]['top']+1, (r['case'], 'row order')
        if r['title']:
            title = [w for w in words if w['text'] == r['title']]
            if side == 'south':
                assert len(title) == 1 and title[0]['bottom'] < p.height-r['plotTopPt']-r['borderPt'], (r['case'], 'title overlap')
            else:
                assert len(title) == 1 and title[0]['top'] > max(w['bottom'] for w in labels), (r['case'], 'title overlap')
        if side == 'south' and r.get('xlabel'):
            xlabel = [w for w in words if w['text'] == r['xlabel']]
            assert len(xlabel) == 1 and xlabel[0]['bottom']+.5 < min(w['top'] for w in labels), (r['case'], 'xlabel overlap')
        if side == 'south':
            bottom = p.height-r['plotBottomPt']-r['borderPt']
            lower_text = [w for w in words if w['top'] >= bottom-.5 and w['text'] not in r['labels']]
            assert all(w['bottom']+.5 < min(label['top'] for label in labels)
                       for w in lower_text), (r['case'], 'tick/lower-text overlap')
        print(f"{r['case']}: PASS ({len(labels)} entries, {r['columns']} columns)")
print(f'HORIZONTAL_LEGEND_PDF_PASS: {len(records)} PDFs')
