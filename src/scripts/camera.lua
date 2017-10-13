local timer = require("scripts/timer")
local windowWidth = love.graphics.getWidth()
local windowHeight = love.graphics.getHeight()
local windowDiag = math.sqrt(windowWidth^2 + windowHeight^2) / 2
local windowScale = windowDiag / config.VISIBILITY_RADIUS

local M = {
	x = 0,
	y = 0,
	zoom = 1,
	-- zoom = math.min(1, windowScale),
	pivotX = windowWidth / 2,
	pivotY = windowHeight / 2,
	width = windowWidth,
	height = windowHeight,
	diag = windowDiag,  -- half of window diagonal
	scale = windowScale,
	-- sound attenuation
	sndAttenMin = windowDiag / windowScale * 0.8,
	sndAttenMax = windowDiag / windowScale * 1.2,
	cometSndAttenMin = 0,
	cometSndAttenMax = windowDiag / windowScale * 0.7,
}

-- subscribe to engine callbacks
addCallbackForward(M, { "update", "wheelmoved", "keypressed" })

local pos = {
	ax = 0, ay = 0,
	vx = 0, vy = 0,
	x = 0, y = 0,
	offsetX = 0, offsetY = 0,
	phase = 1,
	time = 0,
	isFocusing = false,
	isReseting = false,
}

local phases = {}
-- camera focus on rocket after rocket spawn
phases.focus = {
	function(dt, ang, offs)
		pos.x = M.x
		pos.y = M.y
		pos.phase = 2
	end,
	function(dt, ang, offs)
		if pos.time <= config.FOCUS_TIME then
			pos.offsetX = (offs * math.cos(ang) - pos.x) * pos.time / config.FOCUS_TIME
			pos.offsetY = (offs * math.sin(ang) - pos.y) * pos.time / config.FOCUS_TIME
			M.x = pos.x + pos.offsetX
			M.y = pos.y + pos.offsetY
			pos.time = pos.time + dt
		else
			M.x = offs * math.cos(ang)
			M.y = offs * math.sin(ang)
			pos.time = 0
			pos.phase = 1
			pos.isFocusing = false
		end
	end,
}

-- camera reset position after rocket death
phases.reset = {
	function(dt)
		pos.ax = 8 * M.x / (3 * config.SLIDE_BACK_TIME^2)
		pos.ay = 8 * M.y / (3 * config.SLIDE_BACK_TIME^2)
		pos.vx = 4 * M.x / (3 * config.SLIDE_BACK_TIME)
		pos.vy = 4 * M.y / (3 * config.SLIDE_BACK_TIME)
		pos.x = M.x
		pos.y = M.y
		pos.phase = 2
	end,
	function(dt)
		if pos.time <= (config.SLIDE_BACK_TIME * 0.5) then
			M.x = pos.x - pos.vx * pos.time
			M.y = pos.y - pos.vy * pos.time
			pos.time = pos.time + dt
		else
			pos.time = 0
			pos.x = pos.x / 3
			pos.y = pos.y / 3
			pos.phase = 3
		end
	end,
	function(dt)
		if pos.time <= (config.SLIDE_BACK_TIME * 0.5) then
			M.x = pos.x - pos.vx * pos.time + pos.ax * pos.time^2 / 2
			M.y = pos.y - pos.vy * pos.time + pos.ay * pos.time^2 / 2
			pos.time = pos.time + dt
		else
			M.x, M.y = 0, 0
			pos.time = nil
			pos.phase = 1
			pos.isReseting = false
		end
	end,
}

-- ================================
-- Love Callbacks
-- ================================

function M.update(dt)
	-- camera follow
	if galaxy.theRocket then
		local rx, ry = galaxy.theRocket.x, galaxy.theRocket.y
		rd = utils.getDistance({0, 0}, {rx, ry})
		local ang = math.atan2(ry, rx)
		local offsMax = math.max(0, config.VISIBILITY_RADIUS * M.zoom - M.diag)
		local offsFac = math.min(1, rd / config.VISIBILITY_RADIUS)
		local offs = offsMax * offsFac
		-- focus camera on rocket
		if pos.isFocusing then
			phases.focus[pos.phase](dt, ang, offs)
		else
			M.x = offs * math.cos(ang)
			M.y = offs * math.sin(ang)
		end
	else
		-- reset camera position
		if pos.isReseting then
			phases.reset[pos.phase](dt)
		end
	end
end

function M.wheelmoved(x, y)
	local zoomMin = config.ZOOM_MIN * M.scale
	M.zoom = math.max(zoomMin, math.min(config.ZOOM_MAX, M.zoom + y * config.ZOOM_SPEED / 100))
end

function M.keypressed(key, scancode, isrepeat)
	if key == "c" then M.zoom = 1 end
	if key == "v" then M.zoom = windowScale end
	if key == "x" then M.x, M.y = 0, 0 end
end

-- ================================
-- Events
-- ================================

function M.onRocketSpawn()
	pos.time = 0
	pos.phase = 1
	pos.isReseting = false
	pos.isFocusing = true
end

function M.onRocketDestroyed()
	pos.time = 0
	pos.phase = 1
	pos.isFocusing = false
	pos.isReseting = true
end

function M.onTimerFinish(event)
end

-- ================================
-- Methods
-- ================================

function M.getScreenCoords(par)
	local o = par
	local x = (o.x - M.x) * M.zoom + M.pivotX
	local y = (o.y - M.y) * M.zoom + M.pivotY
	local scale = o.scale * M.zoom
	if o.radius then
		o.radius = o.radius * M.zoom
	else
		o.radius = scale
	end
	-- check if entity is off screen
	local isOffscreen = false
	if (x + o.radius < 0) or (x - o.radius > M.width) then isOffscreen = true end
	if (y + o.radius < 0) or (y - o.radius > M.height) then isOffscreen = true end
	return x, y, scale, isOffscreen
end

function M.getMouseXY(x, y)
	local x_ = (x - cam.pivotX) / M.zoom + cam.x
	local y_ = (y - cam.pivotY) / M.zoom + cam.y
	return x_, y_
end

return M