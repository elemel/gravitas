local AsteroidBeltEntity = require "AsteroidBeltEntity"
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
    local planetShaderSource = love.filesystem.read("resources/shaders/planet.glsl")
    local asteroidBeltShaderSource = love.filesystem.read("resources/shaders/asteroidBelt.glsl")

    local planetShader = love.graphics.newShader(noiseShaderSource .. planetShaderSource)
    local asteroidBeltShader = love.graphics.newShader(noiseShaderSource .. asteroidBeltShaderSource)
    local shaders = {planet = planetShader, asteroidBelt = asteroidBeltShader}
    game = Game.new(shaders)

    local starArgs = {}
    starArgs.planetType = "star"
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

    for i = 1, 3 do
        local planetArgs = {}
        planetArgs.radius = config.minPlanetRadius + (config.maxPlanetRadius - config.minPlanetRadius) * love.math.random()
        planetArgs.density = 1000

        planetArgs.angle = 2 * math.pi * love.math.random()

        planetArgs.parentEntity = starEntity
        planetArgs.orbitalRadius = starSystemRadius + utils.getRandomFloat(5, 10) * planetArgs.radius
        starSystemRadius = planetArgs.orbitalRadius + utils.getRandomFloat(5, 10) * planetArgs.radius
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

        if i == 2 then
            local asteroidBeltArgs = {}
            asteroidBeltArgs.majorRadius = 2 * planetEntity.radius
            asteroidBeltArgs.minorRadius = 100
            asteroidBeltArgs.stepRadius = 100
            local angularVelocitySign = utils.getRandomSign()
            asteroidBeltArgs.angularVelocity = angularVelocitySign *
                utils.getOrbitalVelocity(planetEntity:getMass(), asteroidBeltArgs.majorRadius) /
                asteroidBeltArgs.majorRadius
            asteroidBeltArgs.parentEntity = planetEntity
            local asteroidBeltEntity = AsteroidBeltEntity.new(asteroidBeltArgs)
            game:addEntity(asteroidBeltEntity)
        end

        if i == 3 then
            local moonArgs = {}

            moonArgs.radius = config.minMoonRadius + (config.maxMoonRadius - config.minMoonRadius) * love.math.random()
            moonArgs.density = 1000

            moonArgs.angle = 2 * math.pi * love.math.random()

            moonArgs.parentEntity = planetEntity
            moonArgs.orbitalRadius = planetArgs.radius + utils.getRandomFloat(5, 10) * moonArgs.radius
            local orbitalSign = utils.getRandomSign()
            moonArgs.orbitalVelocity = orbitalSign * utils.getOrbitalVelocity(planetEntity:getMass(), moonArgs.orbitalRadius)
            moonArgs.orbitalAngle = 2 * math.pi * love.math.random()

            local mass = utils.getSphereMass(moonArgs.radius, moonArgs.density)
            moonArgs.angularVelocity = utils.getOrbitalVelocity(mass, moonArgs.radius) / moonArgs.radius

            local hue = love.math.random()
            local saturation = utils.getRandomFloat(0.5, 1)
            local lightness = utils.getRandomFloat(0.25, 0.75)
            local red, green, blue = utils.toRgbFromHsl(hue, saturation, lightness)
            moonArgs.color = {utils.toByteFromFloat(red, green, blue, 1)}

            local moonEntity = PlanetEntity.new(moonArgs)
            game:addEntity(moonEntity)
        end
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
