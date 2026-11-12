-- scenes/portfolio.lua (Revision 2 — Europa Universalis V Inspired Gallery Grid & Left Ledger Dock)

local Theme         = require("ui.theme")
local Widgets       = require("ui.widgets")
local HUD           = require("ui.hud")
local Cities        = require("data.cities")
local Artworks      = require("data.artworks")
local GameState     = require("sim.game_state")
local WorldMapScene = require("scenes.world_map")

local PortfolioScene = {}

function PortfolioScene.draw(app)
    local state = app.state
    local sw, sh = love.graphics.getDimensions()
    local player = GameState.getActivePlayer(state)

    -- Keep subtle map backdrop
    WorldMapScene.drawMapCanvas(state, player.city_id, nil)
    love.graphics.setColor(0.04, 0.05, 0.09, 0.65)
    love.graphics.rectangle("fill", 0, HUD.TOP_HEIGHT, sw, sh - HUD.TOP_HEIGHT)

    local top = HUD.TOP_HEIGHT + 10
    local avail_h = sh - HUD.TOP_HEIGHT - HUD.BOTTOM_HEIGHT - 22

    -- =========================================================================
    -- 1. LEFT DOCKED EU5 LEDGER & HOUSE STANDINGS (380px wide)
    -- =========================================================================
    local dock_x = 12
    local dock_w = 380
    Widgets.drawCard(dock_x, top, dock_w, avail_h, {
        bg = Theme.colors.bg_panel,
        border = Theme.colors.gold,
        header_height = 40,
        title = "IMPERIAL TREASURY & HOUSES"
    })

    local ix = dock_x + 14
    local iw = dock_w - 28
    local iy = top + 50

    local estate_val = GameState.getEstateValue(player, 1.0)
    local inv_val = GameState.getInventoryValue(state, player, 1.0)
    local art_val, auth_count, forgery_count, loaned_count = GameState.getArtPortfolioStats(player)
    local nw = GameState.getNetWorth(state, player)

    local rows = {
        { "Liquid Gold",             Theme.formatGold(player.cash), Theme.colors.gold_bright },
        { "Colonial Estates",        Theme.formatGold(estate_val),  Theme.colors.parchment },
        { "Warehouse Commodities",   Theme.formatGold(inv_val),     Theme.colors.parchment },
        { "Authentic Masterpieces",  Theme.formatGold(art_val) .. string.format(" (%d/%d)", auth_count, state.target_artworks), Theme.colors.emerald },
        { "Syndicate Debt",          "-" .. Theme.formatGold(player.loan), player.loan > 0 and Theme.colors.crimson or Theme.colors.muted },
        { "NET WORTH (Goal " .. Theme.formatGold(state.target_net_worth) .. ")", Theme.formatGold(nw), Theme.colors.gold_bright },
    }

    for i, r in ipairs(rows) do
        local ry = iy + (i - 1) * 26
        love.graphics.setColor(Theme.colors.bg_inset)
        love.graphics.rectangle("fill", ix, ry, iw, 22, 3, 3)
        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.print(r[1], ix + 8, ry + 4)
        love.graphics.setColor(r[3])
        love.graphics.printf(r[2], ix + 8, ry + 4, iw - 16, "right")
    end

    iy = iy + #rows * 26 + 16
    love.graphics.setFont(Theme.fonts.h2)
    love.graphics.setColor(Theme.colors.gold_bright)
    love.graphics.print("Competing Trading Houses", ix, iy)

    iy = iy + 26
    for i, p in ipairs(state.players) do
        local py = iy + (i - 1) * 66
        local p_art_val, p_auth, p_forg = GameState.getArtPortfolioStats(p)
        local p_nw = GameState.getNetWorth(state, p)
        local p_city = Cities.by_id[p.city_id] or Cities.list[1]

        Widgets.drawCard(ix, py, iw, 60, {
            bg = (p.id == player.id) and { 0.14, 0.20, 0.30, 0.96 } or Theme.colors.bg_inset,
            border = (p.id == player.id) and Theme.colors.gold_bright or Theme.colors.border_subtle,
            ornate = false
        })

        Widgets.drawPortrait(p, ix + 6, py + 6, 46, 48, { is_high = (p.id == player.id) })
        Widgets.drawShield(p_city.key, ix + iw - 40, py + 8, 32, 38)

        love.graphics.setFont(Theme.fonts.body_lg)
        love.graphics.setColor(Theme.colors.parchment)
        love.graphics.print(p.name, ix + 60, py + 7)

        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.gold_bright)
        love.graphics.print("Net Worth: " .. Theme.formatGold(p_nw), ix + 60, py + 25)

        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.print(string.format("Originals: %d/%d  •  Forgeries: %d", p_auth, state.target_artworks, p_forg), ix + 60, py + 41)
    end

    -- =========================================================================
    -- 2. RIGHT GALLERY GRID: REAL CREATIVE COMMONS MASTERPIECES
    -- =========================================================================
    local gx = dock_x + dock_w + 12
    local gw = sw - gx - 12
    Widgets.drawCard(gx, top, gw, avail_h, {
        bg = Theme.colors.bg_panel,
        border = Theme.colors.gold,
        header_height = 40,
        title = string.format("RECOVERED OLD MASTER GALLERY (%d AUTHENTIC  •  %d ON MUSEUM LOAN)", auth_count, loaned_count)
    })

    if #player.portfolio == 0 then
        love.graphics.setFont(Theme.fonts.h2)
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.printf(
            "Your Gallery Walls Await Their First Masterpiece.\n\nVisit the Auction Salon [3] in London, Paris, Berlin, or New York to bid on works by Vermeer, Rembrandt, Rubens, Dürer, Cranach, Hals, Bosch, and Bruegel.",
            gx + 60, top + 180, gw - 120, "center"
        )
    else
        local cols = 4
        local pad = 14
        local cell_w = math.floor((gw - pad * (cols + 1)) / cols)
        local cell_h = math.min(255, math.floor((avail_h - 68) / 2))

        for idx, owned in ipairs(player.portfolio) do
            if idx <= 8 then
                local col = (idx - 1) % cols
                local row = math.floor((idx - 1) / cols)
                local cx = gx + pad + col * (cell_w + pad)
                local cy = top + 52 + row * (cell_h + 10)
                local art = Artworks.by_id[owned.id]
                local is_auth = Artworks.isAuthentic(art)

                Widgets.drawCard(cx, cy, cell_w, cell_h, {
                    bg = Theme.colors.bg_inset,
                    border = is_auth and Theme.colors.gold_dim or Theme.colors.crimson,
                    ornate = false
                })

                local pw = math.min(cell_w - 24, math.floor((cell_h - 82) * 0.86))
                local ph = cell_h - 82
                Widgets.drawPaintingCanvas(art, cx + math.floor((cell_w - pw) / 2), cy + 8, pw, ph)

                love.graphics.setFont(Theme.fonts.small)
                love.graphics.setColor(Theme.colors.parchment)
                love.graphics.printf(art.title:sub(1, 24), cx + 6, cy + ph + 12, cell_w - 12, "center")

                love.graphics.setColor(is_auth and Theme.colors.emerald or Theme.colors.crimson)
                love.graphics.printf(
                    is_auth and ("Original • " .. Theme.formatGold(art.base_value)) or "Forgery (0 G)",
                    cx + 6, cy + ph + 28, cell_w - 12, "center"
                )

                if is_auth then
                    local roy = math.floor(art.base_value * 0.035)
                    Widgets.button("gal_loan_" .. idx,
                        owned.on_museum_loan and string.format("On Loan (+%dG/m)", roy) or "Loan to Museum",
                        cx + 10, cy + cell_h - 32, cell_w - 20, 24,
                        function()
                            owned.on_museum_loan = not owned.on_museum_loan
                            Theme.playSfx("coin")
                        end,
                        { style = owned.on_museum_loan and "success" or "default", font = Theme.fonts.small }
                    )
                end
            end
        end
    end
end

return PortfolioScene
