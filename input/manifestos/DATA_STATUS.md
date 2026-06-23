# AAP Manifesto Corpus — collection status

Anchor for the drift analysis = **Delhi 2013** (founding document).
Drift spine = Delhi (2013, 2015, 2020, 2025). Punjab + LS = supplementary/robustness.

## In hand (downloaded, AAP_Drift/input/manifestos/)
| Doc | File | Words | Status |
|-----|------|-------|--------|
| Delhi 2015 | delhi2015.pdf | 5,360 | OK, clean (70-point action plan) |
| Punjab 2017 | punjab.pdf | 7,978 | OK, clean (dated from "debt-free by Dec 2018") |
| Delhi 2020 | delhi2020.pdf | 1,692 | IMAGE PDF — needs OCR (text yield too low for 3.7MB) |

(Also exists: Lok_Sabha_Questions/Manifesto/AAP_Manifesto_2020_e048d30b16.pdf = same image-based 2020, 1,692 words.)

## Still needed (priority order)
| Doc | Priority | Where to look | Risk |
|-----|----------|---------------|------|
| **Delhi 2013** | CRITICAL (anchor) | Scribd 191368086 / SlideShare 44579952 / web.archive of party site / news | login-walled, may be partial |
| **Delhi 2025** | CRITICAL (endpoint) | current aamaadmiparty.org / news (15 guarantees, Jan 2025) | PDF not yet located; may be news-grade only |
| Punjab 2022 | high | party site / babushahi / news | findable |
| LS 2019 | medium | aamaadmiparty.org "Vision Document 2019" | findable |
| LS 2014 | medium | party archive / news | findable |
| LS 2024 | medium | verify Lok_Sabha_Questions/Manifesto/MANIFESTO_2024.pdf is AAP (likely not) | verify |

## Blockers
- **OCR**: tesseract / ocrmypdf NOT installed locally (pdftoppm is). Needed to recover the 2020 image PDF and any other scanned manifestos. Requires `brew install tesseract` (or ocrmypdf).
- The two anchor documents (2013, 2025) are the hardest to get as clean full text. The drift framing depends on them.

## Notes
- Indian_Manifestos/ project is an empty scaffold (no PDFs downloaded); manifesto_sources.md lists only AAP LS 2014/2019, not the Delhi/Punjab assembly series.
