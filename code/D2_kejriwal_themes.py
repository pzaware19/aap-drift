"""
D2_kejriwal_themes.py
Project: AAP Drift -- the rhetoric turn in Kejriwal's speeches (Hindi)
Author:  Piyush Zaware
Last updated: 2026-06-28

Score 34 Kejriwal speech transcripts (2013-2026, Hindi) on three theme
dictionaries and plot the trajectory: does the anti-corruption/Swaraj language
fade and the welfare + nationalist/religious language rise, as the manifesto
data suggested but (being English) could not show for the rhetoric?

IN   input/kejriwal_speeches.csv
OUT  output/tables/kejriwal_theme_shares.csv
     output/Kejriwal_theme_trajectory.png
"""
import os
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = "/Users/piyushzaware/Documents/Unsupervised ML/AAP_Drift"
df = pd.read_csv(os.path.join(ROOT, "input", "kejriwal_speeches.csv"))

# Devanagari root substrings (catch inflections by matching the stem)
THEMES = {
    "Anti-corruption / Swaraj": ["भ्रष्ट", "लोकपाल", "स्वराज", "ईमानदार", "घोटाल",
                                  "रिश्वत", "व्यवस्था परिवर्तन", "आंदोलन", "जनता दरबार"],
    "Welfare / delivery":       ["मुफ्त", "मुफ़्त", "बिजली", "पानी", "सब्सिडी", "योजना",
                                  "गारंटी", "क्लीनिक", "राशन", "मोहल्ला", "स्कूल", "इलाज",
                                  "अस्पताल", "पेंशन", "महिला"],
    "Nationalism / religion":   ["भारत माता", "वंदे मातरम", "राम", "हनुमान", "देशभक्त",
                                  "तिरंगा", "राष्ट्र", "सनातन", "मंदिर", "हिंदू", "जय हिंद",
                                  "पाकिस्तान", "देश के लिए"],
}

def share(text, terms):
    text = str(text); n = max(len(text.split()), 1)
    return 100 * sum(text.count(t) for t in terms) / n

for theme, terms in THEMES.items():
    df[theme] = df["text"].apply(lambda t: share(t, terms))

by_year = df.groupby("year")[list(THEMES)].mean().reset_index()
by_year["n"] = df.groupby("year").size().values
by_year.to_csv(os.path.join(ROOT, "output", "tables", "kejriwal_theme_shares.csv"), index=False)
print("Theme share of Kejriwal speech words (%), by year:")
print(by_year.round(3).to_string(index=False))

# ── figure ────────────────────────────────────────────────────────────────────
pal = {"Anti-corruption / Swaraj": "#c0392b", "Welfare / delivery": "#2980b9",
       "Nationalism / religion": "#e67e22"}
fig, ax = plt.subplots(figsize=(9, 5.2))
for theme in THEMES:
    ax.plot(by_year["year"], by_year[theme], marker="o", lw=2, label=theme, color=pal[theme])
ax.set_title("Kejriwal's speeches drift too: anti-corruption fades, welfare and nationalism rise",
             fontsize=12, fontweight="bold")
ax.set_ylabel("Share of speech words (%)"); ax.set_xlabel(None)
ax.legend(frameon=False, fontsize=9)
ax.grid(axis="y", alpha=0.3)
ax.text(0.5, -0.13, "34 Arvind Kejriwal speech transcripts (Hindi), 2013-2026, scored on Devanagari theme dictionaries. Upload date = speech-date proxy.",
        transform=ax.transAxes, ha="center", fontsize=7.5, color="grey")
fig.tight_layout()
fig.savefig(os.path.join(ROOT, "output", "Kejriwal_theme_trajectory.png"), dpi=200, bbox_inches="tight")
print("\nSaved Kejriwal_theme_trajectory.png")
