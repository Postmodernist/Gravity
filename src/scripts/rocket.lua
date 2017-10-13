local body = require("scripts/body")
local timer = require("scripts/timer")
local cameraShake = require("scripts/cameraShake")

local M = {}
M.__index = M
setmetatable(M, body)

function M:init()
	self.miningBeam = nil
	self.isMiningBeamOn = false
	self.beamRadius = 10
	self.beamRadDelta = 100
	self.isEngineOn = false
	if self.trailsData then
		self.trails = self:makeTrails()
		for i = 1,#self.trails do
			self.trails[i]:deactivate()
		end
	end
	sndEngineLoop:setVolume(0)
	sndBeamLoop:setVolume(0)
	-- engine activation delay timer
	timekeeper.addTimer(
		timer.new({
			name = "engineDelayTimer",
			callbackModule = self,
			basePeriod = 0.5,
			randomness = 0,
			isRepeating = false,
		})
	)
	-- report to other modules
	cameraShake.onRocketSpawn()
	cam.onRocketSpawn()
end

function M:kill(effect)
	if sndEngineLoop:isPlaying() then sndEngineLoop:stop() end
	if sndBeamLoop:isPlaying() then sndBeamLoop:stop() end
	if sndRocketDeath:isPlaying() then sndRocketDeath:stop() end
	sndRocketDeath:play()
	-- report to other modules
	galaxy.onBodyDestroyed({ entity = self, effect = effect, soundType = "rocket" })
	gameState.onRocketDestroyed()
	cameraShake.onRocketDestroyed()
	cam.onRocketDestroyed()
end

-- ================================
-- Love Callbacks
-- ================================

function M:draw()
	-- draw trails
	if self.trails then
		if #self.trails > 0 then
			for i = 1,#self.trails do
				self.trails[i]:draw()
			end
		end
	end
	-- draw mining beam
	if self.miningBeam then self:drawMiningBeam() end
	-- draw rocket
	local rocketHalf = self.texture:getWidth() / 2
	local x, y, r, isOffscr = cam.getScreenCoords({
		x = self.x,
		y = self.y,
		scale = self.textureScale,
		radius = rocketHalf * self.textureScale,
	})
	if not isOffscr then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(self.texture, x, y, self.angle + math.pi/2, r, r, rocketHalf, rocketHalf)
	end
	-- draw arrow if rocket is offscreen
	self:drawArrow()
end

function M:mousepressed(x, y, button, istouch)
end

function M:mousereleased(x, y, button, istouch)
	-- turn engine off
	if button == 1 then
		self:engineOff() 
		self:miningBeamOff() 
	end
end

-- ================================
-- Events
-- ================================

function M.onTimerFinish(event)
	if galaxy.theRocket then
		if (event.timer.name == "engineDelayTimer") and (not galaxy.theRocket.isEngineReady) then
			galaxy.theRocket.isEngineReady = true
			sndEngineLoop:setVolume(1)
			if galaxy.theRocket.trails then
				for i = 1,#galaxy.theRocket.trails do
					galaxy.theRocket.trails[i]:activate()
				end
			end
		elseif (event.timer.name == "sndEngineFadeInTimer") then
			event.timer.callbackModule.sndEngineFadeInTimer = nil
			sndEngineLoop:setVolume(1)
			sndEngineLoop:play()
		elseif (event.timer.name == "sndEngineFadeOutTimer") then
			event.timer.callbackModule.sndEngineFadeOutTimer = nil
			sndEngineLoop:setVolume(0)
			sndEngineLoop:stop()
		elseif (event.timer.name == "sndBeamFadeInTimer") then
			event.timer.callbackModule.sndBeamFadeInTimer = nil
			sndBeamLoop:setVolume(1)
			sndBeamLoop:play()
		elseif (event.timer.name == "sndBeamFadeOutTimer") then
			event.timer.callbackModule.sndBeamFadeOutTimer = nil
			sndBeamLoop:setVolume(0)
			sndBeamLoop:stop()
		end
	end
end

-- ================================
-- Methods
-- ================================

function M:doUpdate(dt)
	self.isUpdating = true
	-- get acceleration from the black hole
	local accelX, accelY = utils.getAccelXY({ self.x, self.y }, { 0, 0 }, config.BLACK_HOLE_MASS)
	-- get engine acceleration
	local engineAccelX, engineAccelY = 0, 0
	if love.mouse.isDown(1) and self.isEngineReady then
		local targetX, targetY = cam.getMouseXY(love.mouse.getPosition())
		local dx, dy = targetX - self.x, targetY - self.y 
		self.angle = math.atan2(dy, dx)
		-- turn engine on if enough fuel and not mining
		if (self.fuel > 0) and (not self.miningBeam) then
			if not self.isEngineOn then self:engineOn() end
			-- burn fuel
			self.fuel = self.fuel - config.ROCKET_FUEL_BURN_RATE * dt
			-- get engine thrust
			engineAccelX = self.enginePower * math.cos(self.angle)
			engineAccelY = self.enginePower * math.sin(self.angle)
		end
		-- turn engine off if no fuel
		if self.fuel < 0 then
			self.fuel = 0
			if isEngineOn then self:engineOff() end
		end
		-- mining
		if self.miningBeam then
			if self.isEngineOn then self:engineOff() end
			if not self.isMiningBeamOn then self:miningBeamOn() end
			-- do damage
			self.miningBeam.object.health = self.miningBeam.object.health - dt * config.ROCKET_BEAM_DPS
			if self.miningBeam.object.health <= 0 then
				if self.miningBeam.object.planet then
					galaxy.spawnTanks(self.miningBeam.object)
				end
				self.miningBeam.object:kill("explode")
			end
		else
			if self.isMiningBeamOn then self:miningBeamOff() end
		end
	end
	-- get rocket speed
	self.speedX = self.speedX + (accelX + engineAccelX) * dt
	self.speedY = self.speedY + (accelY + engineAccelY) * dt
	-- get rocket coords
	self.x = self.x + self.speedX * dt
	self.y = self.y + self.speedY * dt
	-- update trails
	if self.trails then
		for i = 1,#self.trails do
			self.trails[i]:update(dt)
		end
	end
	-- update engine sound
	sndEngineLoop:setPosition(self.x - cam.x, self.y - cam.y, 0)
	if self.sndEngineFadeInTimer then
		sndEngineLoop:setVolume(sndEngineLoop:getVolume() + dt / config.ROCKET_SNDENG_FADE_TIME)
	end
	if self.sndEngineFadeOutTimer then
		sndEngineLoop:setVolume(sndEngineLoop:getVolume() - dt / config.ROCKET_SNDENG_FADE_TIME)
	end
	-- update beam sound
	sndBeamLoop:setPosition(self.x - cam.x, self.y - cam.y, 0)
	if self.sndBeamFadeInTimer then
		sndBeamLoop:setVolume(sndBeamLoop:getVolume() + dt / config.ROCKET_SNDBEAM_FADE_TIME)
	end
	if self.sndBeamFadeOutTimer then
		sndBeamLoop:setVolume(sndBeamLoop:getVolume() - dt / config.ROCKET_SNDBEAM_FADE_TIME)
	end
	-- update beam radius
	self.beamRadius = self.beamRadius + self.beamRadDelta * dt
	if (self.beamRadius < 10) then
		self.beamRadius = 10
		self.beamRadDelta = 100 * (1 + 0.3 * (math.random() * 2 - 1))
	elseif (self.beamRadius > 25) then
		self.beamRadius = 25
		self.beamRadDelta = - 100 * (1 + 0.3 * (math.random() * 2 - 1))
	end
	self.isUpdating = false
end

function M:engineOn()
	self.isEngineOn = true
	if self.sndEngineFadeOutTimer then timekeeper.removeTimer(self.sndEngineFadeOutTimer) end
	self.sndEngineFadeOutTimer = nil
	sndEngineLoop:play()
	self.sndEngineFadeInTimer = timer.new({
		name = "sndEngineFadeInTimer",
		callbackModule = self,
		basePeriod = config.ROCKET_SNDENG_FADE_TIME,
		randomness = 0,
		isRepeating = false,
	})
	timekeeper.addTimer(self.sndEngineFadeInTimer)
	if self.trails then
		for i = 1,#self.trails do
			self.trails[i]:activate()
		end
	end
end

function M:engineOff()
	self.isEngineOn = false
	self.isEngineReady = true
	if self.sndEngineFadeInTimer then timekeeper.removeTimer(self.sndEngineFadeInTimer) end
	self.sndEngineFadeInTimer = nil
	self.sndEngineFadeOutTimer = timer.new({
		name = "sndEngineFadeOutTimer",
		callbackModule = self,
		basePeriod = config.ROCKET_SNDENG_FADE_TIME,
		randomness = 0,
		isRepeating = false,
	})
	timekeeper.addTimer(self.sndEngineFadeOutTimer)
	if self.trails then
		for i = 1,#self.trails do
			self.trails[i]:deactivate()
		end
	end
end

function M:miningBeamOn()
	self.isMiningBeamOn = true
	if self.sndBeamFadeOutTimer then timekeeper.removeTimer(self.sndBeamFadeOutTimer) end
	self.sndBeamFadeOutTimer = nil
	sndBeamLoop:play()
	self.sndBeamFadeInTimer = timer.new({
		name = "sndBeamFadeInTimer",
		callbackModule = self,
		basePeriod = config.ROCKET_SNDBEAM_FADE_TIME,
		randomness = 0,
		isRepeating = false,
	})
	timekeeper.addTimer(self.sndBeamFadeInTimer)
end

function M:miningBeamOff()
	self.isMiningBeamOn = false
	if self.sndBeamFadeInTimer then timekeeper.removeTimer(self.sndBeamFadeInTimer) end
	self.sndBeamFadeInTimer = nil
	self.sndBeamFadeOutTimer = timer.new({
		name = "sndBeamFadeOutTimer",
		callbackModule = self,
		basePeriod = config.ROCKET_SNDBEAM_FADE_TIME,
		randomness = 0,
		isRepeating = false,
	})
	timekeeper.addTimer(self.sndBeamFadeOutTimer)
end

function M:addFuel(value)
	if self.fuel + value > config.ROCKET_FUEL_MAX then
		self.fuel = config.ROCKET_FUEL_MAX
	else
		self.fuel = self.fuel + value
	end
end

function M:drawMiningBeam()
	local x, y, s = cam.getScreenCoords({
		x = self.miningBeam.point.x,
		y = self.miningBeam.point.y,
		scale = 1,
	})
	local rx, ry = cam.getScreenCoords({
		x = self.x,
		y = self.y,
		scale = 1,
	})
	love.graphics.setColor(255, 120, 133)
	love.graphics.circle("fill", x, y, self.beamRadius * s, 16)
	love.graphics.setLineWidth(self.beamRadius * s / 2)
	love.graphics.line(rx, ry, x, y)
	love.graphics.setColor(255, 244, 54)
	love.graphics.circle("fill", x, y, self.beamRadius * s / 2, 16)
	love.graphics.setLineWidth(self.beamRadius * s / 8)
	love.graphics.line(rx, ry, x, y)
end

function M:drawArrow()
	local arrowHalf = imgArrow:getWidth() * cam.scale / 2
	local x, y, r, isOffscr = cam.getScreenCoords({
		x = self.x,
		y = self.y,
		scale = self.textureScale,
		radius = self.texture:getWidth() * self.textureScale / 2,
	})
	local rocketHalf = r * self.texture:getWidth() / 2
	local coords = nil
	-- calculate arrow coords
	if x < -rocketHalf then
		if y < -rocketHalf then
			-- upper left corner
			if x < y then	coords = { arrowHalf, arrowHalf, -90 }
			else coords = { arrowHalf, arrowHalf, 0 } end
		elseif y > cam.height+rocketHalf then
			-- bottom left corner
			if x < cam.height-y then coords = { arrowHalf, cam.height-arrowHalf, -90 }
			else coords = { arrowHalf, cam.height-arrowHalf, 180 } end
		else
			-- left edge
			coords = { arrowHalf, math.max(math.min(y, cam.height-arrowHalf), arrowHalf), -90 }
		end
	elseif x > cam.width+rocketHalf then
		if y < -rocketHalf then
			-- upper right corner
			if cam.width-x < y then	coords = { cam.width-arrowHalf, arrowHalf, 90 }
			else coords = { cam.width-arrowHalf, arrowHalf, 0 } end
		elseif y > cam.height+rocketHalf then
			-- bottom right corner
			if x > y then	coords = { cam.width-arrowHalf, cam.height-arrowHalf, 90 }
			else coords = { cam.width-arrowHalf, cam.height-arrowHalf, 180 } end
		else
			-- right edge
			coords = { cam.width-arrowHalf, math.max(math.min(y, cam.height-arrowHalf), arrowHalf), 90 }
		end
	else
		-- upper edge
		if y < -rocketHalf then
			coords = { math.max(math.min(x, cam.width-arrowHalf), arrowHalf), arrowHalf, 0 }
		-- bottom edge
		elseif y > cam.height+rocketHalf then
			coords = { math.max(math.min(x, cam.width-arrowHalf), arrowHalf), cam.height-arrowHalf, 180 }
		end
	end
	if coords then
		-- draw arrow
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(
			imgArrow,
			coords[1], coords[2],
			math.rad(coords[3]),
			cam.scale, cam.scale,
			imgArrow:getWidth() / 2, imgArrow:getWidth() / 2
		)
		-- draw distance
		local d = math.floor(math.sqrt((coords[1] - x)^2 + (coords[2] - y)^2) - rocketHalf - arrowHalf + 0.5)
		local textWidth = fontMain:getWidth(tostring(d))
		local textHeight = fontMain:getHeight()
		local offset = 5 * cam.scale
		love.graphics.setFont(fontMain)
		if coords[3] == 0 then
			love.graphics.print(
				d, 
				coords[1] - textWidth / 2,
				coords[2] + offset
			)
		elseif coords[3] == 180 then
			love.graphics.print(
				d, 
				coords[1] - textWidth / 2,
				coords[2] - (textHeight + offset)
			)
		elseif coords[3] == 90 then
			love.graphics.print(
				d, 
				coords[1] - (textWidth + arrowHalf + offset),
				coords[2] - textHeight / 2
			)
		elseif coords[3] == -90 then
			love.graphics.print(
				d, 
				coords[1] + arrowHalf + offset,
				coords[2] - textHeight / 2
			)
		end
	end
end

return M