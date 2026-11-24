"""Class names shared by data preparation, training, evaluation and prediction.

Unified label format: "<crop>__<condition>", for 3 crops that exist in BOTH datasets:
tomato, potato, pepper (bell pepper). Olive, the main Tunisian tree crop, is in neither
dataset, so the model does not cover it (see README).

Pure Python on purpose: importable without torch.
"""
from typing import Dict, Optional

SUPPORTED_CROPS = ("tomato", "potato", "pepper")

# PlantVillage folder names (spMohanty/PlantVillage-Dataset, raw/color) -> unified label
PV_MAP: Dict[str, str] = {
    "Tomato___Bacterial_spot": "tomato__bacterial_spot",
    "Tomato___Early_blight": "tomato__early_blight",
    "Tomato___Late_blight": "tomato__late_blight",
    "Tomato___Leaf_Mold": "tomato__leaf_mold",
    "Tomato___Septoria_leaf_spot": "tomato__septoria_leaf_spot",
    "Tomato___Spider_mites Two-spotted_spider_mite": "tomato__spider_mites",
    "Tomato___Target_Spot": "tomato__target_spot",
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": "tomato__yellow_leaf_curl_virus",
    "Tomato___Tomato_mosaic_virus": "tomato__mosaic_virus",
    "Tomato___healthy": "tomato__healthy",
    "Potato___Early_blight": "potato__early_blight",
    "Potato___Late_blight": "potato__late_blight",
    "Potato___healthy": "potato__healthy",
    "Pepper,_bell___Bacterial_spot": "pepper__bacterial_spot",
    "Pepper,_bell___healthy": "pepper__healthy",
}

# PlantDoc folder names (pratikkayal/PlantDoc-Dataset, train/ and test/) -> unified label.
# ASSUMPTIONS to confirm by looking at a few images: "Tomato leaf" = healthy,
# "Tomato leaf yellow virus" = yellow leaf curl virus, "Bell_pepper leaf spot" = bacterial spot.
PD_MAP: Dict[str, str] = {
    "Tomato Early blight leaf": "tomato__early_blight",
    "Tomato Septoria leaf spot": "tomato__septoria_leaf_spot",
    "Tomato leaf bacterial spot": "tomato__bacterial_spot",
    "Tomato leaf late blight": "tomato__late_blight",
    "Tomato leaf mosaic virus": "tomato__mosaic_virus",
    "Tomato leaf yellow virus": "tomato__yellow_leaf_curl_virus",
    "Tomato leaf": "tomato__healthy",
    "Tomato mold leaf": "tomato__leaf_mold",
    "Tomato two spotted spider mites leaf": "tomato__spider_mites",
    "Potato leaf early blight": "potato__early_blight",
    "Potato leaf late blight": "potato__late_blight",
    "Bell_pepper leaf spot": "pepper__bacterial_spot",
    "Bell_pepper leaf": "pepper__healthy",
}

ALL_LABELS = sorted(set(PV_MAP.values()) | set(PD_MAP.values()))

# Display names. Arabic and French wording is a first draft: have an agronomist review it.
CONDITION_NAMES: Dict[str, Dict[str, str]] = {
    "early_blight": {"en": "early blight", "fr": "alternariose", "ar": "اللفحة المبكرة"},
    "late_blight": {"en": "late blight", "fr": "mildiou", "ar": "اللفحة المتأخرة (الميلديو)"},
    "septoria_leaf_spot": {"en": "Septoria leaf spot", "fr": "septoriose", "ar": "تبقع الأوراق السبتوري"},
    "bacterial_spot": {"en": "bacterial spot", "fr": "tache bactérienne", "ar": "التبقع البكتيري"},
    "leaf_mold": {"en": "leaf mold", "fr": "cladosporiose", "ar": "عفن الأوراق"},
    "mosaic_virus": {"en": "mosaic virus", "fr": "virus de la mosaïque", "ar": "فيروس الموزاييك"},
    "yellow_leaf_curl_virus": {"en": "yellow leaf curl virus", "fr": "virus des feuilles jaunes en cuillère",
                               "ar": "فيروس تجعد واصفرار الأوراق"},
    "spider_mites": {"en": "spider mites", "fr": "acariens tétranyques", "ar": "العنكبوت الأحمر"},
    "target_spot": {"en": "target spot", "fr": "corynesporiose", "ar": "التبقع الهدفي"},
    "healthy": {"en": "no disease", "fr": "aucune maladie", "ar": "لا يوجد مرض"},
}
CROP_NAMES: Dict[str, Dict[str, str]] = {
    "tomato": {"en": "tomato", "fr": "tomate", "ar": "الطماطم"},
    "potato": {"en": "potato", "fr": "pomme de terre", "ar": "البطاطا"},
    "pepper": {"en": "pepper", "fr": "poivron", "ar": "الفلفل"},
}

# Crop names a farm profile might hold -> supported crop key (lower-case input).
CROP_ALIASES = {
    "tomato": "tomato", "tomatoes": "tomato", "tomate": "tomato", "tomates": "tomato", "طماطم": "tomato", "بندورة": "tomato",
    "potato": "potato", "potatoes": "potato", "pomme de terre": "potato", "pommes de terre": "potato", "بطاطا": "potato", "بطاطس": "potato",
    "pepper": "pepper", "peppers": "pepper", "poivron": "pepper", "poivrons": "pepper", "فلفل": "pepper",
}


def split_label(label: str):
    crop, _, condition = label.partition("__")
    return crop, condition


def label_from_folder(source: str, folder: str) -> Optional[str]:
    """source is 'plantvillage' or 'plantdoc'. Returns None for crops/classes we do not use."""
    return (PV_MAP if source == "plantvillage" else PD_MAP).get(folder)


def supported_crop(farm_crop: str) -> Optional[str]:
    return CROP_ALIASES.get((farm_crop or "").strip().lower())
