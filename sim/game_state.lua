-- sim/game_state.lua
-- Serialized state (turn/date, players, cash, loans, portfolio, inventory)

local Cities      = require("data.cities")
local Commodities = require("data.commodities")
local Artworks    = require("data.artworks")

local GameState = {}

GameState.MONTH_NAMES = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
}

local RIVAL_TEMPLATES = {
    {
        name = "Gerd",
        title = "Hamburg Merchant",
        aggression = 0.58,
        bluff_chance = 0.18,
        art_focus = 0.55,
        preferred_commodity = "coffee",
        portrait_color = { 0.30, 0.52, 0.74 },
        coat_color = { 0.18, 0.26, 0.38 }
    },
    {
        name = "Kurt",
        title = "Rhenish Industrialist",
        aggression = 0.72,
        bluff_chance = 0.25,
        art_focus = 0.65,
        preferred_commodity = "tobacco",
        portrait_color = { 0.72, 0.48, 0.24 },
        coat_color = { 0.34, 0.24, 0.16 }
    },
    {
        name = "Baron von Stahl",
        title = "Prussian Connoisseur",
        aggression = 0.84,
        bluff_chance = 0.32,
        art_focus = 0.82,
        preferred_commodity = "cocoa",
        portrait_color = { 0.68, 0.24, 0.28 },
        coat_color = { 0.28, 0.14, 0.18 }
    }
}

function GameState.newPlayer(idx, name, is_ai, rival_template)
    local estates = {}
    local inventory = {}
    for _, c in ipairs(Commodities.list) do
        estates[c.key] = 0
        inventory[c.key] = 0
    end
    -- Starting plantation: 1 acre of Tea so the player immediately sees harvest mechanics
    estates["tea"] = 1
    inventory["tea"] = 40

    local tpl = rival_template or RIVAL_TEMPLATES[((idx - 1) % #RIVAL_TEMPLATES) + 1]
    return {
        id = idx,
        name = name,
        title = is_ai and tpl.title or "Art & Colonial House",
        is_ai = is_ai and true or false,
        city_id = (idx - 1) % 4, -- Start in London (0) for Player 1
        cash = 18000,
        loan = 0,
        loan_city_id = 0,
        estates = estates,
        inventory = inventory,
        workers = 2,
        has_hardy_seeds = false,
        portfolio = {},          -- List of owned artwork records
        appraised_ids = {},      -- Map of artwork_id -> { inspected = true, appears_authentic = bool, confidence = number }
        aggression = tpl.aggression,
        bluff_chance = tpl.bluff_chance,
        art_focus = tpl.art_focus,
        preferred_commodity = tpl.preferred_commodity,
        portrait_color = tpl.portrait_color,
        coat_color = tpl.coat_color,
        total_crop_sales = 0,
        total_auctions_won = 0,
        forgeries_bought = 0
    }
end

function GameState.createNew(config)
    config = config or {}
    local num_humans = config.num_humans or 1
    local total_players = config.total_players or 4
    local target_artworks = config.target_artworks or 5
    local max_years = config.max_years or 3
    local seed = config.seed or os.time()

    local state = {
        version = 1,
        seed = seed,
        rng_state = seed % 2147483647,
        year = 1924,
        start_year = 1924,
        max_years = max_years,
        month = 5,   -- Start in May just before summer Tea & Tobacco harvests
        day = 1,
        turn = 1,
        target_artworks = target_artworks,
        target_net_worth = config.target_net_worth or 55000,
        active_player_idx = 1,
        players = {},
        market_prices = {},
        price_history = {},
        artwork_pool = {},       -- Remaining unowned artwork IDs
        artwork_owners = {},     -- artwork_id -> player_id (or 0 if unowned)
        city_auctions = {},      -- city_id -> { artwork_id = ..., reserve = ..., expert_checked = false }
        active_modifier = nil,
        telegrams = {},
        seen_tutorials = {},
        tutorial_enabled = (config.tutorial_enabled ~= false),
        game_over = false,
        winner = nil,
        end_reason = nil
    }

    if state.rng_state <= 0 then state.rng_state = 19870604 end

    -- Initialize Players (1..4)
    local rival_idx = 1
    for i = 1, total_players do
        local is_ai = (i > num_humans)
        local name
        local tpl = nil
        if is_ai then
            tpl = RIVAL_TEMPLATES[rival_idx] or RIVAL_TEMPLATES[1]
            name = tpl.name
            rival_idx = rival_idx + 1
        else
            name = (i == 1 and (config.player_name or "Lady Vermeer")) or ("Player " .. i)
        end
        local p = GameState.newPlayer(i, name, is_ai, tpl)
        if i == 1 then p.city_id = 0 end -- Player 1 starts in London
        table.insert(state.players, p)
    end

    -- Initialize Commodity Market Prices & Sparkline Histories
    for _, c in ipairs(Commodities.list) do
        state.market_prices[c.key] = c.base_market_price
        state.price_history[c.key] = {}
        for step = 1, 14 do
            local wave = math.sin(step * 0.65 + c.id * 1.3) * (c.base_market_price * 0.12)
            local val = math.floor(c.base_market_price + wave + 0.5)
            table.insert(state.price_history[c.key], val)
        end
        state.market_prices[c.key] = state.price_history[c.key][#state.price_history[c.key]]
    end

    -- Populate 64-Artwork Pool
    for _, art in ipairs(Artworks.catalog) do
        table.insert(state.artwork_pool, art.id)
        state.artwork_owners[art.id] = 0
    end

    -- Shuffle artwork pool deterministically
    for i = #state.artwork_pool, 2, -1 do
        local j = GameState.randomInt(state, 1, i)
        state.artwork_pool[i], state.artwork_pool[j] = state.artwork_pool[j], state.artwork_pool[i]
    end

    -- Seed initial auctions in all 4 cities
    GameState.refreshCityAuctions(state, true)

    -- Add opening telegram
    GameState.addTelegram(state, "UNCLE WALTER'S TESTAMENT",
        "STOP. SOLICITORS IN LONDON CONFIRM UNCLE WALTER'S WILL. RECOVER " ..
        tostring(state.target_artworks) .. " AUTHENTIC OLD MASTER PAINTINGS AND BUILD AT LEAST " ..
        tostring(state.target_net_worth) .. " GOLD IN NET WORTH BEFORE DECEMBER " ..
        tostring(state.start_year + state.max_years - 1) .. " TO CLAIM THE FAMILY LEGACY. STOP.")

    return state
end

-- Deterministic Park-Miller LCG so saves & tests behave identically
function GameState.random(state)
    state.rng_state = (state.rng_state * 48271) % 2147483647
    return state.rng_state / 2147483647
end

function GameState.randomInt(state, min_val, max_val)
    if max_val <= min_val then return min_val end
    local r = GameState.random(state)
    return min_val + math.floor(r * (max_val - min_val + 1))
end

function GameState.getActivePlayer(state)
    return state.players[state.active_player_idx] or state.players[1]
end

function GameState.getFormattedDate(state)
    local mname = GameState.MONTH_NAMES[state.month] or "Jan"
    return string.format("%s %d, %d", mname, state.day, state.year)
end

function GameState.addTelegram(state, title, body)
    table.insert(state.telegrams, 1, {
        date = GameState.getFormattedDate(state),
        title = title,
        body = body,
        turn = state.turn
    })
    while #state.telegrams > 24 do
        table.remove(state.telegrams)
    end
end

function GameState.getTotalAcres(player)
    local total = 0
    for _, c in ipairs(Commodities.list) do
        total = total + (player.estates[c.key] or 0)
    end
    return total
end

function GameState.getEstateValue(player, exchange_index)
    exchange_index = exchange_index or 1.0
    local total = 0
    for _, c in ipairs(Commodities.list) do
        local acres = player.estates[c.key] or 0
        total = total + acres * c.plantation_base_cost
    end
    return math.floor(total * exchange_index)
end

function GameState.getInventoryValue(state, player, exchange_index)
    exchange_index = exchange_index or 1.0
    local total = 0
    for _, c in ipairs(Commodities.list) do
        local cwt = player.inventory[c.key] or 0
        local price = state.market_prices[c.key] or c.base_market_price
        total = total + math.floor(cwt * price * exchange_index)
    end
    return total
end

function GameState.getArtPortfolioStats(player)
    local total_val = 0
    local authentic_count = 0
    local forgery_count = 0
    local loaned_count = 0
    for _, owned in ipairs(player.portfolio) do
        local art = Artworks.by_id[owned.id]
        if art then
            if Artworks.isAuthentic(art) then
                total_val = total_val + art.base_value
                authentic_count = authentic_count + 1
                if owned.on_museum_loan then
                    loaned_count = loaned_count + 1
                end
            else
                forgery_count = forgery_count + 1
                -- Unexposed forgery only counts if not yet exposed, but final net worth values only authentic art
            end
        end
    end
    return total_val, authentic_count, forgery_count, loaned_count
end

function GameState.getNetWorth(state, player)
    local estate_val = GameState.getEstateValue(player, 1.0)
    local inv_val = GameState.getInventoryValue(state, player, 1.0)
    local art_val = GameState.getArtPortfolioStats(player)
    return math.floor(player.cash - player.loan + estate_val + inv_val + art_val)
end

function GameState.getMaxCredit(state, player, city_id)
    local city = Cities.by_id[city_id or player.city_id] or Cities.list[1]
    local nw = math.max(5000, GameState.getNetWorth(state, player))
    return math.floor(nw * city.max_loan_multiplier)
end

function GameState.refreshCityAuctions(state, force_all)
    if #state.artwork_pool == 0 then return end
    for _, city in ipairs(Cities.list) do
        local current = state.city_auctions[city.id]
        local should_spawn = force_all or (not current) or (GameState.random(state) < city.auction_frequency)
        if should_spawn and #state.artwork_pool > 0 then
            local pick_idx = GameState.randomInt(state, 1, #state.artwork_pool)
            local art_id = state.artwork_pool[pick_idx]
            local art = Artworks.by_id[art_id]
            -- Opening reserve is 60% of base value adjusted by local exchange index
            local opening = math.floor((art.base_value * (0.55 + GameState.random(state) * 0.15)) * city.exchange_index / 50) * 50
            state.city_auctions[city.id] = {
                city_id = city.id,
                artwork_id = art_id,
                opening_bid = math.max(500, opening),
                created_turn = state.turn
            }
        end
    end
end

function GameState.removeArtworkFromPool(state, artwork_id, new_owner_id)
    state.artwork_owners[artwork_id] = new_owner_id
    for i = #state.artwork_pool, 1, -1 do
        if state.artwork_pool[i] == artwork_id then
            table.remove(state.artwork_pool, i)
        end
    end
    for cid, lot in pairs(state.city_auctions) do
        if lot and lot.artwork_id == artwork_id then
            state.city_auctions[cid] = nil
        end
    end
end

-- Simple Lua table serializer for love.filesystem save/load
local function serializeValue(v, indent)
    indent = indent or ""
    local t = type(v)
    if t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" then
        local parts = { "{\n" }
        local next_indent = indent .. "  "
        for k, val in pairs(v) do
            local key_str
            if type(k) == "number" then
                key_str = "[" .. tostring(k) .. "]"
            else
                key_str = "[" .. string.format("%q", tostring(k)) .. "]"
            end
            table.insert(parts, next_indent .. key_str .. " = " .. serializeValue(val, next_indent) .. ",\n")
        end
        table.insert(parts, indent .. "}")
        return table.concat(parts)
    else
        return "nil"
    end
end

function GameState.save(state, filename)
    filename = filename or "vermeer_save.lua"
    local payload = "return " .. serializeValue(state) .. "\n"
    local ok, err = love.filesystem.write(filename, payload)
    if ok then return true, nil end
    -- Fallback to /tmp if OS sandbox restricts ~/Library/Application Support/LOVE
    local f, ferr = io.open("/tmp/" .. filename, "w")
    if f then
        f:write(payload)
        f:close()
        return true, nil
    end
    return false, err or ferr
end

function GameState.hasSave(filename)
    filename = filename or "vermeer_save.lua"
    if love.filesystem.getInfo(filename) ~= nil then return true end
    local f = io.open("/tmp/" .. filename, "r")
    if f then f:close() return true end
    return false
end

function GameState.load(filename)
    filename = filename or "vermeer_save.lua"
    if love.filesystem.getInfo(filename) ~= nil then
        local chunk, err = love.filesystem.load(filename)
        if not chunk then return nil, err end
        local ok, loaded = pcall(chunk)
        if not ok then return nil, loaded end
        return loaded, nil
    end
    local f = io.open("/tmp/" .. filename, "r")
    if f then
        local content = f:read("*a")
        f:close()
        local chunk, err = loadstring(content)
        if not chunk then return nil, err end
        local ok, loaded = pcall(chunk)
        if not ok then return nil, loaded end
        return loaded, nil
    end
    return nil, "No save file found."
end

return GameState
