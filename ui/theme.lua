-- ui/theme.lua (Revision 2 — Europa Universalis Grand Strategy Aesthetic)
-- Loads real Creative Commons Old Master paintings, heraldic shields, HD cartographic map, and fonts.

local Theme = {}

Theme.colors = {
    -- EU5-inspired dark obsidian & royal slate palette
    bg_dark       = { 0.06, 0.08, 0.11, 1.0 },
    bg_panel      = { 0.09, 0.11, 0.16, 0.95 },
    bg_header     = { 0.13, 0.18, 0.28, 0.98 },
    bg_card       = { 0.12, 0.15, 0.21, 0.94 },
    bg_card_hover = { 0.17, 0.22, 0.31, 0.98 },
    bg_inset      = { 0.06, 0.07, 0.10, 0.92 },
    parchment     = { 0.95, 0.92, 0.85, 1.0 },
    parchment_dim = { 0.74, 0.71, 0.64, 1.0 },
    ink_dark      = { 0.10, 0.09, 0.08, 1.0 },
    gold          = { 0.83, 0.68, 0.34, 1.0 },
    gold_bright   = { 0.96, 0.83, 0.46, 1.0 },
    gold_dim      = { 0.48, 0.39, 0.21, 1.0 },
    vermeer_blue  = { 0.18, 0.34, 0.58, 1.0 },
    royal_blue    = { 0.22, 0.42, 0.72, 1.0 },
    emerald       = { 0.28, 0.74, 0.46, 1.0 },
    crimson       = { 0.84, 0.30, 0.30, 1.0 },
    amber         = { 0.90, 0.62, 0.24, 1.0 },
    muted         = { 0.52, 0.56, 0.63, 1.0 },
    border_subtle = { 0.25, 0.29, 0.37, 0.85 },
}

Theme.fonts = {}
Theme.sfx = {}
Theme.shields = {}
Theme.paintings = {}
Theme.portraits = {}
Theme.map_image = nil
Theme.ornate_frame = nil
Theme.emblem = nil

local function loadFontSafe(path, size)
    if love.graphics and love.filesystem.getInfo(path) then
        local ok, f = pcall(love.graphics.newFont, path, size)
        if ok and f then return f end
    end
    if love.graphics then
        return love.graphics.newFont(size)
    end
    return nil
end

local function loadImageSafe(path)
    if not love.graphics then return nil end
    if love.filesystem.getInfo(path) then
        local ok, img = pcall(love.graphics.newImage, path)
        if ok and img then return img end
    end
    return nil
end

function Theme.init()
    Theme.fonts.title    = loadFontSafe("assets/fonts/serif.ttf", 34)
    Theme.fonts.h1       = loadFontSafe("assets/fonts/serif.ttf", 22)
    Theme.fonts.h2       = loadFontSafe("assets/fonts/serif.ttf", 17)
    Theme.fonts.serif_sm = loadFontSafe("assets/fonts/serif.ttf", 14)
    Theme.fonts.map_city = loadFontSafe("assets/fonts/serif.ttf", 18)
    Theme.fonts.body     = loadFontSafe("assets/fonts/sans.ttf", 13)
    Theme.fonts.body_lg  = loadFontSafe("assets/fonts/sans.ttf", 15)
    Theme.fonts.small    = loadFontSafe("assets/fonts/sans.ttf", 11)
    Theme.fonts.mono     = loadFontSafe("assets/fonts/sans.ttf", 12)

    local sfx_files = {
        gavel_tap  = "assets/sfx/gavel_tap.wav",
        gavel_sold = "assets/sfx/gavel_sold.wav",
        telegraph  = "assets/sfx/telegraph_click.wav",
        coin       = "assets/sfx/coin_chime.wav",
        paper      = "assets/sfx/paper_rustle.wav",
        paddle     = "assets/sfx/telegraph_click.wav"
    }
    for k, path in pairs(sfx_files) do
        if love.audio and love.filesystem.getInfo(path) then
            local ok, src = pcall(love.audio.newSource, path, "static")
            if ok and src then Theme.sfx[k] = src end
        end
    end

    Theme.emblem       = loadImageSafe("assets/gfx/emblem.png")
    Theme.ornate_frame = loadImageSafe("assets/ui/ornate_frame.png")
    Theme.map_image    = loadImageSafe("assets/ui/world_map_hd.png") or loadImageSafe("assets/ui/antique_map.jpg")

    for _, key in ipairs({ "london", "paris", "berlin", "new_york" }) do
        Theme.shields[key] = loadImageSafe("assets/ui/shield_" .. key .. ".png")
    end

    for _, pkey in ipairs({ "player", "gerd", "kurt", "baron" }) do
        Theme.portraits[pkey] = loadImageSafe("assets/portraits/" .. pkey .. ".jpg")
            or loadImageSafe("assets/portraits/" .. pkey .. ".png")
    end
end

-- Lazy-load painting image on demand so startup is instant and memory stays lean
function Theme.getPaintingImage(art_id)
    local id = art_id or 0
    if Theme.paintings[id] ~= nil then
        return Theme.paintings[id] or nil
    end
    local jpg_path = string.format("assets/paintings/art_%02d.jpg", id)
    local png_path = string.format("assets/paintings/art_%02d.png", id)
    local img = loadImageSafe(jpg_path) or loadImageSafe(png_path)
    Theme.paintings[id] = img or false
    return img
end

function Theme.playSfx(name)
    local src = Theme.sfx[name]
    if src then
        pcall(function()
            src:stop()
            src:play()
        end)
    end
end

function Theme.formatGold(amount)
    local n = math.floor((amount or 0) + 0.5)
    local sign = n < 0 and "-" or ""
    local s = tostring(math.abs(n))
    local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted .. " G"
end

return Theme
