#!/usr/bin/env python3
"""Generate the Unicode 17.0.0 canonical normalization tables.

Usage: generate-normalisation.py UCD_DIRECTORY > UnicodeNormaliseData.sml
The directory must contain UnicodeData.txt and DerivedNormalizationProps.txt
from https://www.unicode.org/Public/17.0.0/ucd/.
Only regeneration requires Python; the library itself is pure Standard ML.
"""
import hashlib
from pathlib import Path
import sys

root = Path(sys.argv[1])
# Pinned input hashes prevent silently generating a mixture of Unicode versions.
EXPECTED = {
    "UnicodeData.txt": "2e1efc1dcb59c575eedf5ccae60f95229f706ee6d031835247d843c11d96470c",
    "DerivedNormalizationProps.txt": "71fd6a206a2c0cdd41feb6b7f656aa31091db45e9cedc926985d718397f9e488",
}
for name, expected in EXPECTED.items():
    if hashlib.sha256((root / name).read_bytes()).hexdigest() != expected:
        raise SystemExit("Unexpected Unicode 17.0.0 input: " + name)

excluded = set()
quick = {"NFC_QC": [], "NFD_QC": []}
for line in (root / "DerivedNormalizationProps.txt").read_text().splitlines():
    fields = line.split("#")[0].strip().split(";")
    if len(fields) >= 3 and fields[1].strip() in quick:
        bounds = fields[0].strip().split("..")
        quick[fields[1].strip()].append((int(bounds[0], 16), int(bounds[-1], 16)))
    if len(fields) < 2 or fields[1].strip() != "Full_Composition_Exclusion":
        continue
    bounds = fields[0].strip().split("..")
    excluded.update(range(int(bounds[0], 16), int(bounds[-1], 16) + 1))

classes, decompositions, compositions = [], [], []
for line in (root / "UnicodeData.txt").read_text().splitlines():
    fields = line.split(";")
    cp, ccc, mapping = int(fields[0], 16), int(fields[3]), fields[5]
    if ccc:
        classes.append((cp, ccc))
    if mapping and not mapping.startswith("<"):
        parts = [int(x, 16) for x in mapping.split()]
        decompositions.append((cp, parts))
        if len(parts) == 2 and cp not in excluded:
            compositions.append((parts[0], parts[1], cp))
compositions.sort()

print("(* Generated from Unicode 17.0.0; do not edit by hand.")
print(" * Regenerate with tools/generate-normalisation.py.")
print(" * Unicode data license: tools/unicode-license.txt. *)")
print("structure UnicodeNormaliseData = struct")

def vector(name, entries):
    print("  val " + name + " = Vector.fromList [")
    print(",\n".join("    " + entry for entry in entries))
    print("  ]")

vector("classes", [f"({cp}, {ccc})" for cp, ccc in classes])
vector("decompositions", [f"({cp}, [{', '.join(map(str, parts))}])"
                          for cp, parts in decompositions])
vector("compositions", [f"(({a}, {b}), {cp})" for a, b, cp in compositions])
for prop, name in [("NFC_QC", "nfcQuickCheck"), ("NFD_QC", "nfdQuickCheck")]:
    vector(name, [f"(({lo}, {hi}), ())" for lo, hi in sorted(quick[prop])])
print("end")
