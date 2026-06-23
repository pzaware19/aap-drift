# =============================================================================
# B2_question_analysis.R
# Project: AAP Drift -- what AAP actually raises in Parliament
# Author:  Piyush Zaware
# Last updated: 2026-06-23
#
# Goal: Profile AAP's starred questions (2014-2025). Two things:
#   1. Top distinctive vocabulary (what AAP asks about).
#   2. The same four theme dictionaries used on the manifestos, applied to the
#      questions, so the parliamentary footprint can be read against the drift.
#   The questions span ~2014-2025 with changing membership, so they show the
#   CURRENT (post-drift) profile, not a time trajectory.
#
# IN   output/aap_questions.csv
# OUT  output/figures/fig_question_themes.png ; output/tables/question_top_words.csv
# =============================================================================

suppressPackageStartupMessages({ library(tidyverse); library(tidytext) })

root  <- "/Users/piyushzaware/Documents/Unsupervised ML/AAP_Drift"
FIG   <- file.path(root, "output", "figures"); TAB <- file.path(root, "output", "tables")

q <- read_csv(file.path(root, "output", "aap_questions.csv"), show_col_types = FALSE)

themes <- list(
  `Anti-corruption / Swaraj` = c("lokpal","janlokpal","corruption","corrupt","swaraj","mohalla","sabha","sabhas",
      "transparency","accountability","accountable","ombudsman","bribe","bribery","vigilance","referendum",
      "participatory","honest","honesty","integrity"),
  `Welfare / freebies` = c("free","subsidy","subsidies","subsidised","scheme","schemes","guarantee","guarantees",
      "allowance","pension","pensions","ration","welfare","waiver","stipend","insurance","cashless"),
  `Nationalism / religion` = c("ram","ramrajya","deshbhakti","patriot","army","soldier","sena","jawan","sanatan",
      "hindu","temple","mandir","ayodhya","border","agniveer","tiranga"),
  `Development / services` = c("school","schools","hospital","hospitals","road","roads","education","health",
      "employment","jobs","infrastructure","transport","sanitation","clinic","water","electricity","scheme"))

custom_stop <- c("government","minister","whether","details","state","states","sir","madam","india",
                 "country","year","years","number","steps","taken","propose","proposes","ministry",
                 "shri","sabha","rajya","lok","question","questions","total","unstarred","starred",
                 "answered","answer","annexure","pleased","including","wise","give","given","please",
                 "list","detail","regarding","respect","following","above","crore","lakh","central",
                 "national","data","report","fund","funds","under","made","also","since")
sw <- bind_rows(stop_words, tibble(word = custom_stop, lexicon = "c")) %>% distinct(word)

toks <- q %>% select(house, text) %>% unnest_tokens(word, text) %>%
  filter(str_detect(word, "^[a-z][a-z'-]+$"), !word %in% sw$word, nchar(word) >= 4)

# -- Top words -----------------------------------------------------------------
topw <- toks %>% count(word, sort = TRUE) %>% slice_head(n = 30)
write_csv(topw, file.path(TAB, "question_top_words.csv"))
cat("\nTop 20 words in AAP questions:\n"); print(topw, n = 20)

# -- Theme shares (questions vs the 2025 manifesto reference) -------------------
ntot <- nrow(toks)
qshare <- imap_dfr(themes, ~tibble(theme = .y, share = sum(toks$word %in% .x) / ntot))
cat("\nTheme share of AAP question vocabulary:\n")
print(qshare %>% mutate(pct = round(share*100, 2)))

pal <- c("Anti-corruption / Swaraj"="#c0392b","Welfare / freebies"="#2980b9",
         "Nationalism / religion"="#e67e22","Development / services"="#7f8c8d")
p <- qshare %>% mutate(theme = fct_reorder(theme, share)) %>%
  ggplot(aes(share*100, theme, fill = theme)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.2f%%", share*100)), hjust = -0.15, size = 3.6) +
  scale_fill_manual(values = pal, guide = "none") +
  expand_limits(x = max(qshare$share*100) * 1.18) +
  labs(title = "What AAP raises in Parliament, 2014 to 2025",
       subtitle = "Share of AAP's 2,836 starred-question words in each theme. Development and welfare dominate; the\nfounding anti-corruption language is almost absent from its parliamentary work.",
       x = "Share of question vocabulary (%)", y = NULL,
       caption = "Lok Sabha + Rajya Sabha starred questions. Same theme dictionaries as the manifesto analysis.") +
  theme_minimal(base_size = 12) + theme(plot.title = element_text(face = "bold"),
       panel.grid.major.y = element_blank())
ggsave(file.path(FIG, "fig_question_themes.png"), p, width = 8.5, height = 5, dpi = 150, bg = "white")
message("\nB2 complete.")
