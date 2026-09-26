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
