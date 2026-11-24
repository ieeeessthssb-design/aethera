"""Tests for the parts of ai/vision that need no torch (mapping, data split, decisions, metrics).
Run from the repo root:  python -m pytest ai/vision/tests -q
"""
from pathlib import Path

from ai.vision import classes
from ai.vision.metrics import render_markdown, summarize
from ai.vision.predict import check_supported, decide
from ai.vision.prepare_data import prepare


def _img(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(content.encode())


def test_both_datasets_map_to_the_same_label_space():
    assert set(classes.PD_MAP.values()) <= set(classes.PV_MAP.values())
    assert all(l.split("__")[0] in classes.SUPPORTED_CROPS for l in classes.ALL_LABELS)
    for label in classes.ALL_LABELS:
        crop, cond = classes.split_label(label)
        assert cond in classes.CONDITION_NAMES and crop in classes.CROP_NAMES


def test_unknown_crops_are_ignored_and_crop_aliases_work():
    assert classes.label_from_folder("plantdoc", "Apple leaf") is None
    assert classes.label_from_folder("plantvillage", "Corn_(maize)___healthy") is None
    assert classes.supported_crop("Tomates") == "tomato" and classes.supported_crop("طماطم") == "tomato"
    assert classes.supported_crop("olive") is None


def test_prepare_splits_and_never_leaks_test_images(tmp_path):
    pv, pd, out = tmp_path / "pv", tmp_path / "pd", tmp_path / "out"
    for i in range(10):
        _img(pv / "Tomato___Late_blight" / f"a{i}.jpg", f"pv{i}")
        _img(pd / "train" / "Tomato leaf late blight" / f"b{i}.jpg", f"pdt{i}")
    _img(pd / "train" / "Tomato leaf late blight" / "dup.jpg", "SAME")      # also in test: must be dropped
    _img(pd / "test" / "Tomato leaf late blight" / "t0.jpg", "SAME")
    _img(pd / "test" / "Tomato leaf late blight" / "t1.jpg", "other")
    _img(pd / "train" / "Apple leaf" / "x.jpg", "apple")                  # unused crop

    m = prepare(pv, pd, out, pv_cap=4, val_frac=0.2, seed=1)
    label = "tomato__late_blight"
    assert m["dropped_duplicates"] == 1
    assert m["test_plantdoc"][label] == 2
    assert m["train"][label]["plantvillage"] == 4
    assert m["val"][label] == 2 and m["train"][label]["plantdoc"] == 8
    assert not (out / "train" / "apple").exists()
    # test images are in the test folder only
    test_names = {p.name for p in (out / "test_plantdoc" / label).iterdir()}
    for split in ("train", "val"):
        assert not test_names & {p.name for p in (out / split / label).iterdir()}
    assert "tomato__late_blight" in [p.name for p in (out / "train").iterdir()]


LABELS = ["tomato__healthy", "tomato__late_blight", "potato__late_blight"]


def test_decide_confident_prediction_still_says_check_with_an_expert():
    r = decide([0.05, 0.9, 0.05], LABELS, "en")
    assert r["label"] == "tomato__late_blight" and r["needs_expert"] is False
    assert "late blight" in r["message"] and "Check with an expert" in r["message"]


def test_decide_low_confidence_or_ambiguous_goes_to_expert():
    low = decide([0.4, 0.35, 0.25], LABELS, "en")
    assert low["needs_expert"] and "low_confidence" in low["reasons"]
    ambiguous = decide([0.02, 0.50, 0.48], LABELS, "en", threshold=0.4)
    assert ambiguous["needs_expert"] and "ambiguous_top2" in ambiguous["reasons"]
    assert "expert" in low["message"].lower()


def test_decide_flags_crop_mismatch_and_never_adds_treatment_advice():
    r = decide([0.05, 0.05, 0.9], LABELS, "fr", farm_crop="tomate")
    assert r["needs_expert"] and "crop_mismatch" in r["reasons"]
    text = decide([0.05, 0.9, 0.05], LABELS, "ar")["message"]
    assert "خبير" in text
    for word in ("spray", "pulvéris", "dose", "mg", "رش"):
        assert word not in decide([0.05, 0.9, 0.05], LABELS, "en")["message"].lower()


def test_unsupported_crop_short_circuits():
    r = check_supported("olive", "en")
    assert r and r["supported"] is False and r["needs_expert"]
    assert check_supported("tomato") is None and check_supported(None) is None


def test_summarize_reports_accuracy_per_class_and_coverage():
    y_true = ["a", "a", "b", "b"]
    y_pred = ["a", "b", "b", "b"]
    conf = [0.9, 0.55, 0.8, 0.95]
    s = summarize(y_true, y_pred, conf, ["a", "b", "c"])
    assert s["accuracy"] == 0.75 and s["n_images"] == 4
    assert s["per_class"]["b"]["recall"] == 1.0 and s["per_class"]["b"]["precision"] == round(2 / 3, 4)
    assert s["labels_without_test_images"] == ["c"]
    row = {r["threshold"]: r for r in s["accuracy_vs_confidence"]}
    assert row[0.0]["coverage"] == 1.0 and row[0.7]["coverage"] == 0.75 and row[0.7]["accuracy"] == 1.0
    assert "Accuracy" in render_markdown(s, "t")
