"""Audit the prepared dataset BEFORE retraining (pure Pillow, no torch).

    python -m ai.vision.audit_data --prepared data/prepared
    python -m ai.vision.audit_data --prepared data/prepared --sheet-labels tomato__healthy tomato__yellow_leaf_curl_virus pepper__bacterial_spot

Checks
  1. Files on disk vs manifest.json (stale files left by an earlier run of prepare_data).
  2. Source mix per class in train (pv_ = PlantVillage, pd_ = PlantDoc).
  3. Exact (md5) duplicates: across splits (leakage) and across labels (conflicting labels).
  4. Near duplicates (64-bit difference hash): val/test images that look like a train image.
  5. Contact sheets: one JPEG per label, PlantVillage row(s) on top, PlantDoc row(s) below,
     so you can LOOK at the three assumed mappings and at the lab-vs-field gap.

Writes reports/audit_data.json and reports/contact_sheets/<label>.jpg
"""
import argparse
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List

from PIL import Image, ImageDraw

IMAGE_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
SPLITS = ("train", "val", "test_plantdoc", "test_own")
ASSUMED = ("tomato__healthy", "tomato__yellow_leaf_curl_virus", "pepper__bacterial_spot")


def iter_images(prepared: Path):
    """Yield (split, label, path) for every image in the prepared folders."""
    for split in SPLITS:
        root = prepared / split
        if not root.exists():
            continue
        for lab in sorted(p for p in root.iterdir() if p.is_dir()):
            for img in sorted(lab.iterdir()):
                if img.suffix.lower() in IMAGE_EXT:
                    yield split, lab.name, img


def source_of(path: Path) -> str:
    return {"pv": "plantvillage", "pd": "plantdoc", "own": "own"}.get(path.name.split("_", 1)[0], "unknown")


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def dhash(path: Path, size: int = 8) -> int:
    """64-bit difference hash: robust to resizing / recompression, not to crops."""
    with Image.open(path) as im:
        g = im.convert("L").resize((size + 1, size), Image.LANCZOS)
    px = g.tobytes()  # mode "L": one byte per pixel
    bits = 0
    for row in range(size):
        for col in range(size):
            bits = (bits << 1) | (px[row * (size + 1) + col] > px[row * (size + 1) + col + 1])
    return bits


def check_manifest(prepared: Path, items) -> dict:
    mf_path = prepared / "manifest.json"
    if not mf_path.exists():
        return {"manifest": "missing"}
    mf = json.loads(mf_path.read_text(encoding="utf-8"))
    disk: Dict[str, Counter] = defaultdict(Counter)
    for split, label, _ in items:
        disk[split][label] += 1
    expected: Dict[str, Dict[str, int]] = {
        "train": {l: sum(v.values()) for l, v in mf.get("train", {}).items()},
        "val": mf.get("val", {}), "test_plantdoc": mf.get("test_plantdoc", {}), "test_own": mf.get("test_own", {}),
    }
    mismatches = []
    for split in SPLITS:
        for label in sorted(set(disk[split]) | set(expected[split])):
            d, e = disk[split].get(label, 0), expected[split].get(label, 0)
            if d != e:
                mismatches.append({"split": split, "label": label, "on_disk": d, "manifest": e})
    return {"manifest": "ok" if not mismatches else "MISMATCH (stale files? re-run prepare_data on an empty folder)",
            "mismatches": mismatches}


def find_duplicates(items) -> dict:
    by_hash: Dict[str, List[tuple]] = defaultdict(list)
    for split, label, p in items:
        by_hash[md5(p)].append((split, label, str(p)))
    cross_split, cross_label = [], []
    for h, rows in by_hash.items():
        if len(rows) < 2:
            continue
        if len({r[0] for r in rows}) > 1:
            cross_split.append(rows)
        if len({r[1] for r in rows}) > 1:
            cross_label.append(rows)
    return {"exact_cross_split": cross_split, "exact_cross_label": cross_label}


def find_near_duplicates(items, max_dist: int = 5) -> list:
    """val/test images whose hash is within max_dist bits of a train image (any label)."""
    train = [(label, p, dhash(p)) for s, label, p in items if s == "train"]
    out = []
    for split, label, p in items:
        if split == "train":
            continue
        h = dhash(p)
        best = min(((( h ^ th).bit_count(), tl, tp) for tl, tp, th in train), default=None, key=lambda t: t[0])
        if best and best[0] <= max_dist:
            out.append({"split": split, "label": label, "image": str(p), "distance": best[0],
                        "train_label": best[1], "train_image": str(best[2]),
                        "same_label": label == best[1]})
    return out


def contact_sheet(prepared: Path, label: str, out_dir: Path, per_row: int = 8, rows_per_source: int = 2, thumb: int = 150, pd_rows: int = None) -> Path:
    """Also numbers every thumbnail and writes <label>.txt (number, label/file, split) so that a
    bad image can be excluded by number (see make_exclusions)."""
    groups = {"plantvillage": [], "plantdoc": []}
    split_of = {}
    for split, lab, p in iter_images(prepared):
        if lab == label and source_of(p) in groups:
            groups[source_of(p)].append(p)
            split_of[p] = split
    n = per_row * rows_per_source
    pad, head = 4, 22
    height = 0
    blocks = []
    for name, files in groups.items():
        files = files[: per_row * (pd_rows if (pd_rows and name == "plantdoc") else rows_per_source)]
        rows = max(1, -(-len(files) // per_row))
        blocks.append((name, files, rows))
        height += head + rows * (thumb + pad)
    sheet = Image.new("RGB", (per_row * (thumb + pad) + pad, height + 24), "white")
    d = ImageDraw.Draw(sheet)
    d.text((pad, 4), f"{label}", fill="black")
    y = 24
    numbered: List[Path] = []
    for name, files, rows in blocks:
        total = sum(1 for _s, lab, p in iter_images(prepared) if lab == label and source_of(p) == name)
        d.text((pad, y + 4), f"{name}  (showing {len(files)} of {total})", fill=(180, 0, 0))
        y += head
        for i, f in enumerate(files):
            with Image.open(f) as im:
                im = im.convert("RGB")
                im.thumbnail((thumb, thumb))
                x0, y0 = pad + (i % per_row) * (thumb + pad), y + (i // per_row) * (thumb + pad)
                sheet.paste(im, (x0, y0))
            if name == "plantdoc":
                numbered.append(f)
                tag = str(len(numbered))
                d.rectangle([x0, y0, x0 + 7 * len(tag) + 6, y0 + 14], fill="black")
                d.text((x0 + 3, y0 + 1), tag, fill="white")
        y += rows * (thumb + pad)
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{label}.jpg"
    sheet.save(path, quality=88)
    lines = [f"{n}\t{label}/{p.name}\t{split_of[p]}" for n, p in enumerate(numbered, 1)]
    (out_dir / f"{label}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
    return path


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--prepared", type=Path, default=Path("data/prepared"))
    ap.add_argument("--reports", type=Path, default=Path("reports"))
    ap.add_argument("--sheet-labels", nargs="*", default=list(ASSUMED), help="labels to render as contact sheets")
    ap.add_argument("--pd-rows", type=int, default=None, help="rows of 8 PlantDoc thumbnails per sheet (default 2; use 9 to see ~72)")
    ap.add_argument("--near-dist", type=int, default=5, help="max hash distance (bits of 64) for near duplicates")
    a = ap.parse_args()

    items = list(iter_images(a.prepared))
    print(f"{len(items)} images found under {a.prepared}")
    report = {"manifest_check": check_manifest(a.prepared, items)}
    print(f"[1] manifest vs disk: {report['manifest_check']['manifest']}")
    for m in report["manifest_check"].get("mismatches", [])[:10]:
        print(f"      {m}")

    mix: Dict[str, Counter] = defaultdict(Counter)
    for s, label, p in items:
        if s == "train":
            mix[label][source_of(p)] += 1
    report["train_source_mix"] = {l: dict(c) for l, c in sorted(mix.items())}
    print("[2] train source mix (label: plantvillage / plantdoc)")
    for l, c in sorted(mix.items()):
        print(f"      {l:36s} {c['plantvillage']:4d} / {c['plantdoc']:3d}")

    dups = find_duplicates(items)
    report.update(dups)
    print(f"[3] exact duplicates across splits: {len(dups['exact_cross_split'])} | across labels: {len(dups['exact_cross_label'])}")

    near = find_near_duplicates(items, a.near_dist)
    report["near_duplicates_val_test_vs_train"] = near
    same = sum(n["same_label"] for n in near)
    print(f"[4] val/test images with a near-duplicate in train: {len(near)} ({same} with the same label, "
          f"{len(near) - same} with a DIFFERENT label = possible label noise)")

    sheets = []
    for label in a.sheet_labels:
        sheets.append(str(contact_sheet(a.prepared, label, a.reports / "contact_sheets", pd_rows=a.pd_rows)))
    report["contact_sheets"] = sheets
    print("[5] contact sheets:", *sheets, sep="\n      ")

    a.reports.mkdir(parents=True, exist_ok=True)
    (a.reports / "audit_data.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Full report: {a.reports / 'audit_data.json'}")


if __name__ == "__main__":
    main()
