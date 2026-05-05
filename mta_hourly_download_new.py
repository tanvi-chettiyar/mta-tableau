import urllib.request
import urllib.parse
import gzip
import os
from datetime import datetime

BASE = "https://data.ny.gov/resource/wujg-7c2s.csv"
APP_TOKEN = "Q35ThLBc3i4VDX4UiKGvHVxcU"

HEADERS = {
    "Accept-Encoding": "gzip",
    "X-App-Token": APP_TOKEN,
}

start = datetime(2020, 1, 1)
end   = datetime(2020, 2, 1)

def next_month(dt):
    if dt.month == 12:
        return datetime(dt.year + 1, 1, 1)
    return datetime(dt.year, dt.month + 1, 1)

cur = start
while cur < end:
    nxt = next_month(cur)
    out = f"mta_hourly_{cur:%Y_%m}.csv.gz"
    if os.path.exists(out):
        print(f"{cur:%Y-%m}  already exists, skipping")
        cur = nxt
        continue

    where = (
        f"transit_timestamp >= '{cur:%Y-%m-%dT00:00:00}'"
        f" AND transit_timestamp < '{nxt:%Y-%m-%dT00:00:00}'"
    )
    params = urllib.parse.urlencode({
        "$where": where,
        "$limit": 5000000,
    })
    url = f"{BASE}?{params}"

    print(f"{cur:%Y-%m}  downloading...", end=" ", flush=True)
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=300) as resp:
        raw = resp.read()

    # resp may already be gzip-encoded; if not, compress it
    if raw[:2] == b"\x1f\x8b":
        with open(out, "wb") as f:
            f.write(raw)
    else:
        with gzip.open(out, "wb") as f:
            f.write(raw)

    size_mb = os.path.getsize(out) / 1_048_576
    print(f"saved {out} ({size_mb:.1f} MB)")
    cur = nxt
