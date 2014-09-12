local config = require "config"
local utils = require "utils"
local noise2D = require "noise2D"

local AsteroidBeltEntity = {}
AsteroidBeltEntity.__index = AsteroidBeltEntity

function AsteroidBeltEntity.new(args)
    local entity = {}
    setmetatable(entity, AsteroidBeltEntity)

    entity.position = args.position or {0, 0}
    entity.angle = args.angle or 0
    entity.angularVelocity = args.angularVelocity or 0
    entity.color = args.color or {255, 255, 255, 255}

    entity.majorRadius = args.majorRadius or 1
    entity.minorRadius = args.minorRadius or 1
    entity.stepRadius = args.stepRadius or 1

    entity.parentEntity = args.parentEntity

    return entity
end

function AsteroidBeltEntity:getType()
    return "asteroidBelt"
end

function AsteroidBeltEntity:create()
    self:updatePosition()

    self.mesh = love.graphics.newMesh({
        {-1, -1, 0, 0},
        {1, -1, 1, 0},
        {1, 1, 1, 1},
        {-1, 1, 0, 1},
    })
end

function AsteroidBeltEntity:update(dt)
    self:updatePhysics(dt)
end

function AsteroidBeltEntity:updatePhysics(dt)
    self:updatePosition()

    self.angle = self.angle + self.angularVelocity * dt
end

function AsteroidBeltEntity:updatePosition()
    if self.parentEntity then
        local x, y = unpack(self.parentEntity.position)
        self.position = {x, y}
    end
end

function AsteroidBeltEntity:draw()
    local x, y = unpack(self.position)
    local scale = self.majorRadius + 2 * self.minorRadius

    love.graphics.setColor(127, 127, 127, 255)
    love.graphics.setShader(self.game.shaders.asteroidBelt)
    self.game.shaders.asteroidBelt:send("scale", scale)
    self.game.shaders.asteroidBelt:send("innerRadius", self.majorRadius - self.minorRadius)
    self.game.shaders.asteroidBelt:send("outerRadius", self.majorRadius + self.minorRadius)
    self.game.shaders.asteroidBelt:send("innerStepRadius", self.stepRadius)
    self.game.shaders.asteroidBelt:send("outerStepRadius", self.stepRadius)
    love.graphics.draw(self.mesh, x, y, self.angle, scale)
    love.graphics.setShader()
end

function AsteroidBeltEntity:debugDraw()
    if config.debugDraw and config.debugDraw.asteroidBelt then
        local x, y = unpack(self.position)
        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.circle("line", x, y, self.majorRadius - self.minorRadius, config.circleSegmentCount)
        love.graphics.circle("line", x, y, self.majorRadius + self.minorRadius, config.circleSegmentCount)
    end
end

function AsteroidBeltEntity:getDirection()
    return math.cos(self.angle), math.sin(self.angle)
end

function AsteroidBeltEntity:getLocalPoint(x, y)
    local x0, y0 = unpack(self.position)
    return utils.rotate(x - x0, y - y0, -self.angle)
end

function AsteroidBeltEntity:getLocalNoise(x, y)
    local innerRadius = self.majorRadius - self.minorRadius
    local outerRadius = self.majorRadius + self.minorRadius
    local innerStepRadius = self.stepRadius
    local outerStepRadius = self.stepRadius
    local noiseScale = 0.005

    local centerDistance = utils.getLength(x, y)

    local torusDensity = utils.smoothstep(innerRadius - innerStepRadius, innerRadius + innerStepRadius, centerDistance) -
        utils.smoothstep(outerRadius - outerStepRadius, outerRadius + outerStepRadius, centerDistance);

    local tunnelDensity = 2 * math.abs(noise2D.snoise(noiseScale * x, noiseScale * y));

    return torusDensity * tunnelDensity;
end

return AsteroidBeltEntity
