#!/usr/bin/env bash
set -euo pipefail

SOCRATA_APP_TOKEN="Q35ThLBc3i4VDX4UiKGvHVxcU"
YEAR="${1:?Usage: $0 <year>}"

DATASET="wujg-7c2s"
BASE_URL="https://data.ny.gov/resource/${DATASET}.csv"
OUT_DIR="chunks"
mkdir -p "$OUT_DIR"

urlencode() {
  python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$1"
}

for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
  if [ "$YEAR" = "2020" ] && [ "$month" = "01" ]; then
    continue
  fi

  next=$(date -d "${YEAR}-${month}-01 +1 month" +%Y-%m-%d)
  out="${OUT_DIR}/mta_${YEAR}_${month}.csv"

  if [ -s "$out" ]; then
    echo "[${YEAR}] skip  $out"
    continue
  fi

  where="transit_timestamp >= '${YEAR}-${month}-01T00:00:00' AND transit_timestamp < '${next}T00:00:00'"
  encoded=$(urlencode "$where")
  url="${BASE_URL}?\$where=${encoded}&\$limit=10000000"

  echo "[${YEAR}] fetch $out"
  curl --retry 5 --retry-delay 15 --retry-all-errors \
       --connect-timeout 60 --speed-limit 1024 --speed-time 300 \
       -fsSL \
       -H "X-App-Token: ${SOCRATA_APP_TOKEN}" \
       -o "$out" \
       "$url"
done

echo "[${YEAR}] done"

