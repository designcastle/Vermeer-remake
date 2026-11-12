#!/usr/bin/env python3
"""
Generates high-DPI Europa Universalis V inspired UI textures, heraldic city shields,
resource icons, ornate frames, and a detailed cartographic world map PNG.
"""
import os
import math
import struct
import zlib

BASE_DIR = "/Users/wwilk/Projects/Game develeopment/Vermeer remake v2/assets"
UI_DIR = os.path.join(BASE_DIR, "ui")
PAINTINGS_DIR = os.path.join(BASE_DIR, "paintings")
PORTRAITS_DIR = os.path.join(BASE_DIR, "portraits")

os.makedirs(UI_DIR, exist_ok=True)
os.makedirs(PAINTINGS_DIR, exist_ok=True)
os.makedirs(PORTRAITS_DIR, exist_ok=True)

def write_png(path, width, height, rgba_bytes):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    rows = []
    stride = width * 4
    for y in range(height):
        rows.append(b"\x00" + rgba_bytes[y * stride:(y + 1) * stride])
    raw = b"".join(rows)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 6))
        + chunk(b"IEND", b"")
    )
    with open(path, "wb") as f:
        f.write(png)

def clamp_byte(v):
    return max(0, min(255, int(v)))

# 1. Generate Heraldic City Shields (like EU5's coat-of-arms badges)
def make_shield(filename, c_top, c_bot, cross_col, motif="cross"):
    w, h = 48, 56
    buf = bytearray(w * h * 4)
    for y in range(h):
        ny = y / (h - 1.0)
        # Heater shield width curve
        half_w = 21.0 if ny < 0.55 else 21.0 * math.cos((ny - 0.55) / 0.45 * (math.pi * 0.46))
        for x in range(w):
            dx = x - (w - 1) / 2.0
            adx = abs(dx)
            idx = (y * w + x) * 4
            if ny >= 0.06 and ny <= 0.96 and adx <= half_w:
                # Gold bezel border
                if adx >= half_w - 2.6 or ny <= 0.11 or ny >= 0.91:
                    shimmer = 1.0 + 0.18 * math.sin(x * 0.25 + y * 0.18)
                    buf[idx:idx+4] = bytes([
                        clamp_byte(214 * shimmer),
                        clamp_byte(175 * shimmer),
                        clamp_byte(78 * shimmer),
                        255
                    ])
                else:
                    # Interior heraldry
                    col = c_top if (ny < 0.50) else c_bot
                    if motif == "cross" and (abs(dx) < 3.6 or abs(y - h * 0.46) < 3.6):
                        col = cross_col
                    elif motif == "stripes" and (int((x + y) / 6) % 2 == 0):
                        col = cross_col
                    elif motif == "eagle" and (math.hypot(dx, y - h * 0.48) < 9.5):
                        col = cross_col
                    elif motif == "fleur" and (abs(dx) < 3.0 and abs(y - h * 0.48) < 11.0):
                        col = cross_col
                    # Subtle convex gloss
                    gloss = 1.08 - 0.32 * ny - 0.008 * adx
                    buf[idx:idx+4] = bytes([
                        clamp_byte(col[0] * gloss),
                        clamp_byte(col[1] * gloss),
                        clamp_byte(col[2] * gloss),
                        255
                    ])
    write_png(os.path.join(UI_DIR, filename), w, h, buf)

make_shield("shield_london.png",   (235, 232, 224), (225, 222, 214), (192, 38, 42),   "cross")
make_shield("shield_paris.png",    (32, 68, 148),   (24, 52, 122),   (232, 192, 68),  "fleur")
make_shield("shield_berlin.png",   (232, 196, 82),  (212, 174, 62),  (28, 28, 32),    "eagle")
make_shield("shield_new_york.png", (34, 62, 118),   (178, 42, 46),   (238, 234, 225), "stripes")

# 2. Generate Ornate Gilded Painting Frame Overlay
def make_ornate_frame():
    w, h = 240, 280
    buf = bytearray(w * h * 4)
    border = 16
    for y in range(h):
        for x in range(w):
            idx = (y * w + x) * 4
            dist = min(x, w - 1 - x, y, h - 1 - y)
            if dist < border:
                ridge = math.sin(dist / border * math.pi * 3.0)
                filigree = math.sin(x * 0.35) * math.cos(y * 0.35) * 0.15
                lum = 0.72 + 0.28 * ridge + filigree
                buf[idx:idx+4] = bytes([
                    clamp_byte(208 * lum),
                    clamp_byte(164 * lum),
                    clamp_byte(68 * lum),
                    255
                ])
            elif dist < border + 3:
                # Inner shadow mat
                buf[idx:idx+4] = bytes([18, 14, 10, 210])
    write_png(os.path.join(UI_DIR, "ornate_frame.png"), w, h, buf)

make_ornate_frame()

# 3. Generate High-Resolution EU5-Inspired Cartographic World Map (1280x720)
def value_noise(x, y, seed=42):
    xi, yi = int(math.floor(x)), int(math.floor(y))
    xf, yf = x - xi, y - yi
    def h(ix, iy):
        n = (ix * 374761393 + iy * 668265263 + seed * 1442695041) & 0xffffffff
        n = ((n ^ (n >> 13)) * 1274126177) & 0xffffffff
        return ((n ^ (n >> 16)) & 0xffff) / 65535.0
    u = xf * xf * (3.0 - 2.0 * xf)
    v = yf * yf * (3.0 - 2.0 * yf)
    a = h(xi, yi) * (1 - u) + h(xi + 1, yi) * u
    b = h(xi, yi + 1) * (1 - u) + h(xi + 1, yi + 1) * u
    return a * (1 - v) + b * v

def fbm(x, y, seed=42):
    return (
        value_noise(x, y, seed) * 0.55
        + value_noise(x * 2.1, y * 2.1, seed + 7) * 0.30
        + value_noise(x * 4.3, y * 4.3, seed + 19) * 0.15
    )

def make_cartographic_map():
    w, h = 960, 540
    buf = bytearray(w * h * 4)

    # Define landmass blobs (cx, cy, rx, ry, angle, region_color)
    # Styled like EU5's muted political parchment map!
    regions = [
        # North America (New York / New England / Atlantic Seaboard)
        (0.08, 0.22, 0.16, 0.18,  0.2, (112, 134, 104)),
        (0.14, 0.42, 0.11, 0.16, -0.3, (96, 126, 118)),
        (0.07, 0.58, 0.10, 0.18, -0.2, (124, 118, 92)),
        (0.18, 0.36, 0.06, 0.08,  0.1, (86, 132, 114)),
        # British Isles (England, Scotland, Ireland)
        (0.47, 0.32, 0.045, 0.085, -0.15, (158, 86, 82)),
        (0.45, 0.23, 0.035, 0.055,  0.10, (138, 104, 78)),
        (0.41, 0.31, 0.032, 0.052, -0.10, (98, 134, 96)),
        # France (Paris basin, Brittany, Aquitaine, Burgundy)
        (0.51, 0.49, 0.075, 0.095,  0.12, (76, 96, 148)),
        (0.46, 0.47, 0.045, 0.045,  0.00, (86, 106, 154)),
        (0.56, 0.52, 0.045, 0.065, -0.10, (116, 82, 118)),
        # Iberia (Spain & Portugal)
        (0.43, 0.68, 0.080, 0.095,  0.05, (164, 138, 76)),
        (0.38, 0.69, 0.032, 0.075,  0.02, (88, 134, 108)),
        # Low Countries (Flanders, Holland, Brabant)
        (0.55, 0.39, 0.042, 0.045,  0.20, (168, 122, 68)),
        # Germany / HRE / Prussia (Berlin, Rhine, Bavaria, Saxony)
        (0.64, 0.39, 0.085, 0.085,  0.05, (118, 128, 96)),
        (0.73, 0.36, 0.085, 0.075, -0.08, (94, 112, 124)),
        (0.65, 0.49, 0.070, 0.065,  0.10, (142, 118, 88)),
        # Bohemia / Austria / Poland / East
        (0.76, 0.48, 0.085, 0.075,  0.00, (146, 128, 88)),
        (0.84, 0.56, 0.095, 0.085,  0.00, (136, 126, 108)),
        (0.88, 0.38, 0.110, 0.120,  0.00, (124, 102, 108)),
        # Scandinavia (Denmark, Norway, Sweden)
        (0.63, 0.25, 0.030, 0.045,  0.00, (148, 92, 88)),
        (0.68, 0.13, 0.095, 0.095, -0.25, (86, 112, 138)),
        # Italy & Alps
        (0.63, 0.64, 0.045, 0.110, -0.35, (104, 138, 102)),
        (0.59, 0.57, 0.055, 0.045,  0.00, (128, 124, 116)),
    ]

    for y in range(h):
        ny = y / float(h)
        for x in range(w):
            nx = x / float(w)
            idx = (y * w + x) * 4

            n_coast = fbm(nx * 14.0, ny * 14.0, 101)
            n_detail = fbm(nx * 32.0, ny * 32.0, 202)

            best_val = -1.0
            best_col = None
            second_val = -1.0

            for rx, ry, radx, rady, ang, col in regions:
                dx = nx - rx
                dy = ny - ry
                ca, sa = math.cos(ang), math.sin(ang)
                ux = (dx * ca + dy * sa) / radx
                uy = (-dx * sa + dy * ca) / rady
                d = 1.0 - math.hypot(ux, uy) + (n_coast - 0.5) * 0.42
                if d > best_val:
                    second_val = best_val
                    best_val = d
                    best_col = col
                elif d > second_val:
                    second_val = d

            if best_val > 0.0:
                # Landmass!
                border_dist = best_val - max(0.0, second_val)
                relief = 0.88 + 0.24 * n_detail
                if best_val < 0.045:
                    # Dark coastal ink line
                    r, g, b = 36, 38, 42
                elif second_val > 0.0 and border_dist < 0.035:
                    # Political province border line (like EU5!)
                    r, g, b = int(best_col[0] * 0.55), int(best_col[1] * 0.55), int(best_col[2] * 0.55)
                else:
                    r = clamp_byte(best_col[0] * relief)
                    g = clamp_byte(best_col[1] * relief)
                    b = clamp_byte(best_col[2] * relief)
                buf[idx:idx+4] = bytes([r, g, b, 255])
            else:
                # Ocean / Bathymetry
                coastal_glow = math.exp(best_val * 7.5) if best_val > -0.35 else 0.0
                tex = 0.92 + 0.14 * n_detail
                r = clamp_byte((38 + 28 * coastal_glow) * tex)
                g = clamp_byte((54 + 36 * coastal_glow) * tex)
                b = clamp_byte((74 + 38 * coastal_glow) * tex)
                buf[idx:idx+4] = bytes([r, g, b, 255])

    write_png(os.path.join(UI_DIR, "world_map_hd.png"), w, h, buf)

make_cartographic_map()
print("Generated EU5-style shields, ornate frames, and HD cartographic map successfully.")

