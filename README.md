# moonfga-docshare

A small document-sharing authorization core using the published
[`sundaysebasidian-byte/moonfga@0.2.5`](https://mooncakes.io/docs/sundaysebasidian-byte/moonfga)
registry package. **This example is written by the MoonFGA authors**, under the
generic author name `moonfga-docshare contributors`. It is an example application,
not evidence of independent adoption or production deployment.

The library parses a schema 1.1 model, loads tuples into MoonFGA's `MemoryStore`,
uses `Engine.check` / `check_with` for decisions, and `Engine.list_objects` for
document discovery. There is no locally linked or copied authorization engine.

## Model and API

- Users can be group members. Groups can receive viewer/editor shares.
- Folder viewer/editor rights inherit to documents through `parent`.
- Document owners can edit and view; editors can view. Folder ownership implies
  folder edit/view, inherited by documents. Document ownership stays local.
- A document viewer tuple can use CEL `now < expires_at`. Equality denies access.
  Expiry limits that grant only; another independent grant can still allow access.
- `DocShare::{new, from_json, share_document, can_view, can_edit,
  list_viewable_documents}` wrap the fixed model. `model_source()` exposes its DSL.

The root package is the library. IDs are fully qualified (`user:reader`,
`document:guide`, `group:team#member`). `share_document(document, subject, role)`
accepts `Viewer`, `Editor`, or `Owner`, returns whether a tuple was newly inserted,
and validates it against direct model restrictions. `from_json` accepts a JSON
array of MoonFGA tuple objects; see `sample/tuples.json` for the condition format.
Malformed JSON/tuples and engine errors propagate as `FgaError`.

This is an in-memory service core with trusted provisioning inputs. The caller
must authenticate users, authorize share mutations, provide a trusted clock for
`now`, and implement persistence and revocation if needed. The CLI takes an
explicit RFC3339 time for reproducibility. It does not consult the system clock.
Timestamp validation occurs when MoonFGA evaluates a conditional grant; unrelated
unconditional queries may not evaluate the supplied time.

MoonFGA is an independent OpenFGA-style implementation. This example exercises a
small model, not the full compatibility surface. See its
[compatibility matrix and known differences](https://github.com/sundaysebasidian-byte/moonfga/blob/v0.2.5/docs/openfga-comparison.md)
and [conformance evidence](https://github.com/sundaysebasidian-byte/moonfga/blob/v0.2.5/docs/conformance.md).

## Reproduce locally

Requires MoonBit `moon 0.1.20261104`, a native C compiler, and Python 3.
JS tests additionally require Node.js; wasm-gc uses the toolchain's `moonrun`.
Run from this module's root:

```sh
export MOON_HOME=/tmp/moon-new
export PATH="$MOON_HOME/bin:$PATH"
moon version
moon add sundaysebasidian-byte/moonfga@0.2.5
moon add moonbitlang/x@0.5.7
moon fmt
moon check --deny-warn --target native
moon test --deny-warn --target native
python3 scripts/test-cli.py native
moon package
```

The second registry dependency supplies CLI filesystem and process APIs.
The committed manifest records both versions; for a fresh checkout `moon update`
resolves them without repeating `moon add`. No credentials are required for these
public dependencies or `moon package`. Do not run `moon publish` without
`--dry-run`; no publication is needed for this example.

```sh
moon run --quiet --target native cmd/main -- check sample/tuples.json user:member document:guide edit 2030-01-01T00:00:00Z
# true
moon run --quiet --target native cmd/main -- list sample/tuples.json user:reader 2030-01-01T00:00:00Z
# ["document:guide","document:notes"]
moon run --quiet --target native cmd/main -- check sample/tuples.json user:guest document:temporary view 2030-01-02T00:00:00Z
# false
```

CLI syntax:

```text
check <tuples.json> <user> <document> <view|edit> <now RFC3339>
list <tuples.json> <user> <now RFC3339>
```

Check prints one boolean; list prints a JSON array sorted lexicographically.
Both allowed and denied decisions exit 0. Usage, file, parse, and evaluation
errors print `error: ...` and exit 2. The time argument is unused for `edit`.

`scripts/test-cli.py` runs the real CLI against bundled data, compares 11 outputs
byte for byte with `sample/expected.txt`, and checks five nonzero error cases.
The eight library tests cover inheritance, groups, conditional allow/deny,
unrelated subjects, ListObjects, sharing roles, and invalid inputs.

```sh
for target in js wasm-gc; do
  moon check --deny-warn --target "$target"
  moon test --deny-warn --target "$target"
done
moon fmt --check
```

The manual-only Ubuntu workflow is provided in `.github/workflows/ci.yml`.
It is not activated in this local-only repository and has not been run on GitHub.
It uses the official current stable installer; it may differ from the exact
local toolchain recorded below. Installer instructions: [MoonBit downloads](https://www.moonbitlang.com/download/).
See `audit/validation.md` for local validation and any unverified behavior.

Apache-2.0. Copyright 2026 moonfga-docshare contributors.
