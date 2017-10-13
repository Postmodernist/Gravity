local M = {
	states = {
		["title"] = require("scripts/gameStates/title"),
		["play"] = require("scripts/gameStates/play"),
		["scores"] = require("scripts/gameStates/scores"),
	},
}
-- subscribe to engine callbacks
addCallbackForward(M, { "update", "draw", "mousepressed", "mousereleased", "keypressed" })

local currentState = nil
local stateTail = nil  -- { script = <script>, timer = <timer> }

function M.init()
	M.setState("title")
end

-- ================================
-- Love Callbacks
-- ================================

function M.update(dt)
	currentState.update(dt)
	if stateTail then
		stateTail.script.update(dt)
	end
end

function M.draw()
	currentState.draw()
end

function M.mousepressed(x, y, button, istouch)
	if currentState.mousepressed then
		currentState.mousepressed(x, y, button, istouch)
	end
end

function M.mousereleased(x, y, button, istouch)
	if currentState.mousereleased then
		currentState.mousereleased(x, y, button, istouch)
	end
end

function M.keypressed(key, scancode, isrepeat)
	if currentState.keypressed then
		currentState.keypressed(key, scancode, isrepeat)
	end
end

-- ================================
-- Events
-- ================================

function M.onRocketDestroyed()
	if currentState.onRocketDestroyed then
		currentState.onRocketDestroyed()
	end
end

function M.onAstronautPickup()
	if currentState.onAstronautPickup then
		currentState.onAstronautPickup()
	end
end

function M.onTankPickup(tank)
	if currentState.onTankPickup then
		currentState.onTankPickup(tank)
	end
end

function M.onTimerFinish(event)
	if event.timer.name == "stateTailFinish" then
		stateTail.script.finish()
		stateTail = nil
	end
end

-- ================================
-- Methods
-- ================================

function M.setState(stateId)
	if currentState then
		currentState.finish()
	end
	currentState = M.states[stateId]
	currentState.start()
end

function M.setStateTail(tail)
	if stateTail then
		timekeeper.removeTimer(stateTail.timer)
		stateTail.script.finish()
	end
	stateTail = tail
end

return M
