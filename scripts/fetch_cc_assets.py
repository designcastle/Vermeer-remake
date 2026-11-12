#!/usr/bin/env python3
"""
Downloads Creative Commons / Public Domain Old Master paintings and historical portraits
from Wikipedia & Wikimedia Commons APIs for Vermeer Remake v2.
"""
import os
import ssl
import json
import time
import urllib.request
import urllib.parse

BASE_DIR = "/Users/wwilk/Projects/Game develeopment/Vermeer remake v2/assets"
PAINTINGS_DIR = os.path.join(BASE_DIR, "paintings")
UI_DIR = os.path.join(BASE_DIR, "ui")
PORTRAITS_DIR = os.path.join(BASE_DIR, "portraits")

os.makedirs(PAINTINGS_DIR, exist_ok=True)
os.makedirs(UI_DIR, exist_ok=True)
os.makedirs(PORTRAITS_DIR, exist_ok=True)

CTX = ssl.create_default_context()
CTX.check_hostname = False
CTX.verify_mode = ssl.CERT_NONE

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) VermeerRemake/2.0"
}

SEARCH_QUERIES = [
    (0,  "Girl with a Pearl Earring Vermeer"),
    (1,  "The Milkmaid Vermeer"),
    (2,  "View of Delft Vermeer"),
    (3,  "The Astronomer Vermeer"),
    (4,  "The Art of Painting Vermeer"),
    (5,  "The Little Street Vermeer"),
    (6,  "Woman Holding a Balance Vermeer"),
    (7,  "The Lacemaker Vermeer"),
    (8,  "The Night Watch Rembrandt"),
    (9,  "The Anatomy Lesson of Dr. Nicolaes Tulp"),
    (10, "Syndics of the Drapers' Guild Rembrandt"),
    (11, "The Storm on the Sea of Galilee Rembrandt"),
    (12, "The Jewish Bride Rembrandt"),
    (13, "Self-Portrait with Two Circles Rembrandt"),
    (14, "The Return of the Prodigal Son Rembrandt"),
    (15, "The Man with the Golden Helmet"),
    (16, "The Descent from the Cross Rubens"),
    (17, "The Garden of Love Rubens"),
    (18, "The Hippopotamus and Crocodile Hunt Rubens"),
    (19, "Massacre of the Innocents Rubens"),
    (20, "Samson and Delilah Rubens"),
    (21, "The Three Graces Rubens"),
    (22, "Le Chapeau de Paille Rubens"),
    (23, "An Autumn Landscape with a View of Het Steen"),
    (24, "Self-Portrait (Dürer, Munich)"),
    (25, "Young Hare Dürer"),
    (26, "Adoration of the Magi Dürer"),
    (27, "Feast of the Rosary Dürer"),
    (28, "Praying Hands Dürer"),
    (29, "The Four Apostles Dürer"),
    (30, "Melencolia I"),
    (31, "Portrait of Hieronymus Holzschuher"),
    (32, "Cupid Complaining to Venus Cranach"),
    (33, "Judith with the Head of Holofernes Cranach"),
    (34, "The Fountain of Youth Cranach"),
    (35, "Martin Luther Lucas Cranach"),
    (36, "The Judgment of Paris Cranach"),
    (37, "Adam and Eve Cranach"),
    (38, "Sibylle of Cleves Cranach"),
    (39, "The Nymph of the Spring Cranach"),
    (40, "Laughing Cavalier Frans Hals"),
    (41, "Malle Babbe Frans Hals"),
    (42, "The Gypsy Girl Frans Hals"),
    (43, "The Banquet of the Officers of the St George Militia Company in 1616"),
    (44, "The Lute Player Frans Hals"),
    (45, "Marriage Portrait of Isaac Massa and Beatrix van der Laen"),
    (46, "Regents of the Old Men's Almshouse Frans Hals"),
    (47, "Young Man with a Skull Frans Hals"),
    (48, "The Garden of Earthly Delights"),
    (49, "Triptych of the Temptation of St. Anthony"),
    (50, "The Haywain Triptych"),
    (51, "Ship of Fools Bosch"),
    (52, "The Last Judgment (Bosch triptych)"),
    (53, "Cutting the Stone Bosch"),
    (54, "The Wayfarer Bosch"),
    (55, "Christ Carrying the Cross (Bosch, Ghent)"),
    (56, "The Hunters in the Snow"),
    (57, "The Tower of Babel (Bruegel)"),
    (58, "The Peasant Wedding"),
    (59, "Netherlandish Proverbs"),
    (60, "The Triumph of Death"),
    (61, "The Harvesters (painting)"),
    (62, "Children's Games (Bruegel)"),
    (63, "The Parable of the Blind"),
]

PORTRAIT_QUERIES = [
    ("player", "Girl with a Pearl Earring Vermeer"),
    ("gerd",   "Portrait of Georg Giese Holbein"),
    ("kurt",   "Portrait of Jakob Fugger Dürer"),
    ("baron",  "Self-Portrait (Rubens, 1623)"),
]

def search_and_download(query, out_path, width=320):
    if os.path.exists(out_path) and os.path.getsize(out_path) > 1500:
        return True
    # 1. Try Wikipedia pageimages API (very fast and reliable for famous paintings)
    wp_url = (
        "https://en.wikipedia.org/w/api.php?"
        + urllib.parse.urlencode({
            "action": "query",
            "generator": "search",
            "gsrsearch": query,
            "gsrlimit": "3",
            "prop": "pageimages",
            "piprop": "thumbnail",
            "pithumbsize": str(width),
            "format": "json"
        })
    )
    try:
        req = urllib.request.Request(wp_url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=10, context=CTX) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        pages = data.get("query", {}).get("pages", {})
        for _, pinfo in sorted(pages.items(), key=lambda kv: kv[1].get("index", 99)):
            thumb = pinfo.get("thumbnail", {}).get("source")
            if thumb:
                r2 = urllib.request.Request(thumb, headers=HEADERS)
                with urllib.request.urlopen(r2, timeout=10, context=CTX) as img_resp:
                    with open(out_path, "wb") as f:
                        f.write(img_resp.read())
                return True
    except Exception as e:
        print(f"WP warn '{query}': {e}")
    return False

if __name__ == "__main__":
    ok_count = 0
    for idx, q in SEARCH_QUERIES:
        out_file = os.path.join(PAINTINGS_DIR, f"art_{idx:02d}.jpg")
        if search_and_download(q, out_file, width=320):
            ok_count += 1
        time.sleep(0.04)
    print(f"Paintings downloaded: {ok_count}/{len(SEARCH_QUERIES)}")

    p_ok = 0
    for key, q in PORTRAIT_QUERIES:
        out_file = os.path.join(PORTRAITS_DIR, f"{key}.jpg")
        if search_and_download(q, out_file, width=240):
            p_ok += 1
    print(f"Portraits downloaded: {p_ok}/{len(PORTRAIT_QUERIES)}")
