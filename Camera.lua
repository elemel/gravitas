local utils = require "utils"

local Camera = {}
Camera.__index = Camera

function Camera.new(args)
    local camera = {}
    setmetatable(camera, Camera)

    args = args or {}
    camera.viewport = args.viewport or {-1, -1, 1, 1}
    camera.position = args.position or {0, 0}
    camera.scale = args.scale or 1
    camera.angle = args.angle or 0

    return camera
end

function Camera:draw()
    local viewportX, viewportY = self:getViewportCenter()
    local viewportScaleX, viewportScaleY = self:getViewportScale()
    love.graphics.translate(viewportX, viewportY)
    love.graphics.scale(viewportScaleX, viewportScaleY)

    local x, y = unpack(self.position)
    love.graphics.scale(self.scale)
    love.graphics.rotate(-self.angle)
    love.graphics.translate(-x, -y)
end

function Camera:getViewportCenter()
    local viewportX1, viewportY1, viewportX2, viewportY2 = unpack(self.viewport)
    return 0.5 * (viewportX1 + viewportX2), 0.5 * (viewportY1 + viewportY2)
end

function Camera:getViewportScale()
    local x1, y1, x2, y2 = unpack(self.viewport)
    local width, height = math.abs(x2 - x1), math.abs(y2 - y1)
    local minSize = math.min(width, height)
    local signX, signY = utils.sign(x2 - x1), utils.sign(y2 - y1)
    return 0.5 * signX * minSize, 0.5 * signY * minSize
end

return Camera
