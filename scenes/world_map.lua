-- scenes/world_map.lua (Revision 2 — Europa Universalis V Map & Left Docked City Inspector)

local Theme     = require("ui.theme")
local Widgets   = require("ui.widgets")
local HUD       = require("ui.hud")
local Cities    = require("data.cities")
local Artworks  = require("data.artworks")
local GameState = require("sim.game_state")
local Economy   = require("sim.economy")

local WorldMapScene = {
    selected_city_id = 0,
    wave_time = 0,
    sidebar_open = true
}

function WorldMapScene.enter(state)
    local p = GameState.getActivePlayer(state)
    WorldMapScene.selected_city_id = p.city_id
end

function WorldMapScene.update(dt)
    WorldMapScene.wave_time = WorldMapScene.wave_time + dt
end

-- Shared helper so other scenes can also render the live EU5 map background!
function WorldMapScene.drawMapCanvas(state, selected_city_id, onSelectCity)
    local sw, sh = love.graphics.getDimensions()
    local player = GameState.getActivePlayer(state)

    -- 1. Full-screen HD Cartographic Map
    if Theme.map_image then
        love.graphics.setColor(0.92, 0.90, 0.86, 1.0)
        local mw, mh = Theme.map_image:getWidth(), Theme.map_image:getHeight()
        love.graphics.draw(Theme.map_image, 0, HUD.TOP_HEIGHT, 0, sw / mw, (sh - HUD.TOP_HEIGHT) / mh)
    else
        love.graphics.setColor(0.10, 0.16, 0.24, 1.0)
        love.graphics.rectangle("fill", 0, HUD.TOP_HEIGHT, sw, sh - HUD.TOP_HEIGHT)
    end

    -- Subtle cartographic graticule lines
    love.graphics.setColor(0.12, 0.15, 0.20, 0.22)
    for gx = 1, 9 do
        local lx = (gx / 10) * sw
        love.graphics.line(lx, HUD.TOP_HEIGHT, lx, sh)
    end
    for gy = 1, 5 do
        local ly = HUD.TOP_HEIGHT + (gy / 6) * (sh - HUD.TOP_HEIGHT)
        love.graphics.line(0, ly, sw, ly)
    end

    -- Map coordinates shifted slightly right so the Left EU5 Dock never covers New York or London
    local map_x0 = 395
    local map_w = sw - map_x0 - 20
    local map_y0 = HUD.TOP_HEIGHT + 20
    local map_h = sh - HUD.TOP_HEIGHT - HUD.BOTTOM_HEIGHT - 40

    local function getScreenPos(c)
        return math.floor(map_x0 + c.map_pos.x * map_w), math.floor(map_y0 + c.map_pos.y * map_h)
    end

    -- Draw Trade & Steamship Routes from Player's Current City
    local cur_city = Cities.by_id[player.city_id]
    local cur_x, cur_y = getScreenPos(cur_city)

    for _, c in ipairs(Cities.list) do
        if c.id ~= player.city_id then
            local cx, cy = getScreenPos(c)
            local is_sel = (c.id == selected_city_id)
            love.graphics.setColor(is_sel and Theme.colors.gold_bright or { 0.85, 0.78, 0.58, 0.42 })
            love.graphics.setLineWidth(is_sel and 2.8 or 1.4)
            love.graphics.line(cur_x, cur_y, cx, cy)
            love.graphics.setLineWidth(1)
        end
    end

    -- Draw Heraldic Capital Nodes on the Map
    for _, c in ipairs(Cities.list) do
        local cx, cy = getScreenPos(c)
        local is_here = (c.id == player.city_id)
        local is_sel = (c.id == selected_city_id)
        local lot = state.city_auctions[c.id]

        if is_here or is_sel then
            local r = 30 + math.sin(WorldMapScene.wave_time * 3.5) * 3
            love.graphics.setColor(is_here and Theme.colors.emerald or Theme.colors.gold_bright)
            love.graphics.setLineWidth(2.2)
            love.graphics.circle("line", cx, cy, r)
            love.graphics.setLineWidth(1)
        end

        -- Heraldic City Shield (like EU5 capital shields)
        Widgets.drawShield(c.key, cx - 20, cy - 28, 40, 46)

        -- Auction Available Gold Star Badge
        if lot then
            love.graphics.setColor(Theme.colors.gold_bright)
            love.graphics.circle("fill", cx + 20, cy - 22, 8)
            love.graphics.setColor(Theme.colors.ink_dark)
            love.graphics.setFont(Theme.fonts.small)
            love.graphics.printf("★", cx + 12, cy - 29, 16, "center")
        end

        -- City Name & Exchange Index Ribbon Button below Shield
        if onSelectCity then
            Widgets.button("map_node_" .. c.id,
                string.format("%s (%.2fx)", c.name, c.exchange_index),
                cx - 64, cy + 22, 128, 26,
                function() onSelectCity(c.id) end,
                {
                    style = is_sel and "gold" or (is_here and "success" or "default"),
                    font = Theme.fonts.small,
                    tooltip = string.format("%s — %s (Exchange %.2fx)", c.name, c.subtitle, c.exchange_index)
                }
            )
        end
    end

    -- Bottom-Right Compact EU5 Diplomatic / Telegraph Log
    local log_w = 360
    local log_h = 132
    local log_x = sw - log_w - 14
    local log_y = sh - HUD.BOTTOM_HEIGHT - log_h - 14

    Widgets.drawCard(log_x, log_y, log_w, log_h, {
        bg = { 0.06, 0.08, 0.12, 0.92 },
        border = Theme.colors.gold_dim,
        header_height = 24,
        title = "Imperial Telegraph Wire",
        title_font = Theme.fonts.small,
        ornate = false
    })

    local ty = log_y + 30
    for i = 1, math.min(3, #state.telegrams) do
        local tg = state.telegrams[i]
        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.gold_bright)
        love.graphics.print("• " .. tg.title, log_x + 10, ty)
        love.graphics.setColor(Theme.colors.parchment_dim)
        local short_body = tg.body:gsub("^STOP%.%s*", ""):sub(1, 52) .. "..."
        love.graphics.print("  " .. short_body, log_x + 10, ty + 14)
        ty = ty + 32
    end
end

function WorldMapScene.draw(app)
    local state = app.state
    local sw, sh = love.graphics.getDimensions()
    local player = GameState.getActivePlayer(state)

    -- 1. Render the full-screen EU5 Cartographic Map
    WorldMapScene.drawMapCanvas(state, WorldMapScene.selected_city_id, function(cid)
        WorldMapScene.selected_city_id = cid
    end)

    -- 2. Left Docked EU5-Style Inspector Sidebar (Clean & Uncluttered)
    local dock_x = 12
    local dock_y = HUD.TOP_HEIGHT + 10
    local dock_w = 390
    local dock_h = sh - HUD.TOP_HEIGHT - HUD.BOTTOM_HEIGHT - 22

    local sel_city = Cities.by_id[WorldMapScene.selected_city_id] or Cities.list[1]
    local route = Cities.getRoute(player.city_id, sel_city.id)

    Widgets.drawCard(dock_x, dock_y, dock_w, dock_h, {
        bg = Theme.colors.bg_panel,
        border = Theme.colors.gold,
        header_height = 42,
        title = sel_city.name:upper() .. "  —  " .. sel_city.country:upper(),
        title_font = Theme.fonts.h2
    })

    local ix = dock_x + 16
    local iw = dock_w - 32
    local iy = dock_y + 54

    -- City Heraldic Banner Card
    Widgets.drawCard(ix, iy, iw, 76, {
        bg = Theme.colors.bg_inset,
        border = Theme.colors.border_subtle,
        ornate = false
    })
    Widgets.drawShield(sel_city.key, ix + 10, iy + 11, 46, 54)

    love.graphics.setFont(Theme.fonts.serif_sm)
    love.graphics.setColor(Theme.colors.gold_bright)
    love.graphics.print(sel_city.subtitle, ix + 68, iy + 10)

    love.graphics.setFont(Theme.fonts.small)
    love.graphics.setColor(Theme.colors.parchment_dim)
    love.graphics.printf(sel_city.description, ix + 68, iy + 28, iw - 76, "left")

    -- Clean Key-Value Table (from assets.md §6.2)
    iy = iy + 88
    local stats = {
        { "Currency Exchange Index", string.format("%.2fx (%s)", sel_city.exchange_index, sel_city.currency_name), Theme.colors.gold_bright },
        { "Transit Route",           route.days == 0 and "Player Currently in City" or string.format("%s (%d d • %d G)", route.mode, route.days, route.cost), Theme.colors.parchment },
        { "Resident Art Expert",     string.format("%s (%d/255)", sel_city.expert_name, sel_city.expert_skill), Theme.colors.emerald },
        { "Syndicate Credit Terms",  string.format("%.1f%% mo • Max %d%% NW", sel_city.bank_interest_rate * 100, math.floor(sel_city.max_loan_multiplier * 100)), Theme.colors.parchment_dim },
    }
    for i, st in ipairs(stats) do
        local sy = iy + (i - 1) * 26
        love.graphics.setColor(Theme.colors.bg_inset)
        love.graphics.rectangle("fill", ix, sy, iw, 22, 3, 3)
        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.muted)
        love.graphics.print(st[1], ix + 8, sy + 4)
        love.graphics.setColor(st[3])
        love.graphics.printf(st[2], ix + 8, sy + 4, iw - 16, "right")
    end

    -- Featured Auction Lot Card with Real Creative Commons Painting
    iy = iy + 116
    local lot = state.city_auctions[sel_city.id]
    local lot_h = dock_h - (iy - dock_y) - 66
    Widgets.drawCard(ix, iy, iw, lot_h, {
        bg = Theme.colors.bg_inset,
        border = lot and Theme.colors.gold_dim or Theme.colors.border_subtle,
        ornate = false
    })

    if lot then
        local art = Artworks.by_id[lot.artwork_id]
        local ph = math.min(148, lot_h - 24)
        local pw = math.floor(ph * 0.85)
        Widgets.drawPaintingCanvas(art, ix + 12, iy + 12, pw, ph)

        local tx = ix + pw + 24
        local tw = iw - pw - 34
        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.gold_bright)
        love.graphics.print(string.format("CATALOG LOT #%02d", art.id + 1), tx, iy + 14)

        love.graphics.setFont(Theme.fonts.h2)
        love.graphics.setColor(Theme.colors.parchment)
        love.graphics.printf(art.title, tx, iy + 32, tw, "left")

        love.graphics.setFont(Theme.fonts.body)
        love.graphics.setColor(Theme.colors.gold)
        love.graphics.print(art.artist_name .. " (" .. tostring(art.epoch_year) .. ")", tx, iy + 72)

        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.emerald)
        love.graphics.print("Reserve: " .. Theme.formatGold(lot.opening_bid), tx, iy + 94)

        if sel_city.id == player.city_id then
            Widgets.button("dock_bid_now", "Open Auction Salon [3]", tx, iy + ph - 22, tw, 30, function()
                app.switchScene("auction_room")
            end, { style = "gold", font = Theme.fonts.small })
        end
    else
        love.graphics.setFont(Theme.fonts.body)
        love.graphics.setColor(Theme.colors.muted)
        love.graphics.printf("No active painting cataloged in " .. sel_city.name .. " today.\nAdvance the clock or travel to inspect other European houses.", ix + 20, iy + 42, iw - 40, "center")
    end

    -- Bottom Action Button in Dock (Travel or Open Estates/Trade Drawer)
    local btn_y = dock_y + dock_h - 48
    if sel_city.id == player.city_id then
        Widgets.button("dock_open_hub", "MANAGE ESTATES & TRADE [2]", ix, btn_y, iw, 38, function()
            app.switchScene("city_hub")
        end, { style = "primary", font = Theme.fonts.h2 })
    else
        Widgets.button("dock_travel",
            string.format("TRAVEL TO %s (%d G • %d d)", sel_city.name:upper(), route.cost, route.days),
            ix, btn_y, iw, 38,
            function()
                local ok, msg = Economy.travelToCity(state, player, sel_city.id)
                if ok then
                    Theme.playSfx("coin")
                    Widgets.showToast(msg, Theme.colors.emerald)
                    if state.game_over then app.switchScene("end_screen") end
                else
                    Widgets.showToast(msg, Theme.colors.crimson)
                end
            end,
            { disabled = player.cash < route.cost, style = "gold", font = Theme.fonts.h2 }
        )
    end
end

return WorldMapScene
