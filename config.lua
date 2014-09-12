local config = {}

config.window = {
	size = {1024, 512},

	fullscreen = true,
	fullscreentype = "desktop",
	resizable = true,
}

config.gravitationalConstant = 0.00001

config.minStarRadius = 5000
config.maxStarRadius = 10000

config.minPlanetRadius = 1000
config.maxPlanetRadius = 2000

config.minMoonRadius = 200
config.maxMoonRadius = 500

config.circleSegmentCount = 256

config.ship = {
	turnVelocity = 0.5,
}

config.debugDraw = {
    planet = false,
    -- asteroidBelt = true,
}

return config
