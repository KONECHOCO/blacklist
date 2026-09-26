import os, tempfile, time
os.environ["AGG_TTL"] = "0"
os.environ.setdefault("DB_PATH", os.path.join(tempfile.mkdtemp(), "f.db"))
os.environ["FTC_IMPORT"] = "0"
from datetime import date
from fastapi.testclient import TestClient
from app import ftc
from app.main import app, connect

CSV = """Company_Phone_Number,Created_Date,Violation_Date,Consumer_City,Consumer_State,Consumer_Area_Code,Subject,Recorded_Message_Or_Robocall
4342481967,2026-09-23 00:02:35,2026-09-22 18:22:00,SACRAMENTO,California,510,"Reducing your debt (credit cards, mortgage, student loans)",
4342481967,2026-09-23 00:03:35,2026-09-22 18:22:00,X,California,510,"Reducing your debt (credit cards, mortgage, student loans)",Y
4342481967,2026-09-23 00:04:35,2026-09-22 18:22:00,X,California,510,"Calls pretending to be government, businesses, or family and friends",Y
7254652032,2026-09-23 00:02:44,2026-09-22 12:00:00,LAS VEGAS,Nevada,702,Other,Y
0123456789,2026-09-23 00:02:44,2026-09-22 12:00:00,X,Nevada,702,Other,
"""


def test_parse():
    c = ftc.parse(CSV)
    assert c[("+14342481967", "debt")] == 2
    assert c[("+14342481967", "scam")] == 1
    assert c[("+17254652032", "robocall")] == 1
    assert not any(num.startswith("+10") for num, _ in c)


def test_import_counts_in_lookup_and_list(monkeypatch):
    monkeypatch.setattr(ftc, "_download", lambda day: CSV if day == date(2026, 9, 24) else None)
    monkeypatch.setattr(ftc.time, "time", lambda: time.mktime((2026, 9, 26, 0, 0, 0, 0, 0, -1)))
    with TestClient(app) as c:
        assert ftc.import_recent(connect, days=5, today=date(2026, 9, 26)) == 1
        assert ftc.import_recent(connect, days=5, today=date(2026, 9, 26)) == 0  # already imported
    import app.main as m
    monkeypatch.setattr(m.time, "time", lambda: time.mktime((2026, 9, 26, 0, 0, 0, 0, 0, -1)))
    with TestClient(app) as c:
        s = c.get("/v1/lookup", params={"number": "+14342481967"}).json()
        assert s["reports"] == 3 and s["spam"] and s["category"] == "debt"
        rows = c.get("/v1/lists/US").json()["numbers"]
        assert ["+14342481967", "debt", s["score"]] in rows
        assert all(r[0] != "+17254652032" for r in rows)  # only one complaint
        assert c.get("/v1/stats/US").json()["spamNumbers"] >= 1


def test_curated_seed_and_receiving_country():
    with TestClient(app) as c:
        s = c.get("/v1/lookup", params={"number": "055 4657828", "region": "IT"}).json()
        assert s["spam"] and s["category"] == "scam"
        rows = {r[0] for r in c.get("/v1/lists/IT").json()["numbers"]}
        assert "+390554657828" in rows and "+441615647042" in rows  # foreign scam numbers calling Italy
        assert "+390243333011" not in rows  # spoofed police number is never seeded
        c.post("/v1/reports", json={"number": "+44 7700 900123", "region": "IT", "install": "install-uk01"})
        c.post("/v1/reports", json={"number": "+44 7700 900123", "region": "IT", "install": "install-uk02"})
        assert "+447700900123" in {r[0] for r in c.get("/v1/lists/IT").json()["numbers"]}  # IT threshold is 2


def test_bnetza_parse():
    from app import bnetza
    text = """Bescheid vom Rufnummer Kategorie Maßnahme
24.09.2026
030544480600, 030544480611,
030544480612
Telefonie-Dialer Abschaltung der Rufnummern zum 01.10.2026
23.09.2026 01631143952 Spam-Messenger Abschaltung
22.09.2026 0900123456 bis 0900123499 Sonstiges Abschaltung"""
    got = bnetza.parse(text)
    assert got["+4930544480600"] == "robocall" and got["+4930544480612"] == "robocall"
    assert got["+491631143952"] == "scam"
    assert not any(k.startswith("+49900123") for k in got)  # ranges skipped
