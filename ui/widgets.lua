-- ui/widgets.lua (Revision 2 — Europa Universalis Grand Strategy Aesthetic)
-- Ornate brass-trimmed panels, real CC artwork renderer, heraldic shields, sparklines, and clean tabs.

local Theme = require("ui.theme")

local Widgets = {}

Widgets.buttons = {}
Widgets.active_tooltip = nil
Widgets.toast = { text = nil, timer = 0, color = Theme.colors.gold_bright }

function Widgets.beginFrame()
    Widgets.buttons = {}
    Widgets.active_tooltip = nil
end

function Widgets.showToast(text, color)
    Widgets.toast.text = text
    Widgets.toast.timer = 3.5
    Widgets.toast.color = color or Theme.colors.gold_bright
end

function Widgets.update(dt)
    if Widgets.toast.timer > 0 then
        Widgets.toast.timer = math.max(0, Widgets.toast.timer - dt)
    end
end

function Widgets.pointInRect(px, py, x, y, w, h)
    return px >= x and px <= x + w and py >= y and py <= y + h
end

local function drawCornerOrnaments(x, y, w, h, color)
    love.graphics.setColor(color or Theme.colors.gold)
    local s = 5
    -- 4 corner brass filigree ticks
    love.graphics.rectangle("fill", x - 1, y - 1, s, 2)
    love.graphics.rectangle("fill", x - 1, y - 1, 2, s)
    love.graphics.rectangle("fill", x + w - s + 1, y - 1, s, 2)
    love.graphics.rectangle("fill", x + w - 1, y - 1, 2, s)
    love.graphics.rectangle("fill", x - 1, y + h - 1, s, 2)
    love.graphics.rectangle("fill", x - 1, y + h - s + 1, 2, s)
    love.graphics.rectangle("fill", x + w - s + 1, y + h - 1, s, 2)
    love.graphics.rectangle("fill", x + w - 1, y + h - s + 1, 2, s)
end

function Widgets.drawCard(x, y, w, h, opts)
    opts = opts or {}
    local bg = opts.bg or Theme.colors.bg_card
    local border = opts.border or Theme.colors.gold_dim
    local radius = opts.radius or 4

    -- Soft elevation shadow
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x + 3, y + 4, w, h, radius, radius)

    -- Main obsidian slate fill
    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", x, y, w, h, radius, radius)

    -- Optional EU5-style royal header banner
    if opts.title then
        local hh = opts.header_height or 34
        love.graphics.setColor(opts.header_bg or Theme.colors.bg_header)
        love.graphics.rectangle("fill", x + 1, y + 1, w - 2, hh, radius, radius)
        love.graphics.setColor(Theme.colors.gold_dim)
        love.graphics.line(x + 2, y + hh, x + w - 2, y + hh)

        love.graphics.setFont(opts.title_font or Theme.fonts.h2)
        love.graphics.setColor(opts.title_color or Theme.colors.gold_bright)
        love.graphics.printf(opts.title, x + 12, y + math.floor((hh - (opts.title_font or Theme.fonts.h2):getHeight()) / 2), w - 24, opts.title_align or "center")
    end

    -- Outer brass border + inner pinstripe
    love.graphics.setLineWidth(opts.border_width or 1.4)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", x, y, w, h, radius, radius)
    love.graphics.setLineWidth(1)

    if opts.ornate ~= false then
        drawCornerOrnaments(x, y, w, h, border)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Widgets.button(id, label, x, y, w, h, onClick, opts)
    opts = opts or {}
    local mx, my = love.mouse.getPosition()
    local hovered = (not opts.disabled) and Widgets.pointInRect(mx, my, x, y, w, h)

    local style = opts.style or "default"
    local bg = Theme.colors.bg_card
    local border = Theme.colors.gold_dim
    local fg = Theme.colors.parchment

    if opts.disabled then
        bg = { 0.09, 0.10, 0.13, 0.60 }
        border = { 0.22, 0.24, 0.28, 0.50 }
        fg = Theme.colors.muted
    elseif style == "primary" then
        bg = hovered and Theme.colors.royal_blue or Theme.colors.vermeer_blue
        border = hovered and Theme.colors.gold_bright or Theme.colors.gold
        fg = Theme.colors.parchment
    elseif style == "gold" then
        bg = hovered and { 0.64, 0.50, 0.20, 1.0 } or { 0.48, 0.37, 0.15, 1.0 }
        border = Theme.colors.gold_bright
        fg = { 1, 0.98, 0.90, 1 }
    elseif style == "success" then
        bg = hovered and { 0.20, 0.52, 0.34, 1.0 } or { 0.15, 0.40, 0.26, 1.0 }
        border = Theme.colors.emerald
        fg = Theme.colors.parchment
    elseif style == "danger" then
        bg = hovered and { 0.58, 0.20, 0.20, 1.0 } or { 0.42, 0.15, 0.15, 1.0 }
        border = Theme.colors.crimson
        fg = Theme.colors.parchment
    elseif style == "tab_active" then
        bg = { 0.18, 0.27, 0.42, 1.0 }
        border = Theme.colors.gold_bright
        fg = Theme.colors.gold_bright
    elseif style == "tab_idle" then
        bg = hovered and { 0.13, 0.17, 0.24, 1.0 } or { 0.08, 0.10, 0.14, 0.95 }
        border = Theme.colors.border_subtle
        fg = hovered and Theme.colors.parchment or Theme.colors.parchment_dim
    else
        bg = hovered and Theme.colors.bg_card_hover or Theme.colors.bg_card
        border = hovered and Theme.colors.gold or Theme.colors.border_subtle
    end

    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setLineWidth(hovered and 1.8 or 1.1)
    love.graphics.setColor(border)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
    love.graphics.setLineWidth(1)

    local font = opts.font or Theme.fonts.body
    love.graphics.setFont(font)
    love.graphics.setColor(fg)
    local th = font:getHeight()
    love.graphics.printf(label, x + 6, y + math.floor((h - th) / 2), w - 12, opts.align or "center")

    if hovered and opts.tooltip then
        Widgets.active_tooltip = { text = opts.tooltip, x = mx + 14, y = my + 14 }
    end

    if not opts.disabled and onClick then
        table.insert(Widgets.buttons, {
            id = id,
            x = x, y = y, w = w, h = h,
            onClick = onClick,
            sfx = opts.sfx or "paper"
        })
    end
    love.graphics.setColor(1, 1, 1, 1)
    return hovered
end

function Widgets.handleMousePressed(mx, my, button)
    if button ~= 1 then return false end
    for i = #Widgets.buttons, 1, -1 do
        local b = Widgets.buttons[i]
        if Widgets.pointInRect(mx, my, b.x, b.y, b.w, b.h) then
            if b.sfx then Theme.playSfx(b.sfx) end
            b.onClick()
            return true
        end
    end
    return false
end

function Widgets.drawShield(city_key, x, y, w, h)
    local img = Theme.shields[city_key]
    if img then
        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = img:getWidth(), img:getHeight()
        love.graphics.draw(img, x, y, 0, w / iw, h / ih)
    else
        love.graphics.setColor(Theme.colors.gold)
        love.graphics.rectangle("line", x, y, w, h, 4, 4)
    end
end

-- Renders the Real Creative Commons / Public Domain Old Master Painting inside an Ornate Gilded Frame
function Widgets.drawPaintingCanvas(artwork, x, y, w, h, opts)
    opts = opts or {}
    if not artwork then return end

    -- Dark velvet shadow behind frame
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", x + 3, y + 4, w, h, 4, 4)

    local pad = math.max(6, math.floor(math.min(w, h) * 0.07))
    local cx, cy = x + pad, y + pad
    local cw, ch = w - pad * 2, h - pad * 2

    -- Draw the real painting image (loaded from assets/paintings/art_XX.jpg or .png)
    local img = Theme.getPaintingImage(artwork.id)
    if img and img.getWidth then
        love.graphics.setColor(0.08, 0.07, 0.06, 1)
        love.graphics.rectangle("fill", cx, cy, cw, ch)

        local iw, ih = img:getWidth(), img:getHeight()
        -- Cover/fit cleanly inside the frame opening using a scissor rect
        love.graphics.setScissor(cx, cy, cw, ch)
        local scale = math.max(cw / iw, ch / ih)
        local dw, dh = iw * scale, ih * scale
        local dx = cx + (cw - dw) * 0.5
        local dy = cy + (ch - dh) * 0.5
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, dx, dy, 0, scale, scale)
        love.graphics.setScissor()
    else
        love.graphics.setColor(0.18, 0.24, 0.38, 1)
        love.graphics.rectangle("fill", cx, cy, cw, ch)
    end

    -- Draw the Ornate Gilded Frame overlay
    if Theme.ornate_frame and Theme.ornate_frame.getWidth then
        love.graphics.setColor(1, 1, 1, 1)
        local fw, fh = Theme.ornate_frame:getWidth(), Theme.ornate_frame:getHeight()
        love.graphics.draw(Theme.ornate_frame, x, y, 0, w / fw, h / fh)
    else
        love.graphics.setColor(Theme.colors.gold)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x, y, w, h, 4, 4)
        love.graphics.setLineWidth(1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Widgets.drawPortrait(player_or_key, x, y, w, h, opts)
    opts = opts or {}
    local pkey = "player"
    if type(player_or_key) == "string" then
        pkey = player_or_key
    elseif type(player_or_key) == "table" then
        local name = (player_or_key.name or ""):lower()
        if name:find("gerd") then pkey = "gerd"
        elseif name:find("kurt") then pkey = "kurt"
        elseif name:find("baron") then pkey = "baron"
        else pkey = "player" end
    end

    love.graphics.setColor(0.06, 0.07, 0.09, 1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    local img = Theme.portraits[pkey]
    if img and img.getWidth then
        love.graphics.setScissor(x + 2, y + 2, w - 4, h - 4)
        local iw, ih = img:getWidth(), img:getHeight()
        local scale = math.max((w - 4) / iw, (h - 4) / ih)
        local dx = x + 2 + ((w - 4) - iw * scale) * 0.5
        local dy = y + 2 + ((h - 4) - ih * scale) * 0.3
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, dx, dy, 0, scale, scale)
        love.graphics.setScissor()
    end

    love.graphics.setColor(opts.is_high and Theme.colors.gold_bright or Theme.colors.gold)
    love.graphics.setLineWidth(opts.is_high and 2.5 or 1.5)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function Widgets.drawSparkline(values, x, y, w, h, color)
    love.graphics.setColor(Theme.colors.bg_inset)
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)
    love.graphics.setColor(Theme.colors.border_subtle)
    love.graphics.rectangle("line", x, y, w, h, 3, 3)

    if not values or #values < 2 then return end
    local min_v, max_v = values[1], values[1]
    for _, v in ipairs(values) do
        if v < min_v then min_v = v end
        if v > max_v then max_v = v end
    end
    local span = math.max(4, max_v - min_v)
    local pts = {}
    for i, v in ipairs(values) do
        local px = x + 4 + ((i - 1) / (#values - 1)) * (w - 8)
        local py = y + h - 4 - ((v - min_v) / span) * (h - 8)
        table.insert(pts, px)
        table.insert(pts, py)
    end
    love.graphics.setColor(color or Theme.colors.gold_bright)
    love.graphics.setLineWidth(1.8)
    love.graphics.line(pts)
    love.graphics.setLineWidth(1)
    love.graphics.circle("fill", pts[#pts - 1], pts[#pts], 2.5)
    love.graphics.setColor(1, 1, 1, 1)
end

function Widgets.drawRivalBadge(player, x, y, w, h, opts)
    opts = opts or {}
    local is_high = opts.is_high_bidder
    Widgets.drawCard(x, y, w, h, {
        bg = is_high and { 0.17, 0.24, 0.18, 0.98 } or Theme.colors.bg_card,
        border = is_high and Theme.colors.gold_bright or Theme.colors.border_subtle,
        border_width = is_high and 2.2 or 1.1,
        ornate = false
    })

    local pw = h - 12
    Widgets.drawPortrait(player, x + 6, y + 6, pw, pw, { is_high = is_high })

    local tx = x + pw + 14
    love.graphics.setFont(Theme.fonts.body_lg)
    love.graphics.setColor(Theme.colors.parchment)
    love.graphics.print(player.name, tx, y + 6)

    love.graphics.setFont(Theme.fonts.small)
    love.graphics.setColor(Theme.colors.gold)
    love.graphics.print(Theme.formatGold(player.cash), tx, y + 25)

    if opts.status_text then
        love.graphics.setColor(is_high and Theme.colors.emerald or Theme.colors.parchment_dim)
        love.graphics.print(opts.status_text, tx, y + 41)
    end

    if opts.paddle_up then
        love.graphics.setColor(Theme.colors.gold_bright)
        love.graphics.circle("fill", x + w - 20, y + 20, 10)
        love.graphics.setColor(Theme.colors.ink_dark)
        love.graphics.setFont(Theme.fonts.small)
        love.graphics.printf("BID", x + w - 34, y + 14, 28, "center")
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Widgets.drawOverlays()
    local sw, sh = love.graphics.getDimensions()

    if Widgets.active_tooltip then
        local tt = Widgets.active_tooltip
        local font = Theme.fonts.small
        love.graphics.setFont(font)
        local max_w = 270
        local _, wrapped = font:getWrap(tt.text, max_w)
        local box_w = max_w + 20
        local box_h = #wrapped * font:getHeight() + 16
        local bx = math.min(sw - box_w - 10, tt.x)
        local by = math.min(sh - box_h - 10, tt.y)

        love.graphics.setColor(0.05, 0.06, 0.09, 0.97)
        love.graphics.rectangle("fill", bx, by, box_w, box_h, 4, 4)
        love.graphics.setColor(Theme.colors.gold)
        love.graphics.rectangle("line", bx, by, box_w, box_h, 4, 4)
        love.graphics.setColor(Theme.colors.parchment)
        love.graphics.printf(tt.text, bx + 10, by + 8, max_w, "left")
    end

    if Widgets.toast.timer > 0 and Widgets.toast.text then
        local alpha = math.min(1.0, Widgets.toast.timer * 1.5)
        local font = Theme.fonts.body_lg
        love.graphics.setFont(font)
        local tw = math.min(sw - 80, font:getWidth(Widgets.toast.text) + 44)
        local th = 36
        local tx = math.floor((sw - tw) / 2)
        local ty = sh - 88

        love.graphics.setColor(0.07, 0.09, 0.14, 0.95 * alpha)
        love.graphics.rectangle("fill", tx, ty, tw, th, 6, 6)
        love.graphics.setColor(Widgets.toast.color[1], Widgets.toast.color[2], Widgets.toast.color[3], alpha)
        love.graphics.setLineWidth(1.8)
        love.graphics.rectangle("line", tx, ty, tw, th, 6, 6)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.96, 0.94, 0.88, alpha)
        love.graphics.printf(Widgets.toast.text, tx + 12, ty + 9, tw - 24, "center")
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Widgets
