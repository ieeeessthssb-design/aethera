from pathlib import Path

import numpy as np

from ai.vision.train_probe import accuracy, fit_softmax, limit_pv, sample_weights, source_of


def test_fit_softmax_learns_separable_data():
    rng = np.random.default_rng(0)
    X = np.vstack([rng.normal(-2, 1, (60, 5)), rng.normal(2, 1, (60, 5))])
    y = np.array([0] * 60 + [1] * 60)
    W, b = fit_softmax(X, y, 2, np.ones(120), l2=1e-3)
    assert accuracy(X, y, W, b) > 0.95


def test_sample_weights_balance_classes_and_boost_field_photos():
    sources = ["pd", "pv", "pv", "pv", "pv", "pv"]
    y = [0, 0, 0, 1, 1, 1]
    w = sample_weights(sources, y, 2, pd_weight=4.0)
    assert abs(w[y.index(0):3].sum() - w[3:].sum()) < 1e-9           # classes carry equal total weight
    assert w[0] > w[1] > 0                                           # field photo counts more than a lab photo
    assert abs(w.mean() - 1.0) < 1e-9


def test_limit_pv_keeps_all_field_photos_and_caps_lab_photos():
    s = [(Path(f"pv_{i}.jpg"), "a") for i in range(10)] + [(Path(f"pd_{i}.jpg"), "a") for i in range(3)]
    kept = limit_pv(s, 4, "pv")
    assert sum(1 for p, _ in kept if source_of(p, "pv") == "pv") == 4
    assert sum(1 for p, _ in kept if source_of(p, "pv") == "pd") == 3
