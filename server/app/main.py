"""Blacklist Call Blocker — community spam-number API.

Numbers are stored in E.164. A number is published in a country list only once
enough *distinct* installs reported it (REPORT_THRESHOLD), so a single person
can't get someone else's number blocked. Anyone can ask for a removal (GDPR).
"""
import hashlib
import math
import os
import re
import sqlite3
import time
from contextlib import contextmanager
from typing import Optional

import phonenumbers
from . import bnetza, curated, ftc
from fastapi import FastAPI, Form, HTTPException, Request, Response
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

DB_PATH = os.environ.get("DB_PATH", "/data/blacklist.db")
SALT = os.environ.get("HASH_SALT", "dev-salt")
REPORT_THRESHOLD = int(os.environ.get("REPORT_THRESHOLD", "3"))
# Per-country overrides while a country's community is small, e.g. "IT=2,FR=2".
THRESHOLDS = {k.strip().upper(): int(v) for k, v in
              (pair.split("=") for pair in os.environ.get("REPORT_THRESHOLDS", "IT=2").split(",") if "=" in pair)}


def threshold_for(country) -> int:
    return THRESHOLDS.get((country or "").upper(), REPORT_THRESHOLD)
MAX_REPORTS_PER_INSTALL_DAY = 40
MAX_REPORTS_PER_IP_DAY = 120
FLAGS_TO_HIDE = 2
CATEGORIES = {"telemarketing", "scam", "trading", "survey", "debt", "sales", "silent", "robocall", "other"}

app = FastAPI(title="Blacklist API", version="1.0")
app.add_middleware(GZipMiddleware, minimum_size=1000)


# --------------------------------------------------------------------------- db
SCHEMA = """
CREATE TABLE IF NOT EXISTS reports (
  id INTEGER PRIMARY KEY,
  number TEXT NOT NULL,
  country TEXT NOT NULL,
  category TEXT NOT NULL,
  comment TEXT NOT NULL DEFAULT '',
  install TEXT NOT NULL,
  ip TEXT NOT NULL,
  created INTEGER NOT NULL,
  UNIQUE(number, install)
);
CREATE INDEX IF NOT EXISTS reports_number ON reports(number);
CREATE INDEX IF NOT EXISTS reports_country ON reports(country, created);
CREATE TABLE IF NOT EXISTS removals (
  id INTEGER PRIMARY KEY,
  number TEXT NOT NULL,
  email TEXT NOT NULL,
  reason TEXT NOT NULL,
  created INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
);
-- Numbers that must never be published (approved removals, emergency lines...).
CREATE TABLE IF NOT EXISTS allowlist (number TEXT PRIMARY KEY, note TEXT NOT NULL DEFAULT '');
-- Users flag offensive comments; a comment flagged by FLAGS_TO_HIDE installs is hidden.
CREATE TABLE IF NOT EXISTS comment_flags (
  report INTEGER NOT NULL,
  install TEXT NOT NULL,
  created INTEGER NOT NULL,
  UNIQUE(report, install)
);
"""


def connect():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


@contextmanager
def db():
    conn = connect()
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


@app.on_event("startup")
def init_db():
    os.makedirs(os.path.dirname(DB_PATH) or ".", exist_ok=True)
    with db() as conn:
        conn.executescript(SCHEMA)
        conn.executescript(ftc.SCHEMA)
        curated.load(conn, threshold_for)
    if os.environ.get("FTC_IMPORT", "1") == "1":
        ftc.start_background(connect)
        bnetza.start_background(connect, threshold_for)


# Community reports (1 each) plus external complaints (FTC, last 90 days).
SIGNALS = ("SELECT number, country, category, created AS at, 1 AS n FROM reports "
           "UNION ALL SELECT number, country, category, day AS at, n FROM external WHERE day > ? OR source IN ('CURATED','BNETZA')")


def _cutoff() -> int:
    return int(time.time()) - ftc.WINDOW_DAYS * 86400


_AGG_CACHE: dict = {}
AGG_TTL = int(os.environ.get("AGG_TTL", "600"))


def aggregate(conn, country: str, since: int = 0) -> dict:
    """{number: (total, main category)} for a country, allowlisted numbers excluded.
    Full-window results are cached for AGG_TTL seconds (the US list is large)."""
    key = (country, since)
    hit = _AGG_CACHE.get(key)
    if since == 0 and hit and time.time() - hit[0] < AGG_TTL:
        return hit[1]
    result = _aggregate(conn, country, since)
    if since == 0:
        _AGG_CACHE[key] = (time.time(), result)
    return result


def _aggregate(conn, country: str, since: int) -> dict:
    rows = conn.execute(
        f"SELECT number, category, SUM(n) AS n FROM ({SIGNALS}) WHERE country=? AND at > ? "
        "AND number NOT IN (SELECT number FROM allowlist) GROUP BY number, category",
        (_cutoff(), country, since)).fetchall()
    out: dict = {}
    for r in rows:
        total, cat, best = out.get(r["number"], (0, None, 0))
        if r["n"] > best:
            cat, best = r["category"], r["n"]
        out[r["number"]] = (total + r["n"], cat, best)
    return {k: (v[0], v[1]) for k, v in out.items()}


# ----------------------------------------------------------------------- helpers
# Comments are shown to other users: no links, contacts or abuse (App Store 1.2).
_BLOCKED_COMMENT = re.compile(
    r"https?://|www\.|\.(com|net|org|it|fr|de|ru|io)\b|@|\+?\d[\d .-]{7,}\d"
    r"|\b(fuck|shit|bitch|cunt|nigg|cazz|stronz|puttan|putain|salope|connard|scheiß|fotze|mierda|puta\b|coño|pendej|caralho|kurwa|chuj|блять|сука|хуй|пизд|orospu|siktir)",
    re.IGNORECASE)


def clean_comment(text: str) -> str:
    text = " ".join(text.split())[:140]
    return "" if _BLOCKED_COMMENT.search(text) else text


def h(value: str) -> str:
    return hashlib.sha256(f"{SALT}:{value}".encode()).hexdigest()[:32]


def normalize(raw: str, region: Optional[str]) -> tuple[str, str]:
    """Returns (E.164, ISO country) or raises 422."""
    try:
        num = phonenumbers.parse(raw, (region or "").upper() or None)
    except phonenumbers.NumberParseException:
        raise HTTPException(422, "invalid number")
    if not phonenumbers.is_possible_number(num):
        raise HTTPException(422, "invalid number")
    country = phonenumbers.region_code_for_number(num) or (region or "ZZ").upper()
    return phonenumbers.format_number(num, phonenumbers.PhoneNumberFormat.E164), country


def score_for(reporters: int) -> int:
    """1-9 scale like the community apps: 5 = one report, 7 = spam threshold."""
    if reporters <= 0:
        return 0
    return min(9, 4 + round(1.6 * math.log2(reporters + 1)))


def client_ip(request: Request) -> str:
    return request.headers.get("x-real-ip") or (request.client.host if request.client else "?")


# ------------------------------------------------------------------------ routes
@app.get("/health")
def health():
    return {"ok": True}


class ReportIn(BaseModel):
    number: str = Field(max_length=32)
    region: Optional[str] = Field(default=None, max_length=2)  # device region, for national-format numbers
    category: str = Field(default="other", max_length=20)
    comment: str = Field(default="", max_length=140)
    install: str = Field(min_length=8, max_length=64)  # random per-install id, never tied to a person


@app.post("/v1/reports")
def report(body: ReportIn, request: Request):
    number, country = normalize(body.number, body.region)
    # Lists are per *receiving* country: a +44 number calling Italians belongs to IT's list.
    if body.region and len(body.region) == 2 and body.region.isalpha():
        country = body.region.upper()
    category = body.category if body.category in CATEGORIES else "other"
    install, ip = h(body.install), h(client_ip(request))
    day_ago = int(time.time()) - 86400
    with db() as conn:
        # IP hashes only serve rate limiting: drop them after 30 days (privacy policy).
        conn.execute("UPDATE reports SET ip='' WHERE ip!='' AND created<?", (int(time.time()) - 30 * 86400,))
        if conn.execute("SELECT 1 FROM allowlist WHERE number=?", (number,)).fetchone():
            return {"ok": True, "number": number, "ignored": True}
        if conn.execute("SELECT COUNT(*) FROM reports WHERE install=? AND created>?", (install, day_ago)).fetchone()[0] >= MAX_REPORTS_PER_INSTALL_DAY \
                or conn.execute("SELECT COUNT(*) FROM reports WHERE ip=? AND created>?", (ip, day_ago)).fetchone()[0] >= MAX_REPORTS_PER_IP_DAY:
            raise HTTPException(429, "too many reports today")
        conn.execute(
            "INSERT INTO reports(number,country,category,comment,install,ip,created) VALUES(?,?,?,?,?,?,?) "
            "ON CONFLICT(number,install) DO UPDATE SET category=excluded.category, comment=excluded.comment, created=excluded.created",
            (number, country, category, clean_comment(body.comment), install, ip, int(time.time())))
    _AGG_CACHE.pop((country, 0), None)
    return {"ok": True, "number": number, "country": country}


def summary(conn, number: str, country=None) -> dict:
    rows = conn.execute(
        "SELECT id, category, comment, created, (SELECT COUNT(*) FROM comment_flags f WHERE f.report=reports.id) AS flags "
        "FROM reports WHERE number=? ORDER BY created DESC", (number,)).fetchall()
    cats: dict[str, int] = {}
    for r in rows:
        cats[r["category"]] = cats.get(r["category"], 0) + 1
    for r in conn.execute("SELECT category, SUM(n) AS n FROM external WHERE number=? AND (day > ? OR source IN ('CURATED','BNETZA')) GROUP BY category", (number, _cutoff())):
        cats[r["category"]] = cats.get(r["category"], 0) + r["n"]
    allowed = conn.execute("SELECT 1 FROM allowlist WHERE number=?", (number,)).fetchone() is not None
    reporters = 0 if allowed else sum(cats.values())
    return {
        "number": number,
        "reports": reporters,
        "score": score_for(reporters),
        "spam": reporters >= threshold_for(country),
        "category": max(cats, key=cats.get) if cats and not allowed else None,
        "categories": {} if allowed else cats,
        "lastReportedAt": rows[0]["created"] if rows and not allowed else None,
        "comments": [] if allowed else [{"id": r["id"], "category": r["category"], "text": r["comment"], "at": r["created"]}
                                       for r in rows if r["comment"] and r["flags"] < FLAGS_TO_HIDE][:10],
    }


class FlagIn(BaseModel):
    id: int
    install: str = Field(min_length=8, max_length=64)


@app.post("/v1/comments/flag")
def flag_comment(body: FlagIn):
    """Report an offensive comment; hidden for everyone after FLAGS_TO_HIDE flags."""
    with db() as conn:
        if not conn.execute("SELECT 1 FROM reports WHERE id=? AND comment!=''", (body.id,)).fetchone():
            raise HTTPException(404, "no such comment")
        conn.execute("INSERT OR IGNORE INTO comment_flags(report, install, created) VALUES(?,?,?)", (body.id, h(body.install), int(time.time())))
    return {"ok": True}


@app.get("/v1/lookup")
def lookup(number: str, region: Optional[str] = None):
    e164, country = normalize(number, region)
    with db() as conn:
        return {**summary(conn, e164, country), "country": country}


@app.get("/v1/lists/{country}")
def country_list(country: str, request: Request, response: Response):
    """Spam numbers of one country (ISO code), for the on-device block list.
    Compact rows: [e164, category, score]. Cached by the client with ETag."""
    country = country.upper()[:2]
    with db() as conn:
        totals = aggregate(conn, country)
    items = [[num, cat, score_for(n)] for num, (n, cat) in sorted(totals.items()) if n >= threshold_for(country)]
    etag = '"' + hashlib.sha1(repr(items).encode()).hexdigest()[:16] + '"'
    if request.headers.get("if-none-match") == etag:
        return Response(status_code=304)
    response.headers["ETag"] = etag
    response.headers["Cache-Control"] = "public, max-age=900"
    return {"country": country, "generatedAt": int(time.time()), "threshold": threshold_for(country), "numbers": items}


@app.get("/v1/stats/{country}")
def stats(country: str):
    country = country.upper()[:2]
    hit = _STATS_CACHE.get(country)
    if hit and time.time() - hit[0] < AGG_TTL:
        return hit[1]
    result = _stats(country)
    _STATS_CACHE[country] = (time.time(), result)
    return result


_STATS_CACHE: dict = {}


def _stats(country: str) -> dict:
    week = int(time.time()) - 7 * 86400
    with db() as conn:
        spam = sum(1 for n, _ in aggregate(conn, country).values() if n >= threshold_for(country))
        recent = aggregate(conn, country, since=week)
    top = sorted(((n, num) for num, (n, _) in recent.items() if n >= threshold_for(country)), reverse=True)[:10]
    return {"country": country, "spamNumbers": spam, "reportsThisWeek": sum(n for n, _ in recent.values()),
            "trending": [{"number": num, "reports": n, "score": score_for(n)} for n, num in top]}


# ------------------------------------------------------- removal requests (GDPR)
REMOVE_PAGE = """<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Blacklist — remove a number</title><style>body{font-family:-apple-system,system-ui,sans-serif;max-width:560px;margin:40px auto;padding:0 18px;line-height:1.5}
input,textarea,button{font:inherit;width:100%;padding:10px;margin:6px 0 14px;box-sizing:border-box}button{background:#d7263d;color:#fff;border:0;border-radius:8px}</style></head>
<body><h1>Remove my number</h1><p>If your number was reported by mistake in Blacklist Call Blocker, ask for its removal. We review every request and reply by email.</p>
<form method="post"><label>Phone number (with country code)</label><input name="number" required placeholder="+39 02 1234567">
<label>Your email</label><input name="email" type="email" required><label>Why should it be removed?</label><textarea name="reason" rows="4" required maxlength="600"></textarea>
<button>Send request</button></form><p><small>Italiano: usa questo modulo per chiedere la rimozione di un numero segnalato per errore.</small></p></body></html>"""


@app.get("/remove", response_class=HTMLResponse)
def remove_page():
    return REMOVE_PAGE


@app.post("/remove", response_class=HTMLResponse)
def remove_submit(number: str = Form(..., max_length=32), email: str = Form(..., max_length=120), reason: str = Form(..., max_length=600)):
    e164, _ = normalize(number, None)
    with db() as conn:
        conn.execute("INSERT INTO removals(number,email,reason,created) VALUES(?,?,?,?)", (e164, email.strip(), reason.strip(), int(time.time())))
    return "<!doctype html><meta charset=utf-8><p style='font-family:system-ui;margin:40px'>Request received — we will reply by email. / Richiesta ricevuta.</p>"
