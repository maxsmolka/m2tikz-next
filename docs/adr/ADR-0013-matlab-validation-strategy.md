# ADR-0013: MATLAB validation strategy

## Status

Accepted and executed for M4.1. MATLAB R2026a Update 4 was validated locally on
Windows; hosted GNU Octave remains the public CI lane.

## Context

The modern architecture has strong GNU Octave 11.3 evidence on Windows and
hosted Linux but lacks direct MATLAB HG2 evidence. MATLAB and Octave may expose
different object classes, helpers, hierarchy, and defaults even when they
represent the same scientific figure. Claiming compatibility from Octave alone
would be unsupported.

## Decision

Use one layered, semantic, evidence-driven MATLAB validation program. A thin
MATLAB entry point invokes shared test infrastructure for runtime/environment
checks, an authoritative F01–F26 fixture registry, normalized HG audits,
FigureIR evidence, field-aware cross-runtime comparison, deterministic renderer
checks, public workflow and TeX/PDF validation, figure-mutation checks, and a
manual V01–V08 visual subset. JSON and Markdown reports connect each result to
runtime, IR, workflow, and compilation evidence while sanitizing machine paths
and excluding identity and license data.

The key principle is that graphics trees need not be structurally identical.
Normalized scientific semantics must be equivalent. Product changes in M4.1
must follow observed capability evidence, preferably property detection rather
than runtime/version branches. Legacy smoke is reported separately from modern
support criteria.

Two lanes remain: public GNU Octave GitHub Actions and local licensed MATLAB
validation. Public CI does not acquire or imply a MATLAB license. A future
MathWorks Actions lane may be evaluated only with explicit availability and
licensing.

## Rejected alternatives

- claiming MATLAB support based on Octave evidence;
- speculative reader patches before MATLAB execution;
- comparing raw handle trees as compatibility goldens;
- requiring identical runtime defaults;
- manual-only validation without machine-readable evidence;
- duplicating all suites into a separate MATLAB-only codebase;
- collecting license, account, hostname, or machine identifiers.
