# =============================================================================
# A1_extract_manifestos.R
# Project: AAP Drift -- manifesto text extraction
# Author:  Piyush Zaware
# Last updated: 2026-06-23
#
# Goal: Extract clean text from every AAP manifesto PDF. Text-based PDFs go
#       through pdftotext; image/scanned PDFs (low text yield) fall back to OCR
#       (pdftoppm rasterize at 300 dpi -> tesseract per page).
#
# IN
#   input/manifesto_metadata.csv          -- one row per manifesto
#   input/manifestos/*.pdf
# OUT
#   output/manifestos_clean/{file_stem}.txt
#   output/tables/manifesto_extract_log.csv
# Requires: pdftotext, pdftoppm, tesseract on PATH.
# =============================================================================

suppressPackageStartupMessages({ library(readr); library(dplyr); library(stringr); library(tools) })

root    <- "/Users/piyushzaware/Documents/Unsupervised ML/AAP_Drift"
MANDIR  <- file.path(root, "input", "manifestos")
OUTDIR  <- file.path(root, "output", "manifestos_clean")
TABDIR  <- file.path(root, "output", "tables")
TMPDIR  <- file.path(root, "tmp")
dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TABDIR, showWarnings = FALSE, recursive = TRUE)

OCR_WORD_THRESHOLD <- 2500    # below this, assume scanned -> OCR

meta <- read_csv(file.path(root, "input", "manifesto_metadata.csv"), show_col_types = FALSE)

pdftotext_words <- function(pdf) {
  txt <- system2("pdftotext", c("-q", shQuote(pdf), "-"), stdout = TRUE, stderr = FALSE)
  paste(txt, collapse = " ")
}

ocr_pdf <- function(pdf, stem) {
  d <- file.path(TMPDIR, paste0("ocr_", stem)); dir.create(d, showWarnings = FALSE, recursive = TRUE)
  system2("pdftoppm", c("-r", "300", "-png", shQuote(pdf), shQuote(file.path(d, "pg"))),
          stdout = FALSE, stderr = FALSE)
  pages <- sort(list.files(d, pattern = "\\.png$", full.names = TRUE))
  message(sprintf("    OCR %s: %d pages", stem, length(pages)))
  out <- vapply(pages, function(p)
    paste(system2("tesseract", c("-l", "eng", shQuote(p), "stdout"),
                  stdout = TRUE, stderr = FALSE), collapse = " "),
    character(1))
  paste(out, collapse = " ")
}

clean_text <- function(x) {
  x <- str_replace_all(x, "\\s+", " ")
  x <- str_replace_all(x, "[­ ]", " ")     # soft hyphen, nbsp
  str_squish(x)
}

log_rows <- list()
for (i in seq_len(nrow(meta))) {
  f    <- meta$file[i]
  stem <- file_path_sans_ext(f)
  pdf  <- file.path(MANDIR, f)
  if (!file.exists(pdf)) { message(sprintf("[%s] MISSING pdf, skipping", stem)); next }

  raw  <- pdftotext_words(pdf)
  nw   <- str_count(raw, "\\S+")
  method <- "pdftotext"
  if (nw < OCR_WORD_THRESHOLD) {
    message(sprintf("[%s] only %d words from pdftotext -> OCR", stem, nw))
    raw    <- ocr_pdf(pdf, stem)
    nw     <- str_count(raw, "\\S+")
    method <- "ocr"
  }
  clean <- clean_text(raw)
  writeLines(clean, file.path(OUTDIR, paste0(stem, ".txt")))
  message(sprintf("[%s] %s -> %d words", stem, method, str_count(clean, "\\S+")))
  log_rows[[length(log_rows) + 1]] <- tibble(file = f, stem = stem, year = meta$year[i],
    region = meta$region[i], method = method, words = str_count(clean, "\\S+"))
}

bind_rows(log_rows) %>% arrange(year) %>%
  { write_csv(., file.path(TABDIR, "manifesto_extract_log.csv")); print(.) }
message("A1 complete.")
