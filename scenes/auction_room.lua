-- scenes/auction_room.lua (Revision 2 — Focused Grand Auction Salon Modal over World Map)

local Theme           = require("ui.theme")
local Widgets         = require("ui.widgets")
local HUD             = require("ui.hud")
local Cities          = require("data.cities")
local Artworks        = require("data.artworks")
local GameState       = require("sim.game_state")
local Economy         = require("sim.economy")
local Auction         = require("sim.auction")
local WorldMapScene   = require("scenes.world_map")
local TutorialOverlay = require("ui.tutorial_overlay")

local AuctionRoomScene = {
    session = nil,
    error_msg = nil
}

function AuctionRoomScene.enter(state)
    HUD.time_speed = 0 -- Pause map clock during live auction bidding
    TutorialOverlay.triggerCallout(state, "auction_house")
    local player = GameState.getActivePlayer(state)
    if not AuctionRoomScene.session or AuctionRoomScene.session.city_id ~= player.city_id or AuctionRoomScene.session.phase ~= "bidding" then
        local sess, err = Auction.createSession(state, player.city_id)
        AuctionRoomScene.session = sess
        AuctionRoomScene.error_msg = err
    end
end

function AuctionRoomScene.update(dt, app)
    if AuctionRoomScene.session and AuctionRoomScene.session.phase == "bidding" then
        Auction.update(app.state, AuctionRoomScene.session, dt, function(sfx_name)
            Theme.playSfx(sfx_name)
        end)
    end
end

function AuctionRoomScene.handleKeyPressed(key, app)
    local s = AuctionRoomScene.session
    if not s or s.phase ~= "bidding" then return false end
    local player = GameState.getActivePlayer(app.state)

    if key == "space" then
        local ok, msg = Auction.placeBid(app.state, s, player, 1, Theme.playSfx)
        if not ok then Widgets.showToast(msg, Theme.colors.crimson) end
        return true
    elseif key == "b" then
        local ok, msg = Auction.placeBid(app.state, s, player, 2, Theme.playSfx)
        if not ok then Widgets.showToast(msg, Theme.colors.crimson) end
        return true
    elseif key == "e" then
        local ok, msg = Economy.appraiseLot(app.state, player, s.artwork.id)
        Widgets.showToast(msg, ok and Theme.colors.gold_bright or Theme.colors.crimson)
        return true
    elseif key == "p" then
        Auction.passLot(app.state, s, Theme.playSfx)
        return true
    end
    return false
end

function AuctionRoomScene.draw(app)
    local state = app.state
    local sw, sh = love.graphics.getDimensions()
    local player = GameState.getActivePlayer(state)
    local city = Cities.by_id[player.city_id] or Cities.list[1]

    -- Draw the Grand Strategy Map in the background with a rich dark vignette
    WorldMapScene.drawMapCanvas(state, player.city_id, nil)
    love.graphics.setColor(0.03, 0.04, 0.07, 0.76)
    love.graphics.rectangle("fill", 0, HUD.TOP_HEIGHT, sw, sh - HUD.TOP_HEIGHT)

    local mw = math.min(1020, sw - 48)
    local mh = sh - HUD.TOP_HEIGHT - HUD.BOTTOM_HEIGHT - 32
    local mx = math.floor((sw - mw) / 2)
    local my = HUD.TOP_HEIGHT + 12

    local s = AuctionRoomScene.session
    if not s then
        Widgets.drawCard(mx, my, mw, mh, {
            bg = Theme.colors.bg_panel,
            border = Theme.colors.gold,
            header_height = 44,
            title = city.name:upper() .. " AUCTION SALON"
        })
        love.graphics.setFont(Theme.fonts.h1)
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.printf(AuctionRoomScene.error_msg or "No auction currently in session.", mx + 40, my + 140, mw - 80, "center")
        Widgets.button("auc_back_map", "Return to World Map [1]", mx + math.floor(mw / 2) - 120, my + 200, 240, 42, function()
            app.switchScene("world_map")
        end, { style = "gold" })
        return
    end

    Widgets.drawCard(mx, my, mw, mh, {
        bg = Theme.colors.bg_panel,
        border = Theme.colors.gold_bright,
        border_width = 2,
        header_height = 44,
        title = string.format("%s  —  LOT #%02d: %s (%d)",
            city.subtitle:match("^[^•]+"):upper(), s.artwork.id + 1, s.artwork.title:upper(), s.artwork.epoch_year),
        title_font = Theme.fonts.h2
    })

    -- Left Salon Showcase: Large Real Creative Commons Painting in Ornate Gilded Frame
    local art = s.artwork
    local left_w = 370
    local lx = mx + 24
    local ly = my + 58

    local frame_h = math.min(300, mh - 180)
    local frame_w = math.floor(frame_h * 0.86)
    local fx = lx + math.floor((left_w - frame_w) / 2)

    Widgets.drawPaintingCanvas(art, fx, ly, frame_w, frame_h)

    local py = ly + frame_h + 12
    love.graphics.setFont(Theme.fonts.h2)
    love.graphics.setColor(Theme.colors.gold_bright)
    love.graphics.printf(art.title, lx, py, left_w, "center")

    love.graphics.setFont(Theme.fonts.body_lg)
    love.graphics.setColor(Theme.colors.parchment)
    love.graphics.printf(art.artist_name .. " • " .. art.school_name, lx, py + 22, left_w, "center")

    love.graphics.setFont(Theme.fonts.small)
    love.graphics.setColor(Theme.colors.parchment_dim)
    love.graphics.printf(string.format("Catalog Est: %s   |   Local (%.2fx): %s",
        Theme.formatGold(art.base_value), city.exchange_index, Theme.formatGold(s.local_base_value)),
        lx, py + 44, left_w, "center")

    -- Right Salon Podium: Bid Status, Paddle Controls & Rival Connoisseurs
    local rx = mx + left_w + 44
    local rw = mw - left_w - 68
    local ry = my + 58

    -- High Bid & Gavel Progress Pod
    Widgets.drawCard(rx, ry, rw, 86, {
        bg = Theme.colors.bg_inset,
        border = Theme.colors.gold,
        ornate = false
    })

    love.graphics.setFont(Theme.fonts.small)
    love.graphics.setColor(Theme.colors.muted)
    love.graphics.print("CURRENT HIGH BID", rx + 16, ry + 10)

    love.graphics.setFont(Theme.fonts.title)
    love.graphics.setColor(Theme.colors.gold_bright)
    love.graphics.print(Theme.formatGold(s.current_bid), rx + 16, ry + 26)

    local stage_labels = {
        [0] = "Bidding Open — Raise Paddle to Bid",
        [1] = "GOING ONCE! (Gavel 1/3)",
        [2] = "GOING TWICE!! (Gavel 2/3)",
        [3] = (s.phase == "sold") and ("SOLD TO " .. s.high_bidder_name:upper()) or "WITHDRAWN"
    }
    local stage_colors = {
        [0] = Theme.colors.emerald,
        [1] = Theme.colors.amber,
        [2] = Theme.colors.crimson,
        [3] = Theme.colors.gold_bright
    }

    love.graphics.setFont(Theme.fonts.body_lg)
    love.graphics.setColor(s.high_bidder_id == player.id and Theme.colors.emerald or Theme.colors.parchment)
    love.graphics.print("High Bidder: " .. tostring(s.high_bidder_name), rx + 220, ry + 14)

    love.graphics.setFont(Theme.fonts.body)
    love.graphics.setColor(stage_colors[s.gavel_stage] or Theme.colors.parchment)
    love.graphics.print(stage_labels[s.gavel_stage] or "", rx + 220, ry + 38)

    if s.phase == "bidding" then
        local pct = math.min(1.0, (s.gavel_stage + (s.gavel_timer / s.gavel_interval)) / 3.0)
        love.graphics.setColor(0.04, 0.05, 0.08, 1)
        love.graphics.rectangle("fill", rx + 220, ry + 62, rw - 236, 10, 4, 4)
        love.graphics.setColor(stage_colors[s.gavel_stage] or Theme.colors.gold)
        love.graphics.rectangle("fill", rx + 220, ry + 62, (rw - 236) * pct, 10, 4, 4)
    end

    -- Paddle Action Bar
    ry = ry + 98
    local appr = player.appraised_ids[art.id]
    if s.phase == "bidding" then
        local next_1 = Auction.getNextBidAmount(s, 1)
        local next_2 = Auction.getNextBidAmount(s, 2)
        local already_high = (s.high_bidder_id == player.id)
        local bw = math.floor((rw - 24) / 4)

        Widgets.button("auc_b1", string.format("Bid %s [Space]", Theme.formatGold(next_1)),
            rx, ry, bw, 40, function()
                Auction.placeBid(state, s, player, 1, Theme.playSfx)
            end, { disabled = already_high or (player.cash < next_1), style = "gold" })

        Widgets.button("auc_b2", string.format("Jump %s [B]", Theme.formatGold(next_2)),
            rx + bw + 8, ry, bw, 40, function()
                Auction.placeBid(state, s, player, 2, Theme.playSfx)
            end, { disabled = already_high or (player.cash < next_2), style = "primary" })

        Widgets.button("auc_exp", appr and "Appraised" or string.format("Appraise (%dG) [E]", city.expert_fee),
            rx + (bw + 8) * 2, ry, bw, 40, function()
                local ok, msg = Economy.appraiseLot(state, player, art.id)
                Widgets.showToast(msg, ok and Theme.colors.gold_bright or Theme.colors.crimson)
            end, { disabled = (appr ~= nil) or (player.cash < city.expert_fee), font = Theme.fonts.small })

        Widgets.button("auc_pass", already_high and "Hammer Now [P]" or "Pass Lot [P]",
            rx + (bw + 8) * 3, ry, bw, 40, function()
                Auction.passLot(state, s, Theme.playSfx)
            end, { style = "danger" })
    else
        local half = math.floor((rw - 12) / 2)
        Widgets.button("auc_to_map", "Return to World Map [1]", rx, ry, half, 40, function()
            app.switchScene(state.game_over and "end_screen" or "world_map")
        end, { style = "primary", font = Theme.fonts.h2 })

        Widgets.button("auc_to_gal", "Inspect Art Collection [4]", rx + half + 12, ry, half, 40, function()
            app.switchScene(state.game_over and "end_screen" or "portfolio")
        end, { style = "gold", font = Theme.fonts.h2 })
    end

    -- Expert Appraisal Verdict Banner
    ry = ry + 50
    Widgets.drawCard(rx, ry, rw, 44, {
        bg = Theme.colors.bg_inset,
        border = appr and (appr.appears_authentic and Theme.colors.emerald or Theme.colors.crimson) or Theme.colors.border_subtle,
        ornate = false
    })
    love.graphics.setFont(Theme.fonts.small)
    if s.phase == "sold" then
        local is_auth = Artworks.isAuthentic(art)
        love.graphics.setColor(is_auth and Theme.colors.emerald or Theme.colors.crimson)
        love.graphics.printf(
            is_auth and "PROVENANCE VERIFIED: AUTHENTIC MASTERPIECE (Byte 6 = $00)"
                    or string.format("FORGERY EXPOSED! (Byte 6 Quality = $%02X — Worth 0 G)", art.forgery),
            rx + 12, ry + 14, rw - 24, "center"
        )
    elseif appr then
        love.graphics.setColor(appr.appears_authentic and Theme.colors.emerald or Theme.colors.crimson)
        love.graphics.printf(appr.note, rx + 12, ry + 8, rw - 24, "left")
    else
        love.graphics.setColor(Theme.colors.parchment_dim)
        love.graphics.printf(string.format("Uninspected Canvas — %s (Skill %d/255) available for %d G [Press E].",
            city.expert_name, city.expert_skill, city.expert_fee), rx + 12, ry + 14, rw - 24, "center")
    end

    -- Rival Collectors Row (with Real Portraits!)
    ry = ry + 54
    local ai_list = {}
    for _, p in ipairs(state.players) do
        if p.is_ai then table.insert(ai_list, p) end
    end
    local rcard_w = math.floor((rw - (#ai_list - 1) * 10) / math.max(1, #ai_list))
    for i, rp in ipairs(ai_list) do
        local prof = s.ai_profiles[rp.id] or {}
        Widgets.drawRivalBadge(rp, rx + (i - 1) * (rcard_w + 10), ry, rcard_w, 64, {
            is_high_bidder = (s.high_bidder_id == rp.id),
            paddle_up = prof.paddle_up,
            status_text = prof.status_text
        })
    end

    -- Compact Auction Transcript
    ry = ry + 74
    local log_h = mh - (ry - my) - 14
    if log_h > 40 then
        Widgets.drawCard(rx, ry, rw, log_h, {
            bg = Theme.colors.bg_inset,
            border = Theme.colors.border_subtle,
            ornate = false
        })
        local fy = ry + 8
        for i = 1, math.min(3, #s.feed) do
            love.graphics.setFont(i == 1 and Theme.fonts.body or Theme.fonts.small)
            love.graphics.setColor(i == 1 and Theme.colors.gold_bright or Theme.colors.parchment_dim)
            love.graphics.print(s.feed[i], rx + 12, fy)
            fy = fy + 20
        end
    end
end

return AuctionRoomScene
