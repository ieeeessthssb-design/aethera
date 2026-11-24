"""Inference with the frozen-backbone probe (models/probe_<backbone>/probe.npz).

    from ai.vision.predict_probe import load_probe, predict_probe_image
    bundle = load_probe("models/probe_convnext")        # once at startup (downloads/caches ConvNeXt weights)
    result = predict_probe_image(bundle, "leaf.jpg", farm_crop="tomate", lang="fr")

Same output format as ai.vision.predict (label, confidence, top3, needs_expert, reasons, message).
The crop from the farm profile rules out diseases of other crops; if the photo clearly looks like
ANOTHER crop, the result goes to an expert instead (the farmer probably photographed the wrong plant).
The model never gives treatment advice. Thresholds are NOT tuned yet: choose them from the
accuracy-vs-confidence table in reports/eval_probe_*.md.
"""
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

import numpy as np

from .classes import supported_crop
from .evaluate_plus import mask_to_crop
from .predict import TEXT, _t, check_supported, decide
from .train_probe import build_backbone, softmax

PROBE_THRESHOLD = 0.50   # first guess: validate on your data
PROBE_MARGIN = 0.10


def probs_from_features(feat: np.ndarray, mean: np.ndarray, std: np.ndarray, W: np.ndarray, b: np.ndarray) -> List[float]:
    x = (np.asarray(feat, dtype=float).reshape(1, -1) - mean) / std
    return softmax(x @ W + b)[0].tolist()


def apply_known_crop(probs: Sequence[float], labels: Sequence[str], farm_crop: Optional[str],
                     mismatch_threshold: float = 0.5) -> Tuple[List[float], bool]:
    """Mask other crops' labels. mismatch=True if the unmasked top label is another crop with high probability."""
    crop = supported_crop(farm_crop) if farm_crop else None
    if not crop:
        return list(probs), False
    top = max(range(len(labels)), key=lambda i: probs[i])
    mismatch = labels[top].split("__")[0] != crop and probs[top] >= mismatch_threshold
    return mask_to_crop(probs, labels, crop), mismatch


def decide_probe(probs: Sequence[float], labels: Sequence[str], lang: str = "en", farm_crop: Optional[str] = None,
                 threshold: float = PROBE_THRESHOLD, margin: float = PROBE_MARGIN) -> Dict:
    used, mismatch = apply_known_crop(probs, labels, farm_crop)
    result = decide(used, labels, lang, threshold, margin, farm_crop=None)
    if mismatch:
        result["needs_expert"] = True
        result["reasons"] = result["reasons"] + ["crop_mismatch"]
        result["message"] = _t("unsure", lang)
    return result


def load_probe(model_dir) -> Dict:
    d = np.load(Path(model_dir) / "probe.npz", allow_pickle=False)
    backbone = str(d["backbone"])
    return {"W": d["W"], "b": d["b"], "mean": d["mean"], "std": d["std"],
            "labels": [str(x) for x in d["labels"]], "backbone": backbone, "net": build_backbone(backbone)}


def predict_probe_image(bundle: Dict, image, farm_crop: Optional[str] = None, lang: str = "en",
                        threshold: float = PROBE_THRESHOLD, margin: float = PROBE_MARGIN) -> Dict:
    """image: file path, bytes or PIL image."""
    import io

    import torch
    from PIL import Image
    from torchvision import transforms as T

    early = check_supported(farm_crop, lang)
    if early:
        return early
    if isinstance(image, (str, Path)):
        img = Image.open(image)
    elif isinstance(image, (bytes, bytearray)):
        img = Image.open(io.BytesIO(image))
    else:
        img = image
    tf = T.Compose([T.Resize(256), T.CenterCrop(224), T.ToTensor(),
                    T.Normalize((0.485, 0.456, 0.406), (0.229, 0.224, 0.225))])
    with torch.no_grad():
        feat = bundle["net"](tf(img.convert("RGB")).unsqueeze(0)).reshape(1, -1).numpy()
    probs = probs_from_features(feat, bundle["mean"], bundle["std"], bundle["W"], bundle["b"])
    return decide_probe(probs, bundle["labels"], lang, farm_crop, threshold, margin)
