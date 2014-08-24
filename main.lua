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

    local shader = love.graphics.newShader(noiseShaderSource .. [[
        uniform float scale = 1;

        vec4 effect(vec4 color, Image image, vec2 local, vec2 screen) {
            number noise = snoise(scale * local);
            if (-0.25 < noise && noise < 0.25) {
                return vec4(0.0, 0.0, 0.0, 0.0);
            } else {
                return color;
            }
        }
    ]])

    game = Game.new(shader)

    local starArgs = {}
    starArgs.planetType = "star"
    starArgs.density = 1000
    starArgs.radius = config.minStarRadius + (config.maxStarRadius - config.minStarRadius) * love.math.random()

    starArgs.angle = 2 * math.pi * love.math.random()

    local mass = utils.getSphereMass(starArgs.radius, starArgs.density)
    starArgs.angularVelocity = utils.getOrbitalVelocity(mass, starArgs.radius) / starArgs.radius

    local temperature = math.random(0, 511)
    starArgs.color = {255, utils.clamp(temperature, 0, 255), utils.clamp(temperature - 256, 0, 255), 255}

    local starEntity = PlanetEntity.new(starArgs)
    game:addEntity(starEntity)

    local starSystemRadius = starEntity.radius * 3

    local planetCount = love.math.random(config.minPlanetCount, config.maxPlanetCount)
    for i = 1, planetCount do
        local planetArgs = {}
        planetArgs.radius = config.minPlanetRadius + (config.maxPlanetRadius - config.minPlanetRadius) * love.math.random()
        planetArgs.density = 1000

        planetArgs.angle = 2 * math.pi * love.math.random()

        planetArgs.color = {
            love.math.random(0, 255),
            love.math.random(0, 255),
            love.math.random(0, 255),
            255,
        }

        planetArgs.parentEntity = starEntity
        planetArgs.orbitalRadius = starSystemRadius + 3 * planetArgs.radius
        starSystemRadius = starSystemRadius + 6 * planetArgs.radius
        local orbitalSign = utils.getRandomSign()
        planetArgs.orbitalVelocity = orbitalSign * utils.getOrbitalVelocity(starEntity:getMass(), planetArgs.orbitalRadius)
        planetArgs.orbitalAngle = 2 * math.pi * love.math.random()

        local mass = utils.getSphereMass(planetArgs.radius, planetArgs.density)
        planetArgs.angularVelocity = utils.getOrbitalVelocity(mass, planetArgs.radius) / planetArgs.radius

        local planetEntity = PlanetEntity.new(planetArgs)
        game:addEntity(planetEntity)
    end

    local shipOrbitalAngle = 2 * math.pi * love.math.random()
    local shipEntity = ShipEntity.new({
        position = {starSystemRadius * math.cos(shipOrbitalAngle), starSystemRadius * math.sin(shipOrbitalAngle)},
        angle = shipOrbitalAngle + math.pi,
    })
    game:addEntity(shipEntity)
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end
