local config = require "config"
local Game = require "Game"
local PlanetEntity = require "PlanetEntity"
local ShipEntity = require "ShipEntity"
local utils = require "utils"

function love.load()
    love.mouse.setVisible(false)

    local windowConfig = config.window or {}

    local windowWidth, windowHeight = unpack(windowConfig.size or {256, 256})
    local windowFlags = {}

    windowFlags.fsaa = windowConfig.fsaa
    windowFlags.fullscreen = windowConfig.fullscreen
    windowFlags.fullscreentype = windowConfig.fullscreentype
    windowFlags.highdpi = windowConfig.highdpi
    windowFlags.resizable = windowConfig.resizable

    love.window.setMode(windowWidth, windowHeight, windowFlags)

    local noiseShaderSource = love.filesystem.read("resources/shaders/noise2D.glsl")

    local planetShader = love.graphics.newShader(noiseShaderSource .. [[
        uniform float seed = 0;
        uniform float radius = 1;
        uniform float scale = 0.01;

        vec4 effect(vec4 color, Image image, vec2 local, vec2 screen) {
            float distance = length(2.0 * local - 1.0);
            float sphereDensity = 1.0 - smoothstep(1.0 - 10.0 / radius, 1.0 + 10.0 / radius, distance);

            // Generate tunnel density.
            float tunnelDensity = 2.0 * abs(snoise(scale * radius * local + seed));

            float density = sphereDensity * tunnelDensity;

            // Anti-aliasing.
            float r = fwidth(density);
            float a = gl_Color.a * smoothstep(0.5 - r, 0.5 + r, density);

            return vec4(color.rgb, color.a * a);
        }
    ]])

    game = Game.new(planetShader)

    local starArgs = {}
    starArgs.density = 1000
    starArgs.radius = config.minStarRadius + (config.maxStarRadius - config.minStarRadius) * love.math.random()

    starArgs.angle = 2 * math.pi * love.math.random()

    local mass = utils.getSphereMass(starArgs.radius, starArgs.density)
    starArgs.angularVelocity = utils.getOrbitalVelocity(mass, starArgs.radius) / starArgs.radius

    local temperature = math.random(0, 511)
    starArgs.color = {255, 127, 0, 255}

    local starEntity = PlanetEntity.new(starArgs)
    game:addEntity(starEntity)

    local starSystemRadius = starEntity.radius * utils.getRandomFloat(2, 5)

    local planetCount = 3

    for i = 1, planetCount do
        local planetArgs = {}
        planetArgs.radius = config.minPlanetRadius + (config.maxPlanetRadius - config.minPlanetRadius) * love.math.random()
        planetArgs.density = 1000

        planetArgs.angle = 2 * math.pi * love.math.random()

        planetArgs.parentEntity = starEntity
        planetArgs.orbitalRadius = starSystemRadius + utils.getRandomFloat(2, 5) * planetArgs.radius
        starSystemRadius = planetArgs.orbitalRadius + utils.getRandomFloat(2, 5) * planetArgs.radius
        local orbitalSign = utils.getRandomSign()
        planetArgs.orbitalVelocity = orbitalSign * utils.getOrbitalVelocity(starEntity:getMass(), planetArgs.orbitalRadius)
        planetArgs.orbitalAngle = 2 * math.pi * love.math.random()

        local mass = utils.getSphereMass(planetArgs.radius, planetArgs.density)
        planetArgs.angularVelocity = utils.getOrbitalVelocity(mass, planetArgs.radius) / planetArgs.radius

        local hue = love.math.random()
        local saturation = utils.getRandomFloat(0.5, 1)
        local lightness = utils.getRandomFloat(0.25, 0.75)
        local red, green, blue = utils.toRgbFromHsl(hue, saturation, lightness)
        planetArgs.color = {utils.toByteFromFloat(red, green, blue, 1)}

        local planetEntity = PlanetEntity.new(planetArgs)
        game:addEntity(planetEntity)
    end

    local shipOrbitalAngle = 2 * math.pi * love.math.random()
    local shipEntity = ShipEntity.new()
    game:addEntity(shipEntity)
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.keypressed(key, isrepeat)
    if key == "return" and not isrepeat then
        local screenshot = love.graphics.newScreenshot()
        screenshot:encode("screenshot.png")
        print("Saved screenshot: " .. love.filesystem.getSaveDirectory() .. "/screenshot.png")
    end

    if key == "escape" and not isrepeat then
        love.event.quit()
    end
end
