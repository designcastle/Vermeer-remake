-- scenes/end_screen.lua
-- Final net worth breakdown, recovered masterpieces, score summary

local Theme     = require("ui.theme")
local Widgets   = require("ui.widgets")
local Artworks  = require("data.artworks")
local GameState = require("sim.game_state")

local EndScreenScene = {}

function EndScreenScene.draw(app)
    local state = app.state
    local sw, sh = love.graphics.getDimensions()

    love.graphics.setColor(0.06, 0.08, 0.12, 1.0)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    local mw = math.min(1060, sw - 48)
    local mh = sh - 48
    local mx = math.floor((sw - mw) / 2)
    local my = 24

    local winner = state.winner or state.players[1]
    local player_won = (winner.id == 1)

    Widgets.drawCard(mx, my, mw, mh, {
        bg = { 0.11, 0.14, 0.20, 0.99 },
        border = player_won and Theme.colors.gold_bright or Theme.colors.crimson,
        border_width = 3,
        title = player_won and "VICTORY — UNCLE WALTER'S LEGACY SECURED!" or "CAMPAIGN CONCLUDED — FINAL TESTAMENT VERDICT"
    })

    love.graphics.setFont(Theme.fonts.h1)
    love.graphics.setColor(player_won and Theme.colors.emerald or Theme.colors.gold_bright)
    love.graphics.printf(state.end_reason or "The final year has come to a close.", mx + 24, my + 52, mw - 48, "center")

    -- Final Standings Table
    local ty = my + 98
    local row_h = 62
    for i, p in ipairs(state.players) do
        local ry = ty + (i - 1) * (row_h + 8)
        local art_val, auth_count, forg_count = GameState.getArtPortfolioStats(p)
        local estate_val = GameState.getEstateValue(p, 1.0)
        local nw = GameState.getNetWorth(state, p)
        local score = auth_count * 12000 + nw
        local is_win = (p.id == winner.id)

        Widgets.drawCard(mx + 24, ry, mw - 48, row_h, {
            bg = is_win and { 0.18, 0.25, 0.19, 1.0 } or { 0.09, 0.11, 0.15, 1.0 },
            border = is_win and Theme.colors.gold_bright or Theme.colors.border_subtle
        })

        love.graphics.setFont(Theme.fonts.h2)
        love.graphics.setColor(is_win and Theme.colors.gold_bright or Theme.colors.parchment)
        love.graphics.print(string.format("%s %s", is_win and "[WINNER]" or ("#" .. i), p.name), mx + 40, ry + 10)

        love.graphics.setFont(Theme.fonts.small)
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.print(string.format(
            "Authentic Masterpieces: %d (Valued %s)   •   Forgeries: %d   •   Estates: %s   •   Crop Sales: %s",
            auth_count, Theme.formatGold(art_val), forg_count, Theme.formatGold(estate_val), Theme.formatGold(p.total_crop_sales or 0)
        ), mx + 40, ry + 36)

        love.graphics.setFont(Theme.fonts.h2)
        love.graphics.setColor(Theme.colors.emerald)
        love.graphics.printf("Net Worth: " .. Theme.formatGold(nw) .. "   |   Score: " .. tostring(score),
            mx + 40, ry + 18, mw - 80, "right")
    end

    -- Showcase Player 1's Recovered Paintings
    local gy = ty + #state.players * (row_h + 8) + 12
    local gh = mh - (gy - my) - 72
    local human = state.players[1]

    if gh > 90 then
        Widgets.drawCard(mx + 24, gy, mw - 48, gh, {
            bg = { 0.08, 0.09, 0.13, 1.0 },
            border = Theme.colors.border_subtle,
            title = "Your Recovered Collection Showcase"
        })
        if #human.portfolio == 0 then
            love.graphics.setFont(Theme.fonts.body_lg)
            love.graphics.setColor(Theme.colors.muted)
            love.graphics.printf("No paintings acquired during this campaign.", mx + 40, gy + 54, mw - 80, "center")
        else
            local max_show = math.min(7, #human.portfolio)
            local card_w = math.floor((mw - 88) / max_show)
            for i = 1, max_show do
                local owned = human.portfolio[i]
                local art = Artworks.by_id[owned.id]
                local px = mx + 36 + (i - 1) * card_w
                Widgets.drawPaintingCanvas(art, px, gy + 42, math.min(110, card_w - 14), gh - 72)
                love.graphics.setFont(Theme.fonts.small)
                love.graphics.setColor(Artworks.isAuthentic(art) and Theme.colors.gold_bright or Theme.colors.crimson)
                love.graphics.printf(art.artist_name:match("([^%s]+)$"), px, gy + gh - 26, math.min(110, card_w - 14), "center")
            end
        end
    end

    -- Bottom Action Buttons
    local by = my + mh - 54
    Widgets.button("end_new_game", "START NEW CAMPAIGN", mx + math.floor(mw / 2) - 230, by, 220, 40, function()
        app.startNewGame()
    end, { style = "gold", font = Theme.fonts.h2 })

    Widgets.button("end_title", "RETURN TO TITLE SCREEN", mx + math.floor(mw / 2) + 10, by, 220, 40, function()
        app.switchScene("title")
    end, { style = "primary", font = Theme.fonts.h2 })
end

return EndScreenScene
