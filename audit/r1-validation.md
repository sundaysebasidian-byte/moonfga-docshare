# R1 review fixes

Author: moonfga-docshare contributors.

- A1: a folder-owner tuple now has a dedicated test for inherited document edit,
  view and ListObjects results.
- A2: group membership plus direct document Viewer and Editor shares now has a
  dedicated test for both rights, viewer-only denial of edit, nonmember denial,
  and ListObjects results. No folder grant participates in this test.
- A4: CLI diagnostics use stderr. The CLI test requires empty stdout and exit 2
  on all five error cases, and empty stderr on successful result cases.
- A3: `.moonignore` excludes internal audit, closeout and evidence directories.
  `moon package --list` and the final ZIP entries were inspected. The exclusions
  work with the required `moon 0.1.20261104`; audit files remain in Git.
- README setup now requires any `moon >= 0.1.20261104` on PATH, with no fixed
  installation directory.

Validation: `moon fmt` and `moon fmt --check` pass. On each of native, JS and
wasm-gc, `moon check --deny-warn` passes and `moon test --deny-warn` passes 10/10.
On native and JS, `python3 scripts/test-cli.py <target>` passes 11 exact outputs
plus five stderr/error cases. [Command output](r1-commands.txt).

The initial wasm-gc CLI stream check failed: core's `eprintln` explicitly falls
back to stdout on wasm-gc in this toolchain (confirmed in core/builtin/console.mbt
and by captured stdout/stderr). The CLI now declares only native and JS support;
the library continues to support all three targets. The original CLI requirement
is native. No host-specific stderr workaround or third-party runtime was added.

Mutation results, run separately on native:

| Mutation | Result |
| --- | --- |
| A1: remove `or owner` from folder editor | 9 passed, 1 failed; the new folder-owner test fails; exit 2 |
| A2: remove `group#member` from document viewer restriction | 9 passed, 1 failed; the new direct document group test fails; exit 2 |
| A4 regression probe: send CLI diagnostics back to stdout | CLI test rejects the error response; exit 1 |

Each mutated file was restored byte-for-byte in a `finally` block before final
validation. [Mutation output](r1-mutations.txt).

Package validation passes with the existing missing-repository-URL warning.
There is no invented repository URL and no remote. Package contents retain the
library, CLI, tests, sample data, README, license and CLI verification script.
Internal audit/closeout/evidence files are not shipped. Personal-data scans cover
the first-party files, Git identity and final ZIP text payload; see
[scan results](personal-data-scan.txt).

Only the specified local toolchain was executed. Ubuntu/GitHub Actions and
Windows remain unverified; no new publication or publish dry-run was attempted.
No push, remote creation or credential setup was performed.

Closeout: no moved/deleted files, Trash destinations or restore operations.
Current source, fixtures, audit evidence, registry dependencies and build/package
outputs are retained. No server/browser/background task was started. See
[closeout manifest](closeout.json).
