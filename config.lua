local config = {}

config.window = {
	size = {512, 512},

	fsaa = 4,
	fullscreen = false,
	fullscreentype = "desktop",
	highdpi = true,
	resizable = true,
}

config.gravitationalConstant = 0.00001

config.minStarRadius = 1000
config.maxStarRadius = 2000

config.minPlanetCount = 5
config.maxPlanetCount = 10
config.minPlanetRadius = 100
config.maxPlanetRadius = 500
config.minPlanetOrbitVelocity = 100
config.maxPlanetOrbitVelocity = 200

config.circleSegmentCount = 256

config.ship = {
	turnVelocity = 0.5,
}

return config
