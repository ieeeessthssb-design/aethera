"""Evaluate a trained model on a REAL-photo test set and write a report.

    python -m ai.vision.evaluate --model models/v1 --test-dir data/prepared/test_plantdoc --name plantdoc
    python -m ai.vision.evaluate --model models/v1 --test-dir data/prepared/test_own     --name own_photos

Report the real-photo numbers (PlantDoc test, your own photos). Do NOT quote validation
accuracy or PlantVillage accuracy as the project's accuracy: those images are easier.
"""
import argparse
import json
from pathlib import Path

from .metrics import render_markdown, summarize


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", type=Path, default=Path("models/v1"))
    ap.add_argument("--test-dir", type=Path, required=True)
    ap.add_argument("--name", default="real_photos")
    ap.add_argument("--reports", type=Path, default=Path("reports"))
    ap.add_argument("--batch", type=int, default=32)
    a = ap.parse_args()

    import torch
    from torch.utils.data import DataLoader
    from .model import build_model, eval_transform, make_dataset

    labels = json.loads((a.model / "labels.json").read_text(encoding="utf-8"))
    class_to_idx = {l: i for i, l in enumerate(labels)}
    ds = make_dataset(a.test_dir, class_to_idx, eval_transform())
    if len(ds) == 0:
        raise SystemExit(f"No test images found in {a.test_dir}")

    model = build_model(len(labels), pretrained=False)
    model.load_state_dict(torch.load(a.model / "model.pt", map_location="cpu"))
    model.eval()

    y_true, y_pred, conf = [], [], []
    with torch.no_grad():
        for x, y in DataLoader(ds, batch_size=a.batch, shuffle=False):
            probs = torch.softmax(model(x), dim=1)
            top_p, top_i = probs.max(1)
            y_true += [labels[i] for i in y.tolist()]
            y_pred += [labels[i] for i in top_i.tolist()]
            conf += top_p.tolist()

    summary = summarize(y_true, y_pred, conf, labels)
    a.reports.mkdir(parents=True, exist_ok=True)
    (a.reports / f"eval_{a.name}.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    md = render_markdown(summary, f"Photo diagnosis evaluation: {a.name} ({a.model})")
    (a.reports / f"eval_{a.name}.md").write_text(md, encoding="utf-8")
    print(f"{summary['n_images']} images | accuracy {summary['accuracy']:.1%} | macro-F1 {summary['macro_f1']:.3f}")
    print(f"Report: {a.reports / f'eval_{a.name}.md'}")


if __name__ == "__main__":
    main()
