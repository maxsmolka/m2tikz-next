# ADR-0001: TeX engine and Unicode policy

- Status: Proposed
- Date: 2026-08-08
- Scope: policy only; no public API change in M1A

## Context

The M0 runtime baseline showed that a standalone export containing raw `Ω`
fails with pdfLaTeX and succeeds with LuaLaTeX. Existing matlab2tikz users often
embed generated axes in established pdfLaTeX documents, while current scientific
documents increasingly need direct Unicode and OpenType fonts. Choosing an engine
inside the exporter would affect compatibility far beyond this single character.

## Options

### A. Keep pdfLaTeX as default and escape or convert Unicode

This gives the least disruption to existing documents and generally fast,
predictable compilation. A conversion table can cover common mathematical
symbols, but cannot faithfully represent arbitrary scripts, combining characters,
or user-selected system fonts. Conversion also has to distinguish text and math
contexts and may silently alter intended typography. The maintenance surface is
large and incomplete by construction.

### B. Prefer LuaLaTeX as the modern engine

LuaLaTeX accepts UTF-8 directly and provides modern font selection through
`fontspec`, making it the strongest default for multilingual publications and
new scientific projects. It usually consumes more time and memory for large
PGFPlots inputs, and switching an established pdfLaTeX document may change fonts,
package behavior, and build infrastructure. Declaring it unconditionally as the
product default would therefore break expectations of existing users.

### C. Generate engine-neutral output with documented limits

The exporter avoids engine-specific preambles where possible, preserves user
text, and reports constructs whose compilation depends on the selected engine.
This fits matlab2tikz's role as a code generator and keeps embedded-output
workflows intact. Complete neutrality is not achievable for arbitrary Unicode:
pdfLaTeX still needs mappings/packages, while LuaLaTeX can consume raw text.
Users therefore need an explicit compatibility warning and engine guidance.

## Decision

Adopt **Option C as the compatibility policy**, with **LuaLaTeX recommended for
new Unicode-heavy documents**. Continue to support pdfLaTeX-oriented output and
do not silently rewrite arbitrary Unicode in M1A. A later change may add an
explicit engine target or Unicode policy, but it requires public API design,
diagnostic codes, fixtures, and MATLAB plus Octave validation.

For current users:

- ASCII and established TeX markup remain engine-neutral and compatible with
  existing pdfLaTeX publication workflows.
- Raw Unicode should be compiled with LuaLaTeX; pdfLaTeX failure is a documented
  engine limitation, not an export failure.
- Users who require pdfLaTeX should supply TeX macros (for example math-mode
  commands) or pre-process text deliberately rather than rely on lossy guessing.

## Consequences

No output or API changes are made by this ADR. The compile matrix must exercise
both engines and classify raw-Unicode/pdfLaTeX as an expected limitation. A later
2.0 phase should define structured `EngineCompatibility` diagnostics and decide
whether engine intent belongs in exporter options or project-level configuration.
