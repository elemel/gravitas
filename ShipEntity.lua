local config = require "config"
local utils = require "utils"

local ShipEntity = {}
ShipEntity.__index = ShipEntity

function ShipEntity.new(args)
    local entity = {}
    setmetatable(entity, ShipEntity)

    args = args or {}

    entity.radius = args.radius or 2
    entity.position = args.position or {0, 0}
    entity.angle = args.angle or 0
    entity.velocity = args.velocity or {0, 0}
    entity.color = args.color or {255, 255, 255, 255}
    entity.density = args.density or 1000

    entity.thrustInput = false
    entity.leftInput = false
    entity.rightInput = false

    entity.gravity = {0, 0}

    local angle = 2 * math.pi / 3
    entity.polygon = {
        entity.radius, 0,
        entity.radius * math.cos(angle), entity.radius * math.sin(angle),
        entity.radius * math.cos(-angle), entity.radius * math.sin(-angle),
    }

    return entity
end

function ShipEntity:getType()
    return "ship"
end

function ShipEntity:create()
    self:spawn()
end

function ShipEntity:update(dt)
    self:updateGravity(dt)
    self:updatePhysics(dt)
    self:updateCollision(dt)
    self:updateCamera(dt)
end

function ShipEntity:updateGravity(dt)
    self.gravity = {self:getGravity()}
end

function ShipEntity:updatePhysics(dt)
    self.thrustInput = love.keyboard.isDown("up")
    self.leftInput = love.keyboard.isDown("left")
    self.rightInput = love.keyboard.isDown("right")

    local x, y = unpack(self.position)
    local dx, dy = unpack(self.velocity)

    local turn = (self.leftInput and 1 or 0) - (self.rightInput and 1 or 0)
    local thrust = (self.thrustInput and 1 or 0) / self.game.camera.scale * 0.5

    self.angle = self.angle + turn * config.ship.turnVelocity * 2 * math.pi * dt

    local directionX, directionY = self:getDirection()
    dx = dx + thrust * directionX * dt
    dy = dy + thrust * directionY * dt

    local gravityX, gravityY = unpack(self.gravity)
    dx = dx + gravityX * dt
    dy = dy + gravityY * dt

    x = x + dx * dt
    y = y + dy * dt

    self.position = {x, y}
    self.velocity = {dx, dy}
end

function ShipEntity:updateCollision(dt)
    local dead = false

    for entity, _ in pairs(self.game.entities) do
        if entity:getType() == "planet" then
            local x1, y1 = unpack(self.position)
            local x2, y2 = unpack(entity.position)
            local squaredDistance = utils.getSquaredDistance(x1, y1, x2, y2)
            if squaredDistance < entity.radius * entity.radius then
                local data = entity:getCollisionData()
                local u, v = entity:getCollisionPoint(x1, y1) 
                local density = utils.sampleTextureAlpha(data, u, v)
                dead = dead or (density > 0.5)
            end

            if not dead and squaredDistance < 0.5 * 0.5 * entity.radius * entity.radius then
                entity:connect()
            end
        end
    end

    if dead then
        self:spawn()
    end
end

function ShipEntity:spawn()
    local entity = self:disconnectRandomPlanet() or self:getRandomPlanet()

    self.angle = 2 * math.pi * love.math.random()

    local orbitalAngle = 2 * math.pi * love.math.random()
    local directionX, directionY = math.cos(orbitalAngle), math.sin(orbitalAngle)
    local x0, y0 = unpack(entity.position)
    local distance = 1.5 * entity.radius
    local x, y = x0 + distance * directionX, y0 + distance * directionY
    self.position = {x, y}

    local mass = entity:getMass()
    local orbitalVelocity = utils.getOrbitalVelocity(mass, distance)
    local orbitalSign = utils.getRandomSign()
    local dx0, dy0 = entity:getVelocity()
    self.velocity = {dx0 + orbitalSign * -directionY, dy0 + orbitalSign * directionX}
end

function ShipEntity:getRandomPlanet()
    local entities = {}
    for entity, _ in pairs(self.game.entities) do
        if entity:getType() == "planet" and entity.planetType == "planet" and
            entity.connectable then

            table.insert(entities, entity)
        end
    end
    return utils.getRandomValue(entities)
end

function ShipEntity:disconnectRandomPlanet()
    local entities = {}
    for entity, _ in pairs(self.game.entities) do
        if entity:getType() == "planet" and entity.planetType == "planet" and
            entity.connected then

            table.insert(entities, entity)
        end
    end
    local entity = utils.getRandomValue(entities)
    if entity then
        entity:disconnect()
    end
    return entity
end

function ShipEntity:updateCamera(dt)
    self.game.camera.position = self.position

    -- self.game.camera.angle = -0.5 * math.pi + self.angle

    local gravityX, gravityY = unpack(self.gravity)
    self.game.camera.angle = 0.5 * math.pi + math.atan2(gravityY, gravityX)

    local distanceCameraScale = self:getDistanceCameraScale()
    local radiusCameraScale = 0.02 / self.radius
    self.game.camera.scale = math.min(distanceCameraScale, radiusCameraScale)
end

function ShipEntity:getDistanceCameraScale()
    local totalInvSquaredDistance = 0
    for entity, _ in pairs(self.game.entities) do
        if entity:getType() == "planet" then
            local x1, y1 = unpack(self.position)
            local x2, y2 = unpack(entity.position)
            local distance = math.max(0, utils.getDistance(x1, y1, x2, y2) - entity.radius - self.radius)
            totalInvSquaredDistance = totalInvSquaredDistance + 1 / (distance * distance)
        end
    end
    return 0.2 * math.sqrt(totalInvSquaredDistance)
end

function ShipEntity:getDirection()
    local gravityX, gravityY = unpack(self.gravity)
    local gravityAngle = math.atan2(gravityY, gravityX)
    return math.cos(gravityAngle + self.angle), math.sin(gravityAngle + self.angle)
end

function ShipEntity:draw(dt)
    local directionX, directionY = self:getDirection()

    love.graphics.push()
    love.graphics.setColor(self.color)
    love.graphics.translate(unpack(self.position))
    love.graphics.rotate(math.atan2(directionY, directionX))
    love.graphics.polygon("fill", self.polygon)
    love.graphics.pop()

    local x, y = unpack(self.position)
    love.graphics.setColor(127, 127, 127, 63)
    love.graphics.line(x, y, x + directionX * 1e9, y + directionY * 1e9)
end

function ShipEntity:getMass()
    return utils.getSphereMass(self.radius, self.density)
end

function ShipEntity:getGravity()
    local forceX, forceY = self:getGravityForce()
    local invMass = 1 / self:getMass()
    return forceX * invMass, forceY * invMass
end

function ShipEntity:getGravityForce()
    local totalForceX, totalForceY = 0, 0
    for entity, _ in pairs(self.game.entities) do
        if entity:getType() == "planet" then
            local x1, y1 = unpack(self.position)
            local x2, y2 = unpack(entity.position)
            local squaredDistance = utils.getSquaredDistance(x1, y1, x2, y2)

            local planetMass
            if squaredDistance > entity.radius * entity.radius then
                planetMass = entity:getMass()
            else
                -- For gravity inside planet.
                planetMass = utils.getSphereMass(math.sqrt(squaredDistance), entity.density)
            end

            local force = config.gravitationalConstant * self:getMass() * planetMass / squaredDistance
            local directionX, directionY = utils.normalize(x2 - x1, y2 - y1)
            totalForceX = totalForceX + force * directionX
            totalForceY = totalForceY + force * directionY
        end
    end
    return totalForceX, totalForceY
end

return ShipEntity
