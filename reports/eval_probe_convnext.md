# probe_convnext on prepared_v3/test_plantdoc (96 images)

Every configuration is listed. Do not pick the highest row on its own: with this few images, a lucky row looks like a gain.

| Configuration | Images | Accuracy | 95 % interval | Macro-F1 | Crop correct | Answers at 0.5 (accuracy) |
|---|---|---|---|---|---|---|
| probe_convnext | 96 | 56.2% (54) | 46.3% to 65.7% | 0.566 | 85.4% | 79% (64%) |
| probe_convnext + known crop | 96 | 64.6% (62) | 54.6% to 73.4% | 0.647 | 100.0% | 89% (69%) |

"known crop" assumes the photo is of the crop in the farm profile (a farmer photographing another plant breaks this).

# probe_convnext: per-class detail (no known-crop mask)

Images: **96**  |  Accuracy: **56.2%**  |  Macro-F1: **0.566**

## Per class

| Class | Precision | Recall | F1 | Images |
|---|---|---|---|---|
| pepper__bacterial_spot | 0.71 | 0.56 | 0.62 | 9 |
| pepper__healthy | 0.60 | 0.75 | 0.67 | 8 |
| potato__early_blight | 0.67 | 0.67 | 0.67 | 6 |
| potato__late_blight | 0.67 | 0.40 | 0.50 | 5 |
| tomato__bacterial_spot | 0.23 | 0.38 | 0.29 | 8 |
| tomato__early_blight | 0.55 | 0.67 | 0.60 | 9 |
| tomato__healthy | 0.83 | 0.62 | 0.71 | 8 |
| tomato__late_blight | 0.58 | 0.70 | 0.64 | 10 |
| tomato__leaf_mold | 0.38 | 0.50 | 0.43 | 6 |
| tomato__mosaic_virus | 1.00 | 0.20 | 0.33 | 10 |
| tomato__septoria_leaf_spot | 0.70 | 0.64 | 0.67 | 11 |
| tomato__yellow_leaf_curl_virus | 0.67 | 0.67 | 0.67 | 6 |

## Accuracy when the model is allowed to say "ask an expert"

Photos below the confidence threshold would be sent to an expert instead of getting an answer.

| Threshold | Answered (coverage) | Accuracy on answered |
|---|---|---|
| 0.0 | 100.0% | 56.2% |
| 0.5 | 79.2% | 64.5% |
| 0.6 | 57.3% | 65.5% |
| 0.7 | 39.6% | 73.7% |
| 0.8 | 31.2% | 80.0% |
| 0.9 | 20.8% | 85.0% |

## Not evaluated (no test images in this set)

- potato__healthy
- tomato__spider_mites
- tomato__target_spot

## Confusion (true class: predicted class = count)

- **pepper__bacterial_spot**: pepper__bacterial_spot = 5, tomato__septoria_leaf_spot = 2, pepper__healthy = 1, tomato__bacterial_spot = 1
- **pepper__healthy**: pepper__healthy = 6, tomato__healthy = 1, tomato__leaf_mold = 1
- **potato__early_blight**: potato__early_blight = 4, potato__late_blight = 1, tomato__early_blight = 1
- **potato__late_blight**: pepper__healthy = 2, potato__late_blight = 2, tomato__late_blight = 1
- **tomato__bacterial_spot**: tomato__bacterial_spot = 3, pepper__bacterial_spot = 2, tomato__late_blight = 1, tomato__septoria_leaf_spot = 1, tomato__early_blight = 1
- **tomato__early_blight**: tomato__early_blight = 6, tomato__bacterial_spot = 2, potato__early_blight = 1
- **tomato__healthy**: tomato__healthy = 5, tomato__leaf_mold = 1, tomato__bacterial_spot = 1, tomato__yellow_leaf_curl_virus = 1
- **tomato__late_blight**: tomato__late_blight = 7, tomato__bacterial_spot = 2, tomato__early_blight = 1
- **tomato__leaf_mold**: tomato__leaf_mold = 3, tomato__early_blight = 1, tomato__late_blight = 1, tomato__bacterial_spot = 1
- **tomato__mosaic_virus**: tomato__mosaic_virus = 2, tomato__spider_mites = 2, tomato__leaf_mold = 2, tomato__late_blight = 2, pepper__healthy = 1, tomato__yellow_leaf_curl_virus = 1
- **tomato__septoria_leaf_spot**: tomato__septoria_leaf_spot = 7, tomato__bacterial_spot = 2, potato__early_blight = 1, tomato__early_blight = 1
- **tomato__yellow_leaf_curl_virus**: tomato__yellow_leaf_curl_virus = 4, tomato__leaf_mold = 1, tomato__bacterial_spot = 1

_Accuracy on this set is not a promise for farmers' phones. Report which set it was measured on._
