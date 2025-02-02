local timer = require("scripts/timer")
local body = require("scripts/body")

local M = {
	bestScore = saveData.highScore,
}
local soundTrack = sndScores
local scoresDelayTimer = nil
local astronautsNum = 0
local scoreBody = nil
local bestScoreBody = nil
local hintBody = nil
local overlay = {
	buttonWidth = cam.scale * 128,
	buttonOffs = { cam.scale * 32, cam.scale * 192, },
}

function M.start()
	-- create delay timer
	scoresDelayTimer = timer.new(
		{
			name = "scoresDelayTimer",
			callbackModule = M,
			basePeriod = config.SCORES_DELAY_TIME,
			randomness = 0,
			isRepeating = false,
		}
	)
	timekeeper.addTimer(scoresDelayTimer)
	-- update best score
	astronautsNum = gameState.states["play"].stats.astronautsSaved
	if astronautsNum > M.bestScore then
		M.bestScore = astronautsNum
		saveData.highScore = M.bestScore
	end
	local textHeight = fontTitle:getHeight()
	local textWidth = fontTitle:getWidth("Best score: "..M.bestScore)
	local textHeight2 = fontMain:getHeight()
	scoreBody = body:new(
		{
			x = cam.width / 2 - textWidth / 2,
			y = cam.height * 0.3,
			radius = 10,
			angle = math.rad(0),
			movable = false,
			collidable = false,
		},
		{
			text = "Astronauts : "..astronautsNum,
			textFont = fontMain,
			textColor = { r = 255, g = 255, b = 255 },
			align = "left",
		}
	)
	bestScoreBody = body:new(
		{
			x = cam.width / 2 - textWidth / 2,
			y = cam.height * 0.35,
			radius = 10,
			angle = math.rad(0),
			movable = false,
			collidable = false,
		},
		{
			text = "Best score: "..M.bestScore,
			textFont = fontTitle,
			textColor = { r = 255, g = 255, b = 255 },
			align = "left",
		}
	)
	hintBody = body:new(
		{
			x = cam.width / 2,
			y = cam.height * 0.7,
			radius = 10,
			angle = math.rad(0),
			movable = false,
			collidable = false,
		},
		{
			text = "click anywhere to play again",
			textFont = fontMain,
			textColor = { r = 255, g = 255, b = 255 },
			blinkPeriod = 0.8,
		}
	)
	hintBody:init()
end

function M.finish()
	if scoresDelayTimer then
		timekeeper.removeTimer(scoresDelayTimer)
		scoresDelayTimer = nil
	end
	scoreBody:kill("no reports")
	bestScoreBody:kill("no reports")
	hintBody:kill("no reports")
	scoreBody = nil
	bestScoreBody = nil
	hintBody = nil
	-- create state tail script
	local script = {
		update = function(dt)
			if config.SCORES_FADE_TIME > 0 then
				soundTrack:setVolume(soundTrack:getVolume()-dt/config.SCORES_FADE_TIME)
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
			basePeriod = config.SCORES_FADE_TIME,
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
	scoreBody:update(dt)
	bestScoreBody:update(dt)
	hintBody:update(dt)
end

function M.draw()
	scoreBody:draw()
	bestScoreBody:draw()
	if not scoresDelayTimer then hintBody:draw() end
	M.drawOverlay()
end

function M.mousepressed(x, y, button, istouch)
	if button == 1 then
		-- if mouse is not over the button, then switch state
		local btn = M.getButtonClicked(x, y)
		if btn == 0 and not scoresDelayTimer then
			gameState.states["play"].rocketSpawnPoint = { x = x, y = y }
			gameState.setState("play")
		elseif btn == 1 then
			galaxy.theme = "default"
		elseif btn == 2 then
			galaxy.theme = "halloween"
		end
	end
end

-- ================================
-- Events
-- ================================

function M.onTimerFinish(event)
	if event.timer == scoresDelayTimer then
		scoresDelayTimer = nil
		soundTrack:setVolume(1)
		soundTrack:play()
	end
end

-- ================================
-- Methods
-- ================================

function M.getButtonClicked(x, y)
	local button = 0
	for i = 1, galaxy.themesUnlocked do
		if (x > overlay.buttonOffs[1] and x < overlay.buttonOffs[1] + overlay.buttonWidth) and
		   (y > overlay.buttonOffs[i] and y < overlay.buttonOffs[i] + overlay.buttonWidth) then
			button = i
		end
	end
	return button
end

function M.drawOverlay()
	local iconRocket = {
		love.graphics.newImage( imgRocket["default"], config.IMG_MODE ),
		love.graphics.newImage( imgRocket["halloween"], config.IMG_MODE ),
	}
	local iconRocketWidth = iconRocket[1]:getWidth()
	local iconRocketOffs = {
		overlay.buttonOffs[1] + ( overlay.buttonWidth - iconRocketWidth * cam.scale ) / 2,
		overlay.buttonOffs[2] + ( overlay.buttonWidth - iconRocketWidth * cam.scale ) / 2,
	}
	-- draw buttons
	love.graphics.setLineWidth(2)
	if love.mouse.isDown(1) then
		local mx, my = love.mouse.getPosition()
		local btn = M.getButtonClicked(mx, my)
		if btn ~= 0 then
			love.graphics.setColor(231, 255, 170)
			love.graphics.rectangle(
				"fill",
				overlay.buttonOffs[1], overlay.buttonOffs[btn],
				overlay.buttonWidth, overlay.buttonWidth,
				5, 5, 10
			)
		end
	end
	for i = 1, galaxy.themesUnlocked do
		love.graphics.setColor(231, 255, 170)
		love.graphics.rectangle(
			"line",
			overlay.buttonOffs[1], overlay.buttonOffs[i],
			overlay.buttonWidth, overlay.buttonWidth,
			5, 5, 10
		)
		-- icon
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(
			iconRocket[i],
			iconRocketOffs[1], iconRocketOffs[i], 0,
			cam.scale, cam.scale
		)
	end
	-- mark current theme
	local markOffsX = overlay.buttonOffs[1] + overlay.buttonWidth * 0.1
	local markOffsY = 0
	if galaxy.theme == "default" then
		markOffsY = overlay.buttonOffs[1] + overlay.buttonWidth * 0.05
	elseif galaxy.theme == "halloween" then
		markOffsY = overlay.buttonOffs[2] + overlay.buttonWidth * 0.05
	end
	love.graphics.setFont(fontMain)
	love.graphics.setColor(255, 255, 255)
	love.graphics.print("*", markOffsX, markOffsY)
end		

return M