# m2tikz-next 0.8.2

Pre-1.0 acceptance patch for lower legends under the 0.8.0 feature freeze.
Source archives only: no real scientific figures/data, generated PDFs/logs,
MATLAB runtimes or local evidence are bundled. v0.8.0 and v0.8.1 stay immutable.
External scientific acceptance is still pending; this is not production-complete
1.0 or a promise of support for every MATLAB/TeX installation.

## Changes since 0.8.1

- Support `southoutside` below one logical Cartesian 2-D axes, including
  horizontal two-row legends: six entries with `NumColumns=3`.
- Reserve physical space below X ticks and the X label in both 85/170 mm
  publication profiles. Source-size exports preserve original geometry and
  require sufficient original bottom margin.
- Preserve legend membership/order/columns/box state and source scientific
  content. Supported one-cell tiled and dual-Y cases retain their ownership;
  dual-Y legend overlays preserve original X-label clearance.
- Reject actual legend overflow rather than shrinking text/columns, widening
  the page or silently changing source geometry. Existing upper layouts remain
  byte-identical. Public options/result/manifest/IR schema numbers are unchanged.

East/west/manual/shared/multi-axes/3-D outside legends and vertical multicolumn
layouts remain unsupported. Long/custom/multiline labels or other lower
decorations still require visual review; this is not general collision avoidance.
See [legend layout](../LEGENDS.md) and [ADR-0028](../adr/ADR-0028-lower-outside-legends.md).

## Validation and environment

Focused native MATLAB R2026b/Windows testing covers three actual public exports
(source size, 85 mm, 170 mm), plus nine portable IR/PDF layouts also compiled
on Octave 11.3/Linux. All 21 lower PDFs were measured and visually reviewed.
Source-margin and excessive-width failures, caller preservation, negative
ownership/layout cases and existing upper/IR/profile/unsupported regressions
are separate checks. Hosted CI runs portable semantics, real TeX and PDF
geometry checks; it does not run native MATLAB.

Native real compilation uses the existing Linux LuaLaTeX bridge. R2022a and
native Windows MiKTeX remain external acceptance targets, not newly qualified
environments. Prerequisites are unchanged from 0.8.1: POSIX requires Python 3;
Windows uses built-in Windows PowerShell/.NET. Internal compiler discovery/
compilation budgets remain 15/300 seconds; these do not bound total export time
or detached/remote work. No dependencies are installed automatically.

## Update and test a six-entry legend

In an existing clone:

```console
git fetch origin --tags
git checkout --detach v0.8.2
git rev-parse HEAD
```

Restart MATLAB, select the checkout root as the current folder, then select a
trusted `.fig` with one supported 2-D axes and six legend entries:

```matlab
addpath('src');
[name, folder] = uigetfile('*.fig');
if isequal(name, 0), return; end
fig = openfig(fullfile(folder, name));
legend(fig.CurrentAxes, 'show', 'Orientation','horizontal', ...
    'NumColumns',3, 'Location','southoutside');
result = m2t.export(fig, fullfile('.audit','lower-legend-170mm'), ...
    'Profile','publication', 'Width','double-column', 'Overwrite',true);
disp(result.success); disp(result.status); disp(result.diagnostics);
if result.success, open(result.pdfPath); end
```

For 85 mm use `Width='single-column'` and another output name. Without a profile,
omit both `Profile` and `Width`, use another name, and ensure the source already
has enough bottom margin. Do not remove unsupported scientific content simply
to obtain success. The example changes the open legend intentionally but does
not save over the original FIG. Compare the original and PDF, including all six
entries in two rows and clearance from ticks/X label/page edges. Compilation
success is not scientific approval. Keep source figures and generated evidence
local; follow the [acceptance guide](../validation/EXTERNAL_ACCEPTANCE_TESTING.md).
