local timer = require("scripts/timer")

local M = {}
local fadeOutTimer = nil
local fadeOutDuration = 0.3
local screenAlpha0 = 60
local screenAlpha = nil
local color = { r = 255, g = 255, b = 255 }

function M.init(entity)
	if fadeOutTimer then
		timekeeper.removeTimer(fadeOutTimer)
	else
		addCallbackForward(M, { "update", "draw" })
	end
	fadeOutTimer = timer.new(
		{
			name = "fadeOutTimer",
			callbackModule = M,
			basePeriod = fadeOutDuration,
			randomness = 0,
			isRepeating = false,
		}
	)
	timekeeper.addTimer(fadeOutTimer)
	local sound = nil
	if entity.astronaut then
		sound = love.audio.newSource(sndData.pickupAstr)
	elseif entity.tank then
		sound = love.audio.newSource(sndData.pickupTank)
	end
	if sound then sound:play() end
	screenAlpha = screenAlpha0
end

function M.update(dt)
	if fadeOutTimer then
		screenAlpha = screenAlpha - dt*screenAlpha0/fadeOutDuration
	end
end

function M.draw()
	love.graphics.setColor(color.r, color.g, color.b, screenAlpha)
	love.graphics.rectangle("fill", 0, 0, cam.width, cam.height)
end

function M.onTimerFinish(event)
	fadeOutTimer = nil
	removeCallbackForward(M, { "update", "draw" })
end

return M