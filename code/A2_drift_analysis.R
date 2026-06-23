# =============================================================================
# A2_drift_analysis.R
# Project: AAP Drift -- ideological drift in the manifestos
# Author:  Piyush Zaware
# Last updated: 2026-06-23
#
# Goal: Test the claim that AAP drifted from its founding identity. Three
#       length-robust measures over the manifesto time series:
#   1. De-programmatization: raw manifesto length over time (70-point
#      programmatic manifestos -> terse guarantee cards).
#   2. Theme-share trajectory: share of tokens in each of four dictionaries
#      (anti-corruption/Swaraj, welfare/freebies, nationalism/religion,
#      development). Length-robust, so it survives the thin late documents.
#   3. Cosine distance from the 2013 founding manifesto (secondary, length-
#      sensitive, so caveated).
#       Spine = Delhi (2013/2015/2020/2025). Punjab + LS shown as context.
#
# IN   output/manifestos_clean/*.txt ; input/manifesto_metadata.csv
# OUT  output/figures/{fig_length_collapse,fig_theme_trajectory,fig_cosine_drift}.png
#      output/tables/theme_shares.csv
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse); library(tidytext); library(Matrix)
})

root   <- "/Users/piyushzaware/Documents/Unsupervised ML/AAP_Drift"
CLEAN  <- file.path(root, "output", "manifestos_clean")
FIGDIR <- file.path(root, "output", "figures")
TABDIR <- file.path(root, "output", "tables")
dir.create(FIGDIR, showWarnings = FALSE, recursive = TRUE); dir.create(TABDIR, showWarnings = FALSE, recursive = TRUE)

meta <- read_csv(file.path(root, "input", "manifesto_metadata.csv"), show_col_types = FALSE) %>%
  mutate(stem = tools::file_path_sans_ext(file))

# Hindi LS2024 excluded from the English lexical analysis (kept qualitatively).
docs <- meta %>% filter(stem != "LS2024_vision_hindi") %>%
  mutate(text = map_chr(stem, ~{
    p <- file.path(CLEAN, paste0(.x, ".txt")); if (file.exists(p)) read_file(p) else NA_character_
  })) %>% filter(!is.na(text))

# == Theme dictionaries =======================================================
#{
themes <- list(
  `Anti-corruption / Swaraj` = c("lokpal","janlokpal","corruption","corrupt","swaraj","mohalla","sabha","sabhas",
      "transparency","accountability","accountable","ombudsman","bribe","bribery","vigilance","referendum",
      "participatory","honest","honesty","integrity","citizen","citizens"),
  `Welfare / freebies` = c("free","subsidy","subsidies","subsidised","scheme","schemes","guarantee","guarantees",
      "allowance","pension","pensions","ration","welfare","waiver","stipend","insurance","cashless"),
  `Nationalism / religion` = c("ram","ramrajya","deshbhakti","patriot","patriotic","army","soldier","soldiers",
      "sena","jawan","sanatan","hindu","temple","mandir","ayodhya","china","border","agniveer","tiranga","nationalist"),
  `Development / services` = c("school","schools","hospital","hospitals","road","roads","education","health",
      "employment","jobs","infrastructure","transport","sanitation","clinic","clinics","teacher","doctor")
)
#}

# == Tokenize and score theme shares ==========================================
#{
toks <- docs %>% select(stem, region, year, text) %>%
  unnest_tokens(word, text) %>%
  filter(str_detect(word, "^[a-z][a-z'-]+$"))

totals <- toks %>% count(stem, name = "n_tot")

theme_long <- imap_dfr(themes, function(words, tname)
  toks %>% filter(word %in% words) %>% count(stem, name = "n_theme") %>% mutate(theme = tname)) %>%
  right_join(expand_grid(stem = unique(toks$stem), theme = names(themes)), by = c("stem","theme")) %>%
  mutate(n_theme = replace_na(n_theme, 0)) %>%
  left_join(totals, by = "stem") %>%
  left_join(distinct(docs, stem, region, year), by = "stem") %>%
  mutate(share = n_theme / n_tot)

write_csv(theme_long %>% arrange(region, year, theme), file.path(TABDIR, "theme_shares.csv"))
cat("\n=== Theme shares (%) ===\n")
theme_long %>% mutate(pct = round(share*100, 2)) %>%
  select(region, year, theme, pct) %>%
  pivot_wider(names_from = theme, values_from = pct) %>% arrange(region, year) %>% print(width = 200)
#}

# == FIGURE 1: de-programmatization (length collapse, Delhi spine) =============
#{
spine <- c("delhi2013","delhi2015","delhi2020","delhi2025")
len_df <- docs %>% filter(stem %in% spine) %>%
  mutate(words = map_int(stem, ~ totals$n_tot[totals$stem == .x]))

p1 <- ggplot(len_df, aes(year, words)) +
  geom_line(color = "#2c3e50", linewidth = 1) +
  geom_point(size = 3, color = "#c0392b") +
  geom_text(aes(label = paste0(words, "w")), vjust = -1, size = 3.4) +
  scale_x_continuous(breaks = c(2013,2015,2020,2025)) +
  expand_limits(y = c(0, 6200)) +
  labs(title = "From manifesto to guarantee card",
       subtitle = "AAP Delhi manifesto length collapsed as the party shifted from detailed programmes to terse 'guarantees'.",
       x = NULL, y = "Manifesto length (words)",
       caption = "2020 and 2025 are guarantee cards / news-grade; the collapse in length is itself the signal.") +
  theme_minimal(base_size = 12) + theme(plot.title = element_text(face = "bold"))
ggsave(file.path(FIGDIR, "fig_length_collapse.png"), p1, width = 8, height = 5, dpi = 150, bg = "white")
#}

# == FIGURE 2: theme-share trajectory (Delhi spine) ===========================
#{
traj <- theme_long %>% filter(stem %in% spine)
pal <- c("Anti-corruption / Swaraj"="#c0392b","Welfare / freebies"="#2980b9",
         "Nationalism / religion"="#e67e22","Development / services"="#7f8c8d")
p2 <- ggplot(traj, aes(year, share*100, color = theme)) +
  geom_line(linewidth = 1.1) + geom_point(size = 2.6) +
  scale_color_manual(values = pal) +
  scale_x_continuous(breaks = c(2013,2015,2020,2025)) +
  labs(title = "AAP's drift in the Delhi manifestos, 2013 to 2025",
       subtitle = "Share of manifesto vocabulary in each theme. The founding anti-corruption/Swaraj language fades; welfare dominates.",
       x = NULL, y = "Share of manifesto words (%)", color = NULL,
       caption = "Length-robust theme dictionaries. Late documents are thin, so read levels with care; the direction is the finding.") +
  theme_minimal(base_size = 12) + theme(plot.title = element_text(face = "bold"), legend.position = "top")
ggsave(file.path(FIGDIR, "fig_theme_trajectory.png"), p2, width = 8.5, height = 5.5, dpi = 150, bg = "white")
#}

# == FIGURE 3: cosine distance from 2013 founding manifesto (secondary) =======
#{
tfidf <- toks %>% count(stem, word) %>% bind_tf_idf(word, stem, n)
M <- cast_sparse(tfidf, stem, word, tf_idf); M <- M / sqrt(rowSums(M^2))
cosm <- as.matrix(tcrossprod(M))
drift <- tibble(stem = spine) %>%
  mutate(year = c(2013,2015,2020,2025),
         dist_from_2013 = 1 - cosm["delhi2013", stem])
p3 <- ggplot(drift, aes(year, dist_from_2013)) +
  geom_line(color = "#8e44ad", linewidth = 1) + geom_point(size = 3, color = "#8e44ad") +
  scale_x_continuous(breaks = c(2013,2015,2020,2025)) +
  labs(title = "Distance from the 2013 founding manifesto",
       subtitle = "Cosine distance of each Delhi manifesto from 2013. Higher = more drift in vocabulary.",
       x = NULL, y = "1 - cosine similarity to 2013",
       caption = "Secondary, length-sensitive measure (thin late documents inflate distance). Use alongside theme shares.") +
  theme_minimal(base_size = 12) + theme(plot.title = element_text(face = "bold"))
ggsave(file.path(FIGDIR, "fig_cosine_drift.png"), p3, width = 8, height = 5, dpi = 150, bg = "white")
cat("\n=== Cosine distance from 2013 (Delhi spine) ===\n"); print(drift)
#}

message("\nA2 complete.")
