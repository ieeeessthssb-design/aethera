# Retrieval sources (task #33)

The Aethera assistant looks up passages in a small set of verified agronomy documents and shows the source with its answer.

## Contents
- `docs_sources.csv`: every source we use: title, publisher, year, URL, licence (read on the document's own imprint page), who checked it and when.
- `docs/`: the documents that are openly licensed and may be redistributed (see `docs/NOTICE.md`).
- Other sources listed in the CSV are NOT stored in this repository, because their licences do not allow redistribution. To use them, download them from the URL in the CSV into `docs/`; this folder ignores them by default (`.gitignore`).

## How it is used
1. Documents are split into passages and indexed in PostgreSQL with pgvector (owner: Salma).
2. When a farmer asks a question, the assistant retrieves the best passages and returns the answer with the source label (title and page).
3. If nothing relevant is found, the assistant says so and the case can be sent to an expert.

## Licences
- Most sources are CC BY 4.0 or CC BY-NC-SA 3.0 IGO. They are used here for a non-commercial prototype.
- Any commercial use would need a licence request to FAO: www.fao.org/contact-us/licence-request.
- We do not use the FAO logo, and FAO does not endorse Aethera.

## Rules
- Add a source only after opening it and reading its licence yourself. Record your name and the date in the CSV.
- Never commit documents marked "all rights reserved".
- Never write a licence you did not read.