local Camera = require "Camera"

local Game = {}
Game.__index = Game

function Game.new()
    local game = {}
    setmetatable(game, Game)

    game.camera = Camera.new({scale = 0.0002})

    game.entities = {}

    return game
end

function Game:update(dt)
    for entity, _ in pairs(self.entities) do
        if entity.update then
            entity:update(dt)
        end
    end
end

function Game:draw()
    love.graphics.origin()

    local width, height = love.graphics.getDimensions()
    self.camera.viewport = {0, height, width, 0}
    self.camera:draw()

    love.graphics.setLineWidth(1e-9)

    for entity, _ in pairs(self.entities) do
        if entity.draw then
            entity:draw()
        end
    end
end

function Game:addEntity(entity)
    self.entities[entity] = true
    entity.game = self
    if entity.create then
        entity:create()
    end
end

function Game:removeEntity(entity)
    if entity.destroy then
        entity:destroy()
    end
    entity.game = nil
    self.entities[entity] = nil
end

return Game
