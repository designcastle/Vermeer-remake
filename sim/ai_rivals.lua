-- sim/ai_rivals.lua
-- Opponent turn decision-making (travel, bidding, estate investment)

local Cities      = require("data.cities")
local Commodities = require("data.commodities")
local Artworks    = require("data.artworks")
local GameState   = require("sim.game_state")

local AIRivals = {}

function AIRivals.processDailyTurns(state)
    -- Rivals take strategic economic actions every 5 days
    if (state.turn % 5) ~= 0 then return end

    for _, p in ipairs(state.players) do
        if p.is_ai then
            AIRivals.takeAction(state, p)
        end
    end
end

function AIRivals.takeAction(state, p)
    local city = Cities.by_id[p.city_id] or Cities.list[1]

    -- 1. Sell accumulated commodities if in a strong exchange city (Berlin 1.15x or New York 1.40x) or low on cash
    for _, comm in ipairs(Commodities.list) do
        local cwt = p.inventory[comm.key] or 0
        if cwt >= 60 and (city.exchange_index >= 1.15 or p.cash < 4000) then
            local unit_price = math.max(1, math.floor((state.market_prices[comm.key] or comm.base_market_price) * city.exchange_index + 0.5))
            local revenue = cwt * unit_price
            p.inventory[comm.key] = 0
            p.cash = p.cash + revenue
            p.total_crop_sales = (p.total_crop_sales or 0) + revenue
        end
    end

    -- 2. Expand plantations & workers if cash reserves are healthy
    local total_acres = GameState.getTotalAcres(p)
    if p.workers < total_acres and p.cash > 1500 then
        p.cash = p.cash - 220
        p.workers = p.workers + 1
    end

    if total_acres < 6 and p.cash > 7500 and GameState.random(state) < 0.45 then
        local pref_key = p.preferred_commodity or "coffee"
        local comm = Commodities.by_key[pref_key] or Commodities.list[1]
        local cost = math.floor(comm.plantation_base_cost * city.exchange_index)
        if p.cash >= cost + 3500 then
            p.cash = p.cash - cost
            p.estates[comm.key] = (p.estates[comm.key] or 0) + 1
            p.workers = p.workers + 1
            return
        end
    end

    -- 3. Place owned authentic masterpieces on museum loan for monthly royalties
    for _, owned in ipairs(p.portfolio) do
        if not owned.on_museum_loan then
            owned.on_museum_loan = true
        end
    end

    -- 4. Occasional off-screen auction purchase in another city if player is not there
    local human = state.players[1]
    if p.city_id ~= human.city_id and GameState.random(state) < 0.14 then
        local lot = state.city_auctions[p.city_id]
        if lot then
            local art = Artworks.by_id[lot.artwork_id]
            if art then
                local price = math.floor(art.base_value * city.exchange_index * (0.75 + GameState.random(state) * 0.20))
                if p.cash >= price + 2500 and (art.forgery == 0x00 or GameState.random(state) < 0.25) then
                    p.cash = p.cash - price
                    p.total_auctions_won = (p.total_auctions_won or 0) + 1
                    table.insert(p.portfolio, {
                        id = art.id,
                        purchase_price = price,
                        purchase_city_id = p.city_id,
                        purchase_date = GameState.getFormattedDate(state),
                        on_museum_loan = true,
                        authenticity_known = true
                    })
                    GameState.removeArtworkFromPool(state, art.id, p.id)
                    GameState.addTelegram(state, "RIVAL ACQUISITION IN " .. city.name:upper(),
                        string.format("STOP. %s PURCHASED '%s' (%s) AT %s AUCTION FOR %d GOLD. STOP.",
                            p.name:upper(), art.title:upper(), art.artist_name:upper(), city.name:upper(), price))
                    return
                end
            end
        end
    end

    -- 5. Travel between cities
    if GameState.random(state) < 0.35 then
        local next_city = GameState.randomInt(state, 0, 3)
        if next_city ~= p.city_id then
            local route = Cities.getRoute(p.city_id, next_city)
            if p.cash > route.cost + 2000 then
                p.cash = p.cash - route.cost
                p.city_id = next_city
            end
        end
    end
end

return AIRivals
