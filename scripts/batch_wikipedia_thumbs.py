#!/usr/bin/env python3
"""
Fetches the remaining Old Master painting thumbnails from Wikipedia using batched
'titles=A|B|C...' requests (only 3 API calls total) to avoid rate limits.
"""
import os
import ssl
import json
import time
import urllib.request
import urllib.parse

BASE_DIR = "/Users/wwilk/Projects/Game develeopment/Vermeer remake v2/assets"
PAINTINGS_DIR = os.path.join(BASE_DIR, "paintings")
PORTRAITS_DIR = os.path.join(BASE_DIR, "portraits")

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

HEADERS = {
    "User-Agent": "VermeerRemakeBatch/2.0 (Educational Game Dev; mailto:dev@example.com)"
}

WIKI_ARTICLES = {
    10: "Syndics of the Drapers' Guild",
    11: "The Storm on the Sea of Galilee",
    12: "The Jewish Bride",
    13: "Self-Portrait with Two Circles",
    14: "The Return of the Prodigal Son (Rembrandt)",
    15: "The Man with the Golden Helmet",
    16: "The Descent from the Cross (Rubens, 1612–1614)",
    17: "The Garden of Love (Rubens)",
    18: "The Hippopotamus and Crocodile Hunt",
    19: "Massacre of the Innocents (Rubens)",
    20: "Samson and Delilah (Rubens)",
    21: "The Three Graces (Rubens, Madrid)",
    22: "Le Chapeau de Paille",
    23: "An Autumn Landscape with a View of Het Steen in the Early Morning",
    24: "Self-Portrait (Dürer, Munich)",
    25: "Young Hare",
    26: "Adoration of the Magi (Dürer)",
    27: "Feast of the Rosary",
    28: "Praying Hands (Dürer)",
    29: "The Four Apostles",
    30: "Melencolia I",
    31: "Portrait of Hieronymus Holzschuher",
    32: "Venus and Cupid the Honey Thief",
    33: "Judith with the Head of Holofernes (Cranach)",
    34: "The Fountain of Youth (Cranach)",
    35: "Martin Luther",
    36: "The Judgment of Paris (Cranach)",
    37: "Adam and Eve (Cranach)",
    38: "Sibylle of Cleves",
    39: "Lucas Cranach the Elder",
    40: "Laughing Cavalier",
    41: "Malle Babbe",
    42: "Frans Hals",
    43: "The Banquet of the Officers of the St George Militia Company in 1616",
    44: "The Lute Player (Hals)",
    45: "Marriage Portrait of Isaac Massa and Beatrix van der Laen",
    46: "Regents of the Old Men's Almshouse",
    47: "Young Man with a Skull",
    48: "The Garden of Earthly Delights",
    49: "Triptych of the Temptation of St. Anthony",
    50: "The Haywain Triptych",
    51: "Ship of Fools (painting)",
    52: "The Last Judgment (Bosch triptych)",
    63: "The Parable of the Blind",
}

def fetch_batch(batch_items):
    titles_str = "|".join(t for _, t in batch_items)
    url = (
        "https://en.wikipedia.org/w/api.php?"
        + urllib.parse.urlencode({
            "action": "query",
            "titles": titles_str,
            "redirects": "1",
            "prop": "pageimages",
            "piprop": "thumbnail",
            "pithumbsize": "320",
            "format": "json"
        })
    )
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=15, context=CTX) as resp:
        data = json.loads(resp.read().decode("utf-8"))

    q = data.get("query", {})
    norm_map = {n["from"]: n["to"] for n in q.get("normalized", [])}
    redir_map = {r["from"]: r["to"] for r in q.get("redirects", [])}
    thumb_by_title = {}
    for _, pinfo in q.get("pages", {}).items():
        t = pinfo.get("title")
        src = pinfo.get("thumbnail", {}).get("source")
        if t and src:
            thumb_by_title[t] = src

    got = 0
    for idx, orig_t in batch_items:
        out_jpg = os.path.join(PAINTINGS_DIR, f"art_{idx:02d}.jpg")
        if os.path.exists(out_jpg) and os.path.getsize(out_jpg) > 1500:
            got += 1
            continue
        t = norm_map.get(orig_t, orig_t)
        t = redir_map.get(t, t)
        src = thumb_by_title.get(t)
        if src:
            try:
                r2 = urllib.request.Request(src, headers=HEADERS)
                with urllib.request.urlopen(r2, timeout=12, context=CTX) as ir:
                    with open(out_jpg, "wb") as f:
                        f.write(ir.read())
                got += 1
                time.sleep(0.18)
            except Exception as e:
                print(f"Thumb {idx} err: {e}")
    return got

if __name__ == "__main__":
    items = list(WIKI_ARTICLES.items())
    total_got = 0
    for i in range(0, len(items), 15):
        total_got += fetch_batch(items[i:i+15])
        time.sleep(0.5)
    print(f"Batch fetched {total_got} additional real paintings.")

