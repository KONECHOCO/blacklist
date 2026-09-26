"""Builds curated_it.csv: numbers publicly documented as scam/aggressive telemarketing
by Italian consumer associations and press (each row keeps its source).
Never add spoofed numbers of real institutions (e.g. police), they must stay reachable."""
import csv
import os

ICT_2026 = "https://infoconsumotoscana.it/?p=2552"
ICT_2025 = "https://infoconsumotoscana.it/?p=1872"
PI = "https://www.punto-informatico.it/elenco-aggiornato-numeri-spam-diffondono-truffe-telefoniche/"
MELA = "https://www.melablog.it/chiamate-spam-in-aumento-nonostante-le-nuove-regole-i-numeri-da-bloccare-e-le-truffe-piu-diffuse/"
ADW = "https://angolodiwindows.com/2026/01/retelit-digital-services-s-p-a-il-lato-oscuro-dei-numeri-fissi-dei-call-center-molesti/"

# (national or international number, category, source)
ROWS = []

# InfoConsumo Toscana 2026: callers impersonating the Region / distributors (energy scam).
for n in """055 0173619, 055 0176823, 055 4652884, 055 4656510, 055 4656513, 055 4656751, 055 4656773, 055 4657210,
055 4657212, 055 4657302, 055 4657303, 055 4657360, 055 4658910, 055 4658934, 055 0938731, 055 0938737, 055 4652801,
055 4657307, 055 4657313, 055 4657314, 055 4657330, 055 0176082, 055 4654710, 055 4654875, 055 4656102, 055 4656112,
055 4657004, 055 4657678, 055 4657726, 0573 1860400, 055 4657920, 0586 035003, 0573 1860537, 011 19802616,
0573 1746329, 055 4654962, 055 4656164, 055 4657677, 055 4657968, 055 4658473, 055 4658549, 0586 035070, 055 4657828,
055 4658748, 055 4657679""".split(","):
    ROWS.append((n, "scam", ICT_2026))
ROWS += [("352 0575157", "scam", ICT_2026), ("055 4656903", "survey", ICT_2026)]

# InfoConsumo Toscana 2025.
for n in """346 5095540, 349 1113073, 340 6107324, 347 3824873, 347 4429070, 347 3138603, 347 8365192, 347 7786318,
340 8154573, 347 9596216, 347 3529181, 342 5969915, 347 1064556, 347 8834815, 349 0856960, 346 2536271, 331 4542772,
349 6963054, 334 5809632, 340 8629717, 334 3578275, 348 2792552, 347 3020988, 347 7464122, 347 4703762, 340 8254259,
345 5283977, 347 2412893, 345 7185663, 347 5275767, 346 8735695, 347 9140505, 342 5617258, 347 9893669, 349 2837725,
347 9123385, 340 9798816, 347 6720832, 340 8378068, 345 4415475, 333 8027356, 02 55654257, 347 6254226, 349 4293400,
345 0859668, 340 0057282, 340 5784868, 349 1152716, 340 3151789, 342 5007233, 340 1942176, 348 5109203, 347 2103555,
340 8178510, 347 6396042, 348 4942402, 348 3577451, 045 11171044, 340 9311358, 055 4654354, 055 4654322, 338 2259466,
041 2538596, 055 4654514, 055 4654590, 055 4654375""".split(","):
    ROWS.append((n, "scam", ICT_2025))
for n in ("342 0558823", "346 3533645", "347 2857020"):
    ROWS.append((n, "survey", ICT_2025))

# Press.
for n in ("02 692927527", "02 22198700", "02 80887028", "02 80887589", "02 80886927"):
    ROWS.append((n, "telemarketing", PI))
ROWS.append(("06 98235201", "telemarketing", ADW))
for n in ("02 1195589346", "02 1195588724", "02 1195589348", "02 1195588733", "02 1195588727", "02 1195589292", "02 1195588725"):
    ROWS.append((n, "scam", MELA))
ROWS += [("+49 40 655801583", "survey", MELA), ("+49 40 299961730", "scam", MELA), ("+44 161 5647042", "scam", MELA)]

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "curated_it.csv")
with open(out, "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["number", "country", "category", "source"])
    seen = set()
    for n, cat, src in ROWS:
        n = n.strip()
        if n and n not in seen:
            seen.add(n)
            w.writerow([n, "IT", cat, src])
print(len(seen), "numbers ->", out)
