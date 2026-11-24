"""Inference for the backend: one photo in, a cautious answer out.

The model never gives treatment advice, doses or a final diagnosis. Low-confidence,
ambiguous or unsupported-crop photos are sent to an expert.

    from ai.vision.predict import load_model, predict_image
    model = load_model("models/v1")
    result = predict_image(model, "leaf.jpg", farm_crop="tomate", lang="fr")
"""
import json
from pathlib import Path
from typing import Dict, List, Optional, Sequence

from .classes import CONDITION_NAMES, CROP_NAMES, SUPPORTED_CROPS, split_label, supported_crop

DEFAULT_THRESHOLD = 0.70   # minimum top-1 probability
DEFAULT_MARGIN = 0.15      # minimum gap between top-1 and top-2

TEXT = {
    "expert": {"en": "This is not a diagnosis. Check with an expert before treating, ideally with the leaf in hand.",
               "fr": "Ceci n'est pas un diagnostic. Consultez un expert avant tout traitement, idéalement avec la feuille.",
               "ar": "هذا ليس تشخيصاً. استشر خبيراً زراعياً قبل أي علاج، ويفضل أن تحمل الورقة معك."},
    "possible": {"en": "The photo looks like {crop}: possible {cond}.",
                 "fr": "La photo ressemble à {crop} : {cond} possible.",
                 "ar": "تبدو الصورة لـ {crop}: {cond} محتمل."},
    "healthy": {"en": "The photo looks like {crop} with no disease detected. That does not prove the plant is healthy.",
                "fr": "La photo ressemble à {crop} sans maladie détectée. Cela ne prouve pas que la plante est saine.",
                "ar": "تبدو الصورة لـ {crop} دون مرض ظاهر. هذا لا يثبت أن النبتة سليمة."},
    "unsure": {"en": "I can't tell what is wrong from this photo. Please send a clearer, closer photo of one leaf, and check with an expert.",
               "fr": "Je ne peux pas identifier le problème avec cette photo. Envoyez une photo plus nette et plus proche d'une feuille, et consultez un expert.",
               "ar": "لا أستطيع تحديد المشكلة من هذه الصورة. أرسل صورة أوضح وأقرب لورقة واحدة، واستشر خبيراً زراعياً."},
    "unsupported": {"en": "Photo diagnosis currently covers only tomato, potato and pepper leaves. Check with an expert for this crop.",
                    "fr": "Le diagnostic par photo ne couvre que les feuilles de tomate, pomme de terre et poivron. Consultez un expert pour cette culture.",
                    "ar": "التشخيص بالصورة يشمل حالياً أوراق الطماطم والبطاطا والفلفل فقط. استشر خبيراً زراعياً لهذا المحصول."},
}


def _t(key: str, lang: str, **kw) -> str:
    return (TEXT[key].get(lang) or TEXT[key]["en"]).format(**kw)


def decide(probs: Sequence[float], labels: Sequence[str], lang: str = "en",
           threshold: float = DEFAULT_THRESHOLD, margin: float = DEFAULT_MARGIN,
           farm_crop: Optional[str] = None) -> Dict:
    """Turn class probabilities into a cautious result. Pure Python (testable without torch)."""
    order = sorted(range(len(labels)), key=lambda i: probs[i], reverse=True)
    top3 = [{"label": labels[i], "probability": round(float(probs[i]), 4)} for i in order[:3]]
    best, second = float(probs[order[0]]), float(probs[order[1]]) if len(order) > 1 else 0.0
    crop, condition = split_label(labels[order[0]])

    reasons: List[str] = []
    if best < threshold:
        reasons.append("low_confidence")
    if best - second < margin:
        reasons.append("ambiguous_top2")
    expected = supported_crop(farm_crop) if farm_crop else None
    if expected and expected != crop:
        reasons.append("crop_mismatch")   # model sees another crop than the farm profile says

    needs_expert = bool(reasons)
    crop_name = CROP_NAMES[crop].get(lang) or CROP_NAMES[crop]["en"]
    cond_name = (CONDITION_NAMES[condition].get(lang) or CONDITION_NAMES[condition]["en"])
    if needs_expert:
        text = _t("unsure", lang)
    elif condition == "healthy":
        text = _t("healthy", lang, crop=crop_name) + " " + _t("expert", lang)
    else:
        text = _t("possible", lang, crop=crop_name, cond=cond_name) + " " + _t("expert", lang)
    return {"supported": True, "label": labels[order[0]], "confidence": round(best, 4), "top3": top3,
            "needs_expert": needs_expert, "reasons": reasons, "message": text}


def check_supported(farm_crop: Optional[str], lang: str = "en") -> Optional[Dict]:
    """Return a ready 'unsupported crop' result (olive, wheat...), or None if the crop is covered."""
    if farm_crop and supported_crop(farm_crop) is None:
        return {"supported": False, "label": None, "confidence": 0.0, "top3": [], "needs_expert": True,
                "reasons": ["unsupported_crop"], "message": _t("unsupported", lang)}
    return None


def load_model(model_dir) -> Dict:
    import torch
    from .model import build_model, eval_transform

    model_dir = Path(model_dir)
    labels = json.loads((model_dir / "labels.json").read_text(encoding="utf-8"))
    model = build_model(len(labels), pretrained=False)
    model.load_state_dict(torch.load(model_dir / "model.pt", map_location="cpu"))
    model.eval()
    return {"model": model, "labels": labels, "transform": eval_transform()}


def predict_image(bundle: Dict, image, farm_crop: Optional[str] = None, lang: str = "en",
                  threshold: float = DEFAULT_THRESHOLD, margin: float = DEFAULT_MARGIN) -> Dict:
    """image: a file path, bytes, or a PIL image."""
    import io

    import torch
    from PIL import Image

    early = check_supported(farm_crop, lang)
    if early:
        return early
    if isinstance(image, (str, Path)):
        img = Image.open(image)
    elif isinstance(image, (bytes, bytearray)):
        img = Image.open(io.BytesIO(image))
    else:
        img = image
    x = bundle["transform"](img.convert("RGB")).unsqueeze(0)
    with torch.no_grad():
        probs = torch.softmax(bundle["model"](x), dim=1)[0].tolist()
    return decide(probs, bundle["labels"], lang, threshold, margin, farm_crop)
