-- scenes/city_hub.lua (Revision 2 — Europa Universalis V Tabbed Left Inspector over Live Map)
-- Replaces the cluttered 4-box screen with a single clean EU5-style tabbed sidebar!

local Theme           = require("ui.theme")
local Widgets         = require("ui.widgets")
local HUD             = require("ui.hud")
local Cities          = require("data.cities")
local Commodities     = require("data.commodities")
local Artworks        = require("data.artworks")
local GameState       = require("sim.game_state")
local Economy         = require("sim.economy")
local WorldMapScene   = require("scenes.world_map")
local TutorialOverlay = require("ui.tutorial_overlay")

local CityHubScene = {
    active_tab = "estates" -- "estates", "trade", "bank"
}

function CityHubScene.enter(state)
    TutorialOverlay.triggerCallout(state, "city_hub")
end

function CityHubScene.draw(app)
    local state = app.state
    local sw, sh = love.graphics.getDimensions()
    local player = GameState.getActivePlayer(state)
    local city = Cities.by_id[player.city_id] or Cities.list[1]

    -- 1. Keep the Grand Strategy Map visible on the right!
    WorldMapScene.drawMapCanvas(state, player.city_id, function(cid)
        if cid ~= player.city_id then
            WorldMapScene.selected_city_id = cid
            app.switchScene("world_map")
        end
    end)

    -- 2. EU5-Style Left Docked Department Drawer (Single Clean Tabbed Panel)
    local dock_x = 12
    local dock_y = HUD.TOP_HEIGHT + 10
    local dock_w = 450
    local dock_h = sh - HUD.TOP_HEIGHT - HUD.BOTTOM_HEIGHT - 22

    Widgets.drawCard(dock_x, dock_y, dock_w, dock_h, {
        bg = Theme.colors.bg_panel,
        border = Theme.colors.gold,
        header_height = 42,
        title = city.name:upper() .. "  —  COLONIAL & FINANCIAL CHAMBERS",
        title_font = Theme.fonts.h2
    })

    local ix = dock_x + 14
    local iw = dock_w - 28
    local iy = dock_y + 50

    -- EU5-Style Horizontal Sub-Tabs (Only ONE clean view open at a time!)
    local tabs = {
        { id = "estates", label = "Colonial Estates" },
        { id = "trade",   label = "Commodity Market" },
        { id = "bank",    label = "Syndicate Bank" },
    }
    local tw = math.floor((iw - 12) / 3)
    for i, t in ipairs(tabs) do
        local is_act = (CityHubScene.active_tab == t.id)
        Widgets.button("hub_tab_" .. t.id, t.label, ix + (i - 1) * (tw + 6), iy, tw, 32, function()
            CityHubScene.active_tab = t.id
        end, {
            style = is_act and "tab_active" or "tab_idle",
            font = Theme.fonts.body
        })
    end

    iy = iy + 42

    -- =========================================================================
    -- TAB 1: COLONIAL ESTATES & BERLIN AGENCY (Spacious & Uncluttered)
    -- =========================================================================
    if CityHubScene.active_tab == "estates" then
        local total_acres = GameState.getTotalAcres(player)
        local worker_cost = city.has_plantation_agency and city.worker_hire_cost or 290

        Widgets.drawCard(ix, iy, iw, 68, {
            bg = Theme.colors.bg_inset,
            border = Theme.colors.border_subtle,
            ornate = false
        })

        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.parchment)
        love.graphics.print(string.format(
            "Staffing: %d Worker Brigades / %d Acres   •   Seed Stock: %s",
            player.workers, total_acres,
            player.has_hardy_seeds and "Berlin Hardy (-70% Loss)" or "Standard"
        ), ix + 10, iy + 8)

        local hw = math.floor((iw - 28) / 2)
        Widgets.button("est_worker", string.format("+1 Worker Brigade (%d G)", worker_cost),
            ix + 10, iy + 30, hw, 30,
            function()
                local ok, msg = Economy.hireWorkerBrigade(state, player)
                if ok then Theme.playSfx("coin") end
                Widgets.showToast(msg, ok and Theme.colors.emerald or Theme.colors.crimson)
            end,
            { disabled = player.cash < worker_cost, style = "primary", font = Theme.fonts.small }
        )

        Widgets.button("est_seeds",
            player.has_hardy_seeds and "Hardy Seeds Active" or (city.has_plantation_agency and "Buy Hardy Seeds (450 G)" or "Hardy Seeds (Berlin Only)"),
            ix + 18 + hw, iy + 30, hw, 30,
            function()
                local ok, msg = Economy.buyHardySeeds(state, player)
                if ok then Theme.playSfx("coin") end
                Widgets.showToast(msg, ok and Theme.colors.emerald or Theme.colors.crimson)
            end,
            {
                disabled = player.has_hardy_seeds or (not city.has_plantation_agency) or (player.cash < 450),
                style = "gold",
                font = Theme.fonts.small
            }
        )

        iy = iy + 78
        local card_h = math.floor((dock_h - (iy - dock_y) - 10) / 4)
        for _, comm in ipairs(Commodities.list) do
            local acres = player.estates[comm.key] or 0
            local local_cost = math.floor(comm.plantation_base_cost * city.exchange_index)
            local is_opt = Commodities.isOptimalMonth(comm, state.month)

            Widgets.drawCard(ix, iy, iw, card_h - 6, {
                bg = Theme.colors.bg_inset,
                border = is_opt and Theme.colors.emerald or Theme.colors.border_subtle,
                ornate = false
            })

            love.graphics.setFont(Theme.fonts.h2)
            love.graphics.setColor(comm.color)
            love.graphics.print(string.format("%s (%s)", comm.name, comm.german_id), ix + 12, iy + 8)

            love.graphics.setFont(Theme.fonts.body)
            love.graphics.setColor(Theme.colors.gold_bright)
            love.graphics.print(string.format("%d Acres Owned", acres), ix + 150, iy + 10)

            love.graphics.setFont(Theme.fonts.small)
            love.graphics.setColor(Theme.colors.parchment_dim)
            love.graphics.print(string.format("Yield: %d cwt/ac  •  Harvest: %s", comm.base_yield_cwt, comm.optimal_label), ix + 12, iy + 34)
            love.graphics.setColor(Theme.colors.muted)
            love.graphics.print("Risks: " .. table.concat(comm.risk_factors, ", "), ix + 12, iy + 52)

            Widgets.button("buy_ac_" .. comm.key, string.format("+1 Acre (%d G)", local_cost),
                ix + iw - 132, iy + math.floor((card_h - 42) / 2), 120, 34,
                function()
                    local ok, msg = Economy.buyPlantationAcre(state, player, comm.key)
                    if ok then Theme.playSfx("coin") end
                    Widgets.showToast(msg, ok and Theme.colors.emerald or Theme.colors.crimson)
                end,
                { disabled = player.cash < local_cost, style = "success", font = Theme.fonts.body }
            )

            iy = iy + card_h
        end

    -- =========================================================================
    -- TAB 2: COMMODITY EXCHANGE & SPARKLINES
    -- =========================================================================
    elseif CityHubScene.active_tab == "trade" then
        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.print(string.format("Local Exchange Multiplier in %s: %.2fx (%s)",
            city.name, city.exchange_index, city.currency_name), ix + 4, iy)

        iy = iy + 22
        local card_h = math.floor((dock_h - (iy - dock_y) - 10) / 4)
        for _, comm in ipairs(Commodities.list) do
            local cwt = player.inventory[comm.key] or 0
            local unit_price = Economy.getLocalCommodityPrice(state, comm.key, city.id)
            local hist = state.price_history[comm.key] or {}

            Widgets.drawCard(ix, iy, iw, card_h - 8, {
                bg = Theme.colors.bg_inset,
                border = Theme.colors.border_subtle,
                ornate = false
            })

            love.graphics.setFont(Theme.fonts.h2)
            love.graphics.setColor(comm.color)
            love.graphics.print(comm.name, ix + 12, iy + 8)

            love.graphics.setFont(Theme.fonts.body_lg)
            love.graphics.setColor(Theme.colors.gold_bright)
            love.graphics.print(string.format("%d G / cwt", unit_price), ix + 115, iy + 10)

            love.graphics.setFont(Theme.fonts.small)
            love.graphics.setColor(Theme.colors.parchment)
            love.graphics.print(string.format("Stock: %d cwt", cwt), ix + 12, iy + 36)

            Widgets.drawSparkline(hist, ix + 115, iy + 34, 130, card_h - 48, comm.color)

            Widgets.button("tr_sell50_" .. comm.key, "Sell 50",
                ix + iw - 164, iy + 14, 72, card_h - 34,
                function()
                    local ok, msg = Economy.sellCommodity(state, player, comm.key, 50)
                    if ok then Theme.playSfx("coin") end
                    Widgets.showToast(msg, ok and Theme.colors.emerald or Theme.colors.crimson)
                end,
                { disabled = cwt <= 0, font = Theme.fonts.small }
            )

            Widgets.button("tr_sellall_" .. comm.key, "Sell All",
                ix + iw - 86, iy + 14, 76, card_h - 34,
                function()
                    local ok, msg = Economy.sellCommodity(state, player, comm.key, cwt)
                    if ok then Theme.playSfx("coin") end
                    Widgets.showToast(msg, ok and Theme.colors.emerald or Theme.colors.crimson)
                end,
                { disabled = cwt <= 0, style = "gold", font = Theme.fonts.small }
            )

            iy = iy + card_h
        end

    -- =========================================================================
    -- TAB 3: SYNDICATE BANKING & EXPERT APPRAISAL
    -- =========================================================================
    elseif CityHubScene.active_tab == "bank" then
        local max_cred = GameState.getMaxCredit(state, player, city.id)
        local avail_cred = math.max(0, max_cred - player.loan)

        Widgets.drawCard(ix, iy, iw, 160, {
            bg = Theme.colors.bg_inset,
            border = Theme.colors.gold_dim,
            ornate = false
        })

        love.graphics.setFont(Theme.fonts.h2)
        love.graphics.setColor(Theme.colors.gold_bright)
        love.graphics.print(city.name .. " Financial Syndicate", ix + 14, iy + 12)

        love.graphics.setFont(Theme.fonts.body)
        love.graphics.setColor(Theme.colors.parchment)
        love.graphics.print(string.format("Credit Line Limit: %s   (Available: %s)", Theme.formatGold(max_cred), Theme.formatGold(avail_cred)), ix + 14, iy + 40)
        love.graphics.print(string.format("Current Debt: %s   (Monthly Interest: %.1f%%)", Theme.formatGold(player.loan), city.bank_interest_rate * 100), ix + 14, iy + 64)

        local bw = math.floor((iw - 38) / 2)
        Widgets.button("bk_b25", "Borrow 2,500 G", ix + 14, iy + 96, bw, 42, function()
            local ok, msg = Economy.takeLoan(state, player, 2500)
            if ok then Theme.playSfx("coin") end
            Widgets.showToast(msg, ok and Theme.colors.emerald or Theme.colors.crimson)
        end, { disabled = avail_cred <= 0, style = "primary" })

        Widgets.button("bk_r25", "Repay All / 2,500 G", ix + 24 + bw, iy + 96, bw, 42, function()
            local ok, msg = Economy.repayLoan(state, player, player.loan)
            if ok then Theme.playSfx("coin") end
            Widgets.showToast(msg, ok and Theme.colors.emerald or Theme.colors.crimson)
        end, { disabled = player.loan <= 0 or player.cash <= 0, style = "gold" })

        -- Local Auction Expert Card
        iy = iy + 174
        local lot = state.city_auctions[city.id]
        Widgets.drawCard(ix, iy, iw, dock_h - (iy - dock_y) - 14, {
            bg = Theme.colors.bg_inset,
            border = Theme.colors.border_subtle,
            ornate = false
        })

        love.graphics.setFont(Theme.fonts.h2)
        love.graphics.setColor(Theme.colors.gold_bright)
        love.graphics.print("Resident Art Expert: " .. city.expert_name, ix + 14, iy + 12)

        love.graphics.setFont(Theme.fonts.body)
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.printf(
            string.format("Evaluation Skill: %d / 255 (Tested against Byte 6 Forgery Quality).\nInspection Fee: %d Gold.",
                city.expert_skill, city.expert_fee),
            ix + 14, iy + 40, iw - 28, "left"
        )

        if lot then
            local art = Artworks.by_id[lot.artwork_id]
            local appr = player.appraised_ids[art.id]
            Widgets.button("bk_appraise",
                appr and "Current Lot Already Appraised" or string.format("Appraise '%s' (%d G)", art.title:sub(1, 22), city.expert_fee),
                ix + 14, iy + 96, iw - 28, 38,
                function()
                    local ok, msg = Economy.appraiseLot(state, player, art.id)
                    Widgets.showToast(msg, ok and Theme.colors.gold_bright or Theme.colors.crimson)
                end,
                { disabled = (appr ~= nil) or (player.cash < city.expert_fee), style = "gold" }
            )
        end
    end
end

return CityHubScene
