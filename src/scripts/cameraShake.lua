local timer = require("scripts/timer")

local M = {}
local wave = {
	magnitude = 0,
	angle = 0,
	duration = 0,
	offsetX = 0,
	offsetY = 0,
	stepX = 0,
	stepY = 0,
}	

function M.init()
	M.shakeTimer = timer.new{
		name = "shakeTimer",
		callbackModule = M,
		basePeriod = config.WAVE_DURATION,
		randomness = config.WAVE_DURATION_RANDOMNESS,
		isRepeating = true
	}
	timekeeper.addTimer(M.shakeTimer)
	sndBlackHole:setVolume(0)
	sndBlackHole:play()
end

local function getNewWave()
	-- get wave properties
	local dMin = galaxy.theRocket.radius + galaxy.theBlackHole.radius
	local dMax = config.SHAKE_DISTANCE_MAX
	local dRocket = math.min(dMax, galaxy.rocketDistanceToBH or dMax)
	local factor = (dMax - dRocket)^2 / (dMax - dMin)^2
	local mag = config.MAGNITUDE_MAX * factor
	sndBlackHole:setVolume(factor)
	wave.magnitude = math.floor(0.5 + mag *
		(1 + config.MAGNITUDE_RANDOMNESS * (math.random() * 2 - 1)))
	local a = math.random() * config.ANGLE_SPREAD +	(math.pi - config.ANGLE_SPREAD) / 2
	if wave.angle < math.pi / 2 then 
		wave.angle = a + math.pi / 2
	else
		wave.angle = a - math.pi / 2
	end
	wave.duration = config.WAVE_DURATION *
		(1 + config.WAVE_DURATION_RANDOMNESS * (math.random() * 2 - 1))
	-- get step size
	local targetOffsetX = math.cos(wave.angle) * wave.magnitude
	local targetOffsetY = math.sin(wave.angle) * wave.magnitude
	wave.stepX = (targetOffsetX - wave.offsetX) / wave.duration
	wave.stepY = (targetOffsetY - wave.offsetY) / wave.duration
end

-- ================================
-- Love Callbacks
-- ================================

function M.update(dt)
	-- update offsets
	if not M.isActive then return end
	wave.offsetX = wave.offsetX + wave.stepX * dt
	wave.offsetY = wave.offsetY + wave.stepY * dt
end

function M.draw()
	if not M.isActive then return end
   love.graphics.translate(wave.offsetX, wave.offsetY)
end

-- ================================
-- Events
-- ================================

function M.onTimerTick(event)
	if not M.isActive then return end
	getNewWave()
end

function M.onRocketSpawn()
	M.isActive = true
end

function M.onRocketDestroyed()
	M.isActive = nil
	sndBlackHole:setVolume(0)
end

return M