"""Germany: the Bundesnetzagentur publishes the numbers it disconnected or sanctioned
for abuse (dialers, ping calls, spam SMS/messenger, fake hotlines...) as yearly PDFs
("Maßnahmenliste"). Imported weekly into `external` (source BNETZA, country DE)."""
import io
import logging
import re
import threading
import time
import urllib.request

import phonenumbers

log = logging.getLogger("bnetza")
SOURCE = "BNETZA"
BASE = ("https://www.bundesnetzagentur.de/SharedDocs/Downloads/DE/Sachgebiete/Telekommunikation/Verbraucher/"
        "Rufnummernmissbrauch/Massnahmenlisten/Ma%C3%9Fnahmenliste{year}.pdf?__blob=publicationFile")
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140 Safari/537.36"

_ENTRY = re.compile(r"(?:^|\s)(\d{2}\.\d{2}\.\d{4})\s", re.M)
_NUMBER = re.compile(r"(?<![\d.])(\+?0\d{6,15})(?![\d.])")


def category_for(text: str) -> str:
    t = text.lower()
    if "ping" in t or "dialer" in t or "bandansage" in t:
        return "robocall"
    if "hotline" in t or "hacking" in t or "zahlungsaufforderung" in t or "sms" in t or "messenger" in t:
        return "scam"
    if "werbung" in t:
        return "telemarketing"
    return "scam"


def parse(text: str) -> dict:
    """{e164: category} from the PDF text. Ranges ("bis") are skipped."""
    out: dict = {}
    parts = _ENTRY.split(text)
    chunks = [parts[i + 1] for i in range(1, len(parts) - 1, 2)] + [parts[-1]]
    for body in chunks:
        if " bis " in body:
            body = re.sub(r"\S+\s+bis\s+\S+", " ", body)
        category = category_for(_NUMBER.sub(" ", body))
        for raw in _NUMBER.findall(body):
            try:
                num = phonenumbers.parse(raw, "DE")
            except phonenumbers.NumberParseException:
                continue
            if phonenumbers.is_possible_number(num):
                out[phonenumbers.format_number(num, phonenumbers.PhoneNumberFormat.E164)] = category
    return out


def _download(year: int) -> bytes | None:
    req = urllib.request.Request(BASE.format(year=year), headers={"User-Agent": UA, "Accept": "application/pdf,*/*"})
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
    return data if data.startswith(b"%PDF") else None


def _text(pdf: bytes) -> str:
    from pypdf import PdfReader
    return "\n".join(page.extract_text() or "" for page in PdfReader(io.BytesIO(pdf)).pages)


def import_lists(connect, weight_for, years=None) -> int:
    this_year = time.gmtime().tm_year
    numbers: dict = {}
    for year in years or (this_year - 2, this_year - 1, this_year):
        try:
            pdf = _download(year)
        except Exception as e:  # 404 for the current year until it exists
            log.info("BNetzA %s: %s", year, e)
            continue
        if pdf:
            numbers.update(parse(_text(pdf)))
    if not numbers:
        return 0
    weight = weight_for("DE")
    conn = connect()
    try:
        conn.execute("DELETE FROM external WHERE source=?", (SOURCE,))
        conn.executemany("INSERT OR REPLACE INTO external(number,country,category,day,n,source) VALUES(?,?,?,?,?,?)",
                         [(num, "DE", cat, 1, weight, SOURCE) for num, cat in numbers.items()])
        conn.commit()
    finally:
        conn.close()
    log.info("BNetzA: %d numbers", len(numbers))
    return len(numbers)


def start_background(connect, weight_for, every_hours: float = 24 * 7) -> None:
    def loop():
        while True:
            try:
                import_lists(connect, weight_for)
            except Exception as e:
                log.warning("BNetzA import failed: %s", e)
            time.sleep(every_hours * 3600)

    threading.Thread(target=loop, name="bnetza-import", daemon=True).start()
