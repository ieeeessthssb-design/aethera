"""Turn thumbnail numbers from a contact sheet into an exclusion list.

    python -m ai.vision.make_exclusions tomato__healthy 3 7 12-15
    python -m ai.vision.make_exclusions pepper__bacterial_spot 2 8

Reads reports/contact_sheets/<label>.txt (written by audit_data) and appends the matching lines to
data/exclude_plantdoc.txt. Then rebuild with:  prepare_data ... --exclude data/exclude_plantdoc.txt
Numbers refer to the sheet you looked at, so do not rebuild data/prepared_vX between viewing and listing.
"""
import argparse
from pathlib import Path


def parse_numbers(tokens):
    nums = []
    for t in tokens:
        a, _, b = t.partition("-")
        nums.extend(range(int(a), int(b or a) + 1))
    return nums


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("label")
    ap.add_argument("numbers", nargs="+", help="thumbnail numbers, ranges like 12-15 allowed")
    ap.add_argument("--sheets", type=Path, default=Path("reports/contact_sheets"))
    ap.add_argument("--out", type=Path, default=Path("data/exclude_plantdoc.txt"))
    a = ap.parse_args()

    table = {}
    for line in (a.sheets / f"{a.label}.txt").read_text(encoding="utf-8").splitlines():
        n, key, split = line.split("\t")
        table[int(n)] = (key, split)
    existing = set(a.out.read_text(encoding="utf-8").splitlines()) if a.out.exists() else set()
    added = []
    for n in parse_numbers(a.numbers):
        if n not in table:
            raise SystemExit(f"No thumbnail #{n} for {a.label} (valid: 1-{len(table)}).")
        key, split = table[n]
        if key not in existing:
            added.append(key)
            existing.add(key)
            print(f"  #{n:3d} {key}  ({split})")
    a.out.parent.mkdir(parents=True, exist_ok=True)
    with a.out.open("a", encoding="utf-8") as f:
        f.writelines(k + "\n" for k in added)
    print(f"{len(added)} added to {a.out}")


if __name__ == "__main__":
    main()
