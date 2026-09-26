import os, tempfile
os.environ["AGG_TTL"] = "0"
os.environ["FTC_IMPORT"] = "0"
os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "t.db")
from fastapi.testclient import TestClient
from app.main import app

def test_flow():
    with TestClient(app) as c:
        # three distinct installs push an Italian number over the threshold
        for i in range(3):
            r = c.post("/v1/reports", json={"number": "02 1234 5678", "region": "IT", "category": "telemarketing", "comment": "luce e gas", "install": f"install-{i:04d}"})
            assert r.status_code == 200 and r.json()["number"] == "+390212345678"
        # the same install reporting again does not count twice
        c.post("/v1/reports", json={"number": "+390212345678", "category": "scam", "install": "install-0000"})
        s = c.get("/v1/lookup", params={"number": "+39 02 12345678"}).json()
        assert s["reports"] == 3 and s["spam"] and s["score"] >= 7
        lst = c.get("/v1/lists/it").json()
        assert lst["numbers"][0][0] == "+390212345678"
        etag = c.get("/v1/lists/IT").headers["etag"]
        assert c.get("/v1/lists/IT", headers={"If-None-Match": etag}).status_code == 304
        # one report only: not published
        c.post("/v1/reports", json={"number": "+33612345678", "install": "install-9999"})
        assert c.get("/v1/lists/FR").json()["numbers"] == []
        assert c.post("/v1/reports", json={"number": "abc", "install": "install-0001"}).status_code == 422
        assert c.get("/v1/stats/IT").json()["spamNumbers"] == 1
        assert c.post("/remove", data={"number": "+390212345678", "email": "a@b.it", "reason": "mine"}).status_code == 200
