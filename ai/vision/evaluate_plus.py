"""Compare ways of using the SAME trained models on the real-photo test set, without retraining.

    python -m ai.vision.evaluate_plus --models models\\v1_baseline models\\v3_boost ^
        --test-dir data\\prepared_v3\\test_plantdoc --name plus

Rows reported (each one is a legitimate way to run the product):
  - single model / average of all given models (ensemble)
  - with or without test-time augmentation (original + horizontal flip)
  - with or without KNOWN CROP: the farm profile already says which crop the farmer grows,
    so disease classes of other crops can be ruled out (a tomato farm cannot get a pepper label).

Honesty rules: every row is printed, none is hidden. Pick the configuration for a REASON
(known crop is justified by the product design) and not just because it has the highest
number on 96 images: the more rows you compare, the more a lucky row looks like a gain.
Confirm on your own photos before claiming an improvement.
"""
import argparse
import json
from math import sqrt
from pathlib import Path
from typing import Dict, List, Optional, Sequence

from .metrics import summarize

IMAGE_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


# ------------------------------------------------------------- pure logic (tested)

def wilson(k: int, n: int, z: float = 1.96):
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = p + z * z / (2 * n)
    m = z * sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return ((c - m) / d, (c + m) / d)


def align(probs: Sequence[float], model_labels: Sequence[str], union: Sequence[str]) -> List[float]:
    """Re-order one model's probabilities into the union label order (missing label = 0)."""
    by_name = dict(zip(model_labels, probs))
    return [float(by_name.get(l, 0.0)) for l in union]


def average(prob_lists: Sequence[Sequence[float]]) -> List[float]:
    return [sum(col) / len(prob_lists) for col in zip(*prob_lists)]


def mask_to_crop(probs: Sequence[float], labels: Sequence[str], crop: str) -> List[float]:
    """Keep only labels of the known crop and renormalise. Falls back to the input if none match."""
    kept = [p if l.split("__")[0] == crop else 0.0 for p, l in zip(probs, labels)]
    total = sum(kept)
    return [p / total for p in kept] if total > 0 else list(probs)


def evaluate_rows(prob_table: Dict[str, List[List[float]]], labels: Sequence[str], y_true: Sequence[str],
                  masks: Sequence[bool] = (False, True)) -> List[dict]:
    """prob_table: config name -> per-image probabilities (union label order)."""
    rows = []
    for name, per_image in prob_table.items():
        for use_mask in masks:
            preds, confs = [], []
            for probs, truth in zip(per_image, y_true):
                p = mask_to_crop(probs, labels, truth.split("__")[0]) if use_mask else list(probs)
                best = max(range(len(labels)), key=lambda i: p[i])
                preds.append(labels[best])
                confs.append(p[best])
            s = summarize(list(y_true), preds, confs, list(labels))
            n = len(y_true)
            k = sum(t == p for t, p in zip(y_true, preds))
            crop_ok = sum(t.split("__")[0] == p.split("__")[0] for t, p in zip(y_true, preds))
            lo, hi = wilson(k, n)
            sel = {r["threshold"]: r for r in s["accuracy_vs_confidence"]}
            rows.append({
                "config": name + (" + known crop" if use_mask else ""),
                "n": n, "correct": k, "accuracy": k / n, "ci_low": lo, "ci_high": hi,
                "macro_f1": s["macro_f1"], "crop_accuracy": crop_ok / n,
                "at_0.5": {"coverage": sel[0.5]["coverage"], "accuracy": sel[0.5]["accuracy"]},
                "at_0.7": {"coverage": sel[0.7]["coverage"], "accuracy": sel[0.7]["accuracy"]},
            })
    return rows


def render_rows(rows: List[dict], title: str) -> str:
    out = [f"# {title}", "",
           "Every configuration is listed. Do not pick the highest row on its own: with this few images, a lucky row looks like a gain.",
           "", "| Configuration | Images | Accuracy | 95 % interval | Macro-F1 | Crop correct | Answers at 0.5 (accuracy) |",
           "|---|---|---|---|---|---|---|"]
    for r in rows:
        a5 = r["at_0.5"]
        acc5 = "-" if a5["accuracy"] is None else f"{a5['accuracy']:.0%}"
        out.append(f"| {r['config']} | {r['n']} | {r['accuracy']:.1%} ({r['correct']}) | "
                   f"{r['ci_low']:.1%} to {r['ci_high']:.1%} | {r['macro_f1']:.3f} | {r['crop_accuracy']:.1%} | "
                   f"{a5['coverage']:.0%} ({acc5}) |")
    out += ["", "\"known crop\" assumes the photo is of the crop in the farm profile (a farmer photographing another plant breaks this).", ""]
    return "\n".join(out)


# ------------------------------------------------------------- torch part (not unit tested)

def scan_test_dir(test_dir: Path):
    samples = []
    for folder in sorted(p for p in Path(test_dir).iterdir() if p.is_dir()):
        for img in sorted(folder.iterdir()):
            if img.suffix.lower() in IMAGE_EXT:
                samples.append((img, folder.name))
    return samples


def model_probs(model_dir: Path, samples, tta: bool, batch: int = 16):
    import torch
    from PIL import Image

    from .model import build_model, eval_transform

    labels = json.loads((model_dir / "labels.json").read_text(encoding="utf-8"))
    model = build_model(len(labels), pretrained=False)
    model.load_state_dict(torch.load(model_dir / "model.pt", map_location="cpu"))
    model.eval()
    tf = eval_transform()
    out = []
    with torch.no_grad():
        for i in range(0, len(samples), batch):
            x = torch.stack([tf(Image.open(p).convert("RGB")) for p, _ in samples[i:i + batch]])
            probs = torch.softmax(model(x), dim=1)
            if tta:
                probs = (probs + torch.softmax(model(torch.flip(x, dims=[3])), dim=1)) / 2
            out += probs.tolist()
    return labels, out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--models", type=Path, nargs="+", required=True)
    ap.add_argument("--test-dir", type=Path, required=True)
    ap.add_argument("--name", default="plus")
    ap.add_argument("--reports", type=Path, default=Path("reports"))
    a = ap.parse_args()

    samples = scan_test_dir(a.test_dir)
    if not samples:
        raise SystemExit(f"No test images in {a.test_dir}")
    y_true = [label for _, label in samples]

    per_model, all_labels = {}, set()
    for m in a.models:
        for tta in (False, True):
            labels, probs = model_probs(m, samples, tta)
            per_model[(m.name, tta)] = (labels, probs)
            all_labels |= set(labels)
    union = sorted(all_labels)

    table: Dict[str, List[List[float]]] = {}
    for tta in (False, True):
        suffix = " + flip-TTA" if tta else ""
        aligned = {}
        for m in a.models:
            labels, probs = per_model[(m.name, tta)]
            aligned[m.name] = [align(p, labels, union) for p in probs]
            table[m.name + suffix] = aligned[m.name]
        if len(a.models) > 1:
            table["ensemble(" + "+".join(m.name for m in a.models) + ")" + suffix] = [
                average(group) for group in zip(*aligned.values())]

    rows = evaluate_rows(table, union, y_true)
    a.reports.mkdir(parents=True, exist_ok=True)
    (a.reports / f"eval_{a.name}.json").write_text(json.dumps(rows, indent=2), encoding="utf-8")
    md = render_rows(rows, f"Configuration comparison on {a.test_dir.name} ({len(y_true)} images)")
    (a.reports / f"eval_{a.name}.md").write_text(md, encoding="utf-8")
    print(md)
    print(f"Saved {a.reports / f'eval_{a.name}.md'}")


if __name__ == "__main__":
    main()
