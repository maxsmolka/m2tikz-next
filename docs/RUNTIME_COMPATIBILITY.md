# Runtime compatibility contract

Compatibility is capability-based, not inferred from a version number. No
new plot family or public API is introduced by M7.2. The end-user interfaces
remain [m2t.export and m2t.exportSet](API.md).

Validated with MATLAB R2026a Update 4 on Windows.

This sentence records historical evidence. M7.2 and current 0.8.0 release
validation use MATLAB R2026a Update 5 on Windows. The controlled Octave
environment is GNU Octave 11.3 with
gnuplot on Linux in a container. Neither proves another MATLAB release,
another Octave toolkit, nor a native Windows Octave installation.

## Evidence layers

Native MATLAB reader evidence means actual MATLAB graphics were instantiated
and read. Native Octave reader evidence means actual Octave graphics, not
MATLAB graphics interpreted by Octave. Runtime-neutral FigureIR evidence checks
payloads, ownership, canonical persistence and replay. Renderer evidence checks
the generated plan without runtime handles. TeX/PDF evidence means the real
compiler and PDF validator ran; it is not proof of pixel parity or all possible
surrounding document configurations. Unsupported constructors are reported as
portable-only, never as native passes.

## Required source state and retained dependencies

| Family | Required source properties/relationships | Boundary |
| --- | --- | --- |
| Axes/line/errorbar | Limits, scales, directions, ticks, XYZ data, error deltas, styles and actual children | Numeric Cartesian rulers only; Octave compound error geometry is verified. |
| Rich scatter | XYZ, SizeData, CData, marker edge/face roles, alpha | Per-point roles remain coupled; Octave hggroup patch partitions are verified. |
| Legends | Entries and actual PlotChildren / Octave peer links | No inferred ordering by label, color or position; unresolved links fail. |
| Colorbars | Axes association, limits, orientation, direction, ticks, mapping | Octave axes-backed display properties override stale convenience fields. |
| Text/annotations | String, interpreter, visibility, position, coordinate units, explicit owner | Scalar nonmissing strings normalize to char; unsupported string arrays reject. |
| Grouped bars | Peer group, X/Y, baseline, widths, resolved patches | Geometry verified against source semantics; no arbitrary patches. |
| Boxplots | Traditional filled compound metadata and child geometry | MATLAB compound only; Octave package boxplots do not imply this contract. |
| Tiled layouts | GridSize, tile/span, indexing, spacing, padding, explicit parents | Fixed MATLAB layout only; shared labels retain layout ownership. |
| Dual Y | Two rulers, active-side Children, independent limits/ticks/colors | MATLAB yyaxis only; active side restored after reading. |
| Scalar/RGB/alpha images | CData, mapping/index base, coordinates, AlphaData/mapping | uint8/uint16 RGB normalize by full range; no resampling. |
| Supported 3-D | XYZ, view, projection, aspect, camera modes, scene order | Orthographic bounded scenes; multi-object order must be explicit. |
| Multiple axes/profiles | Source rectangles, stable source traversal, owners, physical size | Profile runs after reading; no runtime handles enter renderer. |

Readers do not gate support on MATLAB release numbers. Remaining native
NumericRuler class guards are intentional: merely finding Limits/Ticks does
not establish numeric units (datetime, duration and categorical rulers differ).
The Octave compound/axes-backed adapters and MATLAB tiled/yyaxis adapters are
necessary representation differences, not OS heuristics. Hidden peer metadata
and traditional boxplot metadata remain narrowly validated dependencies; their
absence or inconsistency must fail closed. Removing these checks would widen
claims without evidence.

Manual colorbar placement illustrates an actual difference: MATLAB changes
`Location` to `manual`, so the existing unresolved-orientation guard rejects
it with `M2T2:E007:UnsupportedProperty`. The observed Octave axes-backed
colorbar retains its explicit orientation and can preserve that rectangle.
The older M2.3 fixture now asserts these distinct outcomes instead of claiming
that its original Octave success expectation proves native MATLAB support.

Optional properties in the common axes, semantic guard, figure association,
scatter, errorbar, legend, bar alpha, tick interpreter and colorbar paths now
use explicit property inspection. Only absence
selects a documented default; an existing getter exception is not swallowed.
Invalid/deleted graphics handles reject. Required payloads are validated by
family readers and FigureIR; this is not a general license to default missing
scientific data. Other narrowly scoped ownership adapters retain explicit
unsupported outcomes when links cannot be resolved.

## Numeric and text boundary

Single/double coordinate vectors normalize to double. Scalar integer image
samples retain values and direct-index base; uint8/uint16 RGB and alpha follow
their documented normalized range. Logical CData/alpha are not silently treated
as numeric arrays: the existing explicit unsupported boundary remains.
The public path is not an exact arbitrary-width integer archive. See
[precision and determinism](DETERMINISM.md).

Character rows, existing cell-text normalization and scalar MATLAB strings are
handled explicitly. Missing strings and nonscalar string arrays reject instead
of dropping items. Cell/matrix text retains the existing space-joined contract;
this change does not introduce multiline typesetting. Octave 11.3 does not
provide MATLAB string arrays. Its gnuplot image constructor rejects single
AlphaData, so the common native alpha fixture uses double there; MATLAB tests
single alpha. This is source-runtime evidence, not exporter coercion.

## Synthetic acceptance suite

`test/runM72RuntimeCompatibilityTests` covers R01 line/errorbar/reordered
legend; R02 log/reverse/custom ticks; R03 rich scatter; R04 grouped bars; R05
boxplot; R06 tiled/shared labels; R07 dual Y; R08 scalar image/colorbar; R09
uint8 RGB/per-pixel alpha; R10 text/annotation; R11 surface/Line3; R12 scatter3;
R13 multiple axes; R14 publication profile; R15 figure set.

Every case validates IR, canonical replay and deterministic renderer output.
The optional second argument `true` additionally compiles all 15 representative
plans and runs actual public profile/set workflows. Octave R05–R07 replay
portable semantic fixtures because these supported native MATLAB constructors
are unavailable there. Native R10 figure arrows are MATLAB-specific; Octave
still reads the axes text. Focused helper checks cover absent/present/deleted
properties and scalar/missing/array string behavior. Existing milestone suites
remain mandatory; these 15 cases do not replace their negative matrices.

The boxplot fixture requires the installed MATLAB `boxplot` constructor;
this test environment is not evidence for a base-only MATLAB installation.
Missing optional fixture dependencies must be reported, not replaced by a
different runtime's similarly named plot and counted as native support.
