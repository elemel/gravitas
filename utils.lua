local config = require "config"

local utils = {}

function utils.round(x)
    return math.floor(x + 0.5)
end

function utils.sign(x)
    return x < 0 and -1 or 1
end

function utils.clamp(x, x1, x2)
    return math.min(math.max(x, x1), x2)
end

function utils.getDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
end

function utils.getSquaredDistance(x1, y1, x2, y2)
    return (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)
end

function utils.getLength(x, y)
    return math.sqrt(x * x + y * y)
end

function utils.getSquaredLength(x, y)
    return x * x + y * y
end

function utils.getRandomSign()
    return utils.sign(love.math.random() - 0.5)
end

function utils.normalize(x, y)
    local invLength = 1 / utils.getLength(x, y)
    return x * invLength, y * invLength
end

function utils.getSphereVolume(radius)
    return (4 / 3) * math.pi * radius * radius * radius
end

function utils.getSphereMass(radius, density)
    return utils.getSphereVolume(radius) * density
end

function utils.getOrbitalVelocity(mass, radius)
    return math.sqrt(config.gravitationalConstant * mass / radius)
end

return utils
