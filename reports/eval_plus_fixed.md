# Configuration comparison on test_plantdoc (96 images)

Every configuration is listed. Do not pick the highest row on its own: with this few images, a lucky row looks like a gain.

| Configuration | Images | Accuracy | 95 % interval | Macro-F1 | Crop correct | Answers at 0.5 (accuracy) |
|---|---|---|---|---|---|---|
| v1_baseline | 96 | 43.8% (42) | 34.3% to 53.7% | 0.418 | 85.4% | 32% (68%) |
| v1_baseline + known crop | 96 | 53.1% (51) | 43.2% to 62.8% | 0.515 | 100.0% | 58% (70%) |
| v3_boost | 96 | 49.0% (47) | 39.2% to 58.8% | 0.470 | 81.2% | 40% (71%) |
| v3_boost + known crop | 96 | 59.4% (57) | 49.4% to 68.7% | 0.572 | 100.0% | 60% (78%) |
| ensemble(v1_baseline+v3_boost) | 96 | 47.9% (46) | 38.2% to 57.8% | 0.466 | 83.3% | 34% (70%) |
| ensemble(v1_baseline+v3_boost) + known crop | 96 | 59.4% (57) | 49.4% to 68.7% | 0.580 | 100.0% | 57% (80%) |
| v1_baseline + flip-TTA | 96 | 44.8% (43) | 35.2% to 54.7% | 0.435 | 87.5% | 34% (67%) |
| v1_baseline + flip-TTA + known crop | 96 | 52.1% (50) | 42.2% to 61.8% | 0.507 | 100.0% | 59% (70%) |
| v3_boost + flip-TTA | 96 | 52.1% (50) | 42.2% to 61.8% | 0.502 | 81.2% | 41% (74%) |
| v3_boost + flip-TTA + known crop | 96 | 61.5% (59) | 51.5% to 70.6% | 0.592 | 100.0% | 58% (80%) |
| ensemble(v1_baseline+v3_boost) + flip-TTA | 96 | 49.0% (47) | 39.2% to 58.8% | 0.481 | 84.4% | 34% (70%) |
| ensemble(v1_baseline+v3_boost) + flip-TTA + known crop | 96 | 58.3% (56) | 48.3% to 67.7% | 0.577 | 100.0% | 58% (79%) |

"known crop" assumes the photo is of the crop in the farm profile (a farmer photographing another plant breaks this).
