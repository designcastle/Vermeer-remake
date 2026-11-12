-- ui/hud.lua (Revision 2 — Europa Universalis V Inspired Top Ribbon & Bottom Map Bar)

local Theme           = require("ui.theme")
local Widgets         = require("ui.widgets")
local Cities          = require("data.cities")
local GameState       = require("sim.game_state")
local Economy         = require("sim.economy")
local TutorialOverlay = require("ui.tutorial_overlay")

local HUD = {
    TOP_HEIGHT = 56,
    BOTTOM_HEIGHT = 44,
    time_speed = 0, -- 0 = Paused (Turn-based), 1 = Normal real-time flow, 2 = Fast real-time flow
    day_accum = 0
}

function HUD.updateTime(state, dt, switchScene)
    if HUD.time_speed <= 0 or not state or state.game_over then return end
    local rate = (HUD.time_speed == 1) and 1.2 or 3.2 -- days per second
    HUD.day_accum = HUD.day_accum + dt * rate
    if HUD.day_accum >= 1.0 then
        local d = math.floor(HUD.day_accum)
        HUD.day_accum = HUD.day_accum - d
        Economy.advanceDays(state, d)
        if state.game_over and switchScene then
            HUD.time_speed = 0
            switchScene("end_screen")
        end
    end
end

function HUD.draw(state, current_scene_name, switchScene)
    if not state then return end
    local sw, sh = love.graphics.getDimensions()
    local player = GameState.getActivePlayer(state)
    local city = Cities.by_id[player.city_id] or Cities.list[1]
    local nw = GameState.getNetWorth(state, player)
    local _, auth_count = GameState.getArtPortfolioStats(player)
    local total_acres = GameState.getTotalAcres(player)

    -- =========================================================================
    -- 1. EU5-STYLE TOP IMPERIAL RIBBON BAR
    -- =========================================================================
    love.graphics.setColor(0.06, 0.08, 0.12, 0.98)
    love.graphics.rectangle("fill", 0, 0, sw, HUD.TOP_HEIGHT)
    love.graphics.setColor(Theme.colors.gold)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(0, HUD.TOP_HEIGHT, sw, HUD.TOP_HEIGHT)
    love.graphics.setLineWidth(1)

    -- Far-Left: Ornate Player Portrait + Heraldic City Shield + House Title Banner
    Widgets.drawPortrait("player", 8, 4, 46, 48, { is_high = true })
    Widgets.drawShield(city.key, 60, 4, 40, 48)

    love.graphics.setFont(Theme.fonts.h2)
    love.graphics.setColor(Theme.colors.gold_bright)
    love.graphics.print(city.name, 108, 7)

    love.graphics.setFont(Theme.fonts.small)
    love.graphics.setColor(Theme.colors.parchment_dim)
    love.graphics.print(string.format("Exchange %.2fx", city.exchange_index), 108, 30)

    -- Center: Sleek Dark Inset Resource Pills (like EU5's top bar metrics)
    local pills = {
        { label = "GOLD",       val = Theme.formatGold(player.cash), color = Theme.colors.gold_bright, w = 128 },
        { label = "DEBT",       val = Theme.formatGold(player.loan), color = player.loan > 0 and Theme.colors.crimson or Theme.colors.muted, w = 112 },
        { label = "NET WORTH",  val = Theme.formatGold(nw),          color = Theme.colors.emerald, w = 132 },
        { label = "ORIGINALS",  val = string.format("%d / %d", auth_count, state.target_artworks), color = Theme.colors.parchment, w = 96 },
        { label = "ESTATES",    val = string.format("%d ac • %d wk", total_acres, player.workers), color = Theme.colors.amber, w = 118 },
    }

    local px = 228
    for _, pill in ipairs(pills) do
        if px + pill.w < sw - 355 then
            love.graphics.setColor(Theme.colors.bg_inset)
            love.graphics.rectangle("fill", px, 8, pill.w, 40, 4, 4)
            love.graphics.setColor(Theme.colors.border_subtle)
            love.graphics.rectangle("line", px, 8, pill.w, 40, 4, 4)

            love.graphics.setFont(Theme.fonts.small)
            love.graphics.setColor(Theme.colors.muted)
            love.graphics.print(pill.label, px + 10, 11)

            love.graphics.setFont(Theme.fonts.body_lg)
            love.graphics.setColor(pill.color)
            love.graphics.print(pill.val, px + 10, 26)
            px = px + pill.w + 8
        end
    end

    -- Far-Right: EU5-Style Date & Speed Control Clock Pod
    local clock_w = 340
    local cx = sw - clock_w - 8
    love.graphics.setColor(Theme.colors.bg_inset)
    love.graphics.rectangle("fill", cx, 6, clock_w, 44, 4, 4)
    love.graphics.setColor(Theme.colors.gold_dim)
    love.graphics.rectangle("line", cx, 6, clock_w, 44, 4, 4)

    love.graphics.setFont(Theme.fonts.serif_sm)
    love.graphics.setColor(Theme.colors.parchment)
    love.graphics.print(GameState.getFormattedDate(state), cx + 12, 10)

    love.graphics.setFont(Theme.fonts.small)
    love.graphics.setColor(HUD.time_speed > 0 and Theme.colors.emerald or Theme.colors.gold)
    love.graphics.print(HUD.time_speed == 0 and "Paused [Space +5d]" or (HUD.time_speed == 1 and "Running (1x)" or "Fast (2x)"), cx + 12, 29)

    -- Speed / Step Controls
    Widgets.button("clock_pause", "||", cx + 148, 11, 28, 32, function()
        HUD.time_speed = 0
    end, { style = HUD.time_speed == 0 and "gold" or "default", font = Theme.fonts.small, tooltip = "Pause automatic calendar flow" })

    Widgets.button("clock_play1", ">", cx + 180, 11, 28, 32, function()
        HUD.time_speed = 1
    end, { style = HUD.time_speed == 1 and "success" or "default", font = Theme.fonts.small, tooltip = "Run time continuously (1x speed)" })

    Widgets.button("clock_step5", "+5d", cx + 212, 11, 42, 32, function()
        HUD.time_speed = 0
        Economy.advanceDays(state, 5)
        Theme.playSfx("telegraph")
        if state.game_over then switchScene("end_screen") end
    end, { style = "primary", font = Theme.fonts.small, tooltip = "Step forward 5 days [Space]" })

    Widgets.button("hud_save", "Save", cx + 258, 11, 40, 32, function()
        if GameState.save(state) then
            Theme.playSfx("coin")
            Widgets.showToast("Campaign saved!", Theme.colors.emerald)
        end
    end, { font = Theme.fonts.small, tooltip = "Quick Save [F5]" })

    Widgets.button("hud_help", "?", cx + 302, 11, 30, 32, function()
        TutorialOverlay.toggleRulebook()
    end, { style = "gold", font = Theme.fonts.body_lg, tooltip = "Encyclopedia & C64 Tables [H]" })

    -- =========================================================================
    -- 2. EU5-STYLE FLOATING BOTTOM-CENTER MAP MODE & SCENE BAR
    -- =========================================================================
    local bar_w = 660
    local bx = math.floor((sw - bar_w) / 2)
    local by = sh - HUD.BOTTOM_HEIGHT - 6

    Widgets.drawCard(bx, by, bar_w, HUD.BOTTOM_HEIGHT, {
        bg = { 0.07, 0.09, 0.14, 0.96 },
        border = Theme.colors.gold,
        radius = 6
    })

    local nav_items = {
        { id = "world_map",    label = "[1] World Map & City",  tooltip = "Grand Strategy Map & City Inspector" },
        { id = "city_hub",     label = "[2] Estates & Trade",   tooltip = "Plantations, Commodities & Banking Drawer" },
        { id = "auction_room", label = "[3] Auction Salon",     tooltip = "Live Old Master Bidding & Expert Appraisal" },
        { id = "portfolio",    label = "[4] Art Collection",    tooltip = "Recovered Masterpieces & House Ledger" },
    }

    local bw = 152
    for i, nav in ipairs(nav_items) do
        local is_active = (current_scene_name == nav.id)
        Widgets.button("nav_" .. nav.id, nav.label, bx + 10 + (i - 1) * (bw + 8), by + 6, bw, 32, function()
            switchScene(nav.id)
        end, {
            style = is_active and "gold" or "tab_idle",
            font = Theme.fonts.body,
            tooltip = nav.tooltip
        })
    end
end

return HUD
