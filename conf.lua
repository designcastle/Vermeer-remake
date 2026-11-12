function love.conf(t)
    t.version = "11.5"
    t.identity = "vermeer-remake-v2"
    t.window.title = "VERMEER (1987) — Imperial Grand Strategy Edition (v2)"
    t.window.width = 1280
    t.window.height = 720
    t.window.minwidth = 1024
    t.window.minheight = 600
    t.window.resizable = true
    t.window.highdpi = true
    t.window.vsync = 1
    t.modules.joystick = false
    t.modules.physics = false

    if arg and table.concat(arg, " "):find("--headless", 1, true) then
        t.window = false
        t.modules.window = false
        t.modules.graphics = false
        t.modules.audio = false
    end
end

if arg and (table.concat(arg, " "):find("--frames", 1, true) or table.concat(arg, " "):find("--headless", 1, true)) then
    function love.errorhandler(msg)
        print("ERROR: " .. tostring(msg) .. "\n" .. debug.traceback("", 2))
        return function() return 1 end
    end
end
