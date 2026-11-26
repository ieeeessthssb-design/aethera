"""Build train / val / test folders from the raw PlantVillage and PlantDoc downloads.

    python -m ai.vision.prepare_data --pv-dir data/raw/plantvillage --plantdoc-dir data/raw/plantdoc \
        [--own-dir data/raw/own_photos] --out data/prepared

Layout produced (ImageFolder compatible):
    train/<label>/   PlantVillage (capped per class) + 80 % of PlantDoc train
    val/<label>/     20 % of PlantDoc train (field-like images, used to pick the best epoch)
    test_plantdoc/<label>/   PlantDoc test: real-world photos, NEVER used for training
    test_own/<label>/        your own leaf photos (optional), NEVER used for training

Safety against leaking: PlantDoc train images that are byte-identical to a PlantDoc test
image are dropped from train/val.
Pure Python (no torch).
"""
import argparse
import hashlib
import json
import random
import shutil
from collections import defaultdict
from pathlib import Path
from typing import Dict, List

from .classes import PD_MAP, PV_MAP, label_from_folder

IMAGE_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def list_images(folder: Path) -> List[Path]:
    return sorted(p for p in folder.iterdir() if p.is_file() and p.suffix.lower() in IMAGE_EXT)


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def _put(src: Path, dst_dir: Path, prefix: str, link: bool) -> None:
    dst_dir.mkdir(parents=True, exist_ok=True)
    dst = dst_dir / f"{prefix}_{src.name}"
    if dst.exists():
        return
    if link:
        dst.symlink_to(src.resolve())
    else:
        shutil.copy2(src, dst)


def collect(root: Path, source: str) -> Dict[str, List[Path]]:
    """label -> images, for every mapped class folder directly under root."""
    out: Dict[str, List[Path]] = defaultdict(list)
    if not root.exists():
        return out
    for folder in sorted(p for p in root.iterdir() if p.is_dir()):
        label = label_from_folder(source, folder.name)
        if label:
            out[label].extend(list_images(folder))
    return out


SPLIT_DIRS = ("train", "val", "test_plantdoc", "test_own")


def load_exclusions(path: Path) -> set:
    """Lines like  tomato__healthy/pd_abc.jpg  (label/prepared-file-name). Blank lines and lines
    starting with # are ignored. The 'pd_' prefix added by prepare_data is optional."""
    keys = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        label, _, name = line.rpartition("/")
        if name.startswith("pd_"):
            name = name[3:]
        keys.add(f"{label}/{name}")
    return keys


def clean_output(out: Path) -> None:
    """Remove the four split folders of a previous run. _put() never overwrites, so without this
    a re-run with another seed or mapping leaves old files behind (an image could then sit in
    train AND val, or under an outdated label)."""
    for name in SPLIT_DIRS:
        shutil.rmtree(out / name, ignore_errors=True)


def near_duplicate_groups(files: List[Path], max_dist: int) -> List[List[Path]]:
    """Group images whose 64-bit difference hashes are within max_dist bits (resized / recompressed
    copies of one photo). Needs Pillow. Unreadable files are left out (treated as unique)."""
    from .audit_data import dhash

    hashes = {}
    for p in files:
        try:
            hashes[p] = dhash(p)
        except Exception:
            continue
    items = list(hashes.items())
    parent = list(range(len(items)))

    def find(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if (items[i][1] ^ items[j][1]).bit_count() <= max_dist:
                parent[find(i)] = find(j)
    groups: Dict[int, List[Path]] = defaultdict(list)
    for i, (p, _) in enumerate(items):
        groups[find(i)].append(p)
    return [g for g in groups.values() if len(g) > 1]


def prepare(pv_dir: Path, plantdoc_dir: Path, out: Path, own_dir: Path = None, pv_cap: int = 400,
            val_frac: float = 0.2, seed: int = 42, link: bool = False, clean: bool = True,
            near_dist: int = None, exclude: set = None) -> dict:
    """near_dist: if set, PlantDoc images (train AND test) within this many hash bits are treated as the
    same photo: a group with conflicting labels is dropped entirely; a same-label group keeps one copy(the test copy if there is one). The CLI default is 3; None (library default) skips this step."""
    rng = random.Random(seed)
    if clean:
        clean_output(out)
    manifest = {"train": defaultdict(lambda: defaultdict(int)), "val": defaultdict(int),
                "test_plantdoc": defaultdict(int), "test_own": defaultdict(int), "dropped_duplicates": 0,
                "dropped_internal_duplicates": 0, "dropped_label_conflicts": 0,
                "dropped_near_duplicates": 0, "dropped_near_dup_conflicts": 0,
                "excluded_manual": 0}

    pd_test = collect(plantdoc_dir / "test", "plantdoc")
    pd_train = collect(plantdoc_dir / "train", "plantdoc")
    if exclude:                                              # hand-picked bad images (diagrams, wrong labels)
        for src in (pd_test, pd_train):
            for lab in list(src):
                kept = [p for p in src[lab] if f"{lab}/{p.name}" not in exclude]
                manifest["excluded_manual"] += len(src[lab]) - len(kept)
                src[lab] = kept
    test_hashes = {md5(p) for files in pd_test.values() for p in files}

    near_drop = set()
    if near_dist is not None:
        label_of = {p: l for src in (pd_test, pd_train) for l, fs in src.items() for p in fs}
        test_files = {p for fs in pd_test.values() for p in fs}
        for g in near_duplicate_groups(sorted(label_of), near_dist):
            if len({label_of[p] for p in g}) > 1:
                near_drop.update(g)
                manifest["dropped_near_dup_conflicts"] += len(g)
            else:
                keep = next((p for p in g if p in test_files), g[0])
                extra = [p for p in g if p != keep]
                near_drop.update(extra)
                manifest["dropped_near_duplicates"] += len(extra)

    for label, files in pd_test.items():
        for p in files:
            if p in near_drop:
                continue
            _put(p, out / "test_plantdoc" / label, "pd", link)
            manifest["test_plantdoc"][label] += 1

    # The same bytes under two different labels = contradictory labels: drop every copy.
    labels_of_hash: Dict[str, set] = defaultdict(set)
    hash_of = {}
    for label, files in pd_train.items():
        for p in files:
            hash_of[p] = md5(p)
            labels_of_hash[hash_of[p]].add(label)
    conflicting = {h for h, labs in labels_of_hash.items() if len(labs) > 1}
    seen_hashes = set()
    for label, files in pd_train.items():
        kept = []
        for p in files:
            h = hash_of[p]
            if p in near_drop:
                continue                                      # counted in dropped_near_*
            if h in test_hashes:
                manifest["dropped_duplicates"] += 1          # identical to a PlantDoc test image
            elif h in conflicting:
                manifest["dropped_label_conflicts"] += 1
            elif h in seen_hashes:
                manifest["dropped_internal_duplicates"] += 1  # a second copy would straddle train/val
            else:
                seen_hashes.add(h)
                kept.append(p)
        files = kept
        rng.shuffle(files)
        n_val = max(1, round(len(files) * val_frac)) if len(files) >= 5 else 0
        for i, p in enumerate(files):
            if i < n_val:
                _put(p, out / "val" / label, "pd", link)
                manifest["val"][label] += 1
            else:
                _put(p, out / "train" / label, "pd", link)
                manifest["train"][label]["plantdoc"] += 1

    for label, files in collect(pv_dir, "plantvillage").items():
        files = list(files)
        rng.shuffle(files)
        for p in files[:pv_cap]:
            _put(p, out / "train" / label, "pv", link)
            manifest["train"][label]["plantvillage"] += 1

    if own_dir and own_dir.exists():
        for folder in sorted(p for p in own_dir.iterdir() if p.is_dir()):
            if folder.name not in set(PV_MAP.values()):
                print(f"  skipped own_photos/{folder.name}: folder name must be a unified label (crop__condition)")
                continue
            for p in list_images(folder):
                _put(p, out / "test_own" / folder.name, "own", link)
                manifest["test_own"][folder.name] += 1

    out.mkdir(parents=True, exist_ok=True)
    result = json.loads(json.dumps(manifest))  # plain dicts
    (out / "manifest.json").write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    return result


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pv-dir", type=Path, required=True, help="PlantVillage raw/color folder")
    ap.add_argument("--plantdoc-dir", type=Path, required=True, help="PlantDoc folder containing train/ and test/")
    ap.add_argument("--own-dir", type=Path, help="your own photos, one folder per unified label")
    ap.add_argument("--out", type=Path, default=Path("data/prepared"))
    ap.add_argument("--pv-cap", type=int, default=400, help="max PlantVillage images per class")
    ap.add_argument("--val-frac", type=float, default=0.2)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--link", action="store_true", help="symlink instead of copy (needs privileges on Windows)")
    ap.add_argument("--no-clean", action="store_true", help="keep files of a previous run (not recommended)")
    ap.add_argument("--exclude", type=Path, default=None, help="text file of PlantDoc images to leave out (see make_exclusions)")
    ap.add_argument("--near-dist", type=int, default=3,
                    help="PlantDoc near-duplicate threshold in hash bits (of 64); -1 disables")
    a = ap.parse_args()
    m = prepare(a.pv_dir, a.plantdoc_dir, a.out, a.own_dir, a.pv_cap, a.val_frac, a.seed, a.link, not a.no_clean,
                None if a.near_dist < 0 else a.near_dist,
                load_exclusions(a.exclude) if a.exclude else None)
    print(f"train classes: {len(m['train'])}  val images: {sum(m['val'].values())}  "
          f"test_plantdoc: {sum(m['test_plantdoc'].values())}  test_own: {sum(m['test_own'].values())}  "
          f"dropped: {m['dropped_duplicates']} test-duplicates, {m['dropped_internal_duplicates']} internal duplicates, "
          f"{m['dropped_label_conflicts']} label conflicts, {m['dropped_near_duplicates']} near-duplicates, "
          f"{m['dropped_near_dup_conflicts']} images in near-duplicate groups with conflicting labels, "
          f"{m['excluded_manual']} excluded by hand")
    print(f"manifest written to {a.out / 'manifest.json'}")


if __name__ == "__main__":
    main()