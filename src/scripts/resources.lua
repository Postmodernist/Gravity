local M = {}

function M.load()
	-- fonts
	fontConsole = love.graphics.newFont(12)
	fontMain = love.graphics.newFont("fonts/neuropolitical.ttf", 35 * cam.scale);
	fontTitle = love.graphics.newFont("fonts/neuropolitical.ttf", 70 * cam.scale);
	fontTitle2 = love.graphics.newFont("fonts/neuropolitical.ttf", 140 * cam.scale);
	
	-- textures
	imgAstronaut = love.image.newImageData("textures/astronaut3.tga")
	imgTank = love.image.newImageData("textures/tank01.tga")
	imgTankIcon = love.image.newImageData("textures/tank02.tga")
	imgBlackHole = love.image.newImageData("textures/black_hole02.tga")
	imgRocket = {
		["default"] = love.image.newImageData("textures/rocket2.tga"),
		["halloween"] = love.image.newImageData("textures/rocket_halloween.tga"),
	}
	imgArrow = love.graphics.newImage("textures/arrow.png", config.IMG_MODE)
	imgPlanets = {
		["default"] = {
			love.image.newImageData("textures/planet01.tga"),
			love.image.newImageData("textures/planet02.tga"),
			love.image.newImageData("textures/planet03.tga"),
			love.image.newImageData("textures/planet04.tga"),
			love.image.newImageData("textures/planet05.tga"),
		},
		["halloween"] = {
			love.image.newImageData("textures/planet01_hel.tga"),
			love.image.newImageData("textures/planet02_hel.tga"),
			love.image.newImageData("textures/planet03_hel.tga"),
			love.image.newImageData("textures/planet04_hel.tga"),
			love.image.newImageData("textures/planet05_hel.tga"),
		},
	}
	imgFeedback01 = love.image.newImageData("textures/feedback01.tga")
	imgFeedback02 = love.image.newImageData("textures/feedback02.tga")
	imgAvatar = love.image.newImageData("textures/gagarin.tga")

	-- sounds
	sndTitleMusic = love.audio.newSource("sounds/lost_astronaut.ogg")
	sndTitleMusic:setLooping(true)
	sndAmbient = love.audio.newSource("sounds/space_ambient.ogg")
	sndAmbient:setLooping(true)
	sndBlackHole = love.audio.newSource("sounds/black_hole_rumble.ogg", "static")
	sndBlackHole:setLooping(true)
	sndScores = love.audio.newSource("sounds/solemn.ogg")
	sndScores:setLooping(true)
	sndRocketBeep = love.audio.newSource("sounds/rocket_beep.ogg", "static")
	sndEngineLoop = love.audio.newSource("sounds/engine_loop.ogg", "static")
	sndEngineLoop:setLooping(true)
	sndEngineLoop:setRelative(true)
	sndEngineLoop:setAttenuationDistances(cam.diag / cam.scale * 0.3, cam.sndAttenMax)
	sndBeamLoop = love.audio.newSource("sounds/beam01.ogg", "static")
	sndBeamLoop:setLooping(true)
	sndBeamLoop:setRelative(true)
	sndBeamLoop:setAttenuationDistances(cam.diag / cam.scale, cam.sndAttenMax)
	sndSos = love.audio.newSource("sounds/sos.ogg")
	sndSos:setRelative(true)
	sndSos:setAttenuationDistances(cam.diag, config.GALAXY_RADIUS * 1.5)
	sndRocketDeath = love.audio.newSource("sounds/rocket_death.ogg", "static")
	sndDataExplosion = {
		["default"] = love.sound.newSoundData("sounds/gas_explosion.ogg"),
		["rocket"] = love.sound.newSoundData("sounds/rocket_explode.ogg"),
		["planet"] = {
			love.sound.newSoundData("sounds/planet_explode01.ogg"),
			love.sound.newSoundData("sounds/planet_explode02.ogg"),
		},
		["comet"] = {
			love.sound.newSoundData("sounds/comet_explode01.ogg"),
			love.sound.newSoundData("sounds/comet_explode02.ogg"),
		},
		["astronaut"] = {
			love.sound.newSoundData("sounds/astronaut_die01.ogg"),
			love.sound.newSoundData("sounds/astronaut_die02.ogg"),
		},
		["tank"] = love.sound.newSoundData("sounds/gas_explosion.ogg"),
	}
	sndData = {
		cometFly = love.sound.newSoundData("sounds/comet_fly.ogg"),
		bounce = love.sound.newSoundData("sounds/bounce.ogg"),
		feedback = love.sound.newSoundData("sounds/feedback.ogg"),
		implode = love.sound.newSoundData("sounds/implode.wav"),
		pickupAstr = love.sound.newSoundData("sounds/pickup4.ogg"),
		pickupTank = love.sound.newSoundData("sounds/pickup.ogg"),
	}
end

return M