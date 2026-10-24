# m2tikz-next 0.8.1

Pre-1.0 acceptance patch under the 0.8.0 feature freeze, not production-complete
1.0. This release does not declare external acceptance finished. GitHub source
archives only; no generated products, scientific figures/data, logs or runtimes
are bundled. Original v0.8.0 remains immutable.

## Changes since 0.8.0

- Bounded horizontal/multicolumn legends above one logical 2-D axes, including
  supported single-cell tiled/dual-Y layouts. Preserve membership/order and
  detect actual TeX legend overflow rather than accepting a cropped PDF.
  Long six-column labels may need 170 mm instead of 85 mm.
- MATLAB gallery: four synthetic figure types, each at source size, 85 mm and
  170 mm, with editable FIG sources. A repeatable native smoke test checks all
  12 exports, saved/reopened figures, profile metadata and caller lifecycle.
- Internal 15-second compiler discovery and 300-second compilation budgets.
  Owned local process groups/Jobs are terminated, staged partial PDFs are not
  copied, and compiler environment/staging are restored. Actual deadlines use
  `M2T:C006:CompilerTimeout`; missing/failed supervision uses
  `M2T:C007:ProcessSupervisorFailed`. Ordinary exit codes remain distinct.
- Correctly recognize a wrapped undefined-control-sequence compiler message.
- Acceptance guidance distinguishes historical release baselines from pinned
  corrected commits. Public options, result/manifest/IR schemas are unchanged.

## New POSIX prerequisite and limits

**Linux/POSIX export requires Python 3 on PATH** for process supervision,
using only its standard library. Windows uses built-in Windows PowerShell/.NET,
without Python. Nothing is installed automatically. If supervision cannot run,
export fails closed rather than launching an unbounded compiler.

Budgets cover child discovery/compilation, not total export time. Startup,
OS scheduling/termination and other stages add time; each figure-set entry has
its own budgets. Very slow documents can now fail explicitly. There is no public
deadline override/cancellation option. Detached POSIX or remote WSL/container/
service work is outside the local process boundary. Trusted TeX only: this is
not a sandbox or protection against disk/resource exhaustion.

## Evidence and remaining acceptance

Native focused testing uses MATLAB R2026b on Windows; real compilation uses
the existing Linux LuaLaTeX bridge. Hosted CI uses GNU Octave 11.3 on Linux.
Timeout regressions exercise hung discovery/build, owned children, staged
partial PDFs, cleanup/environment, large output and normal exit codes. Existing
compiler/API/environment/profile workflows remain separate gates.

Historical 0.8.0 MATLAB R2026a Update 5 evidence is not relabeled as R2026b.
MATLAB R2022a, native Windows MiKTeX and broader real scientific acceptance are
still pending. Compilation success is not scientific/visual approval. Existing
unsupported graphics/layout/3-D limits and precision policies still apply.

## Try the patch

```console
git clone https://github.com/maxsmolka/m2tikz-next.git
cd m2tikz-next
git checkout --detach v0.8.1
git rev-parse HEAD
```

In MATLAB from the checkout root:

```matlab
addpath(fullfile('examples', '13-profile-gallery'));
results = example_profile_gallery();
```

Keep real source figures/data and generated evidence local. Follow the
[acceptance guide](../validation/EXTERNAL_ACCEPTANCE_TESTING.md) for 5-10 important
figures and manually review scientific content, layout and physical widths.
The project remains independently derived from matlab2tikz, retaining upstream
Git history, BSD-2-Clause license and attribution.
