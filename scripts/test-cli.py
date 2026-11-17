#!/usr/bin/env python3
"""Check the real CLI against bundled fixtures, without temporary files."""
import difflib
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
TARGET = sys.argv[1] if len(sys.argv) == 2 else "native"
if TARGET not in {"native", "js"}:
    sys.exit("CLI supports native and js; wasm-gc is supported by the library only")
NOW = "2030-01-01T00:00:00Z"
EXPIRY = "2030-01-02T00:00:00Z"


def run(args):
    return subprocess.run(
        ["moon", "run", "--quiet", "--target", TARGET, "cmd/main", "--", *args],
        cwd=ROOT, text=True, capture_output=True, check=False,
    )


cases = [
    ["check", "sample/tuples.json", "user:member", "document:guide", "edit", NOW],
    ["check", "sample/tuples.json", "user:reader", "document:guide", "view", NOW],
    ["check", "sample/tuples.json", "user:reader", "document:guide", "edit", NOW],
    ["check", "sample/tuples.json", "user:guest", "document:temporary", "view", NOW],
    ["check", "sample/tuples.json", "user:guest", "document:temporary", "view", EXPIRY],
    ["check", "sample/tuples.json", "user:outsider", "document:private", "view", NOW],
    ["check", "sample/tuples.json", "user:owner", "document:private", "edit", NOW],
    ["list", "sample/tuples.json", "user:reader", NOW],
    ["list", "sample/tuples.json", "user:guest", NOW],
    ["list", "sample/tuples.json", "user:guest", EXPIRY],
    ["list", "sample/tuples.json", "user:outsider", NOW],
]
actual = ""
for args in cases:
    result = run(args)
    if result.returncode or result.stderr:
        sys.exit(result.stderr + result.stdout)
    actual += result.stdout
expected = (ROOT / "sample/expected.txt").read_text()
if actual != expected:
    sys.exit("".join(difflib.unified_diff(
        expected.splitlines(True), actual.splitlines(True), "expected", "actual"
    )))

for args, message in [
    ([], "usage:"),
    (["check", "sample/tuples.json", "user:guest", "document:temporary", "own", NOW], "usage:"),
    (["list", "sample/missing.json", "user:reader", NOW], "cannot read tuples file"),
    (["list", "sample/expected.txt", "user:reader", NOW], "invalid tuples JSON"),
    (["check", "sample/tuples.json", "user:guest", "document:temporary", "view", "invalid"], "error:"),
]:
    result = run(args)
    if result.returncode != 2 or result.stdout or message not in result.stderr:
        sys.exit(f"unexpected error response: {result.returncode}: {result.stdout}{result.stderr}")

print(f"CLI ({TARGET}): {len(cases)} expected outputs + 5 error cases passed")
