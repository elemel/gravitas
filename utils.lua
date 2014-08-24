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

function utils.mix(x1, x2, t)
    return x1 + (x2 - x1) * t
end

function utils.smoothstep(x1, x2, x)
    x = utils.clamp((x - x1) / (x2 - x1), 0.0, 1.0)
    return 3 * x * x - 2 * x * x * x
end

function utils.rotate(x, y, angle)
    local sinAngle = math.sin(angle)
    local cosAngle = math.cos(angle)
    return cosAngle * x - sinAngle * y, sinAngle * x + cosAngle * y
end

function utils.count(t)
    local n = 0
    for key, value in pairs(t) do
        n = n + 1
    end
    return n
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

function utils.getRandomFloat(x1, x2)
    return utils.mix(x1, x2, love.math.random())
end

function utils.getRandomValue(t, default)
    local n = utils.count(t)
    if n == 0 then
        return default
    end
    local i = love.math.random(1, n)

    local j = 0
    for key, value in pairs(t) do
        j = j + 1
        if j == i then
            return value
        end
    end
    return default
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

function utils.sampleTextureAlpha(texture, u, v)
    local width, height = texture:getDimensions()
    local x, y = u * width - 0.5, v * height - 0.5

    local x1, y1 = math.floor(x), math.floor(y)
    local x2, y2 = x1 + 1, y1 + 1

    local weight11 = (x2 - x) * (y2 - y)
    local weight12 = (x2 - x) * (y - y1)
    local weight21 = (x - x1) * (y2 - y)
    local weight22 = (x - x1) * (y - y1)

    local alpha11 = utils.getPixelAlpha(texture, x1, y1)
    local alpha12 = utils.getPixelAlpha(texture, x1, y2)
    local alpha21 = utils.getPixelAlpha(texture, x2, y1)
    local alpha22 = utils.getPixelAlpha(texture, x2, y2)

    return weight11 * alpha11 + weight12 * alpha12 +
        weight21 * alpha21 + weight22 * alpha22
end

function utils.getPixelAlpha(texture, x, y)
    local width, height = texture:getDimensions()
    local clampedX = utils.clamp(x, 0, width - 1)
    local clampedY = utils.clamp(y, 0, height - 1)
    local red, green, blue, alpha = texture:getPixel(clampedX, clampedY)
    return alpha / 255
end

function utils.toByteFromFloat(...)
    local t = {}
    for i = 1, select("#", ...) do
        local f = select(i, ...)
        local b = utils.clamp(math.floor(f * 256), 0, 255)
        table.insert(t, b)
    end
    return unpack(t)
end

-- Adapted from Taehl: http://love2d.org/wiki/HSL_color
function utils.toRgbFromHsl(h, s, l)
    if s <= 0 then
        return l, l, l
    end

    h = h * 6
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = (1 - math.abs(h % 2 - 1)) * c
    local m, r, g, b = (l - 0.5 * c), 0, 0, 0

    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    return r + m, g + m, b + m
end

return utils
