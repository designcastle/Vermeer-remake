-- data/events.lua
-- Source of Truth: docs/assets.md Section 6.1 (Risk Factors) & C64 Telegram Event System

local Events = {}

-- Plantation Risk Events matching assets.md §6.1
Events.plantation_risks = {
    tea = {
        {
            title = "Ceylon Drought Alert",
            risk_name = "Drought",
            yield_multiplier = 0.55,
            price_spike = 1.28,
            telegram = "STOP. SEVERE DROUGHT ACROSS CEYLON TEA ESTATES. SUMMER YIELDS REDUCED BY 45 PCT. SPOT TEA PRICES SURGING ON LONDON EXCHANGE. STOP."
        },
        {
            title = "Red Spider Mite Outbreak",
            risk_name = "Red spider mite",
            yield_multiplier = 0.65,
            price_spike = 1.18,
            telegram = "STOP. RED SPIDER MITE INFESTATION REPORTED IN TEA PLANTATIONS. UNTREATED ESTATES SUFFER FOLIAGE LOSS. SEED UPGRADES PREVENT DAMAGE. STOP."
        }
    },
    coffee = {
        {
            title = "Highland Frost Warning",
            risk_name = "Frost",
            yield_multiplier = 0.50,
            price_spike = 1.35,
            telegram = "STOP. UNSEASONABLE BLACK FROST STRIKES COFFEE HIGHLANDS. CHERRY HARVEST HALVED. PARIS AND NEW YORK ROASTERS BIDDING UP RESERVES. STOP."
        },
        {
            title = "Coffee Rust Fungus (Hemileia)",
            risk_name = "Coffee rust fungus",
            yield_multiplier = 0.60,
            price_spike = 1.22,
            telegram = "STOP. COFFEE LEAF RUST FUNGUS SPREADING THROUGH PLANTATIONS. BERLIN COLONIAL AGENCY RECOMMENDS HARDY SEED STOCK IMMEDIATELY. STOP."
        }
    },
    tobacco = {
        {
            title = "Summer Hailstorm Devastation",
            risk_name = "Hail",
            yield_multiplier = 0.52,
            price_spike = 1.30,
            telegram = "STOP. VIOLENT HAILSTORMS SHRED BROADLEAF TOBACCO CROPS BEFORE CURING. WAREHOUSE INVENTORIES COMMAND PREMIUM RATES. STOP."
        },
        {
            title = "Blue Mold Epidemic",
            risk_name = "Blue mold",
            yield_multiplier = 0.62,
            price_spike = 1.20,
            telegram = "STOP. PERONOSPORA BLUE MOLD DETECTED IN TOBACCO CURING BARNS. YIELDS DOWN 38 PCT ON UNPROTECTED ESTATES. STOP."
        }
    },
    cocoa = {
        {
            title = "Equatorial River Flooding",
            risk_name = "Flooding",
            yield_multiplier = 0.48,
            price_spike = 1.38,
            telegram = "STOP. TORRENTIAL MONSOON FLOODING INUNDATES COCOA GROVES. TRANSPORT DELAYED AND POD YIELDS SEVERELY REDUCED. STOP."
        },
        {
            title = "Black Pod Rot Contagion",
            risk_name = "Black pod rot",
            yield_multiplier = 0.58,
            price_spike = 1.25,
            telegram = "STOP. PHYTOPHTHORA BLACK POD ROT REPORTED IN COCOA ESTATES. SWISS AND PARISIAN CONFECTIONERS SCRAMBLING FOR SOUND BEANS. STOP."
        }
    }
}

-- Global Economic & Art World Telegrams
Events.world_telegrams = {
    {
        id = "booming_ny",
        title = "Wall Street Bull Run",
        effect = "ny_boom",
        telegram = "STOP. WALL STREET SYNDICATE REPORTS RECORD DIVIDENDS. METROPOLITAN COLLECTORS PAYING 15 PCT PREMIUM ON AUTHENTIC OLD MASTERS THIS MONTH. STOP."
    },
    {
        id = "forgery_scandal",
        title = "Van Meegeren Forgery Ring Exposed",
        effect = "forgery_vigilance",
        telegram = "STOP. SCOTLAND YARD AND SURETE WARN COLLECTORS OF CLEVER OLD MASTER FORGERIES CIRCULATING IN EUROPE. CONSULT LONDON OR PARIS EXPERTS BEFORE BIDDING. STOP."
    },
    {
        id = "museum_endowment",
        title = "Royal Museum Exhibition Grant",
        effect = "museum_bonus",
        telegram = "STOP. NATIONAL GALLERIES INCREASE EXHIBITION ROYALTIES FOR LOANED MASTERPIECES BY 25 PCT THIS QUARTER. STOP."
    },
    {
        id = "shipping_bounty",
        title = "Bumper Colonial Shipping Season",
        effect = "bumper_harvest",
        telegram = "STOP. FAVORABLE TRADE WINDS AND IDEAL MONSOON RAINS BOOST ALL COLONIAL PLANTATION OUTPUT BY 20 PCT THIS MONTH. STOP."
    },
    {
        id = "bank_tightening",
        title = "Bank of England Discount Rate Notice",
        effect = "interest_notice",
        telegram = "STOP. BANK OF ENGLAND ADVISES MERCHANTS TO MAINTAIN HEALTHY EQUITY RATIOS AGAINST OUTSTANDING SYNDICATE LOANS. STOP."
    }
}

return Events
