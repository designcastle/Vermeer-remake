-- data/artworks.lua
-- Source of Truth: docs/assets.md Section 6.3 (64-Painting 8-Byte Catalog Schema)
--
-- +---------------+---------------+---------------+---------------+
-- | Byte 0: ID    | Byte 1: Artist| Bytes 2-3: Base Valuation     |
-- +---------------+---------------+---------------+---------------+
-- | Byte 4: Epoch | Byte 5: School| Byte 6: Forgery| Byte 7: State|
-- +---------------+---------------+---------------+---------------+

local Artworks = {}

Artworks.artists = {
    [1] = { id = 1, name = "Johannes Vermeer",    school = "Dutch Golden Age",      epoch = "17th C. Baroque", palette = { {0.14, 0.28, 0.56}, {0.88, 0.74, 0.28}, {0.92, 0.89, 0.80} } },
    [2] = { id = 2, name = "Rembrandt van Rijn",  school = "Dutch Golden Age",      epoch = "17th C. Baroque", palette = { {0.16, 0.11, 0.08}, {0.68, 0.44, 0.18}, {0.92, 0.78, 0.52} } },
    [3] = { id = 3, name = "Peter Paul Rubens",   school = "Flemish Baroque",       epoch = "17th C. Baroque", palette = { {0.58, 0.14, 0.16}, {0.85, 0.64, 0.48}, {0.22, 0.32, 0.42} } },
    [4] = { id = 4, name = "Albrecht Dürer",      school = "Northern Renaissance",  epoch = "16th C. High Ren.", palette = { {0.22, 0.26, 0.20}, {0.68, 0.55, 0.36}, {0.86, 0.80, 0.68} } },
    [5] = { id = 5, name = "Lucas Cranach",       school = "Northern Renaissance",  epoch = "16th C. Reformation", palette = { {0.12, 0.14, 0.18}, {0.75, 0.22, 0.20}, {0.90, 0.82, 0.68} } },
    [6] = { id = 6, name = "Frans Hals",          school = "Dutch Golden Age",      epoch = "17th C. Civic Guard", palette = { {0.15, 0.16, 0.20}, {0.76, 0.62, 0.44}, {0.88, 0.88, 0.90} } },
    [7] = { id = 7, name = "Hieronymus Bosch",    school = "Early Netherlandish",   epoch = "15th C. Late Gothic", palette = { {0.20, 0.38, 0.34}, {0.78, 0.42, 0.36}, {0.86, 0.76, 0.52} } },
    [8] = { id = 8, name = "Pieter Bruegel",      school = "Flemish Renaissance",   epoch = "16th C. Low Countries", palette = { {0.32, 0.44, 0.48}, {0.58, 0.38, 0.22}, {0.88, 0.86, 0.82} } },
}

-- 64 Catalog Entries (8 per Artist)
-- Byte 6 (forgery): 0x00 = Original Masterpiece; 0x01..0xFF = Forgery quality byte
local raw_catalog = {
    -- 1. Johannes Vermeer (IDs 0..7)
    { 0,  1, 14500, 1665, 1, 0x00, 0, "Girl with a Pearl Earring",      "portrait_pearl" },
    { 1,  1, 13200, 1658, 1, 0x00, 0, "The Milkmaid",                   "interior_window" },
    { 2,  1, 15800, 1660, 1, 0x00, 0, "View of Delft",                  "cityscape_canal" },
    { 3,  1, 11800, 1668, 1, 0x00, 0, "The Astronomer",                 "scholar_globe" },
    { 4,  1, 16500, 1666, 1, 0x00, 0, "The Art of Painting",            "studio_easel" },
    { 5,  1, 10400, 1657, 1, 0xC8, 0, "The Little Street (Attribution)", "street_brick" },
    { 6,  1, 11200, 1664, 1, 0x00, 0, "Woman Holding a Balance",        "interior_window" },
    { 7,  1,  9800, 1669, 1, 0xDC, 0, "The Lacemaker (Van Meegeren Study)", "portrait_pearl" },

    -- 2. Rembrandt van Rijn (IDs 8..15)
    { 8,  2, 16000, 1642, 1, 0x00, 0, "The Night Watch",                "group_chiaroscuro" },
    { 9,  2, 12400, 1632, 1, 0x00, 0, "Anatomy Lesson of Dr. Tulp",     "scholar_globe" },
    { 10, 2, 13800, 1662, 1, 0x00, 0, "The Syndics of the Drapers' Guild", "group_chiaroscuro" },
    { 11, 2, 14200, 1633, 1, 0x00, 0, "Storm on the Sea of Galilee",    "seascape_storm" },
    { 12, 2, 10800, 1667, 1, 0x00, 0, "The Jewish Bride",               "portrait_gold" },
    { 13, 2,  9500, 1659, 1, 0xB4, 0, "Self-Portrait with Two Circles", "portrait_gold" },
    { 14, 2, 11600, 1669, 1, 0x00, 0, "Return of the Prodigal Son",     "group_chiaroscuro" },
    { 15, 2,  8900, 1650, 1, 0xD8, 0, "Man in the Golden Helmet",       "portrait_gold" },

    -- 3. Peter Paul Rubens (IDs 16..23)
    { 16, 3, 12800, 1612, 2, 0x00, 0, "The Descent from the Cross",     "baroque_drama" },
    { 17, 3, 11500, 1635, 2, 0x00, 0, "The Garden of Love",             "pastoral_feast" },
    { 18, 3, 10900, 1617, 2, 0x00, 0, "The Hippopotamus and Crocodile Hunt", "baroque_drama" },
    { 19, 3, 13400, 1611, 2, 0x00, 0, "Massacre of the Innocents",      "baroque_drama" },
    { 20, 3,  9600, 1609, 2, 0x00, 0, "Samson and Delilah",             "interior_candle" },
    { 21, 3,  8800, 1639, 2, 0xBE, 0, "The Three Graces (Workshop)",    "pastoral_feast" },
    { 22, 3, 10200, 1626, 2, 0x00, 0, "Portrait of Susanna Lunden",     "portrait_plume" },
    { 23, 3,  9100, 1636, 2, 0xD0, 0, "Autumn Landscape at Het Steen",  "landscape_golden" },

    -- 4. Albrecht Dürer (IDs 24..31)
    { 24, 4, 13600, 1500, 3, 0x00, 0, "Self-Portrait at Twenty-Eight",  "portrait_fur" },
    { 25, 4,  9800, 1502, 3, 0x00, 0, "Young Hare",                     "nature_study" },
    { 26, 4, 12200, 1504, 3, 0x00, 0, "Adoration of the Magi",          "renaissance_arch" },
    { 27, 4, 11400, 1506, 3, 0x00, 0, "Feast of the Rosary",            "renaissance_arch" },
    { 28, 4,  8600, 1508, 3, 0xA8, 0, "Praying Hands (Folio Copy)",     "nature_study" },
    { 29, 4, 10500, 1526, 3, 0x00, 0, "The Four Apostles",              "portrait_fur" },
    { 30, 4,  9200, 1514, 3, 0x00, 0, "Melencolia I (Illuminated Plate)", "scholar_globe" },
    { 31, 4,  8400, 1521, 3, 0xC4, 0, "Portrait of Hieronymus Holzschuher", "portrait_fur" },

    -- 5. Lucas Cranach (IDs 32..39)
    { 32, 5,  9400, 1532, 3, 0x00, 0, "Venus and Cupid the Honey Thief", "court_portrait" },
    { 33, 5, 10600, 1530, 3, 0x00, 0, "Judith with the Head of Holofernes", "court_portrait" },
    { 34, 5, 11200, 1546, 3, 0x00, 0, "The Fountain of Youth",          "pastoral_feast" },
    { 35, 5,  8500, 1529, 3, 0x00, 0, "Portrait of Martin Luther",      "court_portrait" },
    { 36, 5,  8900, 1530, 3, 0xB8, 0, "The Judgment of Paris",          "pastoral_feast" },
    { 37, 5,  9700, 1526, 3, 0x00, 0, "Adam and Eve in the Garden",     "nature_study" },
    { 38, 5,  8200, 1537, 3, 0xD4, 0, "Sibylle of Cleves as Bride",     "court_portrait" },
    { 39, 5,  9100, 1533, 3, 0x00, 0, "The Nymph of the Spring",        "landscape_golden" },

    -- 6. Frans Hals (IDs 40..47)
    { 40, 6, 11800, 1624, 1, 0x00, 0, "The Laughing Cavalier",          "portrait_plume" },
    { 41, 6,  9300, 1628, 1, 0x00, 0, "Malle Babbe",                    "portrait_plume" },
    { 42, 6,  9900, 1628, 1, 0x00, 0, "The Gypsy Girl",                 "portrait_pearl" },
    { 43, 6, 12100, 1616, 1, 0x00, 0, "Banquet of the St George Civic Guard", "group_chiaroscuro" },
    { 44, 6,  8700, 1623, 1, 0xC2, 0, "The Lute Player (Haarlem Copy)", "portrait_plume" },
    { 45, 6, 10100, 1622, 1, 0x00, 0, "Marriage Portrait of Isaac Massa", "pastoral_feast" },
    { 46, 6,  9500, 1664, 1, 0x00, 0, "Regents of the Old Men's Almshouse", "group_chiaroscuro" },
    { 47, 6,  8100, 1630, 1, 0xDE, 0, "Young Man with a Skull",         "portrait_plume" },

    -- 7. Hieronymus Bosch (IDs 48..55)
    { 48, 7, 16800, 1500, 4, 0x00, 0, "The Garden of Earthly Delights", "triptych_surreal" },
    { 49, 7, 13900, 1501, 4, 0x00, 0, "The Temptation of St. Anthony",  "triptych_surreal" },
    { 50, 7, 12600, 1516, 4, 0x00, 0, "The Haywain Triptych",           "triptych_surreal" },
    { 51, 7, 10800, 1495, 4, 0x00, 0, "The Ship of Fools",              "seascape_storm" },
    { 52, 7, 13100, 1505, 4, 0x00, 0, "The Last Judgment (Vienna)",     "triptych_surreal" },
    { 53, 7,  9200, 1494, 4, 0xCC, 0, "Extraction of the Stone of Madness", "scholar_globe" },
    { 54, 7,  9600, 1502, 4, 0x00, 0, "The Wayfarer Tondo",             "landscape_golden" },
    { 55, 7,  8800, 1510, 4, 0xE0, 0, "Christ Carrying the Cross (Copy)", "baroque_drama" },

    -- 8. Pieter Bruegel (IDs 56..63)
    { 56, 8, 15200, 1565, 5, 0x00, 0, "The Hunters in the Snow",        "winter_village" },
    { 57, 8, 14800, 1563, 5, 0x00, 0, "The Tower of Babel",             "babel_tower" },
    { 58, 8, 13400, 1567, 5, 0x00, 0, "The Peasant Wedding",            "pastoral_feast" },
    { 59, 8, 12900, 1559, 5, 0x00, 0, "Netherlandish Proverbs",         "winter_village" },
    { 60, 8, 14100, 1562, 5, 0x00, 0, "The Triumph of Death",           "triptych_surreal" },
    { 61, 8, 11700, 1565, 5, 0x00, 0, "The Harvesters",                 "landscape_golden" },
    { 62, 8, 10300, 1560, 5, 0xBA, 0, "Children's Games (Antwerp Copy)", "winter_village" },
    { 63, 8, 11100, 1568, 5, 0x00, 0, "The Parable of the Blind",       "landscape_golden" },
}

Artworks.catalog = {}
Artworks.by_id = {}

for _, row in ipairs(raw_catalog) do
    local artist = Artworks.artists[row[2]]
    local entry = {
        -- Exact 8-byte C64 record fields:
        id          = row[1], -- Byte 0: 0..63
        artist_id   = row[2], -- Byte 1: 1..8
        base_value  = row[3], -- Bytes 2-3: 16-bit Base Valuation in Gold
        epoch_year  = row[4], -- Byte 4: Historical Epoch
        school_code = row[5], -- Byte 5: School Index
        forgery     = row[6], -- Byte 6: $00 = Original, $01..$FF = Forgery quality byte
        state       = row[7], -- Byte 7: Owner / Museum state
        -- Extended display metadata:
        title       = row[8],
        motif       = row[9],
        artist_name = artist.name,
        school_name = artist.school,
        epoch_name  = artist.epoch,
        palette     = artist.palette,
    }
    table.insert(Artworks.catalog, entry)
    Artworks.by_id[entry.id] = entry
end

function Artworks.isAuthentic(artwork)
    return artwork.forgery == 0x00
end

return Artworks
