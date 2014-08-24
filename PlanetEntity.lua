local Camera = require "Camera"
local config = require "config"
local utils = require "utils"

local PlanetEntity = {}
PlanetEntity.__index = PlanetEntity

function PlanetEntity.new(args)
    local entity = {}
    setmetatable(entity, PlanetEntity)

    args = args or {}

    entity.planetType = args.planetType or "planet"
    entity.radius = args.radius or 1
    entity.density = args.density or 1000
    entity.position = args.position or {0, 0}
    entity.angle = args.angle or 0
    entity.angularVelocity = args.angularVelocity or 0
    entity.color = args.color or {255, 255, 255, 255}

    entity.parentEntity = args.parentEntity
    entity.orbitalRadius = args.orbitalRadius or 1
    entity.orbitalVelocity = args.orbitalVelocity or 0
    entity.orbitalAngle = args.orbitalAngle or 0

    return entity
end

function PlanetEntity:getType()
    return "planet"
end

function PlanetEntity:update(dt)
    if self.parentEntity then
        local x0, y0 = unpack(self.parentEntity.position)
        local x, y = unpack(self.position)
        self.orbitalAngle = self.orbitalAngle + self.orbitalVelocity / self.orbitalRadius * dt
        x = x0 + math.cos(self.orbitalAngle) * self.orbitalRadius
        y = y0 + math.sin(self.orbitalAngle) * self.orbitalRadius
        self.position = {x, y}
    end

    self.angle = self.angle + self.angularVelocity * dt
end

function PlanetEntity:draw()
    local x, y = unpack(self.position)
    local directionX, directionY = self:getDirection()

    if self.parentEntity then
        local x0, y0 = unpack(self.parentEntity.position)
        love.graphics.setColor(255, 255, 255, 63)
        love.graphics.circle("line", x0, y0, self.orbitalRadius, config.circleSegmentCount)
    end

    if self.planetType == "star" then
        love.graphics.setColor(unpack(self.color))
        love.graphics.circle("fill", x, y, self.radius, config.circleSegmentCount)
    elseif self.planetType == "planet" then
        love.graphics.setColor(unpack(self.color))
        love.graphics.setShader(self.game.shader)
        self.game.shader:send("scale", 0.005 * self.radius)
        love.graphics.draw(self.game.circleMesh, x, y, self.angle, self.radius)
        love.graphics.setShader(nil)
    end
end

function PlanetEntity:debugDraw()
    if self.planetType == "planet" then
        if not self.debugCanvas then
            local size = utils.clamp(utils.round(0.2 * self.radius), 16, 256)
            self.debugCanvas = love.graphics.newCanvas(size, size)
            self.debugCanvas:setFilter("nearest")
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.setCanvas(self.debugCanvas)
            love.graphics.setShader(self.game.shader)
            self.game.shader:send("scale", 0.005 * self.radius)
            love.graphics.push()
            love.graphics.origin()
            love.graphics.draw(self.game.circleMesh, 0.5 * size, 0.5 * size, 0, 0.5 * size, 0.5 * size)
            love.graphics.pop()
            love.graphics.setShader(nil)
            love.graphics.setCanvas(nil)
        end

        self.game.circleMesh:setImage(self.debugCanvas)
        love.graphics.setColor(0, 255, 0, 127)
        local x, y = unpack(self.position)
        love.graphics.draw(self.game.circleMesh, x, y, self.angle, self.radius)
        self.game.circleMesh:setImage(nil)
    end
end

function PlanetEntity:getMass()
    return utils.getSphereMass(self.radius, self.density)
end

function PlanetEntity:getDirection()
    return math.cos(self.angle), math.sin(self.angle)
end

return PlanetEntity
