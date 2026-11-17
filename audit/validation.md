# Local validation

Environment: macOS arm64; `MOON_HOME=/tmp/moon-new`, its `bin` first on PATH.
`moon 0.1.20261104 (940aa18 2026-11-04)`;
`moonc v0.10.20+65efd5b93 (2026-11-05)`.
Author: moonfga-docshare contributors.

See [commands.txt](commands.txt) for command output and exit status.

| Command | Result |
| --- | --- |
| `moon add sundaysebasidian-byte/moonfga@0.2.5` | Registry dependency resolved; no local path dependency |
| `moon add moonbitlang/x@0.5.7` | Registry dependency resolved |
| `moon fmt`, `moon fmt --check` | Passed |
| `moon check --deny-warn --target native/js/wasm-gc` (separate runs) | All passed |
| `moon test --deny-warn --target native/js/wasm-gc` (separate runs) | 8/8 on each target |
| `python3 scripts/test-cli.py native/js/wasm-gc` (separate runs) | Each: 11 exact outputs + 5 error cases passed |
| `moon info` | Public interfaces generated |
| `moon package` | Passed; missing repository URL warning only |
| `moon publish --dry-run` | Exit 255: registry login required; no credentials supplied |

Package: `_build/publish/sundaysebasidian-byte-moonfga-docshare-0.1.0.zip`.
No repository URL was invented for this local-only project. No publish, push,
remote creation, or credential setup was performed.

The initial native test run caught default String sorting that orders by length
before content. Explicit `String::lexical_compare` fixed it; the sharing test
retains different-length IDs as a regression. The initial CLI output test caught
the executable prefix in argv; separate native/Wasm and JS argument offsets are
now exercised by all three real CLI runs.

Personal-data scan covers authored files, public interfaces, the package payload,
and local Git identity metadata. Registry/build caches are third-party/generated
inputs and are excluded from the authored-file scan. The explicitly required
package namespace is allowed. User handles in fixtures are synthetic role IDs.
See [personal-data-scan.txt](personal-data-scan.txt) for results.

Not verified: Ubuntu/GitHub Actions execution, Windows, actual publication, or
broader OpenFGA compatibility. The workflow uses the official current stable
installer, which can differ from the locally validated toolchain. An attempted
date-only installer archive URL returned HTTP 403 and is not used by the workflow.
The local package command validates packaging without registry login; the
publish dry-run did not reach registry-side validation.

Closeout: [closeout.json](closeout.json). Current source, sample data, dependency
cache, build/test evidence and package are retained. No old source copy or
temporary server/browser was created. No Trash moves or deletions were needed.
