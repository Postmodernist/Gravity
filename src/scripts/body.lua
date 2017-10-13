local timer = require("scripts/timer")
local trail = require("scripts/trail")
local trailRake = require("scripts/trailRake")

local M = {}
M.__index = M

function M:new(params, extra)
	local o = extra or {}
	o.x = params.x
	o.y = params.y
	o.angle = params.angle
	o.radius = params.radius
	o.speedX = params.speedX
	o.speedY = params.speedY
	o.movable = params.movable
	o.collidable = params.collidable
	o.health = params.health
	if params.texture then
		o.texture = love.graphics.newImage(params.texture, config.IMG_MODE)
		o.textureScale = params.textureScale or 1
	end
	if params.trails then
		o.trailsData = params.trails
	end
	if extra.blinkPeriod then
		o.blinkTimer = nil
		o.alpha = 255
		o.blinkFadeSpeed = - 200 / extra.blinkPeriod
	end
	if extra.comet then
		o.sound = love.audio.newSource(sndData.cometFly)
		o.sound:setLooping(true)
		o.sound:setRelative(true)
		o.sound:setAttenuationDistances(cam.cometSndAttenMin, cam.cometSndAttenMax)
		o.sound:setPosition(o.x - cam.x, o.y - cam.y, 0)
		o.sound:play()
	elseif extra.astronaut or extra.tank then
		o.sound = love.audio.newSource(sndData.bounce)
		o.sound:setRelative(true)
	end
	setmetatable(o, self)
	return o
end

function M:init()
	if self.trailsData then
		self.trails = self:makeTrails()
	end
	if self.blinkPeriod then
		self.blinkTimer = timer.new(
				{
					name = "blinkTimer",
					callbackModule = self,
					basePeriod = self.blinkPeriod,
					randomness = 0,
					isRepeating = true,
				}
			)
		timekeeper.addTimer(self.blinkTimer)
	end
end

function M:kill(effect)
	if self.sound then
		self.sound:stop()
	end
	if self.blinkTimer then
		timekeeper.removeTimer(self.blinkTimer)
		self.blinkTimer = nil
	end
	if effect == "no reports" then return end
	-- report to galaxy
	local soundType = nil
	if self.rocket then soundType = "rocket"
	elseif self.astronaut then soundType = "astronaut"
	elseif self.tank then soundType = "tank"
	elseif self.comet then soundType = "comet"
	elseif self.planet then soundType = "planet"
	else soundType = "default" end
	galaxy.onBodyDestroyed({ entity = self, effect = effect, soundType = soundType })
end

-- ================================
-- Love Callbacks
-- ================================

function M:update(dt)
	if not self.isUpdating then
		self:doUpdate(dt)
	end
end

function M:draw()
	-- draw trails
	if self.trails then
		for i = 1,#self.trails do
			self.trails[i]:draw()
		end
	end
	-- draw body
	if self.texture then
		local x, y, r, isOffscr = cam.getScreenCoords({
			x = self.x,
			y = self.y,
			scale = self.textureScale,
			radius = self.texture:getWidth() * self.textureScale / 2,
		})
		if not isOffscr then
			love.graphics.setColor(255, 255, 255, self.alpha or 255)
			love.graphics.draw(self.texture, x, y, self.angle, r, r,
				self.texture:getWidth() / 2, self.texture:getWidth() / 2)
		end
	end
	-- draw text
	if self.text then
		love.graphics.setColor(
			self.textColor.r,
			self.textColor.g,
			self.textColor.b,
			self.alpha or 255
		)
		love.graphics.setFont(self.textFont)
		local textWidth = self.textFont:getWidth(self.text)
		local textHeight = self.textFont:getHeight()
		if not self.align then self.align = "center" end
		if self.align == "left" then
			love.graphics.printf(
				self.text,
				self.x,
				self.y - textHeight / 2,
				textWidth,
				"center"
			)
		elseif self.align == "right" then
			love.graphics.printf(
				self.text,
				self.x - textWidth,
				self.y - textHeight / 2,
				textWidth,
				"center"
			)
		else
			love.graphics.printf(
				self.text,
				self.x - textWidth / 2,
				self.y - textHeight / 2,
				textWidth,
				"center"
			)
		end
		-- DEBUG - check pivot
		-- love.graphics.setColor(0, 0, 0)
		-- love.graphics.circle("fill", self.x, self.y, 3, 12)
	end
end

-- ================================
-- Events
-- ================================

function M.onTimerTick(event)
	if event.timer.name == "blinkTimer" then
		event.timer.callbackModule.blinkFadeSpeed = - event.timer.callbackModule.blinkFadeSpeed
	end
end

function M.onTimerFinish(event)
	if event.timer.name == "bounceBroTimer" then
		event.timer.callbackModule.bounceBro = nil
	end
end

-- ================================
-- Methods
-- ================================

function M:doUpdate(dt)
	self.isUpdating = true
	if self.movable then
		-- get acceleration
		local accelX, accelY = utils.getAccelXY({ self.x, self.y }, { 0, 0 }, config.BLACK_HOLE_MASS)
		-- update speed
		self.speedX = self.speedX + accelX * dt
		self.speedY = self.speedY + accelY * dt
		-- update position
		self.x = self.x + self.speedX * dt
		self.y = self.y + self.speedY * dt
		if self.moveOrient then
			self.angle = math.atan2(self.speedY, self.speedX)
		end
		-- update trails
		if self.trails then
			for i = 1,#self.trails do
				self.trails[i]:update(dt)
			end
		end
	end
	-- update sound
	if self.comet then
		self.sound:setAttenuationDistances(cam.cometSndAttenMin, cam.cometSndAttenMax)
		self.sound:setPosition(self.x - cam.x, self.y - cam.y, 0)
	end
	-- update blinking
	if self.alpha then
		self.alpha = self.alpha + self.blinkFadeSpeed * dt
	end
	self.isUpdating = false
end

function M:makeTrails()
	local o = {}
	for i = 1,#self.trailsData do
		local t = nil
		self.trailsData[i].host = self
		if self.trailsData[i].rake then
			t = trailRake.new(self.trailsData[i])
		else
			t = trail.new(self.trailsData[i])
		end
		t:init()
		table.insert(o, t)
	end
	return o
end

function M:bounce(bro)
	self.bounceBro = bro
	-- create bounce bro timer
	timekeeper.addTimer(timer.new(
			{
				name = "bounceBroTimer",
				callbackModule = self,
				basePeriod = 2,
				randomness = 0,
				isRepeating = false,
			}
		)
	)
	-- play bounce sound
	self.sound:setAttenuationDistances(cam.sndAttenMin, cam.sndAttenMax)
	self.sound:setPosition(self.x - cam.x, self.y - cam.y, 0)
	if self.sound:isPlaying() then
		self.sound:rewind()
	else
		self.sound:play()
	end
end

return M
