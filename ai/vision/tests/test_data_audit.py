"""Tests for the data-preparation fixes and the audit script (Pillow only, no torch)."""
import random
from pathlib import Path

from PIL import Image

from ai.vision.audit_data import check_manifest, contact_sheet, find_duplicates, find_near_duplicates, iter_images
from ai.vision.prepare_data import prepare


def _img(path: Path, seed: int, size=(64, 64), scale=1):
    path.parent.mkdir(parents=True, exist_ok=True)
    rng = random.Random(seed)
    small = Image.new("RGB", (16, 16))
    small.putdata([(rng.randrange(256), rng.randrange(256), rng.randrange(256)) for _ in range(256)])
    small.resize((size[0] * scale, size[1] * scale)).save(path, "PNG")


def _raw(tmp_path):
    pv, pd = tmp_path / "pv", tmp_path / "pd"
    for i in range(6):
        _img(pv / "Tomato___Late_blight" / f"a{i}.png", 100 + i)
        _img(pd / "train" / "Tomato leaf late blight" / f"b{i}.png", 200 + i)
    _img(pd / "test" / "Tomato leaf late blight" / "t0.png", 300)
    return pv, pd


def test_rerun_does_not_leave_stale_files(tmp_path):
    pv, pd = _raw(tmp_path)
    out = tmp_path / "out"
    prepare(pv, pd, out, pv_cap=3, seed=1)
    stale = out / "train" / "tomato__old_label"
    stale.mkdir(parents=True)
    (stale / "pv_old.png").write_bytes(b"x")
    prepare(pv, pd, out, pv_cap=3, seed=2)          # different seed: different train/val split
    assert not stale.exists()
    names = lambda split: {p.name for _s, _l, p in iter_images(out) if _s == split}
    assert not names("train") & names("val")        # nothing in both splits
    assert check_manifest(out, list(iter_images(out)))["manifest"] == "ok"


def test_internal_duplicates_and_label_conflicts_are_dropped(tmp_path):
    pv, pd = _raw(tmp_path)
    _img(pd / "train" / "Tomato leaf late blight" / "copy.png", 200)          # same bytes as b0
    _img(pd / "train" / "Tomato leaf late blight" / "clash.png", 777)
    _img(pd / "train" / "Tomato Early blight leaf" / "clash.png", 777)        # same bytes, other label
    m = prepare(pv, pd, tmp_path / "out", pv_cap=3, seed=1)
    assert m["dropped_internal_duplicates"] == 1
    assert m["dropped_label_conflicts"] == 2


def test_audit_finds_leaks_near_duplicates_and_makes_sheets(tmp_path):
    out = tmp_path / "prepared"
    _img(out / "train" / "tomato__healthy" / "pd_a.png", 1)
    _img(out / "val" / "tomato__healthy" / "pd_b.png", 1)                      # exact copy of a train image
    _img(out / "train" / "tomato__late_blight" / "pv_c.png", 2)
    _img(out / "test_plantdoc" / "tomato__healthy" / "pd_d.png", 2, scale=2)   # resized copy, other label
    _img(out / "test_plantdoc" / "tomato__healthy" / "pd_e.png", 3)            # unrelated
    items = list(iter_images(out))
    d = find_duplicates(items)
    assert len(d["exact_cross_split"]) == 1
    near = find_near_duplicates(items, max_dist=5)
    flagged = {Path(n["image"]).name: n for n in near}
    assert "pd_d.png" in flagged and flagged["pd_d.png"]["same_label"] is False
    assert "pd_e.png" not in flagged
    sheet = contact_sheet(out, "tomato__healthy", tmp_path / "sheets")
    assert sheet.exists() and Image.open(sheet).size[0] > 100


def test_near_duplicate_groups_across_train_and_test(tmp_path):
    pv, pd, out = tmp_path / "pv", tmp_path / "pd", tmp_path / "out"
    _img(pv / "Tomato___Late_blight" / "p0.png", 900)
    for i in range(6):
        _img(pd / "train" / "Tomato leaf late blight" / f"u{i}.png", 400 + i)         # unique photos
    # conflict: the same photo (one resized) under potato AND tomato late blight
    _img(pd / "train" / "Tomato leaf late blight" / "c1.png", 555)
    _img(pd / "train" / "Potato leaf late blight" / "c2.png", 555, scale=2)
    # same label, one copy in train and one in test -> train copy dropped, test kept
    _img(pd / "train" / "Tomato leaf late blight" / "s1.png", 666)
    _img(pd / "test" / "Tomato leaf late blight" / "s2.png", 666, scale=2)
    # same label twice in train -> one kept
    _img(pd / "train" / "Tomato leaf late blight" / "d1.png", 777)
    _img(pd / "train" / "Tomato leaf late blight" / "d2.png", 777, scale=2)

    m = prepare(pv, pd, out, pv_cap=2, seed=1, near_dist=3)
    assert m["dropped_near_dup_conflicts"] == 2
    assert m["dropped_near_duplicates"] == 2          # s1 and one of d1/d2
    assert m["test_plantdoc"]["tomato__late_blight"] == 1
    items = list(iter_images(out))
    assert find_near_duplicates(items, 3) == [] or all(
        n["same_label"] for n in find_near_duplicates(items, 3) if "pv_" not in Path(n["train_image"]).name)
    assert check_manifest(out, items)["manifest"] == "ok"
    kept_pd = [p.name for s, l, p in items if s in ("train", "val") and p.name.startswith("pd_")]
    assert not any(n in kept_pd for n in ("pd_c1.png", "pd_c2.png", "pd_s1.png"))


def test_numbered_sheet_exclusion_roundtrip(tmp_path, monkeypatch):
    from ai.vision import make_exclusions
    import sys
    pv, pd = _raw(tmp_path)
    out = tmp_path / "out"
    prepare(pv, pd, out, pv_cap=2, seed=1)
    contact_sheet(out, "tomato__late_blight", tmp_path / "sheets", pd_rows=2)
    rows = (tmp_path / "sheets" / "tomato__late_blight.txt").read_text(encoding="utf-8").splitlines()
    assert len(rows) == 7 and rows[0].split("\t")[1].startswith("tomato__late_blight/pd_")

    excl = tmp_path / "excl.txt"
    monkeypatch.setattr(sys, "argv", ["x", "tomato__late_blight", "1-2", "--sheets", str(tmp_path / "sheets"), "--out", str(excl)])
    make_exclusions.main()
    keys = excl.read_text(encoding="utf-8").splitlines()
    assert len(keys) == 2

    from ai.vision.prepare_data import load_exclusions
    m = prepare(pv, pd, tmp_path / "out2", pv_cap=2, seed=1, exclude=load_exclusions(excl))
    assert m["excluded_manual"] == 2
    left = {p.name for s, l, p in iter_images(tmp_path / "out2") if p.name.startswith("pd_")}
    assert not any(k.split("/")[1] in left for k in keys)