-- sim/auction.lua
-- Live bidding state machine, AI bidder personality/valuation logic

local Cities    = require("data.cities")
local Artworks  = require("data.artworks")
local GameState = require("sim.game_state")
local Economy   = require("sim.economy")

local Auction = {}

function Auction.createSession(state, city_id)
    city_id = city_id or GameState.getActivePlayer(state).city_id
    local city = Cities.by_id[city_id] or Cities.list[1]
    local lot = state.city_auctions[city_id]

    if not lot and #state.artwork_pool > 0 then
        GameState.refreshCityAuctions(state, true)
        lot = state.city_auctions[city_id]
    end
    if not lot then
        return nil, "No artworks currently cataloged for auction in " .. city.name .. "."
    end

    local art = Artworks.by_id[lot.artwork_id]
    if not art then
        return nil, "Catalog entry missing."
    end

    local local_base = math.floor(art.base_value * city.exchange_index)
    local increment = math.max(100, math.floor((local_base * 0.05) / 50) * 50)
    local opening_bid = lot.opening_bid or math.floor(local_base * 0.60)

    -- Compute each AI rival's hidden valuation and bluff threshold for this canvas
    local ai_profiles = {}
    for _, p in ipairs(state.players) do
        if p.is_ai then
            local factor = 0.78 + (p.aggression or 0.65) * 0.35 + (GameState.random(state) - 0.4) * 0.25
            -- If the painting is a forgery (Byte 6 > 0), experienced AI connoisseurs may suspect it
            if art.forgery > 0 then
                local detect_roll = GameState.randomInt(state, 120, 245)
                if detect_roll >= art.forgery then
                    -- Rival suspects a fake: either drops out early or only bluffs low
                    factor = (GameState.random(state) < (p.bluff_chance or 0.2)) and 0.68 or 0.0
                end
            end
            local max_bid = math.min(math.floor(p.cash * 0.82), math.floor(local_base * factor))
            ai_profiles[p.id] = {
                max_bid = max_bid,
                paddle_up = false,
                status_text = (max_bid > opening_bid) and "Studying catalog" or "Uninterested",
                cooldown = 0.4 + GameState.random(state) * 0.7
            }
        end
    end

    local session = {
        city_id = city_id,
        city = city,
        artwork_id = art.id,
        artwork = art,
        local_base_value = local_base,
        opening_bid = opening_bid,
        current_bid = opening_bid,
        increment = increment,
        high_bidder_id = nil,
        high_bidder_name = "Floor Reserve",
        phase = "bidding", -- "bidding", "sold", "passed"
        gavel_stage = 0,   -- 0 = Open, 1 = Going Once, 2 = Going Twice, 3 = Sold/Passed
        gavel_timer = 0,
        gavel_interval = 2.0,
        ai_profiles = ai_profiles,
        feed = {
            string.format("Auctioneer: 'Lot #%02d — %s by %s (%d). Opening reserve: %d Gold!'",
                art.id + 1, art.title, art.artist_name, art.epoch_year, opening_bid)
        }
    }

    return session, nil
end

function Auction.getNextBidAmount(session, mult)
    mult = mult or 1
    if not session.high_bidder_id then
        return session.opening_bid
    end
    return session.current_bid + session.increment * mult
end

function Auction.placeBid(state, session, player, mult, onSfx)
    if session.phase ~= "bidding" then
        return false, "Bidding has already closed."
    end
    if session.high_bidder_id == player.id then
        return false, "You already hold the highest bid!"
    end

    local bid_amount = Auction.getNextBidAmount(session, mult or 1)
    if player.cash < bid_amount then
        return false, string.format("Insufficient cash (%d G required).", bid_amount)
    end

    session.current_bid = bid_amount
    session.high_bidder_id = player.id
    session.high_bidder_name = player.name
    session.gavel_stage = 0
    session.gavel_timer = 0

    for pid, prof in pairs(session.ai_profiles) do
        prof.paddle_up = (pid == player.id)
        if pid == player.id then
            prof.status_text = "Bid " .. tostring(bid_amount) .. " G!"
        elseif prof.max_bid < bid_amount + session.increment then
            prof.status_text = "Out / Shaking head"
        else
            prof.status_text = "Considering..."
            prof.cooldown = 0.55 + GameState.random(state) * 0.75
        end
    end

    table.insert(session.feed, 1, string.format("%s raises paddle: %d Gold!", player.name, bid_amount))
    while #session.feed > 8 do table.remove(session.feed) end

    if onSfx then onSfx("paddle") end
    return true, string.format("Bid placed: %d G", bid_amount)
end

function Auction.passLot(state, session, onSfx)
    if session.phase ~= "bidding" then return end
    -- Let remaining AI bidders finish instantly against each other
    local safety = 0
    while safety < 25 do
        safety = safety + 1
        local best_ai = nil
        local next_amt = Auction.getNextBidAmount(session, 1)
        for _, p in ipairs(state.players) do
            if p.is_ai and session.high_bidder_id ~= p.id then
                local prof = session.ai_profiles[p.id]
                if prof and prof.max_bid >= next_amt and p.cash >= next_amt then
                    best_ai = p
                    break
                end
            end
        end
        if best_ai then
            Auction.placeBid(state, session, best_ai, 1, nil)
        else
            break
        end
    end
    Auction.finalizeLot(state, session, onSfx)
end

function Auction.finalizeLot(state, session, onSfx)
    if session.phase ~= "bidding" then return end
    session.gavel_stage = 3
    if session.high_bidder_id then
        session.phase = "sold"
        local winner = state.players[session.high_bidder_id]
        winner.cash = winner.cash - session.current_bid
        winner.total_auctions_won = (winner.total_auctions_won or 0) + 1
        local is_auth = Artworks.isAuthentic(session.artwork)
        if not is_auth then
            winner.forgeries_bought = (winner.forgeries_bought or 0) + 1
        end
        table.insert(winner.portfolio, {
            id = session.artwork.id,
            purchase_price = session.current_bid,
            purchase_city_id = session.city_id,
            purchase_date = GameState.getFormattedDate(state),
            on_museum_loan = false,
            authenticity_known = true
        })
        GameState.removeArtworkFromPool(state, session.artwork.id, winner.id)

        local auth_tag = is_auth and "AUTHENTIC MASTERPIECE ($00)" or string.format("FORGERY EXPOSED ($%02X)!", session.artwork.forgery)
        table.insert(session.feed, 1, string.format("SOLD to %s for %d Gold! [%s]",
            winner.name, session.current_bid, auth_tag))

        GameState.addTelegram(state, "AUCTION RESULT: " .. session.city.name:upper(),
            string.format("STOP. %s ACQUIRED '%s' (%s) FOR %d GOLD IN %s. %s. STOP.",
                winner.name:upper(), session.artwork.title:upper(), session.artwork.artist_name:upper(),
                session.current_bid, session.city.name:upper(), auth_tag))

        Economy.checkEndConditions(state)
    else
        session.phase = "passed"
        state.city_auctions[session.city_id] = nil
        table.insert(session.feed, 1, "Lot withdrawn — Reserve not met.")
    end
    if onSfx then onSfx("gavel_sold") end
end

function Auction.update(state, session, dt, onSfx)
    if not session or session.phase ~= "bidding" then return end

    -- 1. Update AI rival bidding timers
    local next_amt = Auction.getNextBidAmount(session, 1)
    for _, p in ipairs(state.players) do
        if p.is_ai then
            local prof = session.ai_profiles[p.id]
            if prof and session.high_bidder_id ~= p.id then
                prof.cooldown = prof.cooldown - dt
                if prof.cooldown <= 0 then
                    prof.cooldown = 0.65 + GameState.random(state) * 0.85
                    if prof.max_bid >= next_amt and p.cash >= next_amt then
                        Auction.placeBid(state, session, p, 1, onSfx)
                        return
                    else
                        prof.status_text = "Passed"
                        prof.paddle_up = false
                    end
                end
            end
        end
    end

    -- 2. Advance Gavel Countdown
    session.gavel_timer = session.gavel_timer + dt
    if session.gavel_timer >= session.gavel_interval then
        session.gavel_timer = session.gavel_timer - session.gavel_interval
        session.gavel_stage = session.gavel_stage + 1
        if session.gavel_stage == 1 then
            table.insert(session.feed, 1, string.format("Auctioneer: '%d Gold — Going once...'", session.current_bid))
            if onSfx then onSfx("gavel_tap") end
        elseif session.gavel_stage == 2 then
            table.insert(session.feed, 1, string.format("Auctioneer: '%d Gold — Going twice...!'", session.current_bid))
            if onSfx then onSfx("gavel_tap") end
        elseif session.gavel_stage >= 3 then
            Auction.finalizeLot(state, session, onSfx)
        end
    end
end

return Auction
