local timer = require("scripts/timer")

local M = {}
local isActive = false
local fadeOutTimer = nil
local fadeOutDuration = 1
local screenAlpha = 255

function M.update(dt)
	if fadeOutTimer then
		screenAlpha = screenAlpha - dt*255/fadeOutDuration
	end
end

function M.draw()
	if isActive then
	    love.graphics.setColor(255, 255, 255, screenAlpha)
	    love.graphics.rectangle("fill", 0, 0, cam.width, cam.height)
	end
end

function M.onTimerFinish(event)
	if event.timer == fadeOutTimer then
		fadeOutTimer = nil
		isActive = false
		removeCallbackForward(M, { "update", "draw" })
	end
end

function M.activate()
	addCallbackForward(M, { "update", "draw" })
	screenAlpha = 255
	isActive = true
end

function M.deactivate()
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
end

return M