-- scenes/title.lua (Revision 2 — Europa Universalis V Inspired Grand Strategy Title Screen)

local Theme           = require("ui.theme")
local Widgets         = require("ui.widgets")
local Artworks        = require("data.artworks")
local GameState       = require("sim.game_state")
local TutorialOverlay = require("ui.tutorial_overlay")

local TitleScene = {
    total_players = 4,
    target_artworks = 5,
    max_years = 3,
    target_net_worth = 55000
}

function TitleScene.update(dt)
end

function TitleScene.draw(app)
    local sw, sh = love.graphics.getDimensions()

    -- Draw HD Cartographic Map as atmospheric background with dark royal vignette
    if Theme.map_image then
        love.graphics.setColor(0.42, 0.45, 0.52, 1.0)
        local mw, mh = Theme.map_image:getWidth(), Theme.map_image:getHeight()
        love.graphics.draw(Theme.map_image, 0, 0, 0, sw / mw, sh / mh)
    else
        love.graphics.setColor(Theme.colors.bg_dark)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
    end

    love.graphics.setColor(0.04, 0.06, 0.10, 0.72)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Center Royal Grand Strategy Modal
    local card_w = math.min(920, sw - 80)
    local card_h = math.min(560, sh - 80)
    local cx = math.floor((sw - card_w) / 2)
    local cy = math.floor((sh - card_h) / 2)

    Widgets.drawCard(cx, cy, card_w, card_h, {
        bg = { 0.08, 0.10, 0.15, 0.97 },
        border = Theme.colors.gold_bright,
        border_width = 2,
        header_height = 68,
        title = "V E R M E E R   —   I M P E R I A L   E D I T I O N",
        title_font = Theme.fonts.title
    })

    -- Left Showcase: Real Creative Commons Masterpiece (Girl with a Pearl Earring) + 4 City Shields
    local left_w = 340
    local lx = cx + 28
    local ly = cy + 90

    local pearl_art = Artworks.by_id[0]
    Widgets.drawPaintingCanvas(pearl_art, lx + 35, ly, 230, 270)

    love.graphics.setFont(Theme.fonts.serif_sm)
    love.graphics.setColor(Theme.colors.gold_bright)
    love.graphics.printf("Johannes Vermeer — Girl with a Pearl Earring (1665)", lx, ly + 280, left_w - 20, "center")

    -- 4 Heraldic City Coats of Arms row
    local keys = { "london", "paris", "berlin", "new_york" }
    local labels = { "London", "Paris", "Berlin", "New York" }
    for i, k in ipairs(keys) do
        local sx = lx + 18 + (i - 1) * 76
        Widgets.drawShield(k, sx, ly + 312, 44, 52)
        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.printf(labels[i], sx - 10, ly + 368, 64, "center")
    end

    -- Vertical brass divider
    love.graphics.setColor(Theme.colors.gold_dim)
    love.graphics.line(cx + left_w + 24, cy + 88, cx + left_w + 24, cy + card_h - 28)

    -- Right Column: Clean, Uncluttered Campaign Configuration
    local rx = cx + left_w + 52
    local rw = card_w - left_w - 80
    local ry = cy + 94

    love.graphics.setFont(Theme.fonts.h1)
    love.graphics.setColor(Theme.colors.gold_bright)
    love.graphics.print("Uncle Walter's Testament", rx, ry)

    love.graphics.setFont(Theme.fonts.body_lg)
    love.graphics.setColor(Theme.colors.parchment_dim)
    love.graphics.printf(
        "Manage colonial plantations across Ceylon, Java, Virginia, and the Gold Coast. Arbitrage European and Wall Street exchange rates, consult Royal Academy experts to expose Van Meegeren forgeries, and recover the family's stolen Old Master collection.",
        rx, ry + 32, rw, "left"
    )

    ry = ry + 112
    love.graphics.setFont(Theme.fonts.h2)
    love.graphics.setColor(Theme.colors.gold)
    love.graphics.print("Rival Trading Houses", rx, ry)

    local p_opts = {
        { count = 2, label = "2 Houses (vs. Gerd)" },
        { count = 3, label = "3 Houses (+ Kurt)" },
        { count = 4, label = "4 Houses (+ Baron)" }
    }
    local pb_w = math.floor((rw - 16) / 3)
    for i, opt in ipairs(p_opts) do
        Widgets.button("t_p_" .. opt.count, opt.label, rx + (i - 1) * (pb_w + 8), ry + 26, pb_w, 36, function()
            TitleScene.total_players = opt.count
        end, {
            style = (TitleScene.total_players == opt.count) and "gold" or "tab_idle",
            font = Theme.fonts.body
        })
    end

    ry = ry + 78
    love.graphics.setFont(Theme.fonts.h2)
    love.graphics.setColor(Theme.colors.gold)
    love.graphics.print("Campaign Length & Legacy Target", rx, ry)

    local g_opts = {
        { arts = 3, years = 2, nw = 40000, label = "Short (3 Originals • 40k G)" },
        { arts = 5, years = 3, nw = 55000, label = "Standard (5 Originals • 55k G)" },
        { arts = 8, years = 5, nw = 85000, label = "Grand (8 Originals • 85k G)" }
    }
    for i, g in ipairs(g_opts) do
        Widgets.button("t_g_" .. g.arts, g.label, rx + (i - 1) * (pb_w + 8), ry + 26, pb_w, 36, function()
            TitleScene.target_artworks = g.arts
            TitleScene.max_years = g.years
            TitleScene.target_net_worth = g.nw
        end, {
            style = (TitleScene.target_artworks == g.arts) and "gold" or "tab_idle",
            font = Theme.fonts.small
        })
    end

    ry = ry + 84
    Widgets.button("title_start", "ENTER GRAND CAMPAIGN [Enter]", rx, ry, rw, 48, function()
        app.startNewGame({
            total_players = TitleScene.total_players,
            target_artworks = TitleScene.target_artworks,
            max_years = TitleScene.max_years,
            target_net_worth = TitleScene.target_net_worth
        })
    end, { style = "gold", font = Theme.fonts.h1, sfx = "coin" })

    ry = ry + 60
    local has_save = GameState.hasSave()
    local half_w = math.floor((rw - 12) / 2)
    Widgets.button("title_load", has_save and "Resume Saved Campaign [F9]" or "No Saved Campaign", rx, ry, half_w, 38, function()
        app.loadSavedGame()
    end, { disabled = not has_save, style = "primary" })

    Widgets.button("title_rules", "Encyclopedia & C64 Tables [H]", rx + half_w + 12, ry, half_w, 38, function()
        TutorialOverlay.toggleRulebook()
    end, { style = "default" })
end

return TitleScene
