-- sim/economy.lua
-- Deterministic turn resolution, interest, upkeep, crop yields, price updates

local Cities      = require("data.cities")
local Commodities = require("data.commodities")
local Artworks    = require("data.artworks")
local Events      = require("data.events")
local GameState   = require("sim.game_state")
local AIRivals    = nil -- lazy-loaded to avoid circular require

local Economy = {}

local DAYS_PER_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

-- Commodity Actions
function Economy.buyPlantationAcre(state, player, commodity_key)
    local comm = Commodities.by_key[commodity_key]
    if not comm then return false, "Unknown commodity." end
    local city = Cities.by_id[player.city_id]
    local cost = math.floor(comm.plantation_base_cost * city.exchange_index)
    if player.cash < cost then
        return false, string.format("Insufficient Gold (Need %d G).", cost)
    end
    player.cash = player.cash - cost
    player.estates[commodity_key] = (player.estates[commodity_key] or 0) + 1
    return true, string.format("Purchased 1 acre of %s (%s) for %d G.", comm.name, comm.german_id, cost)
end

function Economy.sellCommodity(state, player, commodity_key, cwt_amount)
    local comm = Commodities.by_key[commodity_key]
    if not comm then return false, "Unknown commodity." end
    local avail = player.inventory[commodity_key] or 0
    cwt_amount = math.min(avail, math.floor(cwt_amount or avail))
    if cwt_amount <= 0 then
        return false, "No inventory in warehouse to sell."
    end
    local city = Cities.by_id[player.city_id]
    local unit_price = Economy.getLocalCommodityPrice(state, commodity_key, player.city_id)
    local revenue = math.floor(cwt_amount * unit_price)
    player.inventory[commodity_key] = avail - cwt_amount
    player.cash = player.cash + revenue
    player.total_crop_sales = (player.total_crop_sales or 0) + revenue
    return true, string.format("Sold %d cwt of %s in %s for %d G (%d G/cwt).",
        cwt_amount, comm.name, city.name, revenue, unit_price)
end

function Economy.getLocalCommodityPrice(state, commodity_key, city_id)
    local comm = Commodities.by_key[commodity_key]
    local base_spot = state.market_prices[commodity_key] or comm.base_market_price
    local city = Cities.by_id[city_id] or Cities.list[1]
    return math.max(1, math.floor(base_spot * city.exchange_index + 0.5))
end

-- Berlin Plantation Seed & Worker Agency Actions (assets.md §6.2 Node 2)
function Economy.hireWorkerBrigade(state, player)
    local city = Cities.by_id[player.city_id]
    local cost = city.has_plantation_agency and city.worker_hire_cost or 290
    if player.cash < cost then
        return false, string.format("Need %d Gold to hire a Worker Brigade.", cost)
    end
    player.cash = player.cash - cost
    player.workers = (player.workers or 0) + 1
    return true, string.format("Hired 1 Colonial Worker Brigade (%d G). Total brigades: %d.", cost, player.workers)
end

function Economy.buyHardySeeds(state, player)
    if player.has_hardy_seeds then
        return false, "Your estates already use disease-resistant Berlin seed stock."
    end
    local city = Cities.by_id[player.city_id]
    if not city.has_plantation_agency then
        return false, "Disease-resistant seed stock is only sold at the Berlin Colonial Agency."
    end
    local cost = city.seed_upgrade_cost or 450
    if player.cash < cost then
        return false, string.format("Need %d Gold for Hardy Seed Stock.", cost)
    end
    player.cash = player.cash - cost
    player.has_hardy_seeds = true
    return true, "Acquired Berlin Hardy Seed Stock! Pest & weather losses reduced by 70%."
end

-- Banking Actions (assets.md §6.2 London Bank of England & New York International Loans)
function Economy.takeLoan(state, player, amount)
    amount = math.floor(amount or 0)
    if amount <= 0 then return false, "Invalid loan amount." end
    local max_credit = GameState.getMaxCredit(state, player, player.city_id)
    local available = math.max(0, max_credit - player.loan)
    local borrow = math.min(amount, available)
    if borrow <= 0 then
        return false, string.format("Credit limit reached in %s (Max %d G).",
            Cities.by_id[player.city_id].name, max_credit)
    end
    player.cash = player.cash + borrow
    player.loan = player.loan + borrow
    player.loan_city_id = player.city_id
    return true, string.format("Borrowed %d Gold from %s syndicate.", borrow, Cities.by_id[player.city_id].name)
end

function Economy.repayLoan(state, player, amount)
    if player.loan <= 0 then return false, "You have no outstanding bank loans." end
    local repay = math.min(player.loan, math.min(player.cash, math.floor(amount or player.loan)))
    if repay <= 0 then return false, "Insufficient cash to repay loan." end
    player.cash = player.cash - repay
    player.loan = player.loan - repay
    return true, string.format("Repaid %d Gold. Remaining debt: %d G.", repay, player.loan)
end

-- Art Expert Inspection in London or Paris (assets.md §6.3 Byte 6 Forgery Quality Check)
function Economy.appraiseLot(state, player, artwork_id)
    local city = Cities.by_id[player.city_id]
    local art = Artworks.by_id[artwork_id]
    if not art then return false, "Artwork not found." end
    if player.appraised_ids[artwork_id] then
        return false, "Your expert has already appraised this canvas."
    end
    local fee = city.expert_fee or 250
    if player.cash < fee then
        return false, string.format("Need %d Gold for %s's appraisal.", fee, city.expert_name)
    end
    player.cash = player.cash - fee

    -- Compare city.expert_skill against art.forgery (Byte 6: $00 = Original, $01..$FF = Forgery quality)
    local appears_authentic = true
    local verdict_note = ""
    local confidence = 92

    if art.forgery == 0x00 then
        appears_authentic = true
        confidence = city.has_expert and 98 or 80
        verdict_note = string.format("%s verifies period pigments and craquelure: AUTHENTIC MASTERPIECE (Byte 6 = $00).", city.expert_name)
    else
        -- Forgery quality byte $01..$FF: if expert_skill >= forgery byte, expert catches the fake!
        if city.expert_skill >= art.forgery then
            appears_authentic = false
            confidence = 96
            verdict_note = string.format("%s detects anachronistic lead-white underpainting! FORGERY DETECTED (Byte 6 = $%02X vs Skill $%02X).",
                city.expert_name, art.forgery, city.expert_skill)
        else
            -- Master forgery fools a weaker local appraiser
            appears_authentic = true
            confidence = 62
            verdict_note = string.format("%s finds no obvious flaws, though provenance is murky (Confidence %d%%).",
                city.expert_name, confidence)
        end
    end

    player.appraised_ids[artwork_id] = {
        inspected = true,
        appears_authentic = appears_authentic,
        confidence = confidence,
        expert_name = city.expert_name,
        note = verdict_note
    }

    return true, verdict_note
end

-- Monthly Economic Resolution
function Economy.resolveMonthEnd(state)
    local month = state.month
    local mname = GameState.MONTH_NAMES[month]

    -- 1. Roll for Plantation Risk Event or Global Telegram
    local risk_commodity_key = nil
    local active_risk = nil
    if GameState.random(state) < 0.45 then
        local comm = Commodities.list[GameState.randomInt(state, 1, #Commodities.list)]
        local risks = Events.plantation_risks[comm.key]
        if risks and #risks > 0 then
            active_risk = risks[GameState.randomInt(state, 1, #risks)]
            risk_commodity_key = comm.key
            GameState.addTelegram(state, active_risk.title .. " (" .. mname .. ")", active_risk.telegram)
        end
    else
        local wt = Events.world_telegrams[GameState.randomInt(state, 1, #Events.world_telegrams)]
        state.active_modifier = wt.effect
        GameState.addTelegram(state, wt.title .. " (" .. mname .. ")", wt.telegram)
    end

    -- 2. Update Commodity Spot Prices & History
    for _, comm in ipairs(Commodities.list) do
        local current = state.market_prices[comm.key] or comm.base_market_price
        local is_harvest = Commodities.isOptimalMonth(comm, month)
        -- Prices dip slightly during abundant optimal harvest months and rise in off-season, unless a risk event hits
        local seasonal_drift = is_harvest and -0.05 or 0.04
        local delta_pct = seasonal_drift + (GameState.random(state) * 2 - 1) * comm.volatility
        -- Mean reversion toward base_market_price
        local pull = (comm.base_market_price - current) * 0.25
        local next_price = current * (1 + delta_pct) + pull

        if risk_commodity_key == comm.key and active_risk then
            next_price = next_price * active_risk.price_spike
        end

        next_price = math.max(comm.min_price, math.min(comm.max_price, math.floor(next_price + 0.5)))
        state.market_prices[comm.key] = next_price

        local hist = state.price_history[comm.key]
        table.insert(hist, next_price)
        if #hist > 18 then table.remove(hist, 1) end
    end

    -- 3. Process Each Player (Yields, Upkeep, Loan Interest, Museum Royalties)
    for _, p in ipairs(state.players) do
        local total_acres = GameState.getTotalAcres(p)
        local staffing_ratio = 1.0
        if total_acres > 0 then
            staffing_ratio = math.min(1.15, math.max(0.55, (p.workers or 0) / total_acres))
        end

        -- Harvest Yields
        local harvest_summary = {}
        for _, comm in ipairs(Commodities.list) do
            local acres = p.estates[comm.key] or 0
            if acres > 0 then
                local is_opt = Commodities.isOptimalMonth(comm, month)
                local season_factor = is_opt and 1.00 or 0.35
                if state.active_modifier == "bumper_harvest" then
                    season_factor = season_factor * 1.20
                end
                local risk_factor = 1.0
                if risk_commodity_key == comm.key and active_risk then
                    if p.has_hardy_seeds then
                        -- Berlin Hardy Seeds protect 70% of the loss
                        risk_factor = 1.0 - (1.0 - active_risk.yield_multiplier) * 0.30
                    else
                        risk_factor = active_risk.yield_multiplier
                    end
                end
                local produced = math.floor(acres * comm.base_yield_cwt * season_factor * staffing_ratio * risk_factor + 0.5)
                if produced > 0 then
                    p.inventory[comm.key] = (p.inventory[comm.key] or 0) + produced
                    if p.id == 1 then
                        table.insert(harvest_summary, string.format("+%d cwt %s", produced, comm.name))
                    end
                end
            end
        end

        -- Plantation & Worker Upkeep
        local upkeep = (p.workers or 0) * 45
        for _, comm in ipairs(Commodities.list) do
            upkeep = upkeep + (p.estates[comm.key] or 0) * comm.upkeep_per_acre
        end
        p.cash = p.cash - upkeep

        -- Museum Exhibition Loan Royalties
        local royalties = 0
        for _, owned in ipairs(p.portfolio) do
            local art = Artworks.by_id[owned.id]
            if art and Artworks.isAuthentic(art) and owned.on_museum_loan then
                local rate = (state.active_modifier == "museum_bonus") and 0.045 or 0.035
                royalties = royalties + math.floor(art.base_value * rate)
            end
        end
        p.cash = p.cash + royalties

        -- Bank Loan Interest
        if p.loan > 0 then
            local bank_city = Cities.by_id[p.loan_city_id or 0] or Cities.list[1]
            local interest = math.floor(p.loan * bank_city.bank_interest_rate)
            p.loan = p.loan + interest
        end

        -- Log player 1 monthly summary
        if p.id == 1 and #harvest_summary > 0 then
            GameState.addTelegram(state, mname .. " Estate Ledger",
                string.format("HARVEST: %s | UPKEEP: -%d G | MUSEUM ROYALTIES: +%d G.",
                    table.concat(harvest_summary, ", "), upkeep, royalties))
        end
    end

    -- Refresh city auctions for the new month
    GameState.refreshCityAuctions(state, false)

    -- Check Victory / Bankruptcy Conditions
    Economy.checkEndConditions(state)
end

function Economy.checkEndConditions(state)
    if state.game_over then return end

    -- 1. Check if human player went deeply bankrupt
    local human = state.players[1]
    local human_nw = GameState.getNetWorth(state, human)
    if human_nw < -12000 and human.cash < 0 then
        state.game_over = true
        state.winner = state.players[2] or human
        state.end_reason = "Bankruptcy! The Bank of England Foreclosed on Your Estates."
        return
    end

    -- 2. Check if any player achieved Uncle Walter's Victory Conditions
    for _, p in ipairs(state.players) do
        local _, auth_count = GameState.getArtPortfolioStats(p)
        local nw = GameState.getNetWorth(state, p)
        if auth_count >= state.target_artworks and nw >= state.target_net_worth then
            state.game_over = true
            state.winner = p
            state.end_reason = string.format("%s fulfilled Uncle Walter's Testament (%d Authentic Masterpieces & %d G Net Worth)!",
                p.name, auth_count, nw)
            return
        end
    end

    -- 3. Check if Campaign Time Limit reached (End of final year)
    local end_year = state.start_year + state.max_years - 1
    if state.year > end_year or (#state.artwork_pool == 0) then
        state.game_over = true
        -- Determine highest score (Authentic Artworks * 10,000 + Net Worth)
        local best_p = state.players[1]
        local best_score = -99999999
        for _, p in ipairs(state.players) do
            local _, auth_count = GameState.getArtPortfolioStats(p)
            local nw = GameState.getNetWorth(state, p)
            local score = auth_count * 12000 + nw
            if score > best_score then
                best_score = score
                best_p = p
            end
        end
        state.winner = best_p
        state.end_reason = string.format("Final Year Concluded! %s claims the Vermeer Legacy with the highest combined collection & fortune.", best_p.name)
    end
end

-- Advance simulation by N days (triggered by Travel or Resting/Working in City)
function Economy.advanceDays(state, days)
    if state.game_over then return end
    AIRivals = AIRivals or require("sim.ai_rivals")

    days = math.max(1, math.floor(days or 1))
    for _ = 1, days do
        state.day = state.day + 1
        state.turn = state.turn + 1

        -- Let AI rivals make decisions each day
        AIRivals.processDailyTurns(state)

        -- Periodically rotate city auction lots mid-month
        if state.day == 10 or state.day == 20 then
            GameState.refreshCityAuctions(state, false)
        end

        local max_d = DAYS_PER_MONTH[state.month] or 30
        if state.day > max_d then
            state.day = 1
            state.month = state.month + 1
            if state.month > 12 then
                state.month = 1
                state.year = state.year + 1
            end
            Economy.resolveMonthEnd(state)
            if state.game_over then break end
        end
    end
end

-- Travel Player to Destination City
function Economy.travelToCity(state, player, dest_city_id)
    if player.city_id == dest_city_id then
        return false, "Already in " .. Cities.by_id[dest_city_id].name .. "."
    end
    local route = Cities.getRoute(player.city_id, dest_city_id)
    if player.cash < route.cost then
        return false, string.format("Insufficient Gold for %s ticket (%d G required).", route.mode, route.cost)
    end
    player.cash = player.cash - route.cost
    player.city_id = dest_city_id
    Economy.advanceDays(state, route.days)
    local dest = Cities.by_id[dest_city_id]
    return true, string.format("Arrived in %s via %s (%d days, -%d G).", dest.name, route.mode, route.days, route.cost)
end

return Economy
