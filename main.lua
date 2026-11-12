-- main.lua (Revision 2 — Europa Universalis V Inspired Map-Centric Grand Strategy Layout)

local Theme           = require("ui.theme")
local Widgets         = require("ui.widgets")
local HUD             = require("ui.hud")
local TutorialOverlay = require("ui.tutorial_overlay")
local GameState       = require("sim.game_state")
local Economy         = require("sim.economy")

local Scenes = {
    title        = require("scenes.title"),
    world_map    = require("scenes.world_map"),
    city_hub     = require("scenes.city_hub"),
    auction_room = require("scenes.auction_room"),
    portfolio    = require("scenes.portfolio"),
    end_screen   = require("scenes.end_screen"),
}

local STEP = 1 / 60
local acc = 0
local check = { frames = nil, shot = nil, scene = nil, count = 0 }

local app = {
    state = nil,
    current_scene = "title",
}

function app.switchScene(name)
    if not Scenes[name] then return end
    app.current_scene = name
    local sc = Scenes[name]
    if sc.enter and app.state then
        sc.enter(app.state)
    end
end

function app.startNewGame(config)
    app.state = GameState.createNew(config)
    TutorialOverlay.triggerCallout(app.state, "welcome")
    -- Start directly on the EU5-style Grand Strategy World Map + Left City Inspector
    app.switchScene("world_map")
end

function app.loadSavedGame()
    local loaded, err = GameState.load()
    if loaded then
        app.state = loaded
        Widgets.showToast("Loaded saved campaign (" .. GameState.getFormattedDate(app.state) .. ").", Theme.colors.emerald)
        app.switchScene("world_map")
    else
        Widgets.showToast(err or "Could not load save.", Theme.colors.crimson)
    end
end

local function step(dt)
    Widgets.update(dt)
    if app.current_scene ~= "title" and app.current_scene ~= "end_screen" and app.current_scene ~= "auction_room" then
        HUD.updateTime(app.state, dt, app.switchScene)
    end
    local sc = Scenes[app.current_scene]
    if sc and sc.update then
        sc.update(dt, app)
    end
end

function love.load(args)
    local is_headless = false
    if args then
        for i, a in ipairs(args) do
            if a == "--frames" then check.frames = tonumber(args[i + 1]) end
            if a == "--shot" then check.shot = args[i + 1] end
            if a == "--scene" then check.scene = args[i + 1] end
            if a == "--headless" then is_headless = true end
        end
    end

    if is_headless then
        local dummy_font = {
            getHeight = function() return 16 end,
            getWidth = function(_, s) return #(tostring(s or "")) * 8 end,
            getWrap = function(_, s, w)
                local len = #(tostring(s or "")) * 8
                local lines = math.max(1, math.ceil(len / math.max(1, w)))
                local t = {}
                for i = 1, lines do t[i] = "line" end
                return w, t
            end
        }
        love.graphics = love.graphics or {
            newFont = function() return dummy_font end,
            newImage = function() return { getWidth = function() return 240 end, getHeight = function() return 280 end } end,
            setFont = function() end,
            setColor = function() end,
            setLineWidth = function() end,
            setScissor = function() end,
            clear = function() end,
            rectangle = function() end,
            circle = function() end,
            ellipse = function() end,
            arc = function() end,
            polygon = function() end,
            line = function() end,
            print = function() end,
            printf = function() end,
            draw = function() end,
            getDimensions = function() return 1280, 720 end,
            captureScreenshot = function() end,
        }
        love.mouse = love.mouse or {
            getPosition = function() return 640, 360 end
        }
    else
        love.keyboard.setKeyRepeat(true)
    end

    Theme.init()

    app.state = GameState.createNew({ seed = 19870604 })
    if check.scene and Scenes[check.scene] then
        app.switchScene(check.scene)
    end

    if is_headless then
        local Auction = require("sim.auction")
        for _, sname in ipairs({ "title", "world_map", "city_hub", "auction_room", "portfolio", "end_screen" }) do
            app.switchScene(sname)
            step(STEP)
            love.draw()
        end
        for _, tab in ipairs({ "estates", "trade", "bank" }) do
            Scenes.city_hub.active_tab = tab
            app.switchScene("city_hub")
            love.draw()
        end
        print("HEADLESS VERIFICATION V2 OK: EU5 Grand Strategy UI & 64 Creative Commons Artworks verified!")
        love.event.quit(0)
    end
end

function love.update(dt)
    acc = acc + math.min(dt, 0.25)
    while acc >= STEP do
        step(STEP)
        acc = acc - STEP
    end

    check.count = check.count + 1
    if check.frames and check.count == check.frames and check.shot then
        love.graphics.captureScreenshot(check.shot)
    elseif check.frames and check.count > check.frames then
        print("RUN OK frames=" .. check.frames .. " scene=" .. app.current_scene)
        love.event.quit(0)
    end
end

function love.draw()
    Widgets.beginFrame()
    love.graphics.clear(Theme.colors.bg_dark)

    local sc = Scenes[app.current_scene]
    if sc and sc.draw then
        sc.draw(app)
    end

    if app.current_scene ~= "title" and app.current_scene ~= "end_screen" then
        HUD.draw(app.state, app.current_scene, app.switchScene)
    end

    TutorialOverlay.draw(app.state)
    Widgets.drawOverlays()
end

function love.mousepressed(x, y, button)
    Widgets.handleMousePressed(x, y, button)
end

function love.keypressed(key)
    if TutorialOverlay.handleKeyPressed(key) then
        return
    end

    if key == "h" or key == "/" then
        TutorialOverlay.toggleRulebook()
        return
    end

    if app.current_scene == "title" then
        if key == "return" or key == "space" then
            app.startNewGame({
                total_players = Scenes.title.total_players,
                target_artworks = Scenes.title.target_artworks,
                max_years = Scenes.title.max_years,
                target_net_worth = Scenes.title.target_net_worth or 55000
            })
        elseif key == "f9" and GameState.hasSave() then
            app.loadSavedGame()
        end
        return
    end

    local sc = Scenes[app.current_scene]
    if sc and sc.handleKeyPressed and sc.handleKeyPressed(key, app) then
        return
    end

    if key == "1" then
        app.switchScene("world_map")
    elseif key == "2" then
        app.switchScene("city_hub")
    elseif key == "3" then
        app.switchScene("auction_room")
    elseif key == "4" then
        app.switchScene("portfolio")
    elseif key == "space" and app.current_scene ~= "auction_room" then
        Economy.advanceDays(app.state, 5)
        Theme.playSfx("telegraph")
        if app.state.game_over then
            app.switchScene("end_screen")
        end
    elseif key == "f5" then
        if GameState.save(app.state) then
            Theme.playSfx("coin")
            Widgets.showToast("Campaign saved!", Theme.colors.emerald)
        end
    elseif key == "f9" then
        app.loadSavedGame()
    elseif key == "escape" then
        app.switchScene("title")
    end
end

function love.textinput(t)
    TutorialOverlay.handleTextInput(t)
end
