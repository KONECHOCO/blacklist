"""Curated seed lists (seed/curated_*.csv): numbers publicly documented as scam or
aggressive telemarketing, with their source. Loaded at startup into `external`
(source CURATED, never expiring) with enough weight to be listed right away."""
import csv
import glob
import os

import phonenumbers

SOURCE = "CURATED"
SEED_DIR = os.environ.get("SEED_DIR", os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "seed"))


def load(conn, weight_for) -> int:
    rows = []
    for path in sorted(glob.glob(os.path.join(SEED_DIR, "curated_*.csv"))):
        with open(path, encoding="utf-8") as f:
            for r in csv.DictReader(f):
                country = r["country"].strip().upper()
                try:
                    num = phonenumbers.parse(r["number"], country)
                except phonenumbers.NumberParseException:
                    continue
                if not phonenumbers.is_possible_number(num):
                    continue
                e164 = phonenumbers.format_number(num, phonenumbers.PhoneNumberFormat.E164)
                rows.append((e164, country, r["category"].strip() or "other", 1, weight_for(country), SOURCE))
    conn.execute("DELETE FROM external WHERE source=?", (SOURCE,))
    conn.executemany("INSERT OR REPLACE INTO external(number,country,category,day,n,source) VALUES(?,?,?,?,?,?)", rows)
    return len(rows)
