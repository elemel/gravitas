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
    entity.seed = args.seed or 1000 * love.math.random()
    entity.color = args.color or {255, 255, 255, 255}

    entity.parentEntity = args.parentEntity
    entity.orbitalRadius = args.orbitalRadius or 1
    entity.orbitalVelocity = args.orbitalVelocity or 0
    entity.orbitalAngle = args.orbitalAngle or 0

    entity.connectable = args.connectable or false
    entity.connected = args.connected
    entity.connectionTime = 0
    entity.disconnectionTime = 0
    entity.connectedColor = entity.color
    entity.disconnectedColor = {127, 127, 127, 255}

    return entity
end

function PlanetEntity:getType()
    return "planet"
end

function PlanetEntity:create()
    self.mesh = love.graphics.newMesh({
        {-1, -1, 0, 0},
        {1, -1, 1, 0},
        {1, 1, 1, 1},
        {-1, 1, 0, 1},
    })

    self:updatePosition()
    self:updateConnectable()

    if self.parentEntity then
        self.parentEntity:updateConnectable()
    end
end

function PlanetEntity:update(dt)
    self:updatePhysics(dt)
    self:updateColor(dt)
end

function PlanetEntity:updatePhysics(dt)
    if self.parentEntity then
        self.orbitalAngle = self.orbitalAngle + self.orbitalVelocity / self.orbitalRadius * dt
    end

    self:updatePosition()

    self.angle = self.angle + self.angularVelocity * dt
end

function PlanetEntity:updatePosition()
    if self.parentEntity then
        local x0, y0 = unpack(self.parentEntity.position)
        local x, y = unpack(self.position)
        x = x0 + math.cos(self.orbitalAngle) * self.orbitalRadius
        y = y0 + math.sin(self.orbitalAngle) * self.orbitalRadius
        self.position = {x, y}
    end
end

function PlanetEntity:updateConnectable()
    self.connectable = true

    for entity, _ in pairs(self.game.entities) do
        if entity:getType() == "planet" and not entity.connected and entity.parentEntity == self then
            self.connectable = false
            break
        end
    end
end

function PlanetEntity:getVelocity()
    if not self.parentEntity then
        return 0, 0
    end

    local directionX, directionY = math.cos(self.orbitalAngle), math.sin(self.orbitalAngle)
    return self.orbitalVelocity * -directionY, self.orbitalVelocity * directionX
end

function PlanetEntity:updateColor(dt)
    if self.connected then
        if self.connectionTime + 2 < love.timer.getTime() then
            self.color = self.connectedColor
        else
            local t = utils.smoothstep(0, 2, love.timer.getTime() - self.connectionTime)
            self.color = self:mixColors(self.disconnectedColor, self.connectedColor, t)
        end
    else
        if self.disconnectionTime + 2 < love.timer.getTime() then
            self.color = self.disconnectedColor
        else
            local t = utils.smoothstep(0, 2, love.timer.getTime() - self.disconnectionTime)
            self.color = self:mixColors(self.connectedColor, self.disconnectedColor, t)
        end
    end
end

function PlanetEntity:mixColors(color1, color2, t)
    local red1, green1, blue1, alpha1 = unpack(color1)
    local red2, green2, blue2, alpha2 = unpack(color2)

    local red = utils.round(utils.mix(red1, red2, t))
    local green = utils.round(utils.mix(green1, green2, t))
    local blue = utils.round(utils.mix(blue1, blue2, t))
    local alpha = utils.round(utils.mix(alpha1, alpha2, t))

    return {red, green, blue, alpha}
end

function PlanetEntity:draw()
    local x, y = unpack(self.position)
    local directionX, directionY = self:getDirection()

    if self.parentEntity then
        local x0, y0 = unpack(self.parentEntity.position)
        love.graphics.setColor(127, 127, 127, 127)
        love.graphics.circle("line", x0, y0, self.orbitalRadius, config.circleSegmentCount)
        love.graphics.line(x, y, x0, y0)
    end

    if self.planetType == "planet" and not self.connected and self.connectable then
        local red, green, blue, alpha = unpack(self.connectedColor)
        love.graphics.setColor(red, green, blue, 255)
        love.graphics.circle("line", x, y, 0.5 * self.radius, config.circleSegmentCount)
    end

    if self.planetType == "star" then
        love.graphics.setColor(unpack(self.color))
        love.graphics.circle("fill", x, y, self.radius, config.circleSegmentCount)
    elseif self.planetType == "planet" then
        love.graphics.setColor(unpack(self.color))
        love.graphics.setShader(self.game.planetShader)
        self.game.planetShader:send("seed", self.seed)
        self.game.planetShader:send("radius", self.radius)
        love.graphics.draw(self.mesh, x, y, self.angle, self.radius)
        love.graphics.setShader(nil)
    end
end

function PlanetEntity:getCollisionData()
    if not self.collisionData and self.planetType == "planet" then
        self:updateCollisionData()
    end
    return self.collisionData
end

function PlanetEntity:updateCollisionData()
    local size = utils.clamp(utils.round(0.2 * self.radius), 16, 256)
    self.collisionCanvas = love.graphics.newCanvas(size, size)
    self.collisionCanvas:setFilter("nearest")
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.setCanvas(self.collisionCanvas)
    love.graphics.setShader(self.game.planetShader)
    self.game.planetShader:send("seed", self.seed)
    self.game.planetShader:send("radius", self.radius)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.draw(self.mesh, 0.5 * size, 0.5 * size, 0, 0.5 * size, 0.5 * size)
    love.graphics.pop()
    love.graphics.setShader(nil)
    love.graphics.setCanvas(nil)

    self.collisionData = self.collisionCanvas:getImageData()
end

function PlanetEntity:debugDraw()
    if self.planetType == "planet" and config.debugDraw and config.debugDraw.planet then
        if not self.collisionCanvas then
            self:updateCollisionData()
        end

        self.mesh:setImage(self.collisionCanvas)
        love.graphics.setColor(0, 255, 0, 255)
        local x, y = unpack(self.position)
        love.graphics.draw(self.mesh, x, y, self.angle, self.radius)
        self.mesh:setImage(nil)
    end
end

function PlanetEntity:getMass()
    return utils.getSphereMass(self.radius, self.density)
end

function PlanetEntity:getDirection()
    return math.cos(self.angle), math.sin(self.angle)
end

function PlanetEntity:getLocalPoint(x, y)
    local x0, y0 = unpack(self.position)
    return utils.rotate(x - x0, y - y0, -self.angle)
end

function PlanetEntity:getCollisionPoint(x, y)
    local localX, localY = self:getLocalPoint(x, y)
    return 0.5 * localX / self.radius + 0.5, 0.5 * localY / self.radius + 0.5
end

function PlanetEntity:connect()
    if not self.connected and self.connectable then
        self.connected = true
        self.connectionTime = love.timer.getTime()

        if self.parentEntity then
            self.parentEntity:updateConnectable()
        end
    end
end

function PlanetEntity:disconnect()
    if self.connected then
        self.connected = false
        self.disconnectionTime = love.timer.getTime()

        if self.parentEntity then
            self.parentEntity:updateConnectable()
        end
    end
end

return PlanetEntity
