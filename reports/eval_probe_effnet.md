# probe_effnet on prepared_v3/test_plantdoc (96 images)

Every configuration is listed. Do not pick the highest row on its own: with this few images, a lucky row looks like a gain.

| Configuration | Images | Accuracy | 95 % interval | Macro-F1 | Crop correct | Answers at 0.5 (accuracy) |
|---|---|---|---|---|---|---|
| probe_effnet | 96 | 38.5% (37) | 29.4% to 48.5% | 0.386 | 68.8% | 97% (39%) |
| probe_effnet + known crop | 96 | 58.3% (56) | 48.3% to 67.7% | 0.583 | 100.0% | 95% (60%) |

"known crop" assumes the photo is of the crop in the farm profile (a farmer photographing another plant breaks this).

# probe_effnet: per-class detail (no known-crop mask)

Images: **96**  |  Accuracy: **38.5%**  |  Macro-F1: **0.386**

## Per class

| Class | Precision | Recall | F1 | Images |
|---|---|---|---|---|
| pepper__bacterial_spot | 0.25 | 0.22 | 0.24 | 9 |
| pepper__healthy | 0.56 | 0.62 | 0.59 | 8 |
| potato__early_blight | 0.25 | 0.50 | 0.33 | 6 |
| potato__late_blight | 0.15 | 0.40 | 0.22 | 5 |
| tomato__bacterial_spot | 0.23 | 0.38 | 0.29 | 8 |
| tomato__early_blight | 0.25 | 0.11 | 0.15 | 9 |
| tomato__healthy | 0.57 | 0.50 | 0.53 | 8 |
| tomato__late_blight | 0.43 | 0.30 | 0.35 | 10 |
| tomato__leaf_mold | 0.25 | 0.17 | 0.20 | 6 |
| tomato__mosaic_virus | 0.75 | 0.30 | 0.43 | 10 |
| tomato__septoria_leaf_spot | 0.60 | 0.55 | 0.57 | 11 |
| tomato__yellow_leaf_curl_virus | 0.80 | 0.67 | 0.73 | 6 |

## Accuracy when the model is allowed to say "ask an expert"

Photos below the confidence threshold would be sent to an expert instead of getting an answer.

| Threshold | Answered (coverage) | Accuracy on answered |
|---|---|---|
| 0.0 | 100.0% | 38.5% |
| 0.5 | 96.9% | 38.7% |
| 0.6 | 90.6% | 41.4% |
| 0.7 | 84.4% | 44.4% |
| 0.8 | 76.0% | 47.9% |
| 0.9 | 63.5% | 47.5% |

## Not evaluated (no test images in this set)

- potato__healthy
- tomato__spider_mites
- tomato__target_spot

## Confusion (true class: predicted class = count)

- **pepper__bacterial_spot**: tomato__bacterial_spot = 3, pepper__bacterial_spot = 2, pepper__healthy = 2, potato__late_blight = 1, tomato__septoria_leaf_spot = 1
- **pepper__healthy**: pepper__healthy = 5, pepper__bacterial_spot = 2, potato__late_blight = 1
- **potato__early_blight**: potato__early_blight = 3, potato__late_blight = 2, tomato__late_blight = 1
- **potato__late_blight**: potato__late_blight = 2, tomato__late_blight = 1, tomato__leaf_mold = 1, potato__early_blight = 1
- **tomato__bacterial_spot**: tomato__bacterial_spot = 3, potato__early_blight = 2, tomato__septoria_leaf_spot = 2, pepper__bacterial_spot = 1
- **tomato__early_blight**: tomato__bacterial_spot = 3, potato__early_blight = 2, tomato__early_blight = 1, tomato__healthy = 1, potato__late_blight = 1, pepper__bacterial_spot = 1
- **tomato__healthy**: tomato__healthy = 4, tomato__late_blight = 1, tomato__leaf_mold = 1, tomato__septoria_leaf_spot = 1, potato__early_blight = 1
- **tomato__late_blight**: potato__late_blight = 4, tomato__late_blight = 3, tomato__early_blight = 2, potato__early_blight = 1
- **tomato__leaf_mold**: tomato__bacterial_spot = 2, tomato__late_blight = 1, tomato__leaf_mold = 1, pepper__bacterial_spot = 1, potato__late_blight = 1
- **tomato__mosaic_virus**: tomato__mosaic_virus = 3, tomato__healthy = 2, tomato__yellow_leaf_curl_virus = 1, tomato__leaf_mold = 1, pepper__healthy = 1, pepper__bacterial_spot = 1, potato__late_blight = 1
- **tomato__septoria_leaf_spot**: tomato__septoria_leaf_spot = 6, tomato__bacterial_spot = 2, potato__early_blight = 2, tomato__early_blight = 1
- **tomato__yellow_leaf_curl_virus**: tomato__yellow_leaf_curl_virus = 4, pepper__healthy = 1, tomato__mosaic_virus = 1

_Accuracy on this set is not a promise for farmers' phones. Report which set it was measured on._
