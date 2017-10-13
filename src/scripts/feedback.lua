local M = {}

function M.new(params)
	local o = {}
	o.text = params.text
	o.font = params.font
	o.color = params.color
	if params.texture then
		o.texture = love.graphics.newImage(params.texture, config.IMG_MODE)
		o.textureScale = params.textureScale or 1
	end
	-- variables
	o.textWidth = o.font:getWidth(o.text)
	o.textHeight = o.font:getHeight()
	o.x = cam.width / 2
	o.y = o.textHeight * 3 / 4
	o.textOffset = { x = 0, y = 0 }
	o.duration = params.duration
	o.timer = 0
	o.anim = { timer = 0, phase = 1 }
	o.phases = {
		function(self)
			if self.anim.timer < 0.3 then
				local d = (self.x + self.textWidth / 2 + 100) / 0.3
				self.textOffset.x = self.x + self.textWidth / 2 - d * self.anim.timer
			else
				self.textOffset.x = -100
				self.anim.timer = 0
				self.anim.phase = 2
			end
		end,
		function(self)
			if self.anim.timer < 0.2 then
				local d = 100 / 0.2
				self.textOffset.x = -100 + d * self.anim.timer
			else
				self.textOffset.x = 0
				self.anim.timer = 0
				self.anim.phase = 3
			end
		end,
		function(self)
			if self.anim.timer >= self.duration - 1 then
				self.anim.timer = 0
				self.anim.phase = 4
			end
		end,
		function(self)
			if self.anim.timer < 0.2 then
				local d = 100 / 0.2
				self.textOffset.x = d * self.anim.timer
			else
				self.textOffset.x = 100
				self.anim.timer = 0
				self.anim.phase = 5
			end
		end,
		function(self)
			if self.anim.timer < 0.3 then
				local d = (self.x + self.textWidth / 2 + 100) / 0.3
				self.textOffset.x = 100 - d * self.anim.timer
			else
				self.textOffset.x = -(self.x + self.textWidth / 2)
				self.anim.timer = 0
				self.anim.phase = 6
			end
		end,
		function(self)
		end,
	}
	o.isActive = true
	local sound = love.audio.newSource(sndData.feedback)
	sound:play()
	setmetatable(o, { __index = M })
	return o
end

function M:update(dt)
	if self.isActive then
		if self.timer >= self.duration then
			self.isActive = false
			feedbackHub.onFeedbackFinished({ entity = self })
		end
		self.timer = self.timer+dt
		self.anim.timer = self.anim.timer+dt
	end
end

function M:draw(num)
	if self.isActive then	
		self.textOffset = { x = 0, y = self.textHeight * (num - 1) * 1.25 }
		-- animated appearance
		self.phases[self.anim.phase](self)
		-- draw texture
		if self.texture then
			love.graphics.setColor(255, 255, 255)
			love.graphics.draw(
				self.texture,
				self.x + self.textOffset.x - (20 * cam.scale + self.textWidth / 2),
				self.y + self.textOffset.y,
				0,
				self.textureScale * cam.scale,
				self.textureScale * cam.scale,
				self.texture:getWidth(),
				self.texture:getHeight() / 2
			)
		end
		love.graphics.setColor(self.color.r, self.color.g, self.color.b)
		love.graphics.setFont(self.font)
		love.graphics.printf(
			self.text,
			self.x - self.textWidth / 2 + self.textOffset.x,
			self.y + self.textOffset.y - self.textHeight / 2,
			self.textWidth,
			"center"
		)
		-- check pivot
		-- love.graphics.setColor(0, 0, 0)
		-- love.graphics.circle("fill", self.x, self.y+self.textOffset.y, 3, 12)
	end
end

return M