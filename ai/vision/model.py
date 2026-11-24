"""Model, transforms and dataset helpers (needs torch + torchvision)."""
from pathlib import Path
from typing import Dict, List, Tuple

IMG_SIZE = 224
MEAN, STD = (0.485, 0.456, 0.406), (0.229, 0.224, 0.225)
IMAGE_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def build_model(num_classes: int, pretrained: bool = True):
    """MobileNetV3-Small (about 2.5 M parameters, runs on a phone-class CPU)."""
    import importlib

    torch = importlib.import_module("torch")
    torchvision = importlib.import_module("torchvision")

    weights = torchvision.models.MobileNet_V3_Small_Weights.IMAGENET1K_V1 if pretrained else None
    model = torchvision.models.mobilenet_v3_small(weights=weights)
    in_features = model.classifier[3].in_features
    model.classifier[3] = torch.nn.Linear(in_features, num_classes)
    return model


def eval_transform():
    from torchvision import transforms as T
    return T.Compose([T.Resize(256), T.CenterCrop(IMG_SIZE), T.ToTensor(), T.Normalize(MEAN, STD)])


def train_transform():
    """Strong augmentation: lab photos (PlantVillage) must generalise to field photos."""
    from torchvision import transforms as T
    return T.Compose([
        T.RandomResizedCrop(IMG_SIZE, scale=(0.5, 1.0)),
        T.RandomHorizontalFlip(), T.RandomVerticalFlip(),
        T.RandomRotation(25),
        T.ColorJitter(brightness=0.4, contrast=0.4, saturation=0.4, hue=0.05),
        T.ToTensor(), T.Normalize(MEAN, STD),
    ])


def scan_folder(root: Path, class_to_idx: Dict[str, int]) -> List[Tuple[Path, int]]:
    """(image, class index) for every class folder under root that the model knows.

    Unlike torchvision.ImageFolder this keeps the TRAIN label indices even when a split
    (val, test) is missing some classes.
    """
    samples = []
    for folder in sorted(p for p in Path(root).iterdir() if p.is_dir()):
        if folder.name not in class_to_idx:
            continue
        for img in sorted(folder.iterdir()):
            if img.suffix.lower() in IMAGE_EXT:
                samples.append((img, class_to_idx[folder.name]))
    return samples


def make_dataset(root: Path, class_to_idx: Dict[str, int], transform):
    from PIL import Image
    from torch.utils.data import Dataset

    samples = scan_folder(root, class_to_idx)

    class _Folder(Dataset):
        def __len__(self):
            return len(samples)

        def __getitem__(self, i):
            path, idx = samples[i]
            return transform(Image.open(path).convert("RGB")), idx

    ds = _Folder()
    ds.samples = samples
    return ds
