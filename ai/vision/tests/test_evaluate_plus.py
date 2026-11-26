from ai.vision.evaluate_plus import align, average, evaluate_rows, mask_to_crop, render_rows, wilson

LABELS = ["pepper__healthy", "tomato__early_blight", "tomato__late_blight"]


def test_wilson_matches_known_values():
    lo, hi = wilson(42, 96)
    assert round(lo, 3) == 0.343 and round(hi, 3) == 0.537
    assert wilson(0, 0) == (0.0, 0.0)


def test_mask_removes_other_crops_and_renormalises():
    p = mask_to_crop([0.6, 0.3, 0.1], LABELS, "tomato")
    assert p[0] == 0.0 and abs(sum(p) - 1.0) < 1e-9 and p[1] > p[2]
    assert mask_to_crop([0.6, 0.3, 0.1], LABELS, "olive") == [0.6, 0.3, 0.1]   # unknown crop: unchanged


def test_align_and_average():
    assert align([0.7, 0.3], ["b", "a"], ["a", "b", "c"]) == [0.3, 0.7, 0.0]
    assert average([[1.0, 0.0], [0.0, 1.0]]) == [0.5, 0.5]


def test_known_crop_fixes_cross_crop_error_but_not_within_crop_error():
    y_true = ["tomato__early_blight", "tomato__late_blight"]
    probs = [[0.50, 0.30, 0.20],    # predicts pepper (wrong crop) -> mask fixes it
             [0.05, 0.60, 0.35]]    # predicts early blight (same crop, wrong) -> mask cannot fix
    rows = {r["config"]: r for r in evaluate_rows({"m": probs}, LABELS, y_true)}
    assert rows["m"]["correct"] == 0 and rows["m"]["crop_accuracy"] == 0.5
    assert rows["m + known crop"]["correct"] == 1 and rows["m + known crop"]["crop_accuracy"] == 1.0
    assert "m + known crop" in render_rows(list(rows.values()), "t")
