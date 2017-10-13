local M = {}

function M.new(params)
	local o = {}
	-- parameters
	o.x = params.x
	o.y = params.y
	o.radius = params.radius
	o.soundType = params.soundType
	-- variables
	o.duration = config.EXPLOSION_DURATION
	o.time = 0
	o.isInProcess = false
	setmetatable(o, {__index = M})
	-- place and play sound effect
	local sound = nil
	if type(sndDataExplosion[o.soundType]) == "table" then
		sound = love.audio.newSource(sndDataExplosion[o.soundType][math.random(2)])
	else
		sound = love.audio.newSource(sndDataExplosion[o.soundType])
	end
	sound:setRelative(true)
	sound:setAttenuationDistances(cam.sndAttenMin, cam.sndAttenMax)
	sound:setPosition(o.x - cam.x, o.y - cam.y, 0)
	sound:play()
	return o
end

function M:init()
	local colors = {
		{ r = 252, g = 213, b = 80 },
		{ r = 255, g = 255, b = 255 },
		{ r = 59, g = 50, b = 81 },
	}
	self.circles = {}
	for i = 1,5 do
		local startTime = 	self.duration*math.random()*i*0.1
		local endTime = 	self.duration*(0.5+math.random()*i*0.1)
		local endRadius = 	self.radius*(1.5+math.random()*i*0.1)
		local x =			self.radius*(1+0.5*(math.random()*2-1))
		local y =			self.radius*(1+0.5*(math.random()*2-1))
		local c1 = {
			startTime = 	startTime,
			endTime = 		endTime,
			startRadius = 	self.radius,
			endRadius = 	endRadius,
			x =				x,
			y =				y,
			color = 		colors[1],
			radius = -1
		}
		local c2 = {
			startTime = 	math.min(startTime+0.1, self.duration*0.9),
			endTime = 		endTime,
			startRadius = 	0,
			endRadius = 	endRadius-10,
			x =				x,
			y =				y,
			color = 		colors[2],
			radius = -1
		}
		local c3 = {
			startTime = 	math.min(startTime+0.3, self.duration*0.9),
			endTime = 		endTime,
			startRadius = 	0,
			endRadius = 	endRadius,
			x =				x,
			y =				y,
			color = 		colors[3],
			radius = -1
		}
		table.insert(self.circles, c1)
		table.insert(self.circles, c2)
		table.insert(self.circles, c3)
	end
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
				x = self.x + c.x,
				y = self.y + c.y,
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