-- data/tutorials.lua
-- Contextual micro-tutorial triggers & searchable Rulebook entries

local Tutorials = {}

Tutorials.callouts = {
    welcome = {
        id = "welcome",
        title = "Uncle Walter's Legacy",
        body = "Welcome to Vermeer! Your late Uncle Walter's priceless Old Master collection was scattered across London, Paris, Berlin, and New York. Build plantation wealth, trade commodities across currency zones, and outbid rivals at auction to recover authentic masterpieces!"
    },
    city_hub = {
        id = "city_hub",
        title = "The City Hub & Exchange Index",
        body = "Each city has a Currency Exchange Index (Paris 0.85x, London 1.00x, Berlin 1.15x, New York 1.40x). Buy plantations or art where the index is low (Paris/London) and sell harvested commodities where the index is high (Berlin/New York)!"
    },
    plantations = {
        id = "plantations",
        title = "Colonial Plantations & Harvest Months",
        body = "Tea (Jun–Aug), Tobacco (Jul–Sep), Coffee (Sep–Nov), and Cocoa (Oct–Dec) produce peak yields during their Optimal Harvest Months. Visit Berlin's Colonial Agency to hire worker brigades and purchase disease-resistant seeds."
    },
    auction_house = {
        id = "auction_house",
        title = "Live Auctions & Forgery Byte ($00–$FF)",
        body = "Not every canvas on the easel is genuine! In London and Paris, you can commission an Art Expert before bidding. Their evaluation skill is tested against the painting's hidden Forgery Quality Byte to warn you of fakes."
    }
}

Tutorials.rulebook = {
    {
        category = "1. Victory & Uncle Walter's Will",
        title = "Winning the Game",
        keywords = "win victory goal masterpieces net worth uncle walter rules",
        content = [[
• OBJECTIVE: Fulfill Uncle Walter's testament by acquiring the target number of AUTHENTIC Old Master paintings (Default: 5 Originals) AND achieving the highest total Net Worth when the target is reached or by December of the final year.
• BANKRUPTCY: If your Net Worth drops below -10,000 Gold and your bank credit is exhausted, your trading house is liquidated.
• RIVALS: You compete against classic C64 opponents—Gerd, Kurt, and Baron von Stahl—who travel, invest in plantations, and bid against you in live auctions.]]
    },
    {
        category = "2. World Travel & Currency Index",
        title = "London, Paris, Berlin & New York",
        keywords = "travel city london paris berlin new york currency exchange steamship cost days",
        content = [[
From docs/assets.md §6.2, the 4 world hubs operate on distinct Currency Exchange Indices:
• LONDON (Node 0): 350 Gold | 1 Day | 1.00x Base Sterling | Christie's/Sotheby's Auctions, Bank of England low-interest loans, Royal Academy Expert (Skill 210/255).
• PARIS (Node 1): 420 Gold | 2 Days | 0.85x Franc Index | Hôtel Drouot Auctions (cheapest currency multiplier for buying!), Louvre Expert (Skill 228/255).
• BERLIN (Node 2): 280 Gold | 1 Day | 1.15x Goldmark Index | Colonial Plantation Seed & Worker Agency, Northern Renaissance auctions.
• NEW YORK (Node 3): 1,800 Gold | 6 Days Steamship | 1.40x Dollar Index | Highest commodity sale multiplier and high-limit Wall Street loans.]]
    },
    {
        category = "3. Plantation Economics",
        title = "Tea, Coffee, Tobacco & Cocoa",
        keywords = "plantation estate tea coffee tobacco cocoa harvest yield cwt drought frost hail workers berlin",
        content = [[
From docs/assets.md §6.1, four plantation commodities generate your steady cash flow:
• TEA (TEE): 1,200 Gold/acre | Base Yield: 80 cwt/acre | Optimal Harvest: June–August | Risks: Drought, Red spider mite.
• TOBACCO (TABAK): 1,800 Gold/acre | Base Yield: 110 cwt/acre | Optimal Harvest: July–September | Risks: Hail, Blue mold.
• COFFEE (KAFFEE): 2,400 Gold/acre | Base Yield: 65 cwt/acre | Optimal Harvest: September–November | Risks: Frost, Coffee rust fungus.
• COCOA (KAKAO): 3,100 Gold/acre | Base Yield: 50 cwt/acre | Optimal Harvest: October–December | Risks: Flooding, Black pod rot.

Each acre requires 1 Worker Brigade (hired in Berlin or automatically staffed at higher local cost) for full 100% output. Purchasing Hardy Seed Stock in Berlin halves crop losses from pests and weather!]]
    },
    {
        category = "4. Art Auctions & Forgeries",
        title = "The 64-Painting Catalog & Expert Appraisal",
        keywords = "auction art painting vermeer rembrandt rubens durer cranach hals bosch bruegel forgery expert museum",
        content = [[
The catalog contains 64 historical works across 8 Old Masters: Vermeer, Rembrandt, Rubens, Dürer, Cranach, Hals, Bosch, and Bruegel.
• BYTE 6 FORGERY MECHANIC: Roughly 20% of catalog works carry a non-zero Forgery Quality Byte ($01–$FF).
• APPRAISAL: Before or during an auction in London or Paris, hire the resident Art Expert. The expert compares their skill against Byte 6 to report whether the canvas is an Authentic Masterpiece ($00) or a suspected forgery.
• MUSEUM LOANS: In your Portfolio, you can place Authentic paintings on Museum Exhibition Loan to earn monthly prestige royalties while keeping full ownership!]]
    },
    {
        category = "5. Banking & Controls",
        title = "Loans, Interest & Keyboard Shortcuts",
        keywords = "bank loan interest controls keyboard shortcuts save load",
        content = [[
• BANKING: Borrow up to a percentage of your Net Worth (up to 90% in New York, or low-interest 1.8%/mo in London). Interest compounds monthly.
• KEYBOARD SHORTCUTS:
  [1] World Map   [2] City Hub   [3] Auction Room   [4] Portfolio & Ledger
  [SPACE] Bid in Auction / Advance Day in Hub
  [H] or [?] Toggle Searchable Rulebook
  [F5] Quick Save   [F9] Quick Load   [ESC] Title / Back]]
    }
}

return Tutorials
