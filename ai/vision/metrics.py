"""Evaluation maths and report text. Pure Python (no torch) so it can be unit tested anywhere."""
from collections import Counter, defaultdict
from typing import Dict, List, Sequence

THRESHOLDS = (0.0, 0.5, 0.6, 0.7, 0.8, 0.9)


def summarize(y_true: Sequence[str], y_pred: Sequence[str], conf: Sequence[float],
              model_labels: Sequence[str]) -> dict:
    """Accuracy, per-class precision/recall/F1, confusion matrix and accuracy-vs-coverage table."""
    assert len(y_true) == len(y_pred) == len(conf)
    n = len(y_true)
    correct = sum(t == p for t, p in zip(y_true, y_pred))
    test_labels = sorted(set(y_true))

    confusion: Dict[str, Dict[str, int]] = {t: defaultdict(int) for t in test_labels}
    for t, p in zip(y_true, y_pred):
        confusion[t][p] += 1
    predicted = Counter(y_pred)
    support = Counter(y_true)

    per_class = {}
    for label in test_labels:
        tp = confusion[label].get(label, 0)
        precision = tp / predicted[label] if predicted[label] else 0.0
        recall = tp / support[label]
        f1 = 2 * precision * recall / (precision + recall) if precision + recall else 0.0
        per_class[label] = {"precision": round(precision, 4), "recall": round(recall, 4),
                            "f1": round(f1, 4), "support": support[label]}

    table = []
    for th in THRESHOLDS:
        kept = [(t, p) for t, p, c in zip(y_true, y_pred, conf) if c >= th]
        table.append({"threshold": th, "coverage": round(len(kept) / n, 4) if n else 0.0,
                      "accuracy": round(sum(t == p for t, p in kept) / len(kept), 4) if kept else None})

    return {
        "n_images": n,
        "accuracy": round(correct / n, 4) if n else 0.0,
        "macro_f1": round(sum(c["f1"] for c in per_class.values()) / len(per_class), 4) if per_class else 0.0,
        "per_class": per_class,
        "confusion": {t: dict(row) for t, row in confusion.items()},
        "accuracy_vs_confidence": table,
        "labels_without_test_images": sorted(set(model_labels) - set(test_labels)),
    }


def render_markdown(summary: dict, title: str) -> str:
    lines = [f"# {title}", "",
             f"Images: **{summary['n_images']}**  |  Accuracy: **{summary['accuracy']:.1%}**  |  Macro-F1: **{summary['macro_f1']:.3f}**",
             "", "## Per class", "", "| Class | Precision | Recall | F1 | Images |", "|---|---|---|---|---|"]
    for label, m in summary["per_class"].items():
        lines.append(f"| {label} | {m['precision']:.2f} | {m['recall']:.2f} | {m['f1']:.2f} | {m['support']} |")
    lines += ["", "## Accuracy when the model is allowed to say \"ask an expert\"", "",
              "Photos below the confidence threshold would be sent to an expert instead of getting an answer.", "",
              "| Threshold | Answered (coverage) | Accuracy on answered |", "|---|---|---|"]
    for row in summary["accuracy_vs_confidence"]:
        acc = "-" if row["accuracy"] is None else f"{row['accuracy']:.1%}"
        lines.append(f"| {row['threshold']:.1f} | {row['coverage']:.1%} | {acc} |")
    if summary["labels_without_test_images"]:
        lines += ["", "## Not evaluated (no test images in this set)", ""]
        lines += [f"- {l}" for l in summary["labels_without_test_images"]]
    lines += ["", "## Confusion (true class: predicted class = count)", ""]
    for true, row in summary["confusion"].items():
        cells = ", ".join(f"{p} = {c}" for p, c in sorted(row.items(), key=lambda kv: -kv[1]))
        lines.append(f"- **{true}**: {cells}")
    lines += ["", "_Accuracy on this set is not a promise for farmers' phones. Report which set it was measured on._", ""]
    return "\n".join(lines)
