# =============================================================================
# B1_extract_questions.R
# Project: AAP Drift -- extract AAP starred questions (Lok Sabha + Rajya Sabha)
# Author:  Piyush Zaware
# Last updated: 2026-06-23
#
# Goal: Pull every starred question asked by an AAP MP in either house, to use
#       for the positioning layer (what AAP raises in Parliament vs other
#       parties). Source data lives in the Lok_Sabha_Questions project.
#
# AAP MP identification:
#   LS  - mp_name_crosswalk.csv, party_family == "AAP" (Punjab MPs, small N).
#   RS  - the project's rs_party_lookup is incomplete/erroneous (only 2, and one
#         is mislabelled), so we use a curated exact-name roster of AAP Rajya
#         Sabha members (Delhi 2018/2024, Punjab 2022). "Sanjay Singh" and
#         "Harbhajan Singh" are common names, flagged as a minor purity risk.
#
# IN   ../Lok_Sabha_Questions/tmp/train-*.parquet            (LS questions)
#      ../Lok_Sabha_Questions/tmp/rajyasabha_clean.parquet   (RS questions)
#      ../Lok_Sabha_Questions/input/mp_name_crosswalk.csv
# OUT  output/aap_questions.csv ; output/tables/aap_question_counts.csv
# =============================================================================

suppressPackageStartupMessages({ library(arrow); library(dplyr); library(stringr); library(purrr); library(readr); library(tidyr) })

root  <- "/Users/piyushzaware/Documents/Unsupervised ML/AAP_Drift"
LSQ   <- "/Users/piyushzaware/Documents/Unsupervised ML/Lok_Sabha_Questions"
OUT   <- file.path(root, "output"); TAB <- file.path(OUT, "tables")
dir.create(TAB, showWarnings = FALSE, recursive = TRUE)

# -- Rajya Sabha ---------------------------------------------------------------
aap_rs <- c("Sanjay Singh","Narain Dass Gupta","Sushil Kumar Gupta","Raghav Chadha",
            "Sandeep Kumar Pathak","Ashok Kumar Mittal","Sanjeev Arora","Harbhajan Singh",
            "Sant Balbir Singh","Vikramjit Singh Sahney","Swati Maliwal")

rs <- read_parquet(file.path(LSQ, "tmp", "rajyasabha_clean.parquet")) %>%
  filter(str_detect(toupper(qtype), "STAR"), name %in% aap_rs, !is.na(english), english != "") %>%
  transmute(house = "Rajya Sabha", member = name, date = as.character(adate),
            session = as.character(ses_no), title = qtitle, text = english)

# -- Lok Sabha -----------------------------------------------------------------
cw <- read_csv(file.path(LSQ, "input", "mp_name_crosswalk.csv"), show_col_types = FALSE) %>%
  filter(party_family == "AAP")

pq <- list.files(file.path(LSQ, "tmp"), pattern = "train-.*\\.parquet$", full.names = TRUE)
ls_raw <- map_dfr(pq, ~read_parquet(.x, col_select = c("lok_no","type","members","question_text"))) %>%
  filter(str_detect(toupper(type), "STAR"), lok_no >= 16) %>%
  mutate(member = map_chr(members, ~tryCatch(str_squish(as.character(list(.x)[[1]])[1]),
                                             error = function(e) NA_character_)))

ls <- ls_raw %>%
  inner_join(cw %>% distinct(raw_name, lok_no), by = c("member" = "raw_name", "lok_no")) %>%
  filter(!is.na(question_text), question_text != "") %>%
  transmute(house = "Lok Sabha", member, date = NA_character_,
            session = as.character(lok_no), title = NA_character_, text = question_text)

# -- Combine + save ------------------------------------------------------------
aap_q <- bind_rows(rs, ls)
write_csv(aap_q, file.path(OUT, "aap_questions.csv"))

counts <- aap_q %>% count(house, member, name = "n_questions") %>% arrange(house, desc(n_questions))
write_csv(counts, file.path(TAB, "aap_question_counts.csv"))

cat(sprintf("\nAAP starred questions: %d total  (RS %d, LS %d)\n",
            nrow(aap_q), sum(aap_q$house == "Rajya Sabha"), sum(aap_q$house == "Lok Sabha")))
cat("By member:\n"); print(counts, n = 30)
message("B1 complete.")
