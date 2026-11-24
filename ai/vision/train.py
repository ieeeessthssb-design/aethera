"""Fine-tune a pretrained MobileNetV3-Small on the prepared PlantVillage + PlantDoc data.

    python -m ai.vision.train --data data/prepared --out models/v1

Phase 1 trains only the new classifier head; phase 2 unfreezes everything with a lower
learning rate. The best epoch is chosen on the PlantDoc-derived validation split (field
photos), not on PlantVillage. PlantDoc test images are never touched here.
Pretrained ImageNet weights are downloaded by torchvision on first run (internet needed once).
"""
import argparse
import json
import platform
import random
import time
from collections import Counter
from pathlib import Path


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, default=Path("data/prepared"))
    ap.add_argument("--out", type=Path, default=Path("models/v1"))
    ap.add_argument("--epochs-head", type=int, default=3)
    ap.add_argument("--epochs-full", type=int, default=8)
    ap.add_argument("--batch", type=int, default=32)
    ap.add_argument("--lr-head", type=float, default=1e-3)
    ap.add_argument("--lr-full", type=float, default=1e-4)
    ap.add_argument("--workers", type=int, default=2)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--pd-boost", type=float, default=4.0,
                    help="draw PlantDoc (field) photos this many times more often than PlantVillage (lab) photos "
                         "of the same class; 1 = old behaviour")
    ap.add_argument("--epoch-size", type=int, default=0,
                    help="images drawn per epoch (0 = size of the train folder). Smaller = faster epochs, so more of them")
    a = ap.parse_args()

    import torch
    from torch.utils.data import DataLoader, WeightedRandomSampler
    from .model import build_model, eval_transform, make_dataset, scan_folder, train_transform

    random.seed(a.seed)
    torch.manual_seed(a.seed)
    device = "cuda" if torch.cuda.is_available() else "cpu"

    labels = sorted(p.name for p in (a.data / "train").iterdir() if p.is_dir())
    class_to_idx = {l: i for i, l in enumerate(labels)}
    train_ds = make_dataset(a.data / "train", class_to_idx, train_transform())
    val_ds = make_dataset(a.data / "val", class_to_idx, eval_transform())
    if len(train_ds) == 0 or len(val_ds) == 0:
        raise SystemExit("Empty train or val set: run ai.vision.prepare_data first.")

    counts = Counter(idx for _, idx in train_ds.samples)
    # Balance classes, and draw field photos (pd_*) more often than lab photos (pv_*): the model is
    # judged on field photos, but PlantVillage lab photos make up most of the training folder.
    weights = [(a.pd_boost if p.name.startswith("pd_") else 1.0) / counts[idx] for p, idx in train_ds.samples]
    n_pd = sum(p.name.startswith("pd_") for p, _ in train_ds.samples)
    print(f"train images: {len(train_ds)} ({n_pd} PlantDoc, {len(train_ds) - n_pd} PlantVillage), pd-boost {a.pd_boost}")
    sampler = WeightedRandomSampler(weights, num_samples=a.epoch_size or len(weights), replacement=True)
    train_dl = DataLoader(train_ds, batch_size=a.batch, sampler=sampler, num_workers=a.workers)
    val_dl = DataLoader(val_ds, batch_size=a.batch, shuffle=False, num_workers=a.workers)

    model = build_model(len(labels), pretrained=True).to(device)
    loss_fn = torch.nn.CrossEntropyLoss(label_smoothing=0.1)

    def run_epoch(loader, optimizer=None):
        model.train(optimizer is not None)
        total, correct, loss_sum = 0, 0, 0.0
        with torch.set_grad_enabled(optimizer is not None):
            for x, y in loader:
                x, y = x.to(device), y.to(device)
                out = model(x)
                loss = loss_fn(out, y)
                if optimizer is not None:
                    optimizer.zero_grad()
                    loss.backward()
                    optimizer.step()
                total += y.size(0)
                correct += (out.argmax(1) == y).sum().item()
                loss_sum += loss.item() * y.size(0)
        return loss_sum / total, correct / total

    a.out.mkdir(parents=True, exist_ok=True)
    (a.out / "labels.json").write_text(json.dumps(labels, indent=2), encoding="utf-8")  # early: survives an interrupted run
    history, best_acc = [], -1.0
    phases = [("head", a.epochs_head, a.lr_head, False), ("full", a.epochs_full, a.lr_full, True)]
    for phase, epochs, lr, unfreeze in phases:
        for p in model.features.parameters():
            p.requires_grad = unfreeze
        optimizer = torch.optim.AdamW([p for p in model.parameters() if p.requires_grad], lr=lr, weight_decay=1e-4)
        for epoch in range(1, epochs + 1):
            t0 = time.time()
            tr_loss, tr_acc = run_epoch(train_dl, optimizer)
            va_loss, va_acc = run_epoch(val_dl)
            history.append({"phase": phase, "epoch": epoch, "train_loss": round(tr_loss, 4),
                            "train_acc": round(tr_acc, 4), "val_loss": round(va_loss, 4), "val_acc": round(va_acc, 4)})
            print(f"[{phase} {epoch}/{epochs}] train acc {tr_acc:.3f} | val acc {va_acc:.3f} | {time.time() - t0:.0f}s")
            if va_acc > best_acc:
                best_acc = va_acc
                torch.save(model.state_dict(), a.out / "model.pt")

    (a.out / "labels.json").write_text(json.dumps(labels, indent=2), encoding="utf-8")
    (a.out / "training.json").write_text(json.dumps({
        "architecture": "mobilenet_v3_small", "pretrained": "torchvision IMAGENET1K_V1",
        "best_val_acc": round(best_acc, 4), "history": history, "args": {k: str(v) for k, v in vars(a).items()},
        "train_images": len(train_ds), "val_images": len(val_ds), "torch": torch.__version__,
        "python": platform.python_version(), "device": device,
    }, indent=2), encoding="utf-8")
    print(f"Best validation accuracy {best_acc:.3f}. Saved to {a.out}. Now run ai.vision.evaluate on the real-photo test sets.")


if __name__ == "__main__":
    main()