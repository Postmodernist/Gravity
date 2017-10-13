local M = {}

function M.new(params)
	o = {}
	o.size = params.size * cam.scale
	o.distance = params.distance
	o.radius = params.radius * math.tan(math.rad(config.OBSERVER_FOV / 2)) * cam.diag * 2
	o.angle = params.angle
	o.starfield = params.starfield
	setmetatable(o, {__index = M})
	return o
end

function M:update(dt)
	self.distance = self.distance - config.OBSERVER_SPEED * dt
	self.angle = self.angle + math.rad(config.OBSERVER_SPIN_SPEED) * dt
	if config.OBSERVER_SPEED >= 0 and self.distance < 1 then
		self.starfield.onStarClipped({ star = self })
	elseif config.OBSERVER_SPEED < 0 and self.distance > config.FAR_CLIP then
		self.starfield.onStarClipped({ star = self })
	end
end

function M:draw()
	if self.distance > 1 and self.distance < config.FAR_CLIP then 
	    local r = self.radius / self.distance
		local x, y =
			math.cos(self.angle) * r + cam.pivotX - cam.x / self.distance,
			math.sin(self.angle) * r + cam.pivotY - cam.y / self.distance
		local s = self.size / self.distance
		local c = {
			math.max(59, 255 - (self.distance * 0.94)^2),
			math.max(50, 255 - (self.distance * 0.94)^2),
			math.max(81, 255 - (self.distance * 0.94)^2),
		}
		-- check if star is off screen
		local isOffscreen = false
		if (x + s < 0) or (x - s > cam.width) then isOffscreen = true end
		if (y + s < 0) or (y - s > cam.height) then isOffscreen = true end		
		if not isOffscreen then
			love.graphics.setColor(c[1], c[2], c[3])
			love.graphics.circle("fill", x, y, s, 12)
		end
	end
end

return M