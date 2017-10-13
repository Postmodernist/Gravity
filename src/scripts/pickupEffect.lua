local M = {}

function M.new(params)
	local o = {}
	-- parameters
	o.x = params.x
	o.y = params.y
	o.radius = params.radius
	-- variables
	o.alpha = 180
	o.duration = config.PICKUP_EFFECT_DURATION
	o.scale = o.radius / 32
	o.time = 0
	o.isInProcess = false
	setmetatable(o, {__index = M})
	return o
end

function M:init()
	-- define circles
	self.circles = {
		{
			startTime = 	0.0 * self.duration,
			endTime = 		0.7 * self.duration,
			startRadius = 	1.0 * self.radius,
			endRadius = 	1.0 * self.radius,
			color = 		{ r = 255, g = 255, b = 255 },
			width = 10 * self.scale,
			radius = -1,
			alpha = self.alpha,
		},
		{
			startTime = 	0.0 * self.duration,
			endTime = 		1.0 * self.duration,
			startRadius = 	0.8 * self.radius,
			endRadius = 	5.0 * self.radius,
			color = 		{ r = 255, g = 255, b = 255 },
			width = 10 * self.scale,
			radius = -1,
			alpha = self.alpha,
		},
		{
			startTime = 	0.3 * self.duration,
			endTime = 		1.0 * self.duration,
			startRadius = 	0.8 * self.radius,
			endRadius = 	5.0 * self.radius,
			color = 		{ r = 255, g = 255, b = 255 },
			width = 10 * self.scale,
			radius = -1,
			alpha = self.alpha,
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
				scale = self.scale,
				radius = c.radius,
			})
			if not isOffscr then
				love.graphics.setColor(c.color.r, c.color.g, c.color.b, c.alpha)
				love.graphics.setLineWidth(c.width * r)
				love.graphics.circle("line", x, y, c.radius * r, 64)
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
			local da = self.alpha / (c.endTime - c.startTime)
			c.alpha = c.alpha - da * dt
		end
	end
end

return M