# Aethera

AI platform for Tunisian smallholder farmers (IEEE TSYP 14, AOTN, Phase 3 prototype).
Core feature: ESP32 soil sensor -> backend -> app dashboard + AI irrigation assistant.

## Where to put your work
| Folder | What goes here | Owners |
|---|---|---|
| backend/ | FastAPI, database, endpoints | Rannym, Salma, Aroua |
| frontend/ | Mobile app and expert web page | Med yassine, Yomna, Azza |
| firmware/src, simulator, wiring | ESP32 code, sensor simulator, wiring diagram | Ela, Bochra |
| ai/assistant | Assistant prompt, safety rules | Aroua, Salma |
| ai/retrieval | Verified documents list, indexing, retrieve() | Salma, Molka |
| ai/stt | FarukSTT test, voice pipeline | Molka, Aroua |
| ai/vision | Photo diagnosis (stretch) | Salma |
| ai/eval | Assistant evaluation | Rannym |
| docs/ | UML, architecture, report, demo script, user tests | see task sheet |

## Rules
- Work on a branch, open a pull request, never push straight to main.
- No API keys, passwords or personal audio in the repo.
- Anything simulated or entered by hand is labelled as such.
- Before you start: `git checkout main` then `git pull origin main`.
