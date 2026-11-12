-- data/commodities.lua
-- Source of Truth: docs/assets.md Section 6.1 (Plantation Commodity Master Tables)

local Commodities = {}

Commodities.list = {
    {
        id = 1,
        key = "tea",
        name = "Tea",
        german_id = "TEE",
        plantation_base_cost = 1200,
        base_yield_cwt = 80,
        optimal_months = { 6, 7, 8 }, -- June-August
        optimal_label = "June–August",
        risk_factors = { "Drought", "Red spider mite" },
        base_market_price = 18,       -- Gold per cwt at 1.00 exchange index
        min_price = 9,
        max_price = 34,
        volatility = 0.14,
        upkeep_per_acre = 95,
        region = "Ceylon & Darjeeling",
        color = { 0.34, 0.65, 0.38 },
        description = "Steady colonial staple with low entry cost (1,200G/acre) and reliable 80 cwt summer harvests."
    },
    {
        id = 2,
        key = "coffee",
        name = "Coffee",
        german_id = "KAFFEE",
        plantation_base_cost = 2400,
        base_yield_cwt = 65,
        optimal_months = { 9, 10, 11 }, -- September-November
        optimal_label = "September–November",
        risk_factors = { "Frost", "Coffee rust fungus" },
        base_market_price = 36,
        min_price = 18,
        max_price = 68,
        volatility = 0.18,
        upkeep_per_acre = 160,
        region = "Santos & Highland Java",
        color = { 0.62, 0.42, 0.24 },
        description = "High-margin autumn crop (2,400G/acre, 65 cwt). Vulnerable to early frost and leaf rust."
    },
    {
        id = 3,
        key = "tobacco",
        name = "Tobacco",
        german_id = "TABAK",
        plantation_base_cost = 1800,
        base_yield_cwt = 110,
        optimal_months = { 7, 8, 9 }, -- July-September
        optimal_label = "July–September",
        risk_factors = { "Hail", "Blue mold" },
        base_market_price = 21,
        min_price = 10,
        max_price = 42,
        volatility = 0.16,
        upkeep_per_acre = 135,
        region = "Virginia & Havana",
        color = { 0.78, 0.58, 0.22 },
        description = "Highest volume yield per acre (110 cwt) during late summer. Watch out for summer hailstorms."
    },
    {
        id = 4,
        key = "cocoa",
        name = "Cocoa",
        german_id = "KAKAO",
        plantation_base_cost = 3100,
        base_yield_cwt = 50,
        optimal_months = { 10, 11, 12 }, -- October-December
        optimal_label = "October–December",
        risk_factors = { "Flooding", "Black pod rot" },
        base_market_price = 58,
        min_price = 28,
        max_price = 110,
        volatility = 0.22,
        upkeep_per_acre = 210,
        region = "Gold Coast & Bahia",
        color = { 0.72, 0.34, 0.48 },
        description = "Luxury winter harvest (3,100G/acre, 50 cwt). Commands top prices in Paris and New York."
    }
}

Commodities.by_key = {}
Commodities.by_id = {}
for _, c in ipairs(Commodities.list) do
    Commodities.by_key[c.key] = c
    Commodities.by_id[c.id] = c
end

function Commodities.isOptimalMonth(commodity, month)
    for _, m in ipairs(commodity.optimal_months) do
        if m == month then return true end
    end
    return false
end

return Commodities
