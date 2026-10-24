# ADR-0027: Internal compiler process deadlines

Status: accepted for the 0.8.1 compatible acceptance patch.

## Context

A synchronous version probe or TeX compilation could previously hang forever.
The freeze permits robustness/diagnostic fixes but not speculative API growth.
A compiler exit code alone cannot identify a deadline: real tools may exit
124 or 137 themselves. Killing only a shell leaves children and partial PDFs.

## Decision

Keep public options/result/manifest schemas unchanged. Internally budget 15
seconds for discovery and 300 seconds for each compilation. An internal fourth
compiler argument permits short executable tests; it is not a public setting.
Report C006 on an actual deadline, C007 on missing/failed supervision, and keep
ordinary failures as C001/C003. Preserve local failure logs and cleanup; never
accept a staged PDF after expiration.

Windows uses built-in Windows PowerShell/.NET with a suspended command assigned
to a kill-on-close Job before resuming it. This prevents the child-creation
race and also cleans children when a launcher exits early. POSIX requires
Python 3 on PATH, standard library only, with `start_new_session`, timed wait,
process-group KILL and reaping. This explicit POSIX runtime prerequisite is new
in 0.8.1; absence fails closed, not an unbounded fallback. Python is not an export
dependency on Windows. No packages are downloaded/installed by the exporter.
The local Linux `timeout` implementation failed the retained-child test; do
not rely on superficially compatible timeout utilities or status heuristics.

Output goes to files, avoiding pipe-buffer/retained-pipe deadlocks. Existing
argument checks and no-shell-escape flags remain. Environment values and locale
are preserved. Process control remains in the compiler layer, never renderers.

## Limits and acceptance

These are child-process budgets, not a hard end-to-end timing guarantee or a
sandbox. OS scheduling, supervisor startup and other export stages add time.
Remote/detached service/WSL/container work is not guaranteed to terminate.
Figure sets apply budgets per figure. Very slow legitimate documents now fail
explicitly rather than running indefinitely; there is no public override yet.

`runCompilerTimeoutTests` exercises hung discovery/build, partial staged PDF
rejection, child termination, environment/staging cleanup and ordinary exit
codes. Run on native Windows MATLAB and Linux Octave, alongside real successful/
invalid compilation, public API/security/environment and profile regressions.

Implementation references: [Windows Job Objects](https://learn.microsoft.com/en-us/windows/win32/procthread/job-objects)
and [Python subprocess](https://docs.python.org/3/library/subprocess.html).
