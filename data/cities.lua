-- data/cities.lua
-- Source of Truth: docs/assets.md Section 6.2 (World Travel & Financial Network)

local Cities = {}

Cities.list = {
    {
        id = 0,
        key = "london",
        name = "London",
        country = "United Kingdom",
        subtitle = "Christie's & Sotheby's • Bank of England",
        primary_activity = "Christie's / Sotheby's Art Auctions, Bank of England loans",
        travel_cost = 350,
        travel_days = 1,
        exchange_index = 1.00,
        currency_name = "Base Sterling (£)",
        has_expert = true,
        expert_name = "Sir Arthur Pendelton (Royal Academy)",
        expert_skill = 0xD2, -- 210 / 255 skill against Byte 6 forgery byte
        expert_fee = 250,
        bank_interest_rate = 0.018, -- 1.8% monthly interest
        max_loan_multiplier = 0.65,
        auction_frequency = 0.70,   -- High frequency of prestigious sales
        map_pos = { x = 0.44, y = 0.36 },
        accent_color = { 0.78, 0.28, 0.25 },
        description = "The financial heart of the Empire. Home to Christie's and Sotheby's auction houses, the Bank of England's low-interest credit lines, and Royal Academy forgery appraisers."
    },
    {
        id = 1,
        key = "paris",
        name = "Paris",
        country = "France",
        subtitle = "Hôtel Drouot • Salon des Beaux-Arts",
        primary_activity = "Hotel Drouot Art Auctions, Luxury art dealers",
        travel_cost = 420,
        travel_days = 2,
        exchange_index = 0.85,
        currency_name = "Franc Index (0.85x)",
        has_expert = true,
        expert_name = "Mme. Claire Beaumont (Louvre Conservateur)",
        expert_skill = 0xE4, -- 228 / 255 skill against Byte 6 forgery byte
        expert_fee = 320,
        bank_interest_rate = 0.022,
        max_loan_multiplier = 0.50,
        auction_frequency = 0.75,
        map_pos = { x = 0.49, y = 0.47 },
        accent_color = { 0.28, 0.52, 0.78 },
        description = "Continental capital of fine art. The favorable 0.85 exchange index makes Hôtel Drouot auctions and Louvre expert appraisals prized among discerning collectors."
    },
    {
        id = 2,
        key = "berlin",
        name = "Berlin",
        country = "Germany",
        subtitle = "Colonial Plantation Agency • Kunstauktion",
        primary_activity = "Domestic art auctions, Plantation seed & worker agency",
        travel_cost = 280,
        travel_days = 1,
        exchange_index = 1.15,
        currency_name = "Goldmark Index (1.15x)",
        has_expert = false,
        expert_name = "Local Guild Appraiser",
        expert_skill = 0x88, -- Basic check only
        expert_fee = 140,
        bank_interest_rate = 0.024,
        max_loan_multiplier = 0.55,
        auction_frequency = 0.55,
        has_plantation_agency = true,
        worker_hire_cost = 180,     -- Cost per worker brigade
        seed_upgrade_cost = 450,    -- Disease-resistant seed stock
        map_pos = { x = 0.64, y = 0.38 },
        accent_color = { 0.76, 0.58, 0.22 },
        description = "Hub of the Continental Plantation & Worker Agency. Essential for hiring estate workers, buying disease-resistant seedlings, and trading Northern Renaissance works."
    },
    {
        id = 3,
        key = "new_york",
        name = "New York",
        country = "United States",
        subtitle = "Metropolitan Auctions • Wall Street Syndicate",
        primary_activity = "Metropolitan art auctions, High-stakes international loans",
        travel_cost = 1800,
        travel_days = 6,
        exchange_index = 1.40,
        currency_name = "Dollar Index (1.40x)",
        has_expert = false,
        expert_name = "Fifth Avenue Dealer",
        expert_skill = 0x96,
        expert_fee = 200,
        bank_interest_rate = 0.028,
        max_loan_multiplier = 0.90, -- High-stakes credit expansion
        auction_frequency = 0.65,
        map_pos = { x = 0.17, y = 0.48 },
        accent_color = { 0.25, 0.68, 0.52 },
        description = "Six days across the Atlantic by steamship. Commands a 1.40x currency exchange index—selling colonial harvests and loaning masterpieces here yields peak returns."
    }
}

Cities.by_id = {}
for _, c in ipairs(Cities.list) do
    Cities.by_id[c.id] = c
end

-- Compute travel route between two city IDs using the exact base table in assets.md §6.2
function Cities.getRoute(from_id, to_id)
    if from_id == to_id then
        return { cost = 0, days = 0, mode = "Local" }
    end
    local dest = Cities.by_id[to_id]
    local orig = Cities.by_id[from_id]
    if not dest or not orig then
        return { cost = 350, days = 1, mode = "Express Train" }
    end
    -- New York transatlantic crossing uses the documented 1,800 Gold / 6 Days Steamship
    if to_id == 3 or from_id == 3 then
        local cost = dest.travel_cost
        local days = dest.travel_days
        if from_id == 3 and to_id ~= 3 then
            -- Returning from NY to Europe combines transatlantic steamship + destination rail
            cost = 1800 + math.floor(dest.travel_cost * 0.5)
            days = 6 + (dest.travel_days - 1)
        end
        return {
            cost = cost,
            days = days,
            mode = "Transatlantic Steamship"
        }
    end
    -- Intra-European rail/ferry uses the exact destination node table from assets.md §6.2
    return {
        cost = dest.travel_cost,
        days = dest.travel_days,
        mode = (from_id == 0 or to_id == 0) and "Channel Packet & Rail" or "Continental Express"
    }
end

return Cities
