local timer = require("scripts/timer")
local planetarium = require("scripts/planetarium")
local body = require("scripts/body")

-- public variables
local M = {
	rocketSpawnPoint = { x = 200, y = 200 },
	stats = nil  -- gets value in start()
}
-- local variables
local soundTrack = sndAmbient
local ambientFadeInTimer = nil
local comboTimer = nil
local speedRescueTimer = nil
local eventHorizonTimer = nil
local eventHorizonTimer2 = nil
local hintBody = nil
local hintDelayTimer = nil
local isHintShown = false
local hint2Body = nil
local hint2StartTimer = nil
local hint2DurationTimer = nil
local isHint2Shown = false
local fuelBlink = true
local fuelBlinkTimer = nil
local popAstrTimer = nil
local popAstrScale = 1
local popTankTimer = nil
local popTankScale = 1
local lazyFuel = {
	timers = {},
	values = {},
}

function M.start()
	-- zeroing stats
	M.stats = {
		astronautsSaved = 0,
		comboNum = 0,
		speedRescueNum = 0,
		eventHorizonNum = 0,
	},
	-- start ambient sound
	soundTrack:setVolume(0)
	soundTrack:play()
	-- creating ambient fade in timer
	ambientFadeInTimer = timer.new(
		{
			name = "ambientFadeInTimer",
			callbackModule = M,
			basePeriod = config.AMBIENT_FADEIN_TIME,
			randomness = 0,
			isRepeating = false,
		}
	)
	timekeeper.addTimer(ambientFadeInTimer)
	-- creating the rocket
	if sndRocketBeep:isPlaying() then sndRocketBeep:stop() end
	sndRocketBeep:play()
	local x, y = cam.getMouseXY(M.rocketSpawnPoint.x, M.rocketSpawnPoint.y)
	local rocket = planetarium.rockets[galaxy.theme].new(x, y)
	galaxy.theRocket = galaxy.createBody(rocket.params, rocket.extra)
	-- unpause collectibles spawn timers
	galaxy.astronautSpawnTimer:unpause()
	-- hints
	if not isHintShown and saveData.tutorial == 1 then
		hintBody = body:new(
			{
				x = cam.width / 2,
				y = cam.height * 0.2,
				radius = 10,
				angle = math.rad(0),
				movable = false,
				collidable = false,
			},
			{
				text = "hold the left mouse button to thrust",
				textFont = fontMain,
				textColor = { r = 255, g = 255, b = 255 },
				blinkPeriod = 0.8,
			}
		)
		hintBody:init()
	end
	if not isHint2Shown and saveData.tutorial == 1 then
		hint2StartTimer = timer.new({
			name = "hint2StartTimer",
			callbackModule = M,
			basePeriod = 15,
			randomness = 0,
			isRepeating = false,
		})
		timekeeper.addTimer(hint2StartTimer)
	end
end

function M.finish()
	if ambientFadeInTimer then
		timekeeper.removeTimer(ambientFadeInTimer)
		ambientFadeInTimer = nil
	end
	if hintBody then
		hintBody:kill("no reports")
		hintBody = nil
	end
	if hint2Body then
		hint2Body:kill("no reports")
		hint2Body = nil
	end
	if #lazyFuel.timers > 0 then
		for i = 1, #lazyFuel.timers do
			timekeeper.removeTimer(lazyFuel.timers[i])
		end
		lazyFuel = {
			timers = {},
			values = {},
		}
	end
	-- reset spawn timers
	galaxy.cometSpawnTimer.basePeriod = config.COMETS_SPAWN_PERIOD
	galaxy.astronautSpawnTimer:pause()
	-- create state tail script
	local script = {
		update = function(dt)
			if config.AMBIENT_FADEOUT_TIME > 0 then
				soundTrack:setVolume(soundTrack:getVolume() -
					dt * config.AMBIENT_VOLUME / config.AMBIENT_FADEOUT_TIME)
			else
				soundTrack:setVolume(0)
			end 
		end,
		finish = function()
			soundTrack:stop()
		end,
	}
	-- create state tail timer
	local timerNew = timer.new(
		{
			name = "stateTailFinish",
			callbackModule = gameState,
			basePeriod = config.AMBIENT_FADEOUT_TIME,
			randomness = 0,
			isRepeating = false,
		}
	)
	timekeeper.addTimer(timerNew)
	-- set state tail
	gameState.setStateTail(
		{
			script = script,
			timer = timerNew,
		}
	)
end

-- ================================
-- Love Callbacks
-- ================================

function M.update(dt)
	-- check for "event horizon" feedback
	if not eventHorizonTimer and galaxy.theRocket then
		local a, b = galaxy.theRocket.radius, galaxy.theBlackHole.radius
		local d = utils.getDistance({0, 0}, {galaxy.theRocket.x, galaxy.theRocket.y})
		if d < config.EVENT_HORIZON_THRESHOLD + a + b then
			if not eventHorizonTimer2 then
				M.stats.eventHorizonNum = M.stats.eventHorizonNum + 1
				-- short timer to ensure that rocket survives
				eventHorizonTimer = timer.new(
					{
						name = "eventHorizonTimer",
						callbackModule = M,
						basePeriod = config.EVENT_HORIZON_COOLDOWN,
						randomness = 0,
						isRepeating = false,
					}
				)
				timekeeper.addTimer(eventHorizonTimer)
				-- long timer to prevent close orbit cyclic feedbacks
				eventHorizonTimer2 = timer.new(
					{
						name = "eventHorizonTimer2",
						callbackModule = M,
						basePeriod = config.EVENT_HORIZON_COOLDOWN2,
						randomness = 0,
						isRepeating = false,
					}
				)
				timekeeper.addTimer(eventHorizonTimer2)
			else
				eventHorizonTimer2:reset()
			end
		end
	end
	-- fade-in ambient
	if ambientFadeInTimer then
		if config.AMBIENT_FADEIN_TIME > 0 then
			soundTrack:setVolume(soundTrack:getVolume() +
				dt * config.AMBIENT_VOLUME / config.AMBIENT_FADEIN_TIME)
		else
			soundTrack:setVolume(config.AMBIENT_VOLUME)
		end
	end
	-- hints
	if hintBody then hintBody:update(dt) end
	if hint2Body then hint2Body:update(dt) end
	-- stats icons
	if popAstrTimer then popAstrScale = popAstrScale + dt * 1.5 end
	if popTankTimer then popTankScale = popTankScale + dt * 1.5 end
end

function M.draw()
	if galaxy.theRocket then M.drawOverlay() end
	if hintBody then hintBody:draw() end
	if hint2Body then hint2Body:draw() end
end

function M.mousepressed(x, y, button, istouch)
	if button == 1 then
		if hintBody then
			if hintDelayTimer then timekeeper.removeTimer(hintDelayTimer) end
			hintDelayTimer = timer.new({
				name = "hintDelayTimer",
				callbackModule = M,
				basePeriod = 1,
				randomness = 0,
				isRepeating = false,
			})
			timekeeper.addTimer(hintDelayTimer)
		end
	end
end

function M.mousereleased(x, y, button, istouch)
	if button == 1 then
		if hintDelayTimer then timekeeper.removeTimer(hintDelayTimer) end
	end
end

-- ================================
-- Events
-- ================================

function M.onRocketDestroyed()
	-- switch to next game state
	gameState.setState("scores")
end

function M.onAstronautPickup()
	M.stats.astronautsSaved = M.stats.astronautsSaved + 1
	-- speed up comets spawn timer
	galaxy.cometSpawnTimer.basePeriod = config.COMETS_SPAWN_PERIOD *
		config.PROGRESS_COEF^M.stats.astronautsSaved
	-- check for "speed rescue" feedback
	if not speedRescueTimer then
		if galaxy.rocketSpeed > config.SPEED_RESCUE_SPEED then
			M.stats.speedRescueNum = M.stats.speedRescueNum+1
			feedbackHub.show("speed rescue")
			speedRescueTimer = timer.new(
				{
					name = "speedRescueTimer",
					callbackModule = M,
					basePeriod = config.SPEED_RESCUE_COOLDOWN,
					randomness = 0,
					isRepeating = false,
				}
			)
			timekeeper.addTimer(speedRescueTimer)
		end
	end
	-- check for "combo" feedback
	M.stats.comboNum = M.stats.comboNum+1
	if M.stats.comboNum > 1 then
		feedbackHub.show("combo")
	end
	if comboTimer then timekeeper.removeTimer(comboTimer) end
	comboTimer = timer.new(
		{
			name = "comboTimer",
			callbackModule = M,
			basePeriod = config.COMBO_COOLDOWN,
			randomness = 0,
			isRepeating = false,
		}
	)
	timekeeper.addTimer(comboTimer)
	-- check for "halloween" feedback
	if M.stats.astronautsSaved == config.THEME_HALLOWEEN_SCORE and galaxy.themesUnlocked < 2 then
		galaxy.themesUnlocked = 2
		saveData.unlocks = galaxy.themesUnlocked
		feedbackHub.show("halloween")
	end
	-- animate astronaut overlay icon
	M.popAstronautIcon()
end

function M.onTankPickup(tank)
	local i = 1
	while lazyFuel.timers[i] do
		i = i + 1
	end
	lazyFuel.timers[i] = timer.new({
		name = "lazyFuelTimer",
		callbackModule = M,
		basePeriod = 1.5,
		randomness = 0,
		isRepeating = false,
	})
	timekeeper.addTimer(lazyFuel.timers[i])
	if galaxy.theRocket then
		local d = config.ROCKET_FUEL_MAX - galaxy.theRocket.fuel
		if d < tank.value then
			lazyFuel.values[i] = d
		else
			lazyFuel.values[i] = tank.value
		end
		galaxy.theRocket:addFuel(tank.value)
	end
	M.popTankIcon()
end

-- timer events

function M.onTimerTick(event)
	if event.timer == fuelBlinkTimer then
		if not galaxy.theRocket or galaxy.theRocket.fuel > 0 then
			timekeeper.removeTimer(fuelBlinkTimer)
			fuelBlinkTimer = nil
			fuelBlink = true
		else
			fuelBlink = not fuelBlink
		end
	end
end

function M.onTimerFinish(event)
	if event.timer == ambientFadeInTimer then
		ambientFadeInTimer = nil
		soundTrack:setVolume(config.AMBIENT_VOLUME)
	elseif event.timer == speedRescueTimer then
		speedRescueTimer = nil
	elseif event.timer == comboTimer then
		comboTimer = nil
		M.stats.comboNum = 0
	elseif event.timer == eventHorizonTimer then
		eventHorizonTimer = nil
		feedbackHub.show("event horizon")
	elseif event.timer == eventHorizonTimer2 then
		eventHorizonTimer2 = nil
	elseif event.timer == hintDelayTimer then
		hintDelayTimer = nil
		if hintBody then 
			hintBody:kill("no reports")
			hintBody = nil
		end
		isHintShown = true
	elseif event.timer == hint2StartTimer then
		hint2StartTimer = nil
		hint2Body = body:new(
			{
				x = cam.width / 2,
				y = cam.height * 0.3,
				radius = 10,
				angle = math.rad(0),
				movable = false,
				collidable = false,
			},
			{
				text = "target and destroy planets to get fuel",
				textFont = fontMain,
				textColor = { r = 255, g = 255, b = 255 },
				blinkPeriod = 0.8,
			}
		)
		hint2Body:init()
		hint2DurationTimer = timer.new({
			name = "hint2DurationTimer",
			callbackModule = M,
			basePeriod = 5,
			randomness = 0,
			isRepeating = false,
		})
		timekeeper.addTimer(hint2DurationTimer)
	elseif event.timer == hint2DurationTimer then
		hint2DurationTimer = nil
		if hint2Body then 
			hint2Body:kill("no reports")
			hint2Body = nil
			isHint2Shown = true
			saveData.tutorial = 0
		end
	elseif event.timer == popAstrTimer then
		popAstrTimer = nil
		popAstrScale = 1
	elseif event.timer == popTankTimer then
		popTankTimer = nil
		popTankScale = 1
	elseif event.timer.name == "lazyFuelTimer" then
		for i = 1, #lazyFuel.timers do
			if lazyFuel.timers[i] == event.timer then
				table.remove(lazyFuel.timers, i)
				table.remove(lazyFuel.values, i)
				break
			end
		end
	end
end

-- ================================
-- Methods
-- ================================

function M.drawOverlay()
	local lineHeight = 64 * cam.scale
	-- draw fuel
	local iconFuel = love.graphics.newImage(imgTankIcon, config.IMG_MODE)
	local iconFuelWidth = iconFuel:getWidth()
	local fuel = galaxy.theRocket.fuel
	local fuelLazy = 0
	for i = 1, #lazyFuel.values do
		fuelLazy = fuelLazy + lazyFuel.values[i]
	end
	local fuelIconOffsetX, fuelIconOffsetY = lineHeight / 4, lineHeight / 4
	local barWidth, barHeight = lineHeight * 5, lineHeight / 2
	local fuelBarWidth = barWidth * fuel / config.ROCKET_FUEL_MAX
	local fuelLazyBarWidth = barWidth * (fuel - fuelLazy) / config.ROCKET_FUEL_MAX
	local barOffsetX = fuelIconOffsetX + lineHeight * 1.3
	local barOffsetY = fuelIconOffsetY + lineHeight * 0.3
	love.graphics.setLineWidth(2)
	if fuel > 0 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.rectangle("fill", barOffsetX, barOffsetY, fuelBarWidth, barHeight, 5, 5, 10)
	end
	if fuel > config.ROCKET_FUEL_MAX * 0.6 then
		love.graphics.setColor(255, 255, 255)
			love.graphics.draw(
				iconFuel,
				fuelIconOffsetX + iconFuelWidth * cam.scale / 2, fuelIconOffsetY + iconFuelWidth * cam.scale / 2, 0,
				cam.scale * popTankScale, cam.scale * popTankScale,
				iconFuelWidth / 2, iconFuelWidth / 2
			)
		if fuelLazyBarWidth > 0 then
			love.graphics.setColor(169, 241, 135)
			love.graphics.rectangle("fill", barOffsetX, barOffsetY, fuelLazyBarWidth, barHeight, 5, 5, 10)
		end
		love.graphics.setColor(231, 255, 170)
		love.graphics.rectangle("line", barOffsetX, barOffsetY, barWidth, barHeight, 5, 5, 10)
	elseif fuel > config.ROCKET_FUEL_MAX * 0.3 then
		love.graphics.setColor(255, 255, 255)
			love.graphics.draw(
				iconFuel,
				fuelIconOffsetX + iconFuelWidth * cam.scale / 2, fuelIconOffsetY + iconFuelWidth * cam.scale / 2, 0,
				cam.scale * popTankScale, cam.scale * popTankScale,
				iconFuelWidth / 2, iconFuelWidth / 2
			)
		if fuelLazyBarWidth > 0 then
			love.graphics.setColor(255, 244, 54)
			love.graphics.rectangle("fill", barOffsetX, barOffsetY, fuelLazyBarWidth, barHeight, 5, 5, 10)
		end
		love.graphics.setColor(255, 244, 54)
		love.graphics.rectangle("line", barOffsetX, barOffsetY, barWidth, barHeight, 5, 5, 10)
	elseif fuel > 0 then
		love.graphics.setColor(255, 255, 255)
			love.graphics.draw(
				iconFuel,
				fuelIconOffsetX + iconFuelWidth * cam.scale / 2, fuelIconOffsetY + iconFuelWidth * cam.scale / 2, 0,
				cam.scale * popTankScale, cam.scale * popTankScale,
				iconFuelWidth / 2, iconFuelWidth / 2
			)
		if fuelLazyBarWidth > 0 then
			love.graphics.setColor(255, 0, 0)
			love.graphics.rectangle("fill", barOffsetX, barOffsetY, fuelLazyBarWidth, barHeight, 5, 5, 10)
		end
		love.graphics.setColor(255, 0, 0)
		love.graphics.rectangle("line", barOffsetX, barOffsetY, barWidth, barHeight, 5, 5, 10)
	else
		if not fuelBlinkTimer then
			fuelBlinkTimer = timer.new({
				name = "fuelBlinkTimer",
				callbackModule = M,
				basePeriod = 0.3,
				randomness = 0,
				isRepeating = true,
			})
			timekeeper.addTimer(fuelBlinkTimer)
		end
		if fuelBlink then
			love.graphics.setColor(255, 255, 255)
			love.graphics.draw(
				iconFuel,
				fuelIconOffsetX + iconFuelWidth * cam.scale / 2, fuelIconOffsetY + iconFuelWidth * cam.scale / 2, 0,
				cam.scale * popTankScale, cam.scale * popTankScale,
				iconFuelWidth / 2, iconFuelWidth / 2
			)
			love.graphics.setColor(255, 0, 0)
			love.graphics.rectangle("line", barOffsetX, barOffsetY, barWidth, barHeight, 5, 5, 10)
		end
	end		
	-- draw astronauts
	local iconAstros = love.graphics.newImage(imgFeedback01, config.IMG_MODE)
	local iconAstrosWidth = iconAstros:getWidth()
	local astros = M.stats.astronautsSaved
	local astrosIconOffsetX, astrosIconOffsetY = lineHeight / 4, lineHeight * 1.5
	local numHeight = fontMain:getHeight()
	local numOffsetX = lineHeight * 1.3 + astrosIconOffsetX
	local numOffsetY = (lineHeight - numHeight) * 0.6 + astrosIconOffsetY
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(
		iconAstros,
		astrosIconOffsetX + iconAstrosWidth * cam.scale / 2, astrosIconOffsetY + iconAstrosWidth * cam.scale / 2, 0,
		cam.scale * popAstrScale, cam.scale * popAstrScale,
		iconAstrosWidth / 2, iconAstrosWidth / 2
	)
	love.graphics.setFont(fontMain)
	love.graphics.print(astros, numOffsetX, numOffsetY)
end

function M.popAstronautIcon()
	if popAstrTimer then
		timekeeper.removeTimer(popAstrTimer)
		popAstrScale = 1
	end
	popAstrTimer = timer.new(
		{
			name = "popAstrTimer",
			callbackModule = M,
			basePeriod = 0.3,
			randomness = 0,
			isRepeating = false,
		}
	)
	timekeeper.addTimer(popAstrTimer)
end

function M.popTankIcon()
	if popTankTimer then
		timekeeper.removeTimer(popTankTimer)
		popTankScale = 1
	end
	popTankTimer = timer.new(
		{
			name = "popTankTimer",
			callbackModule = M,
			basePeriod = 0.3,
			randomness = 0,
			isRepeating = false,
		}
	)
	timekeeper.addTimer(popTankTimer)
end

return M