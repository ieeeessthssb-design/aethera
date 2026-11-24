"""Show the near-duplicate pairs found by audit_data, side by side.

    python -m ai.vision.inspect_pairs                      # reads reports/audit_data.json
    python -m ai.vision.inspect_pairs --only-different     # only pairs with conflicting labels

Writes reports/near_dup_pairs.jpg: left = val/test image, right = its closest train image.
"""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--report", type=Path, default=Path("reports/audit_data.json"))
    ap.add_argument("--out", type=Path, default=Path("reports/near_dup_pairs.jpg"))
    ap.add_argument("--only-different", action="store_true")
    ap.add_argument("--thumb", type=int, default=220)
    a = ap.parse_args()

    pairs = json.loads(a.report.read_text(encoding="utf-8")).get("near_duplicates_val_test_vs_train", [])
    if a.only_different:
        pairs = [p for p in pairs if not p["same_label"]]
    if not pairs:
        raise SystemExit("No near-duplicate pairs to show.")
    pairs.sort(key=lambda p: (p["same_label"], p["distance"]))

    t, head, pad = a.thumb, 34, 6
    sheet = Image.new("RGB", (2 * t + 3 * pad, len(pairs) * (t + head + pad) + pad), "white")
    d = ImageDraw.Draw(sheet)
    for i, p in enumerate(pairs):
        y = pad + i * (t + head + pad)
        colour = (0, 120, 0) if p["same_label"] else (200, 0, 0)
        d.text((pad, y), f"#{i + 1} {p['split']}: {p['label']}   dist={p['distance']}", fill=colour)
        d.text((pad, y + 14), f"train match: {p['train_label']}  ({Path(p['train_image']).name[:28]})", fill=colour)
        for k, f in enumerate((p["image"], p["train_image"])):
            with Image.open(f) as im:
                im = im.convert("RGB")
                im.thumbnail((t, t))
                sheet.paste(im, (pad + k * (t + pad), y + head))
        print(f"#{i + 1:2d} dist={p['distance']} {'SAME ' if p['same_label'] else 'DIFF '} "
              f"{p['split']:14s} {p['label']:32s} <-> {p['train_label']:32s} {Path(p['train_image']).name[:3]}")
    a.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(a.out, quality=88)
    print(f"Saved {a.out}")


if __name__ == "__main__":
    main()
