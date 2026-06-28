"""
C1_myneta_candidates.py
Project: AAP Drift -- "movement to machine" via candidate affidavits
Author:  Piyush Zaware
Last updated: 2026-06-28

Scrape AAP candidate affidavit data (assets, criminal cases, education) from
myneta.info across AAP's Delhi elections (its core) plus Punjab 2022, to test
whether AAP's candidates went from clean insurgents to typical wealthy
politicians over time. Lok Sabha is skipped (all-India table too large to page,
and AAP's LS footprint is marginal).

OUT
  input/myneta_aap_candidates.csv   (one row per AAP candidate)
"""
import os, sys, re, time
import requests
from bs4 import BeautifulSoup
import pandas as pd

ROOT = "/Users/piyushzaware/Documents/Unsupervised ML/AAP_Drift"
OUT  = os.path.join(ROOT, "input", "myneta_aap_candidates.csv")
UA   = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"}

ELECTIONS = {
    "delhi2013": ("Delhi", 2013), "delhi2015": ("Delhi", 2015),
    "delhi2020": ("Delhi", 2020), "delhi2025": ("Delhi", 2025),
    "punjab2022": ("Punjab", 2022),
}
TEST = os.environ.get("TEST_PAGES")   # set to a number to scrape only N pages (testing)

def parse_rs(s):
    m = re.search(r"Rs\s*([\d,]+)", s or "")
    return int(m.group(1).replace(",", "")) if m else None

def parse_criminal(s):
    m = re.search(r"\d+", s or "")
    return int(m.group(0)) if m else 0

def scrape(slug, region, year):
    base = f"https://myneta.info/{slug}/index.php?action=summary&subAction=candidates_analyzed"
    rows, seen = [], set()
    maxp = int(TEST) if TEST else 90
    for page in range(1, maxp + 1):
        try:
            html = requests.get(f"{base}&page={page}", headers=UA, timeout=30).text
        except Exception as e:
            print(f"    {slug} p{page} error: {e}"); break
        soup = BeautifulSoup(html, "html.parser")
        page_snos = []
        for tr in soup.find_all("tr"):
            tds = tr.find_all("td")
            if len(tds) < 8: continue
            c = [td.get_text(" ", strip=True) for td in tds]
            if not c[0].isdigit(): continue
            page_snos.append(c[0])
            pf = c[3].strip().lower()
            if pf != "aap" and "aam aadmi" not in pf: continue
            rows.append({
                "region": region, "year": year, "election": slug,
                "candidate": c[1], "constituency": c[2],
                "criminal_cases": parse_criminal(c[4]), "education": c[5],
                "assets": parse_rs(c[6]), "liabilities": parse_rs(c[7]),
            })
        if not page_snos or all(s in seen for s in page_snos):
            break
        seen.update(page_snos)
        time.sleep(0.4)
    print(f"  {slug}: {len(rows)} AAP candidates over {page} pages")
    return rows

if __name__ == "__main__":
    all_rows = []
    for slug, (region, year) in ELECTIONS.items():
        all_rows += scrape(slug, region, year)
    df = pd.DataFrame(all_rows).drop_duplicates(subset=["election","candidate","constituency"])
    df.to_csv(OUT, index=False)
    print(f"\nSaved {len(df)} AAP candidates -> {OUT}")
    if len(df):
        print(df.groupby(["region","year"]).agg(
            n=("candidate","size"),
            median_assets=("assets","median"),
            pct_criminal=("criminal_cases", lambda x: round((x>0).mean()*100,1))).to_string())
