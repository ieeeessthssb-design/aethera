# Aethera photo diagnosis (task 37, stretch)

A leaf photo goes in; the system returns the crop, a *possible* condition and a confidence, or sends the photo to an
agricultural expert. It is a **triage tool, not a diagnosis**.

Covered crops: **tomato, potato, bell pepper**. Olive, wheat, citrus and every other crop are **not covered**.

## Results

Test set: 96 real-world PlantDoc photos (5 to 11 per class, 12 classes), never used for training or model selection.
Intervals are Wilson 95 %.

| Model | Disease exactly right | 95 % interval | Crop known from farm profile | 95 % interval |
|---|---|---|---|---|
| **ConvNeXt-Tiny probe (final)** | **56.2 % (54/96)**, macro-F1 0.566 | 46.3 to 65.7 % | **64.6 % (62/96)** | 54.6 to 73.4 % |
| MobileNetV3-Small fine-tuned, v3 | 49.0 % (47/96), macro-F1 0.470 | 39.2 to 58.8 % | 59.4 % (57/96) | 49.4 to 68.7 % |
| MobileNetV3-Small fine-tuned, v1 | 43.8 % (42/96), macro-F1 0.418 | 34.3 to 53.7 % | 53.1 % (51/96) | 43.2 to 62.8 % |
| EfficientNet-B0 probe | 38.5 % (37/96), macro-F1 0.386 | 29.4 to 48.5 % | 58.3 % (56/96) | 48.3 to 67.7 % |

How to read it:
- The intervals overlap: the final model **scored higher, but the ranking is not proven**.
- "Crop known" means the disease classes of other crops are ruled out because the farm profile states the crop.
  It assumes the farmer photographs that crop. The crop itself is recognised correctly in 85 % of photos
  (82/96, 77 to 91 %) without this rule.
- The final model was chosen by **validation accuracy** (0.497 on 185 images) among 2 backbones and 4
  regularisation values. The test set was not used to choose.
- About a fifth of the photos go to an expert at confidence threshold 0.5: the final model answers about 79 % of
  photos with about 64 % accuracy (about 89 % with 69 % when the crop is known; rounded values from
  `reports/eval_probe_convnext.md`). Thresholds are not tuned yet.

### Final model
ConvNeXt-Tiny (torchvision ImageNet weights, frozen) + a linear classifier trained on PlantVillage + PlantDoc
(field photos weighted 4x, at most 150 lab photos per class). Regularisation chosen on validation.
SHA256 of `probe.npz`: `8b1de1fb38357a8aa934a8b84f53ccffdcd0f8a21fa29814d51254d939e2bacb`

### Development notes (for honesty)
- The fine-tuned `v3_boost` folder was rewritten by another run during development, so its earlier scores
  (37.5 %, 49.0 %, 56.2 % on the same photos) are **discarded**. The numbers above come from files with recorded
  hashes: v1_baseline `452dc5c5...`, v3_boost `61055184...`, and two scripts (`evaluate.py`, `evaluate_plus.py`)
  agree on them. Their training history is not documented.
- The first report (46.1 % on 102 photos) is not used: its model file cannot be identified.
- Models were compared on the same 96 photos. Choosing among several models on a small test set is optimistic;
  confirm on photos we take ourselves.

## Not tested, not covered, limits
- **Not tested** (no real-photo test images): `potato__healthy`, `tomato__spider_mites`, `tomato__target_spot`.
  They are trained on lab photos only.
- **Not covered:** olive, wheat, citrus and all crops outside tomato, potato and pepper. `check_supported()` sends them
  to an expert.
- Weak classes: `tomato__mosaic_virus` and `tomato__bacterial_spot` have very low recall in the first models.
- Training data is mostly lab photos (PlantVillage) against 34 to 102 field photos (PlantDoc) per class.
- The test set is small and PlantDoc labels contain some noise (for example images in a "healthy" folder that show
  disease or are not leaves, judging by file names).
- **No photos of our own were tested.** [Update this line if you add a set.]
- Not reviewed by an agronomist. French and Arabic disease names in `classes.py` are a first draft.

## Data and licences
| Dataset | Source | Licence |
|---|---|---|
| PlantDoc (Singh et al., 2020) | github.com/pratikkayal/PlantDoc-Dataset | CC BY 4.0 (stated in its repository). Credit the authors. |
| PlantVillage (Hughes & Salathe, 2015; Mohanty, Hughes & Salathe, 2016) | github.com/spMohanty/PlantVillage-Dataset | No licence statement found: confirm before redistributing; cite the papers. |

Pretrained backbones: torchvision ImageNet weights (ConvNeXt: Liu et al., 2022; MobileNetV3: Howard et al., 2019).
Images and model weights are not committed (`data/`, `models/` are git-ignored).

### Data audit
`audit_data.py` checks the prepared dataset and writes `reports/audit_data.json`. Result on `data/prepared_v3`:
manifest consistent, **no exact duplicates** across splits or labels, **no near-duplicates** between validation/test
and train. Contact sheets for visual checks are in `reports/contact_sheets/`.

## Safety behaviour (links to task 34)
Never gives pesticide names, doses or treatment steps. Always adds "this is not a diagnosis, check with an expert".
`needs_expert` is true for: low confidence, ambiguous top-2, a photo that clearly looks like another crop than the
farm profile, or an unsupported crop (see `ai/assistant/SAFETY_RULES.md`).

## Reproduce
```bash
pip install -r ai/vision/requirements-vision.txt
# data: see prepare_data.py --help (data/prepared_v3 = train/ val/ test_plantdoc/ built from PlantVillage + PlantDoc)
set PYTHONPATH=<repo>;<repo>\backend
python -m ai.vision.train_probe --data data\prepared_v3 --backbone convnext_tiny --name probe_convnext
python -m ai.vision.evaluate_plus --models models\v1_baseline models\v3_boost --test-dir data\prepared_v3\test_plantdoc --name plus_fixed
python -m pytest ai/vision/tests -q
```
The probe is deterministic given the same features; ConvNeXt weights download once from torchvision.

## Use in code
```python
from ai.vision.predict_probe import load_probe, predict_probe_image
bundle = load_probe("models/probe_convnext")          # once
result = predict_probe_image(bundle, photo_bytes, farm_crop=farm.crop, lang="fr")
# result["needs_expert"] -> create an ExpertCase (photo_url field exists)
```
Not wired to a backend endpoint yet. ConvNeXt + torch is heavy for small free hosting tiers: check memory first.
Default thresholds (0.5 confidence, 0.10 margin) are first guesses.

## Files
`classes.py` labels, crop names, aliases · `prepare_data.py`, `make_exclusions.py`, `inspect_pairs.py`, `audit_data.py`
data preparation and checks · `model.py`, `train.py`, `evaluate.py`, `metrics.py`, `predict.py` fine-tuned MobileNetV3
pipeline · `train_probe.py`, `evaluate_plus.py`, `predict_probe.py` final probe pipeline · `tests/` unit tests for the
parts that do not need torch.
