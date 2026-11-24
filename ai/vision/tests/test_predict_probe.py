import numpy as np

from ai.vision.predict_probe import apply_known_crop, decide_probe, probs_from_features

LABELS = ["pepper__healthy", "tomato__early_blight", "tomato__late_blight"]


def test_probs_from_features_sum_to_one():
    p = probs_from_features(np.array([1.0, 2.0]), np.zeros(2), np.ones(2), np.eye(2, 3), np.zeros(3))
    assert len(p) == 3 and abs(sum(p) - 1.0) < 1e-9


def test_known_crop_masks_other_crops_without_flagging_mismatch_when_unsure():
    used, mismatch = apply_known_crop([0.40, 0.35, 0.25], LABELS, "tomate")
    assert used[0] == 0.0 and abs(sum(used) - 1.0) < 1e-9 and mismatch is False


def test_clear_other_crop_goes_to_expert():
    r = decide_probe([0.92, 0.05, 0.03], LABELS, "en", farm_crop="tomato")
    assert r["needs_expert"] and "crop_mismatch" in r["reasons"]
    assert "expert" in r["message"].lower()


def test_confident_same_crop_prediction_is_answered_with_expert_wording():
    r = decide_probe([0.05, 0.85, 0.10], LABELS, "en", farm_crop="tomato")
    assert r["label"] == "tomato__early_blight" and r["needs_expert"] is False
    assert "Check with an expert" in r["message"]


def test_unsupported_crop_is_handled_before_the_model_runs():
    from ai.vision.predict import check_supported
    assert check_supported("olive", "fr")["needs_expert"] is True
