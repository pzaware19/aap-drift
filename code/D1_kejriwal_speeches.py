"""
D1_kejriwal_speeches.py
Project: AAP Drift -- the rhetoric turn, in Kejriwal's own (spoken) words
Author:  Piyush Zaware
Last updated: 2026-06-28

Build a time-stamped corpus of Arvind Kejriwal speeches by searching YouTube
with yt-dlp (no API key) and pulling Hindi auto-transcripts. Used to test the
nationalist/Hindutva-soft drift that the (English) Delhi manifestos could not
show. Upload date is used as the speech-date proxy.

OUT
  input/kejriwal_speeches.csv   (video_id, date, year, title, text)
"""
import os, subprocess, time
import pandas as pd
from youtube_transcript_api import YouTubeTranscriptApi

ROOT = "/Users/piyushzaware/Documents/Unsupervised ML/AAP_Drift"
OUT  = os.path.join(ROOT, "input", "kejriwal_speeches.csv")
api  = YouTubeTranscriptApi()

QUERIES = [f"Arvind Kejriwal speech {y}" for y in range(2013, 2027)] + [
    "Arvind Kejriwal rally full speech", "Arvind Kejriwal Hanuman Chalisa speech",
    "Arvind Kejriwal Ram Ayodhya speech", "Arvind Kejriwal Delhi victory speech",
    "Arvind Kejriwal Punjab speech", "Arvind Kejriwal anti corruption speech",
]
PER_QUERY = int(os.environ.get("PER_QUERY", "3"))

def search(q, n):
    try:
        r = subprocess.run(
            ["yt-dlp", "--no-warnings", "--print", "%(id)s\t%(upload_date)s\t%(title)s",
             f"ytsearch{n}:{q}"], capture_output=True, text=True, timeout=240)
    except Exception:
        return []
    out = []
    for line in r.stdout.strip().split("\n"):
        p = line.split("\t")
        if len(p) >= 2 and p[1] and p[1] != "NA":
            out.append((p[0], p[1], p[2] if len(p) > 2 else ""))
    return out

# 1. gather candidate videos with upload dates
vids = {}
for q in QUERIES:
    for vid, date, title in search(q, PER_QUERY):
        vids.setdefault(vid, (date, title))
    print(f"  '{q[:40]}': {len(vids)} unique videos so far", flush=True)

# 2. pull Hindi transcripts
rows = []
for i, (vid, (date, title)) in enumerate(vids.items()):
    try:
        f = api.fetch(vid, languages=["hi", "en", "en-IN"])
        text = " ".join(s.text for s in f)
        if len(text) > 500:
            year = int(date[:4]) if date and date[:4].isdigit() else None
            rows.append({"video_id": vid, "date": date, "year": year,
                         "title": title, "text": text})
    except Exception:
        pass
    if (i + 1) % 20 == 0:
        print(f"    ...{i+1}/{len(vids)} checked, {len(rows)} with transcripts", flush=True)
    time.sleep(0.3)

df = pd.DataFrame(rows).sort_values("date") if rows else pd.DataFrame()
df.to_csv(OUT, index=False)
print(f"\nSaved {len(df)} Kejriwal speeches with transcripts -> {OUT}")
if len(df):
    print("By year:\n", df["year"].value_counts().sort_index().to_string())
