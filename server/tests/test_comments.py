import os, tempfile
os.environ["AGG_TTL"] = "0"
os.environ["FTC_IMPORT"] = "0"
os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "c.db")
from fastapi.testclient import TestClient
from app.main import app, clean_comment


def test_clean_comment():
    assert clean_comment("  Offerta luce   e gas ") == "Offerta luce e gas"
    assert clean_comment("vai su www.truffa.com") == ""
    assert clean_comment("chiama il 333 123 4567") == ""
    assert clean_comment("scrivi a a@b.it") == ""
    assert clean_comment("sei uno stronzo") == ""
    assert clean_comment("Computadora Sales") == "Computadora Sales"


def test_flag_hides_comment():
    with TestClient(app) as c:
        c.post("/v1/reports", json={"number": "+390687654321", "category": "scam", "comment": "ok text", "install": "install-a001"})
        comments = c.get("/v1/lookup", params={"number": "+390687654321"}).json()["comments"]
        assert len(comments) == 1
        cid = comments[0]["id"]
        for who in ("install-f001", "install-f001", "install-f002"):
            assert c.post("/v1/comments/flag", json={"id": cid, "install": who}).status_code == 200
        assert c.get("/v1/lookup", params={"number": "+390687654321"}).json()["comments"] == []
        assert c.post("/v1/comments/flag", json={"id": 99999, "install": "install-f003"}).status_code == 404
