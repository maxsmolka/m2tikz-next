# Technische Bestandsaufnahme: matlab2tikz

Audit-Datum: 2026-08-06
Repository: <https://github.com/matlab2tikz/matlab2tikz>
Bewerteter Default-Branch/Commit: `master` / `806c97d99f87f8a1e99a7c54e853c25c82aac301`

## 1. Executive Summary

**CONDITIONAL GO** für das Projekt „m2tikz-next“.

Der Default-Branch ist für klassische MATLAB-Grafiken weiterhin grundsätzlich plausibel verwendbar: Linien, Achsen, Scatter, Balken, Error Bars, Histogramme, Bilder, Konturen, Flächen, Text und externe Tabellen besitzen explizite Renderer (`src/matlab2tikz.m:679-726`). Das ist keine aktuelle Laufzeitbestätigung: Auf dem Audit-Rechner fehlen MATLAB, Octave und TeX.

Für moderne Grafikobjekte ist die Abdeckung lückenhaft. Unbekannte Typen werden gewarnt und absichtlich leer gerendert (`src/matlab2tikz.m:741-745`); offene Meldungen betreffen unter anderem `tiledlayout`, `heatmap`, Polarplots, `yyaxis`, Function-Objekte und neue Achsen-/Colorbar-Eigenschaften. Ein eindeutiger Defekt im aktuellen Commit (`str` undefiniert bei automatischen Log-Ticklabels) ist statisch bestätigt (`src/matlab2tikz.m:5636-5652`, Issue #1125).

Das größte Risiko ist nicht nur einzelne Fachlogik, sondern fehlende moderne Verifikation: der Default-Branch endete 2023, der letzte veröffentlichte Release ist 1.1.0 von 2016, `.travis.yml` beschreibt eine nicht mehr zeitgemäße Travis-/Octave-PPA-Pipeline, und es existiert kein repository-eigener GitHub-Actions-Testworkflow. 251 offene Issues und 13 offene PRs wurden am Audit-Tag über die öffentliche GitHub API gezählt.

Empfohlen wird **Evolution mit teilweiser Neuentwicklung**: Legacy-Renderer hinter Regressionstests stabilisieren, Figure Reader und normalisierte Intermediate Representation neu einziehen, Asset Writer isolieren und Renderer danach schrittweise migrieren. Ein Big-Bang-Rewrite würde viel über 15 Jahre angesammeltes Spezialwissen und die 100+ ACID-Szenarien riskieren.

## 2. Untersuchte Version

| Merkmal | Ergebnis | Evidenz |
|---|---|---|
| Repository | offizielles GitHub-Repository | `git remote show origin` |
| Default-Branch | `master` | Remote-HEAD nach `git fetch --all --tags --prune` |
| Commit | `806c97d99f87f8a1e99a7c54e853c25c82aac301` | `git rev-parse HEAD` |
| Commit-Datum | 2023-02-10T12:02:11+01:00 | `git show -s --format=%cI HEAD` |
| Letzter Commit auf Default-Branch | 2023-02-10 | Git-Log |
| Letzter Release | v1.1.0, 2016-10-20 | GitHub Releases / Tag `v1.1.0` |
| Tags | 0.0.1 bis v1.1.0; 32 Tags lokal | `git tag --sort=-creatordate` |
| Aktive Remote-Branches | `master`, `develop`, `release/1.2.0`, `revert-1048-patch-1` | `git remote show origin` |
| Neuere Nicht-Default-Arbeit | `release/1.2.0` enthält Commits bis 2026-05-31; offener PR #1157 | Git-Log / GitHub API |

Testumgebung: Windows NT 10.0.26200.0, PowerShell 5.1.26100.8875, Git 2.55.0.windows.3. MATLAB, GNU Octave, `checkcode`, `pdflatex`, `lualatex`, `xelatex`, `latexmk` und GitHub CLI waren **nicht verfügbar**. Dadurch sind visuelle Gleichheit, Laufzeitkompatibilität, Code-Analyzer-Ergebnisse und TeX-Kompilierbarkeit **nicht geprüft**. Linux und macOS sowie ältere/aktuelle MATLAB-/Octave-Versionen sind ebenfalls **nicht geprüft**.

## 3. Aktuelle Architektur

### Öffentliche API und Module

- `src/matlab2tikz.m:1`: Haupt-API und monolithische Implementierung (7.167 Zeilen, 223 lokale Funktionen). Optionen umfassen Standalone, External Data, Pfade, Floating-Point-Format und benutzerdefinierten Code (`src/matlab2tikz.m:1-150`, Parser ab `:192`).
- `src/cleanfigure.m:1`: optionale Datenreduktion/Clipping/Präzisionsbegrenzung (1.294 Zeilen).
- `src/m2tcustom.m:1`: objektspezifische Custom-Handler/-Properties.
- `src/figure2dot.m:1`: Diagnoseexport des HG-Baums als DOT.
- `src/m2tInputParser.m:1`: eigener, rückwärtskompatibler Argumentparser.
- `src/private/*`: Umgebung, Versionen, GUI-Typen, 3D-Erkennung und Self-Updater.

### Tatsächlicher Datenfluss

```text
Figure-Handle / gcf + Optionen
  -> Initialisierung eines großen m2t-Zustandsstructs
  -> Ermittlung relevanter Axes / Colorbars / Legends
  -> rekursive HG-Kindanalyse in Darstellungsreihenfolge
  -> Type-Switch und objektspezifische draw* Funktionen
  -> PGF-Environment-/Option-Cellarrays + direkt formatierte Strings/Tabellen
  -> printAll() in .tex/.tikz
  -> optional .tsv und PNG-Assets
```

Eine eigenständige normalisierte Zwischenrepräsentation existiert nicht. Der mutable `m2t`-Struct enthält Argumente, aktuelle Handles, Zähler, Farben, Abhängigkeiten und Ausgabezustand; Lesen, Normalisieren und Rendern sind in derselben Datei gekoppelt. Externe Daten werden zeilenweise formatiert und als `.tsv` geschrieben (`src/matlab2tikz.m:5696-5790`); Bilder können PNG oder TikZ werden (`:2622-2823`). Ressourcen werden beim Schreiben überwiegend per `onCleanup` geschlossen (`:539`, `:5752`).

### Objektabdeckung

Explizit dispatcht werden `line`, `constantline`, `patch`, `image`, Gruppen (`scatter`, `bar`, `stair`, `stem`, `errorbar`, `area`, `quiver`, `contour`), `hgtransform`, `surface`, `text`, `rectangle`, Arrow-Shapes und `histogram` (`src/matlab2tikz.m:679-726`). `light` und GUI-Typen werden absichtlich ignoriert (`:728-735`). Alle übrigen Typen fallen auf Warnung + `drawNothing` zurück (`:741-745`).

PGFPlots ist Kernabhängigkeit; Mindestversionen werden dynamisch signalisiert (`src/matlab2tikz.m:7092-7106`). TikZ-Libraries werden gesammelt (`:6280-6289`). Der Release 1.1.0 nennt zusätzliche `arrows.meta`-Anforderungen für Quiver.

## 4. Wartungszustand

**Bestätigt:** Der Default-Branch hat seit Februar 2023 keinen Commit. Neuere Maintainer-Aktivität existiert auf `release/1.2.0` und in PR #1157 (2026); das Repository ist daher nicht vollständig inaktiv, aber der freigegebene Hauptpfad ist nicht aktuell integriert.

**Bestätigt:** Der letzte Release ist v1.1.0 (2016). PR #1157 schlägt 1.2.0 vor und ist laut GitHub API mergebar, aber im Zustand `unstable`; er ersetzt keine veröffentlichte Version.

**Bestätigt:** Am 2026-08-06 waren 251 Issues und 13 PRs offen (öffentliche API; GitHub-Webansicht zeigte konsistent 250/13 kurz zuvor, wahrscheinlich Index-/Zeitpunktdifferenz). Die Titel zeigen wiederkehrende Cluster: moderne HG-Objekte/Layout, Achsen/Ticks, Colorbars/Colormaps, Text/Escaping, Octave, Bilder/3D, Balken/Scatter und CI/Tests. Titel allein wurden nicht als Fehlerbeweis gewertet.

**Bus-Faktor:** `git shortlog` ordnet 1.169 von 2.861 Commits Egon Geerardyn und 650 Nico Schlömer zu (Namens-/E-Mail-Aliase nicht vollständig bereinigt). Jüngste Merges/Release-Arbeit stammen erneut überwiegend von Egon. Das ist **starke statische Evidenz** für Konzentrationsrisiko, keine Aussage über private Maintainer-Kapazität.

**CI:** `.travis.yml:1-18` installiert Octave aus einem historischen PPA und ruft `runtests.sh` auf; README nennt zusätzlich einen persönlichen Jenkins (`test/README.md`, Abschnitt „Automated Tests“). Ein repository-eigener Actions-Workflow fehlt. PR #1151 schlägt moderne CI/Governance vor, ist aber ein einzelner, ungeprüfter 15-Dateien-Change. In `.travis.yml` steht außerdem ein historischer credential-artiger Notification-Wert im Klartext; der Wert wird hier bewusst nicht wiedergegeben. Er sollte als kompromittiert/obsolet behandelt und entfernt bzw. rotiert werden.

## 5. Testergebnisse

| Testbereich | Umgebung | Ergebnis | Reproduzierbar | Evidenz |
|---|---|---:|---:|---|
| Repository-Sauberkeit | Git 2.55 / Windows | PASS vor Auditdateien | ja | `git status --short --branch` |
| Offizieller Test-Runner | Git Bash / Windows | BLOCKED, 0 ausgeführt | ja | `C:\Program Files\Git\bin\bash.exe ./runtests.sh` -> Zeile 68: `octave: command not found` |
| MATLAB `checkcode` | Windows | NICHT GEPRÜFT | ja | `matlab` nicht im PATH |
| Direkter Octave-Test | Windows | NICHT GEPRÜFT | ja | `octave` nicht im PATH |
| Bestehende Headless-Suite | — | NICHT AUSGEFÜHRT | — | fehlende Engine |
| Bestehende grafische/LaTeX-Suite | — | NICHT AUSGEFÜHRT | — | fehlende Engine und TeX |
| Minimal-Harness, 18 Grafikfälle | `.audit/run_minimal_audit.m` | ERSTELLT, NICHT AUSGEFÜHRT | vorgesehen | Harness-Datei |
| `pdflatex`/LuaLaTeX/XeLaTeX | Windows | NICHT GEPRÜFT | ja | Engines fehlen |

Die vorhandene Headless-Suite vergleicht generierte Dateien per umgebungsspezifischem MD5; Referenzen gibt es nur für MATLAB 8.3/8.4 und Octave 3.8.0/4.2.0/4.2.2 (`test/suites/ACID.*.md5`). Laut `test/README.md` ist das absichtlich sehr whitespace-empfindlich und prüft nur Gleichheit mit früherer Ausgabe, nicht visuelle oder semantische Richtigkeit. Die grafische Suite erzeugt native und TikZ-PDFs und benötigt Make/LaTeX. `ACID.m` hat 2.819 Zeilen und mehr als 100 szenariobasierte Fälle; mehrere sind versionsabhängig als „unreliable“ markiert.

Der Audit-Harness deckt 2D-Linie, mehrere Linien/Legende, Log-Achsen, Subplots, Scatter, Balken, Error Bars, Histogramm, `imagesc`, Kontur, Oberfläche, Colorbar, Datumsachse, LaTeX, Unicode, Transparenz, NaN/Inf, eine Million Punkte, externe Daten und Standalone ab. Er erzeugt jeden Kernfall zweimal und vergleicht Bytes; Kompilierung und Bildvergleich müssen in M0 ergänzt werden.

## 6. Bestätigte Fehler

### M2T-AUDIT-001

ID: M2T-AUDIT-001
Titel: Undefinierte Variable bei automatischen Log-Ticklabels
Schweregrad: Hoch
Kategorie: Bestätigter Codefehler
Betroffene Version: `806c97d` / master
Betroffene Funktion: `formatPgfTickLabels`, `src/matlab2tikz.m:5636-5652`
Reproduktion: `loglog([1e-2,1e2],[1e-5,1e5]); matlab2tikz('test.tex','strict',true)` (Issue #1125; lokal mangels MATLAB nicht dynamisch wiederholt)
Erwartet: formatierte `$10^{…}$`-Labels
Tatsächlich: Zugriff auf nie definierte Variable `str` in Zeile 5651
Fehlermeldung: „Unrecognized function or variable 'str'.“ laut Issue #1125
Ursache: Platzhalter/Refactoringrest; der Schleifenwert ist `tickLabels{k}`
Issue/PR: [#1125](https://github.com/matlab2tikz/matlab2tikz/issues/1125), kein identifizierter offener Fix-PR
Lösungsansatz: korrekten normalisierten Labelwert einsetzen und Regressionstest für strict + loglog
Beweissicherheit: **Bestätigt durch direkten Codepfad; dynamische lokale Reproduktion nicht geprüft**.

### M2T-AUDIT-002

ID: M2T-AUDIT-002
Titel: Unbekannte moderne Grafikobjekte erzeugen leere Ausgabeanteile
Schweregrad: Mittel bis hoch, abhängig vom Plot
Kategorie: Bestätigtes Fallback-Verhalten / Feature Gap
Betroffene Funktion: `handleAllChildren`, `src/matlab2tikz.m:679-745`
Reproduktion: Objekt mit nicht gelistetem `Type`; dokumentierte Beispiele sind Polarplots (#1020) und Heatmap (#1076)
Erwartet: explizite Unterstützung oder harter, strukturierter Fehler
Tatsächlich: Warnung und `drawNothing`, also potentiell syntaktisch gültige, aber inhaltlich leere Ausgabe
Issue/PR: [#1020](https://github.com/matlab2tikz/matlab2tikz/issues/1020), [#1076](https://github.com/matlab2tikz/matlab2tikz/issues/1076)
Lösungsansatz: Capability Registry, strukturierte Unsupported-Diagnose, neue Reader
Beweissicherheit: **Bestätigt für den Fallback; konkrete Plots lokal nicht reproduziert**.

### M2T-AUDIT-003

ID: M2T-AUDIT-003
Titel: Credential-artiger Klartextwert in historischer CI-Konfiguration
Schweregrad: Hoch (Security Hygiene; tatsächliche Gültigkeit unklar)
Kategorie: Bestätigte Offenlegung / veraltete Infrastruktur
Betroffene Datei: `.travis.yml:14`
Reproduktion: Datei am untersuchten Commit lesen
Erwartet: keine Secrets/Tokens in Git
Tatsächlich: Notification-Konfiguration enthält einen tokenartigen Wert
Lösungsansatz: Wert invalidieren/rotieren, aus Konfiguration entfernen, History-/Provider-Risiko prüfen
Beweissicherheit: **Bestätigt, aber Gültigkeit und Ausnutzbarkeit nicht geprüft**.

## 7. Wahrscheinliche Fehler

- **Sehr wahrscheinlich:** Windows-`relativeDataPath` zerstört führende TeX-Makro-Backslashes, weil `TeXpath` jedes `filesep` global durch `/` ersetzt (`src/matlab2tikz.m:461-462`, Issue #1105). Nicht dynamisch reproduziert.
- **Sehr wahrscheinlich:** Shared-Legends in `tiledlayout` mit Location `layout` fallen in den Unknown-Location-Pfad; PR #1128 ändert genau eine Datei und ist laut API mergebar, aber `unstable`. Code/PR-Lösung ist plausibel, nicht getestet.
- **Unklar:** Octave >=4.4 3D-Achsenposition kann an `x_viewtransform` scheitern (Issue #1057); PR #1058 implementiert einen Workaround, zielt jedoch auf `develop`, ist seit 2019 unverändert und API-Mergeability war `unknown`. Master enthält spätere Octave-6-Arbeit, daher ist aktuelle Reproduktion zwingend.
- **Unklar:** `cleanfigure` mit `yyaxis` sieht möglicherweise nur aktive Kinder (Issue #1146). Der gemeldete Einzeiler muss gegen aktuelle HG-Strukturen getestet werden.
- **Unklar:** NaN in Scatter-Metadaten führte historisch zu nicht kompilierbarem TeX (#331). Aktueller `makeTable` schreibt NaN/Inf bewusst als `nan`/`inf` (`src/matlab2tikz.m:5740-5742`); PGFPlots-Verhalten hängt von Optionen und Spaltenrolle ab.

## 8. Fehlende oder unvollständige Funktionen

| Typ | Bereich | Status/Evidenz |
|---|---|---|
| Feature Gap | Polar axes/`polarplot` | kein Dispatcher; #1020/#950/#1115 |
| Feature Gap | `heatmap` | kein Dispatcher; #1076 |
| Feature Gap | `tiledlayout`/shared labels & legend | #1086/#1123; PR #1128 teilweise |
| Feature Gap | `yyaxis` | #984/#1146; Legacy-Code ist auf `plotyy` ausgerichtet (`src/matlab2tikz.m:763-1344`) |
| Feature Gap | FunctionLine/FunctionSurface/FContour | #1003/#1013/#1092/#1126 |
| Feature Gap | Graph/Bubble/Skyplot/Stackedplot | #1142/#1119/#1148/#1099 |
| Einschränkung | Light/GUI | absichtlich ignoriert (`src/matlab2tikz.m:728-735`) |
| Einschränkung | unbekannte Typen | Warnung + leere Darstellung (`:741-745`) |
| Unvollständig | Colorbar HG2 ticks/labels | explizites TODO (`src/matlab2tikz.m:5045`) und PR #895 |

## 9. Technische Schulden

- **Architektur/Kopplung – sehr hoch:** 7.167-Zeilen-Hauptdatei mit 223 lokalen Funktionen; Figure-Introspection, Normalisierung, Rendering, Formatierung und I/O teilen `m2t`.
- **Testbarkeit – hoch:** kaum isolierbare Reader/Renderer-Grenzen; Tests vergleichen Enddatei-MD5 und markieren diverse Umgebungsfälle als unreliable.
- **Erweiterbarkeit – hoch:** zentraler Type-Switch statt Registry; neue HG-Klassen verlangen Änderungen im Monolith.
- **Portabilität – hoch:** explizite MATLAB/Octave-Forks und Annahmen zu alten Versionen; Referenzhashes enden bei Octave 4.2.2/MATLAB 8.4.
- **Fehlerdiagnose – mittel/hoch:** unbekannte Objekte werden weich ignoriert, wodurch Datenverlust leicht übersehen wird.
- **Performance – mittel:** Tabellenaufbau iteriert Zeile × Spalte mit vielen Cell-/`sprintf`-Operationen (`src/matlab2tikz.m:5732-5739`); bei großen Arrays wahrscheinlich teuer, aber nicht profiliert.
- **Determinismus – unklar:** Reihenfolge der Kinder wird explizit stabil rückwärts verarbeitet (`:667-670`), doch Handle-/Factory-/Umgebungsdefaults und umgebungsspezifische MD5-Dateien zeigen Abhängigkeiten.
- **Text/Unicode – mittel:** umfangreiche handgeschriebene Parser-/Escape-Logik (`:6350-6893`) mit dokumentierten Sonderfällen und FIXME; aktuelle UTF-8-Engines nicht getestet.
- **Eingabevalidierung – gemischt:** eigener Parser validiert zahlreiche Optionen, akzeptiert aber überwiegend `char` und trägt historische Kompatibilitätslast.
- **I/O-Sicherheit – mittel:** Dateinamen werden aus Nutzerpfaden gebildet; `onCleanup` schützt Handles. Kein Shell-Aufruf im Produkt-Hauptpfad gefunden; Self-Updater lädt/ersetzt Dateien und verdient separate Threat-Model-Prüfung (`src/private/m2tUpdater.m`).

Statische Suchung fand 43 TODO- und 11 FIXME-Zeilen unter `src`. MATLAB `checkcode` konnte nicht ausgeführt werden; tote Pfade, McCabe-Komplexität und MATLAB-spezifische Analyzer-Warnungen bleiben offen.

## 10. Kompatibilitätsmatrix

| Funktion | MATLAB | Octave | PGFPlots | Status | Anmerkung |
|---|---|---|---|---|---|
| klassische 2D-Linien | historisch breit | historisch bis 6+ adressiert | Kernpfad | Nicht aktuell geprüft | expliziter Renderer |
| Scatter/Bar/Errorbar/Histogram | explizite Renderer | zahlreiche Env-Forks | featureabhängig | Nicht aktuell geprüft | offene Detailbugs |
| Surface/Contour/Image | explizite Renderer | bekannte 3D-/Transform-Risiken | patchplots/graphics | Nicht aktuell geprüft | PNG-Assets möglich |
| Text/TeX/Unicode | eigener Parser | divergierende Escapes | TeX-engineabhängig | Nicht aktuell geprüft | keine aktuelle Engine lokal |
| `datetime` x/y ticks | Codepfad vorhanden | unklar | date coordinates | Teilweise/unklar | z/duration offen (#966/#967) |
| `tiledlayout` | modernes MATLAB | n/a | groupplot/layout | Unvollständig | #1123/#1086 |
| Polar/Heatmap/Function-Objekte | modernes MATLAB | variabel | prinzipiell möglich | Nicht unterstützt/unvollständig | Fallback `drawNothing` |
| externe TSV/PNG | Windows-Pfadrisiko | historisch | `table`/graphics | Nicht aktuell geprüft | #1105 |
| Standalone | Codepfad vorhanden | historisch | standalone + pgfplots | Nicht kompiliert | TeX fehlt |

„Historisch“ bedeutet ausschließlich Code/Testartefakte, nicht erfolgreiche Prüfung auf heutigen Versionen.

## 11. Risikomatrix

| Risiko | Wahrscheinlichkeit | Auswirkung | Priorität | Evidenz |
|---|---:|---:|---:|---|
| keine aktuelle reproduzierbare CI-Matrix | hoch | hoch | P0 | `.travis.yml`, fehlende Workflows |
| silent/soft data loss bei unbekannten Objekten | hoch | hoch | P0 | `drawNothing`-Fallback |
| moderne MATLAB-HG-Kompatibilität | hoch | hoch | P1 | Issue-Cluster / Type-Switch |
| Octave-Versionen ungeprüft | hoch | mittel/hoch | P1 | alte MD5-Matrix, #1057 |
| monolithische Kopplung | hoch | hoch | P1 | 7.167 Zeilen/223 Funktionen |
| Release-/Default-Branch-Divergenz | hoch | mittel | P1 | Release 2016, master 2023, PR 2026 |
| TeX/PGFPlots-Regressionen | mittel/hoch | hoch | P1 | keine Kompilierung in aktuellem CI |
| credential-artige Alt-Konfiguration | unklar | hoch | P0 | `.travis.yml:14` |
| Performance großer Daten | mittel | mittel | P2 | Tabellenloop; nicht profiliert |
| Rewrite verliert Legacy-Semantik | hoch | hoch | P1 | ACID-Umfang / Spezialfälle |

## 12. Empfohlene Prioritäten für m2tikz-next

**P0 – blockierend**

1. Reproduzierbare CI auf Windows/Linux mit aktuellem MATLAB und Octave sowie TeX Live; Testresultate als Artefakte.
2. Historischen Klartextwert aus CI entfernen/rotieren und Security Review durchführen.
3. Unsupported-Objekte als strukturierte, standardmäßig deutliche Diagnose samt Objektpfad erfassen; kein unbemerkter leerer Export.
4. M2T-AUDIT-001 und weitere eindeutig reproduzierbare Crashes durch Regressionstests einfrieren (noch nicht in dieser Phase beheben).

**P1 – hoch:** Golden-/semantic tests modernisieren, aktuelle Tool-Matrix festlegen, PR #1157/#1151 selektiv prüfen, Reader/IR-Grenze einführen, moderne Layouts/yyaxis/Polar priorisieren.

**P2 – mittel:** Renderer modularisieren, Text/Escaping property-basiert testen, Asset Writer/Pfade härten, große Daten benchmarken, Diagnostics/Codes standardisieren.

**P3 – langfristig:** alternative Renderer, IR-Schema-Versionierung, Visual-Diff-Farm für mehrere OS/MATLAB-Releases, Plugin-Registry für Grafikobjekte.

## 13. Empfohlene Modernisierungsstrategie

1. **Schrittweise Legacy-Modernisierung:** geringstes kurzfristiges Risiko und schnelle Bugfixes; allein löst sie Monolith/Kopplung nicht.
2. **Teilweise Neuentwicklung:** Figure Reader -> normalisierte IR -> Renderer -> Asset Writer, während Legacy-Handler als Adapter weiterlaufen. Höherer Anfangsaufwand, aber klare Testseams und kontrollierbare Migration.
3. **Vollständiger Rewrite:** sauberste Zielarchitektur, aber höchste Regressions-, Zeit- und Bus-Faktor-Risiken; ohne vollständige Oracles nicht verantwortbar.

**Empfehlung:** Variante 2, inkrementell geliefert. Die IR sollte reine Daten ohne Handles enthalten: Figure/Layout, Axes/Transforms, Series-Typ und normalisierte Daten, Styles/Farben, Text samt Interpreter, Legend/Colorbar sowie Asset-Referenzen. Vorteile: Reader-Vertragstests pro MATLAB/Octave-Version, Renderer-Tests ohne MATLAB, deterministische Serialisierung, genaue Unsupported-Diagnosen und später alternative Backends. Zunächst muss ein Legacy-Output-Adapter dieselbe Ausgabe erzeugen; erst danach einzelne Renderer ersetzen.

## 14. Vorgeschlagene Milestones

- **M0:** reproduzierbare Toolchains, CI, Secret-Hygiene, Audit-Harness automatisiert.
- **M1:** aktuelle Baseline auf MATLAB/Octave/TeX; Issues triagiert und reproduzierbare Regressionstests.
- **M2:** stabilisierte 1.x mit strukturierten Diagnostics und Release 1.2.x.
- **M3:** versioniertes IR-Schema plus Reader-Contract-Tests.
- **M4:** isolierter Asset Writer und deterministische Pfad-/Dateipolitik.
- **M5:** inkrementelle Renderer-Migration für Linie/Scatter/Bar/Surface/Text.
- **M6:** moderne MATLAB-Objekte (`tiledlayout`, `yyaxis`, Polar, Function-Objekte) nach Nutzungspriorität.
- **M7:** aktuelle Octave-Matrix und dokumentierte Abweichungen.
- **M8:** 2.0 Release Candidate mit Visual-Diffs und Migrationsleitfaden.

## 15. Offene Fragen

- Welche MATLAB-Releases und Betriebssysteme müssen offiziell unterstützt werden?
- Ist aktuelle Octave-Parität Release-Blocker oder Best-Effort?
- Welche PGFPlots-/TeX-Live-Mindestversion ist akzeptabel?
- Welche modernen Plottypen haben reale Nutzerpriorität?
- Dürfen 2.0-Ausgaben zugunsten von Determinismus/Lesbarkeit brechen?
- Können Maintainer CI-Lizenzen und Multi-OS-MATLAB-Runner bereitstellen?
- Ist der CI-Notification-Wert noch gültig, und wurde er providerseitig rotiert?
- Welche offenen PRs besitzen Rechte/Lizenzen und fachliche Qualität für Cherry-Picks?
- Wie soll visuelle Äquivalenz quantifiziert werden (Pixel-Diff, strukturelle Metriken, manuelle Freigabe)?

## Ausgeführte Befehle und Evidenzprotokoll

```text
git clone https://github.com/matlab2tikz/matlab2tikz.git matlab2tikz
git fetch --all --tags --prune
git remote show origin
git status --short --branch
git rev-parse HEAD
git show -s --format=%H%n%cI%n%an%n%s HEAD
git tag --sort=-creatordate
git log / git shortlog / git ls-tree / git diff --check
rg --files; rg -n ... src test
C:\Program Files\Git\bin\bash.exe ./runtests.sh
```

Zusätzlich wurden öffentliche GitHub-REST-Endpunkte für Repository, Issues (3 Seiten), Pull Requests, Releases und Actions-Workflows am 2026-08-06 gelesen. `gh repo view`, `gh issue list` und `gh pr list` wurden nicht ausgeführt, da `gh` fehlt. Web-/API-Status ist zeitabhängig; Commit- und Codeaussagen beziehen sich strikt auf `806c97d`.
