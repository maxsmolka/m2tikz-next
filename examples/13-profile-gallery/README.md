# MATLAB profile gallery

Run from the repository root in MATLAB:

```matlab
addpath(fullfile('examples', '13-profile-gallery'));
results = example_profile_gallery();
```

The function adds `src` automatically. LuaLaTeX must be accessible from MATLAB,
with TikZ, PGFPlots and standalone installed. Check with
`system('lualatex --version')` and `system('kpsewhich pgfplots.sty')`.

Four synthetic figures stay open: two lines, scatter observations, asymmetric
error bars, and six lines with a horizontal six-column legend above the axes.
No external data or toolboxes are required. This is a MATLAB example using
`savefig` and `NumColumns`, not an Octave compatibility example.

Each figure is exported three ways below `.audit/profile-gallery/`:

| Filename suffix | Export settings |
| --- | --- |
| `no-profile` | No `Profile` or `Width`; uses the source figure size |
| `single-column-85mm` | `Profile='publication'`, `Width='single-column'` |
| `double-column-170mm` | `Profile='publication'`, `Width='double-column'` |

There are 12 PDF/TeX pairs plus four editable `.fig` sources. Rerunning replaces
these demo products, not other figures. Generated files stay ignored by Git.
Publication typography stays physically fixed; single/double-column describe
the PDF width, not the number of axes or legend columns. Compare PDFs at the
same zoom or actual size, since fit-to-window can conceal the width difference.
Short `S1` through `S6` labels deliberately fit both publication widths. Longer
six-column labels may require double-column; overflow fails rather than
silently shrinking text or cropping the legend.

Inspect a result or open a PDF:

```matlab
results(1).exports(2).result.success  % expected: 1
open(results(1).exports(2).result.pdfPath);
```

For your own figure, change `makeExample` or use:

```matlab
[name, folder] = uigetfile('*.fig');  % select a file; do not cancel
fig = openfig(fullfile(folder, name));
result = m2t.export(fig, fullfile('.audit', 'my-figure-double-column'), ...
    'Profile', 'publication', 'Width', 'double-column', 'Overwrite', true);
disp(result.success);
disp(result.diagnostics);
if result.success, open(result.pdfPath); end
```

An `.m` file contains executable examples; `.mat` stores variables, and `.fig`
stores an editable MATLAB figure. Binary `.mat` data is unnecessary here:
all demo data is reproducibly generated in the source.

Validation: all 12 exports and four saved/reopened figures passed with MATLAB
R2026b on Windows using the local Linux LuaLaTeX bridge. PDF widths, glyph/page
bounds and all six legend entries were checked, followed by visual review.
This does not qualify MATLAB R2022a or native Windows MiKTeX.

Repeat the native smoke test from the repository root with:

```matlab
addpath('test');
summary = runProfileGallerySmokeTests();
```

It compiles all 12 variants, reopens the four `.fig` sources and checks sizes,
legend state and figure lifecycle. Each invocation preserves earlier evidence
in a new subdirectory. See [testing](../../test/README.md).
