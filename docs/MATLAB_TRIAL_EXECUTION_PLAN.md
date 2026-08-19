# MATLAB trial execution plan

This plan starts only after the activation gate below is complete. It preserves
trial time by using one non-interactive evidence command and investigating
failures by layer rather than redesigning tests after activation.

## Before activation

- [x] MATLAB runner prepared
- [x] fixture registry complete
- [x] report generation prepared
- [x] compatibility matrix prepared
- [x] HG audit prepared
- [x] one-command runner documented
- [x] local Octave regression green
- [x] no unresolved M4.0 infrastructure issues

Do not record account, license, hostname, serial, MAC-address, or home-directory
data in evidence or issue reports.

## Day 1 — runtime and graphics evidence

From a PowerShell prompt with MATLAB and LuaLaTeX on `PATH`:

```powershell
matlab -batch "addpath('test'); result=runMatlabValidation; assert(result.success)"
```

This detects the exact release/architecture, validates writable paths and
external tools, records installed product names/versions, audits HG objects,
runs F01–F26, compiles workflows, checks mutation, runs legacy smoke separately,
and writes:

```text
build/matlab-validation/report.json
build/matlab-validation/report.md
build/matlab-validation/hg-audit/F*.json
build/matlab-validation/fixtures/F*/
```

If L0 fails, repair the environment before diagnosing product compatibility.
Retain the report and compile logs.

## Day 2 — reader and IR comparison

Compare sanitized MATLAB IR evidence with a same-revision Octave evidence run:

```powershell
octave-cli --quiet --eval "addpath('test'); result=runOctaveValidation('build/octave-validation'); assert(result.success)"
```

Use `m2t_test.compareEvidenceFiles` for matching `ir.json` files. Classify each
difference as exact, tolerance-equivalent, declared runtime representation, or
semantic mismatch. Inspect HG snapshots only to explain reader gaps; never make
raw tree identity a gate.

## Day 3 — workflow, TeX, and PDF

Review L3–L7 results, compile logs, physical profile geometry, overwrite and
failure behavior, manifests, and before/after figure state. Classify missing
LuaLaTeX/PGFPlots as environment failures. Compare TeX as byte-identical when
possible and semantically equivalent otherwise.

## Day 4 — images, hybrid, and planner

Review F18–F26: image coordinates/directions, CLim/colormap/NaN, hybrid PNG
dimensions and bytes, vector axes/colorbar, and 4095/4096/4097 planner decisions.
Unsupported RGB and alpha remain explicit; they are not M4 expansion work.

## Day 5 — triage and visual subset

Apply the A–E policy in [MATLAB_OCTAVE_DIFFERENCES.md](MATLAB_OCTAVE_DIFFERENCES.md).
Generate and manually inspect V01–V08. Fix only evidence-backed compatibility
gaps, rerun the one-command validation after each coherent change, and update
the matrix only when retained evidence is green.

Do not generalize one trial release to all MATLAB versions. Record the exact
detected `R20XXx` in the eventual M4.1 report and support statement.
