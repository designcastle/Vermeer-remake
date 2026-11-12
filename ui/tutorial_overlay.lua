-- ui/tutorial_overlay.lua
-- Non-intrusive callout cards, contextual hints, searchable Rulebook modal

local Theme     = require("ui.theme")
local Widgets   = require("ui.widgets")
local Tutorials = require("data.tutorials")

local TutorialOverlay = {
    rulebook_open = false,
    search_query = "",
    selected_idx = 1,
    active_callout = nil
}

function TutorialOverlay.triggerCallout(state, callout_id)
    if not state or not state.tutorial_enabled then return end
    if state.seen_tutorials[callout_id] then return end
    local entry = Tutorials.callouts[callout_id]
    if entry then
        state.seen_tutorials[callout_id] = true
        TutorialOverlay.active_callout = entry
    end
end

function TutorialOverlay.toggleRulebook()
    TutorialOverlay.rulebook_open = not TutorialOverlay.rulebook_open
    Theme.playSfx("paper")
end

function TutorialOverlay.getFilteredEntries()
    local q = TutorialOverlay.search_query:lower()
    if q == "" then return Tutorials.rulebook end
    local out = {}
    for _, item in ipairs(Tutorials.rulebook) do
        local hay = (item.category .. " " .. item.title .. " " .. item.keywords .. " " .. item.content):lower()
        if hay:find(q, 1, true) then
            table.insert(out, item)
        end
    end
    return out
end

function TutorialOverlay.handleKeyPressed(key)
    if not TutorialOverlay.rulebook_open then return false end
    if key == "escape" then
        TutorialOverlay.rulebook_open = false
        return true
    elseif key == "backspace" then
        TutorialOverlay.search_query = TutorialOverlay.search_query:sub(1, -2)
        TutorialOverlay.selected_idx = 1
        return true
    elseif key == "down" then
        local list = TutorialOverlay.getFilteredEntries()
        TutorialOverlay.selected_idx = math.min( math.max(1, #list), TutorialOverlay.selected_idx + 1)
        return true
    elseif key == "up" then
        TutorialOverlay.selected_idx = math.max(1, TutorialOverlay.selected_idx - 1)
        return true
    end
    return true
end

function TutorialOverlay.handleTextInput(t)
    if not TutorialOverlay.rulebook_open then return false end
    if #TutorialOverlay.search_query < 28 and t:match("[%w%s%-]") then
        TutorialOverlay.search_query = TutorialOverlay.search_query .. t
        TutorialOverlay.selected_idx = 1
    end
    return true
end

function TutorialOverlay.draw(state)
    local sw, sh = love.graphics.getDimensions()

    -- 1. Non-intrusive Contextual Micro-Tutorial Callout Card (top-right corner below HUD)
    if TutorialOverlay.active_callout and not TutorialOverlay.rulebook_open then
        local c = TutorialOverlay.active_callout
        local cw, ch = 390, 148
        local cx, cy = sw - cw - 18, 66

        Widgets.drawCard(cx, cy, cw, ch, {
            bg = { 0.14, 0.17, 0.24, 0.97 },
            border = Theme.colors.gold_bright,
            border_width = 2,
            title = "Tip: " .. c.title
        })

        love.graphics.setFont(Theme.fonts.body)
        love.graphics.setColor(Theme.colors.parchment)
        love.graphics.printf(c.body, cx + 14, cy + 44, cw - 28, "left")

        Widgets.button("callout_dismiss", "Got It", cx + cw - 92, cy + ch - 36, 78, 26, function()
            TutorialOverlay.active_callout = nil
        end, { style = "gold", font = Theme.fonts.small })

        Widgets.button("callout_rules", "Open Rulebook", cx + 14, cy + ch - 36, 116, 26, function()
            TutorialOverlay.active_callout = nil
            TutorialOverlay.rulebook_open = true
        end, { font = Theme.fonts.small })
    end

    -- 2. Searchable Rulebook Modal
    if TutorialOverlay.rulebook_open then
        love.graphics.setColor(0, 0, 0, 0.72)
        love.graphics.rectangle("fill", 0, 0, sw, sh)

        local mw, mh = math.min(920, sw - 60), math.min(560, sh - 70)
        local mx, my = math.floor((sw - mw) / 2), math.floor((sh - mh) / 2)

        Widgets.drawCard(mx, my, mw, mh, {
            bg = { 0.11, 0.13, 0.17, 0.99 },
            border = Theme.colors.gold_bright,
            border_width = 2.5,
            title = "VERMEER (1987) — ENCYCLOPEDIA & DISASSEMBLED TABLES"
        })

        -- Search Input Box
        love.graphics.setColor(0.07, 0.08, 0.11, 1)
        love.graphics.rectangle("fill", mx + 18, my + 48, 340, 32, 5, 5)
        love.graphics.setColor(Theme.colors.gold)
        love.graphics.rectangle("line", mx + 18, my + 48, 340, 32, 5, 5)
        love.graphics.setFont(Theme.fonts.body)
        love.graphics.setColor(Theme.colors.parchment)
        local q_display = TutorialOverlay.search_query == "" and "Type to filter topics (e.g. 'forgery', 'cocoa')..." or ("Filter: " .. TutorialOverlay.search_query .. "_")
        love.graphics.print(q_display, mx + 28, my + 56)

        if TutorialOverlay.search_query ~= "" then
            Widgets.button("rule_clear", "Clear", mx + 368, my + 48, 64, 32, function()
                TutorialOverlay.search_query = ""
                TutorialOverlay.selected_idx = 1
            end, { font = Theme.fonts.small })
        end

        Widgets.button("rule_close", "Close [Esc]", mx + mw - 114, my + 48, 96, 32, function()
            TutorialOverlay.rulebook_open = false
        end, { style = "danger", font = Theme.fonts.small })

        local entries = TutorialOverlay.getFilteredEntries()
        local list_w = 270
        for i, item in ipairs(entries) do
            local by = my + 92 + (i - 1) * 46
            local is_sel = (i == TutorialOverlay.selected_idx)
            Widgets.button("rule_tab_" .. i, item.category, mx + 18, by, list_w, 38, function()
                TutorialOverlay.selected_idx = i
            end, {
                style = is_sel and "primary" or "default",
                align = "left",
                font = Theme.fonts.body
            })
        end

        -- Detail Pane
        local dx, dy = mx + list_w + 34, my + 92
        local dw, dh = mw - list_w - 52, mh - 110
        Widgets.drawCard(dx, dy, dw, dh, {
            bg = { 0.08, 0.09, 0.12, 1.0 },
            border = Theme.colors.border_subtle
        })

        local active = entries[TutorialOverlay.selected_idx] or entries[1]
        if active then
            love.graphics.setFont(Theme.fonts.h1)
            love.graphics.setColor(Theme.colors.gold_bright)
            love.graphics.print(active.title, dx + 18, dy + 16)

            love.graphics.setFont(Theme.fonts.body_lg)
            love.graphics.setColor(Theme.colors.parchment)
            love.graphics.printf(active.content, dx + 18, dy + 56, dw - 36, "left")
        else
            love.graphics.setFont(Theme.fonts.body_lg)
            love.graphics.setColor(Theme.colors.muted)
            love.graphics.print("No rulebook entries match your search.", dx + 18, dy + 24)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return TutorialOverlay
