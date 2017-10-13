local M = {}

function M.new(params)
	local o = {}
	-- parameters
	o.x = params.x
	o.y = params.y
	o.radius = params.radius
	-- variables
	o.duration = 0.8
	o.time = 0
	o.isInProcess = false
	setmetatable(o, {__index = M})
	-- play sound effect
	local sound = love.audio.newSource(sndData.implode)
	sound:setRelative(true)
	sound:setAttenuationDistances(cam.sndAttenMin, cam.sndAttenMax)
	sound:setPosition(o.x - cam.x, o.y - cam.y, 0)
	sound:play()
	return o
end

function M:init()
	self.circles = {
		{
			startTime = 	0.5*self.duration,
			endTime = 		1.0*self.duration,
			startRadius = 	1.9*self.radius,
			endRadius = 	2.6*self.radius,
			color = 		{ r = 0, g = 0, b = 0 },
			radius = -1
		},
		{
			startTime = 	0.5*self.duration,
			endTime = 		1.0*self.duration,
			startRadius = 	1.9*self.radius,
			endRadius = 	1.7*self.radius,
			color = 		{ r = 59, g = 50, b = 81 },
			radius = -1
		},
		{
			startTime = 	0.4*self.duration,
			endTime = 		0.7*self.duration,
			startRadius = 	1.3*self.radius,
			endRadius = 	1.9*self.radius,
			color = 		{ r = 0, g = 0, b = 0 },
			radius = -1
		},
		{
			startTime = 	0.3*self.duration,
			endTime = 		0.7*self.duration,
			startRadius = 	1.3*self.radius,
			endRadius = 	1.0*self.radius,
			color = 		{ r = 59, g = 50, b = 81 },
			radius = -1
		},
		{
			startTime = 	0.0*self.duration,
			endTime = 		0.6*self.duration,
			startRadius = 	0.6*self.radius,
			endRadius = 	1.0*self.radius,
			color = 		{ r = 0, g = 0, b = 0 },
			radius = -1
		},
		{
			startTime = 	0.0*self.duration,
			endTime = 		0.6*self.duration,
			startRadius = 	0.6*self.radius,
			endRadius = 	0.0*self.radius,
			color = 		{ r = 59, g = 50, b = 81 },
			radius = -1
		},
		-- main eraser
		{
			startTime = 	0.1*self.duration,
			endTime = 		1.0*self.duration,
			startRadius = 	0.0*self.radius,
			endRadius = 	2.6*self.radius,
			color = 		{ r = 59, g = 50, b = 81 },
			radius = -1
		},
		-- inner rim
		{
			startTime = 	0.6*self.duration,
			endTime = 		0.9*self.duration,
			startRadius = 	1.3*self.radius,
			endRadius = 	1.5*self.radius,
			color = 		{ r = 0, g = 0, b = 0 },
			radius = -1
		},
		{
			startTime = 	0.6*self.duration,
			endTime = 		0.9*self.duration,
			startRadius = 	1.3*self.radius,
			endRadius = 	1.3*self.radius,
			color = 		{ r = 59, g = 50, b = 81 },
			radius = -1
		},
		{
			startTime = 	0.6*self.duration,
			endTime = 		0.9*self.duration,
			startRadius = 	1.1*self.radius,
			endRadius = 	1.5*self.radius,
			color = 		{ r = 59, g = 50, b = 81 },
			radius = -1
		},
		-- after core
		{
			startTime = 	0.8*self.duration,
			endTime = 		1.0*self.duration,
			startRadius = 	0.4*self.radius,
			endRadius = 	1.0*self.radius,
			color = 		{ r = 0, g = 0, b = 0 },
			radius = -1
		},
		{
			startTime = 	0.8*self.duration,
			endTime = 		1.0*self.duration,
			startRadius = 	0.1*self.radius,
			endRadius = 	1.0*self.radius,
			color = 		{ r = 59, g = 50, b = 81 },
			radius = -1
		},
		{
			startTime = 	0.0*self.duration,
			endTime = 		0.7*self.duration,
			startRadius = 	0.6*self.radius,
			endRadius = 	0.1*self.radius,
			color = 		{ r = 0, g = 0, b = 0 },
			radius = -1
		},
	}
	self.isInProcess = true
end

function M:update(dt)
	if self.isInProcess then
		if self.time <= self.duration then
			self.time = self.time + dt
			self:updateCircles(dt)
		else
			self.isInProcess = false
			galaxy.onEffectFinished({ entity = self })
		end
	end
end

function M:draw()
	for i = 1,#self.circles do
		if self.circles[i].radius > 0 then
			local c = self.circles[i]
			local x, y, r, isOffscr = cam.getScreenCoords({
				x = self.x,
				y = self.y,
				scale = c.radius,
			})
			if not isOffscr then
				love.graphics.setColor(c.color.r, c.color.g, c.color.b)
				love.graphics.circle("fill", x, y, r, 50)
			end
		end
	end
end

function M:updateCircles(dt)
	for i = 1,#self.circles do
		if self.time > self.circles[i].endTime then
			self.circles[i].radius = 0
		elseif self.time > self.circles[i].startTime then
			local c = self.circles[i]
			if c.radius < 0 then c.radius = c.startRadius end
			local dr = (c.endRadius - c.startRadius) / (c.endTime - c.startTime)
			c.radius = c.radius + dr * dt
		end
	end
end

return M