local defaultRes = { x = 2560, y = 1440 }
local visRad = math.sqrt(defaultRes.x^2 + defaultRes.y^2) / 2

local M = {
	IMG_MODE = { linear = true, mipmaps = true },
	-- camera
	ZOOM_MIN = 0.25,
	ZOOM_MAX = 1,
	ZOOM_SPEED = 5,
	FOCUS_TIME = 1,
	SLIDE_BACK_TIME = 2,
	-- galaxy
	VISIBILITY_RADIUS = visRad,
	GALAXY_RADIUS = 2500,
	ROCKET_ENGINE_POWER = 400,
	ROCKET_FUEL_MAX = 100,
	ROCKET_FUEL_BURN_RATE = 2,
	ROCKET_SNDENG_FADE_TIME = 0.5,
	ROCKET_SNDBEAM_FADE_TIME = 0.3,
	ROCKET_BEAM_DPS = 70,
	GRAVITY_DECAY_POWER = 1.8,
	BLACK_HOLE_RADIUS = 7,
	BLACK_HOLE_MASS = 7000000,
	PLANETS_SPAWN_PERIOD = 5,
	COMETS_SPAWN_PERIOD = 4,
	ASTRONAUTS_SPAWN_PERIOD = 3,
	SOS_SIGNAL_PERIOD = 3,
	THEME_HALLOWEEN_SCORE = 10,
	-- effects
	EXPLOSION_DURATION = 0.7,
	EXPLOSION_SCALE = 1,
	IMPLOSION_SCALE = 0.8,
	ROCKET_TRAIL_SPEED = -700,
	PICKUP_EFFECT_DURATION = 0.5,
	-- planetarium
	BODIES_SPAWN_RANGE_MIN = visRad + 100,
	BODIES_SPAWN_RANGE_MAX = visRad + 300,
	-- game states
	PROGRESS_COEF = 0.97,
	TITLE_DELAY_TIME = 1,
	TITLE_FADE_TIME = 3,
	AMBIENT_VOLUME = 0.3,
	AMBIENT_FADEIN_TIME = 2,
	AMBIENT_FADEOUT_TIME = 1,
	SCORES_DELAY_TIME = 0.5,
	SCORES_FADE_TIME = 3,
	-- feedbacks
	SPEED_RESCUE_SPEED = 600,
	SPEED_RESCUE_COOLDOWN = 2,
	COMBO_COOLDOWN = 3,
	EVENT_HORIZON_THRESHOLD = 12,
	EVENT_HORIZON_COOLDOWN = 0.5,
	EVENT_HORIZON_COOLDOWN2 = 5,
	-- starfield
	OBSERVER_SPEED = -0.5,
	OBSERVER_SPIN_SPEED = 5,
	OBSERVER_FOV = 60,
	FAR_CLIP = 15,
	CLUSTER_DEPTH = 100,
	STARS_NUMBER = 800,
	-- camera shake
	SHAKE_DISTANCE_MAX = visRad / 3,
	MAGNITUDE_MAX = 3,
	MAGNITUDE_RANDOMNESS = 0.2,
	ANGLE_SPREAD = math.pi/3,  -- PI is the max angle spread
	WAVE_DURATION_RANDOMNESS = 0.05,
	WAVE_DURATION = 0.04,
}

return M