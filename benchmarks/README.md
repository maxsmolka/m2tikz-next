# Large-data benchmark

`benchmarkLargeData` preserves the M0 performance matrix without making timing
or TeX resource consumption a unit-test gate. It exports 100, 10,000, 100,000,
and 1,000,000 points in both inline and PGFPlots external-data form and, by
default, compiles each standalone document with LuaLaTeX through `latexmk`.

From the repository root:

```matlab
addpath(fullfile(pwd, 'benchmarks'));
benchmarkLargeData();
```

For a quick exporter-only check:

```matlab
benchmarkLargeData([100 10000], false);
```

Results and generated assets are written below `benchmarks/output/`, which is
ignored by Git. The TSV records export time, TeX size, external file count and
size, and compile time/status. Portable peak RSS measurement is deliberately not
guessed; use the operating system's process telemetry when peak memory matters.
