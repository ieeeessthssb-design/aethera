"""Accuracy boost without fine-tuning: strong frozen backbone + small linear classifier.

Why: with 34 to 102 field photos per class and 400 lab photos per class, fine-tuning a small
network overfits the lab photos (train 86 %, validation 45 %). Features from a bigger
pretrained network, plus a regularised linear classifier, usually transfer better to field
photos, train in minutes on CPU, and give the SAME result every run (no random checkpoints).
Not guaranteed to beat your current model: run it and look at the VALIDATION number first.

    python -m ai.vision.train_probe --data data\\prepared_v3 --backbone convnext_tiny --name probe_convnext

Backbones: convnext_tiny | efficientnet_b0 | resnet50 | dinov2_vits14 (needs internet to GitHub once).
Selection rule: the regularisation strength is chosen on the VALIDATION split only. The test
split is evaluated once at the end and is never used to choose anything.
"""
import argparse
import json
import random
from pathlib import Path
from typing import Dict, List, Sequence, Tuple

import numpy as np

IMAGE_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


# ----------------------------------------------------- pure numpy logic (unit tested)

def scan(root: Path) -> List[Tuple[Path, str]]:
    out = []
    for folder in sorted(p for p in Path(root).iterdir() if p.is_dir()):
        for img in sorted(folder.iterdir()):
            if img.suffix.lower() in IMAGE_EXT:
                out.append((img, folder.name))
    return out


def source_of(path: Path, pv_prefix: str) -> str:
    return "pv" if path.name.lower().startswith(pv_prefix.lower()) else "pd"


def limit_pv(samples: List[Tuple[Path, str]], per_class: int, pv_prefix: str, seed: int = 42):
    """Keep every field photo, but at most `per_class` lab photos per class."""
    rng = random.Random(seed)
    keep, pv_by_label = [], {}
    for path, label in samples:
        if source_of(path, pv_prefix) == "pv":
            pv_by_label.setdefault(label, []).append((path, label))
        else:
            keep.append((path, label))
    for label, items in pv_by_label.items():
        rng.shuffle(items)
        keep += items[:per_class]
    return sorted(keep, key=lambda s: str(s[0]))


def sample_weights(sources: Sequence[str], labels_idx: Sequence[int], n_classes: int, pd_weight: float) -> np.ndarray:
    """Balance classes, and count a field photo `pd_weight` times more than a lab photo."""
    w = np.array([pd_weight if s == "pd" else 1.0 for s in sources], dtype=float)
    labels_idx = np.asarray(labels_idx)
    for c in range(n_classes):
        m = labels_idx == c
        if m.any():
            w[m] *= 1.0 / w[m].sum()
    return w * (len(w) / w.sum())


def softmax(z: np.ndarray) -> np.ndarray:
    z = z - z.max(axis=1, keepdims=True)
    e = np.exp(z)
    return e / e.sum(axis=1, keepdims=True)


def fit_softmax(X: np.ndarray, y: np.ndarray, n_classes: int, w: np.ndarray, l2: float,
                iters: int = 400, lr: float = 0.05):
    """Multinomial logistic regression, full-batch Adam, L2 on the weights."""
    n, d = X.shape
    W, b = np.zeros((d, n_classes)), np.zeros(n_classes)
    Y = np.eye(n_classes)[y]
    mW, vW, mb, vb = np.zeros_like(W), np.zeros_like(W), np.zeros_like(b), np.zeros_like(b)
    b1, b2, eps = 0.9, 0.999, 1e-8
    wn = w / w.sum()
    for t in range(1, iters + 1):
        P = softmax(X @ W + b)
        G = (P - Y) * wn[:, None]
        gW, gb = X.T @ G + l2 * W, G.sum(axis=0)
        mW, mb = b1 * mW + (1 - b1) * gW, b1 * mb + (1 - b1) * gb
        vW, vb = b2 * vW + (1 - b2) * gW ** 2, b2 * vb + (1 - b2) * gb ** 2
        W -= lr * (mW / (1 - b1 ** t)) / (np.sqrt(vW / (1 - b2 ** t)) + eps)
        b -= lr * (mb / (1 - b1 ** t)) / (np.sqrt(vb / (1 - b2 ** t)) + eps)
    return W, b


def accuracy(X, y, W, b) -> float:
    return float((np.argmax(X @ W + b, axis=1) == y).mean()) if len(y) else 0.0


# ----------------------------------------------------- torch part (not unit tested)

def build_backbone(name: str):
    import torch
    import torchvision as tv

    if name == "convnext_tiny":
        m = tv.models.convnext_tiny(weights=tv.models.ConvNeXt_Tiny_Weights.IMAGENET1K_V1)
        m.classifier[2] = torch.nn.Identity()
    elif name == "efficientnet_b0":
        m = tv.models.efficientnet_b0(weights=tv.models.EfficientNet_B0_Weights.IMAGENET1K_V1)
        m.classifier = torch.nn.Identity()
    elif name == "resnet50":
        m = tv.models.resnet50(weights=tv.models.ResNet50_Weights.IMAGENET1K_V2)
        m.fc = torch.nn.Identity()
    elif name == "dinov2_vits14":
        m = torch.hub.load("facebookresearch/dinov2", "dinov2_vits14")
    else:
        raise SystemExit(f"Unknown backbone {name}")
    return m.eval()


def extract(model, paths: Sequence[Path], flip: bool, batch: int = 32) -> np.ndarray:
    import torch
    from PIL import Image
    from torchvision import transforms as T

    tf = T.Compose([T.Resize(256), T.CenterCrop(224), T.ToTensor(),
                    T.Normalize((0.485, 0.456, 0.406), (0.229, 0.224, 0.225))])
    feats = []
    with torch.no_grad():
        for i in range(0, len(paths), batch):
            x = torch.stack([tf(Image.open(p).convert("RGB")) for p in paths[i:i + batch]])
            f = model(x)
            if flip:
                f = (f + model(torch.flip(x, dims=[3]))) / 2   # average original + mirrored view
            feats.append(f.reshape(len(x), -1).numpy())
            print(f"\r  {min(i + batch, len(paths))}/{len(paths)}", end="", flush=True)
    print()
    return np.concatenate(feats)


def cached_features(model, samples, cache: Path, tag: str, flip: bool) -> np.ndarray:
    f = cache / f"feat_{tag}.npz"
    paths = [str(p) for p, _ in samples]
    if f.exists():
        data = np.load(f, allow_pickle=True)
        if list(data["paths"]) == paths:
            return data["X"]
    print(f"Extracting {tag} features ({len(paths)} images)...")
    X = extract(model, [Path(p) for p in paths], flip)
    np.savez(f, X=X, paths=np.array(paths, dtype=object))
    return X


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, default=Path("data/prepared_v3"))
    ap.add_argument("--backbone", default="convnext_tiny")
    ap.add_argument("--name", default=None)
    ap.add_argument("--pv-prefix", default="pv", help="file-name prefix of PlantVillage images in train/")
    ap.add_argument("--pv-per-class", type=int, default=150, help="max lab photos per class (field photos all kept)")
    ap.add_argument("--pd-weight", type=float, default=4.0, help="a field photo counts this many lab photos")
    ap.add_argument("--extra-test", nargs="*", default=[], help="more test folders under --data, e.g. test_plantwild")
    ap.add_argument("--reports", type=Path, default=Path("reports"))
    ap.add_argument("--models-dir", type=Path, default=Path("models"))
    a = ap.parse_args()
    name = a.name or f"probe_{a.backbone}"

    from .evaluate_plus import evaluate_rows, render_rows, wilson
    from .metrics import render_markdown, summarize

    train = limit_pv(scan(a.data / "train"), a.pv_per_class, a.pv_prefix)
    val, test = scan(a.data / "val"), scan(a.data / "test_plantdoc")
    labels = sorted({l for _, l in train})
    idx = {l: i for i, l in enumerate(labels)}
    sources = [source_of(p, a.pv_prefix) for p, _ in train]
    n_pw = sum(1 for p, _ in train if p.name.lower().startswith("pw_"))
    print(f"train {len(train)} (field {sources.count('pd')} of which PlantWild {n_pw}, lab {sources.count('pv')}), "
          f"val {len(val)}, test {len(test)}")
    if sources.count("pv") == 0:
        print("WARNING: no PlantVillage image found: check --pv-prefix against the file names in train/")

    out = a.models_dir / name
    out.mkdir(parents=True, exist_ok=True)
    model = build_backbone(a.backbone)
    # train features: original + mirrored view averaged (cheap augmentation); val/test: original only
    Xtr = cached_features(model, train, out, "train", flip=False)
    Xva = cached_features(model, val, out, "val", flip=False)
    Xte = cached_features(model, test, out, "test", flip=False)

    mean, std = Xtr.mean(0), Xtr.std(0) + 1e-6
    norm = lambda X: (X - mean) / std
    ytr = np.array([idx[l] for _, l in train])
    yva = np.array([idx[l] for _, l in val if l in idx])
    Xva_k = norm(Xva)[[l in idx for _, l in val]]
    w = sample_weights(sources, ytr, len(labels), a.pd_weight)

    best = None
    print("Choosing regularisation on the VALIDATION split:")
    for l2 in (1e-4, 1e-3, 1e-2, 1e-1):
        W, b = fit_softmax(norm(Xtr), ytr, len(labels), w, l2)
        v = accuracy(Xva_k, yva, W, b)
        print(f"  l2={l2:g}  validation accuracy {v:.3f}")
        if best is None or v > best[0]:
            best = (v, l2, W, b)
    val_acc, l2, W, b = best
    print(f"Chosen l2={l2:g} (validation accuracy {val_acc:.3f}, {len(yva)} images)")

    probs = softmax(norm(Xte) @ W + b)
    y_true = [l for _, l in test]
    rows = evaluate_rows({name: probs.tolist()}, labels, y_true)
    summary = summarize(y_true, [labels[i] for i in probs.argmax(1)], probs.max(1).tolist(), labels)

    a.reports.mkdir(parents=True, exist_ok=True)
    (a.reports / f"eval_{name}.md").write_text(
        render_rows(rows, f"{name} on {a.data.name}/test_plantdoc ({len(y_true)} images)") + "\n" +
        render_markdown(summary, f"{name}: per-class detail (no known-crop mask)"), encoding="utf-8")
    np.savez(out / "probe.npz", W=W, b=b, mean=mean, std=std, labels=np.array(labels), backbone=a.backbone)
    (out / "probe.json").write_text(json.dumps({"backbone": a.backbone, "l2": l2, "val_accuracy": val_acc,
                                                "pd_weight": a.pd_weight, "pv_per_class": a.pv_per_class,
                                                "train_images": len(train)}, indent=2), encoding="utf-8")
    print(render_rows(rows, name))
    print(f"Saved {a.reports / f'eval_{name}.md'} and {out}")

    for tname in a.extra_test:                      # extra real-photo test sets, each reported separately
        extra = [(p, l) for p, l in scan(a.data / tname) if l in idx]
        if not extra:
            print(f"No images in {a.data / tname}: skipped")
            continue
        Xe = cached_features(model, extra, out, f"test_{tname}", flip=False)
        pe = softmax(norm(Xe) @ W + b)
        ye = [l for _, l in extra]
        rows_e = evaluate_rows({name: pe.tolist()}, labels, ye)
        sum_e = summarize(ye, [labels[i] for i in pe.argmax(1)], pe.max(1).tolist(), labels)
        (a.reports / f"eval_{name}_{tname}.md").write_text(
            render_rows(rows_e, f"{name} on {a.data.name}/{tname} ({len(ye)} images)") + "\n" +
            render_markdown(sum_e, f"{name} on {tname}: per-class detail"), encoding="utf-8")
        print(render_rows(rows_e, f"{name} on {tname}"))


if __name__ == "__main__":
    main()
