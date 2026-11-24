# Photo diagnosis evaluation: plantdoc_v1_on_v3test (models\v1_baseline)

Images: **96**  |  Accuracy: **43.8%**  |  Macro-F1: **0.418**

## Per class

| Class | Precision | Recall | F1 | Images |
|---|---|---|---|---|
| pepper__bacterial_spot | 0.43 | 0.33 | 0.38 | 9 |
| pepper__healthy | 0.57 | 0.50 | 0.53 | 8 |
| potato__early_blight | 1.00 | 0.50 | 0.67 | 6 |
| potato__late_blight | 0.33 | 0.40 | 0.36 | 5 |
| tomato__bacterial_spot | 0.20 | 0.12 | 0.15 | 8 |
| tomato__early_blight | 0.33 | 0.44 | 0.38 | 9 |
| tomato__healthy | 0.57 | 0.50 | 0.53 | 8 |
| tomato__late_blight | 0.40 | 0.60 | 0.48 | 10 |
| tomato__leaf_mold | 0.50 | 0.33 | 0.40 | 6 |
| tomato__mosaic_virus | 0.00 | 0.00 | 0.00 | 10 |
| tomato__septoria_leaf_spot | 0.43 | 0.82 | 0.56 | 11 |
| tomato__yellow_leaf_curl_virus | 0.50 | 0.67 | 0.57 | 6 |

## Accuracy when the model is allowed to say "ask an expert"

Photos below the confidence threshold would be sent to an expert instead of getting an answer.

| Threshold | Answered (coverage) | Accuracy on answered |
|---|---|---|
| 0.0 | 100.0% | 43.8% |
| 0.5 | 32.3% | 67.7% |
| 0.6 | 22.9% | 63.6% |
| 0.7 | 14.6% | 57.1% |
| 0.8 | 6.2% | 66.7% |
| 0.9 | 1.0% | 100.0% |

## Not evaluated (no test images in this set)

- potato__healthy
- tomato__spider_mites
- tomato__target_spot

## Confusion (true class: predicted class = count)

- **pepper__bacterial_spot**: pepper__bacterial_spot = 3, tomato__septoria_leaf_spot = 3, tomato__early_blight = 1, tomato__late_blight = 1, pepper__healthy = 1
- **pepper__healthy**: pepper__healthy = 4, pepper__bacterial_spot = 2, potato__late_blight = 1, tomato__yellow_leaf_curl_virus = 1
- **potato__early_blight**: potato__late_blight = 3, potato__early_blight = 3
- **potato__late_blight**: tomato__late_blight = 3, potato__late_blight = 2
- **tomato__bacterial_spot**: tomato__septoria_leaf_spot = 4, pepper__bacterial_spot = 2, tomato__early_blight = 1, tomato__bacterial_spot = 1
- **tomato__early_blight**: tomato__early_blight = 4, tomato__septoria_leaf_spot = 1, tomato__bacterial_spot = 1, tomato__healthy = 1, tomato__leaf_mold = 1, tomato__late_blight = 1
- **tomato__healthy**: tomato__healthy = 4, tomato__septoria_leaf_spot = 2, tomato__early_blight = 1, tomato__late_blight = 1
- **tomato__late_blight**: tomato__late_blight = 6, tomato__early_blight = 2, pepper__healthy = 1, tomato__mosaic_virus = 1
- **tomato__leaf_mold**: tomato__leaf_mold = 2, tomato__early_blight = 2, tomato__bacterial_spot = 1, tomato__yellow_leaf_curl_virus = 1
- **tomato__mosaic_virus**: tomato__yellow_leaf_curl_virus = 2, tomato__septoria_leaf_spot = 2, tomato__late_blight = 2, tomato__healthy = 1, tomato__bacterial_spot = 1, pepper__healthy = 1, tomato__leaf_mold = 1
- **tomato__septoria_leaf_spot**: tomato__septoria_leaf_spot = 9, tomato__bacterial_spot = 1, tomato__early_blight = 1
- **tomato__yellow_leaf_curl_virus**: tomato__yellow_leaf_curl_virus = 4, tomato__healthy = 1, tomato__late_blight = 1

_Accuracy on this set is not a promise for farmers' phones. Report which set it was measured on._
