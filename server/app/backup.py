"""Nightly backup of the data that cannot be rebuilt (community reports, comment flags,
removal requests, allowlist). Imported data (FTC, BNetzA, curated) is re-imported
automatically and is left out to keep backups small.
Run: docker exec blacklist-api python -m app.backup   (keeps the last KEEP_DAYS files)"""
import gzip
import os
import shutil
import sqlite3
import sys
import time

DB_PATH = os.environ.get("DB_PATH", "/data/blacklist.db")
OUT_DIR = os.environ.get("BACKUP_DIR", "/data/backups")
KEEP_DAYS = int(os.environ.get("BACKUP_KEEP_DAYS", "30"))
TABLES = ("reports", "comment_flags", "removals", "allowlist")


def run() -> str:
    os.makedirs(OUT_DIR, exist_ok=True)
    stamp = time.strftime("%Y-%m-%d_%H%M", time.gmtime())
    tmp = os.path.join(OUT_DIR, f"blacklist_{stamp}.db")
    src = sqlite3.connect(DB_PATH, timeout=30)
    dst = sqlite3.connect(tmp)
    try:
        for (sql,) in src.execute("SELECT sql FROM sqlite_master WHERE type='table' AND name IN (%s)" % ",".join("?" * len(TABLES)), TABLES):
            dst.execute(sql)
        for table in TABLES:
            rows = src.execute(f"SELECT * FROM {table}").fetchall()
            if rows:
                dst.executemany(f"INSERT INTO {table} VALUES ({','.join('?' * len(rows[0]))})", rows)
        dst.commit()
    finally:
        src.close()
        dst.close()
    with open(tmp, "rb") as f, gzip.open(tmp + ".gz", "wb") as g:
        shutil.copyfileobj(f, g)
    os.remove(tmp)
    cutoff = time.time() - KEEP_DAYS * 86400
    for name in os.listdir(OUT_DIR):
        path = os.path.join(OUT_DIR, name)
        if name.startswith("blacklist_") and os.path.getmtime(path) < cutoff:
            os.remove(path)
    return tmp + ".gz"


if __name__ == "__main__":
    path = run()
    print(path, os.path.getsize(path), "bytes")
    sys.exit(0)
