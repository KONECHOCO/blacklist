"""US seed data: the FTC publishes every business day the phone numbers people
reported to the National Do Not Call Registry (public domain, ftc.gov open data).
Complaints are stored per number/day/category in `external` and count like
community reports for 90 days."""
import csv
import io
import logging
import threading
import time
import urllib.error
import urllib.request
from datetime import date, datetime, timedelta, timezone

log = logging.getLogger("ftc")
URL = "https://www.ftc.gov/sites/default/files/DNC_Complaint_Numbers_{day}.csv"
WINDOW_DAYS = 90
SOURCE = "FTC"

SCHEMA = """
CREATE TABLE IF NOT EXISTS external (
  number TEXT NOT NULL,
  country TEXT NOT NULL,
  category TEXT NOT NULL,
  day INTEGER NOT NULL,
  n INTEGER NOT NULL,
  source TEXT NOT NULL,
  PRIMARY KEY (number, day, category, source)
);
CREATE INDEX IF NOT EXISTS external_country ON external(country, day);
CREATE TABLE IF NOT EXISTS external_files (name TEXT PRIMARY KEY, rows INTEGER NOT NULL, imported INTEGER NOT NULL);
"""

# FTC "Subject" -> app category.
_SUBJECTS = [
    ("debt", "debt"),
    ("pretending to be government", "scam"),
    ("technical support", "scam"),
    ("lotteries", "scam"),
    ("prizes", "scam"),
    ("warrant", "sales"),
    ("vacation", "sales"),
    ("timeshare", "sales"),
    ("home security", "sales"),
    ("home improvement", "sales"),
    ("medical", "telemarketing"),
    ("energy", "telemarketing"),
    ("solar", "telemarketing"),
    ("dropped call", "silent"),
    ("no message", "silent"),
]


def category_for(subject: str, robocall: str) -> str:
    s = (subject or "").lower()
    for needle, cat in _SUBJECTS:
        if needle in s:
            return cat
    return "robocall" if (robocall or "").strip().upper() == "Y" else "telemarketing"


def parse(text: str) -> dict:
    """{(e164, category): complaints} for one daily file."""
    counts: dict = {}
    for row in csv.DictReader(io.StringIO(text)):
        digits = "".join(ch for ch in row.get("Company_Phone_Number", "") if ch.isdigit())
        if len(digits) == 11 and digits.startswith("1"):
            digits = digits[1:]
        # NANP: 10 digits, area code and exchange never start with 0/1.
        if len(digits) != 10 or digits[0] in "01" or digits[3] in "01":
            continue
        key = ("+1" + digits, category_for(row.get("Subject", ""), row.get("Recorded_Message_Or_Robocall", "")))
        counts[key] = counts.get(key, 0) + 1
    return counts


def _download(day: date) -> str | None:
    req = urllib.request.Request(URL.format(day=day.isoformat()), headers={"User-Agent": "Mozilla/5.0 (BlacklistCallBlocker seed importer)"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            body = r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None  # weekends/holidays or not published yet
        raise
    return body if body.startswith("Company_Phone_Number") else None


def import_recent(connect, days: int = WINDOW_DAYS, today: date | None = None) -> int:
    """Imports every missing daily file of the window; returns the number of new files."""
    today = today or datetime.now(timezone.utc).date()
    new = 0
    for back in range(1, days + 1):
        day = today - timedelta(days=back)
        name = f"{SOURCE}:{day.isoformat()}"
        conn = connect()
        try:
            if conn.execute("SELECT 1 FROM external_files WHERE name=?", (name,)).fetchone():
                continue
            text = _download(day)
            if text is None:
                # Mark old missing days as done; recent ones may still be published.
                if back > 7:
                    conn.execute("INSERT OR IGNORE INTO external_files VALUES(?,?,?)", (name, 0, int(time.time())))
                    conn.commit()
                continue
            counts = parse(text)
            ts = int(datetime(day.year, day.month, day.day, tzinfo=timezone.utc).timestamp())
            conn.executemany(
                "INSERT OR REPLACE INTO external(number,country,category,day,n,source) VALUES(?,?,?,?,?,?)",
                [(num, "US", cat, ts, n, SOURCE) for (num, cat), n in counts.items()])
            conn.execute("INSERT OR REPLACE INTO external_files VALUES(?,?,?)", (name, sum(counts.values()), int(time.time())))
            conn.commit()
            new += 1
            log.info("FTC %s: %d complaints", day, sum(counts.values()))
        except Exception as e:  # network hiccups: retry next round
            log.warning("FTC %s failed: %s", day, e)
        finally:
            conn.close()
    conn = connect()
    try:
        conn.execute("DELETE FROM external WHERE day < ?", (int(time.time()) - (WINDOW_DAYS + 5) * 86400,))
        conn.commit()
    finally:
        conn.close()
    return new


def start_background(connect, every_hours: float = 6) -> None:
    def loop():
        while True:
            try:
                import_recent(connect)
            except Exception as e:
                log.warning("FTC import round failed: %s", e)
            time.sleep(every_hours * 3600)

    threading.Thread(target=loop, name="ftc-import", daemon=True).start()
