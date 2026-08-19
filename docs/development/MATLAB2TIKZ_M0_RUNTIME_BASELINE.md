# M0 – Laufzeitbaseline für matlab2tikz 2.0

Audit-Datum: 2026-08-08
Repository: <https://github.com/matlab2tikz/matlab2tikz>
Branch/Commit: `master` / `806c97d99f87f8a1e99a7c54e853c25c82aac301`

## 1. Executive Summary

**GNU Octave 11.3.0 kann matlab2tikz laden und klassische Plots exportieren.** Der minimale End-to-End-Pfad

```text
Octave -> Figure -> matlab2tikz -> Standalone-TeX -> pdfLaTeX -> PDF
```

ist bestätigt. Der Smoke-Test erzeugte ein PDF mit einer Seite und 28.928 Bytes.

Der Audit-Harness bewertete 18 Fälle: 15 exportierten Standalone-TeX erfolgreich, zwei brachen in matlab2tikz ab (Bar und Colorbar), und Histogramm ist in Octave 11.3.0 selbst nicht implementiert. Alle 15 exportierbaren Fälle waren bei zwei Exporten mit identischem Basenamen byteweise deterministisch.

Die historische ACID-Suite enthält 105 Tests, führte aber **keinen** aus: der unveränderte Bash-Runner fand den Windows-Octave-Pfad nicht; der direkte vorgesehene Octave-Pfad erreichte den Runner, scheiterte vor Test 1 an `copyfile(template\*, output)` mit `copyfile: no files to move`. Das ist als **TEST INFRASTRUCTURE FAILURE** klassifiziert. Folglich lauten die offiziellen Suite-Zahlen: 0 ausgeführt, 0 bestanden, 0 fehlgeschlagen, 0 übersprungen – nicht etwa „105 fehlgeschlagen“.

pdfLaTeX kompilierte 13 von 15 Harness-Exporten. Roher Unicode `Ω` ist im erzeugten pdfLaTeX-Preamble nicht eingerichtet; eine Million Inline-Punkte überschreiten TeXs Hauptspeicher. LuaLaTeX kompilierte nach Konfiguration eines beschreibbaren Audit-Caches alle sechs repräsentativen Fälle, einschließlich Unicode und einer Million Punkten.

**Empfehlung für M1: CONDITIONAL GO.** Der Kernpfad funktioniert, aber M1 muss zuerst eine Windows-/Octave-11-kompatible Testinfrastruktur und Regressionstests für die drei bestätigten Exportfehler schaffen. MATLAB-spezifische Abdeckung bleibt vollständig offen.

## 2. Environment

| Komponente | Version / Pfad | Status |
|---|---|---|
| Windows | Microsoft Windows NT 10.0.26200.0 | geprüft |
| Git | 2.55.0.windows.3 | geprüft |
| Octave / octave-cli | GNU Octave 11.3.0, `C:\Program Files\GNU Octave\Octave-11.3.0\mingw64\bin` | geprüft |
| TeX Live | 2026, `C:\texlive\2026` | geprüft |
| pdfLaTeX | pdfTeX 3.141592653-2.6-1.40.29, kpathsea 6.4.2 | geprüft |
| LuaLaTeX | LuaHBTeX 1.24.0 | geprüft |
| XeLaTeX | XeTeX 0.999998, ICU 78.2 | Version geprüft, keine Kompilation |
| latexmk | 4.88, 2026-03-09 | geprüft |
| PGFPlots | 1.18.2, Revision 2025-08-14 | `pgfplots.revision.tex` |
| TikZ/PGF | 3.1.12, 2026-08-01 | `pgf.revision.tex` |
| standalone | 1.5a, 2025-02-22 | `standalone.cls` |
| MATLAB | nicht installiert | nicht geprüft |

`kpsewhich` fand `pgfplots.sty`, `standalone.cls` und `tikz.sty`. Die Programme waren in der gestarteten Codex-Shell zunächst nicht im geerbten `PATH`, wurden aber in den oben genannten Installationspfaden gefunden und für jeden Lauf explizit eingebunden. Das verändert keine systemweite Konfiguration.

Der produktive Stand ist unverändert: `git diff 806c97d... -- src test .travis.yml runtests.sh` war leer. Nur `.audit/`, der statische Auditbericht und dieser Bericht sind untracked.

## 3. End-to-End Smoke Test

| Stufe | Ergebnis | Evidenz |
|---|---|---|
| Octave startet | PASS | `octave-cli --no-gui --quiet --eval "disp(version); disp(2+2)"` -> `11.3.0`, `4`, Exit 0 |
| `addpath('src')` | PASS | matlab2tikz wurde als v1.1.0 / Commit `806c97d...` geladen |
| Figure erzeugt | PASS | unsichtbarer Sinusplot |
| matlab2tikz | PASS | `.audit/runtime-baseline/tex/smoke-test.tex`, 4.584 Bytes |
| pdfLaTeX | PASS | latexmk Exit 0 |
| PDF | PASS | `.audit/runtime-baseline/pdf/smoke-test.pdf`, 1 Seite, 28.928 Bytes |

Octave warnte über das nicht mehr aktiv gepflegte FLTK-Toolkit. Zusätzlich erschien bei mehreren Exit-0-Läufen `error: ignoring const execution_exception& while preparing to exit`; da Exportdateien vollständig vorlagen und der Prozess 0 zurückgab, wird dies als Octave-Exit-Anomalie, nicht als matlab2tikz-Fehler klassifiziert.

## 4. Existing Test Suite

| Suite | Executed | Passed | Failed | Skipped | Notes |
|---|---:|---:|---:|---:|---|
| `runtests.sh` unverändert | 0 | 0 | 0 | 0 | Bash Exit 127: `octave: command not found`; Windows-Pfad mit Leerzeichen nicht übernommen |
| direkter `runMatlab2TikzTests` | 0 | 0 | 0 | 0 | Abbruch vor Test 1 in `test/private/testMatlab2tikz.m:72`: `copyfile: no files to move` |
| ACID-Inventar | 105 vorhanden | — | — | — | `numel(ACID(0))` |

Klassifikation: **TEST INFRASTRUCTURE FAILURE / OCTAVE VERSION DIFFERENCE**. Die Tests wurden nicht geändert und es wurde kein Shim in den Testpfad eingeschleust. Deshalb können weder Produktfehlerquote noch Golden-File-Differenzen aus der bestehenden Suite angegeben werden.

## 5. Audit Harness Results

Der Harness wurde nur unter `.audit/run_minimal_audit.m` angepasst: Ausgaben wurden nach `.audit/runtime-baseline/` verlegt; lokaler Function-Handle-Dispatch wurde wegen Octaves `run()`-Semantik durch einen `switch` ersetzt; Dateiprüfung und UTF-8-Erzeugung wurden Octave-kompatibel gemacht; identische Basenamen in getrennten Verzeichnissen verhindern falsche Determinismusdifferenzen. Keine Produkt- oder Testdatei wurde geändert.

| Fall | Figure | matlab2tikz | TeX | pdfLaTeX | LuaLaTeX | Ergebnis |
|---|---:|---:|---:|---:|---:|---|
| 2D-Line | PASS | PASS | PASS | PASS | PASS | PASS |
| mehrere Linien + Legend | PASS | PASS | PASS | PASS | nicht separat | PASS |
| Log-Achsen, normal | PASS | PASS | PASS | PASS | nicht separat | PASS |
| Subplot | PASS | PASS | PASS | PASS | nicht separat | PASS |
| Scatter | PASS | PASS | PASS | PASS | PASS | PASS |
| Bar | PASS | FAIL | FAIL | — | — | OCTAVE COMPATIBILITY FAILURE |
| Errorbar | PASS | PASS | PASS | PASS | nicht separat | PASS |
| Histogram | FAIL | — | — | — | — | NOT TESTABLE WITH OCTAVE |
| imagesc | PASS | PASS | PASS + PNG | PASS | PASS | PASS |
| Contour | PASS | PASS | PASS | PASS | nicht separat | PASS |
| Surface | PASS | PASS | PASS | PASS | PASS | PASS |
| Colorbar | PASS | FAIL | FAIL | — | — | OCTAVE COMPATIBILITY FAILURE |
| Datumsachse | PASS | PASS | PASS | PASS | nicht separat | PASS |
| LaTeX-Beschriftungen | PASS | PASS | PASS | PASS | nicht separat | PASS; Octave-Rendererwarnung |
| Unicode | PASS | PASS | PASS | FAIL | PASS | ENGINE-SPECIFIC TEX FAILURE |
| Transparenz | PASS | PASS | PASS | PASS | nicht separat | PASS |
| NaN / Inf | PASS | PASS | PASS | PASS | nicht separat | PASS |
| 1.000.000 Punkte | PASS | PASS | PASS | FAIL | PASS | TEX CAPACITY LIMIT IN pdfTeX |
| External Data | PASS | PASS | PASS + TSV | PASS bis 10.000 | nicht separat | ab 100.000 pdfTeX-Speicherlimit |
| Standalone | PASS | PASS | PASS | Smoke PASS | Smoke äquivalent | PASS |

Maschinenlesbare Harness-Ergebnisse: `.audit/runtime-baseline/results/harness-results.tsv`.

## 6. TeX Compilation Results

pdfLaTeX kompilierte 13/15 erzeugte Kernfälle. Erfolgreiche Laufzeiten lagen grob zwischen 1,85 und 2,51 Sekunden pro Datei. Fehler:

- `unicode.tex`: `LaTeX Error: Unicode character Ω (U+03A9) not set up for use with LaTeX.` Der Export enthält das Zeichen unverändert; LuaLaTeX kompiliert die Datei.
- `large_data.tex`: `TeX capacity exceeded, sorry [main memory size=5000000]`. LuaLaTeX kompiliert dieselben eine Million Punkte in 131,16 s zu einem PDF mit 6.498.138 Bytes.

LuaLaTeX scheiterte beim ersten Versuch vor dem Lesen der Dokumente an `luaotfload ... no writeable cache path`. Mit `TEXMFVAR` und `TEXMFCACHE` unter `.audit/runtime-baseline/data/texmf-var` kompilierten 6/6 repräsentative Fälle. Das erste Erstellen des Font-Caches machte `line2d` mit 69,14 s deutlich langsamer; Folgeläufe lagen bei 2,29–2,89 s, ausgenommen der Million-Punkte-Fall.

## 7. Runtime-confirmed Bugs

### M2T-RUNTIME-001 – undefinierte Variable bei strikten Log-Ticklabels

- Reproduktion: `loglog(...); matlab2tikz(...,'strict',true)`
- Ergebnis: `Octave:undefined-function: 'str' undefined near line 5651, column 54`
- Stack: `formatPgfTickLabels:5651 -> matlabTicks2pgfplotsTicks:5588 -> getAxisTicks:1610 -> ...`
- Klassifikation: **PRODUCT FAILURE, CONFIRMED AT RUNTIME**.
- Entspricht statischem Befund M2T-AUDIT-001.

### M2T-RUNTIME-002 – Bar-Export scheitert unter Octave 11.3

- Reproduktion: `bar([1 2 3;3 2 1]); matlab2tikz(...)`
- Ergebnis: `get: unknown line property FaceColor`
- Stack: `getPatchDrawOptions:4800 -> drawBarseries:4241 -> drawHggroup:3076 -> ...`
- Klassifikation: **OCTAVE COMPATIBILITY / PRODUCT FAILURE**.

### M2T-RUNTIME-003 – Colorbar-Export scheitert unter Octave 11.3

- Reproduktion: `imagesc(peaks(20)); colorbar; matlab2tikz(...)`
- Ergebnis: `get: unknown axes property axes`
- Stack: `handleColorbar:1490 -> saveToFile:490 -> matlab2tikz:337`
- Klassifikation: **OCTAVE COMPATIBILITY / PRODUCT FAILURE**.

### M2T-RUNTIME-004 – Standalone-pdfLaTeX-Preamble unterstützt rohes Ω nicht

- Reproduktion: Unicode-Titel mit `Ω`, Standalone-Export, `latexmk -pdf -halt-on-error`.
- Ergebnis: pdfLaTeX-Abbruch; LuaLaTeX PASS.
- Klassifikation: **TEX ENGINE COMPATIBILITY FAILURE**. Ob dies Bug oder dokumentierte Einschränkung sein soll, benötigt eine Produktentscheidung.

## 8. Octave-specific Problems

- Bar und Colorbar verwenden in Octave 11.3 andere Objekttypen/Eigenschaften als vom Legacy-Code erwartet.
- `histogram` ist in Octave 11.3 nicht implementiert und daher kein matlab2tikz-Fehler.
- Der unveränderte Test-Runner ist unter Octave 11.3/Windows wegen `copyfile`-Globverhalten nicht ausführbar.
- Octaves LaTeX-Label-Renderer meldete einen Laufzeittestfehler und deaktivierte den Interpreter; matlab2tikz exportierte die Labeldatei dennoch und pdfLaTeX kompilierte sie.
- FLTK wird von Octave selbst als nicht mehr aktiv gepflegt bezeichnet; der historische Testcode erzwingt unter unsichtbaren Octave-Tests ausdrücklich `gnuplot`, wurde wegen des früheren Infrastrukturabbruchs aber nicht erreicht.
- Die Exit-Meldung `execution_exception` erschien auch bei Exit 0.

## 9. Performance Baseline

Export auf demselben Windows-System, einfacher Sinus-Line-Plot:

| Punkte | Modus | Exportzeit | TeX-Größe | Datenfiles/-größe | pdfLaTeX | PDF |
|---:|---|---:|---:|---:|---:|---:|
| 100 | inline | 0,174 s | 4.369 B | — | 2,067 s PASS | 28.740 B |
| 100 | external | 0,108 s | 708 B | 1 / 3.496 B | 1,858 s PASS | 28.740 B |
| 10.000 | inline | 0,585 s | 374.313 B | — | 4,103 s PASS | 113.834 B |
| 10.000 | external | 0,537 s | 916 B | 3 / 353.504 B | 3,858 s PASS | 113.834 B |
| 100.000 | inline | 4,767 s | 3.733.795 B | — | 4,764 s FAIL | 0 |
| 100.000 | external | 4,592 s | 3.223 B | 25 / 3.531.490 B | 5,346 s FAIL | 0 |
| 1.000.000 | inline | 45,156 s | 37.382.643 B | — | 4,857 s FAIL | 0 |
| 1.000.000 | external | 46,639 s | 27.249 B | 250 / 35.365.038 B | 5,447 s FAIL | 0 |

Ab 100.000 Punkten überschritt pdfTeX in beiden Modi `main memory size=5000000`. External Data reduziert die Hauptdatei stark, nicht aber die gesamte Datenmenge oder die PGFPlots-Speicherlast; matlab2tikz splittet eine Million Punkte in 250 TSV-Dateien. LuaLaTeX konnte den Million-Punkte-Inlinefall kompilieren, benötigte aber 131 Sekunden und erzeugte 6,5 MB PDF. Keine Optimierung wurde vorgenommen.

## 10. Determinism

Alle 15 exportierbaren Kernfälle waren **DETERMINISTIC**: zwei frisch geschriebene Dateien mit identischem Basenamen in getrennten Verzeichnissen waren byteweise gleich. Das schließt `imagesc` samt identischer PNG-Referenz im TeX ein; die PNG-Dateien selbst hatten ebenfalls gleiche Größen. Bar/Colorbar sind wegen Exportabbruch und Histogramm wegen fehlender Octave-Funktion **UNKNOWN / NOT TESTABLE**.

## 11. Static Findings Reclassified

| Statischer Befund | Neue Klassifikation | Evidenz |
|---|---|---|
| M2T-AUDIT-001 Log-Tick `str` | STATIC -> RUNTIME CONFIRMED | identischer Fehler in Octave 11.3 |
| M2T-AUDIT-002 unbekannter Objekttyp -> `drawNothing` | STATIC -> MATLAB VALIDATION REQUIRED | beliebiger unbekannter HG-Typ nicht sauber unter Octave konstruierbar; Octave-`hggroup` nimmt rekursiven Fallback |
| historische Octave-Kompatibilität | STATIC -> OCTAVE FAILURES CONFIRMED | Bar, Colorbar, Testinfrastruktur |
| große Daten / String- und TeX-Last | STATIC -> RUNTIME CONFIRMED | 45 s Export, 37 MB TeX, pdfTeX-Kapazitätsfehler |
| Unicode-/Escape-Risiko | STATIC -> RUNTIME PARTLY CONFIRMED | Export deterministisch; pdfLaTeX scheitert an Ω, LuaLaTeX besteht |
| moderne PGFPlots-Kompatibilität | STATIC -> PARTLY CONFIRMED | 13/15 pdfLaTeX- und 6/6 repräsentative LuaLaTeX-Kompilationen mit PGFPlots 1.18.2 |

## 12. Remaining MATLAB Validation

Zwingend mit echtem MATLAB zu prüfen:

- `tiledlayout` und shared legends/labels
- `yyaxis`
- `heatmap`
- `polarplot`
- `FunctionLine`, `FunctionSurface`, `fcontour`
- moderne Colorbar-/Axes-Eigenschaften und HG2-Klassen
- MATLAB `histogram`
- MATLAB-spezifische Unicode-/LaTeX-Interpreterpfade
- `checkcode('src','-id')` / MATLAB Code Analyzer
- bestehende ACID-Suite auf mindestens einer aktuellen und einer älteren unterstützten MATLAB-Version
- visuelle Gleichheit zwischen MATLAB-Figure und PDF; M0 prüfte Erzeugung/Kompilation, keinen Pixelvergleich

## 13. Updated Recommendation

**CONDITIONAL GO für M1.**

GO-Gründe: Der klassische End-to-End-Pfad funktioniert mit aktuellem Octave und aktuellem PGFPlots; 15 Kernfälle exportieren deterministisch; 13 davon kompilieren unverändert mit pdfLaTeX und die repräsentative LuaLaTeX-Matrix inklusive Unicode/Million-Punkte-Fall ist erfolgreich.

Bedingungen: M1 muss vor Feature- oder Architekturarbeit (1) die bestehende Suite auf Octave 11/Windows startfähig machen, ohne ihre Assertions abzuschwächen, (2) M2T-RUNTIME-001 bis -003 als Regressionstests aufnehmen, (3) eine klare Unicode-/Engine-Policy festlegen und (4) mindestens eine echte MATLAB-Baseline ergänzen. Ohne diese Bedingungen wäre Refactoring nicht belastbar abgesichert.

## Ausgeführte Kernbefehle

```text
git status --short --branch
git rev-parse HEAD
octave-cli --version / octave --version
pdflatex --version / lualatex --version / xelatex --version / latexmk --version
kpsewhich pgfplots.sty / standalone.cls / tikz.sty
octave-cli --no-gui --quiet --eval "disp(version); disp(2+2)"
octave-cli --no-gui --quiet --eval "addpath('src'); ... matlab2tikz(...smoke-test.tex...)"
latexmk -pdf -interaction=nonstopmode -halt-on-error smoke-test.tex
C:\Program Files\Git\bin\bash.exe ./runtests.sh
octave-cli --no-gui --quiet --eval "cd('test'); runMatlab2TikzTests"
octave-cli --no-gui --quiet --eval "run('.audit/run_minimal_audit.m')"
octave-cli --no-gui --quiet --eval "run('.audit/run_performance_audit.m')"
latexmk -pdf ... <alle 15 Harness-Dateien und 8 Performance-Dateien>
latexmk -lualatex ... <6 repräsentative Dateien>
```

Alle generierten Logs, TeX-, PDF-, Daten- und Ergebnisdateien liegen ausschließlich unter `.audit/runtime-baseline/`.
