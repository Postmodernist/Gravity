local M = {}

function M.new(params)
	o = {}
	-- parameters
	o.host = params.host
	o.radius = params.radius
	o.stepDelta = params.stepDelta
	o.lifetime = params.lifetime
	o.speed = params.speed or 0
	o.color = params.color
	if params.fading then o.fading = params.fading
	else o.fading = false end
	-- variables
	o.particles = {}
	o.isActive = false
	o.isUpdating = false
	setmetatable(o, { __index = M })
	return o
end

function M:init()
	self.isActive = true
end

-- ================================
-- Love Callbacks
-- ================================

function M:update(dt)
	if not self.isUpdating then
		self.isUpdating = true
		local p = self.particles
		if #p > 0 then
			for i = 1,#p do
				-- update age
				p[i].age = p[i].age + dt
				-- update position
				p[i].x = p[i].x + p[i].speedX * dt
				p[i].y = p[i].y + p[i].speedY * dt
				-- update radius
				if self.fading == true then
					p[i].radius = p[i].radius - (self.radius / self.lifetime) * dt
				end
			end
			-- insert new particle
			if self.isActive then
				local d = math.sqrt((self.host.x - p[#p].x)^2 + (self.host.y - p[#p].y)^2)
				if d >= self.stepDelta then
					local c = {
						x = self.host.x,
						y = self.host.y,
						speedX = math.cos(self.host.angle) * self.speed,
						speedY = math.sin(self.host.angle) * self.speed,
						radius = self.radius,
						age = 0,
					}
					table.insert(p, c)
				end
			end
			-- delete old particles
			local pNew = {}
			for i,v in pairs(p) do
				if v.age < self.lifetime then
					table.insert(pNew, v)
				end
			end
			p = pNew
		else
			if self.isActive then
				local c = {
					x = self.host.x,
					y = self.host.y,
					speedX = math.cos(self.host.angle) * self.speed,
					speedY = math.sin(self.host.angle) * self.speed,
					radius = self.radius,
					age = 0,
				}
				table.insert(p, c)
			end
		end
		self.particles = p
		self.isUpdating = false
	end
end

function M:draw()
	if self.isActive then
		local x, y, r, isOffscr = cam.getScreenCoords({
			x = self.host.x, 
			y = self.host.y,
			scale = self.radius,
		})
		if not isOffscr then
			love.graphics.setColor(self.color.r, self.color.g, self.color.b)
			love.graphics.circle("fill", x, y, r, 12)
		end
	end
	if #self.particles > 0 then
		love.graphics.setColor(self.color.r, self.color.g, self.color.b)
		local p = self.particles
		for i = 1,#p do
			local x, y, r, isOffscr = cam.getScreenCoords({
				x = p[i].x,
				y = p[i].y,
				scale = p[i].radius,
			})
			if i == 1 then
				if not isOffscr then love.graphics.circle("fill", x, y, r, 12) end
			else
				local x_, y_, r_, isOffscr_ = cam.getScreenCoords({
					x = p[i-1].x,
					y = p[i-1].y,
					scale = p[i-1].radius,
				})
				if (not isOffscr) or (not isOffscr_) then
					love.graphics.setLineWidth(r*2)
					love.graphics.line(x, y, x_, y_)
					if i == #p and not self.isActive then love.graphics.circle("fill", x, y, r, 12) end
				end
			end
		end
	end
end

-- ================================
-- Methods
-- ================================

function M:activate()
	self.isActive = true
end

function M:deactivate()
	self.isActive = false
end

return M