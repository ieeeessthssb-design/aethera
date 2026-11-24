# FarukSTT test on Tunisian Derja farming questions (task #35)

Preliminary evaluation of the speech-to-text model FarukSTT for the Aethera voice feature.
Status: **small test, not a validation.** Results below are on 20 questions recorded by 3 team members.

## Setup
- Model: FarukSTT (Whisper large-v3 fine-tuned on Tunisian Derja). Repo ID loaded in Colab: **medyas/FarukSTT**
- Data: 20 short farming questions in Derja (irrigation, soil, olive, tomato, French-mixed terms), recorded by 3 team members on phones, in a quiet room. The audio is not in this repo (voices).
- Hardware: Google Colab, T4 GPU. About 1.5 seconds per question.
- Two configurations on the same recordings:
  - **A**: automatic language detection.
  - **B**: language forced to Arabic (`generate_kwargs={"language": "arabic", "task": "transcribe"}`).
- Metric: word error rate (WER) against the question text we wrote, after light normalisation (diacritics, accents, a few spelling variants). WER is a rough guide only: Derja has no fixed spelling, and French words transcribed in Arabic script count as errors although the meaning is kept.

## Results
| | A: auto language | B: Arabic hint |
|---|---|---|
| Mean WER | 38.39% | 31.43% |
| Median WER | 31.7% | 27.5% |
| Questions with WER 0 | 4 / 20 | 5 / 20 |
| Predictions containing Hebrew letters | 10 / 20 | 0 / 20 |
| Mean time per question | 1.61 s | 1.46 s |

B was better on 8 questions, equal on 10 and worse on 2. That is a 7.0-point drop in mean WER (18.1% relative). With 20 questions this difference is not statistically significant (sign test, p about 0.11).

## Meaning-level check (configuration B)
Suggested grading from comparing text only; **to be confirmed by listening to each recording**: 13 understood, 2 borderline, 5 wrong.
Errors cluster on key agricultural words: soil (التربة), to water (نسقي), rain (تشتي), hot (سخون), and the French term "goutte à goutte".

| id | what we wrote | what B heard | WER A | WER B | grade (suggested) | error (suggested) |
|---|---|---|---|---|---|---|
| q01 | وقتاش نسقي ليوم؟ | وقتاش نسقي اليوم | 0% | 0% | yes | spelling variant |
| q02 | قداش يلزمني نسقي ليوم؟ | قداش يلزمني نسقي اليوم | 0% | 0% | yes | spelling variant |
| q03 | التربة ناشفة شوية، شنوة نعمل؟ | طربوها ناجفة شوية شي يلزمني نعمل | 60% | 80% | no | wrong word (key term: soil) |
| q04 | الطماطم تعيش بالسخانة هاذي؟ | طماطم توا تعيش بالسخانة هاذيا | 100% | 75% | yes | extra word |
| q05 | كيفاش نسقي الزيتون في الصيف ؟ | كيفاش نسخ الزيتون في الصيف توا | 60% | 40% | no | wrong word (key verb: to water) |
| q06 | نسقي بال goutte à goutte | ناسقي بالجوتا | 100% | 100% | no | French term not recognised |
| q07 | نحب نزرع طماطم وقتاش احسن periode نزرع فيها؟ | نحب نزرع الطماطم وقتاش احسن بيريود نزرع فيها | 25% | 25% | yes | French word written in Arabic script |
| q08 | كيفاش نعرف اذو الزيتونة محتاجة ماء/ري؟ | كيفاش نعرف إنو الزيتونة متاعي محتاجة ماء | 43% | 43% | yes | reference typo; meaning kept |
| q09 | شنوما النباتات اللي نجم نزرعهم بتماشو مع نوعية الارض متاعي؟ | شنوما النباتات إلي نجم نزرحهم ويتماشيو مع نوعية الأرض متاعي | 30% | 30% | yes | one letter differs |
| q10 | الارض متاعي شنوا تحتاج؟ | الأرض متاعي شنوة تحتاج | 25% | 25% | yes |  |
| q11 | شنوما les caracteristique متع التربة متاعي؟ | شنوما les caractéristiques متاع التربة متاعي | 33% | 33% | yes | French term kept in Latin script |
| q12 | شنوما الامراض الموجودين في جهتي؟ | شنوما الأمراض الموجودين في جهتي | 0% | 0% | yes |  |
| q13 | كيفاش نجم ناقي الارض متاعي من الامراض؟ | كيفاش انجم ناقي الأرض متاعي من الأمراض | 29% | 14% | yes |  |
| q14 | قداش الرطوبة في التربة متاعي توا؟ | قداش الروطوبة في التروبو متاعي توا | 67% | 33% | borderline | non-word for "soil" |
| q15 | نسقي توا ولا نستنى؟ | نسقي تو ولا نستنى | 50% | 25% | yes | spelling variant |
| q16 | الدنيا باش تشتي غدوة، نسقي ولا لا؟ | الدنيا باش تشطي غدوة نسقي ولا لا | 29% | 14% | no | wrong word (key term: rain) |
| q17 | الجو سخون برشا، نزيد نسقي الماء؟ | الجو سكون برشا نزيد نسقي أمي | 50% | 33% | no | wrong words (hot, water) |
| q18 | قداش من  مرة نسقي في الجمعة؟ | قداش من مرة نسقي في الجمعة | 0% | 0% | yes |  |
| q19 | نسقي بالليل ولا بالنهار؟ | نسقي بالليل ولا بالنهار | 25% | 0% | yes |  |
| q20 | الcapteur يقول التربة مبلولة، يعني ما نسقيش؟ | الكابتور يقول التربة مبلولة ما عندها ما نسقيشها | 43% | 57% | borderline | extra words; French term in Arabic script |

## Findings
1. Forcing Arabic removed the Hebrew-script outputs (10/20 in A, 0/20 in B) and lowered mean WER on this small set.
2. Recognition errors remain on some agricultural terms and on French words inside Arabic sentences.
3. Speed is fine for an interactive demo (about 1.5 s per short question on a T4 GPU).

## Limits
- 20 questions, 3 speakers, all team members in a quiet room: not representative of farmers outdoors.
- Configuration B was chosen after seeing A on the same recordings.
- References are the questions we intended to say; some contain typos or Latin-script French words, which inflates WER.
- No dialect variety, no background noise (wind, pumps, tractors).

## Recommendation for the Aethera pipeline (#36)
- Use configuration B (Arabic hint) for now.
- Always show the transcript to the farmer and let them confirm or edit before the assistant answers, because key words can be wrong.
- Before relying on voice: test with more speakers, including farmers, and with field noise, and add a manual meaning-level grade.

## Reproduce
Open `FarukSTT_test_notebook.ipynb` in Google Colab (T4 GPU), upload a zip of the recordings and the CSV, and run all cells. Per-question results: `FarukSTT_experiments_A_B.csv`.

## Credit
FarukSTT: see its Hugging Face model card (authors credited there). Whisper large-v3 by OpenAI.
